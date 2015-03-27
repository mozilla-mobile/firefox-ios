import Foundation
import Snap

class Toolbar : UIView {
    var drawTopBorder = false
    var drawBottomBorder = false
    var drawSeperators = false

    override init() {
        super.init()
        self.backgroundColor = UIColor.clearColor()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawLine(context: CGContextRef, start: CGPoint, end: CGPoint) {
        CGContextSetStrokeColorWithColor(context, UIColor.darkGrayColor().CGColor)
        CGContextSetLineWidth(context, 1)
        CGContextMoveToPoint(context, start.x, start.y)
        CGContextAddLineToPoint(context, end.x, end.y)
        CGContextStrokePath(context)
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        if drawTopBorder {
            drawLine(context, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
        }

        if drawBottomBorder {
            drawLine(context, start: CGPoint(x: 0, y: frame.height), end: CGPoint(x: frame.width, y: frame.height))
        }

        if drawSeperators {
            var skippedFirst = false
            for view in subviews {
                if let view = view as? UIView {
                    if skippedFirst {
                        let frame = view.frame
                        drawLine(context,
                            start: CGPoint(x: frame.origin.x, y: frame.origin.y),
                            end: CGPoint(x: frame.origin.x, y: frame.origin.y + view.frame.height))
                    } else {
                        skippedFirst = true
                    }
                }
            }
        }
    }

    func addButtons(buttons: UIButton...) {
        for button in buttons {
            button.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            button.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
            button.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            addSubview(button)
        }
    }

    override func updateConstraints() {
        var prev: UIView? = nil
        for view in self.subviews {
            if let view = view as? UIView {
                view.snp_remakeConstraints { make in
                    if let prev = prev {
                        make.left.equalTo(prev.snp_right)
                    } else {
                        make.left.equalTo(self)
                    }
                    prev = view

                    make.centerY.equalTo(self)
                    make.height.equalTo(AppConstants.ToolbarHeight)
                    make.width.equalTo(self).dividedBy(self.subviews.count)
                }
            }
        }
        super.updateConstraints()
    }
}