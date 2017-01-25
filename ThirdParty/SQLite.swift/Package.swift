import PackageDescription

let package = Package(
    name: "SQLite",
    targets: [
        Target(
            name: "SQLite",
            dependencies: [
                .Target(name: "SQLiteObjc")
            ]),
        Target(name: "SQLiteObjc")
    ],
    dependencies: [
        .Package(url: "https://github.com/stephencelis/CSQLite.git", majorVersion: 0)
    ],
    exclude: ["Tests/CocoaPods", "Tests/Carthage"]
)
