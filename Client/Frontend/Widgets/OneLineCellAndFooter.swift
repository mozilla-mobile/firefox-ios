// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

struct OneLineCellUX {
    static let ImageSize: CGFloat = 28
    static let BorderViewMargin: CGFloat = 16
    static let LabelTopBottomMargin: CGFloat = 11
    static let ImageTopBottomMargin: CGFloat = 10
}

enum OneLineTableViewCustomization {
    case regular
    case inactiveCell
}

class OneLineTableViewCell: UITableViewCell, NotificationThemeable, ReusableCell {
    // Tableview cell items

    override var indentationLevel: Int {
        didSet {
            containerViewLeadingConstraint.constant = CGFloat(indentationLevel * Int(indentationWidth))
        }
    }

    var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.selectedBackground
        return view
    }()

    var leftImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.layer.cornerRadius = 5.0
        imgView.clipsToBounds = true
        return imgView
    }()

    var leftOverlayImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body, maxSize: 17)
        label.textAlignment = .natural
        label.numberOfLines = 1
        label.contentMode = .center
        return label
    }()

    lazy var bottomSeparatorView: UIView = .build { separatorLine in
        // separator hidden by default
        separatorLine.isHidden = true
        separatorLine.backgroundColor = UIColor.Photon.Grey40
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let containerView = UIView()
    let midView = UIView()
    var customization: OneLineTableViewCustomization = .regular

    private var containerViewLeadingConstraint: NSLayoutConstraint!
    private var leftImageViewLeadingConstraint: NSLayoutConstraint!
    private var midViewTrailingConstraint: NSLayoutConstraint!

    private var defaultSeparatorInset: UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: OneLineCellViewModel.UX.ImageSize + 2 *
                            OneLineCellViewModel.UX.BorderViewMargin,
                            bottom: 0,
                            right: 0)
    }

    func initialViewSetup() {
        separatorInset = defaultSeparatorInset
        self.selectionStyle = .default
        midView.addSubview(titleLabel)
        containerView.addSubviews(bottomSeparatorView)
        containerView.addSubview(leftImageView)
        containerView.addSubview(midView)

        contentView.addSubview(containerView)
        bringSubviewToFront(containerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        leftImageView.translatesAutoresizingMaskIntoConstraints = false
        midView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerViewLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        leftImageViewLeadingConstraint = leftImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor,
                                                                                constant: 15)
        midViewTrailingConstraint = midView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerViewLeadingConstraint,
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            leftImageView.heightAnchor.constraint(equalToConstant: OneLineCellUX.ImageSize),
            leftImageView.widthAnchor.constraint(equalToConstant: OneLineCellUX.ImageSize),
            leftImageViewLeadingConstraint,
            leftImageView.centerYAnchor.constraint(equalTo: midView.centerYAnchor),
            leftImageView.topAnchor.constraint(greaterThanOrEqualTo: containerView.topAnchor,
                                               constant: OneLineCellUX.ImageTopBottomMargin),
            leftImageView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor,
                                                  constant: OneLineCellUX.ImageTopBottomMargin),

            midView.topAnchor.constraint(equalTo: containerView.topAnchor),
            midView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            midView.leadingAnchor.constraint(equalTo: leftImageView.trailingAnchor, constant: 13),
            midViewTrailingConstraint,

            titleLabel.topAnchor.constraint(equalTo: midView.topAnchor, constant: OneLineCellUX.LabelTopBottomMargin),
            titleLabel.bottomAnchor.constraint(equalTo: midView.bottomAnchor, constant: -OneLineCellUX.LabelTopBottomMargin),
            titleLabel.leadingAnchor.constraint(equalTo: midView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: midView.trailingAnchor),

            bottomSeparatorView.heightAnchor.constraint(equalToConstant: 0.7),
            bottomSeparatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        leftImageView.setContentHuggingPriority(.required, for: .vertical)

        selectedBackgroundView = selectedView
        applyTheme()
    }

    func updateMidConstraint() {
        let leadingConstant: CGFloat = customization == .regular ? 15 : customization == .inactiveCell ? 16 : 15
        leftImageViewLeadingConstraint.constant = leadingConstant
        midViewTrailingConstraint.constant = -7
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
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.selectionStyle = .default
        separatorInset = defaultSeparatorInset
        applyTheme()
    }
}

class OneLineFooterView: UITableViewHeaderFooterView, NotificationThemeable {
    fileprivate let bordersHelper = ThemedHeaderFooterViewBordersHelper()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .natural
        label.numberOfLines = 1
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        initialViewSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let containerView = UIView()
    var shortheight: Bool = false
    private var shortHeight = 32

    private func initialViewSetup() {
        bordersHelper.initBorders(view: containerView)
        setDefaultBordersValues()
        layoutMargins = .zero

        containerView.addSubview(titleLabel)
        addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.height.equalTo(shortheight ? 32 : 58)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.bottom.equalToSuperview().offset(-14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        applyTheme()
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    fileprivate func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, true)
        bordersHelper.showBorder(for: .bottom, true)
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        self.containerView.backgroundColor = UIColor.theme.tableView.selectedBackground
        self.titleLabel.textColor =  theme == .dark ? .white : .black
        bordersHelper.applyTheme()
    }

    func setupHeaderConstraint() {
        containerView.snp.remakeConstraints { make in
            make.height.equalTo(shortheight ? 32 : 58)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setupHeaderConstraint()
        setDefaultBordersValues()
        applyTheme()
    }
}
