import SwiftUI
import MessageUI
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var currentStep = 0
    @State private var babyName = ""
    @State private var babyBirthDate = Date()
    @State private var primaryCaregiverName = ""
    @State private var caregiverEmail = ""
    @State private var partnerName = ""
    @State private var partnerEmail = ""
    @State private var feedingGoal = 8
    @State private var sleepGoal = 15.0
    @State private var diaperGoal = 6
    @State private var enableNotifications = true
    @State private var enableLiveActivity = true
    @State private var showingEmailComposer = false
    @State private var isComplete = false
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    babyDetailsStep.tag(1)
                    caregiverDetailsStep.tag(2)
                    goalsStep.tag(3)
                    permissionsStep.tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                navigationButtons
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.pink.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingEmailComposer) {
            EmailComposerView(
                toEmail: partnerEmail,
                subject: "Join me on Tots - Baby Tracking App",
                body: """
                Hi \(partnerName.isEmpty ? "there" : partnerName),
                
                I've started using Tots to track \(babyName.isEmpty ? "our baby's" : "\(babyName)'s") daily activities. Would you like to join me so we can both stay updated?
                
                Download Tots from the App Store and we can share tracking data!
                
                Love,
                \(primaryCaregiverName)
                """
            )
        }
    }
    
    private var progressIndicator: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.pink : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut, value: currentStep)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color.pink : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("👶")
                    .font(.system(size: 80))
                
                Text("Welcome to Tots")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Your personal baby tracking companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                FeatureRow(icon: "📊", title: "Track Activities", description: "Log feeding, sleeping, diaper changes")
                FeatureRow(icon: "📈", title: "Monitor Progress", description: "See patterns and growth over time")
                FeatureRow(icon: "📱", title: "Live Activities", description: "Quick updates on your lock screen")
                FeatureRow(icon: "👨‍👩‍👧‍👦", title: "Share with Family", description: "Keep everyone in the loop")
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 30)
    }
    
    private var babyDetailsStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Tell us about your baby")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This helps us personalize your experience")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Baby's Name")
                        .font(.headline)
                    TextField("Enter baby's name", text: $babyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birth Date")
                        .font(.headline)
                    DatePicker("Birth Date", selection: $babyBirthDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                // Baby age display
                if !babyName.isEmpty {
                    VStack(spacing: 8) {
                        Text("\(babyName) is \(babyAge)")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.pink)
                        
                        Text("🎉 Welcome to the world, \(babyName)!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var caregiverDetailsStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Caregiver Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Set up your profile and invite family members")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)
                    TextField("Enter your name", text: $primaryCaregiverName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Email")
                        .font(.headline)
                    TextField("your.email@example.com", text: $caregiverEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                Text("Invite Partner (Optional)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Partner's Name")
                        .font(.subheadline)
                    TextField("Enter partner's name", text: $partnerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Partner's Email")
                        .font(.subheadline)
                    TextField("partner.email@example.com", text: $partnerEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                if !partnerName.isEmpty && !partnerEmail.isEmpty && MFMailComposeViewController.canSendMail() {
                    Button(action: {
                        showingEmailComposer = true
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Send Invitation Email")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var goalsStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Daily Goals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Set targets to help track your baby's routine")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 24) {
                GoalSetting(
                    icon: "🍼",
                    title: "Feeding Goal",
                    description: "Times per day",
                    value: $feedingGoal,
                    range: 4...12
                )
                
                GoalSetting(
                    icon: "😴",
                    title: "Sleep Goal",
                    description: "Hours per day",
                    value: $sleepGoal,
                    range: 10...20
                )
                
                GoalSetting(
                    icon: "🧷",
                    title: "Diaper Goal",
                    description: "Changes per day",
                    value: $diaperGoal,
                    range: 4...10
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var permissionsStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Enable Features")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("These features help you stay on top of your baby's needs")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                PermissionRow(
                    icon: "bell.fill",
                    title: "Push Notifications",
                    description: "Get reminders for feeding, sleeping, and diaper changes",
                    isEnabled: $enableNotifications,
                    color: .blue
                )
                
                PermissionRow(
                    icon: "iphone",
                    title: "Live Activities",
                    description: "See real-time updates on your lock screen",
                    isEnabled: $enableLiveActivity,
                    color: .purple
                )
            }
            .padding(.horizontal, 30)
            
            VStack(spacing: 16) {
                Button(action: completeOnboarding) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .disabled(babyName.isEmpty || primaryCaregiverName.isEmpty)
                
                Text("You can change these settings anytime in the Settings tab")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .foregroundColor(.pink)
            }
            
            Spacer()
            
            if currentStep < totalSteps - 1 {
                Button("Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .foregroundColor(.pink)
                .disabled(!canProceed)
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 30)
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !babyName.isEmpty
        case 2: return !primaryCaregiverName.isEmpty
        case 3: return true
        case 4: return true
        default: return false
        }
    }
    
    private var babyAge: String {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year, .month, .day], from: babyBirthDate, to: now)
        
        let years = ageComponents.year ?? 0
        let months = ageComponents.month ?? 0
        let days = ageComponents.day ?? 0
        
        if years >= 1 {
            return months > 0 ? "\(years)y \(months)m old" : "\(years)y old"
        } else if months >= 1 {
            return days > 0 ? "\(months)m \(days)d old" : "\(months)m old"
        } else {
            return "\(days) days old"
        }
    }
    
    private func completeOnboarding() {
        // Save all data to DataManager
        dataManager.babyName = babyName
        dataManager.babyBirthDate = babyBirthDate
        
        // Save caregiver info
        UserDefaults.standard.set(primaryCaregiverName, forKey: "primary_caregiver_name")
        UserDefaults.standard.set(caregiverEmail, forKey: "primary_caregiver_email")
        UserDefaults.standard.set(partnerName, forKey: "partner_name")
        UserDefaults.standard.set(partnerEmail, forKey: "partner_email")
        
        // Save goals (you might want to add these to DataManager)
        UserDefaults.standard.set(feedingGoal, forKey: "feeding_goal")
        UserDefaults.standard.set(sleepGoal, forKey: "sleep_goal")
        UserDefaults.standard.set(diaperGoal, forKey: "diaper_goal")
        
        // Save preferences
        UserDefaults.standard.set(enableNotifications, forKey: "notifications_enabled")
        UserDefaults.standard.set(enableLiveActivity, forKey: "live_activity_enabled")
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        
        // Request permissions if enabled
        if enableNotifications {
            requestNotificationPermission()
        }
        
        if enableLiveActivity {
            // Live Activity permissions are handled automatically when first requested
            dataManager.startLiveActivity()
        }
        
        // Notify the app that onboarding is complete
        NotificationCenter.default.post(name: .init("onboarding_completed"), object: nil)
        
        isComplete = true
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct GoalSetting<T: BinaryFloatingPoint & CVarArg>: View where T: Strideable, T.Stride: BinaryFloatingPoint {
    let icon: String
    let title: String
    let description: String
    @Binding var value: T
    let range: ClosedRange<T>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f", Double(value)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
            }
            
            Slider(value: $value, in: range, step: 1)
                .accentColor(.pink)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GoalSetting<T: BinaryInteger & CVarArg>: View where T: Strideable, T.Stride: SignedInteger {
    let icon: String
    let title: String
    let description: String
    @Binding var value: T
    let range: ClosedRange<T>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(icon)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = T($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                .accentColor(.pink)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Email Composer

struct EmailComposerView: UIViewControllerRepresentable {
    let toEmail: String
    let subject: String
    let body: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([toEmail])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: EmailComposerView
        
        init(_ parent: EmailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(TotsDataManager())
}
