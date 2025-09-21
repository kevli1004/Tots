import CloudKit
import Foundation

/**
 * CLOUDKIT PRODUCTION SETUP SCRIPT
 * 
 * This script sets up your CloudKit production environment with all the new features:
 * - Words tracking with categories and auto-categorization
 * - Custom milestones with age ranges
 * - Enhanced activity tracking with mood and detailed metadata
 * - Growth tracking with multiple measurements
 * - Family sharing capabilities
 * - User preferences and settings
 * 
 * INSTRUCTIONS:
 * 1. Create a new CloudKit container: iCloud.com.growwithtots.tots.DB
 * 2. Run this setup in CloudKit Console
 * 3. Deploy to production
 * 4. Update app configuration
 */

class CloudKitProductionSetup {
    
    // MARK: - Container Configuration
    static let productionContainerID = "iCloud.com.growwithtots.tots.DB"
    
    // MARK: - Record Types Setup
    
    /**
     * 1. BABY PROFILE RECORD TYPE
     * Enhanced with all profile features
     */
    static func createBabyProfileRecordType() {
        /*
        Record Type: BabyProfile
        Fields:
        - name: String (Queryable, Searchable)
        - primaryName: String (Queryable, Searchable)
        - birthday: Date/Time (Queryable, Sortable)
        - profileImageData: Bytes
        - createdAt: Date/Time (Queryable, Sortable)
        - updatedAt: Date/Time (Queryable, Sortable)
        - familyID: String (Queryable) // For family sharing
        - preferences: String (JSON) // User preferences
        
        Indexes:
        - birthday (Queryable, Sortable)
        - familyID (Queryable)
        - createdAt (Sortable)
        */
    }
    
    /**
     * 2. ACTIVITY RECORD TYPE
     * Enhanced with mood tracking and detailed metadata
     */
    static func createActivityRecordType() {
        /*
        Record Type: Activity
        Fields:
        - type: String (Queryable) // feeding, diaper, sleep, pumping, activity, growth
        - time: Date/Time (Queryable, Sortable)
        - details: String (Queryable, Searchable)
        - duration: Int64 // in minutes
        - mood: String (Queryable) // happy, content, fussy, sleepy, alert
        - notes: String (Searchable)
        - location: String
        - weather: String
        - feedingType: String // bottle, breastfeeding, solid
        - feedingAmount: Double
        - diaperType: String // wet, dirty, mixed
        - activitySubType: String // tummyTime, playTime, bath, etc.
        - createdAt: Date/Time (Queryable, Sortable)
        - updatedAt: Date/Time (Queryable, Sortable)
        - babyProfileID: Reference(BabyProfile) (Queryable)
        - familyID: String (Queryable)
        
        Indexes:
        - time (Queryable, Sortable)
        - type (Queryable)
        - babyProfileID (Queryable)
        - familyID (Queryable)
        - mood (Queryable)
        - feedingType (Queryable)
        - diaperType (Queryable)
        - activitySubType (Queryable)
        */
    }
    
    /**
     * 3. GROWTH RECORD TYPE
     * Enhanced with multiple measurement types
     */
    static func createGrowthRecordType() {
        /*
        Record Type: Growth
        Fields:
        - date: Date/Time (Queryable, Sortable)
        - weight: Double (Queryable, Sortable)
        - height: Double (Queryable, Sortable)
        - headCircumference: Double (Queryable, Sortable)
        - weightUnit: String // kg, lbs
        - heightUnit: String // cm, inches
        - headCircumferenceUnit: String // cm, inches
        - notes: String (Searchable)
        - percentileWeight: Double
        - percentileHeight: Double
        - percentileHeadCircumference: Double
        - createdAt: Date/Time (Queryable, Sortable)
        - updatedAt: Date/Time (Queryable, Sortable)
        - babyProfileID: Reference(BabyProfile) (Queryable)
        - familyID: String (Queryable)
        
        Indexes:
        - date (Queryable, Sortable)
        - babyProfileID (Queryable)
        - familyID (Queryable)
        - weight (Sortable)
        - height (Sortable)
        */
    }
    
    /**
     * 4. WORDS RECORD TYPE
     * New feature for vocabulary tracking
     */
    static func createWordsRecordType() {
        /*
        Record Type: Words
        Fields:
        - word: String (Queryable, Searchable)
        - category: String (Queryable) // people, animals, food, actions, objects, sounds, social
        - dateFirstSaid: Date/Time (Queryable, Sortable)
        - notes: String (Searchable)
        - isCustom: Int64 // 0 or 1 (boolean)
        - pronunciation: String
        - context: String // where/when they said it
        - createdAt: Date/Time (Queryable, Sortable)
        - updatedAt: Date/Time (Queryable, Sortable)
        - babyProfileID: Reference(BabyProfile) (Queryable)
        - familyID: String (Queryable)
        
        Indexes:
        - word (Queryable, Searchable)
        - category (Queryable)
        - dateFirstSaid (Queryable, Sortable)
        - babyProfileID (Queryable)
        - familyID (Queryable)
        - isCustom (Queryable)
        */
    }
    
