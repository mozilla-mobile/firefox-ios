// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

public class MenuCell: UITableViewCell, ReusableCell {
    // MARK: - Properties
    public var model: MenuElement?

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configureCellWith(model: MenuElement) {
        self.model = model
        self.textLabel?.text = model.title
        setupView()
    }

    private func setupView() {
        self.backgroundColor = .systemYellow
        self.textLabel?.font = UIFont.systemFont(ofSize: 16)
        self.textLabel?.textColor = .black
    }

    func performAction() {
        guard let action = model?.action else { return }
        action()
    }
}
