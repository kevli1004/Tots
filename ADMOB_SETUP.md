# Google AdMob Integration Setup

## Prerequisites
- You already have a Google AdMob account ✅
- Xcode project is ready

## Step 1: Add Google Mobile Ads SDK

1. Open your Xcode project
2. Go to **File > Add Package Dependencies**
3. Enter this URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`
4. Click **Add Package**
5. Select **GoogleMobileAds** and click **Add Package**

## Step 2: Update Info.plist

Add the following to your `Tots/Info.plist` file:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4fzdc2evr5.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>4pfyvq9l8r.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>2fnua5tdw4.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ydx93a7ass.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>5a6flpkh64.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>p78axxw29g.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>v72qych5uu.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>ludvb6z3bs.skadnetwork</string>
    </dict>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cp8zw746q7.skadnetwork</string>
    </dict>
</array>
```

## Step 3: Update Ad Unit IDs

1. Go to your AdMob dashboard
2. Create a new App (if you haven't already)
3. Create Banner Ad Units for your app
4. Copy your App ID and Ad Unit IDs

5. Update `Tots/Models/AdMobManager.swift`:
   - Replace `GADApplicationIdentifier` in Info.plist with your actual App ID
   - Replace the test Ad Unit ID in `AdMobManager.swift` with your actual Banner Ad Unit ID:

```swift
// Replace this test ID:
static let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

// With your actual ID:
static let bannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
```

## Step 4: App Transport Security (if needed)

If you encounter network issues, you may need to add this to Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## What's Already Implemented

✅ **AdMobManager**: Handles SDK initialization
✅ **BannerAdView**: UIViewRepresentable for banner ads  
✅ **AdBannerContainer**: Styled container for ads
✅ **Integration**: Added to all main views:
   - HomeView (top of scroll)
   - ProgressView (top of scroll) 
   - MilestonesView (top of content)
   - WordTrackerView (top of content)
   - SettingsView (top of scroll)

## Testing

The current implementation uses Google's test ad unit IDs, so you should see test ads immediately after adding the SDK. Once you replace with your actual IDs, you'll see real ads.

## Banner Ad Specifications

- **Size**: 320x50 (standard banner)
- **Position**: Top of each view
- **Style**: Rounded corners, light background
- **Padding**: 16px horizontal, 8px top

## Revenue Optimization Tips

1. **Ad Placement**: Currently at top of views - consider A/B testing different positions
2. **Ad Refresh**: Consider implementing auto-refresh for better revenue
3. **Mediation**: Consider adding other ad networks through AdMob mediation
4. **Ad Types**: Consider adding interstitial or rewarded ads for higher revenue

## Troubleshooting

- **No ads showing**: Check your Ad Unit IDs and App ID
- **Test ads only**: Make sure you've replaced test IDs with your actual IDs
- **Build errors**: Ensure Google Mobile Ads SDK is properly added
- **Crashes**: Check that GADApplicationIdentifier is set in Info.plist
