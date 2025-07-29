import UIKit

public struct MultiplexAdsHandler: AdsHandler {
	
	private let handlers: [AdsHandler]
	
	public init(_ handlers: AdsHandler...) {
		self.handlers = handlers
	}
	
	public init(_ handlers: [AdsHandler]) {
		self.handlers = handlers
	}
	
	public func initAds() async throws {
		var lastError: Error?
		
		for handler in handlers {
			do {
				try await handler.initAds()
				return
			} catch {
				lastError = error
			}
		}
		
		if let lastError {
			throw lastError
		}
	}
	
	@MainActor
	public func loadBanner(in controller: UIViewController, size: Ads.Size, id: String, placement: String?) async throws -> UIView {
		var lastError: Error?
		
		for handler in handlers {
			do {
				return try await handler.loadBanner(in: controller, size: size, id: id, placement: placement)
			} catch {
				lastError = error
			}
		}
		
		throw lastError ?? MultiplexError.noHandlersAvailable
	}
	
	public func loadInterstitial(id: String, placement: String?) async throws {
		var lastError: Error?
		
		for handler in handlers {
			do {
				try await handler.loadInterstitial(id: id, placement: placement)
				return
			} catch {
				lastError = error
			}
		}
		
		if let lastError {
			throw lastError
		}
	}
	
	public func loadRewarderVideo(id: String, placement: String?) async throws {
		var lastError: Error?
		
		for handler in handlers {
			do {
				try await handler.loadRewarderVideo(id: id, placement: placement)
				return
			} catch {
				lastError = error
			}
		}
		
		if let lastError {
			throw lastError
		}
	}
	
	@MainActor
	public func showInterstitial(from controller: UIViewController, id: String, placement: String?) async throws {
		var lastError: Error?
		
		for handler in handlers {
			do {
				try await handler.showInterstitial(from: controller, id: id, placement: placement)
				return
			} catch {
				lastError = error
			}
		}
		
		if let lastError {
			throw lastError
		}
	}
	
	@MainActor
	public func showRewarderVideo(from controller: UIViewController, id: String, placement: String?) async throws {
		var lastError: Error?
		
		for handler in handlers {
			do {
				try await handler.showRewarderVideo(from: controller, id: id, placement: placement)
				return
			} catch {
				lastError = error
			}
		}
		
		if let lastError {
			throw lastError
		}
	}
}

public enum MultiplexError: Error {
	case noHandlersAvailable
}