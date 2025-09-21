import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Force tab bar style on iPad by using a custom container
            VStack(spacing: 0) {
                // Content area
                Group {
                    switch selectedTab {
                    case 0:
                        HomeView()
                    case 1:
                        ProgressView()
                    case 2:
                        MilestonesView()
                    case 3:
                        WordTrackerView()
                    case 4:
                        SettingsView()
                    default:
                        HomeView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom tab bar
                HStack(spacing: 0) {
                    TabBarButton(
                        icon: selectedTab == 0 ? "house.fill" : "house",
                        title: "Home",
                        isSelected: selectedTab == 0,
                        tag: 0,
                        selectedTab: $selectedTab
                    )
                    
                    TabBarButton(
                        icon: selectedTab == 1 ? "chart.bar.fill" : "chart.bar",
                        title: "Growth",
                        isSelected: selectedTab == 1,
                        tag: 1,
                        selectedTab: $selectedTab
                    )
                    
                    TabBarButton(
                        icon: selectedTab == 2 ? "figure.child.circle.fill" : "figure.child.circle",
                        title: "Milestones",
                        isSelected: selectedTab == 2,
                        tag: 2,
                        selectedTab: $selectedTab
                    )
                    
                    TabBarButton(
                        icon: selectedTab == 3 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right",
                        title: "Words",
                        isSelected: selectedTab == 3,
                        tag: 3,
                        selectedTab: $selectedTab
                    )
                    
                    TabBarButton(
                        icon: selectedTab == 4 ? "gearshape.fill" : "gearshape",
                        title: "Settings",
                        isSelected: selectedTab == 4,
                        tag: 4,
                        selectedTab: $selectedTab
                    )
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.systemGray4)),
                    alignment: .top
                )
            }
            .accentColor(.pink)
        } else {
            // Use regular TabView on iPhone
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
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let tag: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            selectedTab = tag
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .pink : .secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .pink : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
        .environmentObject(TotsDataManager())
}
