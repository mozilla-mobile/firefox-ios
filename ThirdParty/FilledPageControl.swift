//  FilledPageControl
//
//  Copyright (c) 2016 Kyle Zaragoza <popwarsweet@gmail.com>
//  MIT License

import UIKit

@IBDesignable public class FilledPageControl: UIView {

    // MARK: - PageControl

    @IBInspectable public var pageCount: Int = 0 {
        didSet {
            updateNumberOfPages(pageCount)
        }
    }
    @IBInspectable public var progress: CGFloat = 0 {
        didSet {
            updateActivePageIndicatorMasks(progress)
        }
    }
    public var currentPage: Int {
        return Int(round(progress))
    }


    // MARK: - Appearance

    override public var tintColor: UIColor! {
        didSet {
            inactiveLayers.forEach() { $0.backgroundColor = tintColor.CGColor }
        }
    }
    @IBInspectable public var inactiveRingWidth: CGFloat = 1 {
        didSet {
            updateActivePageIndicatorMasks(progress)
        }
    }
    @IBInspectable public var indicatorPadding: CGFloat = 10 {
        didSet {
            layoutPageIndicators(inactiveLayers)
        }
    }
    @IBInspectable public var indicatorRadius: CGFloat = 5 {
        didSet {
            layoutPageIndicators(inactiveLayers)
        }
    }

    private var indicatorDiameter: CGFloat {
        return indicatorRadius * 2
    }
    private var inactiveLayers = [CALayer]()


    // MARK: - State Update

    private func updateNumberOfPages(count: Int) {
        // no need to update
        guard count != inactiveLayers.count else { return }
        // reset current layout
        inactiveLayers.forEach() { $0.removeFromSuperlayer() }
        inactiveLayers = [CALayer]()
        // add layers for new page count
        inactiveLayers = 0.stride(to:count, by:1).map() { _ in
            let layer = CALayer()
            layer.backgroundColor = self.tintColor.CGColor
            self.layer.addSublayer(layer)
            return layer
        }
        layoutPageIndicators(inactiveLayers)
        updateActivePageIndicatorMasks(progress)
        self.invalidateIntrinsicContentSize()
    }


    // MARK: - Layout

    private func updateActivePageIndicatorMasks(progress: CGFloat) {
        // ignore if progress is outside of page indicators' bounds
        guard progress >= 0 && progress <= CGFloat(pageCount - 1) else { return }

        // mask rect w/ default stroke width
        let insetRect = CGRectInset(
            CGRect(x: 0, y: 0, width: indicatorDiameter, height: indicatorDiameter),
            inactiveRingWidth, inactiveRingWidth)
        let leftPageFloat = trunc(progress)
        let leftPageInt = Int(progress)

        // inset right moving page indicator
        let spaceToMove = insetRect.width / 2
        let percentPastLeftIndicator = progress - leftPageFloat
        let additionalSpaceToInsetRight = spaceToMove * percentPastLeftIndicator
        let closestRightInsetRect = CGRectInset(insetRect, additionalSpaceToInsetRight, additionalSpaceToInsetRight)

        // inset left moving page indicator
        let additionalSpaceToInsetLeft = (1 - percentPastLeftIndicator) * spaceToMove
        let closestLeftInsetRect = CGRectInset(insetRect, additionalSpaceToInsetLeft, additionalSpaceToInsetLeft)

        // adjust masks
        for (idx, layer) in inactiveLayers.enumerate() {
            let maskLayer = CAShapeLayer()
            maskLayer.fillRule = kCAFillRuleEvenOdd

            let boundsPath = UIBezierPath(rect: layer.bounds)
            let circlePath: UIBezierPath
            if leftPageInt == idx {
                circlePath = UIBezierPath(ovalInRect: closestLeftInsetRect)
            } else if leftPageInt + 1 == idx {
                circlePath = UIBezierPath(ovalInRect: closestRightInsetRect)
            } else {
                circlePath = UIBezierPath(ovalInRect: insetRect)
            }
            boundsPath.appendPath(circlePath)
            maskLayer.path = boundsPath.CGPath
            layer.mask = maskLayer
        }
    }

    private func layoutPageIndicators(layers: [CALayer]) {
        let layerDiameter = indicatorRadius * 2
        var layerFrame = CGRect(x: 0, y: 0, width: layerDiameter, height: layerDiameter)
        layers.forEach() { layer in
            layer.cornerRadius = self.indicatorRadius
            layer.frame = layerFrame
            layerFrame.origin.x += layerDiameter + indicatorPadding
        }
    }

    override public func intrinsicContentSize() -> CGSize {
        return sizeThatFits(CGSize.zero)
    }

    override public func sizeThatFits(size: CGSize) -> CGSize {
        let layerDiameter = indicatorRadius * 2
        return CGSize(width: CGFloat(inactiveLayers.count) * layerDiameter + CGFloat(inactiveLayers.count - 1) * indicatorPadding,
                      height: layerDiameter)
    }
}