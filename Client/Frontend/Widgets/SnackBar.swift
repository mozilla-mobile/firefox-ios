// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class SnackBar: UIView {
    let snackbarClassIdentifier: String

    private struct UX {
        static let borderWidth: CGFloat = 0.5
        static let fontSize: CGFloat = 17
    }

    private var scrollViewHeightConstraint = NSLayoutConstraint()
    private var buttonsViewConstraints = [NSLayoutConstraint]()

    private lazy var scrollView: UIScrollView = .build()
    private lazy var buttonsView: UIStackView = .build { $0.distribution = .fillEqually }
    private lazy var backgroundView: UIVisualEffectView = .build { $0.effect = UIBlurEffect(style: .extraLight) }
    private lazy var separator: UIView = .build { $0.backgroundColor = UIColor.legacyTheme.snackbar.border }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        // These are required to make sure that the image is _never_ smaller or larger than its actual size
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var textLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: UX.fontSize)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textColor = UIColor.Photon.Grey90 // If making themeable, change to UIColor.legacyTheme.tableView.rowText
        label.backgroundColor = UIColor.clear
    }

    private lazy var titleView: UIStackView = .build { stack in
        stack.spacing = UIConstants.DefaultPadding
        stack.distribution = .fill
        stack.axis = .horizontal
        stack.alignment = .center
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        stack.isLayoutMarginsRelativeArrangement = true
    }

    init(text: String, img: UIImage?, snackbarClassIdentifier: String? = nil) {
        self.snackbarClassIdentifier = snackbarClassIdentifier ?? text
        super.init(frame: .zero)
        imageView.image = img ?? UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysOriginal)
        textLabel.text = text
        setupLayout()
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
        clipsToBounds = true // overridden by masksToBounds = false
        layer.borderWidth = UX.borderWidth
        layer.borderColor = UIColor.legacyTheme.snackbar.border.cgColor
        layer.cornerRadius = 8
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }

    private func setupLayout() {
        addSubview(backgroundView)
        addSubview(scrollView)

        scrollView.addSubview(titleView)

        titleView.addArrangedSubview(imageView)
        titleView.addArrangedSubview(textLabel)

        addSubview(separator)
        addSubview(buttonsView)

        let titleViewHeightConstraint = titleView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        titleViewHeightConstraint.priority = .defaultLow
        let titleViewCenterXConstraint = titleView.centerXAnchor.constraint(equalTo: centerXAnchor)
        titleViewCenterXConstraint.priority = UILayoutPriority(500)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: UX.borderWidth),
            separator.topAnchor.constraint(equalTo: buttonsView.topAnchor, constant: -1),

            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonsView.topAnchor),

            titleView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            titleView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            titleView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -(UIConstants.DefaultPadding * 4)),
            titleViewHeightConstraint,
            titleViewCenterXConstraint
        ])
    }

    /**
     * Called to check if the snackbar should be removed or not. By default, Snackbars persist forever.
     * Override this class or use a class like CountdownSnackbar if you want things expire
     * - returns: true if the snackbar should be kept alive
     */
    func shouldPersist(_ tab: Tab) -> Bool {
        return true
    }

    private func setupButtonViewLayout(constant: CGFloat = 0) {
        NSLayoutConstraint.deactivate(buttonsViewConstraints)
        buttonsViewConstraints = [
            buttonsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -constant),
            buttonsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonsView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]
        buttonsViewConstraints.append(!buttonsView.subviews.isEmpty ?
                                      buttonsView.heightAnchor.constraint(equalToConstant: UIConstants.SnackbarButtonHeight) :
                                        buttonsView.heightAnchor.constraint(equalToConstant: 0))
        NSLayoutConstraint.activate(buttonsViewConstraints)
    }

    private func remakeScrollViewHeightConstraint() {
        scrollViewHeightConstraint.isActive = false
        scrollViewHeightConstraint = scrollView
            .heightAnchor
            .constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.height / 2)
        scrollViewHeightConstraint.isActive = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        remakeScrollViewHeightConstraint()
    }

    override func updateConstraints() {
        super.updateConstraints()
        setupButtonViewLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass == .compact &&
            UIDevice.current.userInterfaceIdiom == .pad {
            setupButtonViewLayout(constant: UIConstants.ToolbarHeight)
        } else { setupButtonViewLayout() }
    }

    var showing: Bool {
        return alpha != 0 && self.superview != nil
    }

    func show() {
        alpha = 1
    }

    func addButton(_ snackButton: SnackButton) {
        snackButton.bar = self
        buttonsView.addArrangedSubview(snackButton)

        // Only show the separator on the left of the button if it is not the first view
        if buttonsView.arrangedSubviews.count != 1 {
            snackButton.drawSeparator()
        }
    }
}
