/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UITableViewCell {
    
    func roundedCorners(tableView: UITableView, indexPath: IndexPath) {
        let cornerRadius = UIConstants.layout.settingsCellCornerRadius
        var corners: UIRectCorner = []
        
        if indexPath.row == 0
        {
            corners.update(with: .topLeft)
            corners.update(with: .topRight)
        }
        
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
        {
            corners.update(with: .bottomLeft)
            corners.update(with: .bottomRight)
        }
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: self.bounds,
                                      byRoundingCorners: corners,
                                      cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
        self.layer.mask = maskLayer
    }
    
    func addSeparator(tableView: UITableView, indexPath: IndexPath, leadingOffset: CGFloat = 0) {
        if indexPath.row != tableView.numberOfRows(inSection: indexPath.section) - 1 {
            let separator = UIView()
            separator.backgroundColor = .searchSeparator.withAlphaComponent(0.65)
            
            self.addSubview(separator)
            separator.snp.makeConstraints { make in
                make.height.equalTo(0.5)
                make.leading.equalToSuperview().offset(leadingOffset)
                make.trailing.bottom.equalToSuperview()
            }
        }
    }
}
