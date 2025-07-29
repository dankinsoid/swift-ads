#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// Ads handler that wraps another handler with exponential backoff retry logic for load operations.
/// 
/// Delays between retries follow exponential backoff: 2^1, 2^2, 2^3, 2^4, 2^5, 2^6 seconds.
/// Only applies retry logic to load functions (loadBanner, loadInterstitial, loadRewarderVideo).
public struct ExponentialRetryAdsHandler: AdsHandler {
	
	private let wrappedHandler: AdsHandler
	private let maxRetries: Int
	
	/// Creates an exponential retry handler.
	/// 
	/// - Parameters:
	///   - handler: The handler to wrap with retry logic
	///   - maxRetries: Maximum retry attempts (default: 6)
	public init(
		wrapping handler: AdsHandler,
		maxRetries: Int = 6
	) {
		self.wrappedHandler = handler
		self.maxRetries = maxRetries
	}
	
	public func initAds() async throws {
		try await wrappedHandler.initAds()
	}
	
	#if canImport(UIKit)
	@MainActor
	public func loadBanner(in controller: UIViewController, size: Ads.Size, id: String, placement: String?) async throws -> UIView {
		try await withExponentialRetry {
			try await wrappedHandler.loadBanner(in: controller, size: size, id: id, placement: placement)
		}
	}
	#else
	public func loadBanner(in controller: Any, size: Ads.Size, id: String, placement: String?) async throws -> Any {
		try await withExponentialRetry {
			try await wrappedHandler.loadBanner(in: controller, size: size, id: id, placement: placement)
		}
	}
	#endif
	
	public func loadInterstitial(id: String, placement: String?) async throws {
		try await withExponentialRetry {
			try await wrappedHandler.loadInterstitial(id: id, placement: placement)
		}
	}
	
	public func loadRewarderVideo(id: String, placement: String?) async throws {
		try await withExponentialRetry {
			try await wrappedHandler.loadRewarderVideo(id: id, placement: placement)
		}
	}
	
	#if canImport(UIKit)
	@MainActor
	public func showInterstitial(from controller: UIViewController, id: String, placement: String?) async throws {
		try await wrappedHandler.showInterstitial(from: controller, id: id, placement: placement)
	}
	
	@MainActor
	public func showRewarderVideo(from controller: UIViewController, id: String, placement: String?) async throws {
		try await wrappedHandler.showRewarderVideo(from: controller, id: id, placement: placement)
	}
	#else
	public func showInterstitial(from controller: Any, id: String, placement: String?) async throws {
		try await wrappedHandler.showInterstitial(from: controller, id: id, placement: placement)
	}
	
	public func showRewarderVideo(from controller: Any, id: String, placement: String?) async throws {
		try await wrappedHandler.showRewarderVideo(from: controller, id: id, placement: placement)
	}
	#endif
	
	private func withExponentialRetry<T>(_ operation: () async throws -> T) async throws -> T {
		var retryAttempt = 0
		var lastError: Error?
		
		repeat {
			do {
				return try await operation()
			} catch {
				lastError = error
				
				guard retryAttempt < maxRetries else {
					break
				}
				
				retryAttempt += 1
				let delaySec = pow(2.0, Double(retryAttempt))
				try await Task.sleep(nanoseconds: UInt64(delaySec * 1_000_000_000))
			}
		} while retryAttempt <= maxRetries
		
		throw lastError ?? ExponentialRetryError.maxRetriesExceeded
	}
}

/// Errors specific to exponential retry handling.
public enum ExponentialRetryError: Error {
	/// All retry attempts have been exhausted.
	case maxRetriesExceeded
}

public extension AdsHandler {
	
	/// Wraps this handler with exponential retry logic for load operations only.
	/// 
	/// - Parameter maxRetries: Maximum retry attempts (default: 6)
	/// - Returns: Handler with retry logic applied to load functions
	func withExponentialRetry(maxRetries: Int = 6) -> ExponentialRetryAdsHandler {
		ExponentialRetryAdsHandler(
			wrapping: self,
			maxRetries: maxRetries
		)
	}
}