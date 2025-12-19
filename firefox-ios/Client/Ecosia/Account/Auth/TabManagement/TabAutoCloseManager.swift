// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Ecosia

/// Configuration for tab auto-close behavior
struct TabAutoCloseConfig {
    /// Timeout for fallback closure if notification doesn't arrive
    static let fallbackTimeout: TimeInterval = 10.0

    /// Maximum number of invisible tabs that can be auto-closed simultaneously
    static let maxConcurrentAutoCloseTabs: Int = 5

    /// Debounce interval to prevent multiple rapid auto-close operations
    static let debounceInterval: TimeInterval = 0.5
}

/// Manager for automatic closing of invisible tabs based on notifications
/// Handles authentication completion notifications and fallback timeouts
final class InvisibleTabAutoCloseManager {

    // MARK: - Properties

    /// Singleton instance for app-wide auto-close management
    static let shared = InvisibleTabAutoCloseManager()

    /// Dictionary mapping tab UUIDs to their notification observers
    private var authTabObservers: [String: NSObjectProtocol] = [:]

    /// Dictionary mapping tab UUIDs to their fallback timeout work items
    private var fallbackTimeouts: [String: DispatchWorkItem] = [:]

    /// Queue for thread-safe access to observer dictionaries
    private let observerQueue = DispatchQueue(label: "com.ecosia.tabAutoClose", attributes: .concurrent)

    /// Notification center for observing auth completion
    private let notificationCenter: NotificationCenter

    /// Weak reference to tab manager for tab removal operations
    private weak var tabManager: TabManager?

    // MARK: - Initialization

    /// Private initializer to enforce singleton pattern
    /// - Parameter notificationCenter: Notification center for observing, defaults to default center
    private init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    /// Injects tab manager dependency
    /// - Parameter tabManager: Tab manager to use for tab operations
    func setTabManager(_ tabManager: TabManager) {
        self.tabManager = tabManager
    }

    // MARK: - Auto-Close Setup

    /// Sets up automatic closing for a tab when authentication completes
    /// - Parameters:
    ///   - tab: The tab to setup auto-close for
    ///   - notification: The notification name to observe for completion
    ///   - timeout: Custom timeout for fallback closure, defaults to config value
    func setupAutoCloseForTab(_ tab: Tab,
                              on notification: Notification.Name = .EcosiaAuthStateChanged,
                              timeout: TimeInterval = TabAutoCloseConfig.fallbackTimeout) {

        guard tab.isInvisible else {
            EcosiaLogger.invisibleTabs.notice("Attempted to setup auto-close for visible tab: \(tab.tabUUID)")
            return
        }

        EcosiaLogger.invisibleTabs.info("Setting up auto-close for tab: \(tab.tabUUID)")

        observerQueue.sync(flags: .barrier) {
            cleanupObserver(for: tab.tabUUID)
            createObserver(for: tab, notification: notification, timeout: timeout)
        }
    }

    /// Sets up automatic closing for multiple tabs
    /// - Parameters:
    ///   - tabs: Array of tabs to setup auto-close for
    ///   - notification: The notification name to observe for completion
    ///   - timeout: Custom timeout for fallback closure
    func setupAutoCloseForTabs(_ tabs: [Tab],
                               on notification: Notification.Name = .EcosiaAuthStateChanged,
                               timeout: TimeInterval = TabAutoCloseConfig.fallbackTimeout) {

        let invisibleTabs = tabs.filter { $0.isInvisible }

        guard invisibleTabs.count <= TabAutoCloseConfig.maxConcurrentAutoCloseTabs else {
            EcosiaLogger.invisibleTabs.notice("Too many tabs for concurrent auto-close: \(invisibleTabs.count)")
            return
        }

        for tab in invisibleTabs {
            setupAutoCloseForTab(tab, on: notification, timeout: timeout)
        }
    }

    // MARK: - Private Implementation

