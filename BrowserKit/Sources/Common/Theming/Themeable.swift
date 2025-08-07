// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Combine

public protocol Themeable: ThemeUUIDIdentifiable {
    /// Whether we should override / force the theme to be private or not private. Goes against the basic theme set up.
    nonisolated var shouldUsePrivateOverride: Bool { get }

    /// Determines if we want views to be in private theme or not.
    @MainActor
    var shouldBeInPrivateTheme: Bool { get }

    @MainActor
    var themeManager: ThemeManager { get }

    // MARK: - Theme observation

    /// Holds a reference to the theme changes publisher. Once deallocated, the NotificationCenter observer is removed.
    /// We use an `Any?` type here because we don't want to force a Combine import to access `Cancellable` in other files.
    ///
    /// Note: We can't provide a default `@objc` `nonisolated` `#selector` implementations in `Themeable` because Objective-C
    /// protocols cannot have default implementations. That is why we use the Combine variant of adding notification
    /// observation for `Themeable`. That way, we don't have to have the `#selector` implementation in each conforming class
    /// and we also don't have to worry about removing observers on `deinit`. The `Cancellable` will take care of that for us
    /// when the property deallocates with its parent class.
    @MainActor
    var themeListenerCancellable: Any? { get set }

    /// Start listening for theme changes. Should only be called once in the view lifecycle (e.g. in `viewDidLoad()`).
    @MainActor
    func listenForThemeChanges(withNotificationCenter notificationCenter: NotificationProtocol)

    /// Called when the theme updates for the registered view and all its subviews. Applies the current theme to the
    /// view hierarchy.
    @MainActor
    func applyTheme()
}

/// Protocol for views to identify which iPad window (UUID) the view is associated with.
/// By default, all UIViews conform to this automatically. See: UIView+ThemeUUIDIdentifiable.swift.
public protocol ThemeUUIDIdentifiable: AnyObject {
    @MainActor
    var currentWindowUUID: WindowUUID? { get }
}

/// Protocol that views or controllers may optionally adopt when they provide an explicit (typically, injected)
/// window UUID. This is used by our convenience extensions to allow UIViews to automatically detect their
/// associated iPad window UUID, even if the view is not immediately installed in a window or view hierarchy.
public protocol InjectedThemeUUIDIdentifiable: AnyObject {
    @MainActor
    var windowUUID: WindowUUID { get }
}

extension Themeable {
    public var shouldUsePrivateOverride: Bool { return false }
    public var shouldBeInPrivateTheme: Bool { return false }

    /// Updates subviews of the `Themeable` view, which can specify whether it wants to use the
    /// base theme via `getCurrentTheme` or override the private mode theme via `resolvedTheme`
    @MainActor
    public func updateThemeApplicableSubviews(_ view: UIView, for window: WindowUUID?) {
        assert(Thread.isMainThread)

        guard let uuid = (view as? ThemeUUIDIdentifiable)?.currentWindowUUID ?? window else { return }
        assert(uuid != .unavailable, "Theme applicable view has `unavailable` window UUID. Unexpected.")

        let theme: Theme
        if shouldUsePrivateOverride {
            theme = themeManager.resolvedTheme(with: shouldBeInPrivateTheme)
        } else {
            theme = themeManager.getCurrentTheme(for: uuid)
        }

        let themeViews = getAllSubviews(for: view, ofType: ThemeApplicable.self)
        themeViews.forEach { $0.applyTheme(theme: theme) }
    }

    @MainActor
    public func getAllSubviews<T>(for view: UIView, ofType type: T.Type) -> [T] {
        var secondLevelSubviews = [T]()
        let firstLevelSubviews: [T] = view.subviews.compactMap { childView in
            secondLevelSubviews = secondLevelSubviews + getAllSubviews(for: childView, ofType: type)
            return childView as? T
        }
        return firstLevelSubviews + secondLevelSubviews
    }

    @MainActor
    fileprivate func themeListenerFactory(
        withNotificationCenter notificationCenter: NotificationProtocol,
        themeUpdateClosure: @MainActor @escaping (NotificationCenter.Publisher.Output) -> Void
    ) -> AnyCancellable {
        return notificationCenter
            .publisher(for: .ThemeDidChange, object: nil)
            // NOTE: In case theme updates are ever posted on a background thread, we **MUST** ensure the main queue here.
            // The `@MainActor` isolation is not enough to prevent crashes at the call site where a notification is posted.
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: themeUpdateClosure)
    }
}

extension Themeable where Self: UIViewController {
    @MainActor
    public func listenForThemeChanges(withNotificationCenter notificationCenter: NotificationProtocol) {
        themeListenerCancellable = themeListenerFactory(
            withNotificationCenter: notificationCenter,
            themeUpdateClosure: { [weak self] notification in
                guard let self else { return }

                self.applyTheme()
                self.updateThemeApplicableSubviews(self.view, for: self.currentWindowUUID)
            }
        )
    }
}

extension Themeable where Self: UIView {
    @MainActor
    public func listenForThemeChanges(withNotificationCenter notificationCenter: NotificationProtocol) {
        themeListenerCancellable = themeListenerFactory(
            withNotificationCenter: notificationCenter,
            themeUpdateClosure: { [weak self] notification in
                guard let self else { return }

                self.applyTheme()
                self.updateThemeApplicableSubviews(self, for: self.currentWindowUUID)
            }
        )
    }
}
