import Foundation
import SnapKit

class Toolbar : UIView {
    var drawTopBorder = false
    var drawBottomBorder = false
    var drawSeperators = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear()

        // Allow the view to redraw itself on rotation changes
        contentMode = UIViewContentMode.redraw
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawLine(_ context: CGContext, width: CGFloat, start: CGPoint, end: CGPoint) {
        context.setStrokeColor(UIConstants.BorderColor.cgColor)
        context.setLineWidth(width * (1 / UIScreen.main().scale) )
        context.moveTo(x: start.x, y: start.y)
        context.addLineTo(x: end.x, y: end.y)
        context.strokePath()
    }

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            if drawTopBorder {
                drawLine(context, width: 1, start: CGPoint(x: 0, y: 0), end: CGPoint(x: frame.width, y: 0))
            }

            if drawBottomBorder {
                drawLine(context, width: 1, start: CGPoint(x: 0, y: frame.height), end: CGPoint(x: frame.width, y: frame.height))
            }

            if drawSeperators {
                var skippedFirst = false
                for view in subviews {
                    if skippedFirst {
                        let frame = view.frame
                        drawLine(context,
                            width: 0.5,
                            start: CGPoint(x: floor(frame.origin.x), y: 0),
                            end: CGPoint(x: floor(frame.origin.x), y: self.frame.height))
                    } else {
                        skippedFirst = true
                    }
                }
            }
        }
    }

    func addButtons(_ buttons: UIButton...) {
        for button in buttons {
            button.setTitleColor(UIColor.black(), for: UIControlState())
            button.setTitleColor(UIColor.gray(), for: UIControlState.disabled)
            button.imageView?.contentMode = UIViewContentMode.scaleAspectFit
            addSubview(button)
        }
    }

    override func updateConstraints() {
        var prev: UIView? = nil
        for view in self.subviews {
            view.snp_remakeConstraints { make in
                if let prev = prev {
                    make.left.equalTo(prev.snp_right)
                } else {
                    make.left.equalTo(self)
                }
                prev = view

                make.centerY.equalTo(self)
                make.height.equalTo(UIConstants.ToolbarHeight)
                make.width.equalTo(self).dividedBy(self.subviews.count)
            }
        }
        super.updateConstraints()
    }
}
