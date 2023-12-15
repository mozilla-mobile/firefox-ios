// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import WebKit

class TabPeekViewController: UIViewController {
    weak var tab: Tab? // Tab ID, screenshot, webview accessiblity label

    private var previewAccessibilityLabel: String!
    private var ignoreURL = false
    private var isBookmarked = false
    private var isInReadingList = false
    private var hasRemoteClients = false

    func contextActions(defaultActions: [UIMenuElement]) -> UIMenu {
        return makeMenuActions()
    }

    // MARK: - Lifecycle methods

    init(tab: Tab?) {
        self.tab = tab
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let webViewAccessibilityLabel = tab?.webView?.accessibilityLabel {
            previewAccessibilityLabel = String(format: .TabPeekPreviewAccessibilityLabel, webViewAccessibilityLabel)
        }

        setupWithScreenshot(tab?.screenshot ?? UIImage())
    }

    // MARK: - Private helper methods

    private func setupWithScreenshot(_ screenshot: UIImage) {
        let imageView: UIImageView = .build { imageView in
            imageView.image = screenshot
        }
        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        screenshot.accessibilityLabel = previewAccessibilityLabel
    }

    private func makeMenuActions() -> UIMenu {
        var actions = [UIAction]()

        let urlIsTooLongToSave = self.tab?.urlIsTooLong ?? false
        let isHomeTab = self.tab?.isFxHomeTab ?? false
        if !self.ignoreURL && !urlIsTooLongToSave {
            if !self.isBookmarked && !isHomeTab {
                actions.append(UIAction(title: .TabPeekAddToBookmarks,
                                        image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.bookmark),
                                        identifier: nil) { _ in
                    return
                })
            }
            if self.hasRemoteClients {
                actions.append(UIAction(title: .AppMenu.TouchActions.SendToDeviceTitle, image: UIImage.templateImageNamed("menu-Send"), identifier: nil) { _ in
                    return
                })
            }
            actions.append(UIAction(title: .TabPeekCopyUrl,
                                    image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.link),
                                    identifier: nil) { _ in
                return
            })
        }
        actions.append(UIAction(title: .TabPeekCloseTab,
                                image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
                                identifier: nil) { _ in
            return
        })

        return UIMenu(title: "", children: actions)
    }
}
