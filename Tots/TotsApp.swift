import SwiftUI

@main
struct TotsApp: App {
    @StateObject private var dataManager = TotsDataManager()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
    
    var body: some Scene {
        WindowGroup {
            if showOnboarding {
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
    }
}
