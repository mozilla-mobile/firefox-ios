// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// Protocol followed by child of the bottom sheet, which holds the content shown in the bottom sheet.
public protocol BottomSheetChild: UIViewController {
    /// Tells the child that the bottom sheet will get dismissed
    func willDismiss()
}

/// Protocol followed by the bottom sheet view controller. Gives the possibility to dismiss the bottom sheet.
public protocol BottomSheetDismissProtocol {
    func dismissSheetViewController(completion: (() -> Void)?)
}

public class BottomSheetViewController: UIViewController,
                                        BottomSheetDismissProtocol,
                                        Themeable,
                                        UIGestureRecognizerDelegate {
    private struct UX {
        static let minVisibleTopSpace: CGFloat = 40
        static let closeButtonTopTrailingSpace: CGFloat = 16
        static let initialSpringVelocity: CGFloat = 1
        static let springWithDamping = 0.7
        static let animationDuration = 0.5
    }

    public var notificationCenter: NotificationProtocol
    public var themeManager: ThemeManager
    public var themeObserver: NSObjectProtocol?

    private let viewModel: BottomSheetViewModel
    private var useDimmedBackground: Bool
    private let childViewController: BottomSheetChild

    // Views
    private lazy var scrollView: FadeScrollView = .build { scrollView in
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    private lazy var topTapView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var dimmedBackgroundView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }

    private lazy var sheetView: UIView = .build { _ in }
    private lazy var contentView: UIView = .build { _ in }
    private lazy var scrollContentView: UIView = .build { _ in }
    private var contentViewBottomConstraint: NSLayoutConstraint!
    private var viewTranslation = CGPoint(x: 0, y: 0)
    private let windowUUID: WindowUUID

    // MARK: Init
    public init(viewModel: BottomSheetViewModel,
                childViewController: BottomSheetChild,
                usingDimmedBackground: Bool = false,
                windowUUID: WindowUUID,
                notificationCenter: NotificationProtocol = NotificationCenter.default,
                themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.childViewController = childViewController
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.useDimmedBackground = usingDimmedBackground
        self.windowUUID = windowUUID

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        sheetView.alpha = 1
        setupChildViewController()

        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: viewModel.closeButtonA11yLabel,
                                                        a11yIdentifier: "a11yCloseButton")
        closeButton.configure(viewModel: closeButtonViewModel)

        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        contentView.addGestureRecognizer(gesture)
        gesture.delegate = self

        listenForThemeChange(view)
        setupView()

        contentViewBottomConstraint.constant = childViewController.view.frame.height
        view.layoutIfNeeded()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        contentViewBottomConstraint.constant = 0
        UIView.animate(withDuration: viewModel.animationTransitionDuration) {
            self.view.backgroundColor = self.viewModel.backgroundColor
            self.view.layoutIfNeeded()
        }
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = viewModel.cornerRadius
        contentView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        sheetView.layer.backgroundColor = UIColor.clear.cgColor
        sheetView.layer.shadowColor = UIColor.black.cgColor
        sheetView.layer.shadowOffset = CGSize(width: 0, height: -5.0)
        sheetView.layer.shadowRadius = 20.0
        sheetView.layer.shadowPath = UIBezierPath(roundedRect: sheetView.bounds,
                                                  cornerRadius: viewModel.cornerRadius).cgPath
    }

    // MARK: - Theme

    public func applyTheme() {
        contentView.backgroundColor = themeManager.getCurrentTheme(for: windowUUID).colors.layer1
        sheetView.layer.shadowOpacity = viewModel.shadowOpacity

        if useDimmedBackground {
            dimmedBackgroundView.alpha = 0.4
            dimmedBackgroundView.backgroundColor = .black
        }
    }

    public var currentWindowUUID: WindowUUID? {
        return windowUUID
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }

    // MARK: - Private

    private func setupView() {
        if viewModel.shouldDismissForTapOutside {
            topTapView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                   action: #selector(self.closeTapped)))
        }

        scrollView.addSubview(scrollContentView)
        sheetView.addSubview(contentView)
        contentView.addSubviews(closeButton, scrollView)
        view.addSubviews(dimmedBackgroundView, topTapView, sheetView)
        view.accessibilityElements = [closeButton, sheetView]

        contentViewBottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            greaterThanOrEqualTo: scrollContentView.heightAnchor)

        NSLayoutConstraint.activate([
            topTapView.topAnchor.constraint(equalTo: view.topAnchor),
            topTapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topTapView.bottomAnchor.constraint(equalTo: sheetView.topAnchor, constant: viewModel.cornerRadius),
            topTapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            dimmedBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            sheetView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor,
                                           constant: BottomSheetViewController.UX.minVisibleTopSpace),
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentViewBottomConstraint,
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: sheetView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor,
                                             constant: BottomSheetViewController.UX.closeButtonTopTrailingSpace),
            closeButton.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -BottomSheetViewController.UX.closeButtonTopTrailingSpace),

            scrollContentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollViewHeightConstraint
        ])

        scrollViewHeightConstraint.priority = .defaultLow
        contentView.bringSubviewToFront(closeButton)
    }

    private func setupChildViewController() {
        addChild(childViewController)
        scrollContentView.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)

        guard let childSuperView = childViewController.view.superview else { return }

        NSLayoutConstraint.activate([
            childViewController.view.bottomAnchor.constraint(equalTo: childSuperView.bottomAnchor),
            childViewController.view.topAnchor.constraint(equalTo: childSuperView.topAnchor),
            childViewController.view.leftAnchor.constraint(equalTo: childSuperView.leftAnchor),
            childViewController.view.rightAnchor.constraint(equalTo: childSuperView.rightAnchor)
        ])

        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
    }

    @objc
    private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            viewTranslation = recognizer.translation(in: view)

            // do not allow swiping up
            guard viewTranslation.y > 0 else { return }

            UIView.animate(withDuration: UX.animationDuration,
                           delay: 0,
                           usingSpringWithDamping: UX.springWithDamping,
                           initialSpringVelocity: UX.initialSpringVelocity,
                           options: .curveEaseOut,
                           animations: {
                self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
            })
        case .ended:
            if viewTranslation.y < 200 {
                UIView.animate(withDuration: UX.animationDuration,
                               delay: 0,
                               usingSpringWithDamping: UX.springWithDamping,
                               initialSpringVelocity: UX.initialSpringVelocity,
                               options: .curveEaseOut,
                               animations: {
                    self.sheetView.transform = .identity
                })
            } else {
                dismissSheetViewController()
            }
        default:
            break
        }
    }

    @objc
    private func closeTapped() {
        dismissSheetViewController()
    }

    // MARK: - BottomSheetDismissProtocol

    public func dismissSheetViewController(completion: (() -> Void)? = nil) {
        childViewController.willDismiss()
        contentViewBottomConstraint.constant = childViewController.view.frame.height
        UIView.animate(
            withDuration: viewModel.animationTransitionDuration,
            animations: {
                self.view.layoutIfNeeded()
                self.view.backgroundColor = .clear
            }, completion: { _ in
                self.dismiss(animated: false, completion: completion)
            }
        )
    }
}
