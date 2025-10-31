// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import WebEngine
import Common

class StoriesWebviewViewController: UIViewController,
                                    Themeable {
    private struct UX {
        static let navigationTitleStackViewSpacing: CGFloat = 4
        static let shieldImageSize = CGSize(width: 14, height: 14)
    }

    // MARK: - Themeable Properties
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol

    // MARK: - Private Properties
    private var webView: WKWebView

    // MARK: - UI Properties
    private let navigationTitleStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = UX.navigationTitleStackViewSpacing
    }

    private lazy var domainLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.body.scaledFont()
        label.numberOfLines = 1
        label.text = self.webView.url?.normalizedHost ?? self.webView.url?.absoluteString ?? "X"
    }

    private let shieldImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: StandardImageIdentifiers.Large.shieldCheckmark)?.withRenderingMode(.alwaysTemplate)
    }

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         webView: WKWebView) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupWebView()
        setupNavigationTitle()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    // MARK: Helper functions
    private func setupWebView() {
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupNavigationTitle() {
        navigationTitleStackView.addArrangedSubview(shieldImageView)
        navigationTitleStackView.addArrangedSubview(domainLabel)

        NSLayoutConstraint.activate([
            shieldImageView.widthAnchor.constraint(equalToConstant: UX.shieldImageSize.width),
            shieldImageView.heightAnchor.constraint(equalToConstant: UX.shieldImageSize.height)
        ])

        navigationItem.titleView = navigationTitleStackView
    }

    private func applyNavigationBarTheme(theme: Theme) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.colors.layer1
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        applyNavigationBarTheme(theme: theme)
        domainLabel.textColor = theme.colors.textPrimary
        shieldImageView.tintColor = theme.colors.iconPrimary
    }
}
