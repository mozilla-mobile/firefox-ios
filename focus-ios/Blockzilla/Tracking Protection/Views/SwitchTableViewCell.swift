/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Combine

class SwitchTableViewCell: UITableViewCell {
    private lazy var toggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .accent
        toggle.tintColor = .darkGray
        toggle.addTarget(self, action: #selector(toggle(sender:)), for: .valueChanged)

        return toggle
    }()

    private var cancellable: AnyCancellable?
    private var subject = PassthroughSubject<Bool, Never>()
    public var valueChanged: AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
    public var isOn = false {
        didSet { toggle.isOn = isOn }
    }

    convenience init(item: ToggleItem, style: UITableViewCell.CellStyle = .default, reuseIdentifier: String?) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        toggle.isOn = Settings.getToggle(item.settingsKey)
        toggle.accessibilityIdentifier = "BlockerToggle.\(item.settingsKey.rawValue)"
        textLabel?.text = item.title
        textLabel?.textColor = .primaryText
        textLabel?.numberOfLines = 0
        accessoryView = PaddedSwitch(switchView: toggle)
        backgroundColor = .secondarySystemGroupedBackground
        selectionStyle = .none
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func toggle(sender: UISwitch) {
        subject.send(sender.isOn)
    }
}
