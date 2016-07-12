/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct TwoLineCellUX {
    static let ImageSize: CGFloat = 25
    static let BorderViewMargin: CGFloat = 13
    static let BadgeSize: CGFloat = 16
    static let BadgeMargin: CGFloat = 16
    static let BorderFrameSize: CGFloat = 32
    static let TextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.black() : UIColor(rgb: 0x333333)
    static let DetailTextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGray() : UIColor.gray()
    static let DetailTextTopMargin: CGFloat = 5
}

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
        super.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(_textLabel)
        contentView.addSubview(_detailTextLabel)

        twoLineHelper.setUpViews(self, textLabel: textLabel!, detailTextLabel: detailTextLabel!, imageView: imageView!)

        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsMake(0, TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, 0, 0)
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
        separatorInset = UIEdgeInsetsMake(0, TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, 0, 0)
        twoLineHelper.setupDynamicFonts()
    }

    func setRightBadge(_ badge: UIImage?) {
        if let badge = badge {
            self.accessoryView = UIImageView(image: badge)
        } else {
            self.accessoryView = nil
        }
        twoLineHelper.hasRightBadge = badge != nil
    }

    func setLines(_ text: String?, detailText: String?) {
        twoLineHelper.setLines(text, detailText: detailText)
    }

    func mergeAccessibilityLabels(_ views: [AnyObject?]? = nil) {
        twoLineHelper.mergeAccessibilityLabels(views)
    }
}

class HistoryTableViewCell: TwoLineTableViewCell {
    let borderView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(borderView)
        separatorInset = UIEdgeInsetsMake(0, TwoLineCellUX.BorderFrameSize + 2 * TwoLineCellUX.BorderViewMargin, 0, 0)

        borderView.frame = CGRect(x: TwoLineCellUX.BorderViewMargin, y: TwoLineCellUX.BorderViewMargin, width: TwoLineCellUX.BorderFrameSize, height: TwoLineCellUX.BorderFrameSize)
        borderView.layer.borderWidth = 0.5
        borderView.layer.borderColor = UIColor.gray().cgColor

        twoLineHelper.hasBorderView = true

        twoLineHelper.setUpViews(self, textLabel: textLabel!, detailTextLabel: detailTextLabel!, imageView: imageView!)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()

        imageView!.center = borderView.center
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        separatorInset = UIEdgeInsetsMake(0, TwoLineCellUX.BorderFrameSize + 2 * TwoLineCellUX.BorderViewMargin, 0, 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        contentView.backgroundColor = UIColor.clear()
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

    func setLines(_ text: String?, detailText: String?) {
        twoLineHelper.setLines(text, detailText: detailText)
    }

    func mergeAccessibilityLabels(_ views: [AnyObject?]? = nil) {
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

    func mergeAccessibilityLabels(_ views: [AnyObject?]? = nil) {
        twoLineHelper.mergeAccessibilityLabels(views)
    }
}

private class TwoLineCellHelper {
    weak var container: UIView?
    var textLabel: UILabel!
    var detailTextLabel: UILabel!
    var imageView: UIImageView!
    var hasBorderView: Bool = false
    var hasRightBadge: Bool = false

    // TODO: Not ideal. We should figure out a better way to get this initialized.
    func setUpViews(_ container: UIView, textLabel: UILabel, detailTextLabel: UILabel, imageView: UIImageView) {
        self.container = container
        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
        self.imageView = imageView

        if let headerView = self.container as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = UIColor.clear()
        } else {
            self.container?.backgroundColor = UIColor.clear()
        }

        textLabel.textColor = TwoLineCellUX.TextColor
        detailTextLabel.textColor = TwoLineCellUX.DetailTextColor
        setupDynamicFonts()

        imageView.contentMode = .scaleAspectFill
    }

    func setupDynamicFonts() {
        textLabel.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        detailTextLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallHistoryPanel
    }

    func layoutSubviews() {
        guard let container = self.container else{
            return
        }
        let height = container.frame.height
        let textLeft = hasBorderView ? TwoLineCellUX.BorderFrameSize + 2 * TwoLineCellUX.BorderViewMargin : TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin
        let textLabelHeight = textLabel.intrinsicContentSize().height
        let detailTextLabelHeight = detailTextLabel.intrinsicContentSize().height
        var contentHeight = textLabelHeight
        if detailTextLabelHeight > 0 {
            contentHeight += detailTextLabelHeight + TwoLineCellUX.DetailTextTopMargin
        }

        let textRightInset: CGFloat = hasRightBadge ? (TwoLineCellUX.BadgeSize + TwoLineCellUX.BadgeMargin) : 0

        imageView.frame = CGRect(x: TwoLineCellUX.BorderViewMargin, y: (height - TwoLineCellUX.ImageSize) / 2, width: TwoLineCellUX.ImageSize, height: TwoLineCellUX.ImageSize)
        textLabel.frame = CGRect(x: textLeft, y: (height - contentHeight) / 2,
            width: container.frame.width - textLeft - TwoLineCellUX.BorderViewMargin - textRightInset, height: textLabelHeight)
        detailTextLabel.frame = CGRect(x: textLeft, y: textLabel.frame.maxY + TwoLineCellUX.DetailTextTopMargin,
            width: container.frame.width - textLeft - TwoLineCellUX.BorderViewMargin - textRightInset, height: detailTextLabelHeight)
    }

    func setLines(_ text: String?, detailText: String?) {
        if text?.isEmpty ?? true {
            textLabel.text = detailText
            detailTextLabel.text = nil
        } else {
            textLabel.text = text
            detailTextLabel.text = detailText
        }
    }

    func mergeAccessibilityLabels(_ labels: [AnyObject?]?) {
        let labels = labels ?? [textLabel, imageView, detailTextLabel]

        let label = labels.map({ (label: AnyObject?) -> AttributedString? in
            var label = label
            if let view = label as? UIView {
                label = view.value(forKey: "accessibilityLabel")
            }

            if let attrString = label as? AttributedString {
                return attrString
            } else if let string = label as? String {
                return AttributedString(string: string)
            } else {
                return nil
            }
        }).filter({
            $0 != nil
        }).reduce(NSMutableAttributedString(string: ""), combine: {
            if ($0.length > 0) {
                $0.append(AttributedString(string: ", "))
            }
            $0.append($1!)
            return $0
        })

        container?.isAccessibilityElement = true
        container?.setValue(AttributedString(attributedString: label), forKey: "accessibilityLabel")
    }
}
