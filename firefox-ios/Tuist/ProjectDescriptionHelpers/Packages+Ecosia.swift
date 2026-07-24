import ProjectDescription

/// Swift Package dependencies for the Ecosia app.
/// Single source of truth for SPM packages used by Project.swift.
public enum Packages {
    public static let all: [Package] = [
        .local(path: "../BrowserKit"),
        .local(path: "../MozillaRustComponents"),
        .remote(url: "https://github.com/auth0/Auth0.swift.git", requirement: .upToNextMajor(from: "2.0.0")),
        .remote(url: "https://github.com/braze-inc/braze-swift-sdk.git", requirement: .upToNextMajor(from: "11.9.0")),
        .remote(url: "https://github.com/airbnb/lottie-ios.git", requirement: .exact("4.4.0")),
        .remote(url: "https://github.com/mozilla/glean-swift.git", requirement: .upToNextMinor(from: "66.3.0")),
        .remote(url: "https://github.com/snowplow/snowplow-ios-tracker.git", requirement: .upToNextMinor(from: "6.0.9")),
        .remote(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", requirement: .upToNextMajor(from: "1.18.7")),
        .remote(url: "https://github.com/nalexn/ViewInspector.git", requirement: .upToNextMajor(from: "0.10.1")),
        .remote(url: "https://github.com/kif-framework/KIF.git", requirement: .exact("3.8.9")),
        .remote(url: "https://github.com/adjust/ios_sdk.git", requirement: .exact("4.37.0")),
        .remote(url: "https://github.com/SnapKit/SnapKit.git", requirement: .exact("5.7.0")),
        .remote(url: "https://github.com/nbhasin2/Fuzi.git", requirement: .branch("master")),
        .remote(url: "https://github.com/nbhasin2/GCDWebServer.git", requirement: .branch("master")),
        .remote(url: "https://github.com/getsentry/sentry-cocoa.git", requirement: .exact("9.10.0")),
        .remote(url: "https://github.com/onevcat/Kingfisher.git", requirement: .exact("8.2.0")),
        .remote(url: "https://github.com/apple/swift-certificates.git", requirement: .exact("1.2.0")),
        .remote(url: "https://github.com/mozilla-mobile/MappaMundi.git", requirement: .branch("master")),
        .remote(url: "https://github.com/scinfu/SwiftSoup.git", requirement: .upToNextMajor(from: "2.0.0")),
    ]
}
