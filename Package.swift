// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DirectorStudio",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DirectorStudioLib",
            targets: ["DirectorStudioLib"]
        )
    ],
    targets: [
        .target(
            name: "DirectorStudioLib",
            path: "DirectorStudio"
        )
    ]
)
