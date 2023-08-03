// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

public protocol BottomSheetChild: UIViewController {
    /// Tells the child that the bottom sheet will get dismissed
    func willDismiss()
}

public protocol BottomSheetDismissProtocol {
    func dismissSheetViewController(completion: (() -> Void)?)
}

/// A container that present from the bottom as a sheet
public class BottomSheetViewController: UIViewController,
                                        BottomSheetDismissProtocol,
                                        Themeable,
                                        UIGestureRecognizerDelegate {
    private struct UX {
        static let minVisibleTopSpace: CGFloat = 40
        static let closeButtonWidthHeight: CGFloat = 30
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

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }

    private lazy var sheetView: UIView = .build()
    private lazy var contentView: UIView = .build()
    private lazy var scrollContentView: UIView = .build()

    private var contentViewBottomConstraint: NSLayoutConstraint!
    private var contentViewHeightConstraint: NSLayoutConstraint!

    private var viewTranslation = CGPoint(x: 0, y: 0)
    private var currentContentHeight: CGFloat
    private var defaultHeight: CGFloat
    private var maximumContentHeight = UIScreen.main.bounds.height * 0.93

    // MARK: Init
    public init(viewModel: BottomSheetViewModel,
                childViewController: BottomSheetChild,
                usingDimmedBackground: Bool = false,
                notificationCenter: NotificationProtocol = NotificationCenter.default,
                themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.childViewController = childViewController
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.useDimmedBackground = usingDimmedBackground
        defaultHeight = viewModel.contentHeight
        currentContentHeight = viewModel.contentHeight
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View lifecyle
    override public func viewDidLoad() {
        super.viewDidLoad()
        sheetView.alpha = 1
        setupChildViewController()
        closeButton.accessibilityLabel = viewModel.closeButtonA11yLabel

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
        animateContentView()
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

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard !viewModel.isFixedHeight else { return }
        remakeHeights()
    }

    // MARK: - Theme

    public func applyTheme() {
        contentView.backgroundColor = themeManager.currentTheme.colors.layer1
        sheetView.layer.shadowOpacity = viewModel.shadowOpacity

        if useDimmedBackground {
            dimmedBackgroundView.alpha = 0.4
            dimmedBackgroundView.backgroundColor = .black
        }
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

        contentViewBottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        contentViewHeightConstraint = sheetView.heightAnchor.constraint(equalToConstant: defaultHeight)

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
                                           constant: UX.minVisibleTopSpace),
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentViewBottomConstraint,
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentViewHeightConstraint,
            contentView.topAnchor.constraint(equalTo: sheetView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: sheetView.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor,
                                             constant: UX.closeButtonTopTrailingSpace),
            closeButton.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -UX.closeButtonTopTrailingSpace),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),

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

    private func remakeHeights() {
        maximumContentHeight = UIScreen.main.bounds.height * 0.93
        defaultHeight = UIScreen.main.bounds.height * 0.5
        currentContentHeight = defaultHeight
        contentViewHeightConstraint.isActive = false
        contentViewHeightConstraint = sheetView.heightAnchor.constraint(equalToConstant: defaultHeight)
        contentViewHeightConstraint.isActive = true
    }

    private func setupChildViewController() {
        addChild(childViewController)
        scrollContentView.addSubview(childViewController.view)
        childViewController.didMove(toParent: self)

        guard let childSuperView = childViewController.view.superview else { return }
        if viewModel.isFixedHeight {
            childViewController.view.heightAnchor.constraint(equalToConstant: defaultHeight).isActive = true
        }
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
        viewTranslation = recognizer.translation(in: view)
        let isPanningDown = viewTranslation.y > 0

        let newHeight = currentContentHeight - viewTranslation.y
        switch recognizer.state {
        case .changed:
            guard viewModel.isPanningUpEnabled else {
                if viewTranslation.y > 0 {
                    contentViewHeightConstraint?.constant = newHeight
                }
                return
            }
            contentViewHeightConstraint?.constant = newHeight
            view.layoutIfNeeded()
        case .ended:
            // If the user pans to the bottom and
            // y goes beyond 200 we dismiss the bottom sheet.
            if viewTranslation.y > 200 {
                self.dismissSheetViewController()
            } else if newHeight < defaultHeight {
                // Animate to default height if the new height
                // is below the default threshold.
                animateContentHeight(defaultHeight)
            } else if newHeight < maximumContentHeight,
                                  isPanningDown,
                                  viewModel.isPanningUpEnabled {
                // If the new height is below the maximum threshold and
                // decreasing, reset it to the default height.
                animateContentHeight(defaultHeight)
            } else if newHeight > defaultHeight,
                                  !isPanningDown,
                                  viewModel.isPanningUpEnabled {
                // If the new height is below the maximum threshold and
                // increasing, set it to the maximum height at the top.
                animateContentHeight(maximumContentHeight)
            }
        default:
            break
        }
    }

    private func animateContentHeight(_ height: CGFloat) {
        UIView.animate(withDuration: UX.animationDuration,
                       delay: 0,
                       usingSpringWithDamping: UX.springWithDamping,
                       initialSpringVelocity: UX.initialSpringVelocity,
                       options: .curveEaseOut,
                       animations: {
            self.contentViewHeightConstraint?.constant = height
            self.view.layoutIfNeeded()
        })
        currentContentHeight = height
    }

    private func animateContentView() {
        contentViewBottomConstraint.constant = 0
        UIView.animate(withDuration: viewModel.animationTransitionDuration) {
            self.view.backgroundColor = self.viewModel.backgroundColor
            self.view.layoutIfNeeded()
        }
    }

    @objc
    private func closeTapped() {
        dismissSheetViewController()
    }

    // MARK: - BottomSheetDismissProtocol

    public func dismissSheetViewController(completion: (() -> Void)? = nil) {
        childViewController.willDismiss()
        contentViewBottomConstraint.constant = currentContentHeight
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
