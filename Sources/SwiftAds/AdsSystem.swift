import UIKit

public enum AdsSystem {

	fileprivate static var handler: AdsHandler {
		lock.lock()
		defer { lock.unlock() }
		return _handler
	}

	private static let lock = NSRecursiveLock()
	private static var _handler: AdsHandler = NOOPAdsHandler()
	private static var wasSet = false
	private static var setContinuation: CheckedContinuation<Void, Never>?
	private static var setTask: Task<Void, Never>?
	// private static var

	public static func bootstrap(_ handler: AdsHandler) {
		lock.withLock {
			precondition(!wasSet, "AdsHandler shouldn't be set more than once")
			let continuation = setContinuation
			setContinuation = nil
			wasSet = true
			_handler = handler
			Task {
				continuation?.resume()
				try await handler.initAds()
			}
		}
	}

	fileprivate static func waitAdsHandler() async {
		let (_wasSet, _setTask) = lock.withLock {
			(wasSet, setTask)
		}
		guard !_wasSet else { return }
		if let _setTask {
			await _setTask.value
			return
		}
		let task = Task {
			await withCheckedContinuation { continuation in
				lock.withLock {
					setContinuation = continuation
				}
			}
		}
		lock.withLock {
			setTask = task
		}
		await task.value
	}
}

public struct Ads {

	private let handler: AdsHandler
	private let placement: String?

	public init(placement: String? = nil) {
		handler = AdsSystem.handler
		self.placement = placement
	}

	@MainActor
	public func showInterstitial(id: String, from controller: UIViewController? = nil) async throws {
		guard let controller = controller ?? UIViewController.top else {
			throw ThereIsNoViewControllerOnTheScreen()
		}
		try await handler.showInterstitial(from: controller, id: id, placement: placement)
	}

	@MainActor
	public func showRewarderVideo(id: String, from controller: UIViewController? = nil) async throws {
		guard let controller = controller ?? UIViewController.top else {
			throw ThereIsNoViewControllerOnTheScreen()
		}
		try await handler.showRewarderVideo(from: controller, id: id, placement: placement)
	}

	public func loadBanner(id: String, in controller: UIViewController, size: Size) async throws -> UIView {
		await AdsSystem.waitAdsHandler()
		return try await handler.loadBanner(in: controller, size: size, id: id, placement: placement)
	}

	public func loadInterstitial(id: String) async throws {
		await AdsSystem.waitAdsHandler()
		try await handler.loadInterstitial(id: id, placement: placement)
	}

	public func loadRewarderVideo(id: String) async throws {
		await AdsSystem.waitAdsHandler()
		try await handler.loadRewarderVideo(id: id, placement: placement)
	}

	public enum Size: Hashable {

		case standart
		case medium
		case large
		case adaptive
		case custom(width: CGFloat, height: CGFloat)
	}
}

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

public struct NOOPAdsHandler: AdsHandler {

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

private struct ThereIsNoViewControllerOnTheScreen: Error {}

private extension UIViewController {

	var top: UIViewController {
		presentedViewController?.top ?? self
	}

	static var top: UIViewController? {
		UIApplication.shared.connectedScenes.flatMap {
			($0 as? UIWindowScene)?.windows.filter(\.isKeyWindow).compactMap(\.rootViewController) ?? []
		}
		.first?.top
	}
}
