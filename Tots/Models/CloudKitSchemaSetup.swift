import Foundation
import CloudKit

class CloudKitSchemaSetup {
    static let shared = CloudKitSchemaSetup()
    private let container = CKContainer(identifier: "iCloud.com.mytotsapp.tots.DB")
    private let privateDatabase: CKDatabase
    
    private init() {
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Schema Instructions
    
    func printSchemaInstructions() {
        
    }
    
    // MARK: - Schema Validation
    
    func checkSchemaStatus() async -> SchemaStatus {
        var status = SchemaStatus()
        
        do {
            // Check Users record type
            let usersQuery = CKQuery(recordType: "Users", predicate: NSPredicate(value: true))
            let (_, _) = try await privateDatabase.records(matching: usersQuery, resultsLimit: 1)
            status.usersExists = true
        } catch {
            status.usersExists = false
        }
        
        do {
            // Check BabyProfile record type
            let profileQuery = CKQuery(recordType: "BabyProfile", predicate: NSPredicate(value: true))
            let (_, _) = try await privateDatabase.records(matching: profileQuery, resultsLimit: 1)
            status.babyProfileExists = true
        } catch {
            status.babyProfileExists = false
        }
        
        do {
            // Check Activity record type
            let activityQuery = CKQuery(recordType: "Activity", predicate: NSPredicate(value: true))
            let (_, _) = try await privateDatabase.records(matching: activityQuery, resultsLimit: 1)
            status.activityExists = true
        } catch {
            status.activityExists = false
        }
        
        return status
    }
    
    func isSchemaSetup() async -> Bool {
        let status = await checkSchemaStatus()
        return status.usersExists && status.babyProfileExists && status.activityExists
    }
    
    // MARK: - Development Helper (Creates sample records to establish schema)
    
    func createSampleRecordsForSchema() async throws {
        
        let uniqueID = UUID().uuidString.prefix(8)
        
        do {
            // Step 1: Create Users record type first
            let userRecordID = CKRecord.ID(recordName: "schema_user_\(uniqueID)")
            let userRecord = CKRecord(recordType: "Users", recordID: userRecordID)
            userRecord["displayName"] = "Schema User"
            userRecord["email"] = "schema@test.com"
            userRecord["role"] = "parent"
            userRecord["joinedDate"] = Date()
            userRecord["isActive"] = 1
            
            let savedUser = try await privateDatabase.save(userRecord)
            
            // Step 2: Create BabyProfile record type (without Reference first)
            let profileRecordID = CKRecord.ID(recordName: "schema_profile_\(uniqueID)")
            let profileRecord = CKRecord(recordType: "BabyProfile", recordID: profileRecordID)
            profileRecord["name"] = "Schema Baby"
            profileRecord["birthDate"] = Date()
            profileRecord["feedingGoal"] = 8
            profileRecord["sleepGoal"] = 15.0
            profileRecord["diaperGoal"] = 6
            
            // Try to create with Reference, fallback to String if field doesn't exist yet
            do {
                profileRecord["createdBy"] = CKRecord.Reference(recordID: savedUser.recordID, action: .none)
                let savedProfile = try await privateDatabase.save(profileRecord)
                
                // Step 3: Create Activity record type
                try await createActivityRecord(profileRecord: savedProfile, userRecord: savedUser, uniqueID: String(uniqueID))
                
                // Clean up
                try await cleanupRecords(userID: savedUser.recordID, profileID: savedProfile.recordID)
                
            } catch let error as CKError where error.code == .invalidArguments {
                
                // Create without Reference field first to establish the record type
                let basicProfile = CKRecord(recordType: "BabyProfile")
                basicProfile["name"] = "Basic Schema"
                basicProfile["birthDate"] = Date()
                basicProfile["feedingGoal"] = 1
                basicProfile["sleepGoal"] = 1.0
                basicProfile["diaperGoal"] = 1
                
                let basicSaved = try await privateDatabase.save(basicProfile)
                
                // Clean up and throw error with instructions
                try await privateDatabase.deleteRecord(withID: basicSaved.recordID)
                try await privateDatabase.deleteRecord(withID: savedUser.recordID)
                
                throw SchemaError.referenceFieldNotConfigured
            }
            
        } catch {
            throw error
        }
    }
    
    private func createActivityRecord(profileRecord: CKRecord, userRecord: CKRecord, uniqueID: String) async throws {
        let activityRecordID = CKRecord.ID(recordName: "schema_activity_\(uniqueID)")
        let activityRecord = CKRecord(recordType: "Activity", recordID: activityRecordID)
        activityRecord["type"] = "feeding"
        activityRecord["time"] = Date()
        activityRecord["details"] = "Schema test"
        activityRecord["mood"] = "happy"
        activityRecord["duration"] = 1
        activityRecord["notes"] = "test"
        activityRecord["babyProfile"] = CKRecord.Reference(recordID: profileRecord.recordID, action: .deleteSelf)
        activityRecord["createdBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        _ = try await privateDatabase.save(activityRecord)
    }
    
    private func cleanupRecords(userID: CKRecord.ID, profileID: CKRecord.ID) async throws {
        // Note: Activity will be deleted automatically due to cascade delete
        try await privateDatabase.deleteRecord(withID: profileID)
        try await privateDatabase.deleteRecord(withID: userID)
    }
}

// MARK: - Supporting Types

enum SchemaError: Error, LocalizedError {
    case referenceFieldNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .referenceFieldNotConfigured:
            return "CloudKit schema needs manual setup - Reference fields not configured properly"
        }
    }
}

