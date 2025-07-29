# SwiftAds

A Swift package that provides a common interface for advertising systems across different platforms and ad networks. Similar to [swift-log](https://github.com/apple/swift-log) and [swift-metrics](https://github.com/apple/swift-metrics), SwiftAds defines a standardized API that allows you to switch between different ad implementations without changing your application code.

## Features

- 🎯 **Unified API** - Single interface for all ad types (banners, interstitials, rewarded videos)
- 🔧 **Pluggable Backends** - Easy integration with any ad network
- 🚀 **Async/Await Support** - Modern Swift concurrency
- 📱 **Cross-Platform** - iOS, macOS, tvOS, watchOS support
- 🎮 **Placement Targeting** - Flexible ad placement management
- 🚫 **NOOP Handler** - Built-in no-operation handler
- 🔄 **Multiplex Handler** - Fallback support with multiple ad networks

## Installation

### Swift Package Manager

Add SwiftAds to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dankinsoid/swift-ads.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/dankinsoid/swift-ads.git`

## Quick Start

### 1. Bootstrap the Ads System

First, configure SwiftAds with your preferred ad handler during app startup:

```swift
import SwiftAds

// Bootstrap with your ad handler (once per app lifecycle)
AdsSystem.bootstrap(YourCustomAdsHandler())
```

### 2. Display Ads

```swift
import SwiftAds

// Create ads instance
let ads = Ads()

// Show interstitial ad
try await ads.showInterstitial(id: "your-ad-id")

// Show rewarded video
try await ads.showRewarderVideo(id: "your-rewarded-ad-id")

// Load and display banner
let bannerView = try await ads.loadBanner(
    id: "your-banner-id", 
    in: viewController, 
    size: .standart
)
view.addSubview(bannerView)
```

### 3. Preload Ads for Better Performance

```swift
// Preload ads for faster display
try await ads.loadInterstitial(id: "your-ad-id")
try await ads.loadRewarderVideo(id: "your-rewarded-ad-id")
```

## Ad Placements

Use placements to organize and target different ad locations in your app:

```swift
// Create ads instance with placement
let mainMenuAds = Ads(placement: "main_menu")
let gameOverAds = Ads(placement: "game_over")

// Different placements can show different ads
try await mainMenuAds.showInterstitial(id: "menu-ad")
try await gameOverAds.showInterstitial(id: "game-over-ad")
```

## Banner Sizes

SwiftAds supports various banner sizes:

```swift
// Standard banner sizes
let standardBanner = try await ads.loadBanner(id: "banner-id", in: vc, size: .standart)
let mediumBanner = try await ads.loadBanner(id: "banner-id", in: vc, size: .medium)
let largeBanner = try await ads.loadBanner(id: "banner-id", in: vc, size: .large)

// Adaptive banner (adjusts to screen width)
let adaptiveBanner = try await ads.loadBanner(id: "banner-id", in: vc, size: .adaptive)

// Custom size
let customBanner = try await ads.loadBanner(
    id: "banner-id", 
    in: vc, 
    size: .custom(width: 320, height: 100)
)
```

## Creating Custom Ad Handlers

Implement the `AdsHandler` protocol to integrate with your preferred ad network:

```swift
import SwiftAds

struct MyAdMobHandler: AdsHandler {
    
    func initAds() async throws {
        // Initialize your ad network SDK
    }
    
    @MainActor
    func loadBanner(
        in controller: UIViewController, 
        size: Ads.Size, 
        id: String, 
        placement: String?
    ) async throws -> UIView {
        // Return configured banner view
    }
    
    func loadInterstitial(id: String, placement: String?) async throws {
        // Preload interstitial ad
    }
    
    func loadRewarderVideo(id: String, placement: String?) async throws {
        // Preload rewarded video ad
    }
    
    @MainActor
    func showInterstitial(
        from controller: UIViewController, 
        id: String, 
        placement: String?
    ) async throws {
        // Display interstitial ad
    }
    
    @MainActor
    func showRewarderVideo(
        from controller: UIViewController, 
        id: String, 
        placement: String?
    ) async throws {
        // Display rewarded video ad
    }
}

// Bootstrap your handler
AdsSystem.bootstrap(MyAdMobHandler())
```

### Example Implementation

For a complete handler implementation example, see:
- [**AppLovinAdsHandler**](https://github.com/dankinsoid/AppLovinAdsHandler) - Full AppLovin integration with SwiftAds

## Multiplex Handler (Fallback Support)

Use `MultiplexAdsHandler` to combine multiple ad networks with automatic fallback:

```swift
import SwiftAds

// Create multiplex handler with fallback priority
let multiplexHandler = MultiplexAdsHandler(
    PrimaryAdNetworkHandler(),    // Try this first
    SecondaryAdNetworkHandler(),  // Fallback to this if first fails
    NOOPAdsHandler()             // Final fallback (always succeeds)
)

// Bootstrap with multiplex handler
AdsSystem.bootstrap(multiplexHandler)
```

The `MultiplexAdsHandler` tries each handler in sequence until one succeeds:

1. **Primary Network**: Attempts to load/show ads with your main provider
2. **Secondary Network**: Falls back if primary fails (network issues, no fill, etc.)
3. **Tertiary/NOOP**: Final fallback to ensure ads never completely break your app

Benefits:
- **Higher Fill Rates**: Multiple networks increase ad availability
- **Redundancy**: App continues working if one network fails
- **Revenue Optimization**: Waterfall approach maximizes monetization

## Exponential Retry Handler

Use `ExponentialRetryAdsHandler` to add automatic retry logic with exponential backoff for **load operations only**:

```swift
import SwiftAds

// Wrap any handler with exponential retry logic
let retryHandler = ExponentialRetryAdsHandler(
    wrapping: YourAdNetworkHandler(),
    maxRetries: 6        // Default: 6 attempts
)

// Bootstrap with retry handler
AdsSystem.bootstrap(retryHandler)
```

The retry delays follow exponential backoff (only for load functions):
- 1st retry: 2 seconds (2^1)
- 2nd retry: 4 seconds (2^2)
- 3rd retry: 8 seconds (2^3)
- 4th retry: 16 seconds (2^4)
- 5th retry: 32 seconds (2^5)
- 6th retry: 64 seconds (2^6)

**Load Functions with Retry:**
- `loadBanner()` - Retries with exponential backoff
- `loadInterstitial()` - Retries with exponential backoff  
- `loadRewarderVideo()` - Retries with exponential backoff

**Show Functions (No Retry):**
- `showInterstitial()` - No retry (immediate success/failure)
- `showRewarderVideo()` - No retry (immediate success/failure)

Benefits:
- **Load Reliability**: Automatically recovers from temporary network issues during ad loading
- **Smart Backoff**: Exponential delays prevent server overload while maximizing success rate
- **Show Performance**: No delays on show operations for immediate user experience

You can combine handlers for powerful retry + fallback patterns:

```swift
let robustHandler = MultiplexAdsHandler(
    ExponentialRetryAdsHandler(wrapping: PrimaryAdNetworkHandler()),
    ExponentialRetryAdsHandler(wrapping: SecondaryAdNetworkHandler()),
    NOOPAdsHandler()
)
AdsSystem.bootstrap(robustHandler)
```

## Testing

For testing and development, use the built-in `NOOPAdsHandler`:

```swift
#if DEBUG
AdsSystem.bootstrap(NOOPAdsHandler())
#endif
```

## Error Handling

SwiftAds methods can throw errors. Handle them appropriately:

```swift
do {
    try await ads.showInterstitial(id: "ad-id")
} catch {
    print("Failed to show ad: \\(error)")
    // Handle error (e.g., no internet, ad not loaded, etc.)
}
```

## Thread Safety

SwiftAds is thread-safe and can be used from any queue. UI-related operations are automatically dispatched to the main actor.

## Related Packages

SwiftAds works great with other Swift ecosystem packages that follow similar interface patterns:

- [**swift-analytics**](https://github.com/dankinsoid/swift-analytics) - Unified analytics interface
- [**swift-remote-configs**](https://github.com/dankinsoid/swift-remote-configs) - Unified remote configuration interface

Example integration:

```swift
import SwiftAds
import SwiftAnalytics
import SwiftRemoteConfigs

// Track ad events
try await ads.showInterstitial(id: "game-over-ad")
Analytics.track("ad_displayed", properties: ["placement": "game_over"])

// Use remote config for ad IDs
let adId = RemoteConfigs.string("interstitial_ad_id", default: "default-ad-id")
try await ads.showInterstitial(id: adId)

// Combine with retry handler
let handler = MyAdNetworkHandler().withExponentialRetry()
AdsSystem.bootstrap(handler)
```

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.9+
- Xcode 15.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.