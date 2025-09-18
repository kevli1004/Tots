import Foundation
import CloudKit

class CloudKitSchemaSetup {
    static let shared = CloudKitSchemaSetup()
    private let container = CKContainer.default()
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
        
        7. Create Indexes:
           - Activity: Index on "babyProfile" (QUERYABLE)
           - Activity: Index on "time" (QUERYABLE, SORTABLE)
           - BabyProfile: Index on "createdBy" (QUERYABLE)
           - Users: Index on "email" (QUERYABLE)
        
        8. Deploy to Production:
           - After testing in Development, deploy schema to Production
           - Go to Schema → Deploy Schema Changes → Deploy to Production
        
        ⚠️  IMPORTANT: 
        - Make sure iCloud is enabled in your app's capabilities
        - Test thoroughly in Development before deploying to Production
        - Schema changes in Production are permanent and cannot be undone
        
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
        print("🔧 Creating sample records to establish CloudKit schema...")
        
        do {
            // Create sample user
            let userRecord = CKRecord(recordType: "Users")
            userRecord["displayName"] = "Sample User"
            userRecord["email"] = "sample@example.com"
            userRecord["role"] = "parent"
            userRecord["joinedDate"] = Date()
            userRecord["isActive"] = 1
            
            let savedUser = try await privateDatabase.save(userRecord)
            print("✅ Created Users record type")
            
            // Create sample baby profile
            let profileRecord = CKRecord(recordType: "BabyProfile")
            profileRecord["name"] = "Sample Baby"
            profileRecord["birthDate"] = Date()
            profileRecord["feedingGoal"] = 8
            profileRecord["sleepGoal"] = 15.0
            profileRecord["diaperGoal"] = 6
            profileRecord["createdBy"] = CKRecord.Reference(recordID: savedUser.recordID, action: .none)
            
            let savedProfile = try await privateDatabase.save(profileRecord)
            print("✅ Created BabyProfile record type")
            
            // Create sample activity
            let activityRecord = CKRecord(recordType: "Activity")
            activityRecord["type"] = "feeding"
            activityRecord["time"] = Date()
            activityRecord["details"] = "Sample feeding"
            activityRecord["mood"] = "happy"
            activityRecord["duration"] = 30
            activityRecord["notes"] = "Sample notes"
            activityRecord["babyProfile"] = CKRecord.Reference(recordID: savedProfile.recordID, action: .deleteSelf)
            activityRecord["createdBy"] = CKRecord.Reference(recordID: savedUser.recordID, action: .none)
            
            _ = try await privateDatabase.save(activityRecord)
            print("✅ Created Activity record type")
            
            // Clean up sample records
            try await privateDatabase.deleteRecord(withID: activityRecord.recordID)
            try await privateDatabase.deleteRecord(withID: savedProfile.recordID)
            try await privateDatabase.deleteRecord(withID: savedUser.recordID)
            print("🧹 Cleaned up sample records")
            
            print("✅ CloudKit schema setup complete!")
            
        } catch {
            print("❌ Failed to create sample records: \(error)")
            throw error
        }
    }
}

// MARK: - Supporting Types

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
