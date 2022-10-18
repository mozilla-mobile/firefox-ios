// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

enum OneLineTableViewCustomization {
    case regular
    case inactiveCell
}

struct OneLineTableViewCellViewModel {
    let title: String?
    var leftImageView: UIImage?
    var leftImageViewContentView: UIView.ContentMode
    let accessoryView: UIImageView?
    let accessoryType: UITableViewCell.AccessoryType
}

class OneLineTableViewCell: UITableViewCell, ReusableCell {
    // Tableview cell items

    struct UX {
        static let imageSize: CGFloat = 29
        static let borderViewMargin: CGFloat = 16
    }

    var notificationCenter: NotificationProtocol = NotificationCenter.default
    var shouldLeftAlignTitle = false
    var customization: OneLineTableViewCustomization = .regular

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }

    lazy var leftImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 5.0
        imageView.clipsToBounds = true
    }

    lazy var titleLabel: UILabel = .build { label in
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .natural
    }

    private lazy var bottomSeparatorView: UIView = .build { separatorLine in
        // separator hidden by default
        separatorLine.isHidden = true
        separatorLine.backgroundColor = UIColor.Photon.Grey40
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupLayout()
        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged])
        applyTheme()
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

    private func setupLayout() {
        separatorInset = defaultSeparatorInset
        selectionStyle = .default

        containerView.addSubviews(leftImageView,
                                  titleLabel,
                                  bottomSeparatorView)

        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        let containerViewTrailingAnchor = accessoryView?.leadingAnchor ?? contentView.trailingAnchor
        let midViewLeadingMargin: CGFloat = shouldLeftAlignTitle ? 5 : 13

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                              constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                  constant: -8),
            containerView.trailingAnchor.constraint(equalTo: containerViewTrailingAnchor),

            leftImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            leftImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                  constant: 16),
            leftImageView.widthAnchor.constraint(equalToConstant: 28),
            leftImageView.heightAnchor.constraint(equalToConstant: 28),
            leftImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor,
                                                    constant: -midViewLeadingMargin),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor,
                                            constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor,
                                               constant: -4),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                                 constant: -8),

            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: 0.7)
        ])

        selectedBackgroundView = selectedView
        applyTheme()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .default
        separatorInset = defaultSeparatorInset
        titleLabel.text = nil
        leftImageView.image = nil
        applyTheme()
    }

    // To simplify setup, OneLineTableViewCell now has a viewModel
    // Use it for new code, replace when possible in old code
    func configure(viewModel: OneLineTableViewCellViewModel) {
        titleLabel.text = viewModel.title
        leftImageView.image = viewModel.leftImageView
        leftImageView.contentMode = viewModel.leftImageViewContentView
        accessoryView = viewModel.accessoryView
        editingAccessoryType = viewModel.accessoryType
    }

    func configureTapState(isEnabled: Bool) {
        titleLabel.alpha = isEnabled ? 1.0 : 0.5
        leftImageView.alpha = isEnabled ? 1.0 : 0.5
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        selectedView.backgroundColor = UIColor.theme.tableView.selectedBackground
        if theme == .dark {
            self.backgroundColor = UIColor.Photon.Grey80
            self.titleLabel.textColor = .white
        } else {
            self.backgroundColor = .white
            self.titleLabel.textColor = .black
        }

        bottomSeparatorView.backgroundColor = UIColor.Photon.Grey40
    }
}

extension OneLineTableViewCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
