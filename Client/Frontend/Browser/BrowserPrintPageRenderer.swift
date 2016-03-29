/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private struct PrintedPageUX {
    static let PageInsets = CGFloat(36.0)
    static let PageTextFont = DynamicFontHelper.defaultHelper.DefaultSmallFont
    static let PageMarginScale = CGFloat(0.5)
}

class BrowserPrintPageRenderer: UIPrintPageRenderer {
    private weak var browser: Browser?
    let textAttributes = [NSFontAttributeName: PrintedPageUX.PageTextFont]
    let dateString: String

    required init(browser: Browser) {
        self.browser = browser
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        self.dateString = dateFormatter.stringFromDate(NSDate())

        super.init()

        self.footerHeight = PrintedPageUX.PageMarginScale * PrintedPageUX.PageInsets
        self.headerHeight = PrintedPageUX.PageMarginScale * PrintedPageUX.PageInsets

        if let browser = self.browser {
            let formatter = browser.webView!.viewPrintFormatter()
            formatter.perPageContentInsets = UIEdgeInsets(top: PrintedPageUX.PageInsets, left: PrintedPageUX.PageInsets, bottom: PrintedPageUX.PageInsets, right: PrintedPageUX.PageInsets)
            addPrintFormatter(formatter, startingAtPageAtIndex: 0)
        }
    }

    override func drawFooterForPageAtIndex(pageIndex: Int, inRect headerRect: CGRect) {
        let headerInsets = UIEdgeInsets(top: CGRectGetMinY(headerRect), left: PrintedPageUX.PageInsets, bottom: CGRectGetMaxY(paperRect) - CGRectGetMaxY(headerRect), right: PrintedPageUX.PageInsets)
        let headerRect = UIEdgeInsetsInsetRect(paperRect, headerInsets)

        // url on left
        self.drawTextAtPoint(browser!.displayURL?.absoluteString ?? "", rect: headerRect, onLeft: true)

        // page number on right
        let pageNumberString = "\(pageIndex + 1)"
        self.drawTextAtPoint(pageNumberString, rect: headerRect, onLeft: false)
    }

    override func drawHeaderForPageAtIndex(pageIndex: Int, inRect headerRect: CGRect) {
        let headerInsets = UIEdgeInsets(top: CGRectGetMinY(headerRect), left: PrintedPageUX.PageInsets, bottom: CGRectGetMaxY(paperRect) - CGRectGetMaxY(headerRect), right: PrintedPageUX.PageInsets)
        let headerRect = UIEdgeInsetsInsetRect(paperRect, headerInsets)

        // page title on left
        self.drawTextAtPoint(browser!.displayTitle, rect: headerRect, onLeft: true)

        // date on right
        self.drawTextAtPoint(dateString, rect: headerRect, onLeft: false)
    }

    func drawTextAtPoint(text: String, rect:CGRect, onLeft: Bool){
        let size = text.sizeWithAttributes(textAttributes)
        let x, y: CGFloat
        if onLeft {
            x = CGRectGetMinX(rect)
            y = CGRectGetMidY(rect) - size.height / 2
        } else {
            x = CGRectGetMaxX(rect) - size.width
            y = CGRectGetMidY(rect) - size.height / 2
        }
        text.drawAtPoint(CGPoint(x: x, y: y), withAttributes: textAttributes)
    }
    
}
