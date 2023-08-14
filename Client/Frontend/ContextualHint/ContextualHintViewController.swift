// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit
import Shared

class ContextualHintViewController: UIViewController, OnViewDismissable, Themeable {
    struct UX {
        static let closeButtonSize = CGSize(width: 35, height: 35)
        static let closeButtonTrailing: CGFloat = 5
        static let closeButtonTop: CGFloat = 5

        static let labelLeading: CGFloat = 16
        static let labelTop: CGFloat = 10
        static let labelBottom: CGFloat = 23
        static let labelTrailing: CGFloat = 3
    }

    // MARK: - UI Elements
    private lazy var containerView: UIView = .build { [weak self] view in
        view.backgroundColor = .clear
    }

    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: StandardImageIdentifiers.Medium.cross)?.withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.addTarget(self,
                         action: #selector(self?.dismissAnimated),
                         for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0,
                                                left: 7.5,
                                                bottom: 15,
                                                right: 7.5)
        button.accessibilityLabel = String.ContextualHints.ContextualHintsCloseAccessibility
    }

    private lazy var descriptionLabel: UILabel = .build { [weak self] label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 17)
        label.textAlignment = .left
        label.numberOfLines = 0
    }

    private lazy var actionButton: ResizableButton = .build { [weak self] button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self,
                         action: #selector(self?.performAction),
                         for: .touchUpInside)
        button.buttonEdgeSpacing = 0
    }

    private lazy var stackView: UIStackView = .build { [weak self] stack in
        stack.backgroundColor = .clear
        stack.distribution = .fillProportionally
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = 7.0
    }

    private lazy var scrollView: FadeScrollView = .build { view in
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
    }

    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        gradient.startPoint = CGPoint(x: 1, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.locations = [0, 0.63]
        return gradient
    }()

    // MARK: - Properties
    private var viewModel: ContextualHintViewModel
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    private var onViewSummoned: (() -> Void)?
    var onViewDismissed: (() -> Void)?
    private var onActionTapped: (() -> Void)?
    private var topContainerConstraint: NSLayoutConstraint?
    private var bottomContainerConstraint: NSLayoutConstraint?

    var isPresenting = false

    private var popupContentHeight: CGFloat {
        let spacingWidth = UX.labelLeading + UX.closeButtonSize.width + UX.closeButtonTrailing + UX.labelTrailing

        let labelHeight = descriptionLabel.heightForLabel(
            descriptionLabel,
            width: containerView.frame.width - spacingWidth,
            text: viewModel.getCopyFor(.description)
        )

        switch viewModel.isActionType() {
        case true:
            guard let titleLabel = actionButton.titleLabel else { fallthrough }

            let buttonHeight = titleLabel.heightForLabel(
                titleLabel,
                width: containerView.frame.width - spacingWidth,
                text: viewModel.getCopyFor(.action)
            )

            return buttonHeight + labelHeight + UX.labelTop + UX.labelBottom

        case false:
            return labelHeight + UX.labelTop + UX.labelBottom
        }
    }

    // MARK: - Initializers
    init(with viewModel: ContextualHintViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        listenForThemeChange(view)
        applyTheme()
        isPresenting = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewSummoned?()
        onViewSummoned = nil
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Portrait orientation: lock enable
        OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.portrait,
                                               andRotateTo: UIInterfaceOrientation.portrait)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = CGSize(width: 350, height: popupContentHeight)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.markContextualHintPresented()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Portrait orientation: lock disable
        OrientationLockUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.sendTelemetryEvent(for: .tapToDismiss)
        isPresenting = false
        onViewDismissed?()
        onViewDismissed = nil
    }

    private func commonInit() {
        setupView()
    }

    private func setupView() {
        gradient.frame = view.bounds
        view.layer.addSublayer(gradient)

        stackView.addArrangedSubview(descriptionLabel)
        if viewModel.isActionType() { stackView.addArrangedSubview(actionButton) }

        containerView.addSubview(stackView)
        scrollView.addSubviews(containerView)
        view.addSubview(scrollView)
        view.addSubview(closeButton)

        setupConstraints()
        toggleArrowBasedConstraints()
    }

    private func setupConstraints() {
        topContainerConstraint = scrollView.topAnchor.constraint(equalTo: view.topAnchor)
        bottomContainerConstraint = scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainerConstraint!,
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainerConstraint!,

            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: containerView.widthAnchor),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: scrollView.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.closeButtonTrailing),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                               constant: UX.labelLeading),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                constant: -UX.closeButtonSize.width - UX.labelTrailing),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        descriptionLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .vertical)
    }

    private func toggleArrowBasedConstraints() {
        let topPadding = viewModel.arrowDirection == .up ? UX.labelBottom : UX.labelTop
        let bottomPadding = viewModel.arrowDirection == .up ? UX.labelTop : UX.labelBottom

        topContainerConstraint?.constant = topPadding
        bottomContainerConstraint?.constant = -bottomPadding

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func setupContent() {
        descriptionLabel.text = viewModel.getCopyFor(.description)
    }

    // MARK: - Button Actions
    @objc
    private func dismissAnimated() {
        viewModel.sendTelemetryEvent(for: .closeButton)
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func performAction() {
        self.viewModel.sendTelemetryEvent(for: .performAction)
        self.dismiss(animated: true) {
            self.onActionTapped?()
            self.onActionTapped = nil
        }
    }

    // MARK: - Interface
    func shouldPresentHint() -> Bool {
        return viewModel.shouldPresentContextualHint()
    }

    func configure(
        anchor: UIView,
        withArrowDirection arrowDirection: UIPopoverArrowDirection,
        andDelegate delegate: UIPopoverPresentationControllerDelegate,
        presentedUsing presentation: (() -> Void)?,
        sourceRect: CGRect = CGRect.null,
        withActionBeforeAppearing preAction: (() -> Void)? = nil,
        actionOnDismiss postAction: (() -> Void)? = nil,
        andActionForButton buttonAction: (() -> Void)? = nil,
        andShouldStartTimerRightAway shouldStartTimer: Bool = true,
        overlayState: OverlayStateProtocol? = nil
    ) {
        stopTimer()
        modalPresentationStyle = .popover
        popoverPresentationController?.sourceRect = sourceRect
        popoverPresentationController?.sourceView = anchor
        popoverPresentationController?.permittedArrowDirections = arrowDirection
        popoverPresentationController?.delegate = delegate
        onViewSummoned = preAction
        onViewDismissed = postAction
        onActionTapped = buttonAction
        viewModel.presentFromTimer = presentation
        viewModel.arrowDirection = arrowDirection
        viewModel.overlayState = overlayState

        setupContent()
        toggleArrowBasedConstraints()
        if viewModel.shouldPresentContextualHint() && shouldStartTimer {
            viewModel.startTimer()
        }

        viewModel.markContextualHintConfiguration(configured: true)
    }

    func unconfigure() {
        viewModel.markContextualHintConfiguration(configured: false)
    }

    func stopTimer() {
        viewModel.stopTimer()
    }

    func startTimer() {
        viewModel.startTimer()
    }

    func applyTheme() {
        let theme = themeManager.currentTheme
        closeButton.tintColor = theme.colors.textOnDark
        descriptionLabel.textColor = theme.colors.textOnDark
        gradient.colors = theme.colors.layerGradient.cgColors

        if viewModel.isActionType() {
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 17),
                .foregroundColor: theme.colors.textOnDark,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]

            let attributeString = NSMutableAttributedString(
                string: viewModel.getCopyFor(.action),
                attributes: textAttributes
            )

            actionButton.setAttributedTitle(attributeString, for: .normal)
        }
    }
}
