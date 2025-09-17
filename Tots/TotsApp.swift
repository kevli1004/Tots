import SwiftUI

@main
struct TotsApp: App {
    @StateObject private var dataManager = TotsDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
