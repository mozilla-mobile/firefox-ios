// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class BottomSheetViewController: UIViewController {

    private struct UX {
        static let defaultHeight: CGFloat = 200
        static let minVisibleTopSpace: CGFloat = 40
        static let closeButtonWidthHeight: CGFloat = 22
        static let topSpace: CGFloat = 16
    }

    private let viewModel: BottomSheetViewModel
    private let childViewController: UIViewController

    // Views
    private lazy var scrollView: FadeScrollView = .build { scrollView in
        scrollView.showsHorizontalScrollIndicator = false
    }
    private lazy var topTapView: UIView = .build { view in
        view.backgroundColor = .clear
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.closeTapped)))
    }
    private lazy var contentView: UIView = .build { view in
        view.backgroundColor = .white
    }
    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: ImageIdentifiers.contextualHintClose), for: .normal)
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }
    private lazy var scrollContentView: UIView = .build { _ in }
    private var contentViewBottomConstraint: NSLayoutConstraint!

    private var viewTranslation = CGPoint(x: 0, y: 0)

    // MARK: Init
    public init(viewModel: BottomSheetViewModel, childViewController: UIViewController) {
        self.viewModel = viewModel
        self.childViewController = childViewController

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
        contentView.alpha = 1
        setupChildViewController()

        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture))
        contentView.addGestureRecognizer(gesture)
        gesture.delegate = self

        setupView()

        contentViewBottomConstraint.constant = childViewController.view.frame.height
        view.layoutIfNeeded()
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
        scrollView.addRoundedCorners([.topLeft, .topRight], radius: viewModel.cornerRadius)

        contentView.layer.backgroundColor = UIColor.clear.cgColor
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: -5.0)
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowRadius = 20.0
    }

    public func dismissViewController() {
        contentViewBottomConstraint.constant = childViewController.view.frame.height
        UIView.animate(withDuration: viewModel.animationTransitionDuration, animations: {
            self.view.layoutIfNeeded()
            self.view.backgroundColor = .clear
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
}

private extension BottomSheetViewController {

    func setupView() {
        scrollView.addSubview(scrollContentView)
        contentView.addSubviews(closeButton, scrollView)
        view.addSubviews(topTapView, contentView)

        contentViewBottomConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            greaterThanOrEqualTo: scrollContentView.heightAnchor)

        NSLayoutConstraint.activate([
            topTapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topTapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            topTapView.bottomAnchor.constraint(equalTo: contentView.topAnchor),
            topTapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            contentView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: BottomSheetViewController.UX.minVisibleTopSpace),
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            contentViewBottomConstraint,
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor,
                                             constant: BottomSheetViewController.UX.topSpace),
            closeButton.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                                                  constant: -BottomSheetViewController.UX.topSpace),
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

    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
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
                self.contentView.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
            })
        case .ended:
            if viewTranslation.y < 200 {
                UIView.animate(withDuration: 0.5,
                               delay: 0,
                               usingSpringWithDamping: 0.7,
                               initialSpringVelocity: 1,
                               options: .curveEaseOut,
                               animations: {
                    self.contentView.transform = .identity
                })
            } else {
                dismissViewController()
            }
        default:
            break
        }
    }

    @objc func closeTapped() {
        dismissViewController()
    }
}

extension BottomSheetViewController: UIGestureRecognizerDelegate {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
        return false
    }
}
