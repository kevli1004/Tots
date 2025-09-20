import Foundation
import SwiftUI
import ActivityKit
import CloudKit

class TotsDataManager: ObservableObject {
    // MARK: - Storage Keys
    private let activitiesKey = "tots_activities"
    private let milestonesKey = "tots_milestones"
    private let growthDataKey = "tots_growth_data"
    private let wordsKey = "tots_words"
    private let babyNameKey = "tots_baby_name"
    private let babyBirthDateKey = "tots_baby_birth_date"
    private let weeklyGoalsKey = "tots_weekly_goals"
    private var countdownTimer: Timer?
    // MARK: - Smart Analytics
    @Published var aiInsights: [AIInsight] = []
    @Published var predictedNextActivity: ActivityType?
    @Published var sleepPatterns: [SleepPattern] = []
    @Published var feedingEfficiency: Double = 0.85
    @Published var developmentScore: Int = 78
    
    // Growth percentile data
    var currentBMI: Double {
        guard let latestGrowth = growthData.last else { return 0.0 }
        let weightKg = convertWeightToKg(latestGrowth.weight)
        let heightM = convertHeightToCm(latestGrowth.height) / 100.0
        return weightKg / (heightM * heightM)
    }
    
    var currentWeight: Double {
        return growthData.last?.weight ?? 0.0
    }
    
    var currentHeight: Double {
        return growthData.last?.height ?? 0.0
    }
    
    var currentHeadCircumference: Double {
        return growthData.last?.headCircumference ?? 0.0
    }
    @Published var healthTrends: [HealthTrend] = []
    
    // CloudKit
    @Published var familySharingEnabled: Bool = false
    @Published var babyProfileRecord: CKRecord?
    let cloudKitManager = CloudKitManager.shared
    private let schemaSetup = CloudKitSchemaSetup.shared
    
    // App State Management
    @Published var shouldShowOnboarding: Bool = false
    
