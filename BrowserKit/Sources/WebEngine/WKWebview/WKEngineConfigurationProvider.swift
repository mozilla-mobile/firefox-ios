// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Network
import WebKit

public struct ProxyScope: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let normal   = ProxyScope(rawValue: 1 << 0)
    public static let `private` = ProxyScope(rawValue: 1 << 1)
    public static let all: ProxyScope = [.normal, .private]
}

@MainActor
public struct WKWebViewParameters {
    /// A boolean value customizable with a user preference indicating whether JavaScript can
    /// open windows without user interaction.
    var blockPopups: Bool

    /// A boolean value indicating if we have a persitent webview data store.
    var isPrivate: Bool

    /// The type of pull refresh that is going to be instantiated and displayed by the webview.
    var pullRefreshType: EnginePullRefreshViewType

    /// A value indicating the user preference for audio visual media types
    var autoPlay: WKAudiovisualMediaTypes

    /// FXIOS-11986  - Allow Client to pass down it's own scheme handler for now, this will be internal later on
    var schemeHandler: SchemeHandler

    public init(blockPopups: Bool,
                isPrivate: Bool,
                autoPlay: WKAudiovisualMediaTypes,
                schemeHandler: SchemeHandler,
                pullRefreshType: EnginePullRefreshViewType = UIRefreshControl.self) {
        self.blockPopups = blockPopups
        self.isPrivate = isPrivate
        self.autoPlay = autoPlay
        self.schemeHandler = schemeHandler
        self.pullRefreshType = pullRefreshType
    }

    /// Default internal Webview parameters initializer for WebEngine reader mode purpose
    init() {
        self.blockPopups = false
        self.isPrivate = false
        self.autoPlay = .all
        self.schemeHandler = WKInternalSchemeHandler()
        self.pullRefreshType = UIRefreshControl.self
    }
}

/// Provider to get a configured `WKEngineConfiguration`
/// Only one configuration provider per application should exists.
@MainActor
public protocol WKEngineConfigurationProvider {
    func createConfiguration(parameters: WKWebViewParameters) -> WKEngineConfiguration
}

/// FXIOS-11986 - This will be internal when the WebEngine is fully integrated in Firefox iOS
public struct DefaultWKEngineConfigurationProvider: WKEngineConfigurationProvider {
    private static var nonPersistentStore = WKWebsiteDataStore.nonPersistent()
    private static var defaultStore = WKWebsiteDataStore.default()
    /// Identifier of the persistent store currently held in `defaultStore`, when we have
    /// swapped away from `WKWebsiteDataStore.default()` (e.g. for a VPN session). Used to
    /// clean up the on-disk footprint via `WKWebsiteDataStore.remove(forIdentifier:)` once
    /// no webviews retain the previous store.
    private static var defaultStoreIdentifier: UUID?
    private static let defaultDataDetectorTypes: WKDataDetectorTypes = [.phoneNumber]
    private let configuration: WKWebViewConfiguration

    public init(configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        self.configuration = configuration
    }

    public func createConfiguration(parameters: WKWebViewParameters) -> WKEngineConfiguration {
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !parameters.blockPopups
        configuration.mediaTypesRequiringUserActionForPlayback = parameters.autoPlay
        configuration.userContentController = WKUserContentController()
        configuration.allowsInlineMediaPlayback = true
        configuration.dataDetectorTypes = DefaultWKEngineConfigurationProvider.defaultDataDetectorTypes

        // TODO: FXIOS-8086 - Evaluate if ignoresViewportScaleLimits is still needed
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true

        // Since our app creates multiple web views, we assign the same WKWebsiteDataStore object to web views that
        // may safely share cookies.
        // The cookie store should only be created once, otherwise we can loose them. See FXIOS-11833
        configuration.websiteDataStore = parameters.isPrivate
            ? Self.nonPersistentStore
            : Self.defaultStore

        // Popup WKWebViewConfiguration can have the scheme already registered thus registering again
        // leads to crash
        if configuration.urlSchemeHandler(forURLScheme: parameters.schemeHandler.scheme) == nil {
            configuration.setURLSchemeHandler(parameters.schemeHandler,
                                              forURLScheme: parameters.schemeHandler.scheme)
        }

        return DefaultEngineConfiguration(webViewConfiguration: configuration)
    }

    /// Replaces the active website data stores with ones that have the given proxy
    /// configurations applied. Returning a new store is the only way to guarantee WebKit's
    /// network process abandons the existing connection pool — assigning
    /// `proxyConfigurations` on a live store does not.
    ///
    /// The normal (persistent) store is handled asymmetrically:
    /// - VPN-on (non-empty configs): we mint a fresh `WKWebsiteDataStore(forIdentifier:)`
    ///   and copy cookies forward so the user stays signed in.
    /// - VPN-off (empty configs): we swap back to `WKWebsiteDataStore.default()` so the
    ///   user's full persistent state (localStorage, IndexedDB, etc.) is preserved, and
    ///   we deliberately do NOT copy cookies back — VPN-session identity should not leak
    ///   into the user's normal browsing.
    ///
    /// - Returns: Identifiers of persistent stores that were displaced and are safe to
    ///   clean up via `removeDataStores(forIdentifiers:)` once all webviews referencing
    ///   them have been torn down.
    @available(iOS 17.0, *)
    @discardableResult
    public static func applyProxyConfigurations(
        _ configs: [ProxyConfiguration],
        scope: ProxyScope = .all
    ) async -> [UUID] {
        var staleIdentifiers: [UUID] = []

        if scope.contains(.normal) {
            let oldStore = defaultStore
            let newStore: WKWebsiteDataStore
            let newIdentifier: UUID?
            if configs.isEmpty {
                // VPN off: return to the original .default() store with its untouched
                // persistent state, and do not carry VPN-session cookies back.
                newStore = WKWebsiteDataStore.default()
                newIdentifier = nil
            } else {
                // VPN on: isolate the session in a fresh identifier-based store so it has
                // its own connection pool and disk footprint we can clean up later.
                let identifier = UUID()
                newStore = WKWebsiteDataStore(forIdentifier: identifier)
                newIdentifier = identifier
                newStore.proxyConfigurations = configs
                await copyCookies(from: oldStore, to: newStore)
            }

            if let oldIdentifier = defaultStoreIdentifier {
                staleIdentifiers.append(oldIdentifier)
            }

            defaultStore = newStore
            defaultStoreIdentifier = newIdentifier
        }

        if scope.contains(.private) {
            let oldStore = nonPersistentStore
            let newStore = WKWebsiteDataStore.nonPersistent()
            newStore.proxyConfigurations = configs
            await copyCookies(from: oldStore, to: newStore)
            nonPersistentStore = newStore
        }

        return staleIdentifiers
    }

    /// Removes the on-disk footprint of persistent stores previously displaced by
    /// `applyProxyConfigurations`. Call only after webviews referencing those stores have
    /// been discarded — outstanding requests keep the store alive and removal will fail.
    @available(iOS 17.0, *)
    public static func removeDataStores(forIdentifiers identifiers: [UUID]) async {
        for identifier in identifiers {
            try? await WKWebsiteDataStore.remove(forIdentifier: identifier)
        }
    }

    @available(iOS 17.0, *)
    private static func copyCookies(
        from oldStore: WKWebsiteDataStore,
        to newStore: WKWebsiteDataStore
    ) async {
        let cookies = await oldStore.httpCookieStore.allCookies()
        for cookie in cookies {
            await newStore.httpCookieStore.setCookie(cookie)
        }
    }
}
