// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class BeforeOrAfterView: UIView, ThemeApplicable {
    enum ContentType {
        case before
        case after
    }

    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = .ecosia.borderRadius._l
        return view
    }()
    private lazy var labelStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = .ecosia.space._2s
        return stack
    }()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = isBefore ? .localized(.before) : .localized(.after)
        label.font = .preferredFont(forTextStyle: .subheadline).semibold()
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    private lazy var treeImage: UIImageView = {
        let view = UIImageView()
        view.isHidden = isBefore
        view.image = .init(named: "smallTree")?.withRenderingMode(.alwaysTemplate)
        return view
    }()
    private lazy var ellipse: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.image = .init(named: isBefore ? "ellipseBefore" : "ellipseAfter")
        image.setContentHuggingPriority(.required, for: .horizontal)
        return image
    }()
    private lazy var dot: Dot = {
        return Dot(effect: UIBlurEffect(style: .light))
    }()

    var isBefore: Bool { type == .before }
    private let type: ContentType
    init(type: ContentType) {
        self.type = type
        super.init(frame: .zero)
        setup()
        setupConstraints()
    }

    required init?(coder: NSCoder) { nil }

    private func setup() {
        addSubview(container)
        labelStack.addArrangedSubview(treeImage)
        labelStack.addArrangedSubview(label)
        container.addSubview(labelStack)
        addSubview(ellipse)
        addSubview(dot)
    }

    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
            // View's height equals dot's since that's desired our Y anchor
            topAnchor.constraint(equalTo: dot.topAnchor),
            bottomAnchor.constraint(equalTo: dot.bottomAnchor),

            labelStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: .ecosia.space._s),
            labelStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -.ecosia.space._s),
            labelStack.topAnchor.constraint(equalTo: container.topAnchor, constant: .ecosia.space._s),
            labelStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -.ecosia.space._s),
        ]

        if isBefore {
            constraints.append(contentsOf: [
                leadingAnchor.constraint(equalTo: container.leadingAnchor),
                trailingAnchor.constraint(equalTo: dot.trailingAnchor),
                ellipse.leadingAnchor.constraint(equalTo: container.trailingAnchor),
                ellipse.topAnchor.constraint(equalTo: container.centerYAnchor),
                dot.topAnchor.constraint(equalTo: ellipse.bottomAnchor),
                dot.centerXAnchor.constraint(equalTo: ellipse.trailingAnchor),
            ])
        } else {
            constraints.append(contentsOf: [
                leadingAnchor.constraint(equalTo: dot.leadingAnchor),
                trailingAnchor.constraint(equalTo: container.trailingAnchor),
                ellipse.trailingAnchor.constraint(equalTo: container.leadingAnchor),
                ellipse.bottomAnchor.constraint(equalTo: container.centerYAnchor),
                dot.bottomAnchor.constraint(equalTo: ellipse.topAnchor),
                dot.centerXAnchor.constraint(equalTo: ellipse.leadingAnchor),
            ])
        }
        NSLayoutConstraint.activate(constraints)
    }

    func applyTheme(theme: Theme) {
        container.backgroundColor = theme.colors.ecosia.backgroundSecondary
        label.textColor = theme.colors.ecosia.textPrimary
        treeImage.tintColor = theme.colors.ecosia.brandPrimary
        dot.applyTheme(theme: theme)
    }
}

private final class Dot: UIVisualEffectView, ThemeApplicable {
    struct UX {
        static let size: CGFloat = 20
        static let centerSize: CGFloat = 8
    }

    private lazy var centerDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = UX.centerSize/2
        return view
    }()

    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        setup()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = UX.size/2
        layer.masksToBounds = true
        contentView.addSubview(centerDot)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: UX.size),
            widthAnchor.constraint(equalToConstant: UX.size),
            centerDot.heightAnchor.constraint(equalToConstant: UX.centerSize),
            centerDot.widthAnchor.constraint(equalToConstant: UX.centerSize),
            centerDot.centerYAnchor.constraint(equalTo: centerYAnchor),
            centerDot.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    func applyTheme(theme: Theme) {
        centerDot.backgroundColor = theme.colors.ecosia.backgroundPrimary
    }
}
