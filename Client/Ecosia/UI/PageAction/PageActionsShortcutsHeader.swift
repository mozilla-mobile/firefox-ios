// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol PageActionsShortcutsDelegate: AnyObject {
    func pageOptionsOpenHome()
    func pageOptionsNewTab()
    func pageOptionsYourImpact()
    func pageOptionsShare()
}

class PageActionsShortcutsHeader: UITableViewHeaderFooterView {

    var mainView = UIStackView()
    weak var delegate: PageActionsShortcutsDelegate?

    struct Panel {
        let title: String
        let image: UIImage?
        let tag: Int
    }

    var shortcuts: [NTPLibraryShortcutView] = []

    let home = Panel(title: .localized(.home), image: UIImage(named: "menu-Home"), tag: 0)
    let newTab = Panel(title: .AppMenu.NewTab, image: UIImage(named: "menu-NewTab"), tag: 1)
    let impact = Panel(title: .localized(.yourImpact), image: UIImage(named: "myImpact"), tag: 2)
    let share = Panel(title: .AppMenu.Share, image: UIImage(named: "action_share"), tag: 3)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        mainView.distribution = .fillEqually
        mainView.alignment = .leading
        mainView.spacing = 0
        mainView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainView)

        let height = mainView.heightAnchor.constraint(equalToConstant: 100)
        height.priority = .defaultHigh
        height.isActive = true

        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])


        // Ecosia: Show history instead of synced tabs
        [home, newTab, impact, share].forEach { item in
            let view = NTPLibraryShortcutView()
            view.button.layer.cornerRadius = 10
            view.button.setImage(item.image, for: .normal)
            view.button.tag = item.tag
            view.button.addTarget(self, action: #selector(tapped), for: .primaryActionTriggered)
            view.title.text = item.title
            let words = view.title.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
            view.title.numberOfLines = words == 1 ? 1 : 2
            view.accessibilityLabel = item.title
            mainView.addArrangedSubview(view)
            shortcuts.append(view)
        }
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        backgroundView?.backgroundColor = .clear

        shortcuts.forEach { item in
            item.title.textColor = .theme.ecosia.primaryText
            item.button.tintColor = .theme.ecosia.secondaryText
            item.button.backgroundColor = .theme.ecosia.impactMultiplyCardBackground
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    @objc func tapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            delegate?.pageOptionsOpenHome()
            Analytics.shared.menuClick(label: "home")
        case 1:
            delegate?.pageOptionsNewTab()
            Analytics.shared.menuClick(label: "new_tab")
        case 2:
            delegate?.pageOptionsYourImpact()
            Analytics.shared.menuClick(label: "your_impact")
        case 3:
            delegate?.pageOptionsShare()
            Analytics.shared.menuClick(label: "share")
        default:
            break
        }
    }

}
