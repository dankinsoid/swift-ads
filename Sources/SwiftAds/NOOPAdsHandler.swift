import UIKit

/// No-operation ads handler for testing and fallback scenarios.
///
/// Always succeeds without displaying actual ads.
public struct NOOPAdsHandler: AdsHandler {
    /// Creates a no-operation ads handler.
    public init() {}
    public func initAds() async throws {}
    @MainActor
    public func loadBanner(in _: UIViewController, size _: Ads.Size, id _: String, placement _: String?) async throws -> UIView { UIView() }
    public func loadInterstitial(id _: String, placement _: String?) async throws {}
    public func loadRewarderVideo(id _: String, placement _: String?) async throws {}
    @MainActor
    public func showInterstitial(from _: UIViewController, id _: String, placement _: String?) async throws {}
    @MainActor
    public func showRewarderVideo(from _: UIViewController, id _: String, placement _: String?) async throws {}
}
