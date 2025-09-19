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
        print("""
        
        📋 CLOUDKIT SCHEMA SETUP INSTRUCTIONS
        =====================================
        
        Follow these steps to set up your CloudKit schema:
        
        1. Open CloudKit Console: https://icloud.developer.apple.com/dashboard/
        2. Select your app and Development environment
        3. Go to Schema → Record Types
        
        4. Create "Users" record type with fields:
           - displayName (String, Required)
           - email (String, Optional)
           - role (String, Required)
           - joinedDate (Date/Time, Required)
           - isActive (Int(64), Required)
        
        5. Create "BabyProfile" record type with fields:
           - name (String, Required)
           - birthDate (Date/Time, Required)
           - feedingGoal (Int(64), Required)
           - sleepGoal (Double, Required)
           - diaperGoal (Int(64), Required)
           - createdBy (Reference to Users, Required)
        
        6. Create "Activity" record type with fields:
           - type (String, Required)
           - time (Date/Time, Required)
           - details (String, Required)
           - mood (String, Required)
           - duration (Int(64), Optional)
           - notes (String, Optional)
           - weight (Double, Optional)
           - height (Double, Optional)
           - babyProfile (Reference to BabyProfile, Required)
           - createdBy (Reference to Users, Required)
        
        7. Create Indexes (IMPORTANT for queries):
           - Activity: Index on "babyProfile" (QUERYABLE)
           - Activity: Index on "time" (QUERYABLE, SORTABLE)
           - BabyProfile: Index on "birthDate" (QUERYABLE, SORTABLE)
           - BabyProfile: Index on "createdBy" (QUERYABLE)
           - Users: Index on "email" (QUERYABLE)
        
        8. Deploy to Production:
           - After testing in Development, deploy schema to Production
           - Go to Schema → Deploy Schema Changes → Deploy to Production
        
        ⚠️  IMPORTANT: 
        - Make sure iCloud is enabled in your app's capabilities
        - Test thoroughly in Development before deploying to Production
        - Schema changes in Production are permanent and cannot be undone
        - ALL indexes are required for the app to work properly
        
        """)
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
        print("🔧 Creating CloudKit schema step by step...")
        
        let uniqueID = UUID().uuidString.prefix(8)
        
        do {
            // Step 1: Create Users record type first
            print("📝 Step 1: Creating Users record type...")
            let userRecordID = CKRecord.ID(recordName: "schema_user_\(uniqueID)")
            let userRecord = CKRecord(recordType: "Users", recordID: userRecordID)
            userRecord["displayName"] = "Schema User"
            userRecord["email"] = "schema@test.com"
            userRecord["role"] = "parent"
            userRecord["joinedDate"] = Date()
            userRecord["isActive"] = 1
            
            let savedUser = try await privateDatabase.save(userRecord)
            print("✅ Users record type created successfully")
            
            // Step 2: Create BabyProfile record type (without Reference first)
            print("📝 Step 2: Creating BabyProfile record type...")
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
                print("✅ BabyProfile with Reference field created successfully")
                
                // Step 3: Create Activity record type
                try await createActivityRecord(profileRecord: savedProfile, userRecord: savedUser, uniqueID: String(uniqueID))
                
                // Clean up
                try await cleanupRecords(userID: savedUser.recordID, profileID: savedProfile.recordID)
                
            } catch let error as CKError where error.code == .invalidArguments {
                print("⚠️ Reference field not supported yet, creating basic record first...")
                
                // Create without Reference field first to establish the record type
                let basicProfile = CKRecord(recordType: "BabyProfile")
                basicProfile["name"] = "Basic Schema"
                basicProfile["birthDate"] = Date()
                basicProfile["feedingGoal"] = 1
                basicProfile["sleepGoal"] = 1.0
                basicProfile["diaperGoal"] = 1
                
                let basicSaved = try await privateDatabase.save(basicProfile)
                print("✅ Basic BabyProfile record type created")
                
                // Clean up and throw error with instructions
                try await privateDatabase.deleteRecord(withID: basicSaved.recordID)
                try await privateDatabase.deleteRecord(withID: savedUser.recordID)
                
                throw SchemaError.referenceFieldNotConfigured
            }
            
        } catch {
            print("❌ Schema creation failed: \(error)")
            throw error
        }
    }
    
    private func createActivityRecord(profileRecord: CKRecord, userRecord: CKRecord, uniqueID: String) async throws {
        print("📝 Step 3: Creating Activity record type...")
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
        print("✅ Activity record type created successfully")
    }
    
    private func cleanupRecords(userID: CKRecord.ID, profileID: CKRecord.ID) async throws {
        print("🧹 Cleaning up schema records...")
        // Note: Activity will be deleted automatically due to cascade delete
        try await privateDatabase.deleteRecord(withID: profileID)
        try await privateDatabase.deleteRecord(withID: userID)
        print("✅ Schema setup complete and cleaned up!")
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
