// swift-tools-version: 6.1
import PackageDescription

let package = Package(
	name: "Storehouse",
	platforms: [.iOS(.v17), .macOS(.v14)],
	products: [
		.library(name: "Storehouse", targets: ["Storehouse"])
	],
	targets: [
		.target(name: "Storehouse"),
		.testTarget(name: "StorehouseTests", dependencies: ["Storehouse"]),
	]
)
