import UIKit

/// Central system for managing ad handlers.
/// 
/// Bootstrap once at app launch, then use `Ads` instances throughout your app.
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

	/// Configures the global ads handler.
	/// 
	/// - Parameter handler: The ads handler implementation to use
	/// - Important: Must be called exactly once during app initialization
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

/// Main interface for displaying ads.
/// 
/// Create instances for specific placements or use the default instance.
public struct Ads {

	private let handler: AdsHandler
	private let placement: String?
	private let loadingTasks = LoadingTasks()

	/// Creates an ads instance.
	/// 
	/// - Parameter placement: Optional placement identifier for targeting
	public init(placement: String? = nil) {
		handler = AdsSystem.handler
		self.placement = placement
	}

	/// Displays an interstitial ad.
	/// 
	/// - Parameters:
	///   - id: Ad unit identifier
	///   - controller: Presenting view controller (uses top controller if nil)
	@MainActor
	public func showInterstitial(id: String, from controller: UIViewController? = nil) async throws {
		guard let controller = controller ?? UIViewController.top else {
			throw ThereIsNoViewControllerOnTheScreen()
		}
		
		// Load ad if not already loaded/loading
		try await loadingTasks.loadIfNeeded(id: id, type: .interstitial) {
			try await loadInterstitial(id: id)
		}
		
		try await handler.showInterstitial(from: controller, id: id, placement: placement)
	}

	/// Displays a rewarded video ad.
	/// 
	/// - Parameters:
	///   - id: Ad unit identifier
	///   - controller: Presenting view controller (uses top controller if nil)
	@MainActor
	public func showRewarderVideo(id: String, from controller: UIViewController? = nil) async throws {
		guard let controller = controller ?? UIViewController.top else {
			throw ThereIsNoViewControllerOnTheScreen()
		}
		
		// Load ad if not already loaded/loading
		try await loadingTasks.loadIfNeeded(id: id, type: .rewarderVideo) {
			try await loadRewarderVideo(id: id)
		}
		
		try await handler.showRewarderVideo(from: controller, id: id, placement: placement)
	}

	/// Loads and returns a banner ad view.
	/// 
	/// - Parameters:
	///   - id: Ad unit identifier
	///   - controller: Container view controller
	///   - size: Banner size specification
	/// - Returns: Configured banner view ready for display
	public func loadBanner(id: String, in controller: UIViewController, size: Size) async throws -> UIView {
		await AdsSystem.waitAdsHandler()
		return try await handler.loadBanner(in: controller, size: size, id: id, placement: placement)
	}

	/// Preloads an interstitial ad for faster display.
	/// 
	/// - Parameter id: Ad unit identifier
	public func loadInterstitial(id: String) async throws {
		await AdsSystem.waitAdsHandler()
		try await loadingTasks.executeLoad(id: id, type: .interstitial) {
			try await handler.loadInterstitial(id: id, placement: placement)
		}
	}

	/// Preloads a rewarded video ad for faster display.
	/// 
	/// - Parameter id: Ad unit identifier
	public func loadRewarderVideo(id: String) async throws {
		await AdsSystem.waitAdsHandler()
		try await loadingTasks.executeLoad(id: id, type: .rewarderVideo) {
			try await handler.loadRewarderVideo(id: id, placement: placement)
		}
	}

	/// Banner ad size specifications.
	public enum Size: Hashable {

		case standart
		case medium
		case large
		case adaptive
		case custom(width: CGFloat, height: CGFloat)
	}
}

private struct ThereIsNoViewControllerOnTheScreen: Error {}

/// Manages loading tasks to prevent duplicate loads and coordinate show/load operations.
private final class LoadingTasks {
	private var tasks: [String: Task<Void, Error>] = [:]
	private let lock = NSRecursiveLock()
	
	/// Executes a load operation, ensuring only one load per ad unit ID.
	func executeLoad(id: String, type: AdType, operation: @escaping () async throws -> Void) async throws {
		let key = "\(type.rawValue):\(id)"
		
		let task = lock.withLock { () -> Task<Void, Error>? in
			if let existingTask = tasks[key] {
				return existingTask
			}
			
			let newTask = Task { [weak self] in
				do {
					try await operation()
					// Keep successful task in cache (don't remove)
				} catch {
					// Remove failed task so it can be retried
					self?.lock.withLock {
						self?.tasks.removeValue(forKey: key)
					}
					throw error
				}
			}
			tasks[key] = newTask
			return newTask
		}
		
		if let task = task {
			try await task.value
		}
	}
	
	/// Loads an ad if not already loading, or waits for existing load to complete.
	func loadIfNeeded(id: String, type: AdType, loadOperation: @escaping () async throws -> Void) async throws {
		try await executeLoad(id: id, type: type, operation: loadOperation)
	}
}

/// Ad types for tracking loading operations.
private enum AdType: String {
	case interstitial
	case rewarderVideo
}

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
