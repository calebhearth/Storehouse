import Foundation

extension Storehouse {
	final class Entry: Sendable {
		let value: Value
		let expirationDate: Date

		init(value: Value, expirationDate: Date) {
			self.value = value
			self.expirationDate = expirationDate
		}
	}
}
