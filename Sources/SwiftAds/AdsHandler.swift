import UIKit

/// Protocol for implementing ad network backends.
///
/// Conform to this protocol to integrate with specific ad networks.
public protocol AdsHandler {
    /// Initializes the ad network SDK.
    ///
    /// Called once during app bootstrap.
    func initAds() async throws
    /// Loads and returns a banner ad view.
    ///
    /// - Parameters:
    ///   - controller: Container view controller
    ///   - size: Banner size specification
    ///   - id: Ad unit identifier
    ///   - placement: Optional placement identifier
    /// - Returns: Configured banner view
    @MainActor
    func loadBanner(in controller: UIViewController, size: Ads.Size, id: String, placement: String?) async throws -> UIView
    /// Preloads an interstitial ad.
    ///
    /// - Parameters:
    ///   - id: Ad unit identifier
    ///   - placement: Optional placement identifier
    func loadInterstitial(id: String, placement: String?) async throws
    /// Preloads a rewarded video ad.
    ///
    /// - Parameters:
    ///   - id: Ad unit identifier
    ///   - placement: Optional placement identifier
    func loadRewarderVideo(id: String, placement: String?) async throws
    /// Displays an interstitial ad.
    ///
    /// - Parameters:
    ///   - controller: Presenting view controller
    ///   - id: Ad unit identifier
    ///   - placement: Optional placement identifier
    @MainActor
    func showInterstitial(from controller: UIViewController, id: String, placement: String?) async throws
    /// Displays a rewarded video ad.
    ///
    /// - Parameters:
    ///   - controller: Presenting view controller
    ///   - id: Ad unit identifier
    ///   - placement: Optional placement identifier
    @MainActor
    func showRewarderVideo(from controller: UIViewController, id: String, placement: String?) async throws
}
