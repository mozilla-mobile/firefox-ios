// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import ComponentLibrary

// TODO: FXIOS-14070 - migrate OnboardingBottomSheetViewController to ComponentLibrary and adopt it where needed. 
public class SetDefaultBrowserViewController: UIViewController,
                                              Themeable {
    public var themeManager: any Common.ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: Common.WindowUUID?
    private var notificationCenter: NotificationProtocol
    private let child: UIViewController
    
    var lastCalculatedHeight: CGFloat = 0
    private var hasInitialLayoutCompleted = false

    private lazy var closeButton: UIButton = .build {
        $0.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        $0.addAction(UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        $0.showsLargeContentViewer = true
    }
    private lazy var contentView: UIScrollView = .build {
        $0.showsVerticalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
    }

    init(
        child: UIViewController,
        closeButtonModel: CloseButtonViewModel,
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol,
        themeManager: ThemeManager
    ) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.currentWindowUUID = windowUUID
        self.child = child
        super.init(nibName: nil, bundle: nil)
    }

    public static func factory(
        child: UIViewController,
        closeButtonModel: CloseButtonViewModel,
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) -> UIViewController {
        let controller = SetDefaultBrowserViewController(child: child,
                                                         closeButtonModel: closeButtonModel,
                                                         windowUUID: windowUUID,
                                                         notificationCenter: notificationCenter,
                                                         themeManager: themeManager)
        let navController = UINavigationController(rootViewController: controller)

        if #available(iOS 16.0, *) {
            let customDetent = UISheetPresentationController.Detent.custom { [weak controller] context in
                return controller?.lastCalculatedHeight ?? 0.0
            }
            navController.sheetPresentationController?.detents = [customDetent]
        } else {
            navController.sheetPresentationController?.detents = [.large(), .medium()]
        }
        navController.sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
        navController.sheetPresentationController?.prefersScrollingExpandsWhenScrolledToEdge = false
        return navController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasInitialLayoutCompleted {
            calculateAndUpdateHeight()
            hasInitialLayoutCompleted = true
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if lastCalculatedHeight == 0 {
            calculateAndUpdateHeight()
        }
    }
    
    private func setupLayout() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)
        
        addChild(child)
        view.addSubview(contentView)
        contentView.addSubview(child.view)

        contentView.pinToSuperview()
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: contentView.contentLayoutGuide.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: contentView.contentLayoutGuide.bottomAnchor),
            child.view.leadingAnchor.constraint(equalTo: contentView.contentLayoutGuide.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: contentView.contentLayoutGuide.trailingAnchor),
            child.view.widthAnchor.constraint(equalTo: contentView.frameLayoutGuide.widthAnchor),
            child.view.heightAnchor.constraint(greaterThanOrEqualTo: contentView.heightAnchor)
        ])
        
        child.didMove(toParent: self)
    }

    private func calculateAndUpdateHeight() {
        child.view.layoutIfNeeded()
        let targetSize = CGSize(
            width: view.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        let fittingSize = child.view.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let calculatedHeight = fittingSize.height
        print("FF: calculated Height: \(calculatedHeight)")
        if #available(iOS 16.0, *) {
            lastCalculatedHeight = calculatedHeight
            navigationController?.sheetPresentationController?.animateChanges { [weak self] in
                self?.navigationController?.sheetPresentationController?.invalidateDetents()
            }
        }
    }

    // MARK: - Themeable

    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        closeButton.tintColor = theme.colors.iconPrimary
        if #unavailable(iOS 26.0) {
            view.backgroundColor = theme.colors.layer1
        }
    }
}
