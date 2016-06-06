/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ChevronDirection {
    case Left
    case Up
    case Right
    case Down
}

enum ChevronStyle {
    case Angular
    case Rounded
}

class ChevronView: UIView {
    private let Padding: CGFloat = 2.5
    private var direction = ChevronDirection.Right
    private var lineCapStyle = CGLineCap.Round
    private var lineJoinStyle = CGLineJoin.Round

    var lineWidth: CGFloat = 3.0
    
    var style: ChevronStyle = .Rounded {
        didSet {
            switch style {
            case .Rounded:
                lineCapStyle = CGLineCap.Round
                lineJoinStyle = CGLineJoin.Round
            case .Angular:
                lineCapStyle = CGLineCap.Butt
                lineJoinStyle = CGLineJoin.Miter

            }
        }
    }

    init(direction: ChevronDirection) {
        super.init(frame: CGRectZero)

        self.direction = direction
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft {
            if direction == .Left {
                self.direction = .Right
            } else if direction == .Right {
                self.direction = .Left
            }
        }
        self.backgroundColor = UIColor.clearColor()
        self.contentMode = UIViewContentMode.Redraw
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        let strokeLength = (rect.size.height / 2) - Padding;

        let path: UIBezierPath

        switch (direction) {
        case .Left:
            path = drawLeftChevronAt(origin: CGPointMake(rect.size.width - (strokeLength + Padding), strokeLength + Padding), strokeLength:strokeLength)
        case .Up:
            path = drawUpChevronAt(origin: CGPointMake((rect.size.width - Padding) - strokeLength, (strokeLength / 2) + Padding), strokeLength:strokeLength)
        case .Right:
            path = drawRightChevronAt(origin: CGPointMake(rect.size.width - Padding, strokeLength + Padding), strokeLength:strokeLength)
        case .Down:
            path = drawDownChevronAt(origin: CGPointMake((rect.size.width - Padding) - strokeLength, (strokeLength * 1.5) + Padding), strokeLength:strokeLength)
        }

        tintColor.set()

        // The line thickness needs to be proportional to the distance from the arrow head to the tips.  Making it half seems about right.
        path.lineCapStyle = lineCapStyle
        path.lineJoinStyle = lineJoinStyle
        path.lineWidth = lineWidth
        path.stroke();
    }

    private func drawUpChevronAt(origin origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(leftTip: CGPointMake(origin.x-strokeLength, origin.y+strokeLength),
            head: CGPointMake(origin.x, origin.y),
            rightTip: CGPointMake(origin.x+strokeLength, origin.y+strokeLength))
    }

    private func drawDownChevronAt(origin origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(leftTip: CGPointMake(origin.x-strokeLength, origin.y-strokeLength),
            head: CGPointMake(origin.x, origin.y),
            rightTip: CGPointMake(origin.x+strokeLength, origin.y-strokeLength))
    }

    private func drawLeftChevronAt(origin origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(leftTip: CGPointMake(origin.x+strokeLength, origin.y-strokeLength),
            head: CGPointMake(origin.x, origin.y),
            rightTip: CGPointMake(origin.x+strokeLength, origin.y+strokeLength))
    }

    private func drawRightChevronAt(origin origin: CGPoint, strokeLength: CGFloat) -> UIBezierPath {
        return drawChevron(leftTip: CGPointMake(origin.x-strokeLength, origin.y+strokeLength),
            head: CGPointMake(origin.x, origin.y),
            rightTip: CGPointMake(origin.x-strokeLength, origin.y-strokeLength))
    }

    private func drawChevron(leftTip leftTip: CGPoint, head: CGPoint, rightTip: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()

        // Left tip
        path.moveToPoint(leftTip)
        // Arrow head
        path.addLineToPoint(head)
        // Right tip
        path.addLineToPoint(rightTip)

        return path
    }
}