    // Live Activity
    @Published var currentActivity: Activity<TotsLiveActivityAttributes>?
    @Published var widgetEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(widgetEnabled, forKey: "widget_enabled")
        }
    }
    
    // Units preference
    @Published var useMetricUnits: Bool = true {
        didSet {
            UserDefaults.standard.set(useMetricUnits, forKey: "use_metric_units")
        }
    }
    
    @Published var babyName: String = "" {
        didSet {
            UserDefaults.standard.set(babyName, forKey: babyNameKey)
        }
    }
    @Published var babyBirthDate: Date = {
        // Default to 8 weeks ago for demo purposes
        Calendar.current.date(byAdding: .weekOfYear, value: -8, to: Date()) ?? Date()
    }() {
        didSet {
            UserDefaults.standard.set(babyBirthDate, forKey: babyBirthDateKey)
        }
    }
    @Published var streakCount: Int = 0
    @Published var totalActivitiesLogged: Int = 0
    
    // MARK: - Countdown Timers
    @Published var nextFeedingCountdown: TimeInterval = 0
    @Published var nextDiaperCountdown: TimeInterval = 0
    @Published var nextFeedingTime: Date?
    @Published var nextDiaperTime: Date?
    
    // Today's tracking data
    @Published var todayFeedings: Int = 7
    @Published var todayDiapers: Int = 5
    @Published var todaySleepHours: Double = 14.2
    @Published var todayMilestones: Int = 1
    @Published var todayTummyTime: Int = 45 // minutes
    @Published var todayPlayTime: Int = 120 // minutes
    
    // Weekly goals
    @Published var weeklyFeedingGoal: Int = 56 // 8 per day
    @Published var weeklyDiaperGoal: Int = 42 // 6 per day
    @Published var weeklySleepGoal: Double = 105.0 // 15 hours per day
    @Published var weeklyTummyTimeGoal: Int = 350 // 50 minutes per day
    
    // Recent activities - loaded from storage
    @Published var recentActivities: [TotsActivity] = [] {
        didSet {
            saveActivities()
        }
    }
    
    // Weekly progress data - calculated from real activities
    @Published var weeklyData: [DayData] = []
    
    // Milestones - loaded from storage
    @Published var milestones: [Milestone] = [] {
        didSet {
            saveMilestones()
        }
    }
    
    // Growth tracking - loaded from storage
    @Published var growthData: [GrowthEntry] = [] {
        didSet {
            saveGrowthData()
        }
    }
    
    // Word tracking - loaded from storage
    @Published var words: [BabyWord] = [] {
        didSet {
            saveWords()
        }
    }
    
    var wordCount: Int {
        return words.count
    }
    
    var wordsByCategory: [WordCategory: [BabyWord]] {
        return Dictionary(grouping: words) { $0.category }
    }
    
    // Top 500+ baby/kid words organized by category for autocomplete and auto-categorization
    let commonBabyWords: [WordCategory: [String]] = [
        .people: [
            "mama", "dada", "papa", "baby", "mommy", "daddy", "grandma", "grandpa", "nana", "pop",
            "sister", "brother", "family", "me", "you", "name", "boy", "girl", "friend", "person",
            "lady", "man", "kid", "child", "aunt", "uncle", "cousin", "neighbor", "teacher", "doctor",
            "nurse", "mom", "dad", "granny", "grampa", "mimi", "gigi", "nanny",
            "babysitter", "stranger", "visitor", "guest", "everyone", "somebody", "nobody", "anybody"
        ],
        .animals: [
            "dog", "cat", "cow", "duck", "fish", "bird", "horse", "pig", "sheep", "chicken",
            "bear", "lion", "tiger", "elephant", "monkey", "rabbit", "mouse", "frog", "bee", "butterfly",
            "snake", "turtle", "owl", "fox", "deer", "squirrel", "puppy", "kitty", "bunny", "doggy",
            "zebra", "giraffe", "hippo", "rhino", "kangaroo", "penguin", "dolphin", "whale", "shark",
            "octopus", "crab", "lobster", "spider", "ant", "fly", "ladybug", "worm", "snail", "slug",
            "goat", "llama", "donkey", "camel", "peacock", "parrot", "robin", "eagle", "hawk", "crow"
        ],
        .food: [
            "milk", "water", "cookie", "banana", "apple", "more", "eat", "drink", "hungry", "bottle",
            "cup", "spoon", "bowl", "plate", "bread", "cheese", "crackers", "juice", "snack", "dinner",
            "breakfast", "lunch", "hot", "cold", "sweet", "yummy", "orange", "grape", "berry", "cake",
            "ice cream", "pizza", "pasta", "soup", "sandwich", "toast", "cereal", "yogurt", "eggs",
            "meat", "vegetables", "carrots", "peas", "corn", "broccoli", "potato",
            "rice", "noodles", "spaghetti", "hamburger", "hotdog", "french fries", "chips", "popcorn",
            "candy", "chocolate", "gum", "lollipop", "popsicle", "jelly", "jam", "honey", "sugar",
            "salt", "ketchup", "mustard", "mayonnaise", "butter", "cream", "strawberry", "blueberry"
        ],
        .actions: [
            "go", "up", "down", "stop", "come", "sit", "stand", "walk", "run", "jump", "dance",
            "play", "look", "see", "watch", "listen", "hear", "touch", "hold", "give", "take",
            "put", "get", "open", "close", "push", "pull", "throw", "catch", "kick", "hug",
            "kiss", "sleep", "wake", "wash", "brush", "clean", "help", "work", "read", "sing",
            "talk", "say", "tell", "ask", "answer", "call", "shout", "whisper", "laugh", "cry",
            "smile", "frown", "wink", "blink", "nod", "shake", "wave", "clap", "snap", "point",
            "crawl", "climb", "slide", "swing", "ride", "drive", "fly", "swim", "float", "sink",
            "build", "make", "draw", "paint", "color", "cut", "paste", "fold", "tear", "fix"
        ],
        .objects: [
            "ball", "book", "car", "shoe", "toy", "hat", "shirt", "pants", "sock",
            "diaper", "blanket", "pillow", "bed", "chair", "table", "door", "window", "phone", "keys",
            "bag", "box", "pacifier", "blocks", "doll", "truck", "train", "plane", "bike",
            "swing", "slide", "sandbox", "bubble", "music", "tv", "computer", "camera", "watch", "glasses",
            "house", "home", "room", "kitchen", "bathroom", "bedroom", "living room", "garage", "yard",
            "tree", "flower", "grass", "sun", "moon", "star", "cloud", "rain", "snow", "wind",
            "light", "lamp", "candle", "fire", "pool", "ocean", "lake", "river", "mountain",
            "road", "street", "sidewalk", "bridge", "building", "store", "school", "park", "playground"
        ],
        .feelings: [
            "happy", "sad", "mad", "love", "good", "bad", "nice", "pretty", "beautiful", "funny",
            "scared", "brave", "excited", "tired", "sleepy", "awake", "hungry", "full", "thirsty", "hurt",
            "better", "sick", "well", "fine", "okay", "great", "wonderful", "amazing", "surprised", "proud",
            "angry", "upset", "worried", "nervous", "calm", "peaceful", "comfortable", "uncomfortable",
            "warm", "cool", "hot", "cold", "wet", "dry", "clean", "dirty", "soft", "hard",
            "smooth", "rough", "sharp", "dull", "bright", "dark", "loud", "quiet", "fast", "slow"
        ],
        .sounds: [
            "wow", "oh", "uh-oh", "shh", "boom", "beep", "pop", "bang", "crash", "splash",
            "meow", "woof", "moo", "quack", "roar", "chirp", "buzz", "hiss", "oink", "baa",
            "neigh", "trumpet", "honk", "ring", "tick", "tock", "whoosh", "zoom", "vroom", "choo-choo",
            "ding", "dong", "clang", "clunk", "thud", "thump", "knock", "tap", "click", "snap",
            "crackle", "sizzle", "bubble", "gurgle", "slurp", "gulp", "burp", "hiccup", "sneeze", "cough",
            "achoo", "bless you", "excuse me", "pardon", "sorry", "oops", "ouch", "ow", "yay", "hooray"
        ],
        .colors: [
            "red", "blue", "yellow", "green", "purple", "pink", "orange", "black", "white", "brown",
            "gray", "grey", "gold", "silver", "rainbow", "bright", "dark", "light", "colorful"
        ],
        .shapes: [
            "round", "square", "circle", "triangle", "rectangle", "oval", "star", "heart", "diamond",
            "straight", "curved", "big", "little", "small", "tall", "short", "long", "wide", "thin", "thick"
        ],
        .numbers: [
            "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
            "eleven", "twelve", "hundred", "zero", "first", "last", "many", "all", "some", "none"
        ],
        .bodyParts: [
            "head", "hair", "face", "eyes", "nose", "mouth", "ears", "teeth", "tongue", "chin",
            "neck", "shoulders", "arms", "hands", "fingers", "thumb", "legs", "feet", "toes", "belly",
            "back", "knee", "elbow", "wrist", "ankle", "cheek", "forehead", "eyebrow", "lip"
        ],
        .clothes: [
            "shirt", "pants", "dress", "skirt", "shoes", "socks", "hat", "coat", "jacket", "sweater",
            "pajamas", "underwear", "diaper", "mittens", "gloves", "scarf", "boots", "sandals", "belt"
        ],
        .places: [
            "here", "there", "inside", "outside", "up", "down", "top", "bottom", "middle", "corner",
            "home", "house", "room", "kitchen", "bathroom", "bedroom", "park", "store", "school",
            "playground", "beach", "garden", "yard", "street"
        ],
        .transportation: [
            "car", "truck", "bus", "train", "plane", "boat", "bike", "motorcycle", "helicopter",
            "taxi", "fire truck", "police car", "school bus", "van", "ship", "rocket", "scooter"
        ],
        .other: [
            "yes", "no", "please", "thank you", "help", "mine", "yours", "this", "that",
            "where", "what", "who", "when", "why", "how", "again", "more", "done", "finished", "ready",
            "in", "on", "under", "over", "beside", "behind", "front", "back", "left", "right", "edge", "center",
            "today", "tomorrow", "yesterday", "now", "later", "soon", "never", "always", "sometimes"
        ]
    ]
    
    // Flattened word list for quick lookup and auto-categorization
    private lazy var allWordsWithCategories: [(word: String, category: WordCategory)] = {
        var result: [(String, WordCategory)] = []
        for (category, words) in commonBabyWords {
            for word in words {
                result.append((word.lowercased(), category))
            }
        }
        return result.sorted(by: { $0.0 < $1.0 })
    }()
    
    // Comprehensive predefined milestones based on AAP, CDC, and WHO guidelines
    private let predefinedMilestones: [Milestone] = [
        // BIRTH TO 2 MONTHS
        Milestone(title: "Lifts head briefly", minAgeWeeks: 0, maxAgeWeeks: 4, category: .motor, description: "Lifts head briefly during tummy time", isPredefined: true),
        Milestone(title: "Startles at loud sounds", minAgeWeeks: 0, maxAgeWeeks: 2, category: .sensory, description: "Shows startle reflex to sudden noises", isPredefined: true),
        Milestone(title: "Focuses on faces", minAgeWeeks: 0, maxAgeWeeks: 4, category: .sensory, description: "Looks at faces, especially parent's face", isPredefined: true),
        Milestone(title: "Makes quiet sounds", minAgeWeeks: 2, maxAgeWeeks: 6, category: .language, description: "Makes soft grunting or cooing sounds", isPredefined: true),
        Milestone(title: "Calms when comforted", minAgeWeeks: 0, maxAgeWeeks: 4, category: .social, description: "Calms down when picked up or spoken to", isPredefined: true),
        Milestone(title: "Sleeps 14-17 hours daily", minAgeWeeks: 0, maxAgeWeeks: 8, category: .sleep, description: "Sleeps in short periods throughout day and night", isPredefined: true),
        
        // 2-4 MONTHS
        Milestone(title: "First social smile", minAgeWeeks: 4, maxAgeWeeks: 10, category: .social, description: "Smiles in response to your voice or face", isPredefined: true),
        Milestone(title: "Holds head steady", minAgeWeeks: 6, maxAgeWeeks: 12, category: .motor, description: "Holds head steady when upright", isPredefined: true),
        Milestone(title: "Follows objects with eyes", minAgeWeeks: 6, maxAgeWeeks: 12, category: .sensory, description: "Tracks moving objects with eyes", isPredefined: true),
        Milestone(title: "Makes cooing sounds", minAgeWeeks: 6, maxAgeWeeks: 14, category: .language, description: "Makes happy cooing and gurgling sounds", isPredefined: true),
        Milestone(title: "Brings hands to mouth", minAgeWeeks: 6, maxAgeWeeks: 12, category: .motor, description: "Brings hands to mouth and may suck on them", isPredefined: true),
        Milestone(title: "Pushes up on forearms", minAgeWeeks: 8, maxAgeWeeks: 16, category: .motor, description: "Pushes up on forearms during tummy time", isPredefined: true),
        
        // 4-6 MONTHS
        Milestone(title: "Laughs out loud", minAgeWeeks: 12, maxAgeWeeks: 20, category: .social, description: "Giggles and laughs in response to play", isPredefined: true),
        Milestone(title: "Reaches for toys", minAgeWeeks: 12, maxAgeWeeks: 20, category: .motor, description: "Reaches for and grasps toys", isPredefined: true),
        Milestone(title: "Rolls from tummy to back", minAgeWeeks: 14, maxAgeWeeks: 24, category: .motor, description: "Rolls over from tummy to back", isPredefined: true),
        Milestone(title: "Sits with support", minAgeWeeks: 16, maxAgeWeeks: 24, category: .motor, description: "Sits with support from pillows or hands", isPredefined: true),
        Milestone(title: "Babbles with consonants", minAgeWeeks: 16, maxAgeWeeks: 28, category: .language, description: "Makes sounds like 'ba', 'ma', 'da'", isPredefined: true),
        Milestone(title: "Puts everything in mouth", minAgeWeeks: 16, maxAgeWeeks: 32, category: .sensory, description: "Explores objects by mouthing them", isPredefined: true),
        Milestone(title: "Shows curiosity", minAgeWeeks: 16, maxAgeWeeks: 24, category: .cognitive, description: "Shows interest in surroundings", isPredefined: true),
        Milestone(title: "Ready for solid foods", minAgeWeeks: 17, maxAgeWeeks: 26, category: .feeding, description: "Shows signs of readiness for first foods", isPredefined: true),
        
        // 6-9 MONTHS
        Milestone(title: "Sits without support", minAgeWeeks: 24, maxAgeWeeks: 36, category: .motor, description: "Sits independently without falling", isPredefined: true),
        Milestone(title: "Crawls or scoots", minAgeWeeks: 28, maxAgeWeeks: 40, category: .motor, description: "Moves around by crawling, scooting, or rolling", isPredefined: true),
        Milestone(title: "Transfers objects", minAgeWeeks: 24, maxAgeWeeks: 32, category: .motor, description: "Passes objects from one hand to the other", isPredefined: true),
        Milestone(title: "Says 'mama' or 'dada'", minAgeWeeks: 28, maxAgeWeeks: 44, category: .language, description: "Says first words (may not be specific)", isPredefined: true),
        Milestone(title: "Responds to name", minAgeWeeks: 24, maxAgeWeeks: 36, category: .language, description: "Looks when you call their name", isPredefined: true),
        Milestone(title: "Shows stranger anxiety", minAgeWeeks: 24, maxAgeWeeks: 40, category: .social, description: "May be wary of strangers", isPredefined: true),
        Milestone(title: "Plays peek-a-boo", minAgeWeeks: 28, maxAgeWeeks: 40, category: .social, description: "Enjoys and participates in peek-a-boo", isPredefined: true),
        Milestone(title: "Looks for dropped objects", minAgeWeeks: 28, maxAgeWeeks: 40, category: .cognitive, description: "Understands object permanence", isPredefined: true),
        Milestone(title: "Eats finger foods", minAgeWeeks: 32, maxAgeWeeks: 44, category: .feeding, description: "Self-feeds with finger foods", isPredefined: true),
        
        // 9-12 MONTHS
        Milestone(title: "Pulls to standing", minAgeWeeks: 36, maxAgeWeeks: 48, category: .motor, description: "Pulls themselves up to standing", isPredefined: true),
        Milestone(title: "Cruises along furniture", minAgeWeeks: 40, maxAgeWeeks: 52, category: .motor, description: "Walks holding onto furniture", isPredefined: true),
        Milestone(title: "Pincer grasp", minAgeWeeks: 36, maxAgeWeeks: 48, category: .motor, description: "Picks up small objects with thumb and finger", isPredefined: true),
        Milestone(title: "Waves bye-bye", minAgeWeeks: 36, maxAgeWeeks: 48, category: .social, description: "Waves hand to say goodbye", isPredefined: true),
        Milestone(title: "Imitates sounds", minAgeWeeks: 36, maxAgeWeeks: 52, category: .language, description: "Copies sounds and simple words", isPredefined: true),
        Milestone(title: "Understands 'no'", minAgeWeeks: 36, maxAgeWeeks: 48, category: .language, description: "Responds to the word 'no'", isPredefined: true),
        Milestone(title: "Shows preferences", minAgeWeeks: 36, maxAgeWeeks: 52, category: .social, description: "Shows clear preferences for people and toys", isPredefined: true),
        Milestone(title: "Drinks from cup", minAgeWeeks: 40, maxAgeWeeks: 60, category: .feeding, description: "Drinks from sippy cup with help", isPredefined: true),
        
        // 12-15 MONTHS
        Milestone(title: "First steps", minAgeWeeks: 48, maxAgeWeeks: 72, category: .motor, description: "Takes first independent steps", isPredefined: true),
        Milestone(title: "Says first words", minAgeWeeks: 44, maxAgeWeeks: 68, category: .language, description: "Uses words meaningfully (mama, dada, etc.)", isPredefined: true),
        Milestone(title: "Points at objects", minAgeWeeks: 48, maxAgeWeeks: 64, category: .language, description: "Points to show you things", isPredefined: true),
        Milestone(title: "Stacks 2 blocks", minAgeWeeks: 52, maxAgeWeeks: 68, category: .cognitive, description: "Stacks 2 blocks on top of each other", isPredefined: true),
        Milestone(title: "Shows affection", minAgeWeeks: 48, maxAgeWeeks: 68, category: .social, description: "Gives hugs and kisses", isPredefined: true),
        Milestone(title: "Uses spoon", minAgeWeeks: 52, maxAgeWeeks: 78, category: .feeding, description: "Attempts to use spoon to self-feed", isPredefined: true),
        Milestone(title: "Sleeps through night", minAgeWeeks: 24, maxAgeWeeks: 78, category: .sleep, description: "Sleeps 6+ hours without waking", isPredefined: true),
        
        // 15-18 MONTHS
        Milestone(title: "Walks independently", minAgeWeeks: 52, maxAgeWeeks: 78, category: .motor, description: "Walks without support", isPredefined: true),
        Milestone(title: "Climbs stairs with help", minAgeWeeks: 60, maxAgeWeeks: 84, category: .motor, description: "Climbs stairs with one hand held", isPredefined: true),
        Milestone(title: "Says 3-5 words", minAgeWeeks: 60, maxAgeWeeks: 78, category: .language, description: "Uses 3-5 words regularly", isPredefined: true),
        Milestone(title: "Follows simple commands", minAgeWeeks: 60, maxAgeWeeks: 78, category: .language, description: "Follows one-step instructions", isPredefined: true),
        Milestone(title: "Imitates activities", minAgeWeeks: 60, maxAgeWeeks: 78, category: .cognitive, description: "Imitates household activities", isPredefined: true),
        Milestone(title: "Shows independence", minAgeWeeks: 60, maxAgeWeeks: 84, category: .social, description: "Wants to do things independently", isPredefined: true),
        
        // 18-24 MONTHS
        Milestone(title: "Runs steadily", minAgeWeeks: 72, maxAgeWeeks: 96, category: .motor, description: "Runs without falling frequently", isPredefined: true),
        Milestone(title: "Kicks a ball", minAgeWeeks: 78, maxAgeWeeks: 104, category: .motor, description: "Kicks ball forward while walking", isPredefined: true),
        Milestone(title: "Walks up stairs", minAgeWeeks: 78, maxAgeWeeks: 104, category: .motor, description: "Walks up stairs with support", isPredefined: true),
        Milestone(title: "Says 50+ words", minAgeWeeks: 78, maxAgeWeeks: 104, category: .language, description: "Uses 50 or more words", isPredefined: true),
        Milestone(title: "Two-word phrases", minAgeWeeks: 78, maxAgeWeeks: 104, category: .language, description: "Combines words like 'more milk'", isPredefined: true),
        Milestone(title: "Pretend play", minAgeWeeks: 72, maxAgeWeeks: 96, category: .cognitive, description: "Pretends to feed dolls, talk on phone", isPredefined: true),
        Milestone(title: "Sorts shapes", minAgeWeeks: 84, maxAgeWeeks: 104, category: .cognitive, description: "Sorts objects by shape or color", isPredefined: true),
        Milestone(title: "Plays alongside others", minAgeWeeks: 78, maxAgeWeeks: 104, category: .social, description: "Plays near other children", isPredefined: true),
        Milestone(title: "Uses fork", minAgeWeeks: 78, maxAgeWeeks: 104, category: .feeding, description: "Uses fork to eat", isPredefined: true),
        
        // 2-3 YEARS
        Milestone(title: "Jumps with both feet", minAgeWeeks: 96, maxAgeWeeks: 130, category: .motor, description: "Jumps off ground with both feet", isPredefined: true),
        Milestone(title: "Pedals tricycle", minAgeWeeks: 104, maxAgeWeeks: 156, category: .motor, description: "Pedals tricycle or ride-on toy", isPredefined: true),
        Milestone(title: "Throws ball overhand", minAgeWeeks: 104, maxAgeWeeks: 130, category: .motor, description: "Throws ball overhand", isPredefined: true),
        Milestone(title: "Three-word sentences", minAgeWeeks: 104, maxAgeWeeks: 130, category: .language, description: "Uses sentences with 3+ words", isPredefined: true),
        Milestone(title: "Asks 'what' questions", minAgeWeeks: 104, maxAgeWeeks: 130, category: .language, description: "Asks simple questions", isPredefined: true),
        Milestone(title: "Names body parts", minAgeWeeks: 104, maxAgeWeeks: 130, category: .language, description: "Names several body parts", isPredefined: true),
        Milestone(title: "Counts to 3", minAgeWeeks: 104, maxAgeWeeks: 156, category: .cognitive, description: "Can count to 3", isPredefined: true),
        Milestone(title: "Plays with other children", minAgeWeeks: 104, maxAgeWeeks: 156, category: .social, description: "Engages in cooperative play", isPredefined: true),
        Milestone(title: "Shows potty interest", minAgeWeeks: 104, maxAgeWeeks: 208, category: .physical, description: "Shows interest in potty training", isPredefined: true),
        Milestone(title: "Brushes teeth with help", minAgeWeeks: 104, maxAgeWeeks: 156, category: .physical, description: "Brushes teeth with assistance", isPredefined: true),
        
        // PHYSICAL MILESTONES
        Milestone(title: "First tooth", minAgeWeeks: 24, maxAgeWeeks: 52, category: .physical, description: "First tooth appears", isPredefined: true),
        Milestone(title: "8 teeth", minAgeWeeks: 40, maxAgeWeeks: 78, category: .physical, description: "Has about 8 teeth", isPredefined: true),
        Milestone(title: "16 teeth", minAgeWeeks: 78, maxAgeWeeks: 130, category: .physical, description: "Has about 16 teeth", isPredefined: true),
        Milestone(title: "Doubles birth weight", minAgeWeeks: 20, maxAgeWeeks: 32, category: .physical, description: "Weight doubles from birth", isPredefined: true),
        Milestone(title: "Triples birth weight", minAgeWeeks: 48, maxAgeWeeks: 68, category: .physical, description: "Weight triples from birth", isPredefined: true),
        
        // SENSORY MILESTONES
        Milestone(title: "Sees in color", minAgeWeeks: 8, maxAgeWeeks: 16, category: .sensory, description: "Can see colors clearly", isPredefined: true),
        Milestone(title: "Depth perception", minAgeWeeks: 20, maxAgeWeeks: 32, category: .sensory, description: "Develops depth perception", isPredefined: true),
        Milestone(title: "Recognizes familiar sounds", minAgeWeeks: 12, maxAgeWeeks: 24, category: .sensory, description: "Recognizes familiar voices and sounds", isPredefined: true),
        
        // FEEDING MILESTONES
        Milestone(title: "Breastfeeds effectively", minAgeWeeks: 1, maxAgeWeeks: 4, category: .feeding, description: "Latches and feeds well", isPredefined: true),
        Milestone(title: "Shows hunger cues", minAgeWeeks: 2, maxAgeWeeks: 8, category: .feeding, description: "Shows clear hunger and fullness cues", isPredefined: true),
        Milestone(title: "Sits in high chair", minAgeWeeks: 20, maxAgeWeeks: 32, category: .feeding, description: "Sits supported in high chair", isPredefined: true),
        Milestone(title: "Chews soft foods", minAgeWeeks: 32, maxAgeWeeks: 52, category: .feeding, description: "Chews soft table foods", isPredefined: true),
        Milestone(title: "Self-feeds with utensils", minAgeWeeks: 78, maxAgeWeeks: 130, category: .feeding, description: "Uses utensils independently", isPredefined: true),
        
        // SLEEP MILESTONES
        Milestone(title: "Day/night confusion resolves", minAgeWeeks: 6, maxAgeWeeks: 16, category: .sleep, description: "Sleeps longer at night", isPredefined: true),
        Milestone(title: "Naps regularly", minAgeWeeks: 12, maxAgeWeeks: 104, category: .sleep, description: "Takes predictable naps", isPredefined: true),
        Milestone(title: "Transitions to toddler bed", minAgeWeeks: 104, maxAgeWeeks: 208, category: .sleep, description: "Ready for toddler bed", isPredefined: true),
    ]
    
    var babyAge: String {
        let months = Calendar.current.dateComponents([.month], from: babyBirthDate, to: Date()).month ?? 0
        if months < 12 {
            return "\(months) months old"
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return "\(years) year\(years == 1 ? "" : "s") old"
            } else {
                return "\(years)y \(remainingMonths)m old"
            }
        }
    }
    
    // MARK: - Unit Conversion Helpers
    
    func formatWeight(_ weightInKg: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f kg", weightInKg)
        } else {
            let weightInLbs = weightInKg * 2.20462
            return String(format: "%.1f lbs", weightInLbs)
        }
    }
    
    func formatHeight(_ heightInCm: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f cm", heightInCm)
        } else {
            let heightInInches = heightInCm / 2.54
            return String(format: "%.1f in", heightInInches)
        }
    }
    
    func formatHeadCircumference(_ headCircumferenceInCm: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f cm", headCircumferenceInCm)
        } else {
            let headCircumferenceInInches = headCircumferenceInCm / 2.54
            return String(format: "%.1f in", headCircumferenceInInches)
        }
    }
    
    func convertWeightToKg(_ weight: Double, fromImperial: Bool = false) -> Double {
        if fromImperial {
            return weight / 2.20462
        }
        return weight
    }
    
    func convertHeightToCm(_ height: Double, fromImperial: Bool = false) -> Double {
        if fromImperial {
            return height * 2.54
        }
        return height
    }
    
    init() {
        loadData()
        updateCountdowns()
        startCountdownTimer()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        // Load basic settings
        babyName = UserDefaults.standard.string(forKey: babyNameKey) ?? "Baby"
        if let birthDate = UserDefaults.standard.object(forKey: babyBirthDateKey) as? Date {
            babyBirthDate = birthDate
        } else {
            babyBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
        }
        
        // Load widget settings
        widgetEnabled = UserDefaults.standard.object(forKey: "widget_enabled") as? Bool ?? false
        
        // Load units preference
        useMetricUnits = UserDefaults.standard.object(forKey: "use_metric_units") as? Bool ?? true
        
        // Load activities
        if let data = UserDefaults.standard.data(forKey: activitiesKey),
           let activities = try? JSONDecoder().decode([TotsActivity].self, from: data) {
            recentActivities = activities.sorted { $0.time > $1.time }
        }
        
        // Load milestones
        if let data = UserDefaults.standard.data(forKey: milestonesKey),
           let milestones = try? JSONDecoder().decode([Milestone].self, from: data) {
            self.milestones = milestones
        }
        
        // Load growth data
        if let data = UserDefaults.standard.data(forKey: growthDataKey),
           let growth = try? JSONDecoder().decode([GrowthEntry].self, from: data) {
            growthData = growth
        }
        
        // Load words
        if let data = UserDefaults.standard.data(forKey: wordsKey),
           let words = try? JSONDecoder().decode([BabyWord].self, from: data) {
            self.words = words.sorted { $0.dateFirstSaid < $1.dateFirstSaid }
        }
        
        // Load CloudKit settings
        familySharingEnabled = UserDefaults.standard.bool(forKey: "family_sharing_enabled")
        
        // Always try to fetch existing baby profiles from CloudKit
        Task {
            await loadExistingBabyProfile()
        }
        
        // Calculate stats from loaded data
        calculateStats()
    }
    
    private func saveActivities() {
        if let data = try? JSONEncoder().encode(recentActivities) {
            UserDefaults.standard.set(data, forKey: activitiesKey)
        }
        calculateStats()
    }
    
    private func saveMilestones() {
        if let data = try? JSONEncoder().encode(milestones) {
            UserDefaults.standard.set(data, forKey: milestonesKey)
        }
    }
    
    private func saveGrowthData() {
        if let data = try? JSONEncoder().encode(growthData) {
            UserDefaults.standard.set(data, forKey: growthDataKey)
        }
    }
    
    private func saveWords() {
        if let data = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(data, forKey: wordsKey)
        }
    }
    
    
    private func calculateStats() {
        totalActivitiesLogged = recentActivities.count
        
        // Calculate streak (consecutive days with activities)
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        
        while true {
            let hasActivityOnDate = recentActivities.contains { activity in
                calendar.isDate(activity.time, inSameDayAs: currentDate)
            }
            
            if hasActivityOnDate {
                streak += 1
                if let nextDate = calendar.date(byAdding: .day, value: -1, to: currentDate),
                   let normalizedDate = calendar.dateInterval(of: .day, for: nextDate)?.start {
                    currentDate = normalizedDate
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        streakCount = streak
        
        // Update today's stats
        let today = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        let todayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: today) }
        
        todayFeedings = todayActivities.filter { $0.type == .feeding }.count
        todayDiapers = todayActivities.filter { $0.type == .diaper }.count
        todayMilestones = todayActivities.filter { $0.type == .milestone }.count
        
        let sleepActivities = todayActivities.filter { $0.type == .sleep }
        todaySleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
        
        let tummyActivities = todayActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
        todayTummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
        
        let playActivities = todayActivities.filter { $0.type == .activity && !$0.details.lowercased().contains("tummy") }
        todayPlayTime = playActivities.compactMap { $0.duration }.reduce(0, +)
        
        // Update weekly data based on real activities
        updateWeeklyData()
        
        // Save widget data
        saveWidgetData()
    }
    
    private func updateWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        
        weeklyData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: date) }
            
            let feedings = dayActivities.filter { $0.type == .feeding }.count
            let diapers = dayActivities.filter { $0.type == .diaper }.count
            
            let sleepActivities = dayActivities.filter { $0.type == .sleep }
            let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
            
            let tummyActivities = dayActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
            let tummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
            
            let playActivities = dayActivities.filter { $0.type == .activity && !$0.details.lowercased().contains("tummy") }
            let playTime = playActivities.compactMap { $0.duration }.reduce(0, +)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayString = formatter.string(from: date)
            
            return DayData(
                day: dayString,
                date: date,
                feedings: feedings,
                diapers: diapers,
                sleepHours: sleepHours,
                tummyTime: tummyTime,
                playTime: playTime
            )
        }.reversed()
    }
    
    
    var weeklyProgress: (feedings: Double, diapers: Double, sleep: Double, tummyTime: Double) {
        let totalFeedings = weeklyData.reduce(0) { $0 + $1.feedings }
        let totalDiapers = weeklyData.reduce(0) { $0 + $1.diapers }
        let totalSleep = weeklyData.reduce(0) { $0 + $1.sleepHours }
        let totalTummyTime = weeklyData.reduce(0) { $0 + $1.tummyTime }
        
        return (
            feedings: Double(totalFeedings) / Double(weeklyFeedingGoal),
            diapers: Double(totalDiapers) / Double(weeklyDiaperGoal),
            sleep: totalSleep / weeklySleepGoal,
            tummyTime: Double(totalTummyTime) / Double(weeklyTummyTimeGoal)
        )
    }
    
    func addActivity(_ activity: TotsActivity) {
        recentActivities.insert(activity, at: 0)
        updateCountdowns() // Update countdowns after adding activity
        
        // Handle growth activities - create growth entry with partial updates
        if activity.type == .growth {
            addGrowthEntry(from: activity)
        }
        
        // Update Live Activity if running
        updateLiveActivity()
        
        // Start Live Activity if not running and widget is enabled
        if currentActivity == nil && widgetEnabled {
            startLiveActivity()
        }
        
        // Debug logging
        print("🔍 Add Activity Debug:")
        print("   familySharingEnabled: \(familySharingEnabled)")
        print("   babyProfileRecord: \(babyProfileRecord != nil ? "exists" : "nil")")
        
        // Always sync to CloudKit (create baby profile if needed)
        Task {
            do {
                // Ensure we have a baby profile record
                if babyProfileRecord == nil {
                    print("🍼 No baby profile found, creating one...")
                    await createDefaultBabyProfile()
                }
                
                guard let profileRecord = babyProfileRecord else {
                    print("❌ Failed to create baby profile record")
                    return
                }
                
                try await cloudKitManager.saveActivity(activity, to: profileRecord.recordID)
                print("✅ Activity synced to CloudKit")
            } catch {
                print("❌ Failed to sync activity to CloudKit: \(error)")
            }
        }
    }
    
    private func addGrowthEntry(from activity: TotsActivity) {
        // Only create growth entry if at least one measurement is provided
        guard activity.weight != nil || activity.height != nil || activity.headCircumference != nil else {
            return
        }
        
        // Use provided values or fall back to current latest values (but not 0.0)
        let weight = activity.weight ?? (currentWeight > 0 ? currentWeight : nil)
        let height = activity.height ?? (currentHeight > 0 ? currentHeight : nil)
        let headCircumference = activity.headCircumference ?? (currentHeadCircumference > 0 ? currentHeadCircumference : nil)
        
        // Only create entry if we have at least one valid measurement
        if let weight = weight, let height = height, let headCircumference = headCircumference {
            let growthEntry = GrowthEntry(
                date: activity.time,
                weight: weight,
                height: height,
                headCircumference: headCircumference
            )
            
            growthData.append(growthEntry)
        }
    }
    
    func deleteActivity(_ activity: TotsActivity) {
        recentActivities.removeAll { $0.id == activity.id }
        updateCountdowns() // Update countdowns after deleting activity
        
        // Update Live Activity if running
        updateLiveActivity()
        
        // Recalculate stats
        calculateStats()
    }
    
    func updateActivity(_ oldActivity: TotsActivity, with newActivity: TotsActivity) {
        if let index = recentActivities.firstIndex(where: { $0.id == oldActivity.id }) {
            // Create updated activity with same ID
            var updatedActivity = newActivity
            updatedActivity = TotsActivity(
                type: newActivity.type,
                time: newActivity.time,
                details: newActivity.details,
                mood: newActivity.mood,
                duration: newActivity.duration,
                notes: newActivity.notes,
                weight: newActivity.weight,
                height: newActivity.height
            )
            
            recentActivities[index] = updatedActivity
            updateCountdowns()
            updateLiveActivity()
            calculateStats()
        }
    }
    
    private func updateTodayStats(for activity: TotsActivity) {
        switch activity.type {
        case .feeding:
            todayFeedings += 1
        case .pumping:
            // Pumping doesn't directly affect feeding count but could be tracked separately
            break
        case .diaper:
            todayDiapers += 1
        case .sleep:
            todaySleepHours += Double(activity.duration ?? 90) / 60.0
        case .milestone:
            todayMilestones += 1
        case .activity:
            if activity.details.lowercased().contains("tummy") {
                todayTummyTime += activity.duration ?? 15
            } else {
                todayPlayTime += activity.duration ?? 30
            }
        case .growth:
            // Growth tracking doesn't affect daily stats
            break
        }
        
        // Save widget data
        saveWidgetData()
    }
    
    private func saveWidgetData() {
        UserDefaults.standard.set(todayFeedings, forKey: "today_feedings")
        UserDefaults.standard.set(todaySleepHours, forKey: "today_sleep_hours")
        UserDefaults.standard.set(todayDiapers, forKey: "today_diapers")
        UserDefaults.standard.set(todayTummyTime, forKey: "today_tummy_time")
    }
    
    func completeMilestone(_ milestone: Milestone) {
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index].isCompleted = true
            milestones[index].completedDate = Date()
        } else if milestone.isPredefined {
            // Add the predefined milestone as completed
            var completedMilestone = milestone
            completedMilestone.isCompleted = true
            completedMilestone.completedDate = Date()
            milestones.append(completedMilestone)
        }
        
        // Add milestone activity
        let activity = TotsActivity(
            type: .milestone,
            time: Date(),
            details: milestone.title,
            mood: .happy,
            notes: milestone.description
        )
        addActivity(activity)
        
        // Update development score
        updateDevelopmentScore()
        generateAIInsights()
    }
    
    // MARK: - Word Tracking
    
    func addWord(_ word: String, category: WordCategory = .other, notes: String = "") {
        // Check if word already exists
        if !words.contains(where: { $0.word.lowercased() == word.lowercased() }) {
            let newWord = BabyWord(
                word: word,
                category: category,
                dateFirstSaid: Date(),
                notes: notes
            )
            words.append(newWord)
            words.sort { $0.dateFirstSaid < $1.dateFirstSaid }
            
            // Add milestone activity for first words
            if words.count == 1 {
                let activity = TotsActivity(
                    type: .milestone,
                    time: Date(),
                    details: "First Word: \(word)",
                    mood: .happy,
                    notes: "Said their very first word!"
                )
                addActivity(activity)
            } else if words.count == 10 {
                let activity = TotsActivity(
                    type: .milestone,
                    time: Date(),
                    details: "10 Words Milestone",
                    mood: .happy,
                    notes: "Now knows 10 words!"
                )
                addActivity(activity)
            }
            
            updateDevelopmentScore()
            generateAIInsights()
        }
    }
    
    func deleteWord(_ word: BabyWord) {
        words.removeAll { $0.id == word.id }
    }
    
    func updateWord(_ word: BabyWord, newWord: String, category: WordCategory, notes: String) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].word = newWord
            words[index].category = category
            words[index].notes = notes
        }
    }
    
    // MARK: - Word Auto-Categorization & Typeahead
    
    func getWordSuggestions(for input: String, limit: Int = 3) -> [String] {
        guard !input.isEmpty else { return [] }
        
        let lowercaseInput = input.lowercased()
        let suggestions = allWordsWithCategories
            .filter { $0.0.hasPrefix(lowercaseInput) }
            .prefix(limit)
            .map { $0.0.capitalized }
        
        let result = Array(Set(suggestions)).sorted() // Remove duplicates and sort
        
        // Debug logging for "chi" prefix
        if lowercaseInput.hasPrefix("chi") {
            print("🔍 Suggestions for '\(input)': \(result)")
        }
        
        return result
    }
    
    func getAutoCategorizedCategory(for word: String) -> WordCategory {
        let lowercaseWord = word.lowercased()
        
        // First, check if the word exists in our database
        if let match = allWordsWithCategories.first(where: { $0.0 == lowercaseWord }) {
            return match.1
        }
        
        // If not found, use simple heuristics for categorization
        return categorizeWordByHeuristics(lowercaseWord)
    }
    
    private func categorizeWordByHeuristics(_ word: String) -> WordCategory {
        // Simple heuristics for unknown words
        let actionIndicators = ["ing", "ed", "go", "run", "walk", "jump", "play"]
        let feelingIndicators = ["happy", "sad", "good", "bad", "love", "like", "hate"]
        let soundIndicators = ["oo", "ah", "oh", "wow", "beep", "ring"]
        
        if actionIndicators.contains(where: { word.contains($0) }) {
            return .actions
        } else if feelingIndicators.contains(where: { word.contains($0) }) {
            return .feelings
        } else if soundIndicators.contains(where: { word.contains($0) }) {
            return .sounds
        } else if word.hasSuffix("y") || word.hasSuffix("ie") {
            // Many animal names end in y (doggy, kitty, etc.)
            return .animals
        } else {
            // Default to other for unknown words
            return .other
        }
    }
    
    // MARK: - Milestone Management
    
    func getBabyAgeInWeeks() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: babyBirthDate, to: Date())
        let days = components.day ?? 0
        return max(0, days / 7)
    }
    
    func getBabyAgeFormatted() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day], from: babyBirthDate, to: Date())
        
        let years = components.year ?? 0
        let months = components.month ?? 0
        let weeks = components.weekOfYear ?? 0
        
        if years > 0 {
            if months > 0 {
                return "\(years) yr \(months) month\(months == 1 ? "" : "s") old"
            } else {
                return "\(years) year\(years == 1 ? "" : "s") old"
            }
        } else if months > 0 {
            let remainingWeeks = weeks - (months * 4)
            if remainingWeeks > 0 {
                return "\(months) month\(months == 1 ? "" : "s") \(remainingWeeks) week\(remainingWeeks == 1 ? "" : "s") old"
            } else {
                return "\(months) month\(months == 1 ? "" : "s") old"
            }
        } else {
            return "\(weeks) week\(weeks == 1 ? "" : "s") old"
        }
    }
    
    func getRelevantMilestones() -> [Milestone] {
        // Get all predefined milestones that aren't already in custom milestones
        let availablePredefined = predefinedMilestones.filter { predefined in
            !milestones.contains { existing in existing.title == predefined.title }
        }
        
        // Combine ALL milestones (no age filtering here - let the UI handle age group filtering)
        return (milestones + availablePredefined).sorted { milestone1, milestone2 in
            // Sort by: completed status (incomplete first), then by min age, then by title
            if milestone1.isCompleted != milestone2.isCompleted {
                return !milestone1.isCompleted && milestone2.isCompleted
            }
            if milestone1.minAgeWeeks != milestone2.minAgeWeeks {
                return milestone1.minAgeWeeks < milestone2.minAgeWeeks
            }
            return milestone1.title < milestone2.title
        }
    }
    
    func addMilestone(_ milestone: Milestone) {
        milestones.append(milestone)
    }
    
    func deleteMilestone(_ milestone: Milestone) {
        milestones.removeAll { $0.id == milestone.id }
        saveMilestones()
    }
    
    func uncompleteMilestone(_ milestone: Milestone) {
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index].isCompleted = false
            milestones[index].completedDate = nil
        }
    }
    
    
    // MARK: - Growth Percentile Calculations
    
    func getWeightPercentile() -> Int {
        guard let latestGrowth = growthData.last else { return 50 }
        return getWeightPercentile(for: latestGrowth)
    }
    
    func getHeightPercentile() -> Int {
        guard let latestGrowth = growthData.last else { return 50 }
        return getHeightPercentile(for: latestGrowth)
    }
    
    func getBMIPercentile() -> Int {
        guard let latestGrowth = growthData.last else { return 50 }
        return getBMIPercentile(for: latestGrowth)
    }
    
    func getWeightPercentile(for entry: GrowthEntry) -> Int {
        let ageInMonths = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
        let weightKg = convertWeightToKg(entry.weight)
        
        // WHO growth standards with age-appropriate standard deviation
        let expectedWeight = getExpectedWeight(ageInMonths: ageInMonths)
        let standardDeviation = getWeightStandardDeviation(ageInMonths: ageInMonths)
        let percentile = calculatePercentile(value: weightKg, expected: expectedWeight, standardDeviation: standardDeviation)
        return percentile
    }
    
    func getHeightPercentile(for entry: GrowthEntry) -> Int {
        let ageInMonths = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
        let heightCm = convertHeightToCm(entry.height)
        
        // WHO growth standards with age-appropriate standard deviation
        let expectedHeight = getExpectedHeight(ageInMonths: ageInMonths)
        let standardDeviation = getHeightStandardDeviation(ageInMonths: ageInMonths)
        let percentile = calculatePercentile(value: heightCm, expected: expectedHeight, standardDeviation: standardDeviation)
        return percentile
    }
    
    func getBMIPercentile(for entry: GrowthEntry) -> Int {
        let ageInMonths = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
        let weightKg = convertWeightToKg(entry.weight)
        let heightM = convertHeightToCm(entry.height) / 100.0
        let bmi = weightKg / (heightM * heightM)
        
        // WHO BMI-for-age standards with age-appropriate standard deviation
        let expectedBMI = getExpectedBMI(ageInMonths: ageInMonths)
        let standardDeviation = getBMIStandardDeviation(ageInMonths: ageInMonths)
        let percentile = calculatePercentile(value: bmi, expected: expectedBMI, standardDeviation: standardDeviation)
        return percentile
    }
    
    private func getWeightStandardDeviation(ageInMonths: Int) -> Double {
        // WHO weight standard deviations (kg)
        let whoWeightSD: [Double] = [
            0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.0, 1.1, 1.1, 1.2, 1.2, 1.3, 1.3, // 0-12 months
            1.3, 1.4, 1.4, 1.4, 1.5, 1.5, 1.5, 1.6, 1.6, 1.6, 1.7, 1.7 // 13-24 months
        ]
        
        if ageInMonths < whoWeightSD.count {
            return whoWeightSD[ageInMonths]
        } else {
            return 1.8 // Default for older ages
        }
    }
    
    private func getHeightStandardDeviation(ageInMonths: Int) -> Double {
        // WHO height standard deviations (cm)
        let whoHeightSD: [Double] = [
            1.9, 2.0, 2.1, 2.2, 2.3, 2.4, 2.4, 2.5, 2.5, 2.6, 2.6, 2.7, 2.7, // 0-12 months
            2.8, 2.8, 2.9, 2.9, 3.0, 3.0, 3.1, 3.1, 3.2, 3.2, 3.3, 3.3 // 13-24 months
        ]
        
        if ageInMonths < whoHeightSD.count {
            return whoHeightSD[ageInMonths]
        } else {
            return 3.5 // Default for older ages
        }
    }
    
    private func getBMIStandardDeviation(ageInMonths: Int) -> Double {
        // WHO BMI standard deviations (kg/m²)
        let whoBMISD: [Double] = [
            1.3, 1.4, 1.4, 1.3, 1.2, 1.2, 1.1, 1.1, 1.0, 1.0, 1.0, 1.0, 0.9, // 0-12 months
            0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9 // 13-24 months
        ]
        
        if ageInMonths < whoBMISD.count {
            return whoBMISD[ageInMonths]
        } else {
            return 1.0 // Default for older ages
        }
    }
    
    var growthPercentileHistory: [(date: Date, weightPercentile: Int, heightPercentile: Int, bmiPercentile: Int)] {
        return growthData.map { entry in
            (
                date: entry.date,
                weightPercentile: getWeightPercentile(for: entry),
                heightPercentile: getHeightPercentile(for: entry),
                bmiPercentile: getBMIPercentile(for: entry)
            )
        }
    }
    
    private func getAgeInMonths() -> Int {
        let components = Calendar.current.dateComponents([.month], from: babyBirthDate, to: Date())
        return max(0, components.month ?? 0)
    }
    
    private func getExpectedWeight(ageInMonths: Int) -> Double {
        // WHO growth standards 50th percentile for boys/girls average (in kg)
        let whoWeightData: [Double] = [
            3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2, 9.4, 9.6, // 0-12 months
            9.9, 10.1, 10.3, 10.5, 10.7, 10.9, 11.1, 11.3, 11.5, 11.8, 12.0, 12.2 // 13-24 months
        ]
        
        if ageInMonths < whoWeightData.count {
            return whoWeightData[ageInMonths]
        } else {
            // Extrapolate for older ages
            return 12.2 + Double(ageInMonths - 24) * 0.15
        }
    }
    
    private func getExpectedHeight(ageInMonths: Int) -> Double {
        // WHO growth standards 50th percentile for boys/girls average (in cm)
        let whoHeightData: [Double] = [
            49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.3, 74.5, 75.7, // 0-12 months
            76.9, 78.0, 79.1, 80.2, 81.2, 82.3, 83.2, 84.2, 85.1, 86.0, 86.9, 87.8 // 13-24 months
        ]
        
        if ageInMonths < whoHeightData.count {
            return whoHeightData[ageInMonths]
        } else {
            // Extrapolate for older ages
            return 87.8 + Double(ageInMonths - 24) * 0.5
        }
    }
    
    private func getExpectedBMI(ageInMonths: Int) -> Double {
        // WHO BMI-for-age 50th percentile (kg/m²)
        let whoBMIData: [Double] = [
            13.3, 14.9, 16.3, 16.8, 16.8, 16.6, 16.4, 16.2, 16.0, 15.8, 15.7, 15.5, 15.4, // 0-12 months
            15.3, 15.2, 15.1, 15.0, 14.9, 14.9, 14.8, 14.8, 14.7, 14.7, 14.7, 14.6 // 13-24 months
        ]
        
        if ageInMonths < whoBMIData.count {
            return whoBMIData[ageInMonths]
        } else {
            // Extrapolate for older ages
            return 14.6 + Double(ageInMonths - 24) * -0.02
        }
    }
    
    private func calculatePercentile(value: Double, expected: Double, standardDeviation: Double) -> Int {
        let zScore = (value - expected) / standardDeviation
        
        // More accurate z-score to percentile conversion using cumulative distribution
        let percentile = cumulativeNormalDistribution(zScore) * 100
        
        return max(3, min(97, Int(percentile.rounded())))
    }
    
    private func cumulativeNormalDistribution(_ z: Double) -> Double {
        // Approximation of cumulative normal distribution using error function
        return 0.5 * (1 + erf(z / sqrt(2)))
    }
    
    private func erf(_ x: Double) -> Double {
        // Approximation of error function
        let a1 = 0.254829592
        let a2 = -0.284496736
        let a3 = 1.421413741
        let a4 = -1.453152027
        let a5 = 1.061405429
        let p = 0.3275911
        
        let sign = x < 0 ? -1.0 : 1.0
        let absX = abs(x)
        
        let t = 1.0 / (1.0 + p * absX)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX)
        
        return sign * y
    }
    
    // MARK: - AI & Smart Features
    
    func generateAIInsights() {
        aiInsights = []
        
        // Sleep pattern analysis
        if let sleepInsight = analyzeSleepPatterns() {
            aiInsights.append(sleepInsight)
        }
        
        // Feeding optimization
        if let feedingInsight = analyzeFeedingPatterns() {
            aiInsights.append(feedingInsight)
        }
        
        // Milestone prediction
        if let milestoneInsight = predictNextMilestone() {
            aiInsights.append(milestoneInsight)
        }
        
        // Mood analysis
        if let moodInsight = analyzeMoodPatterns() {
            aiInsights.append(moodInsight)
        }
        
        // Growth analysis
        if let growthInsight = analyzeGrowthTrends() {
            aiInsights.append(growthInsight)
        }
    }
    
    private func analyzeSleepPatterns() -> AIInsight? {
        let recentSleep = weeklyData.suffix(7).map { $0.sleepHours }
        let avgSleep = recentSleep.reduce(0, +) / Double(recentSleep.count)
        let idealSleep = 14.5
        
        if avgSleep >= idealSleep {
            return AIInsight(
                id: "sleep_excellent",
                icon: "moon.stars.fill",
                title: "Excellent Sleep Pattern",
                description: "\(babyName) is getting \(String(format: "%.1f", avgSleep)) hours of sleep on average. This is optimal for healthy development!",
                type: .positive,
                confidence: 0.94
            )
        } else if avgSleep < idealSleep - 2 {
            return AIInsight(
                id: "sleep_concern",
                icon: "moon.circle.fill",
                title: "Sleep Improvement Needed",
                description: "\(babyName) is getting \(String(format: "%.1f", avgSleep)) hours of sleep. Consider adjusting bedtime routine for better rest.",
                type: .warning,
                confidence: 0.87
            )
        }
        
        return nil
    }
    
    private func analyzeFeedingPatterns() -> AIInsight? {
        let recentFeedings = weeklyData.suffix(7).map { $0.feedings }
        let avgFeedings = Double(recentFeedings.reduce(0, +)) / Double(recentFeedings.count)
        let consistency = calculateConsistency(recentFeedings.map { Double($0) })
        
        if consistency > 0.8 && avgFeedings >= 7 {
            return AIInsight(
                id: "feeding_optimal",
                icon: "drop.fill",
                title: "Perfect Feeding Rhythm",
                description: "Your feeding schedule is very consistent with \(String(format: "%.1f", avgFeedings)) feeds per day. Great job!",
                type: .positive,
                confidence: 0.91
            )
        }
        
        return nil
    }
    
    private func predictNextMilestone() -> AIInsight? {
        let completedCount = milestones.filter { $0.isCompleted }.count
        let totalCount = milestones.count
        let completionRate = Double(completedCount) / Double(totalCount)
        
        if let nextMilestone = milestones.first(where: { !$0.isCompleted }) {
            let daysOld = Calendar.current.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
            let weeksOld = daysOld / 7
            
            return AIInsight(
                id: "milestone_prediction",
                icon: "star.fill",
                title: "Next Milestone Prediction",
                description: "Based on current development, \(nextMilestone.title.lowercased()) may occur within the next 2-4 weeks!",
                type: .exciting,
                confidence: min(0.95, completionRate + 0.2)
            )
        }
        
        return nil
    }
    
    private func analyzeMoodPatterns() -> AIInsight? {
        let recentActivities = recentActivities.prefix(20)
        let moodCounts = Dictionary(grouping: recentActivities, by: { $0.mood })
            .mapValues { $0.count }
        
        let totalActivities = recentActivities.count
        let happyRatio = Double(moodCounts[.happy] ?? 0) / Double(totalActivities)
        
        if happyRatio > 0.7 {
            return AIInsight(
                id: "mood_excellent",
                icon: "face.smiling.fill",
                title: "Very Happy Baby",
                description: "\(babyName) has been happy in \(Int(happyRatio * 100))% of recent activities. You're doing an amazing job!",
                type: .positive,
                confidence: 0.88
            )
        } else if happyRatio < 0.3 {
            return AIInsight(
                id: "mood_attention",
                icon: "face.dashed.fill",
                title: "Mood Needs Attention",
                description: "\(babyName) seems fussy lately. Consider checking for growth spurts or schedule adjustments.",
                type: .warning,
                confidence: 0.75
            )
        }
        
        return nil
    }
    
    private func analyzeGrowthTrends() -> AIInsight? {
        guard growthData.count >= 3 else { return nil }
        
        let recentGrowth = growthData.suffix(3)
        let weightGain = recentGrowth.last!.weight - recentGrowth.first!.weight
        let timeSpan = Calendar.current.dateComponents([.month], 
                                                      from: recentGrowth.first!.date, 
                                                      to: recentGrowth.last!.date).month ?? 1
        
        let monthlyWeightGain = weightGain / Double(max(timeSpan, 1))
        
        if monthlyWeightGain >= 0.5 && monthlyWeightGain <= 1.0 {
            return AIInsight(
                id: "growth_healthy",
                icon: "chart.line.uptrend.xyaxis",
                title: "Healthy Growth Rate",
                description: "\(babyName) is gaining \(String(format: "%.1f", monthlyWeightGain)) kg per month. This is perfect for their age!",
                type: .positive,
                confidence: 0.92
            )
        }
        
        return nil
    }
    
    private func calculateConsistency(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Normalize to 0-1 scale (lower deviation = higher consistency)
        return max(0, 1 - (standardDeviation / mean))
    }
    
    private func updateDevelopmentScore() {
        let completedMilestones = milestones.filter { $0.isCompleted }.count
        let totalMilestones = milestones.count
        let baseScore = Int(Double(completedMilestones) / Double(totalMilestones) * 100)
        
        // Adjust based on age appropriateness
        let daysOld = Calendar.current.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
        let monthsOld = daysOld / 30
        
        // Bonus for early milestones, penalty for delayed ones
        var adjustedScore = baseScore
        if monthsOld < 8 && completedMilestones > 4 {
            adjustedScore += 10 // Early achiever bonus
        } else if monthsOld > 10 && completedMilestones < 3 {
            adjustedScore -= 5 // Gentle adjustment for delayed milestones
        }
        
        developmentScore = min(100, max(0, adjustedScore))
    }
    
    func predictNextActivity() -> ActivityType? {
        guard !recentActivities.isEmpty else { return .feeding }
        
        let now = Date()
        let lastActivity = recentActivities.first!
        let timeSinceLastActivity = now.timeIntervalSince(lastActivity.time) / 3600 // hours
        
        // Smart prediction based on patterns and time
        switch lastActivity.type {
        case .feeding:
            if timeSinceLastActivity > 2.5 {
                return .diaper
            }
        case .pumping:
            if timeSinceLastActivity > 1 {
                return .feeding // After pumping, suggest feeding
            }
        case .diaper:
            if timeSinceLastActivity > 1 {
                return .activity
            }
        case .sleep:
            if timeSinceLastActivity > 0.5 {
                return .feeding
            }
        case .activity:
            if timeSinceLastActivity > 1.5 {
                return .feeding
            }
        case .milestone:
            return .activity // Celebrate with activity time
        case .growth:
            return .feeding // After growth tracking, suggest feeding
        }
        
        // Default prediction based on time of day
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 6...9, 12...13, 17...18: return .feeding
        case 10...11, 14...16: return .activity
        case 19...22: return .sleep
        default: return .diaper
        }
    }
    
    func getSmartSuggestions() -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Time-based suggestions
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        if let lastActivity = recentActivities.first {
            let timeSinceLastActivity = now.timeIntervalSince(lastActivity.time) / 3600 // hours
            
            // Feeding suggestion
            if timeSinceLastActivity > 3 && lastActivity.type != .feeding {
                suggestions.append(SmartSuggestion(
                    id: "feeding_time",
                    icon: "drop.fill",
                    title: "Feeding Time",
                    description: "It's been \(Int(timeSinceLastActivity)) hours since last feeding",
                    action: "Log Feeding",
                    priority: .high
                ))
            }
            
            // Tummy time suggestion
            let lastTummyTime = recentActivities.first { $0.type == .activity && $0.details.lowercased().contains("tummy") }
            if let lastTummy = lastTummyTime {
                let timeSinceTummy = now.timeIntervalSince(lastTummy.time) / 3600
                if timeSinceTummy > 3 {
                    suggestions.append(SmartSuggestion(
                        id: "tummy_time",
                        icon: "figure.strengthtraining.traditional",
                        title: "Tummy Time",
                        description: "Important for motor development",
                        action: "Start Session",
                        priority: .medium
                    ))
                }
            }
        }
        
        // Milestone-based suggestions
        if let nextMilestone = milestones.first(where: { !$0.isCompleted }) {
            suggestions.append(SmartSuggestion(
                id: "milestone_activity",
                icon: "star.circle.fill",
                title: "Milestone Practice",
                description: "Activities to help with \(nextMilestone.title.lowercased())",
                action: "Get Ideas",
                priority: .medium
            ))
        }
        
        // Photo memory suggestion
        if Calendar.current.isDateInToday(Date()) {
            let todayActivities = recentActivities.filter { Calendar.current.isDateInToday($0.time) }
            if todayActivities.count > 3 && !todayActivities.contains(where: { $0.notes?.contains("photo") ?? false }) {
                suggestions.append(SmartSuggestion(
                    id: "photo_memory",
                    icon: "camera.fill",
                    title: "Capture Today",
                    description: "Document this special day",
                    action: "Take Photo",
                    priority: .low
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - History Methods
    
    func getActivities(for date: Date) -> [TotsActivity] {
        let calendar = Calendar.current
        return recentActivities.filter { activity in
            calendar.isDate(activity.time, inSameDayAs: date)
        }
    }
    
    func getStatsForDate(_ date: Date) -> DayStats {
        let activities = getActivities(for: date)
        
        let feedings = activities.filter { $0.type == .feeding }.count
        let diapers = activities.filter { $0.type == .diaper }.count
        
        let sleepActivities = activities.filter { $0.type == .sleep }
        let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
        
        let tummyTimeActivities = activities.filter { $0.type == .activity && $0.details.contains("Tummy") }
        let tummyTime = tummyTimeActivities.compactMap { $0.duration }.reduce(0, +)
        
        return DayStats(
            feedings: feedings,
            sleepHours: sleepHours,
            diapers: diapers,
            tummyTime: tummyTime
        )
    }
    
    // MARK: - Countdown Methods
    
    func updateCountdowns() {
        let now = Date()
        
        // Calculate next feeding time
        if let lastFeeding = recentActivities.first(where: { $0.type == .feeding }) {
            let averageFeedingInterval: TimeInterval = 3 * 3600 // 3 hours
            let nextFeeding = lastFeeding.time.addingTimeInterval(averageFeedingInterval)
            nextFeedingTime = nextFeeding
            nextFeedingCountdown = max(0, nextFeeding.timeIntervalSince(now))
        } else {
            // Default to 2 minutes from now for demo purposes to see seconds timer
            let defaultNextFeeding = now.addingTimeInterval(2 * 60)
            nextFeedingTime = defaultNextFeeding
            nextFeedingCountdown = max(0, defaultNextFeeding.timeIntervalSince(now))
        }
        
        // Calculate next diaper change
        if let lastDiaper = recentActivities.first(where: { $0.type == .diaper }) {
            let averageDiaperInterval: TimeInterval = 2.5 * 3600 // 2.5 hours
            let nextDiaper = lastDiaper.time.addingTimeInterval(averageDiaperInterval)
            nextDiaperTime = nextDiaper
            nextDiaperCountdown = max(0, nextDiaper.timeIntervalSince(now))
        } else {
            // Default to 3 minutes from now for demo purposes to see seconds timer
            let defaultNextDiaper = now.addingTimeInterval(3 * 60)
            nextDiaperTime = defaultNextDiaper
            nextDiaperCountdown = max(0, defaultNextDiaper.timeIntervalSince(now))
        }
        
    }
    
    func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateCountdowns()
            }
        }
    }
    
    func formatCountdown(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Now"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Now"
        }
    }
    
    func formatCountdownWithSeconds(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "DUE"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct TotsActivity: Identifiable, Codable {
    let id = UUID()
    let type: ActivityType
    let time: Date
    let details: String
    let mood: BabyMood
    let duration: Int? // in minutes
    let notes: String?
    let weight: Double? // in pounds
    let height: Double? // in inches
    let headCircumference: Double? // in cm
    
    init(type: ActivityType, time: Date, details: String, mood: BabyMood = .neutral, duration: Int? = nil, notes: String? = nil, weight: Double? = nil, height: Double? = nil, headCircumference: Double? = nil) {
        self.type = type
        self.time = time
        self.details = details
        self.mood = mood
        self.duration = duration
        self.notes = notes
        self.weight = weight
        self.height = height
        self.headCircumference = headCircumference
    }
}

enum ActivityType: String, CaseIterable, Codable {
    case feeding = "🍼"
    case pumping = "PumpingIcon"
    case diaper = "DiaperIcon"
    case sleep = "moon.zzz.fill"
    case milestone = "🎉"
    case activity = "🧸"
    case growth = "📏"
    
    var name: String {
        switch self {
        case .feeding: return "Feeding"
        case .pumping: return "Pumping"
        case .diaper: return "Diaper"
        case .sleep: return "Sleep"
        case .milestone: return "Milestone"
        case .activity: return "Activity"
        case .growth: return "Growth"
        }
    }
    
        var color: Color {
            switch self {
            case .feeding: return .pink
            case .pumping: return .cyan
            case .diaper: return .orange
            case .sleep: return .purple
            case .milestone: return .purple
            case .activity: return .green
            case .growth: return .blue
            }
        }
    
    var gradientColors: [Color] {
        switch self {
        case .feeding: return [.pink, .red]
        case .pumping: return [.cyan, .blue]
        case .diaper: return [.orange, .yellow]
        case .sleep: return [.indigo, .blue]
        case .milestone: return [.purple, .pink]
        case .activity: return [.green, .mint]
        case .growth: return [.blue, .cyan]
        }
    }
}

enum ActivitySubType: String, CaseIterable, Codable {
    case tummyTime = "🤸‍♂️"
    case bathTime = "🛁"
    case storyTime = "📖"
    case screenTime = "📱"
    case outdoorTime = "🌳"
    case playTime = "🧸"
    case musicTime = "🎵"
    case artTime = "🎨"
    
    var name: String {
        switch self {
        case .tummyTime: return "Tummy Time"
        case .bathTime: return "Bath Time"
        case .storyTime: return "Story Time"
        case .screenTime: return "Screen Time"
        case .outdoorTime: return "Outdoor Time"
        case .playTime: return "Play Time"
        case .musicTime: return "Music Time"
        case .artTime: return "Art Time"
        }
    }
    
    var color: Color {
        switch self {
        case .tummyTime: return .green
        case .bathTime: return .blue
        case .storyTime: return .purple
        case .screenTime: return .orange
        case .outdoorTime: return .green
        case .playTime: return .yellow
        case .musicTime: return .pink
        case .artTime: return .red
        }
    }
}

enum BabyMood: String, CaseIterable, Codable {
    case happy = "😊"
    case content = "😌"
    case sleepy = "😴"
    case fussy = "😫"
    case curious = "🤔"
    case neutral = "😐"
    
    var name: String {
        switch self {
        case .happy: return "Happy"
        case .content: return "Content"
        case .sleepy: return "Sleepy"
        case .fussy: return "Fussy"
        case .curious: return "Curious"
        case .neutral: return "Neutral"
        }
    }
    
    var color: Color {
        switch self {
        case .happy: return .yellow
        case .content: return .green
        case .sleepy: return .blue
        case .fussy: return .red
        case .curious: return .orange
        case .neutral: return .gray
        }
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let day: String
    let date: Date
    let feedings: Int
    let diapers: Int
    let sleepHours: Double
    let tummyTime: Int // minutes
    let playTime: Int // minutes
}

struct Milestone: Identifiable, Codable {
    let id: UUID
    let title: String
    var isCompleted: Bool
    var completedDate: Date?
    let minAgeWeeks: Int // Minimum age in weeks
    let maxAgeWeeks: Int // Maximum age in weeks  
    let category: MilestoneCategory
    let description: String
    let isPredefined: Bool
    
    init(title: String, isCompleted: Bool = false, completedDate: Date? = nil, minAgeWeeks: Int, maxAgeWeeks: Int, category: MilestoneCategory, description: String, isPredefined: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.minAgeWeeks = minAgeWeeks
        self.maxAgeWeeks = maxAgeWeeks
        self.category = category
        self.description = description
        self.isPredefined = isPredefined
    }
    
    var expectedAgeRange: String {
        if minAgeWeeks == maxAgeWeeks {
            return "\(minAgeWeeks) weeks"
        } else if minAgeWeeks < 52 && maxAgeWeeks < 52 {
            return "\(minAgeWeeks)-\(maxAgeWeeks) weeks"
        } else {
            let minMonths = minAgeWeeks / 4
            let maxMonths = maxAgeWeeks / 4
            if minMonths == maxMonths {
                return "\(minMonths) months"
            } else {
                return "\(minMonths)-\(maxMonths) months"
            }
        }
    }
    
    func isRelevantForAge(weeks: Int) -> Bool {
        // Show milestones that are within 4 weeks of being due, or overdue
        return weeks >= (minAgeWeeks - 4) && weeks <= (maxAgeWeeks + 8)
    }
}

enum MilestoneCategory: String, CaseIterable, Codable {
    case motor = "Motor Skills"
    case language = "Language & Communication"
    case social = "Social & Emotional"
    case cognitive = "Cognitive & Learning"
    case physical = "Physical Growth"
    case feeding = "Feeding & Eating"
    case sleep = "Sleep & Routine"
    case sensory = "Sensory Development"
    
    var icon: String {
        switch self {
        case .motor: return "figure.walk"
        case .language: return "bubble.left.and.text.bubble.right.fill"
        case .social: return "heart.2.fill"
        case .cognitive: return "brain.head.profile.fill"
        case .physical: return "ruler.fill"
        case .feeding: return "fork.knife"
        case .sleep: return "moon.zzz.fill"
        case .sensory: return "eye.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .motor: return .blue
        case .language: return .green
        case .social: return .pink
        case .cognitive: return .purple
        case .physical: return .orange
        case .feeding: return .red
        case .sleep: return .indigo
        case .sensory: return .yellow
        }
    }
}

struct GrowthEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let weight: Double // kg
    let height: Double // cm
    let headCircumference: Double // cm
}

struct BabyWord: Identifiable, Codable {
    let id = UUID()
    var word: String
    var category: WordCategory
    let dateFirstSaid: Date
    var notes: String
    
    init(word: String, category: WordCategory = .other, dateFirstSaid: Date = Date(), notes: String = "") {
        self.word = word
        self.category = category
        self.dateFirstSaid = dateFirstSaid
        self.notes = notes
    }
}

enum WordCategory: String, CaseIterable, Codable {
    case people = "People"
    case animals = "Animals"
    case food = "Food"
    case actions = "Actions"
    case objects = "Objects"
    case feelings = "Feelings"
    case sounds = "Sounds"
    case colors = "Colors"
    case shapes = "Shapes"
    case numbers = "Numbers"
    case bodyParts = "Body Parts"
    case clothes = "Clothes"
    case places = "Places"
    case transportation = "Transportation"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .people: return "person.2.fill"
        case .animals: return "pawprint.fill"
        case .food: return "fork.knife"
        case .actions: return "figure.run"
        case .objects: return "cube.box.fill"
        case .feelings: return "heart.fill"
        case .sounds: return "speaker.wave.2.fill"
        case .colors: return "paintpalette.fill"
        case .shapes: return "circle.square"
        case .numbers: return "number"
        case .bodyParts: return "figure.arms.open"
        case .clothes: return "tshirt.fill"
        case .places: return "house.fill"
        case .transportation: return "car.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .people: return .blue
        case .animals: return .brown
        case .food: return .green
        case .actions: return .orange
        case .objects: return .gray
        case .feelings: return .pink
        case .sounds: return .purple
        case .colors: return .red
        case .shapes: return .indigo
        case .numbers: return .cyan
        case .bodyParts: return .mint
        case .clothes: return .teal
        case .places: return .yellow
        case .transportation: return Color(.systemBlue)
        case .other: return Color(.systemGray)
        }
    }
}

