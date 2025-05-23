import Foundation
import Testing

@testable import Storehouse

struct StorehouseTests {
	@Test func emptyStorehouseReturnsNil() {
		let storehouse = Storehouse<Int, String>()
		#expect(storehouse.value(forKey: 1) == nil)
	}

	@Test func storehouseStoresAndRetrievesValues() {
		let storehouse = Storehouse<Int, String>()
		storehouse.insert("one", forKey: 1)
		#expect(storehouse.value(forKey: 1) == "one")
	}

	@Test func removingValueFromStorehouse() {
		let storehouse = Storehouse<Int, String>()
		storehouse.insert("one", forKey: 1)
		#expect(storehouse.value(forKey: 1) == "one")
		storehouse.removeValue(forKey: 1)
		#expect(storehouse.value(forKey: 1) == nil)
	}

	@Test func removingNonexistentValueFromStorehouse() {
		let storehouse = Storehouse<Int, String>()
		#expect(storehouse.value(forKey: 1) == nil)
		storehouse.removeValue(forKey: 1)
		#expect(storehouse.value(forKey: 1) == nil)
	}

	@Test func readingWorksFromBackgroundThread() async {
		let storehouse = Storehouse<String, String>()
		storehouse.insert("value", forKey: "key")
		let value = await Task<String?, Never>
			.detached {
				storehouse.value(forKey: "key")
			}
			.value
		#expect(value == "value")
	}

	@Test func settingWorksFromBackgroundThread() async {
		let storehouse = Storehouse<String, String>()
		await Task.detached {
			storehouse.insert("value", forKey: "key")
		}
		.value
		#expect(storehouse.value(forKey: "key") == "value")
	}

	@Test func retrievingExpiredValueReturnsNil() {
		let callStorehouse = Storehouse<String, Int>()
		callStorehouse.insert(0, forKey: "calls")
		// dateProvider will be called:
		// 1. to set expirationDate on setting the value
		// 2. to check expirationDate the first time we ask
		// 3. to check expirationDate again, which we want to be expired for this test
		let entryLifetime: TimeInterval = 5 * 50
		let dateProvider: @Sendable () -> Date = {
			var called = callStorehouse.value(forKey: "calls")!
			called += 1
			callStorehouse.insert(called, forKey: "calls")
			guard called >= 3 else { return Date.now }
			return Date.now.addingTimeInterval(entryLifetime + 100)
		}

		let storehouse = Storehouse<Int, Bool>(dateProvider: dateProvider, entryLifetime: entryLifetime)
		// dateProvider called first time to set expirationDate
		storehouse.insert(true, forKey: 1)
		// dateProvider called second time to check expirationDate, returns .now
		#expect(storehouse.value(forKey: 1) == true)
		// dateProvider called third time, returns after expiration
		#expect(storehouse.value(forKey: 1) == nil)
	}

	@Test func observationTrackingSettingValue() async {
		let storehouse = Storehouse<Int, Bool>()
		await confirmation("onChange was called") { confirm in
			withObservationTracking {
				_ = storehouse[1]
			} onChange: {
				#expect(storehouse[1] == nil)
				confirm()
			}
			storehouse[1] = true
			#expect(storehouse[1] == true)
		}
	}

	@Test func observationTrackingResettingValue() async {
		let storehouse = Storehouse<Int, Bool>()
		storehouse[1] = false
		await confirmation("onChange was called") { confirm in
			withObservationTracking {
				_ = storehouse[1]
			} onChange: {
				#expect(storehouse[1] == false)
				confirm()
			}
			storehouse[1] = true
			#expect(storehouse[1] == true)
		}
	}

	@Test func observationTrackingRemovingValue() async {
		let storehouse = Storehouse<Int, Bool>()
		storehouse[1] = true
		await confirmation("onChange was called") { confirm in
			withObservationTracking {
				_ = storehouse[1]
			} onChange: {
				#expect(storehouse[1] == true)
				confirm()
			}
			storehouse.removeValue(forKey: 1)
			#expect(storehouse[1] == nil)
		}
	}
}
