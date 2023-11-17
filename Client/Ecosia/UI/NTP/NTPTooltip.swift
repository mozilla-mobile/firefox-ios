/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Common

final class NTPTooltip: UICollectionReusableView, Themeable {
    enum TailPosition {
        case leading, center
    }
    struct UX {
        static let margin: CGFloat = 16
        static let containerMargin: CGFloat = 12
    }
    
    static let key = String(describing: NTPTooltip.self)
    private weak var textLabel: UILabel!
    private weak var tail: UIImageView!
    private weak var closeButton: UIButton!
    private weak var background: UIView!
    weak var delegate: NTPTooltipDelegate?
    
    private var tailLeadingConstraint: NSLayoutConstraint!
    private var tailCenterConstraint: NSLayoutConstraint!
    var tailPosition: TailPosition = .center {
        didSet {
            updateTailPosition()
        }
    }
    
    private let linkButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        button.isHidden = true
        return button
    }()
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        // Empty override required to prevent UICollectionViewRecursion on NTPLayout.adjustImpactTooltipFrame
        return layoutAttributes
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        self.background = background

        background.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        background.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        background.topAnchor.constraint(equalTo: topAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.margin, priority: .init(999)).isActive = true

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fill
        
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.numberOfLines = 0
        verticalStack.addArrangedSubview(label)
        self.textLabel = label
        
        linkButton.addTarget(self, action: #selector(linkButtonTapped), for: .touchDown)
        verticalStack.addArrangedSubview(linkButton)
        
        stack.addArrangedSubview(verticalStack)

        let closeButton = UIButton()
        closeButton.setImage(.templateImageNamed("crossLarge"), for: .normal)
        closeButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchDown)
        stack.addArrangedSubview(closeButton)
        self.closeButton = closeButton

        addSubview(stack)
        stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.margin).isActive = true
        let trailing = stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.margin)
        trailing.priority = .init(rawValue: 999)
        trailing.isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor, constant: UX.containerMargin).isActive = true
        stack.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -UX.containerMargin).isActive = true

        let tail = UIImageView(image: .init(named: "tail"))
        tail.translatesAutoresizingMaskIntoConstraints = false
        tail.contentMode = .scaleAspectFit
        tail.setContentHuggingPriority(.required, for: .horizontal)
        tail.setContentHuggingPriority(.required, for: .vertical)
        addSubview(tail)
        self.tail = tail

        tailCenterConstraint = tail.centerXAnchor.constraint(equalTo: centerXAnchor)
        tailLeadingConstraint = tail.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        updateTailPosition()
        
        tail.topAnchor.constraint(equalTo: background.bottomAnchor, constant: -0.5).isActive = true
        tail.widthAnchor.constraint(equalToConstant: 28).isActive = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)

        applyTheme()
        addShadows()

        listenForThemeChange(self)
    }

    func setText(_ text: String) {
        textLabel.text = text
        accessibilityLabel = text
        accessibilityTraits = .button
        isAccessibilityElement = true
    }
    
    func removeLink() {
        linkButton.setTitle(nil, for: .normal)
        linkButton.isHidden = true
    }
    
    func setLinkTitle(_ text: String) {
        let titleString = NSMutableAttributedString(string: text)
        titleString.addAttributes([
            .font: UIFont.preferredFont(forTextStyle: .callout).bold(),
            .foregroundColor: UIColor.legacyTheme.ecosia.primaryTextInverted
        ], range: NSRange(location: 0, length: text.count))
        linkButton.setAttributedTitle(titleString, for: .normal)
        linkButton.isHidden = false
    }

    private func addShadows() {
        [background, tail].forEach {
            $0?.layer.cornerRadius = 8
            $0?.layer.shadowColor = UIColor(red: 0.059, green: 0.059, blue: 0.059, alpha: 0.18).cgColor
            $0?.layer.shadowOpacity = 1
            $0?.layer.shadowRadius = 2
            $0?.layer.shadowOffset = CGSize(width: 0, height: 1)
        }
    }

    @objc func applyTheme() {
        tail.tintColor = UIColor.legacyTheme.ecosia.quarternaryBackground
        background.backgroundColor = UIColor.legacyTheme.ecosia.quarternaryBackground
        textLabel.textColor = .legacyTheme.ecosia.primaryTextInverted
        closeButton.tintColor = .legacyTheme.ecosia.primaryTextInverted
    }

    @objc func tapped() {
        delegate?.ntpTooltipTapped(self)
    }
    
    @objc private func closeTapped() {
        delegate?.ntpTooltipCloseTapped(self)
    }
    
    @objc private func linkButtonTapped() {
        delegate?.ntpTooltipLinkTapped(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    private func updateTailPosition() {
        switch tailPosition {
        case .center:
            tailLeadingConstraint.isActive = false
            tailCenterConstraint.isActive = true
        case .leading:
            tailCenterConstraint.isActive = false
            tailLeadingConstraint.isActive = true
        }
    }
}
