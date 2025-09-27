import SwiftUI
import CloudKit
import AuthenticationServices
import StoreKit

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

struct SettingsView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingFamilyInvite = false
    @State private var showingPersonalDetails = false
    @State private var isSettingUpCloudKit = false
    @State private var cloudKitSetupMessage = ""
    // Computed property based on CloudKit sign-in state
    private var isLocalStorageOnly: Bool {
        return !dataManager.cloudKitManager.isSignedIn
    }
    @State private var showingCloudKitShare = false
    @State private var showingFamilyManager = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var showingClearDataConfirmation = false
    @State private var showingClearLocalDataConfirmation = false
    @State private var isDeletingAccount = false
    @State private var isClearingData = false
    @State private var familyMembers: [FamilyMember] = []
    @State private var shareDelegate: ShareControllerDelegate?
    @State private var profileImageUpdateTrigger = false
    @State private var showingExportSheet = false
    @State private var showingTrackingGoals = false
    @State private var showingTerms = false
    @State private var showingPrivacyPolicy = false
    @State private var appearanceMode: AppearanceMode = .light
    
    var body: some View {
        ZStack {
            // Liquid animated background
            LiquidBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Baby profile
                    babyProfileView
                        .id(profileImageUpdateTrigger)
                    
                    // Sync status indicator
                    syncStatusView
                    
                    // App preferences (appearance & live activity)
                    appPreferencesView
                    
                    // Family sharing (only show when signed in)
                    if !isLocalStorageOnly {
                        familySharingView
                    }
                    
                    // Settings options (without appearance & live activity)
                    otherSettingsView
                    
                    // Support section
                    supportSectionView
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showingFamilyInvite) {
            FamilyInviteView()
        }
        .sheet(isPresented: $showingPersonalDetails) {
            PersonalDetailsView()
                .onDisappear {
                    // Trigger refresh of profile view when returning from PersonalDetailsView
                    profileImageUpdateTrigger.toggle()
                }
        }
        .sheet(isPresented: $showingFamilyManager) {
            FamilyManagerView(familyMembers: $familyMembers)
                .environmentObject(dataManager)
        }
        .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            if dataManager.cloudKitManager.isSignedIn {
                Button("Delete Account", role: .destructive) {
                    isDeletingAccount = true
                    Task {
                        do {
                            try await dataManager.deleteAccount()
                        } catch {
                            // Even if CloudKit deletion fails, still sign out locally
                            await dataManager.signOut()
                        }
                        await MainActor.run {
                            isDeletingAccount = false
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your data from CloudKit and cannot be undone.")
        }
        .confirmationDialog("Sign Out", isPresented: $showingLogoutConfirmation, titleVisibility: .visible) {
            if dataManager.cloudKitManager.isSignedIn {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await dataManager.signOut()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will sign you out and clear all local data. Your CloudKit data will remain safe.")
        }
        .confirmationDialog("Clear Cloud Data", isPresented: $showingClearDataConfirmation, titleVisibility: .visible) {
            Button("Clear All Data", role: .destructive) {
                isClearingData = true
                Task {
                    do {
                        try await dataManager.clearCloudData()
                    } catch {
                        print("❌ Error clearing cloud data: \(error)")
                    }
                    await MainActor.run {
                        isClearingData = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your data from both CloudKit and this device, but you'll remain signed in. This cannot be undone.")
        }
        .confirmationDialog("Clear Local Data", isPresented: $showingClearLocalDataConfirmation, titleVisibility: .visible) {
            Button("Clear All Data", role: .destructive) {
                clearLocalData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your local data including activities, growth records, milestones, and words. This cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ActivityViewController(activityItems: [generateCSVFile()])
        }
        .sheet(isPresented: $showingTrackingGoals) {
            TrackingGoalsView()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingTerms) {
            TermsAndConditionsView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            loadAppearanceMode()
            // Debug: Log current sign-in state
            print("🔍 SettingsView onAppear: isSignedIn = \(dataManager.cloudKitManager.isSignedIn), isLocalStorageOnly = \(isLocalStorageOnly)")
        }
    }
    
    // MARK: - Appearance Mode Properties
    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    private var currentAppearanceText: String {
        switch appearanceMode {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    // MARK: - Appearance Mode Methods
    private func loadAppearanceMode() {
        let savedMode = UserDefaults.standard.string(forKey: "appearance_mode") ?? "light"
        appearanceMode = AppearanceMode(rawValue: savedMode) ?? .light
    }
    
    private func setAppearanceMode(_ mode: AppearanceMode) {
        appearanceMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "appearance_mode")
        
        // Apply to the entire app
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            switch mode {
            case .light:
                window.overrideUserInterfaceStyle = .light
            case .dark:
                window.overrideUserInterfaceStyle = .dark
            case .system:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
    
    private func exportDataAsCSV() {
        showingExportSheet = true
    }
    
    
    private func generateCSVFile() -> URL {
        let csvContent = generateCSVContent()
        let fileName = "tots_data_\(Date().formatted(date: .numeric, time: .omitted)).csv"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            // Ignore file writing errors
        }
        
        return fileURL
    }
    
    private func generateCSVContent() -> String {
        var csvContent = ""
        
        // Activities CSV
        csvContent += "ACTIVITIES\n"
        csvContent += "Date,Time,Type,Details,Duration (minutes),Notes\n"
        
        let sortedActivities = dataManager.recentActivities.sorted { $0.time > $1.time }
        for activity in sortedActivities {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            
            let date = dateFormatter.string(from: activity.time).replacingOccurrences(of: ",", with: ";")
            let type = activity.type.name
            let details = (activity.details ?? "").replacingOccurrences(of: ",", with: ";")
            let duration = activity.duration?.description ?? ""
            let notes = (activity.notes ?? "").replacingOccurrences(of: ",", with: ";")
            
            csvContent += "\"\(date)\",\(type),\"\(details)\",\(duration),\"\(notes)\"\n"
        }
        
        // Growth Data CSV
        csvContent += "\nGROWTH DATA\n"
        csvContent += "Date,Weight (kg),Height (cm),Head Circumference (cm)\n"
        
        let sortedGrowthData = dataManager.growthData.sorted { $0.date > $1.date }
        for entry in sortedGrowthData {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            let date = dateFormatter.string(from: entry.date)
            let weight = String(format: "%.1f", entry.weight)
            let height = String(format: "%.1f", entry.height)
            let headCirc = String(format: "%.1f", entry.headCircumference)
            
            csvContent += "\(date),\(weight),\(height),\(headCirc)\n"
        }
        
        // Words CSV
        csvContent += "\nWORDS\n"
        csvContent += "Word,Category,Date First Said,Notes\n"
        
        let sortedWords = dataManager.words.sorted { $0.dateFirstSaid > $1.dateFirstSaid }
        for word in sortedWords {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            let wordText = word.word.replacingOccurrences(of: ",", with: ";")
            let category = word.category.rawValue
            let date = dateFormatter.string(from: word.dateFirstSaid)
            let notes = word.notes.replacingOccurrences(of: ",", with: ";")
            
            csvContent += "\"\(wordText)\",\(category),\(date),\"\(notes)\"\n"
        }
        
        return csvContent
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var babyProfileView: some View {
        Button(action: {
            showingPersonalDetails = true
        }) {
            HStack(spacing: 16) {
                // Baby avatar - show profile picture if available, otherwise show TotsIcon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.blue.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    if let profileImageData = UserDefaults.standard.data(forKey: "baby_profile_image"),
                       let profileImage = UIImage(data: profileImageData) {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .shadow(color: .black.opacity(0.1), radius: 1)
                            )
                    } else {
                        Image("TotsIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(dataManager.babyName.isEmpty ? "Enter your baby's name" : dataManager.babyName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(dataManager.babyAge)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(.regularMaterial)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var syncStatusView: some View {
        HStack(spacing: 12) {
            // Sync status icon
            Group {
                if isLocalStorageOnly {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.blue)
                } else {
                    switch dataManager.syncStatus {
                    case .synced:
                        Image(systemName: "checkmark.icloud")
                            .foregroundColor(.green)
                    case .syncing:
                        Image(systemName: "arrow.clockwise.icloud")
                            .foregroundColor(.blue)
                    case .pendingSync(let count):
                        Image(systemName: "exclamationmark.icloud")
                            .foregroundColor(.orange)
                    case .error:
                        Image(systemName: "xmark.icloud")
                            .foregroundColor(.red)
                    case .offline:
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.gray)
                    }
                }
            }
            .font(.system(size: 16, weight: .medium))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(syncStatusTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(syncStatusSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Manual sync button for pending items
            if case .pendingSync = dataManager.syncStatus, dataManager.isConnected {
                Button("Sync Now") {
                    Task {
                        await dataManager.forceSyncNow()
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(12)
    }
    
    private var syncStatusTitle: String {
        if isLocalStorageOnly {
            return "Local Data"
        }
        
        switch dataManager.syncStatus {
        case .synced:
            return "All Data Synced"
        case .syncing:
            return "Syncing..."
        case .pendingSync(let count):
            return "\(count) Items Pending"
        case .error:
            return "Sync Error"
        case .offline:
            return "Offline"
        }
    }
    
    private var syncStatusSubtitle: String {
        if isLocalStorageOnly {
            return "All data will sync when you sign in"
        }
        
        switch dataManager.syncStatus {
        case .synced:
            return "Your data is up to date across all devices"
        case .syncing:
            return "Uploading your latest activities to CloudKit"
        case .pendingSync(let count):
            return "\(count) activities will sync when connection improves"
        case .error(let message):
            return "Sync failed: \(message)"
        case .offline:
            return "Data will sync automatically when online"
        }
    }
    
    private var familySharingView: some View {
        VStack(spacing: 16) {
            // Only show family sharing when signed in to CloudKit
            if !isLocalStorageOnly {
                // Single Family Sharing Button
                Button(action: {
                    Task {
                        await manageFamilySharing()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Manage Family Sharing")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Text("Share baby tracking with family")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .liquidGlassCard()
                }
            }
            
            // Show any error messages
            if !cloudKitSetupMessage.isEmpty {
                Text(cloudKitSetupMessage)
                    .font(.caption)
                    .foregroundColor(cloudKitSetupMessage.contains("❌") ? .red : .secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
        }
    }
    
    private var appPreferencesView: some View {
        VStack(spacing: 16) {
            // Appearance mode toggle
            HStack(spacing: 12) {
                Image(systemName: "moon.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Appearance")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Choose between light and dark mode")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("Light") {
                        setAppearanceMode(.light)
                    }
                    Button("Dark") {
                        setAppearanceMode(.dark)
                    }
                    Button("System") {
                        setAppearanceMode(.system)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentAppearanceText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Live Activity toggle
            HStack(spacing: 12) {
                Image(systemName: "app.badge")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Activity")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    #if targetEnvironment(simulator)
                    Text("Not supported in iOS Simulator - use physical device")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    #else
                    Text("Show feeding & diaper countdowns on lock screen")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    #endif
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { dataManager.widgetEnabled },
                    set: { enabled in
                        dataManager.widgetEnabled = enabled
                        if enabled {
                            dataManager.startLiveActivity()
                        } else {
                            dataManager.stopLiveActivity()
                        }
                    }
                ))
                    .labelsHidden()
                    #if targetEnvironment(simulator)
                    .disabled(true)
                    #endif
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .liquidGlassCard()
    }
    
    private var otherSettingsView: some View {
        VStack(spacing: 16) {
            
            // Home Screen Widget toggle - hidden for now
            /*
            HStack(spacing: 12) {
                Image(systemName: "widget.small")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Home Screen Widget")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Add Tots summary widget to your home screen")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $dataManager.widgetEnabled)
                    .labelsHidden()
            }
            .padding(.vertical, 12)
            */
            
            SettingsRow(
                icon: "target",
                title: "Edit tracking goals",
                action: { showingTrackingGoals = true }
            )
            
            // Hidden settings sections
            /*
            SettingsRow(
                icon: "flag.fill",
                title: "Goals & milestones",
                action: { /* Navigate to goals */ }
            )
            
            SettingsRow(
                icon: "clock.fill",
                title: "Activity history",
                action: { /* Navigate to history */ }
            )
            
            SettingsRow(
                icon: "globe",
                title: "Language",
                action: { /* Navigate to language */ }
            )
            
            SettingsRow(
                icon: "bell.fill",
                title: "Notifications",
                action: { /* Navigate to notifications */ }
            )
            */
        }
    }
    
    private var supportSectionView: some View {
        VStack(spacing: 16) {
            SettingsRow(
                icon: "doc.text.fill",
                title: "Terms and Conditions",
                action: { showingTerms = true }
            )
            
            SettingsRow(
                icon: "shield.fill",
                title: "Privacy Policy",
                action: { showingPrivacyPolicy = true }
            )
            
            SettingsRow(
                icon: "envelope.fill",
                title: "Support Email",
                action: { 
                    if let url = URL(string: "mailto:support@growwithtots.com") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            
            SettingsRow(
                icon: "star.fill",
                title: "Rate Tots",
                action: { 
                    // Open App Store page directly for rating
                    if let url = URL(string: "https://apps.apple.com/app/id6752828411?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            
            // Hidden for now
            /*
            SettingsRow(
                icon: "megaphone.fill",
                title: "Feature Requests",
                action: { /* Open feedback */ }
            )
            */
            
            // Data management section removed
            
            Divider()
                .padding(.vertical, 8)
            
            // Conditional account management based on storage type
            if isLocalStorageOnly {
                // Clear local data option for local storage users - moved to top
                SettingsRow(
                    icon: "trash.fill",
                    title: isClearingData ? "Clearing Data..." : "Clear Local Data",
                    titleColor: .red,
                    action: {
                        if !isClearingData {
                            showingClearLocalDataConfirmation = true
                        }
                    }
                )
                
                // For local storage users, show sign in with Apple option
                VStack(spacing: 12) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignInFromSettings(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    
                    Text("Sign in to sync your data across devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            } else {
                // For CloudKit users, show clear data, delete and sign out options
                SettingsRow(
                    icon: "trash.circle.fill",
                    title: isClearingData ? "Clearing Data..." : "Clear Cloud Data",
                    titleColor: .orange,
                    action: { 
                        if !isClearingData {
                            showingClearDataConfirmation = true 
                        }
                    }
                )
                
                SettingsRow(
                    icon: "trash.fill",
                    title: isDeletingAccount ? "Deleting Account..." : "Delete Account",
                    titleColor: .red,
                    action: { 
                        if !isDeletingAccount {
                            showingDeleteConfirmation = true 
                        }
                    }
                )
                
                SettingsRow(
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    title: "Sign Out",
                    action: { showingLogoutConfirmation = true }
                )
            }
        }
    }
    
    // MARK: - CloudKit Setup Methods
    
    private func manageFamilySharing() async {
        print("🔗 Managing family sharing button tapped")
        
        // Ensure family sharing is always active - create share if needed
        do {
            // Check if we have an active share, create one if not
            var activeShare = await dataManager.cloudKitManager.activeShare
            if activeShare == nil {
                print("🔗 No active share, creating one...")
                activeShare = try await dataManager.shareBabyProfile()
            }
            
            // Fetch family members
            let members = try await dataManager.fetchFamilyMembers()
            await MainActor.run {
                familyMembers = members
                showingFamilyManager = true
            }
        } catch {
            print("❌ Error setting up family sharing: \(error)")
            await MainActor.run {
                cloudKitSetupMessage = "❌ Failed to setup family sharing: \(error.localizedDescription)"
            }
        }
    }
    
    private func presentCloudKitSharingController(share: CKShare) {
        // Get the share URL directly from CloudKit
        Task {
            do {
                guard let shareURL = share.url else {
                    print("❌ No URL available for CloudKit share")
                    return
                }
                await MainActor.run {
                    presentNativeShareSheet(with: shareURL)
                }
            }
        }
    }
    
    private func presentNativeShareSheet(with url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // Create share items
        let shareText = "Join our family baby tracker! I'd like to share our baby's tracking data with you. Tap the link to join and help track activities, feeding, sleep, and more!"
        let shareItems: [Any] = [shareText, url]
        
        // Create native share sheet
        let activityController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityController.modalPresentationStyle = .formSheet
        
        // Configure for iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Find the root view controller
        var rootViewController = window.rootViewController
        while let presented = rootViewController?.presentedViewController {
            rootViewController = presented
        }
        
        rootViewController?.present(activityController, animated: true)
    }
    
    private func signInToCloudKit() {
        print("🔄 SettingsView signInToCloudKit called")
        self.isSettingUpCloudKit = true
        cloudKitSetupMessage = "Signing in to CloudKit..."
        
        Task {
            do {
                // Sign in to CloudKit and upload local data
                print("🔄 Calling dataManager.signInToCloudKit()")
                try await dataManager.signInToCloudKit()
                
                await MainActor.run {
                    print("✅ CloudKit sign-in successful, isSignedIn = \(dataManager.cloudKitManager.isSignedIn)")
                    cloudKitSetupMessage = "✅ Successfully signed in! Your data is now syncing."
                    isSettingUpCloudKit = false
                    // isLocalStorageOnly is now computed from CloudKitManager.isSignedIn
                }
                
                // Clear message after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    cloudKitSetupMessage = ""
                }
            } catch {
                print("❌ CloudKit sign-in failed: \(error)")
                await MainActor.run {
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("No iCloud account found") {
                        cloudKitSetupMessage = "❌ Please sign in to iCloud in Settings app first, then try again."
                    } else if errorMessage.contains("restricted") {
                        cloudKitSetupMessage = "❌ iCloud access is restricted. Check parental controls or device restrictions."
                    } else if errorMessage.contains("temporarily unavailable") {
                        cloudKitSetupMessage = "❌ iCloud is temporarily unavailable. Please try again later."
                    } else {
                        cloudKitSetupMessage = "❌ Sign in failed: \(errorMessage)"
                    }
                    isSettingUpCloudKit = false
                }
            }
        }
    }
    
    private func handleAppleSignInFromSettings(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Successfully signed in with Apple ID
                print("🍎 Apple ID sign-in successful, proceeding to CloudKit sign-in")
                // Now try to sign in to CloudKit
                self.signInToCloudKit()
            }
        case .failure(let error):
            print("❌ Apple ID sign-in failed: \(error)")
            cloudKitSetupMessage = "❌ Sign in cancelled or failed: \(error.localizedDescription)"
            isSettingUpCloudKit = false
        }
    }
    
    private func clearLocalData() {
        isClearingData = true
        
        Task {
            // Clear all local data
            await MainActor.run {
                // Clear activities
                dataManager.recentActivities.removeAll()
                
                // Clear growth data
                dataManager.growthData.removeAll()
                
                // Clear milestones
                dataManager.milestones.removeAll()
                
                // Clear words
                dataManager.words.removeAll()
                
                // Clear UserDefaults data
                UserDefaults.standard.removeObject(forKey: "baby_name")
                UserDefaults.standard.removeObject(forKey: "baby_birth_date")
                UserDefaults.standard.removeObject(forKey: "primary_caregiver_name")
                UserDefaults.standard.removeObject(forKey: "baby_profile_image")
                
                // Clear goals
                UserDefaults.standard.removeObject(forKey: "feeding_goal")
                UserDefaults.standard.removeObject(forKey: "sleep_goal")
                UserDefaults.standard.removeObject(forKey: "diaper_goal")
                UserDefaults.standard.removeObject(forKey: "feeding_interval")
                UserDefaults.standard.removeObject(forKey: "pumping_interval")
                UserDefaults.standard.removeObject(forKey: "diaper_interval")
                
                // Clear timer states
                UserDefaults.standard.removeObject(forKey: "breastfeedingStartTime")
                UserDefaults.standard.removeObject(forKey: "breastfeedingElapsed")
                UserDefaults.standard.removeObject(forKey: "leftPumpingStartTime")
                UserDefaults.standard.removeObject(forKey: "leftPumpingElapsed")
                UserDefaults.standard.removeObject(forKey: "rightPumpingStartTime")
                UserDefaults.standard.removeObject(forKey: "rightPumpingElapsed")
                UserDefaults.standard.set(false, forKey: "breastfeedingIsRunning")
                UserDefaults.standard.set(false, forKey: "leftPumpingIsRunning")
                UserDefaults.standard.set(false, forKey: "rightPumpingIsRunning")
                
                // Clear widget and notification settings
                UserDefaults.standard.removeObject(forKey: "live_activity_enabled")
                
                // Reset baby data
                dataManager.babyName = ""
                dataManager.babyBirthDate = Date()
                
                isClearingData = false
            }
        }
    }
    
    private func setupCloudKitSharing() {
        self.isSettingUpCloudKit = true
        cloudKitSetupMessage = "Setting up CloudKit..."
        
        Task {
            do {
                // Check schema first
                await dataManager.checkCloudKitSchema()
                
                // Enable family sharing
                try await dataManager.enableFamilySharing()
                
                await MainActor.run {
                    cloudKitSetupMessage = "✅ CloudKit enabled successfully!"
                    isSettingUpCloudKit = false
                }
                
                // Clear message after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    cloudKitSetupMessage = ""
                }
                
            } catch {
                await MainActor.run {
                    cloudKitSetupMessage = "❌ Setup failed: \(error.localizedDescription)"
                    isSettingUpCloudKit = false
                }
            }
        }
    }
    
    
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var titleColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Glass icon container
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                        .shadow(color: .primary.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .liquidGlassCard(cornerRadius: 16, shadowRadius: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FamilyInviteView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Invite Family Members")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Share the joy of tracking your baby's growth with family members. They'll be able to add activities and view progress.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 16) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Invite via Email")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Invite Link")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PersonalDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var babyName = ""
    @State private var birthDate = Date()
    @State private var primaryCaregiverName = ""
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picture Section
                        VStack(spacing: 16) {
                            Text("Profile Picture")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    
                                    if let profileImage = profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 4)
                                                    .shadow(color: .black.opacity(0.1), radius: 2)
                                            )
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                            Text("Add Photo")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if profileImage != nil {
                                Button("Remove Photo") {
                                    profileImage = nil
                                    saveProfileImage(nil)
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                        }
                        .padding(20)
                        .liquidGlassCard()
                        
                        // Baby Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                Text("Baby Information")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    TextField("Baby's name", text: $babyName)
                                        .font(.system(.body, design: .rounded))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .liquidGlassCard()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(babyName.isEmpty ? Color.clear : Color.purple.opacity(0.4), lineWidth: 2)
                                                .animation(.easeInOut(duration: 0.2), value: babyName.isEmpty)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Birth Date")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                                            .datePickerStyle(CompactDatePickerStyle())
                                            .labelsHidden()
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .liquidGlassCard()
                        
                        // Caregivers Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text("Caregiver")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("Your name", text: $primaryCaregiverName)
                                    .font(.system(.body, design: .rounded))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .liquidGlassCard()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(primaryCaregiverName.isEmpty ? Color.clear : Color.pink.opacity(0.4), lineWidth: 2)
                                            .animation(.easeInOut(duration: 0.2), value: primaryCaregiverName.isEmpty)
                                    )
                            }
                        }
                        .padding(20)
                        .liquidGlassCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("Personal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                        dismiss()
                    }
                    .disabled(babyName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $profileImage) { image in
                    saveProfileImage(image)
                }
            }
            .alert("Clear All Data", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your baby's data including activities, milestones, and growth records. This action cannot be undone.")
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private func loadCurrentSettings() {
        babyName = dataManager.babyName
        birthDate = dataManager.babyBirthDate
        primaryCaregiverName = UserDefaults.standard.string(forKey: "primary_caregiver_name") ?? ""
        loadProfileImage()
    }
    
    private func saveSettings() {
        // Save primary caregiver name locally (not synced to CloudKit)
        UserDefaults.standard.set(primaryCaregiverName, forKey: "primary_caregiver_name")
        
        // Update baby profile (both locally and in CloudKit if available)
        Task {
            do {
                try await dataManager.updateBabyProfile(name: babyName, birthDate: birthDate)
            } catch {
                // If CloudKit update fails, still update locally
                await MainActor.run {
                    dataManager.babyName = babyName
                    dataManager.babyBirthDate = birthDate
                }
                print("Failed to update CloudKit profile: \(error)")
            }
        }
    }
    
    private func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: "baby_profile_image"),
           let image = UIImage(data: imageData) {
            profileImage = image
        }
    }
    
    private func saveProfileImage(_ image: UIImage?) {
        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "baby_profile_image")
        } else {
            UserDefaults.standard.removeObject(forKey: "baby_profile_image")
        }
    }
    
    private func exportData() {
        // Future: Implement data export functionality
    }
    
    private func clearAllData() {
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Reset data manager
        dataManager.recentActivities = []
        dataManager.milestones = []
        dataManager.growthData = []
        dataManager.babyName = "Baby"
        dataManager.babyBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
    }
}

struct FamilyManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
    @Binding var familyMembers: [FamilyMember]
    @State private var isLoading = true
    @State private var hasActiveShare = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    VStack {
                        SwiftUI.ProgressView()
                        Text("Loading family members...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    if familyMembers.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.3.sequence.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No Family Members Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Invite family members to share baby tracking duties!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(familyMembers) { member in
                                    FamilyMemberRow(member: member)
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Always show invite button (family sharing is always active)
                        Button(action: {
                            Task {
                                if let activeShare = await dataManager.cloudKitManager.activeShare {
                                    // Present share sheet directly without dismissing
                                    await MainActor.run {
                                        presentShareSheet(with: activeShare)
                                    }
                                } else {
                                    print("❌ No active share found for inviting")
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Invite Family Members")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Family Members")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            do {
                familyMembers = try await dataManager.fetchFamilyMembers()
                // Family sharing is always active now
                hasActiveShare = true
                isLoading = false
            } catch {
                familyMembers = []
                hasActiveShare = true
                isLoading = false
            }
        }
    }
    
    private func presentShareSheet(with share: CKShare) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        guard let shareURL = share.url else {
            print("❌ No URL available for CloudKit share")
            return
        }
        
        // Create share items with caregiver's name
        let caregiverName = UserDefaults.standard.string(forKey: "primary_caregiver_name") ?? "Caregiver"
        let shareText = "Hi! I'm \(caregiverName) and I'd like to share our baby's tracking data with you. Tap the link to join and help track activities, feeding, sleep, and more!"
        let shareItems: [Any] = [shareText, shareURL]
        
        // Create native share sheet
        let activityController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityController.modalPresentationStyle = .formSheet
        
        // Configure for iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Find the root view controller
        var rootViewController = window.rootViewController
        while let presented = rootViewController?.presentedViewController {
            rootViewController = presented
        }
        
        rootViewController?.present(activityController, animated: true)
    }
    
    private var debugSectionView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🐛 Debug Tools")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Button(action: {
                Task {
                    await dataManager.loadExistingBabyProfile()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reload Profile Data")
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingRevokeConfirmation = false
    
    private var displayName: String {
        // Use caregiver name for display
        let caregiverName = UserDefaults.standard.string(forKey: "primary_caregiver_name") ?? "Caregiver"
        return member.role == .owner ? caregiverName : member.name
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(displayName.prefix(1)).uppercased())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                
                VStack(spacing: 4) {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(member.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(member.role == .owner ? "Owner" : "Member")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(member.role == .owner ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundColor(member.role == .owner ? .green : .blue)
                        .cornerRadius(8)
                }
                
                // Revoke button for non-owners who have accepted
                if member.role != .owner && member.acceptanceStatus == .accepted {
                    Button("Revoke Access") {
                        showingRevokeConfirmation = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 16, shadowRadius: 4)
        .confirmationDialog("Revoke Access", isPresented: $showingRevokeConfirmation, titleVisibility: .visible) {
            Button("Revoke Access", role: .destructive) {
                Task {
                    await revokeMemberAccess()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to revoke \(member.name)'s access to baby tracking data?")
        }
    }
    
    private func revokeMemberAccess() async {
        guard let activeShare = await dataManager.cloudKitManager.activeShare else { return }
        
        do {
            try await dataManager.cloudKitManager.revokeFamilyMemberAccess(member, from: activeShare)
            print("✅ Successfully revoked access for \(member.name)")
        } catch {
            print("❌ Failed to revoke access: \(error)")
        }
    }
}

// CloudKit sharing delegate
class ShareControllerDelegate: NSObject, UICloudSharingControllerDelegate {
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("❌ Failed to save share: \(error)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "Baby Tracker"
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        // Return app icon as thumbnail
        if let image = UIImage(named: "TotsIcon") {
            return image.pngData()
        }
        return nil
    }
    
    func itemType(for csc: UICloudSharingController) -> String? {
        return "Family Baby Tracking"
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("✅ Share saved successfully")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("🔗 Sharing stopped")
    }
    
    // CloudKit handles the sharing configuration automatically
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
                parent.onImageSelected(originalImage)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct TrackingGoalsView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var feedingInterval: Double = 3.0 // hours (covers both breastfeeding and bottle feeding)
    @State private var pumpingInterval: Double = 3.0 // hours
    @State private var diaperInterval: Double = 2.0 // hours
    
    // Daily goals
    @State private var sleepHoursGoal: Double = 15.0 // hours per day
    @State private var diaperCountGoal: Double = 6.0 // diapers per day
    @State private var feedingSessionsGoal: Double = 8.0 // feeding sessions per day
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Configure how often you want to be reminded for each activity.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            // Feeding interval (covers both breastfeeding and bottle feeding)
                            GoalSliderRow(
                                title: "Feeding",
                                subtitle: "Time between feeding sessions (breastfeeding & bottle)",
                                value: $feedingInterval,
                                range: 1.0...8.0,
                                step: 0.5,
                                unit: "hours"
                            )
                            
                            // Pumping interval
                            GoalSliderRow(
                                title: "Pumping",
                                subtitle: "Time between pumping sessions",
                                value: $pumpingInterval,
                                range: 1.0...8.0,
                                step: 0.5,
                                unit: "hours"
                            )
                            
                            // Diaper interval
                            GoalSliderRow(
                                title: "Diaper Change",
                                subtitle: "Time between diaper checks",
                                value: $diaperInterval,
                                range: 1.0...6.0,
                                step: 0.5,
                                unit: "hours"
                            )
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            Text("Daily Goals")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            Text("Set your daily targets for tracking progress.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            // Sleep hours goal
                            GoalSliderRow(
                                title: "Sleep Hours",
                                subtitle: "Total hours of sleep per day",
                                value: $sleepHoursGoal,
                                range: 8.0...20.0,
                                step: 0.5,
                                unit: "hours"
                            )
                            
                            // Daily diaper count goal
                            GoalSliderRow(
                                title: "Diaper Changes",
                                subtitle: "Number of diaper changes per day",
                                value: $diaperCountGoal,
                                range: 3.0...15.0,
                                step: 1.0,
                                unit: "diapers"
                            )
                            
                            // Daily feeding sessions goal
                            GoalSliderRow(
                                title: "Feeding Sessions",
                                subtitle: "Number of feeding sessions per day",
                                value: $feedingSessionsGoal,
                                range: 4.0...20.0,
                                step: 1.0,
                                unit: "sessions"
                            )
                        }
                        .padding(.vertical)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Tracking Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTrackingGoals()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadTrackingGoals()
        }
    }
    
    private func loadTrackingGoals() {
        feedingInterval = UserDefaults.standard.double(forKey: "feeding_interval")
        if feedingInterval == 0 { feedingInterval = 3.0 }
        
        pumpingInterval = UserDefaults.standard.double(forKey: "pumping_interval")
        if pumpingInterval == 0 { pumpingInterval = 3.0 }
        
        diaperInterval = UserDefaults.standard.double(forKey: "diaper_interval")
        if diaperInterval == 0 { diaperInterval = 2.0 }
        
        // Load daily goals
        sleepHoursGoal = UserDefaults.standard.double(forKey: "sleep_goal")
        if sleepHoursGoal == 0 { sleepHoursGoal = 15.0 }
        
        diaperCountGoal = UserDefaults.standard.double(forKey: "diaper_goal")
        if diaperCountGoal == 0 { diaperCountGoal = 6.0 }
        
        feedingSessionsGoal = UserDefaults.standard.double(forKey: "feeding_goal")
        if feedingSessionsGoal == 0 { feedingSessionsGoal = 8.0 }
    }
    
    private func saveTrackingGoals() {
        UserDefaults.standard.set(feedingInterval, forKey: "feeding_interval")
        UserDefaults.standard.set(pumpingInterval, forKey: "pumping_interval")
        UserDefaults.standard.set(diaperInterval, forKey: "diaper_interval")
        
        // Save daily goals
        UserDefaults.standard.set(sleepHoursGoal, forKey: "sleep_goal")
        UserDefaults.standard.set(diaperCountGoal, forKey: "diaper_goal")
        UserDefaults.standard.set(feedingSessionsGoal, forKey: "feeding_goal")
        
        // Trigger countdown update
        dataManager.updateCountdowns()
        
        // Post notification to refresh home view with new goals
        NotificationCenter.default.post(name: NSNotification.Name("GoalsUpdated"), object: nil)
    }
}

struct GoalSliderRow: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("\(range.lowerBound, specifier: "%.1f") \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(value, specifier: "%.1f") \(unit)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(range.upperBound, specifier: "%.1f") \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $value, in: range, step: step)
                    .accentColor(.blue)
            }
        }
        .padding(20)
        .liquidGlassCard(cornerRadius: 20, shadowRadius: 6)
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms and Conditions")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Group {
                        Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("By downloading, installing, or using the Tots baby tracking app (\"the App\"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.")
                        
                        Text("2. Description of Service")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Tots is a baby tracking application that helps parents monitor and record their baby's activities including feeding, sleeping, diaper changes, growth measurements, and developmental milestones. The App may sync data across devices using CloudKit.")
                        
                        Text("3. User Responsibilities")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("You are responsible for:\n• Providing accurate information\n• Maintaining the security of your device\n• Using the App in accordance with these terms\n• Consulting healthcare professionals for medical advice")
                        
                        Text("4. Privacy and Data")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information. All baby tracking data is stored locally on your device and optionally synced through Apple's CloudKit service.")
                    }
                    
                    Group {
                        Text("5. Medical Disclaimer")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Tots is for informational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your pediatrician or other qualified healthcare provider with any questions you may have regarding your baby's health.")
                        
                        Text("6. Limitation of Liability")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("The App is provided \"as is\" without warranties of any kind. We shall not be liable for any damages arising from the use of this App, including but not limited to data loss, inaccurate tracking, or reliance on App information for medical decisions.")
                        
                        Text("7. Updates and Changes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("We may update these Terms and Conditions from time to time. Continued use of the App after changes constitutes acceptance of the new terms.")
                        
                        Text("8. Contact Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("For questions about these Terms and Conditions, please contact us at support@growwithtots.com or visit growwithtots.com.")
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Group {
                        Text("Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 10)
                        
                        Text("1. Information We Collect")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Tots collects and stores the following information locally on your device:\n• Baby's name and birth date\n• Feeding, sleeping, and diaper tracking data\n• Growth measurements and milestones\n• Photos you choose to add\n• Notes and observations")
                        
                        Text("2. How We Use Your Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Your information is used to:\n• Provide baby tracking functionality\n• Generate insights and reports\n• Sync data across your devices (if enabled)\n• Improve the App experience")
                        
                        Text("3. Data Storage and Security")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("All data is primarily stored locally on your device. If you enable CloudKit sync, data is securely transmitted and stored in your personal iCloud account, which is encrypted and controlled by Apple's privacy policies.")
                        
                        Text("4. Data Sharing")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("We do not sell, trade, or share your personal data with third parties. Your baby tracking data remains private to you. If you enable family sharing features, data is only shared with family members you explicitly invite.")
                    }
                    
                    Group {
                        Text("5. Analytics and Diagnostics")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("We may collect anonymized usage statistics and crash reports to improve the App. This data cannot be used to identify you or your baby.")
                        
                        Text("6. Age Requirements")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Grow with Tots is intended for use by individuals who are at least 16 years of age. The app is designed for parents, guardians, and caregivers to track their babies and children. We do not knowingly collect personal information from anyone under the age of 16. If you are under 16 years of age, please do not use this app.")
                        
                        Text("7. Your Rights")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("You have the right to:\n• Access your data (it's stored on your device)\n• Delete your data (through the App or by deleting the App)\n• Export your data (through the App's export feature)\n• Control sync settings")
                        
                        Text("8. Changes to Privacy Policy")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("We may update this Privacy Policy periodically. We will notify you of significant changes through the App or our website.")
                        
                        Text("9. Contact Us")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("If you have questions about this Privacy Policy or your data, please contact us at support@growwithtots.com or visit growwithtots.com.")
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TotsDataManager())
}

