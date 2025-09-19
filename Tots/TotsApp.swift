import SwiftUI

@main
struct TotsApp: App {
    @StateObject private var dataManager = TotsDataManager()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
    @State private var isCheckingExistingData = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingExistingData {
                    // Show simple loading view while checking for existing data
                    VStack(spacing: 20) {
                        Image("TotsIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        Text("Tots")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Checking for your data...")
                            .foregroundColor(.secondary)
                        
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    }
                    .environmentObject(dataManager)
                } else if showOnboarding {
                    OnboardingView()
                        .environmentObject(dataManager)
                    .onReceive(NotificationCenter.default.publisher(for: .init("onboarding_completed"))) { _ in
                        showOnboarding = false
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .init("user_signed_out"))) { _ in
                        showOnboarding = true
                        isCheckingExistingData = true
                    }
                } else {
                    ContentView()
                        .environmentObject(dataManager)
                }
            }
            .onAppear {
                checkForExistingUserData()
            }
        }
    }
    
    private func checkForExistingUserData() {
        // If onboarding was already completed, skip the check
        if UserDefaults.standard.bool(forKey: "onboarding_completed") {
            isCheckingExistingData = false
            return
        }
        
        // Check if user has existing CloudKit data
        Task {
            do {
                let profiles = try await CloudKitManager.shared.fetchBabyProfiles()
                
                await MainActor.run {
                    if !profiles.isEmpty {
                        // User has existing data - skip onboarding
                        print("🎉 Found existing baby profiles, skipping onboarding")
                        UserDefaults.standard.set(true, forKey: "onboarding_completed")
                        showOnboarding = false
                    }
                    isCheckingExistingData = false
                }
            } catch {
                // If CloudKit check fails, proceed with normal onboarding flow
                print("⚠️ CloudKit check failed, proceeding with onboarding: \(error)")
                await MainActor.run {
                    isCheckingExistingData = false
                }
            }
        }
    }
}
