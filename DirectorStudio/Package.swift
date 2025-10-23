// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DirectorStudio",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "DirectorStudio", targets: ["DirectorStudio"])
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "0.0.1")
    ],
    targets: [
        .target(name: "DirectorStudio", dependencies: ["Supabase"])
    ]
)
