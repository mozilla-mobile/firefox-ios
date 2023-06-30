// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol BrowserNavigationHandler: AnyObject {
    /// Asks to show a settings page, can be a general settings page or a child page
    /// - Parameter settings: The settings route we're trying to get to
    func show(settings: Route.SettingsSection)

    /// Asks to show a enhancedTrackingProtection page, can be a general enhancedTrackingProtection page or a child page
    func showEnhancedTrackingProtection()

    /// Shows the specified section of the home panel.
    ///
    /// - Parameter homepanelSection: The section to be displayed.
    func show(homepanelSection: Route.HomepanelSection)

    /// Shows the share extension.
    ///
    /// - Parameter url: The url to be shared.
    /// - Parameter sourceView: The reference view to show the popoverViewController.
    /// - Parameter alertContainer: The view in which is displayed the alert results from actions in the share extension.
    func showShareExtension(url: URL, sourceView: UIView, alertContainer: UIView, popoverArrowDirection: UIPopoverArrowDirection)
}

extension BrowserNavigationHandler {
    func showShareExtension(url: URL, sourceView: UIView, alertContainer: UIView, popoverArrowDirection: UIPopoverArrowDirection = .up) {
        showShareExtension(url: url, sourceView: sourceView, alertContainer: alertContainer, popoverArrowDirection: popoverArrowDirection)
    }
}
