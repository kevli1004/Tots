import SwiftUI
import CloudKit


struct SettingsView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingFamilyInvite = false
    @State private var showingPersonalDetails = false
    @State private var isSettingUpCloudKit = false
    @State private var cloudKitSetupMessage = ""
    @State private var showingCloudKitShare = false
    @State private var showingFamilyManager = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var familyMembers: [FamilyMember] = []
    @State private var showingDebugAlert = false
    @State private var debugMessage = ""
    @State private var shareDelegate: ShareControllerDelegate?
    @State private var profileImageUpdateTrigger = false
    @State private var showingExportSheet = false
    @State private var showingTrackingGoals = false
    
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
                    
                    // Family sharing - hidden for now
                    // familySharingView
                    
                    // Settings options
                    settingsOptionsView
                    
                    // Support section
                    supportSectionView
                }
                .padding(.horizontal, 20)
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
            Button("Delete Account", role: .destructive) {
                Task {
                    do {
                        try await dataManager.deleteAccount()
                    } catch {
                        print("❌ Failed to delete account: \(error)")
                        // Even if CloudKit deletion fails, still sign out locally
                        await dataManager.signOut()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your data from CloudKit and cannot be undone.")
        }
        .confirmationDialog("Sign Out", isPresented: $showingLogoutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                print("🚪 Sign Out button tapped")
                Task {
                    print("🚪 Starting sign out...")
                    await dataManager.signOut()
                    print("✅ Signed out successfully")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will sign you out and clear all local data. Your CloudKit data will remain safe.")
        }
        .alert("Debug Info", isPresented: $showingDebugAlert) {
            Button("OK") { }
        } message: {
            Text(debugMessage)
        }
        .sheet(isPresented: $showingExportSheet) {
            ActivityViewController(activityItems: [generateCSVFile()])
        }
        .sheet(isPresented: $showingTrackingGoals) {
            TrackingGoalsView()
                .environmentObject(dataManager)
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
            print("Error writing CSV file: \(error)")
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
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(dataManager.babyName.isEmpty ? "Enter your baby's name" : dataManager.babyName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(dataManager.babyAge)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var familySharingView: some View {
        VStack(spacing: 16) {
            // CloudKit Setup Button
            if !dataManager.familySharingEnabled {
                Button(action: {
                    self.setupCloudKitSharing()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Enable Family Sharing")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Text("Sync data with CloudKit")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isSettingUpCloudKit {
                            SwiftUI.ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .liquidGlassCard()
                }
                .disabled(isSettingUpCloudKit)
                
                if !cloudKitSetupMessage.isEmpty {
                    Text(cloudKitSetupMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            } else {
                // Family Management (when CloudKit is enabled)
                Button(action: {
                    showingFamilyManager = true
                    Task {
                        familyMembers = try await dataManager.fetchFamilyMembers()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Manage Family Sharing")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("\(familyMembers.count) member\(familyMembers.count == 1 ? "" : "s")")
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
                
                // Single Share Button
                Button(action: {
                    Task {
                        await manageFamilySharing()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(dataManager.familySharingEnabled ? "Manage Family Sharing" : "Enable Family Sharing")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            
        }
    }
    
    private var settingsOptionsView: some View {
        VStack(spacing: 16) {
            SettingsRow(
                icon: "person.crop.square.fill",
                title: "Personal details",
                action: { showingPersonalDetails = true }
            )
            
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
                    get: { dataManager.currentActivity != nil },
                    set: { enabled in
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
            .padding(.vertical, 12)
            
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
                action: { /* Open terms */ }
            )
            
            SettingsRow(
                icon: "shield.fill",
                title: "Privacy Policy",
                action: { /* Open privacy */ }
            )
            
            SettingsRow(
                icon: "envelope.fill",
                title: "Support Email",
                action: { /* Open email */ }
            )
            
            // Hidden for now
            /*
            SettingsRow(
                icon: "megaphone.fill",
                title: "Feature Requests",
                action: { /* Open feedback */ }
            )
            */
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Export Data",
                    subtitle: "Download your data as CSV",
                    action: { 
                        exportDataAsCSV()
                    }
                )
            }
            
            // Hidden debug buttons
            /*
            SettingsRow(
                icon: "ladybug.fill",
                title: "Debug CloudKit Data",
                subtitle: "Check what's in your CloudKit",
                action: { 
                    Task {
                        do {
                            let profiles = try await dataManager.cloudKitManager.fetchBabyProfiles()
                            let message = "Found \(profiles.count) baby profiles\n\nApp State:\n• Baby Name: \(dataManager.babyName)\n• Activities: \(dataManager.recentActivities.count)"
                            await MainActor.run {
                                debugMessage = message
                                showingDebugAlert = true
                            }
                        } catch {
                            await MainActor.run {
                                debugMessage = "CloudKit Error: \(error.localizedDescription)"
                                showingDebugAlert = true
                            }
                        }
                    }
                }
            )
            
            SettingsRow(
                icon: "arrow.clockwise",
                title: "Force Reload Profile",
                subtitle: "Manually reload data from CloudKit",
                action: { 
                    Task {
                        // Clear any cached record ID to force a fresh lookup
                        UserDefaults.standard.removeObject(forKey: "baby_profile_record_id")
                        await dataManager.loadExistingBabyProfile()
                        
                        await MainActor.run {
                            debugMessage = "Profile reload complete!\n\n• Baby Name: \(dataManager.babyName)\n• Activities: \(dataManager.recentActivities.count)"
                            showingDebugAlert = true
                        }
                    }
                }
            )
            */
            
            SettingsRow(
                icon: "trash.fill",
                title: "Delete Account",
                titleColor: .red,
                action: { showingDeleteConfirmation = true }
            )
            
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right.fill",
                title: "Sign Out",
                action: { showingLogoutConfirmation = true }
            )
        }
    }
    
    // MARK: - CloudKit Setup Methods
    
    private func manageFamilySharing() async {
        do {
            if let share = try await dataManager.shareBabyProfile() {
                await MainActor.run {
                    // Show the native CloudKit sharing controller
                    presentCloudKitSharingController(share: share)
                }
            }
        } catch {
            await MainActor.run {
                debugMessage = "❌ Sharing setup failed:\n\(error.localizedDescription)\n\nPlease try again."
                showingDebugAlert = true
            }
        }
    }
    
    private func presentCloudKitSharingController(share: CKShare) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let container = CKContainer(identifier: "iCloud.com.mytotsapp.tots.DB")
        
        // Always use the preparation handler to ensure proper setup
        print("📱 Setting up CloudKit sharing UI...")
        let shareController = UICloudSharingController { controller, prepareCompletionHandler in
            // The share and container are prepared here
            prepareCompletionHandler(share, container, nil)
        }
        
        shareDelegate = ShareControllerDelegate()
        shareController.delegate = shareDelegate
        shareController.availablePermissions = [.allowReadWrite, .allowPrivate]
        shareController.modalPresentationStyle = .formSheet
        
        // Find the root view controller
        var rootViewController = window.rootViewController
        while let presented = rootViewController?.presentedViewController {
            rootViewController = presented
        }
        
        rootViewController?.present(shareController, animated: true)
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
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
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
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.body)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Birth Date")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .labelsHidden()
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
                                Text("Primary Caregiver")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("Your name", text: $primaryCaregiverName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.body)
                            }
                        }
                        .padding(20)
                        .liquidGlassCard()
                        
                        // Data Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.orange)
                                Text("Data Management")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            VStack(spacing: 12) {
                                Button("Export Data") {
                                    exportData()
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                
                                Button("Clear All Data") {
                                    showingDeleteConfirmation = true
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
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
        dataManager.babyName = babyName
        dataManager.babyBirthDate = birthDate
        UserDefaults.standard.set(primaryCaregiverName, forKey: "primary_caregiver_name")
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
        print("Export data functionality would be implemented here")
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
                        Button(action: {
                            // Enable family sharing locally
                            dataManager.familySharingEnabled = true
                            UserDefaults.standard.set(true, forKey: "family_sharing_enabled")
                            hasActiveShare = true
                            print("✅ Family sharing enabled successfully")
                        }) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                Text("Enable Family Sharing")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        if hasActiveShare {
                            Button(action: {
                                Task {
                                    try await dataManager.stopSharingProfile()
                                    await MainActor.run {
                                        familyMembers = []
                                        dismiss()
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "stop.circle.fill")
                                    Text("Stop Sharing")
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
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
                hasActiveShare = await dataManager.cloudKitManager.activeShare != nil
                isLoading = false
            } catch {
                print("Failed to fetch family members: \(error)")
                isLoading = false
            }
        }
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
                    print("🔄 Manual Data Reload - Starting...")
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
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(member.name.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(member.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(member.role == .owner ? "Owner" : "Member")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(member.role == .owner ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundColor(member.role == .owner ? .green : .blue)
                        .cornerRadius(8)
                    
                    Text(member.permission == .readWrite ? "Edit" : "View")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// CloudKit sharing delegate
class ShareControllerDelegate: NSObject, UICloudSharingControllerDelegate {
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("❌ Failed to save share: \(error)")
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        return "Baby Profile"
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        // Return thumbnail data for the baby profile if you have one
        return nil
    }
    
    func itemType(for csc: UICloudSharingController) -> String? {
        return "Baby Tracking Profile"
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("✅ Share saved successfully")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("ℹ️ Sharing stopped")
    }
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
    }
    
    private func saveTrackingGoals() {
        UserDefaults.standard.set(feedingInterval, forKey: "feeding_interval")
        UserDefaults.standard.set(pumpingInterval, forKey: "pumping_interval")
        UserDefaults.standard.set(diaperInterval, forKey: "diaper_interval")
        
        // Trigger countdown update
        dataManager.updateCountdowns()
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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

#Preview {
    SettingsView()
        .environmentObject(TotsDataManager())
}

