/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit
import Shared

private struct HistoryBackButtonUX {
    static let HistoryHistoryBackButtonHeaderChevronInset: CGFloat = 10
    static let HistoryHistoryBackButtonHeaderChevronSize: CGFloat = 20
    static let HistoryHistoryBackButtonHeaderChevronLineWidth: CGFloat = 3.0
}

class HistoryBackButton: UIButton, Themeable {
    lazy var title: UILabel = {
        let label = UILabel()
        label.text = Strings.HistoryBackButtonTitle
        return label
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .left)
        chevron.lineWidth = HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronLineWidth
        return chevron
    }()

    let topBorder = UIView()
    let bottomBorder = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true

        addSubview(topBorder)
        addSubview(chevron)
        addSubview(title)

        chevron.snp.makeConstraints { make in
            make.leading.equalTo(self.safeArea.leading).offset(HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronInset)
            make.centerY.equalTo(self)
            make.size.equalTo(HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronSize)
        }

        title.snp.makeConstraints { make in
            make.leading.equalTo(chevron.snp.trailing).offset(HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronInset)
            make.trailing.greaterThanOrEqualTo(self).offset(-HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronInset)
            make.centerY.equalTo(self)
        }

        topBorder.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        title.textColor = UIColor.theme.general.highlightBlue
        chevron.tintColor = UIColor.theme.general.highlightBlue
        backgroundColor = UIColor.theme.tableView.headerBackground
        [topBorder, bottomBorder].forEach { $0.backgroundColor = UIColor.theme.homePanel.siteTableHeaderBorder }
    }
}
