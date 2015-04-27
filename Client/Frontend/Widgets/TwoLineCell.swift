/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let ImageSize: CGFloat = 24
private let ImageMargin: CGFloat = 20
private let TextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x333333)
private let DetailTextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : UIColor.grayColor()

class TwoLineTableViewCell: UITableViewCell {
    private let twoLineHelper = TwoLineCellHelper()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)

        twoLineHelper.setUpViews(self, textLabel: textLabel!, detailTextLabel: detailTextLabel!, imageView: imageView!)

        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsMake(0, ImageSize + 2 * ImageMargin, 0, 0)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }

    func setLines(text: String?, detailText: String?) {
        twoLineHelper.setLines(text, detailText: detailText)
    }
}

class TwoLineCollectionViewCell: UICollectionViewCell {
    private let twoLineHelper = TwoLineCellHelper()
    let textLabel = UILabel()
    let detailTextLabel = UILabel()
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        twoLineHelper.setUpViews(self, textLabel: textLabel, detailTextLabel: detailTextLabel, imageView: imageView)

        contentView.addSubview(textLabel)
        contentView.addSubview(detailTextLabel)
        contentView.addSubview(imageView)

        backgroundColor = UIColor.clearColor()
        layoutMargins = UIEdgeInsetsZero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }

    func setLines(text: String?, detailText: String?) {
        twoLineHelper.setLines(text, detailText: detailText)
    }
}

class TwoLineHeaderFooterView: UITableViewHeaderFooterView {
    private let twoLineHelper = TwoLineCellHelper()

    // UITableViewHeaderFooterView includes textLabel and detailTextLabel, so we can't override
    // them.  Unfortunately, they're also used in ways that interfere with us just using them: I get
    // hard crashes in layout if I just use them; it seems there's a battle over adding to the
    // contentView.  So we add our own members, and cover up the other ones.
    let _textLabel = UILabel()
    let _detailTextLabel = UILabel()

    let imageView = UIImageView()

    // Yes, this is strange.
    override var textLabel: UILabel {
        return _textLabel
    }

    // Yes, this is strange.
    override var detailTextLabel: UILabel {
        return _detailTextLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        twoLineHelper.setUpViews(self, textLabel: _textLabel, detailTextLabel: _detailTextLabel, imageView: imageView)

        contentView.addSubview(_textLabel)
        contentView.addSubview(_detailTextLabel)
        contentView.addSubview(imageView)

        layoutMargins = UIEdgeInsetsZero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }
}

private class TwoLineCellHelper {
    var container: UIView!
    var textLabel: UILabel!
    var detailTextLabel: UILabel!
    var imageView: UIImageView!

    // TODO: Not ideal. We should figure out a better way to get this initialized.
    func setUpViews(container: UIView, textLabel: UILabel, detailTextLabel: UILabel, imageView: UIImageView) {
        self.container = container
        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
        self.imageView = imageView

        self.container.backgroundColor = UIColor.clearColor()

        textLabel.font = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue-Medium", size: 14)
        textLabel.textColor = TextColor

        detailTextLabel.font = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 10)
        detailTextLabel.textColor = DetailTextColor

        imageView.contentMode = .ScaleAspectFill
    }

    func layoutSubviews() {
        let height = container.frame.height
        let textLeft = ImageSize + 2 * ImageMargin
        let textLabelHeight = textLabel.intrinsicContentSize().height
        let detailTextLabelHeight = detailTextLabel.intrinsicContentSize().height
        let contentHeight = textLabelHeight + detailTextLabelHeight + 1
        imageView.frame = CGRectMake(ImageMargin, (height - ImageSize) / 2, ImageSize, ImageSize)
        textLabel.frame = CGRectMake(textLeft, (height - contentHeight) / 2,
            container.frame.width - textLeft - ImageMargin, textLabelHeight)
        detailTextLabel.frame = CGRectMake(textLeft, textLabel.frame.maxY + 5,
            container.frame.width - textLeft - ImageMargin, detailTextLabelHeight)
    }

    func setLines(text: String?, detailText: String?) {
        if text?.isEmpty ?? true {
            textLabel.text = detailText
            detailTextLabel.text = nil
        } else {
            textLabel.text = text
            detailTextLabel.text = detailText
        }
    }
}