// MARK: - Live Activity Attributes
public struct TotsLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties that change during the activity
        public var todayFeedings: Int
        public var todaySleepHours: Double
        public var todayDiapers: Int
        public var todayTummyTime: Int
        public var lastUpdateTime: Date
        
        // Timer countdowns for next activities
        public var nextFeedingTime: Date?
        public var nextDiaperTime: Date?
        public var nextTummyTime: Date?
        
        public init(todayFeedings: Int, todaySleepHours: Double, todayDiapers: Int, todayTummyTime: Int, lastUpdateTime: Date, nextFeedingTime: Date? = nil, nextDiaperTime: Date? = nil, nextTummyTime: Date? = nil) {
            self.todayFeedings = todayFeedings
            self.todaySleepHours = todaySleepHours
            self.todayDiapers = todayDiapers
            self.todayTummyTime = todayTummyTime
            self.lastUpdateTime = lastUpdateTime
            self.nextFeedingTime = nextFeedingTime
            self.nextDiaperTime = nextDiaperTime
            self.nextTummyTime = nextTummyTime
        }
    }

    // Fixed properties for the activity
    public var babyName: String
    public var feedingGoal: Int
    public var sleepGoal: Double
    public var diaperGoal: Int
    public var tummyTimeGoal: Int
    
    public init(babyName: String, feedingGoal: Int, sleepGoal: Double, diaperGoal: Int, tummyTimeGoal: Int) {
        self.babyName = babyName
        self.feedingGoal = feedingGoal
        self.sleepGoal = sleepGoal
        self.diaperGoal = diaperGoal
        self.tummyTimeGoal = tummyTimeGoal
    }
}

