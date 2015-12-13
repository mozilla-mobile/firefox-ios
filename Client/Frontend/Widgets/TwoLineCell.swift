/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let ImageSize: CGFloat = 24
private let ImageMargin: CGFloat = 12
private let TextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x333333)
private let DetailTextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : UIColor.grayColor()
private let DetailTextTopMargin = CGFloat(5)

class TwoLineTableViewCell: UITableViewCell {
    private let twoLineHelper = TwoLineCellHelper()

    let _textLabel = UILabel()
    let _detailTextLabel = UILabel()

    // Override the default labels with our own to disable default UITableViewCell label behaviours like dynamic type
    override var textLabel: UILabel? {
        return _textLabel
    }

    override var detailTextLabel: UILabel? {
        return _detailTextLabel
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(_textLabel)
        contentView.addSubview(_detailTextLabel)

        twoLineHelper.setUpViews(self, textLabel: textLabel!, detailTextLabel: detailTextLabel!, imageView: imageView!)

        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsMake(0, ImageSize + 2 * ImageMargin, 0, 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        twoLineHelper.setupDynamicFonts()
    }

    func setLines(text: String?, detailText: String?) {
        twoLineHelper.setLines(text, detailText: detailText)
    }

    func mergeAccessibilityLabels(views: [AnyObject?]? = nil) {
        twoLineHelper.mergeAccessibilityLabels(views)
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

        contentView.backgroundColor = UIColor.clearColor()
        layoutMargins = UIEdgeInsetsZero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        twoLineHelper.setupDynamicFonts()
    }

    func setLines(text: String?, detailText: String?) {
        twoLineHelper.setLines(text, detailText: detailText)
    }

    func mergeAccessibilityLabels(views: [AnyObject?]? = nil) {
        twoLineHelper.mergeAccessibilityLabels(views)
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
    override var textLabel: UILabel? {
        return _textLabel
    }

    // Yes, this is strange.
    override var detailTextLabel: UILabel? {
        return _detailTextLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        twoLineHelper.setUpViews(self, textLabel: _textLabel, detailTextLabel: _detailTextLabel, imageView: imageView)

        contentView.addSubview(_textLabel)
        contentView.addSubview(_detailTextLabel)
        contentView.addSubview(imageView)

        layoutMargins = UIEdgeInsetsZero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        twoLineHelper.setupDynamicFonts()
    }

    func mergeAccessibilityLabels(views: [AnyObject?]? = nil) {
        twoLineHelper.mergeAccessibilityLabels(views)
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

        if let headerView = self.container as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = UIColor.clearColor()
        } else {
            self.container.backgroundColor = UIColor.clearColor()
        }

        textLabel.textColor = TextColor
        detailTextLabel.textColor = DetailTextColor
        setupDynamicFonts()

        imageView.contentMode = .ScaleAspectFill
    }

    func setupDynamicFonts() {
        textLabel.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.DefaultMediumFontSize, weight: UIFontWeightMedium)
        detailTextLabel.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.DefaultSmallFontSize, weight: UIFontWeightRegular)
    }

    func layoutSubviews() {
        let height = container.frame.height
        let textLeft = ImageSize + 2 * ImageMargin
        let textLabelHeight = textLabel.intrinsicContentSize().height
        let detailTextLabelHeight = detailTextLabel.intrinsicContentSize().height
        var contentHeight = textLabelHeight
        if detailTextLabelHeight > 0 {
            contentHeight += detailTextLabelHeight + DetailTextTopMargin
        }
        
        imageView.frame = CGRectMake(ImageMargin, (height - ImageSize) / 2, ImageSize, ImageSize)
        textLabel.frame = CGRectMake(textLeft, (height - contentHeight) / 2,
            container.frame.width - textLeft - ImageMargin, textLabelHeight)
        detailTextLabel.frame = CGRectMake(textLeft, textLabel.frame.maxY + DetailTextTopMargin,
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

    func mergeAccessibilityLabels(labels: [AnyObject?]?) {
        let labels = labels ?? [textLabel, imageView, detailTextLabel]

        let label = labels.map({ (var label: AnyObject?) -> NSAttributedString? in
            if let view = label as? UIView {
                label = view.valueForKey("accessibilityLabel")
            }

            if let attrString = label as? NSAttributedString {
                return attrString
            } else if let string = label as? String {
                return NSAttributedString(string: string)
            } else {
                return nil
            }
        }).filter({
            $0 != nil
        }).reduce(NSMutableAttributedString(string: ""), combine: {
            if ($0.length > 0) {
                $0.appendAttributedString(NSAttributedString(string: ", "))
            }
            $0.appendAttributedString($1!)
            return $0
        })

        container.isAccessibilityElement = true
        container.setValue(NSAttributedString(attributedString: label), forKey: "accessibilityLabel")
    }
}
