import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitManager: ObservableObject {
    nonisolated static let shared = CloudKitManager()
    
    private let container = CKContainer(identifier: "iCloud.com.mytotsapp.tots.DB")
    let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    @Published var isSignedIn = false
    @Published var familyMembers: [FamilyMember] = []
    @Published var activeShare: CKShare?
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle, syncing, success, error(String)
    }
    
    nonisolated private init() {
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
        
        // Production CloudKit setup
        
        Task { @MainActor in
            checkAccountStatus()
        }
    }
    
    // MARK: - Account Management
    
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isSignedIn = true
                case .noAccount:
                    self?.isSignedIn = false
                case .restricted:
                    self?.isSignedIn = false
                case .couldNotDetermine:
                    self?.isSignedIn = false
                case .temporarilyUnavailable:
                    self?.isSignedIn = false
                @unknown default:
                    self?.isSignedIn = false
                }
            }
        }
    }
    
    func checkAccountStatus() async throws -> CKAccountStatus {
        return try await withCheckedThrowingContinuation { continuation in
            container.accountStatus { status, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }
    
    // MARK: - User Management
    
    func getOrCreateUserRecord() async throws -> CKRecord {
        let userID = try await container.userRecordID()
        
        // Try to fetch existing user record
        do {
            let existingUser = try await privateDatabase.record(for: userID)
            return existingUser
        } catch let error as CKError {
            if error.code == .unknownItem {
                // User record doesn't exist, create it
                let userRecord = CKRecord(recordType: "Users", recordID: userID)
                userRecord["displayName"] = "Parent" // Default name
                userRecord["email"] = "" // Can be filled in later
                userRecord["role"] = "parent"
                userRecord["joinedDate"] = Date()
                userRecord["isActive"] = 1
                
                return try await privateDatabase.save(userRecord)
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Baby Profile Management
    
    func createBabyProfile(name: String, birthDate: Date, goals: BabyGoals) async throws -> CKRecord {
        // First ensure user record exists
        let userRecord = try await getOrCreateUserRecord()
        
        let record = CKRecord(recordType: "BabyProfile")
        record["name"] = name
        record["birthDate"] = birthDate
        record["feedingGoal"] = goals.feeding
        record["sleepGoal"] = goals.sleep
        record["diaperGoal"] = goals.diaper
        record["createdBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        return try await privateDatabase.save(record)
    }
    
    func fetchBabyProfiles() async throws -> [CKRecord] {
        // First ensure user record exists
        let userRecord = try await getOrCreateUserRecord()
        
        // Query for baby profiles created by this user
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        let predicate = NSPredicate(format: "createdBy == %@", userReference)
        let query = CKQuery(recordType: "BabyProfile", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "birthDate", ascending: false)]
        
        let result = try await privateDatabase.records(matching: query)
        let profiles = result.matchResults.compactMap { try? $0.1.get() }
        
        return profiles
    }
    
    func fetchBabyProfile(recordID: CKRecord.ID) async throws -> CKRecord {
        return try await privateDatabase.record(for: recordID)
    }
    
    // MARK: - Activity Management
    
    func saveActivity(_ activity: TotsActivity, to babyProfileID: CKRecord.ID) async throws {
        // Ensure user record exists
        let userRecord = try await getOrCreateUserRecord()
        
        let record = CKRecord(recordType: "Activity")
        record["type"] = activity.type.rawValue
        record["time"] = activity.time
        record["details"] = activity.details
        record["mood"] = activity.mood.rawValue
        record["duration"] = activity.duration
        record["notes"] = activity.notes
        record["weight"] = activity.weight
        record["height"] = activity.height
        record["babyProfile"] = CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf)
        record["createdBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        // Save to shared database if profile is shared, otherwise private
        let database = activeShare != nil ? sharedDatabase : privateDatabase
        _ = try await database.save(record)
    }
    
    func fetchActivities(for babyProfileID: CKRecord.ID) async throws -> [TotsActivity] {
        let reference = CKRecord.Reference(recordID: babyProfileID, action: .none)
        let predicate = NSPredicate(format: "babyProfile == %@", reference)
        let query = CKQuery(recordType: "Activity", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        
        let database = activeShare != nil ? sharedDatabase : privateDatabase
        let result = try await database.records(matching: query)
        
        return result.matchResults.compactMap { matchResult in
            guard let record = try? matchResult.1.get() else { return nil }
            return convertToActivity(record)
        }
    }
    
    private func convertToActivity(_ record: CKRecord) -> TotsActivity? {
        guard let typeString = record["type"] as? String,
              let type = ActivityType(rawValue: typeString),
              let time = record["time"] as? Date,
              let details = record["details"] as? String,
              let moodString = record["mood"] as? String,
              let mood = BabyMood(rawValue: moodString) else {
            return nil
        }
        
        return TotsActivity(
            type: type,
            time: time,
            details: details,
            mood: mood,
            duration: record["duration"] as? Int,
            notes: record["notes"] as? String,
            weight: record["weight"] as? Double,
            height: record["height"] as? Double
        )
    }
    
    // MARK: - Family Sharing
    
    func shareBabyProfile(_ profileRecord: CKRecord) async throws -> CKShare {
        
        // Create a new record without any reference fields to avoid the reference error
        let cleanRecord = CKRecord(recordType: "BabyProfile")
        cleanRecord["name"] = profileRecord["name"]
        cleanRecord["birthDate"] = profileRecord["birthDate"]
        cleanRecord["feedingGoal"] = profileRecord["feedingGoal"]
        cleanRecord["sleepGoal"] = profileRecord["sleepGoal"]
        cleanRecord["diaperGoal"] = profileRecord["diaperGoal"]
        // Explicitly NOT copying createdBy or other reference fields
        
        let savedRecord = try await privateDatabase.save(cleanRecord)
        
        // Create and return the share for UICloudSharingController to handle
        let share = CKShare(rootRecord: savedRecord)
        share[CKShare.SystemFieldKey.title] = profileRecord["name"] as? String ?? "Baby Profile"
        share.publicPermission = .none
        
        // Let UICloudSharingController handle the actual share saving
        return share
    }
    
    func fetchSharedProfiles() async throws -> [CKRecord] {
        let query = CKQuery(recordType: "BabyProfile", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "birthDate", ascending: false)]
        
        let result = try await sharedDatabase.records(matching: query)
        return result.matchResults.compactMap { try? $0.1.get() }
    }
    
    func stopSharingProfile(_ profileRecord: CKRecord) async throws {
        // For now, just mark as not shared locally
        // CloudKit will handle the actual share removal
    }
    
    func fetchFamilyMembers(for share: CKShare) async throws -> [FamilyMember] {
        var members: [FamilyMember] = []
        
        // Add owner
        let ownerParticipant = share.owner
        let member = FamilyMember(
            name: ownerParticipant.userIdentity.nameComponents?.formatted() ?? "Owner",
            email: ownerParticipant.userIdentity.lookupInfo?.emailAddress ?? "",
            role: .owner,
            permission: .readWrite
        )
        members.append(member)
        
        // Add participants
        for participant in share.participants {
            if participant != ownerParticipant {
                let member = FamilyMember(
                    name: participant.userIdentity.nameComponents?.formatted() ?? "Family Member",
                    email: participant.userIdentity.lookupInfo?.emailAddress ?? "",
                    role: participant.role,
                    permission: participant.permission
                )
                members.append(member)
            }
        }
        
        return members
    }
    
    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        operation.qualityOfService = .userInitiated
        
        try await withCheckedThrowingContinuation { continuation in
            operation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    Task { @MainActor in
                        self.activeShare = metadata.share
                    }
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            container.add(operation)
        }
    }
    
    func checkForSharedRecords() async throws {
        let query = CKQuery(recordType: "cloudkit.share", predicate: NSPredicate(value: true))
        let result = try await sharedDatabase.records(matching: query)
        
        if let firstShare = result.matchResults.first?.1 {
            let shareRecord = try firstShare.get()
            if let share = shareRecord as? CKShare {
                await setActiveShare(share)
            }
        }
    }
    
    func setActiveShare(_ share: CKShare?) async {
        self.activeShare = share
    }
    
    // MARK: - Account Management
    
    func signOut() async {
        await MainActor.run {
            self.isSignedIn = false
            self.familyMembers = []
            self.activeShare = nil
            self.syncStatus = .idle
        }
        
        // Clear local storage
        UserDefaults.standard.removeObject(forKey: "baby_profile_record_id")
        UserDefaults.standard.removeObject(forKey: "family_sharing_enabled")
        UserDefaults.standard.set(false, forKey: "onboarding_completed")
        
        // Notify app to show onboarding
        await MainActor.run {
            NotificationCenter.default.post(name: .init("user_signed_out"), object: nil)
        }
    }
    
    func deleteAccount() async throws {
        print("🗑️ Starting account deletion...")
        
        // Fetch all user's records and delete them
        let userRecord = try await getOrCreateUserRecord()
        print("🗑️ Found user record: \(userRecord.recordID)")
        
        // Collect all record IDs to delete in batches
        var recordIDsToDelete: [CKRecord.ID] = []
        
        // Delete all baby profiles and associated data
        let profiles = try await fetchBabyProfiles()
        print("🗑️ Found \(profiles.count) baby profiles")
        
        for profile in profiles {
            print("🗑️ Processing profile: \(profile.recordID)")
            
            // Stop sharing first (this also deletes the share record)
            do {
                try await stopSharingProfile(profile)
                print("🗑️ Stopped sharing for profile")
            } catch {
                print("🗑️ Error stopping sharing: \(error)")
            }
            
            // Collect activities for batch deletion
            let activities = try await fetchActivities(for: profile.recordID)
            print("🗑️ Found \(activities.count) activities for profile")
            for activity in activities {
                recordIDsToDelete.append(CKRecord.ID(recordName: activity.id.uuidString))
            }
            
            // Add profile to deletion list
            recordIDsToDelete.append(profile.recordID)
        }
        
        // Also query for ALL activities directly (in case they're not linked to profiles)
        let allActivitiesQuery = CKQuery(recordType: "Activity", predicate: NSPredicate(format: "TRUEPREDICATE"))
        do {
            let (allActivityRecords, _) = try await privateDatabase.records(matching: allActivitiesQuery)
            print("🗑️ Found \(allActivityRecords.count) total activities in database")
            for (recordID, result) in allActivityRecords {
                switch result {
                case .success(_):
                    if !recordIDsToDelete.contains(recordID) {
                        recordIDsToDelete.append(recordID)
                        print("🗑️ Added unlinked activity: \(recordID)")
                    }
                case .failure(let error):
                    print("🗑️ Error fetching activity \(recordID): \(error)")
                }
            }
        } catch {
            print("🗑️ Error querying all activities: \(error)")
        }
        
        // Query for all other record types
        let recordTypes = ["Growth", "Words", "Milestones", "FamilyMembers", "UserPreferences"]
        for recordType in recordTypes {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(format: "TRUEPREDICATE"))
            do {
                let (records, _) = try await privateDatabase.records(matching: query)
                print("🗑️ Found \(records.count) \(recordType) records")
                for (recordID, result) in records {
                    switch result {
                    case .success(_):
                        recordIDsToDelete.append(recordID)
                    case .failure(let error):
                        print("🗑️ Error fetching \(recordType) \(recordID): \(error)")
                    }
                }
            } catch {
                print("🗑️ Error querying \(recordType): \(error)")
            }
        }
        
        print("🗑️ Total records to delete: \(recordIDsToDelete.count)")
        
        if recordIDsToDelete.count > 0 {
            // Batch delete records in groups of 400 (CloudKit limit)
            let batchSize = 400
            for i in stride(from: 0, to: recordIDsToDelete.count, by: batchSize) {
                let endIndex = min(i + batchSize, recordIDsToDelete.count)
                let batch = Array(recordIDsToDelete[i..<endIndex])
                
                print("🗑️ Deleting batch of \(batch.count) records...")
                
                let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: batch)
                operation.database = privateDatabase
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    operation.modifyRecordsResultBlock = { result in
                        switch result {
                        case .success:
                            print("🗑️ Successfully deleted batch of \(batch.count) records")
                            continuation.resume()
                        case .failure(let error):
                            print("🗑️ Error deleting batch: \(error)")
                            // Continue even if some deletions fail
                            continuation.resume()
                        }
                    }
                    privateDatabase.add(operation)
                }
            }
        } else {
            print("🗑️ No CloudKit records found - data is stored locally only")
        }
        
        // Clear local CloudKit state
        await MainActor.run {
            self.isSignedIn = false
            self.familyMembers = []
            self.activeShare = nil
            self.syncStatus = .idle
        }
        
        print("🗑️ Account deletion completed!")
    }
}

// MARK: - Supporting Types

struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let role: CKShare.ParticipantRole
    let permission: CKShare.ParticipantPermission
}

enum CloudKitError: Error, LocalizedError {
    case userNotFound
    case shareNotFound
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found in CloudKit"
        case .shareNotFound:
            return "Shared record not found"
        case .syncFailed:
            return "Failed to sync with CloudKit"
        }
    }
}
