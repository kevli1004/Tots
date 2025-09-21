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
    static let bannerAdUnitID = "ca-app-pub-1320655646844688/2987594446"
}

// MARK: - Banner Ad View
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    
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
        
        // Debug logging
        print("🔍 AdMob Debug:")
        print("   Ad Unit ID: \(adUnitID)")
        print("   Is Test ID: \(adUnitID.contains("3940256099942544"))")
        print("   Is Production ID: \(adUnitID.contains("1320655646844688"))")
        
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No updates needed
    }
}

// MARK: - Ad Banner Container
struct AdBannerContainer: View {
    let height: CGFloat = 50 // Standard banner height
    
    var body: some View {
        BannerAdView()
            .frame(height: height)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.top, 8)
    }
}

// MARK: - Ad Banner Container with Extra Margins (for Milestones & Words)
struct AdBannerContainerWithMargins: View {
    let height: CGFloat = 50 // Standard banner height
    
    var body: some View {
        BannerAdView()
            .frame(height: height)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }
}

