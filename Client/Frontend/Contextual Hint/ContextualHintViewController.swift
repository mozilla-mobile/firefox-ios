// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import Shared

class ContextualHintViewController: UIViewController, OnViewDismissable {
    
    // MARK: - Public constants
    
    // Note: make sure to use convenience init to set the type of hint while initializing 
    let viewModel = ContextualHintViewModel()
    
    // MARK: - Properties
    
    var onViewDismissed: (() -> Void)? = nil
    
    // Orientation independent screen size
    private let screenSize = DeviceInfo.screenSizeOrientationIndependent()

    // UI
    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: "find_close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(self?.dismissAnimated), for: .touchUpInside)
    }

    private lazy var descriptionText: UILabel = .build { [weak self] label in
        guard let self = self else { return }
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, maxSize: 28)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.textColor = .white
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
        descriptionText.heightForLabel(descriptionText, width: 185, text: viewModel.hintType?.descriptionForHint())
    }
    
    // Used to set the part of text in center
    private var containerView = UIView()

    // MARK: - Inits
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(hintType: ContextualHintViewType) {
        self.init()
        viewModel.hintType = hintType
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Portrait orientation: lock enable
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Portrait orientation: lock disable
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onViewDismissed?()
        onViewDismissed = nil
    }
    
    func initialViewSetup() {
        gradient.frame = view.bounds
        view.layer.addSublayer(gradient)
        view.addSubview(closeButton)
        view.addSubview(descriptionText)
        
        // Constraints
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupView() {
        descriptionText.text = viewModel.hintType?.descriptionForHint()
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            descriptionText.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            descriptionText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CGFloat(18)),
            descriptionText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: CGFloat(-30)),
            descriptionText.heightAnchor.constraint(equalToConstant: heightForDescriptionLabel),
        ])

    }
    
    // Button Actions
    @objc private func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
    }
}
