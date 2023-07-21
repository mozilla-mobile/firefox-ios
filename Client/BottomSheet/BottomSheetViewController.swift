// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

protocol BottomSheetChild {
    /// Tells the child that the bottom sheet will get dismissed
    func willDismiss()
}

class BottomSheetViewController: UIViewController, Themeable {
    private struct UX {
        static let minVisibleTopSpace: CGFloat = 40
        static let closeButtonWidthHeight: CGFloat = 30
        static let closeButtonTopTrailingSpace: CGFloat = 16
    }

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private let viewModel: BottomSheetViewModel
    private var useDimmedBackground: Bool

    typealias BottomSheetChildViewController = UIViewController & BottomSheetChild
    private let childViewController: BottomSheetChildViewController

    // Views
    private lazy var scrollView: FadeScrollView = .build { scrollView in
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
    }
    private lazy var topTapView: UIView = .build { view in
        view.backgroundColor = .clear
    }
    private lazy var sheetView: UIView = .build { _ in }
    private lazy var contentView: UIView = .build { _ in }
    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: ImageIdentifiers.bottomSheetClose), for: .normal)
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
        button.accessibilityLabel = .CloseButtonTitle
    }
    private lazy var scrollContentView: UIView = .build { _ in }
    private var contentViewBottomConstraint: NSLayoutConstraint!

    private var viewTranslation = CGPoint(x: 0, y: 0)

    // MARK: Init
    public init(viewModel: BottomSheetViewModel,
                childViewController: BottomSheetChildViewController,
                usingDimmedBackground: Bool = false,
                notificationCenter: NotificationProtocol = NotificationCenter.default,
                themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.childViewController = childViewController
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.useDimmedBackground = usingDimmedBackground

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

        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        contentView.addGestureRecognizer(gesture)
        gesture.delegate = self

        listenForThemeChange(view)
        setupView()

        contentViewBottomConstraint.constant = childViewController.view.frame.height
        view.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
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

    public func dismissViewController() {
        childViewController.willDismiss()
        contentViewBottomConstraint.constant = childViewController.view.frame.height
        UIView.animate(
            withDuration: viewModel.animationTransitionDuration,
            animations: {
                self.view.layoutIfNeeded()
                self.view.backgroundColor = .clear
            }, completion: { _ in
                self.dismiss(animated: false, completion: nil)
            })
    }

    func applyTheme() {
        contentView.backgroundColor = themeManager.currentTheme.colors.layer1
        sheetView.layer.shadowOpacity = viewModel.shadowOpacity
        if useDimmedBackground {
            topTapView.alpha = 0.4
            topTapView.backgroundColor = .black
        }
    }
}

private extension BottomSheetViewController {
    func setupView() {
        if viewModel.shouldDismissForTapOutside {
            topTapView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                   action: #selector(self.closeTapped)))
        }
        scrollView.addSubview(scrollContentView)
        sheetView.addSubview(contentView)
        contentView.addSubviews(closeButton, scrollView)
        view.addSubviews(topTapView, sheetView)

        contentViewBottomConstraint = sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            greaterThanOrEqualTo: scrollContentView.heightAnchor)

        NSLayoutConstraint.activate([
            topTapView.topAnchor.constraint(equalTo: view.topAnchor),
            topTapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topTapView.bottomAnchor.constraint(equalTo: sheetView.topAnchor, constant: viewModel.cornerRadius),
            topTapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

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
            closeButton.widthAnchor.constraint(equalToConstant: BottomSheetViewController.UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: BottomSheetViewController.UX.closeButtonWidthHeight),

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

    func setupChildViewController() {
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
    func panGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed:
            viewTranslation = recognizer.translation(in: view)

            // do not allow swiping up
            guard viewTranslation.y > 0 else { return }

            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut,
                           animations: {
                self.sheetView.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
            })
        case .ended:
            if viewTranslation.y < 200 {
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 1,
                               options: .curveEaseOut,
                               animations: {
                    self.sheetView.transform = .identity
                })
            } else {
                dismissViewController()
            }
        default:
            break
        }
    }

    @objc
    func closeTapped() {
        dismissViewController()
    }
}

extension BottomSheetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}
