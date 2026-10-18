// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoopCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "MoopCore", targets: ["MoopCore"])],
    targets: [
        .target(name: "MoopCore"),
        .testTarget(name: "MoopCoreTests", dependencies: ["MoopCore"])
    ]
)
