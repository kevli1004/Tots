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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Baby profile
                babyProfileView
                
                // Family sharing
                familySharingView
                
                // Settings options
                settingsOptionsView
                
                // Support section
                supportSectionView
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingFamilyInvite) {
            FamilyInviteView()
        }
        .sheet(isPresented: $showingPersonalDetails) {
            PersonalDetailsView()
        }
        .sheet(isPresented: $showingFamilyManager) {
            FamilyManagerView(familyMembers: $familyMembers)
                .environmentObject(dataManager)
        }
        .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task {
                    try await dataManager.deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your data from CloudKit and cannot be undone.")
        }
        .confirmationDialog("Sign Out", isPresented: $showingLogoutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await dataManager.signOut()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will sign you out and clear all local data. Your CloudKit data will remain safe.")
        }
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
        HStack(spacing: 16) {
            // Baby avatar
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.blue.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Image("TotsIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Button(action: {
                    showingPersonalDetails = true
                }) {
                    HStack {
                        Text(dataManager.babyName.isEmpty ? "Enter your baby's name" : dataManager.babyName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
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
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
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
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Share Button
                Button(action: {
                    self.shareWithFamily()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Invite New Family Member")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            Button(action: {
                showingFamilyInvite = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Invite family members")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Family sharing promo
            VStack(spacing: 12) {
                Text("The journey is easier together")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Share tracking duties with partners and grandparents")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showingFamilyInvite = true
                }) {
                    Text("Invite Family")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
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
            
            SettingsRow(
                icon: "target",
                title: "Edit tracking goals",
                action: { /* Navigate to goals */ }
            )
            
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
            
            SettingsRow(
                icon: "megaphone.fill",
                title: "Feature Requests",
                action: { /* Open feedback */ }
            )
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                SettingsRow(
                    icon: "icloud.fill",
                    title: "Sync Data",
                    subtitle: "Last Synced: 7:52 PM",
                    action: { /* Sync data */ }
                )
            }
            
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
    
    private func shareWithFamily() {
        Task {
            do {
                if let share = try await dataManager.shareBabyProfile() {
                    await MainActor.run {
                        // Present CloudKit sharing controller
                        presentCloudKitShareController(share: share)
                    }
                }
            } catch {
                await MainActor.run {
                    cloudKitSetupMessage = "❌ Sharing failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func presentCloudKitShareController(share: CKShare) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let shareController = UICloudSharingController(share: share, container: CKContainer(identifier: "iCloud.com.mytotsapp.tots.DB"))
        shareController.availablePermissions = [.allowPublic, .allowPrivate, .allowReadOnly, .allowReadWrite]
        shareController.delegate = UIApplication.shared.delegate as? UICloudSharingControllerDelegate
        
        // Find the top-most view controller
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        topController.present(shareController, animated: true)
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
    
    var body: some View {
        NavigationView {
            Form {
                Section("Baby Information") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Baby's name", text: $babyName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                }
                
                Section("Caregivers") {
                    HStack {
                        Text("Primary Caregiver")
                        Spacer()
                        TextField("Your name", text: $primaryCaregiverName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        exportData()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
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
                }
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
    }
    
    private func saveSettings() {
        dataManager.babyName = babyName
        dataManager.babyBirthDate = birthDate
        UserDefaults.standard.set(primaryCaregiverName, forKey: "primary_caregiver_name")
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
                            Task {
                                if let share = try await dataManager.shareBabyProfile() {
                                    await MainActor.run {
                                        presentCloudKitShareController(share: share)
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Invite Family Member")
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
    
    private func presentCloudKitShareController(share: CKShare) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let shareController = UICloudSharingController(share: share, container: CKContainer(identifier: "iCloud.com.mytotsapp.tots.DB"))
        shareController.availablePermissions = [.allowPublic, .allowPrivate, .allowReadOnly, .allowReadWrite]
        
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        topController.present(shareController, animated: true)
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

#Preview {
    SettingsView()
        .environmentObject(TotsDataManager())
}

