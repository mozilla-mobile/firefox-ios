/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class TooltipTableViewCell: UITableViewCell {

    private lazy var tooltip: TooltipView = {
        let tooltipView = TooltipView()
        tooltipView.translatesAutoresizingMaskIntoConstraints = false
        tooltipView.delegate = self
        return tooltipView
    }()

    public weak var delegate: TooltipViewDelegate?

    public convenience init(title: String, body: String, style: UITableViewCell.CellStyle = .default, reuseIdentifier: String? = nil) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        tooltip.set(title: title, body: body)
        contentView.addSubview(tooltip)
        NSLayoutConstraint.activate([
            tooltip.topAnchor.constraint(equalTo: contentView.topAnchor),
            tooltip.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            tooltip.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tooltip.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TooltipTableViewCell: TooltipViewDelegate {
    public func didTapTooltipDismissButton() {
        delegate?.didTapTooltipDismissButton()
    }
}
