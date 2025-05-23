import Foundation

extension Storehouse {
	final class WrappedKey: NSObject, Sendable {
		let key: Key

		init(_ key: Key) { self.key = key }

		override var hash: Int { key.hashValue }

		override func isEqual(_ object: Any?) -> Bool {
			guard let value = object as? WrappedKey else { return false }
			return key == value.key
		}
	}
}
