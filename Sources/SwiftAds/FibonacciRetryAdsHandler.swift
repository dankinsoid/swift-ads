#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// Ads handler that wraps another handler with Fibonacci sequence retry logic.
/// 
/// Delays between retries follow the Fibonacci sequence: 1, 1, 2, 3, 5, 8...
public struct FibonacciRetryAdsHandler: AdsHandler {
	
	private let wrappedHandler: AdsHandler
	private let maxRetries: Int
	private let baseDelay: TimeInterval
	
	/// Creates a Fibonacci retry handler.
	/// 
	/// - Parameters:
	///   - handler: The handler to wrap with retry logic
	///   - maxRetries: Maximum retry attempts (default: 5)
	///   - baseDelay: Base delay multiplier in seconds (default: 1.0)
	public init(
		wrapping handler: AdsHandler,
		maxRetries: Int = 5,
		baseDelay: TimeInterval = 1.0
	) {
		self.wrappedHandler = handler
		self.maxRetries = maxRetries
		self.baseDelay = baseDelay
	}
	
	public func initAds() async throws {
		try await withFibonacciRetry {
			try await wrappedHandler.initAds()
		}
	}
	
	#if canImport(UIKit)
	@MainActor
	public func loadBanner(in controller: UIViewController, size: Ads.Size, id: String, placement: String?) async throws -> UIView {
		try await withFibonacciRetry {
			try await wrappedHandler.loadBanner(in: controller, size: size, id: id, placement: placement)
		}
	}
	#else
	public func loadBanner(in controller: Any, size: Ads.Size, id: String, placement: String?) async throws -> Any {
		try await withFibonacciRetry {
			try await wrappedHandler.loadBanner(in: controller, size: size, id: id, placement: placement)
		}
	}
	#endif
	
	public func loadInterstitial(id: String, placement: String?) async throws {
		try await withFibonacciRetry {
			try await wrappedHandler.loadInterstitial(id: id, placement: placement)
		}
	}
	
	public func loadRewarderVideo(id: String, placement: String?) async throws {
		try await withFibonacciRetry {
			try await wrappedHandler.loadRewarderVideo(id: id, placement: placement)
		}
	}
	
	#if canImport(UIKit)
	@MainActor
	public func showInterstitial(from controller: UIViewController, id: String, placement: String?) async throws {
		try await withFibonacciRetry {
			try await wrappedHandler.showInterstitial(from: controller, id: id, placement: placement)
		}
	}
	
	@MainActor
	public func showRewarderVideo(from controller: UIViewController, id: String, placement: String?) async throws {
		try await withFibonacciRetry {
			try await wrappedHandler.showRewarderVideo(from: controller, id: id, placement: placement)
		}
	}
	#else
	public func showInterstitial(from controller: Any, id: String, placement: String?) async throws {
		try await withFibonacciRetry {
			try await wrappedHandler.showInterstitial(from: controller, id: id, placement: placement)
		}
	}
	
	public func showRewarderVideo(from controller: Any, id: String, placement: String?) async throws {
		try await withFibonacciRetry {
			try await wrappedHandler.showRewarderVideo(from: controller, id: id, placement: placement)
		}
	}
	#endif
	
	private func withFibonacciRetry<T>(_ operation: () async throws -> T) async throws -> T {
		var lastError: Error?
		var fib1 = 1
		var fib2 = 1
		
		for attempt in 0...maxRetries {
			do {
				return try await operation()
			} catch {
				lastError = error
				
				if attempt == maxRetries {
					break
				}
				
				let delay = TimeInterval(fib1) * baseDelay
				try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
				
				let nextFib = fib1 + fib2
				fib1 = fib2
				fib2 = nextFib
			}
		}
		
		throw lastError ?? FibonacciRetryError.maxRetriesExceeded
	}
}

/// Errors specific to Fibonacci retry handling.
public enum FibonacciRetryError: Error {
	/// All retry attempts have been exhausted.
	case maxRetriesExceeded
}

public extension AdsHandler {
	
	/// Wraps this handler with Fibonacci retry logic.
	/// 
	/// - Parameters:
	///   - maxRetries: Maximum retry attempts (default: 5)
	///   - baseDelay: Base delay multiplier in seconds (default: 1.0)
	/// - Returns: Handler with retry logic applied
	func withFibonacciRetry(
		maxRetries: Int = 5,
		baseDelay: TimeInterval = 1.0
	) -> FibonacciRetryAdsHandler {
		FibonacciRetryAdsHandler(
			wrapping: self,
			maxRetries: maxRetries,
			baseDelay: baseDelay
		)
	}
}