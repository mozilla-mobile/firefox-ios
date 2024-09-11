// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class MicrosurveyTableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        isScrollEnabled = false

        register(
            MicrosurveyTableHeaderView.self,
            forHeaderFooterViewReuseIdentifier: MicrosurveyTableHeaderView.cellIdentifier
        )
        register(cellType: MicrosurveyTableViewCell.self)
        rowHeight = UITableView.automaticDimension
        separatorStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize { contentSize }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !bounds.size.equalTo(intrinsicContentSize) {
            invalidateIntrinsicContentSize()
        }
    }
}
