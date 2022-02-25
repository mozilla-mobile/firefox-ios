// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

class ContextualHintViewController: UIViewController, OnViewDismissable {

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
        button.setImage(UIImage(named: "find_close")?.withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.tintColor = .white
        button.addTarget(self,
                         action: #selector(self?.dismissAnimated),
                         for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0,
                                                left: 7.5,
                                                bottom: 15,
                                                right: 7.5)
    }

    private lazy var descriptionLabel: UILabel = .build { [weak self] label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .body,
            maxSize: 28)
        label.textAlignment = .left
        label.textColor = .white
        label.numberOfLines = 0
    }

    private lazy var actionButton: UIButton = .build { [weak self] button in
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self,
                         action: #selector(self?.performAction),
                         for: .touchUpInside)
    }

    private lazy var stackView: UIStackView = .build { [weak self] stack in
        stack.backgroundColor = .clear
        stack.distribution = .fillProportionally
        stack.alignment = .leading
        stack.axis = .vertical
    }

    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        gradient.colors = [
            UIColor.Photon.Violet40.cgColor,
            UIColor.Photon.Violet70.cgColor
        ]
        gradient.startPoint = CGPoint(x: 1, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.locations = [0, 0.63]
        return gradient
    }()

    // MARK: - Properties
    private var viewModel: ContextualHintViewModel
    private var onViewSummoned: (() -> Void)? = nil
    var onViewDismissed: (() -> Void)? = nil
    private var onActionTapped: (() -> Void)? = nil
    private var topContainerConstraint: NSLayoutConstraint?
    private var bottomContainerConstraint: NSLayoutConstraint?

    var isPresenting: Bool = false

    private var popupContentHeight: CGFloat {
        let spacingWidth = UX.labelLeading + UX.closeButtonSize.width + UX.closeButtonTrailing + UX.labelTrailing
        let labelHeight = descriptionLabel.heightForLabel(
            descriptionLabel,
            width: containerView.frame.width - spacingWidth,
            text: viewModel.descriptionText(arrowDirection: viewModel.arrowDirection))

        switch viewModel.isActionType() {
        case true:
            guard let titleLabel = actionButton.titleLabel else { fallthrough }
            let buttonHeight = titleLabel.heightForLabel(
                titleLabel,
                width: containerView.frame.width - spacingWidth,
                text: viewModel.buttonActionText())
            return buttonHeight + labelHeight + UX.labelTop + UX.labelBottom

        case false:
            return labelHeight + UX.labelTop + UX.labelBottom
        }
    }

    // MARK: - Initializers
    init(with viewModel: ContextualHintViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        isPresenting = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewSummoned?()
        onViewSummoned = nil
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Portrait orientation: lock enable
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait,
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
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
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

        containerView.addSubview(closeButton)
        containerView.addSubview(stackView)
        view.addSubview(containerView)

        setupConstraints()
        toggleArrowBasedConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                  constant: -UX.closeButtonTrailing),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                               constant: UX.labelLeading),
            stackView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                constant: -UX.labelTrailing),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        topContainerConstraint = containerView.topAnchor.constraint(equalTo: view.topAnchor)
        topContainerConstraint?.isActive = true
        bottomContainerConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomContainerConstraint?.isActive = true
        
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
        descriptionLabel.text = viewModel.descriptionText(arrowDirection: viewModel.arrowDirection)

        if viewModel.isActionType() {

            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                     maxSize: 28),
                .foregroundColor: UIColor.white,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]

            let attributeString = NSMutableAttributedString(
                string: viewModel.buttonActionText(),
                attributes: textAttributes
            )

            actionButton.setAttributedTitle(attributeString, for: .normal)
        }
    }

    // MARK: - Button Actions
    @objc private func dismissAnimated() {
        viewModel.sendTelemetryEvent(for: .closeButton)
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func performAction() {
        self.viewModel.sendTelemetryEvent(for: .performAction)
        self.dismiss(animated: true) {
            self.onActionTapped?()
            self.onActionTapped = nil
        }
    }

    // MARK: - Interface
    public func shouldPresentHint() -> Bool {
        return viewModel.shouldPresentContextualHint()
    }

    public func configure(
        anchor: UIView,
        withArrowDirection arrowDirection: UIPopoverArrowDirection,
        andDelegate delegate: UIPopoverPresentationControllerDelegate,
        presentedUsing presentation: (() -> Void)? = nil,
        withActionBeforeAppearing preAction: (() -> Void)? = nil,
        actionOnDismiss postAction: (() -> Void)? = nil,
        andActionForButton buttonAction: (() -> Void)? = nil
    ) {
        stopTimer()
        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.sourceView = anchor
        self.popoverPresentationController?.permittedArrowDirections = arrowDirection
        self.popoverPresentationController?.delegate = delegate
        self.onViewSummoned = preAction
        self.onViewDismissed = postAction
        self.onActionTapped = buttonAction
        viewModel.presentFromTimer = presentation
        viewModel.arrowDirection = arrowDirection

        setupContent()
        toggleArrowBasedConstraints()
        if viewModel.shouldPresentContextualHint() { viewModel.startTimer() }
    }

    public func stopTimer() {
        viewModel.stopTimer()
    }
}
