/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private struct PrintedPageUX {
    static let PageInsets = CGFloat(36.0)
    static let PageTextFont = DynamicFontHelper.defaultHelper.DefaultSmallFont
    static let PageMarginScale = CGFloat(0.5)
}

class TabPrintPageRenderer: UIPrintPageRenderer {
    fileprivate weak var tab: Tab?
    let textAttributes = [NSFontAttributeName: PrintedPageUX.PageTextFont]
    let dateString: String

    required init(tab: Tab) {
        self.tab = tab
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        self.dateString = dateFormatter.string(from: Date())

        super.init()

        self.footerHeight = PrintedPageUX.PageMarginScale * PrintedPageUX.PageInsets
        self.headerHeight = PrintedPageUX.PageMarginScale * PrintedPageUX.PageInsets

        if let tab = self.tab {
            let formatter = tab.webView!.viewPrintFormatter()
            formatter.perPageContentInsets = UIEdgeInsets(top: PrintedPageUX.PageInsets, left: PrintedPageUX.PageInsets, bottom: PrintedPageUX.PageInsets, right: PrintedPageUX.PageInsets)
            addPrintFormatter(formatter, startingAtPageAt: 0)
        }
    }

    override func drawFooterForPage(at pageIndex: Int, in headerRect: CGRect) {
        let headerInsets = UIEdgeInsets(top: headerRect.minY, left: PrintedPageUX.PageInsets, bottom: paperRect.maxY - headerRect.maxY, right: PrintedPageUX.PageInsets)
        let headerRect = UIEdgeInsetsInsetRect(paperRect, headerInsets)

        // url on left
        self.drawTextAtPoint(tab!.url?.displayURL?.absoluteString ?? "", rect: headerRect, onLeft: true)

        // page number on right
        let pageNumberString = "\(pageIndex + 1)"
        self.drawTextAtPoint(pageNumberString, rect: headerRect, onLeft: false)
    }

    override func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        let headerInsets = UIEdgeInsets(top: headerRect.minY, left: PrintedPageUX.PageInsets, bottom: paperRect.maxY - headerRect.maxY, right: PrintedPageUX.PageInsets)
        let headerRect = UIEdgeInsetsInsetRect(paperRect, headerInsets)

        // page title on left
        self.drawTextAtPoint(tab!.displayTitle, rect: headerRect, onLeft: true)

        // date on right
        self.drawTextAtPoint(dateString, rect: headerRect, onLeft: false)
    }

    func drawTextAtPoint(_ text: String, rect: CGRect, onLeft: Bool) {
        let size = text.size(attributes: textAttributes)
        let x, y: CGFloat
        if onLeft {
            x = rect.minX
            y = rect.midY - size.height / 2
        } else {
            x = rect.maxX - size.width
            y = rect.midY - size.height / 2
        }
        text.draw(at: CGPoint(x: x, y: y), withAttributes: textAttributes)
    }
    
}
