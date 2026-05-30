// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TripNest",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "TripNestLib", targets: ["TripNestLib"]),
        .executable(name: "TripNest", targets: ["TripNest"])
    ],
    targets: [
        // Library target for modular view access and Xcode Previews
        .target(
            name: "TripNestLib",
            path: ".",
            exclude: [
                "App/TripNestApp.swift",
                "generate_xcodeproj.py",
                "README.md",
                "Assets"
            ],
            sources: [
                "App/ContentView.swift",
                "Core",
                "Models",
                "Repositories",
                "ViewModels",
                "Views"
            ]
        ),
        .executableTarget(
            name: "TripNest",
            dependencies: ["TripNestLib"],
            path: "App",
            exclude: [
                "ContentView.swift"
            ],
            sources: [
                "TripNestApp.swift"
            ]
        )
    ]
)
