// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// What the viewer reports back. The coordinator does the dismissing.
@MainActor
public protocol WebCompatFullPageScreenshotDelegate: AnyObject {
    func webCompatFullPageScreenshotDidRequestDismiss()
}

/// Describes the capture to assistive tech and to UI automation. Both values are supplied by the
/// caller because the package can reach neither Client's strings nor its `AccessibilityIdentifiers`.
public struct WebCompatFullPageScreenshotViewModel: Equatable, Sendable {
    public let captureAccessibilityLabel: String
    public let captureAccessibilityIdentifier: String

    public init(captureAccessibilityLabel: String, captureAccessibilityIdentifier: String) {
        self.captureAccessibilityLabel = captureAccessibilityLabel
        self.captureAccessibilityIdentifier = captureAccessibilityIdentifier
    }
}

/// Full-screen page viewer, shown over the Report Preview sheet.
public final class WebCompatFullPageScreenshotViewController: UIViewController, Themeable {
    public weak var delegate: WebCompatFullPageScreenshotDelegate?

    public let themeManager: ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: WindowUUID?
    private let notificationCenter: NotificationProtocol

    private let screenshotView: WebCompatFullPageScreenshotView

    public init(
        image: UIImage?,
        viewModel: WebCompatFullPageScreenshotViewModel,
        closeButtonViewModel: CloseButtonViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        screenshotView = WebCompatFullPageScreenshotView(
            image: image,
            viewModel: viewModel,
            closeButtonViewModel: closeButtonViewModel
        )
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        // The sheet underneath stays mounted, so without this VoiceOver swipes into it.
        screenshotView.accessibilityViewIsModal = true
        screenshotView.onClose = { [weak self] in
            self?.delegate?.webCompatFullPageScreenshotDidRequestDismiss()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        view = screenshotView
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    // MARK: - Accessibility

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        screenshotView.moveAccessibilityFocusToCloseButton()
    }

    /// The two-finger scrub. Without it the only way out is the close button.
    override public func accessibilityPerformEscape() -> Bool {
        guard let delegate else { return false }
        delegate.webCompatFullPageScreenshotDidRequestDismiss()
        return true
    }

    // MARK: - Themeable

    public func applyTheme() {
        screenshotView.applyTheme(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
    }
}
