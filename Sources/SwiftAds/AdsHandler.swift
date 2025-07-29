import UIKit

public protocol AdsHandler {

	func initAds() async throws
	@MainActor
	func loadBanner(in controller: UIViewController, size: Ads.Size, id: String, placement: String?) async throws -> UIView
	func loadInterstitial(id: String, placement: String?) async throws
	func loadRewarderVideo(id: String, placement: String?) async throws
	@MainActor
	func showInterstitial(from controller: UIViewController, id: String, placement: String?) async throws
	@MainActor
	func showRewarderVideo(from controller: UIViewController, id: String, placement: String?) async throws
}
