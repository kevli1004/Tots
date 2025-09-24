import SwiftUI
import GoogleMobileAds

// MARK: - AdMob Manager
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    override init() {
        super.init()
        MobileAds.shared.start { _ in }
    }
    
    // Production Ad Unit IDs
    static let bannerAdUnitID = "ca-app-pub-1320655646844688/2987594446" // Production banner ID
}

// MARK: - Orientation Monitor
class OrientationMonitor: ObservableObject {
    @Published var refreshTrigger = false
    private var lastOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    init() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleOrientationChange()
        }
    }
    
    private func handleOrientationChange() {
        let currentOrientation = UIDevice.current.orientation
        
        // Trigger refresh when coming back to portrait from landscape
        if (lastOrientation == .landscapeLeft || lastOrientation == .landscapeRight) &&
           (currentOrientation == .portrait || currentOrientation == .portraitUpsideDown) {
            refreshTrigger.toggle()
        }
        
        lastOrientation = currentOrientation
    }
}

// MARK: - Banner Ad View
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    @StateObject private var orientationMonitor = OrientationMonitor()
    
    init(adUnitID: String = AdMobManager.bannerAdUnitID, adSize: AdSize = AdSizeBanner) {
        self.adUnitID = adUnitID
        self.adSize = adSize
    }
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        
        // Get the root view controller properly for iOS 15+
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // Force reload when orientation changes back to portrait
        uiView.load(Request())
    }
}

// MARK: - Ad Banner Container
struct AdBannerContainer: View {
    let height: CGFloat = 50 // Standard banner height
    @StateObject private var orientationMonitor = OrientationMonitor()
    
    var body: some View {
        BannerAdView()
            .frame(height: height)
            .padding(.horizontal, 16)
            .id(orientationMonitor.refreshTrigger) // Force recreation when orientation changes
    }
}

struct AdBannerContainerWide: View {
    let height: CGFloat = 50 // Standard banner height
    @StateObject private var orientationMonitor = OrientationMonitor()
    
    var body: some View {
        BannerAdView()
            .frame(height: height)
            .padding(.horizontal, 0)
            .id(orientationMonitor.refreshTrigger) // Force recreation when orientation changes
    }
}

struct AdBannerContainerMedium: View {
    let height: CGFloat = 50 // Standard banner height
    @StateObject private var orientationMonitor = OrientationMonitor()
    
    var body: some View {
        BannerAdView()
            .frame(height: height)
            .padding(.horizontal, 16)
            .id(orientationMonitor.refreshTrigger) // Force recreation when orientation changes
    }
}

