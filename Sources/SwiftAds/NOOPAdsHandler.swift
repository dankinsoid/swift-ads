import UIKit

/// No-operation ads handler for testing and fallback scenarios.
/// 
/// Always succeeds without displaying actual ads.
public struct NOOPAdsHandler: AdsHandler {

	/// Creates a no-operation ads handler.
	public init() {}
	public func initAds() async throws {}
	@MainActor
	public func loadBanner(in controller: UIViewController, size: Ads.Size, id: String, placement: String?) async throws -> UIView { UIView() }
	public func loadInterstitial(id: String, placement: String?) async throws {}
	public func loadRewarderVideo(id: String, placement: String?) async throws {}
	@MainActor
	public func showInterstitial(from controller: UIViewController, id: String, placement: String?) async throws {}
	@MainActor
	public func showRewarderVideo(from controller: UIViewController, id: String, placement: String?) async throws {}
}
