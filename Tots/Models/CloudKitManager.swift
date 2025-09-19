import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitManager: ObservableObject {
    nonisolated static let shared = CloudKitManager()
    
    private let container = CKContainer(identifier: "iCloud.com.mytotsapp.tots.DB")
    private let privateDatabase: CKDatabase
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
        
        // Debug: Print which environment we're using
        print("🔧 CloudKit Environment Info:")
        print("   Container ID: \(container.containerIdentifier ?? "unknown")")
        print("   Environment: Production (aps-environment=production)")
        print("   Database: Private CloudKit Database")
        
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
                    print("❌ No iCloud account")
                case .restricted:
                    self?.isSignedIn = false
                    print("❌ iCloud account restricted")
                case .couldNotDetermine:
                    self?.isSignedIn = false
                    print("❌ Could not determine iCloud status")
                case .temporarilyUnavailable:
                    self?.isSignedIn = false
                    print("⚠️ iCloud temporarily unavailable")
                @unknown default:
                    self?.isSignedIn = false
                    print("❌ Unknown iCloud status")
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
        print("🔍 CloudKit: Fetching profiles for user: \(userRecord.recordID.recordName)")
        
        // Query for baby profiles created by this user
        let userReference = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        let predicate = NSPredicate(format: "createdBy == %@", userReference)
        let query = CKQuery(recordType: "BabyProfile", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "birthDate", ascending: false)]
        
        print("🔍 CloudKit: Running query for BabyProfile records...")
        let result = try await privateDatabase.records(matching: query)
        let profiles = result.matchResults.compactMap { try? $0.1.get() }
        print("🔍 CloudKit: Found \(profiles.count) baby profiles")
        
        for (index, profile) in profiles.enumerated() {
            print("🔍 CloudKit: Profile \(index + 1): \(profile["name"] as? String ?? "Unknown") (ID: \(profile.recordID.recordName))")
        }
        
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
        // Ensure the profile record is saved first
        let savedProfile = try await privateDatabase.save(profileRecord)
        
        // Create the share
        let share = CKShare(rootRecord: savedProfile)
        share[CKShare.SystemFieldKey.title] = "Baby Profile: \(savedProfile["name"] as? String ?? "Unknown")"
        share.publicPermission = .none
        
        // Note: Participant permissions are set when users accept the share
        
        // Save the share
        _ = try await privateDatabase.save(share)
        
        return share
    }
    
    func fetchSharedProfiles() async throws -> [CKRecord] {
        let query = CKQuery(recordType: "BabyProfile", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "birthDate", ascending: false)]
        
        let result = try await sharedDatabase.records(matching: query)
        return result.matchResults.compactMap { try? $0.1.get() }
    }
    
    func stopSharingProfile(_ profileRecord: CKRecord) async throws {
        // Find the share record for this profile
        let shareQuery = CKQuery(recordType: "cloudkit.share", predicate: NSPredicate(format: "rootRecord == %@", profileRecord.recordID))
        let shareResult = try await privateDatabase.records(matching: shareQuery)
        
        if let shareRecord = shareResult.matchResults.first?.1 {
            let share = try shareRecord.get()
            try await privateDatabase.deleteRecord(withID: share.recordID)
        }
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
            print("📢 Posting user_signed_out notification")
            NotificationCenter.default.post(name: .init("user_signed_out"), object: nil)
        }
    }
    
    func deleteAccount() async throws {
        print("🗑️ CloudKit: Starting comprehensive account deletion...")
        
        // Fetch all user's records and delete them
        let userRecord = try await getOrCreateUserRecord()
        print("🗑️ CloudKit: Found user record: \(userRecord.recordID.recordName)")
        
        // Delete all baby profiles and associated data
        let profiles = try await fetchBabyProfiles()
        print("🗑️ CloudKit: Found \(profiles.count) baby profiles to delete")
        
        for profile in profiles {
            print("🗑️ CloudKit: Deleting profile: \(profile["name"] as? String ?? "Unknown")")
            
            // Stop sharing first (this also deletes the share record)
            do {
                try await stopSharingProfile(profile)
                print("✅ CloudKit: Stopped sharing for profile")
            } catch {
                print("⚠️ CloudKit: Could not stop sharing (might not be shared): \(error)")
            }
            
            // Delete all activities for this profile
            let activities = try await fetchActivities(for: profile.recordID)
            print("🗑️ CloudKit: Found \(activities.count) activities to delete for this profile")
            
            for activity in activities {
                do {
                    let activityRecord = try await privateDatabase.record(for: CKRecord.ID(recordName: activity.id.uuidString))
                    try await privateDatabase.deleteRecord(withID: activityRecord.recordID)
                    print("✅ CloudKit: Deleted activity: \(activity.type.rawValue)")
                } catch {
                    print("⚠️ CloudKit: Could not delete activity \(activity.id): \(error)")
                }
            }
            
            // Delete the profile record
            try await privateDatabase.deleteRecord(withID: profile.recordID)
            print("✅ CloudKit: Deleted baby profile record")
        }
        
        // Delete any remaining records by querying all record types
        print("🗑️ CloudKit: Checking for any remaining records...")
        
        // Query for any remaining Activity records
        let activityQuery = CKQuery(recordType: "Activity", predicate: NSPredicate(format: "createdBy == %@", userRecord.recordID))
        do {
            let (activityRecords, _) = try await privateDatabase.records(matching: activityQuery)
            print("🗑️ CloudKit: Found \(activityRecords.count) remaining activity records")
            for (recordID, result) in activityRecords {
                switch result {
                case .success(let record):
                    try await privateDatabase.deleteRecord(withID: record.recordID)
                    print("✅ CloudKit: Deleted remaining activity record")
                case .failure(let error):
                    print("⚠️ CloudKit: Could not fetch activity record \(recordID): \(error)")
                }
            }
        } catch {
            print("⚠️ CloudKit: Could not query remaining activities: \(error)")
        }
        
        // Query for any remaining BabyProfile records
        let profileQuery = CKQuery(recordType: "BabyProfile", predicate: NSPredicate(format: "createdBy == %@", userRecord.recordID))
        do {
            let (profileRecords, _) = try await privateDatabase.records(matching: profileQuery)
            print("🗑️ CloudKit: Found \(profileRecords.count) remaining profile records")
            for (recordID, result) in profileRecords {
                switch result {
                case .success(let record):
                    try await privateDatabase.deleteRecord(withID: record.recordID)
                    print("✅ CloudKit: Deleted remaining profile record")
                case .failure(let error):
                    print("⚠️ CloudKit: Could not fetch profile record \(recordID): \(error)")
                }
            }
        } catch {
            print("⚠️ CloudKit: Could not query remaining profiles: \(error)")
        }
        
        // Delete user record last
        try await privateDatabase.deleteRecord(withID: userRecord.recordID)
        print("✅ CloudKit: Deleted user record")
        
        // Clear all local data completely
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print("✅ CloudKit: Cleared all UserDefaults")
        
        // Reset CloudKit manager state
        await MainActor.run {
            self.isSignedIn = false
            self.familyMembers = []
            self.activeShare = nil
            self.syncStatus = .idle
        }
        
        print("🗑️ CloudKit: Account deletion completed - all iCloud data should be removed")
        
        // Small delay to ensure all cleanup is complete before notifying UI
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Notify app to show onboarding (single notification)
        await MainActor.run {
            print("📢 Account deleted - posting user_signed_out notification")
            NotificationCenter.default.post(name: .init("user_signed_out"), object: nil)
        }
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
