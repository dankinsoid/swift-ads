// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-ads",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SwiftAds",
            targets: ["SwiftAds"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftAds",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "SwiftAdsTests",
            dependencies: ["SwiftAds"]
        ),
    ]
)
