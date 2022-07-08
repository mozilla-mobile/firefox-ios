// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

struct OneLineCellUX {
    static let ImageSize: CGFloat = 29
    static let BorderViewMargin: CGFloat = 16
}

enum OneLineTableViewCustomization {
    case regular
    case inactiveCell
}

class OneLineTableViewCell: UITableViewCell, NotificationThemeable, ReusableCell {
    // Tableview cell items

    override var indentationLevel: Int {
        didSet {
            containerView.snp.remakeConstraints { make in
                make.height.equalTo(44)
                make.top.bottom.equalToSuperview()
                make.leading.equalToSuperview().offset(indentationLevel * Int(indentationWidth))
                make.trailing.equalTo(accessoryView?.snp.leading ?? contentView.snp.trailing)
            }
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

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textAlignment = .natural
        label.numberOfLines = 1
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
    var shouldLeftAlignTitle = false
    var customization: OneLineTableViewCustomization = .regular

    private var defaultSeparatorInset: UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: OneLineCellUX.ImageSize + 2 * OneLineCellUX.BorderViewMargin,
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

        containerView.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(accessoryView?.snp.leading ?? contentView.snp.trailing)
        }

        leftImageView.snp.makeConstraints { make in
            make.height.width.equalTo(28)
            make.leading.equalTo(containerView.snp.leading).offset(15)
            make.centerY.equalTo(containerView.snp.centerY)
        }

        midView.snp.makeConstraints { make in
            make.height.equalTo(42)
            make.centerY.equalToSuperview()
            if shouldLeftAlignTitle {
                make.leading.equalTo(containerView.snp.leading).offset(5)
            } else {
                make.leading.equalTo(leftImageView.snp.trailing).offset(13)
            }
            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.centerY.equalTo(midView.snp.centerY)
            make.leading.equalTo(midView.snp.leading)
            make.trailing.equalTo(midView.snp.trailing)
        }

        bottomSeparatorView.snp.makeConstraints { make in
            make.height.equalTo(0.7)
            make.bottom.equalTo(containerView.snp.bottom)
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalTo(containerView.snp.trailing)
        }

        selectedBackgroundView = selectedView
        applyTheme()
    }

    func updateMidConstraint() {
        leftImageView.snp.updateConstraints { update in
            let leadingLeft = customization == .regular ? 15 : customization == .inactiveCell ? 16 : 15
            update.leading.equalTo(containerView.snp.leading).offset(leadingLeft)
        }

        midView.snp.remakeConstraints { make in
            make.height.equalTo(42)
            make.centerY.equalToSuperview()
            if shouldLeftAlignTitle {
                make.leading.equalTo(containerView.snp.leading).offset(5)
            } else {
                make.leading.equalTo(leftImageView.snp.trailing).offset(13)
            }
            make.trailing.equalTo(containerView.snp.trailing).offset(-7)
        }
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