    /// Creates notification observer and fallback timeout for a tab
    /// - Parameters:
    ///   - tab: The tab to create observer for
    ///   - notification: The notification name to observe
    ///   - timeout: Fallback timeout interval
    private func createObserver(for tab: Tab,
                                notification: Notification.Name,
                                timeout: TimeInterval) {

        let tabUUID = tab.tabUUID

        // Create notification observer for auth completion
        let observer = notificationCenter.addObserver(
            forName: notification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAuthenticationCompletion(for: tabUUID)
        }

        // Store observer
        authTabObservers[tabUUID] = observer

        // Set up page load monitoring for invisible tabs
        setupPageLoadMonitoring(for: tab)

        // Create fallback timeout
        let fallbackWorkItem = DispatchWorkItem { [weak self] in
            EcosiaLogger.invisibleTabs.info("Fallback timeout reached for tab: \(tabUUID)")
            self?.handleAuthenticationCompletion(for: tabUUID, isFallback: true)
        }

        fallbackTimeouts[tabUUID] = fallbackWorkItem

        // Schedule fallback timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: fallbackWorkItem)

        EcosiaLogger.invisibleTabs.info("Auto-close setup completed for tab: \(tabUUID)")
    }

    /// Sets up page load monitoring for an invisible tab
    /// - Parameter tab: The tab to monitor
    private func setupPageLoadMonitoring(for tab: Tab) {
        EcosiaLogger.invisibleTabs.debug("Setting up page load monitoring for tab: \(tab.tabUUID)")
        EcosiaLogger.invisibleTabs.debug("Tab URL: \(tab.url?.absoluteString ?? "nil")")
        EcosiaLogger.invisibleTabs.debug("WebView URL: \(tab.webView?.url?.absoluteString ?? "nil")")

        let pageLoadObserver = notificationCenter.addObserver(
            forName: .OnLocationChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Process immediately without delay to catch all events
            self?.handlePageLoadCompletion(notification, for: tab)
        }

        /*
         We need to track both auth and pageload observers for each tab.
         Using "_pageload" suffix lets us distinguish between the two types
         when counting or cleaning up later.
         */
        authTabObservers["\(tab.tabUUID)_pageload"] = pageLoadObserver

        EcosiaLogger.invisibleTabs.info("Page load monitoring setup for tab: \(tab.tabUUID)")
    }

