// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import ComponentLibrary

// TODO: FXIOS-14070 - migrate OnboardingBottomSheetViewController to ComponentLibrary and adopt it where needed. 
public class OnboardingBottomSheetViewController: UIViewController,
                                                  Themeable,
                                                  Notifiable {
    private struct UX {
        static var closeButtonPadding: CGFloat {
            if #available(iOS 26, *) {
                return 18.0
            }
            return 12.0
        }
    }

    public var themeManager: any Common.ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: Common.WindowUUID?

    private var notificationCenter: NotificationProtocol
    /// The last calculated height for the bottom sheet custom detent.
    private var lastCalculatedHeight: CGFloat = 0
    private var child: UIViewController?
    /// Closure called when the bottom sheet is dismissed via the close button
    public var onDismiss: (() -> Void)?

    private lazy var closeButton: UIButton = .build {
        $0.addAction(UIAction(handler: { [weak self] _ in
            self?.onDismiss?()
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        if #available(iOS 26, *) {
            $0.configuration = .prominentClearGlass()
        } else {
            $0.configuration = .filled()
            $0.configuration?.cornerStyle = .capsule
        }
        $0.configuration?.image = UIImage(named: StandardImageIdentifiers.Large.cross)?
            .withRenderingMode(.alwaysTemplate)
    }
    private lazy var backgroundView: UIVisualEffectView = .build {
        if #unavailable(iOS 26.0) {
            $0.effect = UIBlurEffect(style: .systemUltraThinMaterial)
        }
    }

    private lazy var contentView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
    }

    public init(
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.currentWindowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
        setupDetents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupDetents() {
        if #available(iOS 16.0, *) {
            let customDetent = UISheetPresentationController.Detent.custom { [weak self] context in
                return self?.lastCalculatedHeight ?? 0.0
            }
            sheetPresentationController?.detents = [customDetent]
        } else {
            sheetPresentationController?.detents = [.large(), .medium()]
        }
    }

    /// Configure the bottom sheet with the required models and view to show.
    ///
    /// Make sure to call this methid just once, otherwise it won't update the new child.
    public func configure(closeButtonModel: CloseButtonViewModel, child: UIViewController) {
        closeButton.accessibilityLabel = closeButtonModel.a11yLabel
        closeButton.accessibilityIdentifier = closeButtonModel.a11yIdentifier

        // Add the child only if it wasn't added yet.
        guard child.view.superview == nil else { return }
        self.child = child
        setupLayout(child: child)
        calculateAndUpdateDetentsHeight(child: child)
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
        UIAccessibility.post(notification: .screenChanged, argument: closeButton)
    }

    private func setupLayout(child: UIViewController) {
        closeButton.scalesLargeContentImage = true

        addChild(child)
        view.addSubviews(backgroundView, contentView, closeButton)
        view.accessibilityElements = [closeButton, contentView]
        contentView.addSubview(child.view)
        child.view.translatesAutoresizingMaskIntoConstraints = false

        backgroundView.pinToSuperview()
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.closeButtonPadding),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.closeButtonPadding),

            contentView.topAnchor.constraint(equalTo: closeButton.bottomAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            child.view.topAnchor.constraint(equalTo: contentView.contentLayoutGuide.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: contentView.contentLayoutGuide.bottomAnchor),
            child.view.leadingAnchor.constraint(equalTo: contentView.contentLayoutGuide.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: contentView.contentLayoutGuide.trailingAnchor),
            child.view.widthAnchor.constraint(equalTo: contentView.frameLayoutGuide.widthAnchor),

            child.view.heightAnchor.constraint(greaterThanOrEqualTo: contentView.heightAnchor)
        ])

        child.didMove(toParent: self)
        closeButton.setContentCompressionResistancePriority(.required, for: .vertical)
        closeButton.setContentHuggingPriority(.required, for: .vertical)
    }

    private func calculateAndUpdateDetentsHeight(child: UIViewController) {
        guard #available(iOS 16.0, *) else { return }
        let targetSize = CGSize(
            width: view.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        let fittingSize = child.view.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        closeButton.layoutIfNeeded()
        let calculatedHeight = fittingSize.height
                                + closeButton.frame.height
                                + UX.closeButtonPadding * 2.0

        lastCalculatedHeight = calculatedHeight
        sheetPresentationController?.animateChanges { [weak self] in
            self?.sheetPresentationController?.invalidateDetents()
        }
    }

    // MARK: - Notifiable
    nonisolated public func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        DispatchQueue.main.async { [self] in
            guard let child else { return }
            calculateAndUpdateDetentsHeight(child: child)
        }
    }

    // MARK: - Themeable
    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        view.backgroundColor = .clear
        // The background view is not needed when presenting a bottom sheet in iOS 26.
        // The bottom sheet presentation already contains the glass effect.
        if #unavailable(iOS 26.0) {
            backgroundView.alpha = 1.0
            closeButton.configuration?.baseBackgroundColor = theme.colors.layer2
            closeButton.configuration?.baseForegroundColor = theme.colors.iconPrimary
        } else {
            closeButton.tintColor = theme.colors.iconPrimary
            backgroundView.alpha = 0.0
        }
    }
}