// MARK: - Live Activity Management
extension TotsDataManager {
    func startLiveActivity() {
        // Check if Live Activities are supported on this device
        #if targetEnvironment(simulator)
        print("Live Activities are not supported in the iOS Simulator")
        return
        #endif
        
        let authInfo = ActivityAuthorizationInfo()
        print("Live Activity authorization status: \(authInfo.areActivitiesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("Live Activities are not enabled. User needs to enable in Settings → Face ID & Passcode → Live Activities")
            return
        }
        
        // Check if activity is already running
        if currentActivity != nil {
            updateLiveActivity()
            return
        }
        
        let attributes = TotsLiveActivityAttributes(
            babyName: babyName,
            feedingGoal: 8,
            sleepGoal: 15.0,
            diaperGoal: 6,
            tummyTimeGoal: 60
        )
        
        let initialState = TotsLiveActivityAttributes.ContentState(
            todayFeedings: todayFeedings,
            todaySleepHours: todaySleepHours,
            todayDiapers: todayDiapers,
            todayTummyTime: todayTummyTime,
            lastUpdateTime: Date(),
            nextFeedingTime: nextFeedingTime,
            nextDiaperTime: nextDiaperTime,
            nextTummyTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("✅ Started Live Activity: \(activity.id)")
            print("🔒 Lock your device to see the Live Activity on the lock screen")
        } catch {
            print("Failed to start Live Activity: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Handle common error cases
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("unsupported") {
                print("Live Activities are not supported on this device")
            } else if errorString.contains("denied") {
                print("Live Activities permission denied - check Settings")
            } else if errorString.contains("disabled") {
                print("Live Activities are disabled in Settings")
            }
        }
    }
    
    func updateLiveActivity() {
        guard let activity = currentActivity else { return }
        
        let updatedState = TotsLiveActivityAttributes.ContentState(
            todayFeedings: todayFeedings,
            todaySleepHours: todaySleepHours,
            todayDiapers: todayDiapers,
            todayTummyTime: todayTummyTime,
            lastUpdateTime: Date(),
            nextFeedingTime: nextFeedingTime,
            nextDiaperTime: nextDiaperTime,
            nextTummyTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
        
        Task {
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }
    
    func stopLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            await MainActor.run {
                currentActivity = nil
            }
        }
    }
    
    // MARK: - CloudKit Family Sharing
    
    func enableFamilySharing() async throws {
        let goals = BabyGoals(
            feeding: weeklyFeedingGoal / 7,
            sleep: weeklySleepGoal / 7.0,
            diaper: weeklyDiaperGoal / 7
        )
        
        babyProfileRecord = try await cloudKitManager.createBabyProfile(
            name: babyName,
            birthDate: babyBirthDate,
            goals: goals
        )
        
        familySharingEnabled = true
        UserDefaults.standard.set(true, forKey: "family_sharing_enabled")
        UserDefaults.standard.set(babyProfileRecord!.recordID.recordName, forKey: "baby_profile_record_id")
    }
    
    func shareBabyProfile() async throws -> CKShare? {
        guard let profileRecord = babyProfileRecord else { 
            print("❌ No baby profile record found to share")
            return nil 
        }
        
        print("🔄 Attempting to share profile: \(profileRecord.recordID.recordName)")
        
        do {
            let share = try await cloudKitManager.shareBabyProfile(profileRecord)
            print("✅ Share created successfully")
            
            await cloudKitManager.setActiveShare(share)
            
            // Enable family sharing
            await MainActor.run {
                self.familySharingEnabled = true
                UserDefaults.standard.set(true, forKey: "family_sharing_enabled")
            }
            
            return share
        } catch {
            print("❌ Failed to share profile: \(error)")
            throw error
        }
    }
    
    func stopSharingProfile() async throws {
        guard let profileRecord = babyProfileRecord else { return }
        try await cloudKitManager.stopSharingProfile(profileRecord)
        
        await cloudKitManager.setActiveShare(nil)
    }
    
    func fetchFamilyMembers() async throws -> [FamilyMember] {
        guard let share = await cloudKitManager.activeShare else { return [] }
        return try await cloudKitManager.fetchFamilyMembers(for: share)
    }
    
    // MARK: - Account Management
    
    func signOut() async {
        print("🚪 TotsDataManager: Starting sign out process")
        await cloudKitManager.signOut()
        
        await MainActor.run {
            // Reset all local data
            self.recentActivities = []
            self.milestones = []
            self.growthData = []
            self.babyName = "Baby"
            self.babyBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
            self.babyProfileRecord = nil
            self.familySharingEnabled = false
            
            // Stop any running live activities
            self.stopLiveActivity()
            
            // Trigger app to show onboarding
            self.shouldShowOnboarding = true
            
            print("🚪 TotsDataManager: Local data reset complete")
        }
    }
    
    func deleteAccount() async throws {
        print("🗑️ TotsDataManager: Starting account deletion process")
        
        // Delete from CloudKit first
        try await cloudKitManager.deleteAccount()
        
        await MainActor.run {
            // Clear all local data
            self.recentActivities = []
            self.milestones = []
            self.growthData = []
            self.babyName = "Baby"
            self.babyBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
            self.babyProfileRecord = nil
            self.familySharingEnabled = false
            
            // Stop any running live activities
            self.stopLiveActivity()
            
            // Trigger app to show onboarding
            self.shouldShowOnboarding = true
            
            print("🗑️ TotsDataManager: Account deletion complete")
        }
    }
    
    func syncFromCloudKit() async {
        guard let profileRecord = babyProfileRecord else { 
            print("⚠️ No baby profile record available for syncing")
            return 
        }
        
        print("🔄 Starting CloudKit activity sync for profile: \(profileRecord.recordID.recordName)")
        
        do {
            let cloudActivities = try await cloudKitManager.fetchActivities(for: profileRecord.recordID)
            print("🔄 Found \(cloudActivities.count) activities in CloudKit")
            
            await MainActor.run {
                let originalCount = self.recentActivities.count
                
                // Merge cloud activities with local ones
                for cloudActivity in cloudActivities {
                    if !self.recentActivities.contains(where: { $0.id == cloudActivity.id }) {
                        self.recentActivities.append(cloudActivity)
                        print("✅ Added activity: \(cloudActivity.type.rawValue) at \(cloudActivity.time)")
                    }
                }
                
                // Sort activities by time (most recent first)
                self.recentActivities.sort { $0.time > $1.time }
                
                let newCount = self.recentActivities.count
                print("✅ Activities sync complete: \(originalCount) → \(newCount) total activities")
                
                self.updateCountdowns()
                self.updateLiveActivity()
            }
        } catch {
            print("❌ Failed to sync from CloudKit: \(error)")
        }
    }
    
    private func loadBabyProfileRecord(recordName: String) async {
        do {
            let recordID = CKRecord.ID(recordName: recordName)
            let record = try await cloudKitManager.fetchBabyProfile(recordID: recordID)
            await MainActor.run {
                self.babyProfileRecord = record
                print("✅ Baby profile record loaded successfully")
            }
        } catch {
            print("❌ Failed to load baby profile record: \(error)")
        }
    }
    
    func loadExistingBabyProfile() async {
        print("🔄 TotsDataManager: Starting loadExistingBabyProfile...")
        
        // First check if we have a stored record ID (for existing installations)
        if let recordName = UserDefaults.standard.string(forKey: "baby_profile_record_id") {
            print("🍼 Found saved baby profile record ID: \(recordName)")
            await loadBabyProfileRecord(recordName: recordName)
            return
        }
        
        // If no stored record ID, try to fetch existing profiles from CloudKit
        print("🔍 No stored record ID found, searching CloudKit for existing baby profiles...")
        do {
            let profiles = try await cloudKitManager.fetchBabyProfiles()
            print("🔍 TotsDataManager: CloudKit returned \(profiles.count) profiles")
            
            if let mostRecentProfile = profiles.first {
                await MainActor.run {
                    self.babyProfileRecord = mostRecentProfile
                    // Store the record ID for future use
                    UserDefaults.standard.set(mostRecentProfile.recordID.recordName, forKey: "baby_profile_record_id")
                    
                    // Update local data with CloudKit data
                    if let name = mostRecentProfile["name"] as? String {
                        print("🔄 Setting baby name from CloudKit: \(name)")
                        self.babyName = name
                        print("✅ Baby name updated to: \(self.babyName)")
                    }
                    if let birthDate = mostRecentProfile["birthDate"] as? Date {
                        print("🔄 Setting baby birth date from CloudKit: \(birthDate)")
                        self.babyBirthDate = birthDate
                        print("✅ Baby birth date updated to: \(self.babyBirthDate)")
                    }
                    
                    // Load goals from CloudKit
                    if let feedingGoal = mostRecentProfile["feedingGoal"] as? Int {
                        UserDefaults.standard.set(feedingGoal, forKey: "feeding_goal")
                    }
                    if let sleepGoal = mostRecentProfile["sleepGoal"] as? Double {
                        UserDefaults.standard.set(sleepGoal, forKey: "sleep_goal")
                    }
                    if let diaperGoal = mostRecentProfile["diaperGoal"] as? Int {
                        UserDefaults.standard.set(diaperGoal, forKey: "diaper_goal")
                    }
                    
                    print("✅ Found existing baby profile: \(self.babyName)")
                    print("🔄 Updated local data with CloudKit profile and goals")
                }
                
                // Also sync activities from CloudKit
                await syncFromCloudKit()
            } else {
                print("📝 No existing baby profiles found in CloudKit")
            }
        } catch {
            print("❌ Failed to fetch baby profiles from CloudKit: \(error)")
        }
    }
    
    private func createDefaultBabyProfile() async {
        do {
            // Use default values if not set
            let name = babyName.isEmpty ? "Baby" : babyName
            let birthDate = babyBirthDate
            let goals = BabyGoals(
                feeding: weeklyFeedingGoal / 7,
                sleep: weeklySleepGoal / 7.0,
                diaper: weeklyDiaperGoal / 7
            )
            
            let record = try await cloudKitManager.createBabyProfile(
                name: name,
                birthDate: birthDate,
                goals: goals
            )
            
            await MainActor.run {
                self.babyProfileRecord = record
                UserDefaults.standard.set(record.recordID.recordName, forKey: "baby_profile_record_id")
                print("✅ Default baby profile created and saved")
            }
        } catch {
            print("❌ Failed to create default baby profile: \(error)")
        }
    }
    
    func checkCloudKitSchema() async {
        let status = await schemaSetup.checkSchemaStatus()
        print(status.description)
        
        if !status.allExist {
            print("⚠️ CloudKit schema not complete. Attempting automatic setup...")
            
            // Try to create schema automatically
            do {
                try await schemaSetup.createSampleRecordsForSchema()
                print("✅ Schema created automatically!")
            } catch {
                print("❌ Automatic schema creation failed: \(error)")
                print("\n" + String(repeating: "=", count: 60))
                print("🔧 MANUAL CLOUDKIT SETUP REQUIRED")
                print(String(repeating: "=", count: 60))
                schemaSetup.printSchemaInstructions()
                print("\n💡 KEY ISSUE: The 'createdBy' field must be a REFERENCE type, not String!")
                print("   1. Go to CloudKit Console")
                print("   2. Delete any existing 'createdBy' fields that are String type") 
                print("   3. Add new 'createdBy' field as Reference to Users")
                print("   4. Do the same for 'babyProfile' field in Activity (Reference to BabyProfile)")
                print(String(repeating: "=", count: 60))
            }
        }
    }
}



// MARK: - Milestone Models

