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

class HistoryBackButton : UIButton {
    lazy var title: UILabel = {
        let label = UILabel()
        label.textColor = UIConstants.HighlightBlue
        label.text = Strings.HistoryBackButtonTitle
        return label
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .left)
        chevron.tintColor = UIConstants.HighlightBlue
        chevron.lineWidth = HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronLineWidth
        return chevron
    }()

    lazy var topBorder: UIView = self.createBorderView()
    lazy var bottomBorder: UIView = self.createBorderView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true

        addSubview(topBorder)
        addSubview(chevron)
        addSubview(title)

        backgroundColor = UIColor.white()

        chevron.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronInset)
            make.centerY.equalTo(self)
            make.size.equalTo(HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronSize)
        }

        title.snp_makeConstraints { make in
            make.leading.equalTo(chevron.snp_trailing).offset(HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronInset)
            make.trailing.greaterThanOrEqualTo(self).offset(-HistoryBackButtonUX.HistoryHistoryBackButtonHeaderChevronInset)
            make.centerY.equalTo(self)
        }

        topBorder.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }
    }

    private func createBorderView() -> UIView {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
