import SwiftUI
import GoogleMobileAds

// MARK: - AdMob Manager
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    override init() {
        super.init()
        MobileAds.shared.start { _ in }
    }
    
    // Test Ad Unit IDs - Replace with your actual Ad Unit IDs
    static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ID
    
    // Replace with your actual Ad Unit IDs when ready for production:
    // static let bannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
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
            .padding(.horizontal, 16)
            .padding(.top, 21) // ~0.75cm padding above ad
    }
}

struct AdBannerContainerWide: View {
    let height: CGFloat = 50 // Standard banner height
    
    var body: some View {
        BannerAdView()
            .frame(height: height)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal, 0) // Widest - no horizontal padding like milestone page
            .padding(.top, 21) // ~0.75cm padding above ad
    }
}

