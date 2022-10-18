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

//    override var indentationLevel: Int {
//        didSet {
//            containerView.snp.remakeConstraints { make in
//                make.height.equalTo(44)
//                make.top.bottom.equalToSuperview()
//                make.leading.equalToSuperview().offset(indentationLevel * Int(indentationWidth))
//                make.trailing.equalTo(accessoryView?.snp.leading ?? contentView.snp.trailing)
//            }
//        }
//    }

    private lazy var selectedView: UIView = .build { _ in }
    private lazy var containerView: UIView = .build { _ in }
    private lazy var midView: UIView = .build { _ in }

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

        midView.addSubview(titleLabel)
        containerView.addSubviews(bottomSeparatorView)
        containerView.addSubview(leftImageView)
        containerView.addSubview(midView)

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

            leftImageView.centerYAnchor.constraint(equalTo: midView.centerYAnchor),
            leftImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                  constant: 16),
            leftImageView.widthAnchor.constraint(equalToConstant: 28),
            leftImageView.heightAnchor.constraint(equalToConstant: 28),
            leftImageView.trailingAnchor.constraint(equalTo: midView.leadingAnchor,
                                                    constant: -midViewLeadingMargin),

            midView.topAnchor.constraint(equalTo: containerView.topAnchor),
            midView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            midView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor,
                                             constant: -8),

            titleLabel.topAnchor.constraint(equalTo: midView.topAnchor,
                                           constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: midView.leadingAnchor,
                                             constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: midView.bottomAnchor,
                                              constant: -4),
            titleLabel.trailingAnchor.constraint(equalTo: midView.trailingAnchor,
                                             constant: -8),

            bottomSeparatorView.topAnchor.constraint(greaterThanOrEqualTo: midView.bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: 0.7)
        ])

//        containerView.snp.makeConstraints { make in
//            make.height.equalTo(44)
//            make.top.bottom.equalToSuperview()
//            make.leading.equalToSuperview()
//            make.trailing.equalTo(accessoryView?.snp.leading ?? contentView.snp.trailing)
//        }

//        leftImageView.snp.makeConstraints { make in
//            make.height.width.equalTo(28)
//            make.leading.equalTo(containerView.snp.leading).offset(15)
//            make.centerY.equalTo(containerView.snp.centerY)
//        }

//        midView.snp.makeConstraints { make in
//            make.height.equalTo(42)
//            make.centerY.equalToSuperview()
//            if shouldLeftAlignTitle {
//                make.leading.equalTo(containerView.snp.leading).offset(5)
//            } else {
//                make.leading.equalTo(leftImageView.snp.trailing).offset(13)
//            }
//            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
//        }

//        titleLabel.snp.makeConstraints { make in
//            make.height.equalTo(40)
//            make.centerY.equalTo(midView.snp.centerY)
//            make.leading.equalTo(midView.snp.leading)
//            make.trailing.equalTo(midView.snp.trailing)
//        }

//        bottomSeparatorView.snp.makeConstraints { make in
//            make.height.equalTo(0.7)
//            make.bottom.equalTo(containerView.snp.bottom)
//            make.leading.equalTo(titleLabel.snp.leading)
//            make.trailing.equalTo(containerView.snp.trailing)
//        }

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

//    private func updateMidConstraint() {
//        leftImageView.snp.updateConstraints { update in
//            let leadingLeft = customization == .regular ? 15 : customization == .inactiveCell ? 16 : 15
//            update.leading.equalTo(containerView.snp.leading).offset(leadingLeft)
//        }
//
//        midView.snp.remakeConstraints { make in
//            make.height.equalTo(42)
//            make.centerY.equalToSuperview()
//            if shouldLeftAlignTitle {
//                make.leading.equalTo(containerView.snp.leading).offset(5)
//            } else {
//                make.leading.equalTo(leftImageView.snp.trailing).offset(13)
//            }
//            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
//        }
//    }

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
