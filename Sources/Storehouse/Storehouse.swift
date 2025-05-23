import Foundation
import Observation

extension NSCache: @unchecked @retroactive Sendable {}

@Observable
public final class Storehouse<Key: Hashable & Sendable, Value: Sendable>: Sendable {
	let wrapped = NSCache<WrappedKey, Entry>()
	private let dateProvider: @Sendable () -> Date
	private let entryLifetime: TimeInterval

	init(dateProvider: @Sendable @escaping () -> Date = ({ Date() }), entryLifetime: TimeInterval = 12 * 60 * 60) {
		self.dateProvider = dateProvider
		self.entryLifetime = entryLifetime
	}

	func insert(_ value: Value, forKey key: Key) {
		_$observationRegistrar.withMutation(of: self, keyPath: \.wrapped) {
			let expirationDate = dateProvider().addingTimeInterval(entryLifetime)
			wrapped.setObject(Entry(value: value, expirationDate: expirationDate), forKey: WrappedKey(key))
		}
	}

	func value(forKey key: Key) -> Value? {
		_$observationRegistrar.access(self, keyPath: \.wrapped)
		guard let entry = wrapped.object(forKey: WrappedKey(key)) else { return nil }
		guard dateProvider() < entry.expirationDate else {
			// Discard values that have expired
			removeValue(forKey: key)
			return nil
		}
		return entry.value
	}

	func removeValue(forKey key: Key) {
		_$observationRegistrar.withMutation(of: self, keyPath: \.wrapped) {
			wrapped.removeObject(forKey: WrappedKey(key))
		}
	}

	subscript(key: Key) -> Value? {
		get { return value(forKey: key) }
		set {
			guard let value = newValue else {
				// If nil was assigned using our subscript,
				// then we remove any value for that key:
				removeValue(forKey: key)
				return
			}

			insert(value, forKey: key)
		}
	}
}
