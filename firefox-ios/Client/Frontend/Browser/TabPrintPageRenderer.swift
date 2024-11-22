// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class TabPrintPageRenderer: UIPrintPageRenderer {
    private struct PrintedPageUX {
        static let insets = CGFloat(36.0)
        static let textFont = FXFontStyles.Regular.caption1.scaledFont()
        static let marginScale = CGFloat(0.5)
    }

    fileprivate var tabDisplayTitle: String
    fileprivate var tabURL: URL?
    fileprivate weak var webView: TabWebView?

    let textAttributes = [NSAttributedString.Key.font: PrintedPageUX.textFont]
    let dateString: String

    required init(tabDisplayTitle: String, tabURL: URL?, webView: TabWebView?) {
        self.tabDisplayTitle = tabDisplayTitle
        self.tabURL = tabURL
        self.webView = webView
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        self.dateString = dateFormatter.string(from: Date())

        super.init()

        self.footerHeight = PrintedPageUX.marginScale * PrintedPageUX.insets
        self.headerHeight = PrintedPageUX.marginScale * PrintedPageUX.insets

        if let formatter = webView?.viewPrintFormatter() {
            formatter.perPageContentInsets = UIEdgeInsets(equalInset: PrintedPageUX.insets)
            addPrintFormatter(formatter, startingAtPageAt: 0)
        }
    }

    override func drawFooterForPage(at pageIndex: Int, in headerRect: CGRect) {
        let headerInsets = UIEdgeInsets(
            top: headerRect.minY,
            left: PrintedPageUX.insets,
            bottom: paperRect.maxY - headerRect.maxY,
            right: PrintedPageUX.insets
        )
        let headerRect = paperRect.inset(by: headerInsets)

        // url on left
        self.drawTextAtPoint(tabURL?.displayURL?.absoluteString ?? "", rect: headerRect, onLeft: true)

        // page number on right
        let pageNumberString = "\(pageIndex + 1)"
        self.drawTextAtPoint(pageNumberString, rect: headerRect, onLeft: false)
    }

    override func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        let headerInsets = UIEdgeInsets(
            top: headerRect.minY,
            left: PrintedPageUX.insets,
            bottom: paperRect.maxY - headerRect.maxY,
            right: PrintedPageUX.insets
        )
        let headerRect = paperRect.inset(by: headerInsets)

        // page title on left
        self.drawTextAtPoint(tabDisplayTitle, rect: headerRect, onLeft: true)

        // date on right
        self.drawTextAtPoint(dateString, rect: headerRect, onLeft: false)
    }

    func drawTextAtPoint(_ text: String, rect: CGRect, onLeft: Bool) {
        let size = text.size(withAttributes: textAttributes)
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
