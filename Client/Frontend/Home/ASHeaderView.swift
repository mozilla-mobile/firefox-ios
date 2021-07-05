/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit

// MARK: - Section Header View
public struct FirefoxHomeHeaderViewUX {
    static let Insets: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeUX.SectionInsetsForIpad + FirefoxHomeUX.MinimumInsets : FirefoxHomeUX.MinimumInsets
    static let TitleTopInset: CGFloat = 5
    static let sectionHeaderSize: CGFloat = 20
}

class ASHeaderView: UICollectionReusableView {
    static let verticalInsets: CGFloat = 4

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = UIFont.systemFont(ofSize: FirefoxHomeHeaderViewUX.sectionHeaderSize, weight: .bold)
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()

    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        button.contentHorizontalAlignment = .right
        button.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
        button.setTitleColor(UIColor.Photon.Grey50, for: .highlighted)
        return button
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.Insets : FirefoxHomeUX.MinimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        moreButton.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-6)
            make.trailing.equalTo(self.safeArea.trailing).inset(titleInsets)
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.safeArea.leading).inset(titleInsets)
            make.trailing.equalTo(moreButton.snp.leading).inset(-FirefoxHomeHeaderViewUX.TitleTopInset)
            
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum ExpandButtonState {
    case right
    case down
    
    var image: UIImage {
        switch self {
        case .right:
            return UIImage(named: "menu-Disclosure")!
        case .down:
            return UIImage(named: "find_next")!
        }
    }
}

class TabsHeaderView: UICollectionReusableView {
    var state: ExpandButtonState? {
        willSet(state) {
            moreButton.setImage(state?.image, for: .normal)
        }
    }
    
    lazy var containerView: UIView = {
        let containerView = UIView()
        return titleLabel
    }()
    
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        titleLabel.font = UIFont.systemFont(ofSize: FirefoxHomeHeaderViewUX.sectionHeaderSize, weight: .bold)
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        return titleLabel
    }()
    
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.setImage(state?.image, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    var titleInsets: CGFloat {
        get {
            return UIScreen.main.bounds.size.width == self.frame.size.width && UIDevice.current.userInterfaceIdiom == .pad ? FirefoxHomeHeaderViewUX.Insets : FirefoxHomeUX.MinimumInsets
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.isHidden = true
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil;
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
        titleLabel.textColor = UIColor.theme.homePanel.activityStreamHeaderText
        moreButton.setTitleColor(UIColor.theme.homePanel.activityStreamHeaderButton, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .cyan
        addSubview(titleLabel)
        addSubview(moreButton)
        addSubview(containerView)
        containerView.backgroundColor = .systemPink
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.width.equalTo(230)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
        }
        moreButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.trailing.equalTo(self.safeArea.trailing) //.inset(titleInsets)
        }
        moreButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.safeArea.leading) //.inset(titleInsets)
            //make.trailing.equalTo(moreButton.snp.leading).inset(-FirefoxHomeHeaderViewUX.TitleTopInset)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class TabsHeaderView1: UICollectionReusableView {

    static let reuseIdentifier = "supplementary-header-reusable-view"
    let label: UILabel

    enum Constants {
        static let padding: CGFloat = 20.0
    }

    override init(frame: CGRect) {
        label = UILabel()
        super.init(frame: .zero)
        backgroundColor = .cyan
    }
    
    func setupView() {
        label.numberOfLines = 0
        addSubview(label)
        label.text = "HELLO WORLD"
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding),
            label.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding),
            ])
    }
    
    func removeSubviews() {
        label.removeFromSuperview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
