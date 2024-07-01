// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol Themeable: ThemeUUIDIdentifiable, AnyObject {
    var themeManager: ThemeManager { get }
    var themeObserver: NSObjectProtocol? { get set }
    var notificationCenter: NotificationProtocol { get set }

    func listenForThemeChange(_ subview: UIView)
    func applyTheme()
}

/// Protocol for views to identify which iPad window (UUID) the view is associated with.
/// By default, all UIViews conform to this automatically. See: UIView+ThemeUUIDIdentifiable.swift.
public protocol ThemeUUIDIdentifiable: AnyObject {
    var currentWindowUUID: WindowUUID? { get }
}

/// Protocol that views or controllers may optionally adopt when they provide an explicit (typically, injected)
/// window UUID. This is used by our convenience extensions to allow UIViews to automatically detect their
/// associated iPad window UUID, even if the view is not immediately installed in a window or view hierarchy.
public protocol InjectedThemeUUIDIdentifiable: AnyObject {
    var windowUUID: WindowUUID { get }
}

extension Themeable {
    public func listenForThemeChange(_ subview: UIView) {
        let mainQueue = OperationQueue.main
        themeObserver = notificationCenter.addObserver(name: .ThemeDidChange,
                                                       queue: mainQueue) { [weak self] _ in
            self?.applyTheme()
            self?.updateThemeApplicableSubviews(subview, for: self?.currentWindowUUID)
        }
    }

    public func updateThemeApplicableSubviews(_ view: UIView, for window: WindowUUID?) {
        guard let uuid = (view as? ThemeUUIDIdentifiable)?.currentWindowUUID ?? window else { return }
        assert(uuid != .unavailable, "Theme applicable view has `unavailable` window UUID. Unexpected.")
        let theme = themeManager.getCurrentTheme(for: uuid)
        let themeViews = getAllSubviews(for: view, ofType: ThemeApplicable.self)
        themeViews.forEach { $0.applyTheme(theme: theme) }
    }

    public func getAllSubviews<T>(for view: UIView, ofType type: T.Type) -> [T] {
        var secondLevelSubviews = [T]()
        let firstLevelSubviews: [T] = view.subviews.compactMap { childView in
            secondLevelSubviews = secondLevelSubviews + getAllSubviews(for: childView, ofType: type)
            return childView as? T
        }
        return firstLevelSubviews + secondLevelSubviews
    }
}
