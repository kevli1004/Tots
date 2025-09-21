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
        GeometryReader { geometry in
            BannerAdView()
                .frame(width: geometry.size.width - 8, height: height) // Responsive width
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 4) // Wider for popups
                .padding(.top, 21) // ~0.75cm padding above ad
        }
        .frame(height: height + 21) // Total height including top padding
    }
}

struct AdBannerContainerWide: View {
    let height: CGFloat = 50 // Standard banner height
    
    var body: some View {
        GeometryReader { geometry in
            BannerAdView()
                .frame(width: geometry.size.width, height: height) // Full responsive width
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 0) // Widest - no horizontal padding like milestone page
                .padding(.top, 21) // ~0.75cm padding above ad
        }
        .frame(height: height + 21) // Total height including top padding
    }
}

struct AdBannerContainerMedium: View {
    let height: CGFloat = 50 // Standard banner height
    
    var body: some View {
        GeometryReader { geometry in
            BannerAdView()
                .frame(width: geometry.size.width - 32, height: height) // Responsive width with medium padding
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 16) // Less wide for main milestone/word pages
                .padding(.top, 21) // ~0.75cm padding above ad
        }
        .frame(height: height + 21) // Total height including top padding
    }
}

