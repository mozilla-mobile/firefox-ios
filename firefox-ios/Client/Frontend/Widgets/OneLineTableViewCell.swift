// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SiteImageView

enum OneLineTableViewCustomization {
    case regular
    case newFolder
    case desktopBookmarksLabel
}

struct OneLineTableViewCellViewModel {
    let title: String?
    var leftImageView: UIImage?
    var accessoryView: UIView?
    let accessoryType: UITableViewCell.AccessoryType
    let editingAccessoryView: UIImageView?
}

class OneLineTableViewCell: UITableViewCell,
                            ReusableCell,
                            ThemeApplicable,
                            BookmarksRefactorFeatureFlagProvider {
    // Tableview cell items

    struct UX {
        static let imageSize: CGFloat = 29
        static let borderViewMargin: CGFloat = 16
        static let verticalMargin: CGFloat = 8
        static let leftImageViewSize: CGFloat = 28
        static let separatorViewHeight: CGFloat = 0.7
        static let labelMargin: CGFloat = 4
        static let shortLeadingMargin: CGFloat = 5
        static let longLeadingMargin: CGFloat = 13
        static let cornerRadius: CGFloat = 5
        static let accessoryViewIconSize: CGFloat = 24
        static let accessoryViewSize: CGFloat = 44
        static let accessoryViewTrailingPadding: CGFloat = 6
    }

    var reorderControlImageView: UIImageView? {
        let reorderControl = self.subviews.first { view in
            view.classForCoder.description() == "UITableViewCellReorderControl"
        }
        return reorderControl?.subviews.first { view in
            view is UIImageView
        } as? UIImageView
    }

    var shouldLeftAlignTitle = false
    var customization: OneLineTableViewCustomization = .regular

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }

    lazy var leftImageView: FaviconImageView = .build { _ in }

    lazy var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.textAlignment = .natural
    }

    private lazy var bottomSeparatorView: UIView = .build { separatorLine in
        // separator hidden by default
        separatorLine.isHidden = true
    }

    var isAccessoryViewInteractive = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var defaultSeparatorInset: UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: UX.imageSize + 2 * UX.borderViewMargin,
                            bottom: 0,
                            right: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateReorderControl()

        // Position the accessory at the trailing edge of the cell, accounting for safe area and padding
        if let accessoryView {
            if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
                accessoryView.frame.origin.x = UX.accessoryViewTrailingPadding + safeAreaInsets.left
            } else {
                accessoryView.frame.origin.x = frame.width
                    - accessoryView.frame.width
                    - UX.accessoryViewTrailingPadding
                    - safeAreaInsets.right
            }
        }
    }

    private func updateReorderControl() {
        guard isBookmarkRefactorEnabled else { return }
        reorderControlImageView?.image = reorderControlImageView?.image?.withRenderingMode(.alwaysTemplate)
    }

    /// Holds a reference to the left image view's leading constraint so we can update
    /// its constant when modifying this cell's ``indentationLevel`` value.
    private var leftImageViewLeadingConstraint: NSLayoutConstraint?

    override var indentationLevel: Int {
        didSet {
            // Update the leading constraint based on this cell's indentationLevel value
            if isBookmarkRefactorEnabled {
                setBookmarksRefactorMargin()
            } else {
                // adding 1 since the default indentation is 0.
                leftImageViewLeadingConstraint?.constant = UX.borderViewMargin * CGFloat(1 + indentationLevel)
            }
        }
    }

    private func setBookmarksRefactorMargin() {
        // Sets the indentation so that at each level the folder icon is left
        // aligned with the label of the parent folder above it.
        if indentationLevel == 0 {
            leftImageViewLeadingConstraint?.constant = UX.borderViewMargin
        } else {
            let indentationLevelMargin: CGFloat = UX.borderViewMargin + UX.imageSize + UX.longLeadingMargin
            let indentSize = (UX.imageSize + UX.longLeadingMargin)
            let indentLevel = indentSize * CGFloat(indentationLevel-1)
            leftImageViewLeadingConstraint?.constant = indentationLevelMargin + indentLevel
        }
    }

    private func setupLayout() {
        separatorInset = defaultSeparatorInset
        selectionStyle = .default

        containerView.addSubviews(leftImageView,
                                  titleLabel,
                                  bottomSeparatorView)

        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        let containerViewTrailingAnchor = accessoryView?.leadingAnchor ?? contentView.trailingAnchor
        let midViewLeadingMargin: CGFloat = shouldLeftAlignTitle ? UX.shortLeadingMargin : UX.longLeadingMargin

        // Keep a reference to the left image's leading constraint to be able to update its value when
        // modifying this cell's indentationLevel value
        leftImageViewLeadingConstraint = leftImageView.leadingAnchor.constraint(
            equalTo: containerView.leadingAnchor,
            constant: UX.borderViewMargin
        )
        let imageViewDynamicSize = min(UIFontMetrics.default.scaledValue(for: UX.leftImageViewSize),
                                       2 * UX.leftImageViewSize)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                               constant: UX.verticalMargin),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: -UX.verticalMargin),
            containerView.trailingAnchor.constraint(equalTo: containerViewTrailingAnchor),

            leftImageViewLeadingConstraint,
            leftImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            leftImageView.widthAnchor.constraint(equalToConstant: imageViewDynamicSize),
            leftImageView.heightAnchor.constraint(equalToConstant: imageViewDynamicSize),
            leftImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor,
                                                    constant: -midViewLeadingMargin),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor,
                                            constant: UX.labelMargin),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                               constant: -UX.labelMargin),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                 constant: -UX.verticalMargin),

            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: UX.separatorViewHeight)
        ].compactMap { $0 })

        selectedBackgroundView = selectedView
    }

    private func createAccessoryView(accessoryView: UIView?) -> UIView? {
        guard let accessoryView else { return nil }
        let isButton = accessoryView is UIButton
        let iconSize = min(UIFontMetrics.default.scaledValue(for: UX.accessoryViewIconSize), UX.accessoryViewIconSize * 2)
        let accessoryViewSize = isButton ? UX.accessoryViewSize : iconSize

        let customAccessoryView: UIView = {
            let view = UIView()
            view.addSubview(accessoryView)

            if isButton {
                let button = accessoryView as? UIButton
                var buttonConfig = button?.configuration
                let image = buttonConfig?.image?.createScaled(
                    CGSize(width: iconSize, height: iconSize)).withRenderingMode(.alwaysTemplate)
                buttonConfig?.image = image
                button?.configuration = buttonConfig
            }

            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                accessoryView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                accessoryView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                accessoryView.widthAnchor.constraint(equalToConstant: accessoryViewSize),
                accessoryView.heightAnchor.constraint(equalToConstant: accessoryViewSize)
            ])

            return view
        }()

        customAccessoryView.frame = CGRect(x: 0, y: 0, width: UX.accessoryViewSize, height: UX.accessoryViewSize)
        return customAccessoryView
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        selectionStyle = .default
        separatorInset = defaultSeparatorInset
        titleLabel.text = nil
        titleLabel.font = FXFontStyles.Regular.body.scaledFont()
        leftImageView.isHidden = false
    }

    // To simplify setup, OneLineTableViewCell now has a viewModel
    // Use it for new code, replace when possible in old code
    func configure(viewModel: OneLineTableViewCellViewModel) {
        isAccessoryViewInteractive = viewModel.accessoryView is UIButton

        titleLabel.text = viewModel.title
        accessoryView = createAccessoryView(accessoryView: viewModel.accessoryView)
        accessoryType = viewModel.accessoryType
        editingAccessoryView =  createAccessoryView(accessoryView: viewModel.editingAccessoryView)

        if let image = viewModel.leftImageView {
            leftImageView.manuallySetImage(image)
        }
    }

    func configureTapState(isEnabled: Bool) {
        titleLabel.alpha = isEnabled ? 1.0 : 0.5
        leftImageView.alpha = isEnabled ? 1.0 : 0.5
    }

    func applyTheme(theme: Theme) {
        selectedView.backgroundColor = theme.colors.layer5Hover
        backgroundColor = theme.colors.layer5
        bottomSeparatorView.backgroundColor = theme.colors.borderPrimary
        if isBookmarkRefactorEnabled {
            accessoryView?.tintColor = theme.colors.iconSecondary
            editingAccessoryView?.tintColor = theme.colors.iconSecondary
            tintColor = theme.colors.iconSecondary
        }

        switch customization {
        case .regular:
            accessoryView?.tintColor = isAccessoryViewInteractive ? theme.colors.iconPrimary : theme.colors.iconSecondary
            leftImageView.tintColor = theme.colors.textPrimary
            titleLabel.textColor = theme.colors.textPrimary
        case .newFolder:
            accessoryView?.tintColor = theme.colors.iconSecondary
            leftImageView.tintColor = theme.colors.textAccent
            titleLabel.textColor = theme.colors.textAccent
        case .desktopBookmarksLabel:
            titleLabel.font = FXFontStyles.Regular.caption1.scaledFont()
            titleLabel.textColor = theme.colors.textSecondary
            leftImageView.isHidden = true
        }
    }
}