    /// Handles page load completion for invisible tabs
    /// - Parameters:
    ///   - notification: The location change notification
    ///   - tab: The tab being monitored
    private func handlePageLoadCompletion(_ notification: Notification, for tab: Tab) {
        guard let userInfo = notification.userInfo,
              let url = userInfo["url"] as? URL else {
            return
        }

        // Always log OnLocationChange events for debugging
        EcosiaLogger.invisibleTabs.debug("OnLocationChange: \(url) (isPrivate: \(userInfo["isPrivate"] ?? "unknown"))")

        // Check if this is for our invisible tab by comparing webView
        guard let tabWebView = tab.webView else {
            EcosiaLogger.invisibleTabs.debug("Tab \(tab.tabUUID) has no webView")
            return
        }

        EcosiaLogger.invisibleTabs.info("Ecosia page load detected for invisible tab: \(url)")
        // Wait a moment for any final redirects/auth to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.handleAuthenticationCompletion(for: tab.tabUUID)
        }
    }

    /// Handles authentication completion by closing the tab
    /// - Parameters:
    ///   - tabUUID: UUID of the tab to close
    ///   - isFallback: Whether this was triggered by fallback timeout
    private func handleAuthenticationCompletion(for tabUUID: String, isFallback: Bool = false) {
        observerQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self.cleanupObserver(for: tabUUID)

            // Close the tab on main queue
            DispatchQueue.main.async { [weak self] in
                self?.closeTab(with: tabUUID, isFallback: isFallback)
            }
        }
    }

    /// Closes a tab with the given UUID
    /// - Parameters:
    ///   - tabUUID: UUID of the tab to close
    ///   - isFallback: Whether this was triggered by fallback timeout
    private func closeTab(with tabUUID: String, isFallback: Bool) {
        guard let tabManager = tabManager else {
            EcosiaLogger.invisibleTabs.notice("No tab manager available for closing tab: \(tabUUID)")
            return
        }

        guard let tab = tabManager.tabs.first(where: { $0.tabUUID == tabUUID }) else {
            EcosiaLogger.invisibleTabs.notice("Tab not found for closing: \(tabUUID)")
            return
        }

        // Only close if tab is still invisible
        guard tab.isInvisible else {
            EcosiaLogger.invisibleTabs.notice("Tab is no longer invisible, skipping close: \(tabUUID)")
            return
        }

        EcosiaLogger.invisibleTabs.info("Closing tab: \(tabUUID) \(isFallback ? "(fallback)" : "")")

        // Remove the tab
        tabManager.removeTab(tab) { [weak self] in
            // Select appropriate tab if needed
            self?.selectAppropriateTabAfterRemoval(tabManager: tabManager)

            // Clean up invisible tab tracking
            tabManager.cleanupInvisibleTabTracking()

            EcosiaLogger.invisibleTabs.info("Tab closed successfully: \(tabUUID)")
        }
    }

    /// Selects an appropriate tab after removal if no tab is currently selected
    /// - Parameter tabManager: Tab manager to use for selection
    private func selectAppropriateTabAfterRemoval(tabManager: TabManager) {
        guard tabManager.selectedTab == nil else { return }

        // Try to select the last visible normal tab
        if let lastVisibleTab = tabManager.visibleNormalTabs.last {
            tabManager.selectTab(lastVisibleTab)
                            EcosiaLogger.invisibleTabs.info("Selected last visible normal tab")
        } else if let lastVisibleTab = tabManager.visibleTabs.last {
            tabManager.selectTab(lastVisibleTab)
                            EcosiaLogger.invisibleTabs.info("Selected last visible tab")
        }
    }

    /// Cleans up observer and timeout for a tab UUID
    /// - Parameter tabUUID: UUID of the tab to clean up
    private func cleanupObserver(for tabUUID: String) {
        // Remove auth notification observer
        if let observer = authTabObservers[tabUUID] {
            notificationCenter.removeObserver(observer)
            authTabObservers.removeValue(forKey: tabUUID)
        }

        // Remove page load notification observer
        if let pageLoadObserver = authTabObservers["\(tabUUID)_pageload"] {
            notificationCenter.removeObserver(pageLoadObserver)
            authTabObservers.removeValue(forKey: "\(tabUUID)_pageload")
        }

        // Cancel and remove fallback timeout
        if let timeout = fallbackTimeouts[tabUUID] {
            timeout.cancel()
            fallbackTimeouts.removeValue(forKey: tabUUID)
        }
    }

    // MARK: - Public Cleanup

    /// Cancels auto-close for a specific tab
    /// - Parameter tabUUID: UUID of the tab to cancel auto-close for
    func cancelAutoCloseForTab(_ tabUUID: String) {
        observerQueue.sync(flags: .barrier) {
            cleanupObserver(for: tabUUID)
            EcosiaLogger.invisibleTabs.info("Cancelled auto-close for tab: \(tabUUID)")
        }
    }

    /// Cancels auto-close for multiple tabs
    /// - Parameter tabUUIDs: Array of tab UUIDs to cancel auto-close for
    func cancelAutoCloseForTabs(_ tabUUIDs: [String]) {
        for tabUUID in tabUUIDs {
            cancelAutoCloseForTab(tabUUID)
        }
    }

    /// Cleans up all observers and timeouts
    func cleanupAllObservers() {
        observerQueue.sync(flags: .barrier) {
            // Clean up all observers
            for (tabUUID, observer) in authTabObservers {
                notificationCenter.removeObserver(observer)
                EcosiaLogger.invisibleTabs.info("Cleaned up observer for tab: \(tabUUID)")
            }

            // Cancel all timeouts
            for (tabUUID, timeout) in fallbackTimeouts {
                timeout.cancel()
                EcosiaLogger.invisibleTabs.info("Cancelled timeout for tab: \(tabUUID)")
            }

            // Clear dictionaries
            authTabObservers.removeAll()
            fallbackTimeouts.removeAll()

            EcosiaLogger.invisibleTabs.info("All observers and timeouts cleaned up")
        }
    }

    /// Returns the current number of tabs being tracked for auto-close
    var trackedTabCount: Int {
        return observerQueue.sync {
            /*
             Each tab has two observers (auth + pageload), but we only want
             to count tabs, not individual observers
             */
            authTabObservers.keys.filter { !$0.contains("_pageload") }.count
        }
    }

    /// Returns the UUIDs of all tabs currently being tracked for auto-close
    var trackedTabUUIDs: [String] {
        return observerQueue.sync {
            /*
             Filter out the pageload observer keys to get just the tab UUIDs
             */
            Array(authTabObservers.keys.filter { !$0.contains("_pageload") })
        }
    }
}
