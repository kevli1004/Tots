import SwiftUI
import MessageUI
import UserNotifications
import AuthenticationServices


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
    @State private var enableLiveActivity = false
    @State private var showingEmailComposer = false
    @State private var isComplete = false
    @State private var userEmail = ""
    @State private var userName = ""
    @State private var isSignedIn = false
    
    @State private var totalSteps = 1 // Start with just Apple sign in
    @State private var showingSteps = false // Show steps 2-4 only after sign in
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    progressIndicator
                    
                    // Content without sliding animation
                    Group {
                        switch currentStep {
                        case 0:
                            appleSignInStep
                        case 1:
                            if showingSteps {
                                babyDetailsStepWithNav
                            }
                        case 2:
                            if showingSteps {
                                goalsStepWithNav
                            }
                        case 3:
                            if showingSteps {
                                permissionsStepWithNav
                            }
                        default:
                            appleSignInStep
                        }
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
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
    
    
    private func checkForExistingData() {
        // Check for baby name only - simplest and most reliable indicator
        let babyName = UserDefaults.standard.string(forKey: "tots_baby_name")
        let hasProfileData = !(babyName?.isEmpty ?? true)
        
        if hasProfileData {
            // Found existing baby name - skip onboarding
            UserDefaults.standard.set(true, forKey: "onboarding_completed")
            NotificationCenter.default.post(name: .init("onboarding_completed"), object: nil)
            return
        }
        
        // No local data, check CloudKit if user is signed in
        Task {
            do {
                let profiles = try await dataManager.cloudKitManager.fetchBabyProfiles()
                
                await MainActor.run {
                    if !profiles.isEmpty {
                        // Found existing CloudKit data - load it and skip onboarding
                        UserDefaults.standard.set(true, forKey: "onboarding_completed")
                        
                        // Load the profile data into the app
                        Task {
                            await dataManager.loadExistingBabyProfile()
                            await MainActor.run {
                                NotificationCenter.default.post(name: .init("onboarding_completed"), object: nil)
                            }
                        }
                    } else {
                        // No existing data - show registration steps
                        proceedToRegistration()
                    }
                }
            } catch {
                await MainActor.run {
                    // On error, show registration steps
                    proceedToRegistration()
                }
            }
        }
    }
    
    private func proceedToRegistration() {
        // Enable the registration steps
        showingSteps = true
        totalSteps = 4
        
        // Move to step 2 (baby details)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = 1
        }
    }
    
    private var appleSignInStep: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 40) {
                // App icon and welcome
                VStack(spacing: 30) {
                    Image("TotsIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 8)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6).repeatForever(autoreverses: true).delay(2), value: UUID())
                    
                    VStack(spacing: 20) {
                        Text("Welcome to Tots")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Track your baby's feeding, sleep, and diaper changes with ease")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 40)
                    }
                }
                
                // Sign in with Apple only
                VStack(spacing: 24) {
                    // Sign in with Apple button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                    
                    // Continue without signing in button
                    Button(action: {
                        continueWithoutSignIn()
                    }) {
                        HStack {
                            Image(systemName: "iphone")
                                .font(.system(size: 16, weight: .medium))
                            Text("Continue without signing in")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Sign in to sync your data across devices and share with family. You can always sign in later in Settings.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    private var progressIndicator: some View {
        VStack(spacing: 20) {
            if showingSteps {
                HStack {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? Color.purple.opacity(0.7) : Color(.systemGray5))
                            .frame(width: 10, height: 10)
                            .scaleEffect(step == currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
                        
                        if step < totalSteps - 1 {
                            Capsule()
                                .fill(step < currentStep ? Color.purple.opacity(0.7) : Color(.systemGray5))
                                .frame(height: 3)
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                }
                .padding(.horizontal, 50)
                
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 30)
        .padding(.bottom, 40)
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image("TotsIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                
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
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 20) {
                    Text("Tell us about your baby")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("This helps us personalize your experience")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Baby's Name")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        TextField("Enter baby's name", text: $babyName)
                            .font(.system(.body, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(babyName.isEmpty ? Color.clear : Color.purple.opacity(0.4), lineWidth: 2)
                                    .animation(.easeInOut(duration: 0.2), value: babyName.isEmpty)
                            )
                            .contentShape(Rectangle())
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Birth Date")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        DatePicker("Birth Date", selection: $babyBirthDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Baby age display with smooth animation
                    if !babyName.isEmpty {
                        VStack(spacing: 16) {
                            Text("\(babyName) is \(babyAge)")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                            
                            Text("🎉 Welcome to the world, \(babyName)!")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                        )
                        .padding(.top, 10)
                        .scaleEffect(1.0)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8)),
                            removal: .scale.combined(with: .opacity).animation(.easeInOut(duration: 0.3))
                        ))
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var babyDetailsStepWithNav: some View {
        ScrollView {
            VStack(spacing: 0) {
                babyDetailsContent
                navigationButtons
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var babyDetailsContent: some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Text("Tell us about your baby")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("This helps us personalize your experience")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Baby's Name")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Enter baby's name", text: $babyName)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .liquidGlassCard()
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(babyName.isEmpty ? Color.clear : Color.purple.opacity(0.4), lineWidth: 2)
                                .animation(.easeInOut(duration: 0.2), value: babyName.isEmpty)
                        )
                        .contentShape(Rectangle())
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Birth Date")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    DatePicker("Birth Date", selection: $babyBirthDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .liquidGlassCard()
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Baby age display with smooth animation
                if !babyName.isEmpty {
                    VStack(spacing: 16) {
                        Text("\(babyName) is \(babyAge)")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                        
                        Text("🎉 Welcome to the world, \(babyName)!")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.purple.opacity(0.08))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                    )
                    .padding(.top, 10)
                    .scaleEffect(1.0)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.8)),
                        removal: .scale.combined(with: .opacity).animation(.easeInOut(duration: 0.3))
                    ))
                }
            }
            .padding(.horizontal, 30)
            
            Spacer(minLength: 40)
        }
        .padding(.top, 20)
    }
    
    private var caregiverDetailsStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Caregiver Information")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if isSignedIn && !userName.isEmpty {
                    Text("Great! We've filled in your details from Apple Sign In")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text("Set up your profile and invite family members")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Name")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("Enter your name", text: $primaryCaregiverName)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .contentShape(Rectangle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(primaryCaregiverName.isEmpty ? Color.clear : Color.pink.opacity(0.3), lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Email")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    TextField("your.email@example.com", text: $caregiverEmail)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(caregiverEmail.isEmpty ? Color.clear : Color.pink.opacity(0.3), lineWidth: 2)
                        )
                }
                
                // Divider with softer styling
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
                    .padding(.vertical, 16)
                
                VStack(spacing: 16) {
                    Text("Invite Partner (Optional)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Partner's Name")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter partner's name", text: $partnerName)
                            .font(.system(.body, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(partnerName.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 2)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Partner's Email")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("partner.email@example.com", text: $partnerEmail)
                            .font(.system(.body, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(partnerEmail.isEmpty ? Color.clear : Color.blue.opacity(0.3), lineWidth: 2)
                            )
                    }
                }
                
                if !partnerName.isEmpty && !partnerEmail.isEmpty && MFMailComposeViewController.canSendMail() {
                    Button(action: {
                        showingEmailComposer = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text("Send Invitation Email")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(SleekButtonStyle())
                    .padding(.top, 12)
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
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    Text("Based on \(babyName.isEmpty ? "your baby's" : "\(babyName)'s") age (\(babyAge)), here are our recommendations:")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Age-based recommendations card
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            Text("📊")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Age-Based Recommendations")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                Text(getAgeRecommendationText())
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            VStack(spacing: 24) {
                GoalSettingInt(
                    icon: "🍼",
                    title: "Feeding Goal",
                    description: "Times per day (Recommended: \(getRecommendedFeedings()))",
                    value: $feedingGoal,
                    range: 4...12
                )
                
                GoalSettingDouble(
                    icon: "moon.zzz.fill",
                    title: "Sleep Goal",
                    description: "Hours per day (Recommended: \(String(format: "%.0f", getRecommendedSleep())))",
                    value: $sleepGoal,
                    range: 10...20
                )
                
                GoalSettingInt(
                    icon: "DiaperIcon",
                    title: "Diaper Goal",
                    description: "Changes per day (Recommended: \(getRecommendedDiapers()))",
                    value: $diaperGoal,
                    range: 4...10
                )
            }
            .padding(.horizontal, 30)
            .onAppear {
                // Set recommended values based on age
                feedingGoal = getRecommendedFeedings()
                sleepGoal = getRecommendedSleep()
                diaperGoal = getRecommendedDiapers()
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    private var goalsStepWithNav: some View {
        ScrollView {
            VStack(spacing: 0) {
                goalsContent
                navigationButtons
            }
        }
        .onTapGesture {
            // Dismiss keyboard if it's open
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var goalsContent: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Daily Goals")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    Text("Based on \(babyName.isEmpty ? "your baby's" : "\(babyName)'s") age (\(babyAge)), here are our recommendations:")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Age-based recommendations card
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            Text("📊")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Age-Based Recommendations")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                                Text(getAgeRecommendationText())
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            VStack(spacing: 24) {
                GoalSettingInt(
                    icon: "🍼",
                    title: "Feeding Goal",
                    description: "Times per day (Recommended: \(getRecommendedFeedings()))",
                    value: $feedingGoal,
                    range: 4...12
                )
                
                GoalSettingDouble(
                    icon: "moon.zzz.fill",
                    title: "Sleep Goal",
                    description: "Hours per day (Recommended: \(String(format: "%.0f", getRecommendedSleep())))",
                    value: $sleepGoal,
                    range: 10...20
                )
                
                GoalSettingInt(
                    icon: "DiaperIcon",
                    title: "Diaper Goal",
                    description: "Changes per day (Recommended: \(getRecommendedDiapers()))",
                    value: $diaperGoal,
                    range: 4...10
                )
            }
            .padding(.horizontal, 30)
            .onAppear {
                // Set recommended values based on age
                feedingGoal = getRecommendedFeedings()
                sleepGoal = getRecommendedSleep()
                diaperGoal = getRecommendedDiapers()
            }
            
            Spacer(minLength: 40)
        }
        .padding(.top, 40)
    }
    
    private var permissionsStep: some View {
        VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Text("Enable Features")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("These features help you stay on top of your baby's needs")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 24) {
                    PermissionRow(
                        icon: "iphone",
                        title: "Live Activities",
                        description: "See real-time updates on your lock screen",
                        isEnabled: $enableLiveActivity,
                        color: .purple
                    )
                }
                .padding(.horizontal, 30)
                
                VStack(spacing: 20) {
                    Button(action: completeOnboarding) {
                        HStack(spacing: 10) {
                            Text("Get Started")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple.opacity(0.6)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(SleekButtonStyle())
                    .disabled(babyName.isEmpty)
                    .opacity(babyName.isEmpty ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: babyName.isEmpty)
                    
                    Text("You can change these settings anytime in the Settings tab")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    if babyName.isEmpty {
                        Text("⚠️ Baby name is required to continue")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 30)
                
            Spacer()
        }
        .padding(.top, 40)
        .onTapGesture {
            // Dismiss keyboard if it's open
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var permissionsStepWithNav: some View {
        ScrollView {
            VStack(spacing: 0) {
                permissionsContent
                navigationButtons
            }
        }
        .onTapGesture {
            // Dismiss keyboard if it's open
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var permissionsContent: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Text("Enable Features")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("These features help you stay on top of your baby's needs")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 24) {
                PermissionRow(
                    icon: "iphone",
                    title: "Live Activities",
                    description: "See real-time updates on your lock screen",
                    isEnabled: $enableLiveActivity,
                    color: .purple
                )
            }
            .padding(.horizontal, 30)
            
            VStack(spacing: 20) {
                Button(action: completeOnboarding) {
                    HStack(spacing: 10) {
                        Text("Get Started")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.semibold)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple.opacity(0.6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(SleekButtonStyle())
                .disabled(babyName.isEmpty)
                .opacity(babyName.isEmpty ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: babyName.isEmpty)
                
                Text("You can change these settings anytime in the Settings tab")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                if babyName.isEmpty {
                    Text("⚠️ Baby name is required to continue")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer(minLength: 40)
        }
        .padding(.top, 40)
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentStep -= 1
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(SleekButtonStyle())
            }
            
            Spacer()
            
            if currentStep < totalSteps - 1 {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        currentStep += 1
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Next")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(canProceed ? Color.purple.opacity(0.8) : Color.gray)
                    .cornerRadius(12)
                }
                .buttonStyle(SleekButtonStyle())
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.2), value: canProceed)
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Extract user information
                if let email = appleIDCredential.email {
                    userEmail = email
                    caregiverEmail = email
                }
                
                if let fullName = appleIDCredential.fullName {
                    let firstName = fullName.givenName ?? ""
                    let lastName = fullName.familyName ?? ""
                    userName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                    if !userName.isEmpty {
                        primaryCaregiverName = userName
                    } else {
                        primaryCaregiverName = "Parent"  // Default fallback
                    }
                } else {
                    primaryCaregiverName = "Parent"  // Default when no name provided
                }
                
                isSignedIn = true
                
                
                // Now check for existing profiles
                checkForExistingData()
            }
        case .failure(let error):
            // On sign in failure, show registration steps
            proceedToRegistration()
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return isSignedIn
        case 1: return !babyName.isEmpty
        case 2: return true
        case 3: return true
        default: return false
        }
    }
    
    private func continueWithoutSignIn() {
        // Set flag to indicate user is using local storage only
        UserDefaults.standard.set(false, forKey: "cloudkit_enabled")
        UserDefaults.standard.set(true, forKey: "local_storage_only")
        
        // Check for baby name only - simplest and most reliable indicator
        let babyName = UserDefaults.standard.string(forKey: "tots_baby_name")
        let hasProfileData = !(babyName?.isEmpty ?? true)
        
        if hasProfileData {
            // Found existing baby name - skip onboarding
            UserDefaults.standard.set(true, forKey: "onboarding_completed")
            NotificationCenter.default.post(name: .init("onboarding_completed"), object: nil)
        } else {
            // No baby name found - proceed to registration steps
            proceedToRegistration()
        }
    }
    
    // MARK: - Age-based Recommendations
    
    private func getAgeInDays() -> Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
        return max(0, days)
    }
    
    private func getRecommendedFeedings() -> Int {
        let days = getAgeInDays()
        switch days {
        case 0...7: return 10      // Newborn: 8-12 times
        case 8...30: return 9      // 1 week - 1 month: 8-10 times
        case 31...90: return 8     // 1-3 months: 6-8 times
        case 91...180: return 7    // 3-6 months: 5-7 times
        case 181...365: return 6   // 6-12 months: 4-6 times
        default: return 5          // 12+ months: 3-5 times
        }
    }
    
    private func getRecommendedSleep() -> Double {
        let days = getAgeInDays()
        switch days {
        case 0...30: return 16.0   // Newborn: 14-18 hours
        case 31...90: return 15.0  // 1-3 months: 14-16 hours
        case 91...180: return 14.0 // 3-6 months: 12-16 hours
        case 181...365: return 13.0 // 6-12 months: 11-15 hours
        default: return 12.0       // 12+ months: 10-14 hours
        }
    }
    
    private func getRecommendedDiapers() -> Int {
        let days = getAgeInDays()
        switch days {
        case 0...7: return 8       // Newborn: 6-10 changes
        case 8...30: return 8      // 1 week - 1 month: 6-8 changes
        case 31...90: return 7     // 1-3 months: 5-7 changes
        case 91...180: return 6    // 3-6 months: 4-6 changes
        case 181...365: return 6   // 6-12 months: 4-6 changes
        default: return 5          // 12+ months: 3-5 changes
        }
    }
    
    private func getAgeRecommendationText() -> String {
        let days = getAgeInDays()
        switch days {
        case 0...7: return "Newborn stage - frequent feeding and sleeping"
        case 8...30: return "Early infancy - establishing routines"
        case 31...90: return "Young infant - longer sleep stretches developing"
        case 91...180: return "Older infant - more predictable patterns"
        case 181...365: return "Mobile baby - solid foods being introduced"
        default: return "Toddler stage - established eating and sleeping patterns"
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
        dataManager.babyName = babyName.isEmpty ? "Baby" : babyName
        dataManager.babyBirthDate = babyBirthDate
        
        // Ensure we have a caregiver name fallback
        let finalCaregiverName = primaryCaregiverName.isEmpty ? "Parent" : primaryCaregiverName
        
        // Save caregiver info
        UserDefaults.standard.set(finalCaregiverName, forKey: "primary_caregiver_name")
        UserDefaults.standard.set(caregiverEmail, forKey: "primary_caregiver_email")
        UserDefaults.standard.set(partnerName, forKey: "partner_name")
        UserDefaults.standard.set(partnerEmail, forKey: "partner_email")
        
        // Save goals (you might want to add these to DataManager)
        UserDefaults.standard.set(feedingGoal, forKey: "feeding_goal")
        UserDefaults.standard.set(sleepGoal, forKey: "sleep_goal")
        UserDefaults.standard.set(diaperGoal, forKey: "diaper_goal")
        
        // Save preferences
        UserDefaults.standard.set(enableLiveActivity, forKey: "live_activity_enabled")
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        
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
            } else {
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

// MARK: - Goal Setting Component (unified for Int and Double)
struct GoalSettingInt: View {
    let icon: String
    let title: String
    let description: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if icon.contains(".") || icon == "DiaperIcon" {
                    // SF Symbol or custom image
                    if icon == "DiaperIcon" {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                    }
                } else {
                    // Emoji
                    Text(icon)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(value)")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.12))
                    )
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
            }
            
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                .accentColor(.purple)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .liquidGlassCard()
    }
}

struct GoalSettingDouble: View {
    let icon: String
    let title: String
    let description: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if icon.contains(".") || icon == "DiaperIcon" {
                    // SF Symbol or custom image
                    if icon == "DiaperIcon" {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                    }
                } else {
                    // Emoji
                    Text(icon)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.0f", value))
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.12))
                    )
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: value)
            }
            
            Slider(value: $value, in: range, step: 1)
                .accentColor(.purple)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .liquidGlassCard()
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
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isEnabled ? color.opacity(0.3) : Color(.systemGray4), lineWidth: isEnabled ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
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

// MARK: - Button Styles
struct SleekButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Keyboard Adaptive Modifier
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.cgRectValue.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptive())
    }
}

#Preview {
    OnboardingView()
        .environmentObject(TotsDataManager())
}
