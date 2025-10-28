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
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "DirectorStudioLib",
            path: "DirectorStudio",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]
        )
    ]
)
