/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/**
 * creates a view that consists of an image and a title.
 * the image view is displayed at the center top of the
 **/
public class MenuItemView: UIControl {

    private(set) public var imageView: UIImageView
    private(set) public var titleLabel: UILabel

    private var previousLocation: CGPoint?
    public init() {
        imageView = UIImageView()
        titleLabel = UILabel()

        super.init(frame: CGRectZero)

        self.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: UILayoutConstraintAxis.Vertical)

        self.addSubview(imageView)

        self.addSubview(titleLabel)

        imageView.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self.snp_centerYWithinMargins)
        }

        titleLabel.snp_makeConstraints { make in
            make.top.equalTo(imageView.snp_bottom).offset(2.5).priorityLow()
            make.left.right.equalTo(self)
            make.bottom.equalTo(self).offset(-5)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        imageView.image = nil
        titleLabel.text = nil

        guard let recognisers = gestureRecognizers else { return }
        for recogniser in recognisers {
            if recogniser is UILongPressGestureRecognizer {
                self.removeGestureRecognizer(recogniser)
            }
        }
    }

    public func setTitle(title: String) {
        titleLabel.text = title
    }

    public func setImage(image: UIImage) {
        imageView.image = image
    }

    public func setHighlightedImage(image: UIImage) {
        imageView.highlightedImage = image
    }

    public override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        super.beginTrackingWithTouch(touch, withEvent: event)
        // work out whether or not the touch happened inside this item
        // return true if so, false otherwise
        if !self.bounds.contains(touch.locationInView(self)) {
            return false
        }

        imageView.highlighted = true
        return true
    }

    public override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        super.continueTrackingWithTouch(touch, withEvent: event)
        if !self.bounds.contains(touch.locationInView(self)) {
            imageView.highlighted = false
            return false
        }
        return true
    }

    public override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        super.endTrackingWithTouch(touch, withEvent: event)
        imageView.highlighted = false
    }
}
