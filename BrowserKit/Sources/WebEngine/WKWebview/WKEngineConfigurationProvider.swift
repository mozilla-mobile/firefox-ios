// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

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
    func endPrivateBrowsingSession()
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
    private static var staleStoreIdentifier: UUID?
    private static let defaultDataDetectorTypes: WKDataDetectorTypes = [.phoneNumber]
    private let configuration: WKWebViewConfiguration

    public init(configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        self.configuration = configuration
    }

    @available(iOS 26.0, *)
    public static func rebuildStores(
        applyingProxy configs: [ProxyConfiguration],
        scope: ProxyScope
    ) async {
        switch scope {
        case .normal:
            let oldStore = defaultStore
            let newIdentifier = UUID()
            let newStore = WKWebsiteDataStore(forIdentifier: newIdentifier)
            newStore.proxyConfigurations = configs
            await copyData(from: oldStore, to: newStore)
            await copyCookies(from: oldStore, to: newStore)
            staleStoreIdentifier = defaultStoreIdentifier
            defaultStore = newStore
            defaultStoreIdentifier = newIdentifier
        case .private:
            let oldStore = nonPersistentStore
            let newStore = WKWebsiteDataStore.nonPersistent()
            newStore.proxyConfigurations = configs
            await copyData(from: oldStore, to: newStore)
            await copyCookies(from: oldStore, to: newStore)
            nonPersistentStore = newStore
        }
    }

    @available(iOS 26.0, *)
    public static func copyData(from newStore: WKWebsiteDataStore, to oldStore: WKWebsiteDataStore) async {
        do {
            let oldData = try await oldStore.fetchData(of: WKWebsiteDataStore.allWebsiteDataTypes())
            try await newStore.restoreData(oldData)
        } catch {
            // log error
        }
    }

    /// Assigns `proxyConfigurations` on the active stores without swapping them or copying
    /// cookies. Use this for token rotation, where the proxy endpoint is unchanged and only
    /// the auth header differs: WebKit keeps the existing connection pool so in-flight
    /// requests get their grace period, and future requests are sent with the new header.
    @available(iOS 17.0, *)
    public static func applyProxyConfigurations(
        _ configs: [ProxyConfiguration],
        scope: ProxyScope
    ) {
        switch scope {
        case .normal:
            defaultStore.proxyConfigurations = configs
        case .private:
            nonPersistentStore.proxyConfigurations = configs
        }
    }

    /// Removes the on-disk footprint of persistent stores previously displaced by
    /// `rebuildStores(applyingProxy:scope:)`. Call only after webviews referencing those
    /// stores have been discarded — outstanding requests keep the store alive and removal
    /// will fail.
    @available(iOS 17.0, *)
    public static func removeStaleStores() async {
        do {
            if let staleID = Self.staleStoreIdentifier {
                try await WKWebsiteDataStore.remove(forIdentifier: staleID)
            }
        } catch {
            // log error
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

    public func endPrivateBrowsingSession() {
        Self.nonPersistentStore = .nonPersistent()
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
}

public enum ProxyScope {
    case `private`
    case normal
}
