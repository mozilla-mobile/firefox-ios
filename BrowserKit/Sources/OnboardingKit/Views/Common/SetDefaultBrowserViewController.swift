// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit
import ComponentLibrary

// BottomSheetViewController
public class SetDefaultBrowserViewController: UIViewController,
                                              Themeable {
    public var themeManager: any Common.ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: Common.WindowUUID?
    private var notificationCenter: NotificationProtocol
    private let child: UIViewController
    var onHeightUpdate: ((CGFloat) -> Void)?

    private var lastCalculatedHeight: CGFloat = 0
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

    init(
        child: UIViewController,
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
        windowUUID: WindowUUID,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) -> UIViewController {
        let testChild = UIHostingController(rootView: TestOnboardingView())
        testChild.view.backgroundColor = .clear
        let controller = SetDefaultBrowserViewController(child: testChild,
                                                         windowUUID: windowUUID,
                                                         notificationCenter: notificationCenter,
                                                         themeManager: themeManager)
        let navController = UINavigationController(rootViewController: controller)

        if #available(iOS 16.0, *) {
            final class HeightHolder {
                var height: CGFloat = 400
            }
            let heightHolder = HeightHolder()

            controller.onHeightUpdate = { [weak navController] height in
                heightHolder.height = height
                if let sheet = navController?.sheetPresentationController {
                    sheet.animateChanges {
                        sheet.invalidateDetents()
                    }
                }
            }

            let customDetent = UISheetPresentationController.Detent.custom { context in
                return heightHolder.height
            }

            navController.sheetPresentationController?.detents = [customDetent]
        } else {
            navController.sheetPresentationController?.detents = [.large(), .medium()]
        }
        navController.sheetPresentationController?.prefersGrabberVisible = true
        navController.sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
        return navController
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    private func calculateAndUpdateHeight() {
        child.view.setNeedsLayout()
        child.view.layoutIfNeeded()

        var calculatedHeight: CGFloat = 0

        if let hostingController = child as? UIHostingController<TestOnboardingView> {
            let hostingSize = hostingController.sizeThatFits(in: CGSize(
                width: view.bounds.width,
                height: CGFloat.greatestFiniteMagnitude
            ))
            calculatedHeight = hostingSize.height
        } else {
            let targetSize = CGSize(
                width: view.bounds.width,
                height: UIView.layoutFittingCompressedSize.height
            )

            let fittingSize = child.view.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            calculatedHeight = fittingSize.height
        }

        let heightDifference = abs(calculatedHeight - lastCalculatedHeight)
        if heightDifference > 5 || lastCalculatedHeight == 0 {
            lastCalculatedHeight = calculatedHeight
            onHeightUpdate?(calculatedHeight)
        }
    }

    private func setupLayout() {
        addChild(child)

        view.addSubviews(child.view)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)

        child.view.pinToSuperview()
        child.didMove(toParent: self)
    }

    // MARK: - Themeable

    public func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        closeButton.tintColor = theme.colors.iconPrimary
    }
}

import SwiftUI

struct TestOnboardingView: View {
    var body: some View {
            VStack(spacing: 32.0) {
                VStack {
                }
                Text("Switch your default browser")
                    .font(FXFontStyles.Bold.title3.scaledSwiftUIFont())

                Text("""
        1. Go to **Settings**

        2. Tap to **Default Browser App**

        3. Select **Firefox**
        """
                )
                .font(FXFontStyles.Regular.subheadline.scaledSwiftUIFont())

                OnboardingPrimaryButton(
                    title: "Go to settings",
                    action: {
                    },
                    theme: LightTheme(),
                    accessibilityIdentifier: "")
            }
        .padding(.horizontal, 40.0)
        .padding(.top, 30.0)
        .padding(.bottom, 20.0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrollBounceBehavior(basedOnSize: true)
        .background(Color.blue.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 3)
        )
    }
}
