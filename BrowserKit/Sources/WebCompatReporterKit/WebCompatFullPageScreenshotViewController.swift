// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// What the viewer reports back. The coordinator does the dismissing.
@MainActor
public protocol WebCompatFullPageScreenshotDelegate: AnyObject {
    func webCompatFullPageScreenshotDidTapClose()
}

/// Full-screen page viewer, shown over the Report Preview sheet.
public final class WebCompatFullPageScreenshotViewController: UIViewController, ThemeApplicable {
    public weak var delegate: WebCompatFullPageScreenshotDelegate?

    let screenshotView: WebCompatFullPageScreenshotView

    public init(image: UIImage?, closeButtonViewModel: CloseButtonViewModel, theme: Theme) {
        screenshotView = WebCompatFullPageScreenshotView(image: image, closeButtonViewModel: closeButtonViewModel)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        // The scrim is translucent and the sheet underneath stays mounted, so
        // without this VoiceOver swipes straight through into it.
        screenshotView.accessibilityViewIsModal = true
        screenshotView.onClose = { [weak self] in
            self?.delegate?.webCompatFullPageScreenshotDidTapClose()
        }
        screenshotView.applyTheme(theme: theme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        view = screenshotView
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: Theme) {
        screenshotView.applyTheme(theme: theme)
    }
}
