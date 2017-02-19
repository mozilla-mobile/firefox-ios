/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ChevronDirection {
    case left
    case up
    case right
    case down
}

enum ChevronStyle {
    case angular
    case rounded
}

class ChevronView: UIView {
    fileprivate let Padding: CGFloat = 2.5
    fileprivate var direction = ChevronDirection.right
    fileprivate var lineCapStyle = CGLineCap.round
    fileprivate var lineJoinStyle = CGLineJoin.round

    var lineWidth: CGFloat = 3.0
    
    var style: ChevronStyle = .rounded {
        didSet {
            switch style {
            case .rounded:
                lineCapStyle = CGLineCap.round
                lineJoinStyle = CGLineJoin.round
            case .angular:
                lineCapStyle = CGLineCap.butt
                lineJoinStyle = CGLineJoin.miter

            }
        }
    }

    init(direction: ChevronDirection) {
        super.init(frame: CGRect.zero)

        self.direction = direction
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            if direction == .left {
                self.direction = .right
            } else if direction == .right {
                self.direction = .left
            }
        }
        self.backgroundColor = UIColor.clear
        self.contentMode = UIViewContentMode.redraw
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        let strokeLength = (rect.size.height / 2) - Padding

        let path: UIBezierPath

        switch direction {
        case .left:
            path = drawLeftChevronAt(CGPoint(x: rect.size.width - (strokeLength + Padding), y: strokeLength + Padding), strokeLength:strokeLength)
        case .up:
            path = drawUpChevronAt(CGPoint(x: (rect.size.width - Padding) - strokeLength, y: (strokeLength / 2) + Padding), strokeLength:strokeLength)
        case .right:
            path = drawRightChevronAt(CGPoint(x: rect.size.width - Padding, y: strokeLength + Padding), strokeLength:strokeLength)
        case .down:
            path = drawDownChevronAt(CGPoint(x: (rect.size.width - Padding) - strokeLength, y: (strokeLength * 1.5) + Padding), strokeLength:strokeLength)
        }

        tintColor.set()

        // The line thickness needs to be proportional to the distance from the arrow head to the tips.  Making it half seems about right.
        path.lineCapStyle = lineCapStyle
        path.lineJoinStyle = lineJoinStyle
        path.lineWidth = lineWidth
        path.stroke()
    }

    fileprivate func drawUpChevronAt(_ origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(CGPoint(x: origin.x-strokeLength, y: origin.y+strokeLength),
            head: CGPoint(x: origin.x, y: origin.y),
            rightTip: CGPoint(x: origin.x+strokeLength, y: origin.y+strokeLength))
    }

    fileprivate func drawDownChevronAt(_ origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(CGPoint(x: origin.x-strokeLength, y: origin.y-strokeLength),
            head: CGPoint(x: origin.x, y: origin.y),
            rightTip: CGPoint(x: origin.x+strokeLength, y: origin.y-strokeLength))
    }

    fileprivate func drawLeftChevronAt(_ origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(CGPoint(x: origin.x+strokeLength, y: origin.y-strokeLength),
            head: CGPoint(x: origin.x, y: origin.y),
            rightTip: CGPoint(x: origin.x+strokeLength, y: origin.y+strokeLength))
    }

    fileprivate func drawRightChevronAt(_ origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(CGPoint(x: origin.x-strokeLength, y: origin.y+strokeLength),
            head: CGPoint(x: origin.x, y: origin.y),
            rightTip: CGPoint(x: origin.x-strokeLength, y: origin.y-strokeLength))
    }

    fileprivate func drawChevron(_ leftTip: CGPoint, head: CGPoint, rightTip: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()

        // Left tip
        path.move(to: leftTip)
        // Arrow head
        path.addLine(to: head)
        // Right tip
        path.addLine(to: rightTip)

        return path
    }
}
