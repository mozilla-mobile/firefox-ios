/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class TooltipTableViewCell: UITableViewCell {

    private var tooltip = TooltipView()
    public weak var delegate: TooltipViewDelegate?
    
    public convenience init(title: String, body: String, style: UITableViewCell.CellStyle = .default, reuseIdentifier: String? = nil) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(tooltip)
        tooltip.set(title: title, body: body)
        tooltip.delegate = self
        tooltip.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
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