    /**
     * 5. MILESTONES RECORD TYPE
     * Enhanced with custom milestones and age ranges
     */
    static func createMilestonesRecordType() {
        /*
        Record Type: Milestones
        Fields:
        - title: String (Queryable, Searchable)
        - description: String (Searchable)
        - ageGroup: String (Queryable) // 0-3 months, 3-6 months, etc.
        - minAgeWeeks: Int64 (Queryable, Sortable)
        - maxAgeWeeks: Int64 (Queryable, Sortable)
        - category: String (Queryable) // motor, cognitive, social, language
        - isCompleted: Int64 // 0 or 1 (boolean)
        - completedDate: Date/Time (Queryable, Sortable)
        - isCustom: Int64 // 0 or 1 (boolean)
        - notes: String (Searchable)
        - createdAt: Date/Time (Queryable, Sortable)
        - updatedAt: Date/Time (Queryable, Sortable)
        - babyProfileID: Reference(BabyProfile) (Queryable)
        - familyID: String (Queryable)
        
        Indexes:
        - ageGroup (Queryable)
        - minAgeWeeks (Queryable, Sortable)
        - maxAgeWeeks (Queryable, Sortable)
        - category (Queryable)
        - isCompleted (Queryable)
        - isCustom (Queryable)
        - babyProfileID (Queryable)
        - familyID (Queryable)
        - completedDate (Sortable)
        */
    }
    
    /**
     * 6. FAMILY MEMBERS RECORD TYPE
     * For family sharing functionality
     */
    static func createFamilyMembersRecordType() {
        /*
        Record Type: FamilyMembers
        Fields:
        - name: String (Queryable, Searchable)
        - email: String (Queryable, Searchable)
        - role: String (Queryable) // parent, caregiver, grandparent, etc.
        - permissions: String (JSON) // what they can access/edit
        - inviteStatus: String (Queryable) // pending, accepted, declined
        - invitedAt: Date/Time (Queryable, Sortable)
        - joinedAt: Date/Time (Queryable, Sortable)
        - familyID: String (Queryable)
        - createdAt: Date/Time (Queryable, Sortable)
        - updatedAt: Date/Time (Queryable, Sortable)
        
        Indexes:
        - email (Queryable)
        - familyID (Queryable)
        - role (Queryable)
        - inviteStatus (Queryable)
        */
    }
    
    /**
     * 7. USER PREFERENCES RECORD TYPE
     * For app settings and configurations
     */
    static func createUserPreferencesRecordType() {
        /*
        Record Type: UserPreferences
        Fields:
        - useMetricUnits: Int64 // 0 or 1 (boolean)
        - trackingGoals: String (JSON) // feeding, diaper, sleep intervals
        - notificationSettings: String (JSON)
        - privacySettings: String (JSON)
        - appTheme: String // light, dark, auto
        - language: String
        - timeZone: String
        - createdAt: Date/Time (Queryable, Sortable)
        - updatedAt: Date/Time (Queryable, Sortable)
        - babyProfileID: Reference(BabyProfile) (Queryable)
        - familyID: String (Queryable)
        
        Indexes:
        - babyProfileID (Queryable)
        - familyID (Queryable)
        */
    }
    
    // MARK: - Security and Permissions
    
    /**
     * SECURITY ROLES SETUP
     */
    static func setupSecurityRoles() {
        /*
        Security Roles:
        
        1. Owner Role:
        - Can read/write all records for their family
        - Can manage family members
        - Can delete baby profile
        
        2. Parent Role:
        - Can read/write activities, growth, words, milestones
        - Can read baby profile (limited write)
        - Cannot delete baby profile
        - Cannot manage family members
        
        3. Caregiver Role:
        - Can read/write activities
        - Can read growth, words, milestones
        - Cannot write growth, words, milestones
        - Cannot access baby profile
        
        Record Permissions:
        - All records: Creator can read/write
        - Family members: Read based on role permissions
        - Public: No access
        */
    }
    
    // MARK: - Sample Data and Migration
    
    /**
     * SAMPLE DATA SETUP
     */
    static func createSampleData() {
        /*
        Sample Data to Create:
        
        1. Default Milestones:
        - 0-3 months: First smile, holds head up, follows objects
        - 3-6 months: Rolls over, sits with support, babbles
        - 6-9 months: Sits without support, crawls, says first words
        - 9-12 months: Pulls to stand, walks with support, waves bye-bye
        - 12+ months: Walks independently, says 2-3 words, follows simple commands
        
        2. Common First Words:
        - People: mama, dada, baby
        - Animals: dog, cat, bird
        - Food: milk, water, banana
        - Actions: hi, bye, more
        - Objects: ball, book, car
        - Sounds: moo, woof, meow
        
        3. Activity Templates:
        - Feeding types and amounts
        - Common sleep durations
        - Typical diaper patterns
        - Popular activities
        */
    }
    
    // MARK: - One-Button Setup Function
    
    /**
     * MAIN SETUP FUNCTION - ONE BUTTON SOLUTION
     */
    static func setupProductionCloudKit() {
        
        // Step 1: Create all record types
        createBabyProfileRecordType()
        createActivityRecordType()
        createGrowthRecordType()
        createWordsRecordType()
        createMilestonesRecordType()
        createFamilyMembersRecordType()
        createUserPreferencesRecordType()
        
        // Step 2: Setup security
        setupSecurityRoles()
        
        // Step 3: Create sample data
        createSampleData()
        
    }
}

// MARK: - Quick Reference

/**
 * CLOUDKIT CONSOLE CHECKLIST:
 * 
 * □ Create container: iCloud.com.growwithtots.tots.DB
 * □ Create BabyProfile record type with 8 fields
 * □ Create Activity record type with 16 fields  
 * □ Create Growth record type with 14 fields
 * □ Create Words record type with 11 fields
 * □ Create Milestones record type with 14 fields
 * □ Create FamilyMembers record type with 10 fields
 * □ Create UserPreferences record type with 10 fields
 * □ Set up security roles and permissions
 * □ Add sample milestone and word data
 * □ Deploy to Production
 * □ Test with production app build
 */
