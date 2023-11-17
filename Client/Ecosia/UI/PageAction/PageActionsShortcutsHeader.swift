// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

protocol PageActionsShortcutsDelegate: AnyObject {
    func pageOptionsOpenHome()
    func pageOptionsNewTab()
    func pageOptionsShare()
    func pageOptionsSettings()
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

    let home = Panel(title: .localized(.home), 
                     image: UIImage(named: StandardImageIdentifiers.Large.home),
                     tag: 0)
    let newTab = Panel(title: .AppMenu.NewTab, 
                       image: UIImage(named: StandardImageIdentifiers.Large.plus),
                       tag: 1)
    let share = Panel(title: .AppMenu.Share, 
                      image: UIImage(named: ImageIdentifiers.share),
                      tag: 2)
    let settings = Panel(title: .AppMenu.AppMenuSettingsTitleString, 
                         image: UIImage(named: ImageIdentifiers.settings),
                         tag: 3)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        mainView.distribution = .fillEqually
        mainView.alignment = .center
        mainView.spacing = 8
        mainView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainView)

        let height = mainView.heightAnchor.constraint(equalToConstant: 100)
        height.priority = .defaultHigh
        height.isActive = true

        NSLayoutConstraint.activate([
            mainView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8, priority: .defaultHigh),
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])


        // Ecosia: Custom options
        [home, newTab, share, settings].forEach { item in
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

    private func applyTheme() {
        backgroundView?.backgroundColor = .clear

        shortcuts.forEach { item in
            item.title.textColor = .legacyTheme.ecosia.primaryText
            item.button.tintColor = .legacyTheme.ecosia.secondaryText
            item.button.backgroundColor = .legacyTheme.ecosia.impactMultiplyCardBackground
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
        case 1:
            delegate?.pageOptionsNewTab()
        case 2:
            delegate?.pageOptionsShare()
        case 3:
            delegate?.pageOptionsSettings()
        default:
            break
        }
    }

}
