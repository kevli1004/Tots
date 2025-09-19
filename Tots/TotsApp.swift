import SwiftUI

@main
struct TotsApp: App {
    @StateObject private var dataManager = TotsDataManager()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
    @State private var isCheckingExistingData = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingExistingData {
                    // Simple loading view while checking CloudKit
                    VStack(spacing: 20) {
                        Image("TotsIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        Text("Tots")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Loading...")
                            .foregroundColor(.secondary)
                        
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    }
                } else if showOnboarding {
                    OnboardingView()
                        .environmentObject(dataManager)
                        .onReceive(NotificationCenter.default.publisher(for: .init("onboarding_completed"))) { _ in
                            showOnboarding = false
                        }
                } else {
                    ContentView()
                        .environmentObject(dataManager)
                }
            }
            .onAppear {
                checkForExistingUserData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("user_signed_out"))) { _ in
                print("📱 TotsApp: Received user_signed_out notification - resetting to onboarding")
                print("📱 TotsApp: Current showOnboarding = \(showOnboarding)")
                
                // Reset to show onboarding from the beginning
                showOnboarding = true
                isCheckingExistingData = false
                
                // Also make sure UserDefaults reflects this
                UserDefaults.standard.set(false, forKey: "onboarding_completed")
                
                print("📱 TotsApp: Set showOnboarding = \(showOnboarding)")
            }
            .onChange(of: dataManager.shouldShowOnboarding) { shouldShow in
                if shouldShow {
                    print("📱 TotsApp: DataManager triggered onboarding - showing sign-in")
                    showOnboarding = true
                    isCheckingExistingData = false
                    UserDefaults.standard.set(false, forKey: "onboarding_completed")
                    // Reset the flag
                    dataManager.shouldShowOnboarding = false
                }
            }
        }
    }
    
    private func checkForExistingUserData() {
        // If onboarding was already completed, skip the check
        if UserDefaults.standard.bool(forKey: "onboarding_completed") {
            return
        }
        
        // For first-time users, just show onboarding directly
        // No automatic CloudKit checking - let them choose
        showOnboarding = true
    }
}
