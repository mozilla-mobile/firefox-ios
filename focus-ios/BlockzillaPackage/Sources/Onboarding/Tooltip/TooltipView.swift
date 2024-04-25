/* This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import DesignSystem

public protocol TooltipViewDelegate: AnyObject {
    func didTapTooltipDismissButton()
}

class TooltipView: UIView {
    weak var delegate: TooltipViewDelegate?

    private lazy var gradient: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = .cornerRadius
        gradientLayer.colors = [UIColor.purple70.cgColor, UIColor.purple30.cgColor]
        gradientLayer.startPoint = .startPoint
        gradientLayer.endPoint = .endPoint
        return gradientLayer
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [labelContainerStackView, dismissButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = .space
        stackView.layoutMargins = UIEdgeInsets(top: .margin, left: .margin, bottom: .margin, right: .margin)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private lazy var labelContainerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = .space
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .body16Bold
        label.textColor = .defaultFont
        label.numberOfLines = 0
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .body16
        label.textColor = .defaultFont
        label.numberOfLines = 0
        return label
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: CGFloat.dismissButtonSize),
            button.heightAnchor.constraint(equalToConstant: CGFloat.dismissButtonSize)
        ])
        button.setImage(.iconClose, for: .normal)
        button.addTarget(self, action: #selector(didTapTooltipDismissButton), for: .primaryActionTriggered)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupLayout()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        layer.insertSublayer(gradient, at: 0)
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        gradient.frame = bounds
    }

    private func setupLayout() {
        addSubview(mainStackView)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: self.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    func set(title: String = "", body: String, maxWidth: CGFloat? = nil) {
        titleLabel.text = title
        titleLabel.isHidden = title.isEmpty
        bodyLabel.text = body
        guard let maxWidth = maxWidth else { return }
        let maxSize = CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude)
        let idealSize = body.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], context: nil).size
        NSLayoutConstraint.activate([
            labelContainerStackView.widthAnchor.constraint(lessThanOrEqualToConstant: idealSize.width)
            ])
    }

    @objc
    func didTapTooltipDismissButton() {
        delegate?.didTapTooltipDismissButton()
    }
}

fileprivate extension CGFloat {
    static let space: CGFloat = 12
    static let margin: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    static let dismissButtonSize: CGFloat = 24
}

fileprivate extension CGPoint {
    static let startPoint = CGPoint(x: 0, y: 1)
    static let endPoint = CGPoint(x: 1, y: 1)
}
