/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Shared

protocol NTPLayoutHighlightDataSource: AnyObject {
    func getSectionViewModel(shownSection: Int) -> HomepageViewModelProtocol?
}

class NTPLayout: UICollectionViewCompositionalLayout {
    weak var highlightDataSource: NTPLayoutHighlightDataSource?

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attr = super.layoutAttributesForElements(in: rect)
        adjustImpactTooltipFrame(attr: attr)
        return attr
    }
    
    private func adjustImpactTooltipFrame(attr: [UICollectionViewLayoutAttributes]?) {
        guard let highlight = NTPTooltip.highlight(), let impact = attr?.first(where: {
            $0.isCell && $0.isImpactSection(dataSource: highlightDataSource)
        }), let tooltip = attr?.first(where: {
            $0.isHeader && $0.isImpactSection(dataSource: highlightDataSource)
        }) else { return }
        
        let font = UIFont.preferredFont(forTextStyle: .callout)
        let width = impact.bounds.width - 4 * NTPTooltip.UX.margin
        let height = highlight.text.height(constrainedTo: width, using: font) + 2 * NTPTooltip.UX.containerMargin + NTPTooltip.UX.margin

        tooltip.frame = impact.frame
        tooltip.frame.size.height = height
        tooltip.frame.origin.y -= (height)
        tooltip.alpha = 1
    }
}

extension UICollectionViewLayoutAttributes {
    fileprivate var isCell: Bool {
        self.representedElementCategory == .cell
    }
    
    fileprivate var isHeader: Bool {
        self.representedElementCategory == .supplementaryView &&
        self.representedElementKind == UICollectionView.elementKindSectionHeader
    }
    
    fileprivate func isImpactSection(dataSource: NTPLayoutHighlightDataSource?) -> Bool {
        dataSource?.getSectionViewModel(shownSection: self.indexPath.section)?.sectionType == .impact
    }
}

extension String {
    fileprivate func height(constrainedTo width: CGFloat, using font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height
    }
}