struct SchemaStatus {
    var usersExists: Bool = false
    var babyProfileExists: Bool = false
    var activityExists: Bool = false
    
    var allExist: Bool {
        return usersExists && babyProfileExists && activityExists
    }
    
    var description: String {
        return """
        Schema Status:
        - Users: \(usersExists ? "✅" : "❌")
        - BabyProfile: \(babyProfileExists ? "✅" : "❌") 
        - Activity: \(activityExists ? "✅" : "❌")
        """
    }
}

// MARK: - Production Schema Setup Extension
extension CloudKitSchemaSetup {
    
    func createProductionSchema() async throws {
        // Create all record types for production by creating and deleting sample records
        do {
            try await createBabyProfileSchema()
        } catch {
            throw NSError(domain: "CloudKitSchemaSetup", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create BabyProfile schema: \(error.localizedDescription)"
            ])
        }
        
        do {
            try await createActivitySchema()
        } catch {
            throw NSError(domain: "CloudKitSchemaSetup", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create Activity schema: \(error.localizedDescription)"
            ])
        }
        
        do {
            try await createGrowthSchema()
        } catch {
            throw NSError(domain: "CloudKitSchemaSetup", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create Growth schema: \(error.localizedDescription)"
            ])
        }
        
        do {
            try await createWordsSchema()
        } catch {
            throw NSError(domain: "CloudKitSchemaSetup", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create Words schema: \(error.localizedDescription)"
            ])
        }
        
        do {
            try await createMilestonesSchema()
        } catch {
            throw NSError(domain: "CloudKitSchemaSetup", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create Milestones schema: \(error.localizedDescription)"
            ])
        }
        
        do {
            try await createFamilyMembersSchema()
        } catch {
            throw NSError(domain: "CloudKitSchemaSetup", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create FamilyMembers schema: \(error.localizedDescription)"
            ])
        }
        
        do {
            try await createUserPreferencesSchema()
        } catch {
            throw NSError(domain: "CloudKitSchemaSetup", code: 7, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create UserPreferences schema: \(error.localizedDescription)"
            ])
        }
    }
    
    private func createBabyProfileSchema() async throws {
        let record = CKRecord(recordType: "BabyProfile")
        record["name"] = "Schema Setup" as CKRecordValue
        record["primaryName"] = "Setup" as CKRecordValue
        record["birthday"] = Date() as CKRecordValue
        record["profileImageData"] = Data() as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["familyID"] = "schema_family" as CKRecordValue
        record["preferences"] = "{}" as CKRecordValue
        
        let saved = try await privateDatabase.save(record)
        try await privateDatabase.deleteRecord(withID: saved.recordID)
    }
    
    private func createActivitySchema() async throws {
        let record = CKRecord(recordType: "Activity")
        record["type"] = "feeding" as CKRecordValue
        record["time"] = Date() as CKRecordValue
        record["details"] = "Schema setup" as CKRecordValue
        record["duration"] = 30 as CKRecordValue
        record["mood"] = "content" as CKRecordValue
        record["notes"] = "Setup" as CKRecordValue
        record["location"] = "Home" as CKRecordValue
        record["weather"] = "Clear" as CKRecordValue
        record["feedingType"] = "bottle" as CKRecordValue
        record["feedingAmount"] = 4.0 as CKRecordValue
        record["diaperType"] = "wet" as CKRecordValue
        record["activitySubType"] = "tummyTime" as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["familyID"] = "schema_family" as CKRecordValue
        
        let saved = try await privateDatabase.save(record)
        try await privateDatabase.deleteRecord(withID: saved.recordID)
    }
    
    private func createGrowthSchema() async throws {
        let record = CKRecord(recordType: "Growth")
        record["date"] = Date() as CKRecordValue
        record["weight"] = 3.5 as CKRecordValue
        record["height"] = 50.0 as CKRecordValue
        record["headCircumference"] = 35.0 as CKRecordValue
        record["weightUnit"] = "kg" as CKRecordValue
        record["heightUnit"] = "cm" as CKRecordValue
        record["headCircumferenceUnit"] = "cm" as CKRecordValue
        record["notes"] = "Schema setup" as CKRecordValue
        record["percentileWeight"] = 50.0 as CKRecordValue
        record["percentileHeight"] = 50.0 as CKRecordValue
        record["percentileHeadCircumference"] = 50.0 as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["familyID"] = "schema_family" as CKRecordValue
        
        let saved = try await privateDatabase.save(record)
        try await privateDatabase.deleteRecord(withID: saved.recordID)
    }
    
    private func createWordsSchema() async throws {
        let record = CKRecord(recordType: "Words")
        record["word"] = "mama" as CKRecordValue
        record["category"] = "people" as CKRecordValue
        record["dateFirstSaid"] = Date() as CKRecordValue
        record["notes"] = "First word!" as CKRecordValue
        record["isCustom"] = 0 as CKRecordValue
        record["pronunciation"] = "ma-ma" as CKRecordValue
        record["context"] = "Looking at mom" as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["familyID"] = "schema_family" as CKRecordValue
        
        let saved = try await privateDatabase.save(record)
        try await privateDatabase.deleteRecord(withID: saved.recordID)
    }
    
    private func createMilestonesSchema() async throws {
        let record = CKRecord(recordType: "Milestones")
        record["title"] = "First Smile" as CKRecordValue
        record["description"] = "Baby's first social smile" as CKRecordValue
        record["ageGroup"] = "0-3 months" as CKRecordValue
        record["minAgeWeeks"] = 4 as CKRecordValue
        record["maxAgeWeeks"] = 12 as CKRecordValue
        record["category"] = "social" as CKRecordValue
        record["isCompleted"] = 0 as CKRecordValue
        record["completedDate"] = Date() as CKRecordValue
        record["isCustom"] = 0 as CKRecordValue
        record["notes"] = "Schema setup" as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["familyID"] = "schema_family" as CKRecordValue
        
        let saved = try await privateDatabase.save(record)
        try await privateDatabase.deleteRecord(withID: saved.recordID)
    }
    
    private func createFamilyMembersSchema() async throws {
        let record = CKRecord(recordType: "FamilyMembers")
        record["name"] = "Parent" as CKRecordValue
        record["email"] = "parent@example.com" as CKRecordValue
        record["role"] = "parent" as CKRecordValue
        record["permissions"] = "{\"canEdit\": true}" as CKRecordValue
        record["inviteStatus"] = "accepted" as CKRecordValue
        record["invitedAt"] = Date() as CKRecordValue
        record["joinedAt"] = Date() as CKRecordValue
        record["familyID"] = "schema_family" as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        
        let saved = try await privateDatabase.save(record)
        try await privateDatabase.deleteRecord(withID: saved.recordID)
    }
    
    private func createUserPreferencesSchema() async throws {
        let record = CKRecord(recordType: "UserPreferences")
        record["useMetricUnits"] = 1 as CKRecordValue
        record["trackingGoals"] = "{\"feeding\": 180, \"diaper\": 240}" as CKRecordValue
        record["notificationSettings"] = "{}" as CKRecordValue
        record["privacySettings"] = "{}" as CKRecordValue
        record["appTheme"] = "auto" as CKRecordValue
        record["language"] = "en" as CKRecordValue
        record["timeZone"] = "UTC" as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue
        record["familyID"] = "schema_family" as CKRecordValue
        
        let saved = try await privateDatabase.save(record)
        try await privateDatabase.deleteRecord(withID: saved.recordID)
    }
}
