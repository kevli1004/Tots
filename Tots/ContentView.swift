import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            ProgressView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                    Text("Growth")
                }
                .tag(1)
            
            MilestonesView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "figure.child.circle.fill" : "figure.child.circle")
                    Text("Milestones")
                }
                .tag(2)
            
            WordTrackerView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    Text("Words")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.pink)
    }
}

#Preview {
    ContentView()
        .environmentObject(TotsDataManager())
}
