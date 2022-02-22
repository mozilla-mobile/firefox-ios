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
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, maxSize: 28)
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.textColor = .white
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self,
                         action: #selector(self?.performAction),
                         for: .touchUpInside)
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
    
    var heightForDescriptionLabel: CGFloat {
        let spacingWidth = UX.labelLeading + UX.closeButtonSize.width + UX.closeButtonTrailing
        let height = descriptionLabel.heightForLabel(descriptionLabel,
                                                     width: containerView.frame.width - spacingWidth,
                                                     text: viewModel.hintType.descriptionForHint())
        return height + UX.labelTop + UX.labelBottom
    }

    // MARK: - Properties
    private var viewModel: ContextualHintViewModel
    internal var onViewSummoned: (() -> Void)? = nil
    internal var onViewDismissed: (() -> Void)? = nil
    var isPresenting: Bool = false
    var hasAlreadyBeenPresented: Bool {
        return viewModel.hasAlreadyBeenPresented
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
        preferredContentSize = CGSize(width: 350, height: heightForDescriptionLabel)
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
        setupContent()
    }
    
    private func setupView() {
        gradient.frame = view.bounds
        view.layer.addSublayer(gradient)
        containerView.addSubview(closeButton)
        containerView.addSubview(descriptionLabel)
        view.addSubview(containerView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.closeButtonTrailing),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize.height),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize.width),

            descriptionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.labelTop),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.labelLeading),
            descriptionLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -UX.labelTrailing),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.labelBottom),
            
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupContent() {
        descriptionLabel.text = viewModel.hintType.descriptionForHint()
    }
    
    // MARK: - Button Actions
    @objc private func dismissAnimated() {
        viewModel.sendTelemetryEvent(for: .closeButton)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func performAction() {
        viewModel.sendTelemetryEvent(for: .performAction)
    }
    
    // MARK: - Interface
    public func shouldPresentHint() -> Bool {
        return viewModel.shouldPresentContextualHint()
    }
    
    public func set(
        anchor: UIView,
        withArrowDirection arrowDirection: UIPopoverArrowDirection,
        andDelegate delegate: UIPopoverPresentationControllerDelegate,
        withActionBeforeAppearing preAction: (() -> Void)? = nil,
        andOnDismiss postAction: (() -> Void)? = nil
    ) {
        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.sourceView = anchor
        self.popoverPresentationController?.permittedArrowDirections = arrowDirection
        self.popoverPresentationController?.delegate = delegate
        self.onViewSummoned = preAction
        self.onViewDismissed = postAction
    }
}
