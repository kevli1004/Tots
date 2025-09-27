import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitManager: ObservableObject {
    nonisolated static let shared = CloudKitManager()
    
    private let container = CKContainer(identifier: "iCloud.com.mytotsapp.tots.DB")
    let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    // Custom zone for shared records
    private let customZoneID = CKRecordZone.ID(zoneName: "TotsSharedZone", ownerName: CKCurrentUserDefaultName)
    
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
    
    // MARK: - Custom Zone Management
    
    private func createCustomZoneIfNeeded() async throws {
        do {
            // Try to fetch the zone first from private database
            _ = try await privateDatabase.recordZone(for: customZoneID)
            print("✅ Custom zone already exists in private database")
        } catch {
            // Zone doesn't exist, create it in private database
            let customZone = CKRecordZone(zoneID: customZoneID)
            _ = try await privateDatabase.save(customZone)
            print("✅ Created custom zone in private database: \(customZoneID.zoneName)")
        }
    }
    
    // MARK: - Baby Profile Management
    
    func createBabyProfile(name: String, birthDate: Date, goals: BabyGoals) async throws -> CKRecord {
        // First ensure user record exists
        let userRecord = try await getOrCreateUserRecord()
        
        // Create custom zone if needed (required for sharing)
        try await createCustomZoneIfNeeded()
        
        // Create record in custom zone (required for sharing)
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: customZoneID)
        let record = CKRecord(recordType: "BabyProfile", recordID: recordID)
        record["name"] = name
        record["birthDate"] = birthDate
        record["feedingGoal"] = goals.feeding
        record["sleepGoal"] = goals.sleep
        record["diaperGoal"] = goals.diaper
        record["createdBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        // Save to private database custom zone (shareable via CKShare)
        return try await privateDatabase.save(record)
    }
    
    func updateBabyProfile(_ record: CKRecord, name: String, birthDate: Date, goals: BabyGoals) async throws -> CKRecord {
        // Update the existing record
        record["name"] = name
        record["birthDate"] = birthDate
        record["feedingGoal"] = goals.feeding
        record["sleepGoal"] = goals.sleep
        record["diaperGoal"] = goals.diaper
        
        // Save to private database (records must be in private DB to be shareable)
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
        
        // Fetch from private database custom zone (where shareable records are created)
        let operation = CKQueryOperation(query: query)
        operation.zoneID = customZoneID
        operation.resultsLimit = 100 // Limit results for performance
        
        var profiles: [CKRecord] = []
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    profiles.append(record)
                case .failure(let error):
                    print("Error fetching profile record: \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.privateDatabase.add(operation)
        }
        
        return profiles
    }
    
    func fetchBabyProfile(recordID: CKRecord.ID) async throws -> CKRecord {
        // Try shared database first (if record is shared), then private database
        do {
            return try await sharedDatabase.record(for: recordID)
        } catch {
        return try await privateDatabase.record(for: recordID)
        }
    }
    
    // MARK: - Activity Management
    
    func saveActivity(_ activity: TotsActivity, to babyProfileID: CKRecord.ID) async throws {
        // Ensure user record exists
        let userRecord = try await getOrCreateUserRecord()
        
        // Create custom zone if needed (required for sharing)
        try await createCustomZoneIfNeeded()
        
        // Create activity record in custom zone (will be accessible via share)
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: customZoneID)
        let record = CKRecord(recordType: "Activity", recordID: recordID)
        record["type"] = activity.type.rawValue
        record["time"] = activity.time
        record["details"] = activity.details
        record["mood"] = activity.mood.rawValue
        record["duration"] = activity.duration
        record["notes"] = activity.notes
        record["weight"] = activity.weight
        record["height"] = activity.height
        record["headCircumference"] = activity.headCircumference
        record["createdAt"] = activity.createdAt
        record["modifiedAt"] = activity.modifiedAt
        record["createdBy"] = activity.createdBy
        record["modifiedBy"] = activity.modifiedBy
        record["activityID"] = activity.id.uuidString // Store the UUID for conflict resolution
        record["babyProfile"] = CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf)
        record["userCreatedBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        // Save to private database custom zone (shareable via CKShare to family members)
        print("💾 Saving activity to private database custom zone (shareable via CKShare for family access)")
        _ = try await privateDatabase.save(record)
    }
    
    func fetchActivities(for babyProfileID: CKRecord.ID) async throws -> [TotsActivity] {
        let reference = CKRecord.Reference(recordID: babyProfileID, action: .none)
        let predicate = NSPredicate(format: "babyProfile == %@", reference)
        let query = CKQuery(recordType: "Activity", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        
        // Fetch from private database custom zone (where records are created and shared via CKShare)
        print("📖 Fetching activities from private database custom zone (shareable via CKShare for family access)")
        
        let operation = CKQueryOperation(query: query)
        operation.zoneID = customZoneID
        operation.resultsLimit = 500 // Limit results for performance
        var activities: [TotsActivity] = []
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if let activity = self.convertToActivity(record) {
                        activities.append(activity)
                    }
                case .failure(let error):
                    print("Error fetching activity record: \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.privateDatabase.add(operation)
        }
        
        return activities
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
        
        // Create a new activity with proper initialization
        var activity = TotsActivity(
            type: type,
            time: time,
            details: details,
            mood: mood,
            duration: record["duration"] as? Int,
            notes: record["notes"] as? String,
            weight: record["weight"] as? Double,
            height: record["height"] as? Double,
            headCircumference: record["headCircumference"] as? Double,
            createdBy: record["createdBy"] as? String
        )
        
        // Override timestamps and modification info if available from CloudKit
        if let createdAt = record["createdAt"] as? Date {
            // We need to create a new instance with the CloudKit data
            // Since TotsActivity properties are immutable, we'll need to reconstruct it
            return TotsActivity(
                id: UUID(uuidString: record["activityID"] as? String ?? UUID().uuidString) ?? UUID(),
                type: type,
                time: time,
                details: details,
                mood: mood,
                duration: record["duration"] as? Int,
                notes: record["notes"] as? String,
                weight: record["weight"] as? Double,
                height: record["height"] as? Double,
                headCircumference: record["headCircumference"] as? Double,
                createdAt: createdAt,
                modifiedAt: record["modifiedAt"] as? Date ?? createdAt,
                createdBy: record["createdBy"] as? String,
                modifiedBy: record["modifiedBy"] as? String
            )
        }
        
        return activity
    }
    
    // MARK: - Growth Data Management
    
    func saveGrowthEntry(_ entry: GrowthEntry, to babyProfileID: CKRecord.ID) async throws {
        let userRecord = try await getOrCreateUserRecord()
        try await createCustomZoneIfNeeded()
        
        let recordID = CKRecord.ID(recordName: entry.id.uuidString, zoneID: customZoneID)
        let record = CKRecord(recordType: "GrowthEntry", recordID: recordID)
        record["date"] = entry.date
        record["weight"] = entry.weight
        record["height"] = entry.height
        record["headCircumference"] = entry.headCircumference
        record["babyProfile"] = CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf)
        record["createdBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        print("💾 Saving growth entry to CloudKit")
        _ = try await privateDatabase.save(record)
    }
    
    func fetchGrowthEntries(for babyProfileID: CKRecord.ID) async throws -> [GrowthEntry] {
        try await createCustomZoneIfNeeded()
        
        let predicate = NSPredicate(format: "babyProfile == %@", CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf))
        let query = CKQuery(recordType: "GrowthEntry", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.zoneID = customZoneID
        operation.resultsLimit = 500
        
        var entries: [GrowthEntry] = []
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if let entry = self.convertToGrowthEntry(record) {
                        entries.append(entry)
                    }
                case .failure(let error):
                    print("Error fetching growth entry: \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.privateDatabase.add(operation)
        }
        
        return entries
    }
    
    private func convertToGrowthEntry(_ record: CKRecord) -> GrowthEntry? {
        guard let date = record["date"] as? Date,
              let weight = record["weight"] as? Double,
              let height = record["height"] as? Double,
              let headCircumference = record["headCircumference"] as? Double else {
            return nil
        }
        
        return GrowthEntry(
            date: date,
            weight: weight,
            height: height,
            headCircumference: headCircumference
        )
    }
    
    // MARK: - Milestone Management
    
    func saveMilestone(_ milestone: Milestone, to babyProfileID: CKRecord.ID) async throws {
        let userRecord = try await getOrCreateUserRecord()
        try await createCustomZoneIfNeeded()
        
        let recordID = CKRecord.ID(recordName: milestone.id.uuidString, zoneID: customZoneID)
        let record = CKRecord(recordType: "Milestone", recordID: recordID)
        record["title"] = milestone.title
        record["isCompleted"] = milestone.isCompleted
        record["completedDate"] = milestone.completedDate
        record["minAgeWeeks"] = milestone.minAgeWeeks
        record["maxAgeWeeks"] = milestone.maxAgeWeeks
        record["category"] = milestone.category.rawValue
        record["description"] = milestone.description
        record["isPredefined"] = milestone.isPredefined
        record["babyProfile"] = CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf)
        record["createdBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        print("💾 Saving milestone to CloudKit")
        _ = try await privateDatabase.save(record)
    }
    
    func fetchMilestones(for babyProfileID: CKRecord.ID) async throws -> [Milestone] {
        try await createCustomZoneIfNeeded()
        
        let predicate = NSPredicate(format: "babyProfile == %@", CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf))
        let query = CKQuery(recordType: "Milestone", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "minAgeWeeks", ascending: true)]
        
        let operation = CKQueryOperation(query: query)
        operation.zoneID = customZoneID
        operation.resultsLimit = 500
        
        var milestones: [Milestone] = []
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if let milestone = self.convertToMilestone(record) {
                        milestones.append(milestone)
                    }
                case .failure(let error):
                    print("Error fetching milestone: \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.privateDatabase.add(operation)
        }
        
        return milestones
    }
    
    private func convertToMilestone(_ record: CKRecord) -> Milestone? {
        guard let title = record["title"] as? String,
              let isCompleted = record["isCompleted"] as? Bool,
              let minAgeWeeks = record["minAgeWeeks"] as? Int,
              let maxAgeWeeks = record["maxAgeWeeks"] as? Int,
              let categoryString = record["category"] as? String,
              let category = MilestoneCategory(rawValue: categoryString),
              let description = record["description"] as? String,
              let isPredefined = record["isPredefined"] as? Bool else {
            return nil
        }
        
        return Milestone(
            title: title,
            isCompleted: isCompleted,
            completedDate: record["completedDate"] as? Date,
            minAgeWeeks: minAgeWeeks,
            maxAgeWeeks: maxAgeWeeks,
            category: category,
            description: description,
            isPredefined: isPredefined
        )
    }
    
    // MARK: - Words Management
    
    func saveBabyWord(_ word: BabyWord, to babyProfileID: CKRecord.ID) async throws {
        let userRecord = try await getOrCreateUserRecord()
        try await createCustomZoneIfNeeded()
        
        let recordID = CKRecord.ID(recordName: word.id.uuidString, zoneID: customZoneID)
        let record = CKRecord(recordType: "BabyWord", recordID: recordID)
        record["word"] = word.word
        record["category"] = word.category.rawValue
        record["dateFirstSaid"] = word.dateFirstSaid
        record["notes"] = word.notes
        record["babyProfile"] = CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf)
        record["createdBy"] = CKRecord.Reference(recordID: userRecord.recordID, action: .none)
        
        print("💾 Saving baby word to CloudKit")
        _ = try await privateDatabase.save(record)
    }
    
    func fetchBabyWords(for babyProfileID: CKRecord.ID) async throws -> [BabyWord] {
        try await createCustomZoneIfNeeded()
        
        let predicate = NSPredicate(format: "babyProfile == %@", CKRecord.Reference(recordID: babyProfileID, action: .deleteSelf))
        let query = CKQuery(recordType: "BabyWord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "dateFirstSaid", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.zoneID = customZoneID
        operation.resultsLimit = 500
        
        var words: [BabyWord] = []
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if let word = self.convertToBabyWord(record) {
                        words.append(word)
                    }
                case .failure(let error):
                    print("Error fetching baby word: \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.privateDatabase.add(operation)
        }
        
        return words
    }
    
    private func convertToBabyWord(_ record: CKRecord) -> BabyWord? {
        guard let word = record["word"] as? String,
              let categoryString = record["category"] as? String,
              let category = WordCategory(rawValue: categoryString),
              let dateFirstSaid = record["dateFirstSaid"] as? Date,
              let notes = record["notes"] as? String else {
            return nil
        }
        
        return BabyWord(
            word: word,
            category: category,
            dateFirstSaid: dateFirstSaid,
            notes: notes
        )
    }
    
    // MARK: - Family Sharing
    
    func shareBabyProfile(_ profileRecord: CKRecord) async throws -> CKShare {
        print("🔗 Starting to share baby profile: \(profileRecord.recordID)")
        
        // Check if the record already has a share reference
        if let shareReference = profileRecord.share {
            print("🔗 Record has share reference, fetching actual share...")
            do {
                let shareRecord = try await privateDatabase.record(for: shareReference.recordID)
                if let existingShare = shareRecord as? CKShare {
                    print("✅ Found existing share, using it")
                    await setActiveShare(existingShare)
                    return existingShare
                }
            } catch {
                print("⚠️ Failed to fetch existing share: \(error), creating new one")
            }
        }
        
        // Create a new share for the record
        let share = CKShare(rootRecord: profileRecord)
        share[CKShare.SystemFieldKey.title] = "Tots Baby Tracker"
        share.publicPermission = .readWrite  // Allow read/write access for family members
        
        // Save both records in the same operation (required by CloudKit)
        let operation = CKModifyRecordsOperation(recordsToSave: [profileRecord, share], recordIDsToDelete: nil)
        operation.savePolicy = .allKeys
        operation.qualityOfService = .userInitiated
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    print("✅ Successfully saved baby profile and share")
                    continuation.resume()
                case .failure(let error):
                    print("❌ Failed to save baby profile and share: \(error)")
                    continuation.resume(throwing: error)
                }
            }
            
            self.privateDatabase.add(operation)
        }
        
        // Set the active share
        await setActiveShare(share)
        
        print("🔗 Baby profile shared successfully")
        return share
    }
    
    func fetchSharedProfiles() async throws -> [CKRecord] {
        // Query shared profiles that the user has access to
        let query = CKQuery(recordType: "BabyProfile", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "birthDate", ascending: false)]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 50 // Limit results for performance
        
        var profiles: [CKRecord] = []
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    profiles.append(record)
                case .failure(let error):
                    print("Error fetching shared profile record: \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.sharedDatabase.add(operation)
        }
        
        return profiles
    }
    
    func stopSharingProfile(_ profileRecord: CKRecord) async throws {
        // For now, just mark as not shared locally
        // CloudKit will handle the actual share removal
    }
    
    func revokeFamilyMemberAccess(_ member: FamilyMember, from share: CKShare) async throws {
        // Find the participant to remove
        guard let participantToRemove = share.participants.first(where: { participant in
            participant.userIdentity.userRecordID?.recordName == member.participantID
        }) else {
            throw CloudKitError.userNotFound
        }
        
        // Remove the participant from the share
        share.removeParticipant(participantToRemove)
        
        // Save the updated share
        _ = try await privateDatabase.save(share)
        
        print("✅ Revoked access for family member: \(member.name)")
    }
    
    func fetchFamilyMembers(for share: CKShare) async throws -> [FamilyMember] {
        var members: [FamilyMember] = []
        
        // Add owner
        let ownerParticipant = share.owner
        let member = FamilyMember(
            name: ownerParticipant.userIdentity.nameComponents?.formatted() ?? "Owner",
            email: ownerParticipant.userIdentity.lookupInfo?.emailAddress ?? "",
            role: .owner,
            permission: .readWrite,
            acceptanceStatus: .accepted,
            participantID: ownerParticipant.userIdentity.userRecordID?.recordName ?? ""
        )
        members.append(member)
        
        // Add participants
        for participant in share.participants {
            if participant != ownerParticipant {
                let member = FamilyMember(
                    name: participant.userIdentity.nameComponents?.formatted() ?? "Family Member",
                    email: participant.userIdentity.lookupInfo?.emailAddress ?? "",
                    role: participant.role,
                    permission: participant.permission,
                    acceptanceStatus: participant.acceptanceStatus,
                    participantID: participant.userIdentity.userRecordID?.recordName ?? ""
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
        // Query for shares in the shared database
        let query = CKQuery(recordType: "cloudkit.share", predicate: NSPredicate(value: true))
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 10 // Limit results for performance
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if let share = record as? CKShare {
                        Task { @MainActor in
                            await self.setActiveShare(share)
                        }
                    }
                case .failure(let error):
                    print("Error fetching share record: \(error)")
                }
            }
            
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            self.sharedDatabase.add(operation)
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
        UserDefaults.standard.set(true, forKey: "local_storage_only")
        UserDefaults.standard.set(false, forKey: "onboarding_completed")
        
        // Notify app to show onboarding
        await MainActor.run {
            NotificationCenter.default.post(name: .init("user_signed_out"), object: nil)
        }
    }
    
    func deleteAllData() async throws {
        print("🗑️ Deleting all CloudKit data...")
        
        // Create custom zone if needed
        try await createCustomZoneIfNeeded()
        
        // Delete all records in the custom zone
        let recordTypes = ["BabyProfile", "Activity", "GrowthEntry", "Milestone", "BabyWord"]
        
        for recordType in recordTypes {
            do {
                let predicate = NSPredicate(value: true) // Match all records
                let query = CKQuery(recordType: recordType, predicate: predicate)
                
                let operation = CKQueryOperation(query: query)
                operation.zoneID = customZoneID
                operation.resultsLimit = 500
                
                var recordsToDelete: [CKRecord.ID] = []
                
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    operation.recordMatchedBlock = { recordID, result in
                        switch result {
                        case .success(let record):
                            recordsToDelete.append(record.recordID)
                        case .failure(let error):
                            print("Error fetching record for deletion: \(error)")
                        }
                    }
                    
                    operation.queryResultBlock = { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    self.privateDatabase.add(operation)
                }
                
                // Delete records in batches
                if !recordsToDelete.isEmpty {
                    let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordsToDelete)
                    deleteOperation.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
                        if let error = error {
                            print("❌ Error deleting \(recordType) records: \(error)")
                        } else {
                            print("✅ Deleted \(deletedRecordIDs?.count ?? 0) \(recordType) records")
                        }
                    }
                    
                    try await privateDatabase.add(deleteOperation)
                }
                
            } catch {
                print("❌ Error deleting \(recordType) records: \(error)")
                // Continue with other record types even if one fails
            }
        }
        
        print("✅ CloudKit data deletion completed")
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
    let acceptanceStatus: CKShare.ParticipantAcceptanceStatus
    let participantID: String
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
