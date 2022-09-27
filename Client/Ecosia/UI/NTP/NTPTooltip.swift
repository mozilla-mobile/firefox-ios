/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol NTPTooltipDelegate: AnyObject {
    func ntpTooltipTapped(_ tooltip: NTPTooltip?)
    func reloadTooltip()
}

final class NTPTooltip: UICollectionReusableView, NotificationThemeable {
    static let key = String(describing: NTPTooltip.self)
    static let margin = CGFloat(16)
    static let containerMargin = CGFloat(12)
    private weak var textLabel: UILabel!
    private weak var tail: UIImageView!
    private weak var closeImage: UIImageView!
    private weak var background: UIView!
    weak var delegate: NTPTooltipDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        self.background = background

        background.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        background.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        background.topAnchor.constraint(equalTo: topAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.margin).isActive = true

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fill

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.numberOfLines = 0
        stack.addArrangedSubview(label)
        self.textLabel = label

        let closeImage = UIImageView(image: .init(named: "tab_close"))
        closeImage.heightAnchor.constraint(equalToConstant: 24).isActive = true
        closeImage.widthAnchor.constraint(equalToConstant: 24).isActive = true
        stack.addArrangedSubview(closeImage)
        self.closeImage = closeImage

        addSubview(stack)
        stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.margin).isActive = true
        let trailing = stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.margin)
        trailing.priority = .init(rawValue: 999)
        trailing.isActive = true
        stack.topAnchor.constraint(equalTo: topAnchor, constant: Self.containerMargin).isActive = true
        stack.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -Self.containerMargin).isActive = true

        let tail = UIImageView(image: .init(named: "tail"))
        tail.translatesAutoresizingMaskIntoConstraints = false
        tail.contentMode = .scaleAspectFit
        tail.setContentHuggingPriority(.required, for: .horizontal)
        tail.setContentHuggingPriority(.required, for: .vertical)
        addSubview(tail)
        self.tail = tail

        tail.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        tail.topAnchor.constraint(equalTo: background.bottomAnchor, constant: -0.5).isActive = true
        tail.widthAnchor.constraint(equalToConstant: 28).isActive = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)

        applyTheme()
        addShadows()

        NotificationCenter.default.addObserver(self, selector: #selector(applyTheme), name: .DisplayThemeChanged, object: nil)
    }

    func setText(_ text: String) {
        textLabel.text = text
        accessibilityLabel = text
        accessibilityTraits = .button
        isAccessibilityElement = true
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
        tail.tintColor = UIColor.theme.ecosia.quarternaryBackground
        background.backgroundColor = UIColor.theme.ecosia.quarternaryBackground
        textLabel.textColor = .theme.ecosia.primaryTextInverted
        closeImage.tintColor = .theme.ecosia.primaryTextInverted
    }

    @objc func tapped() {
        delegate?.ntpTooltipTapped(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
