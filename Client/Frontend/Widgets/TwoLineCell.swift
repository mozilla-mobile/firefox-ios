/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct TwoLineCellUX {
    static let ImageSize: CGFloat = 29
    static let ImageCornerRadius: CGFloat = 8
    static let BorderViewMargin: CGFloat = 16
    static let BadgeSize: CGFloat = 16
    static let BadgeMargin: CGFloat = 16
    static let BorderFrameSize: CGFloat = 32
    static let DetailTextTopMargin: CGFloat = 0
}

class TwoLineTableViewCell: UITableViewCell, Themeable {
    fileprivate let twoLineHelper = TwoLineCellHelper()

    let _textLabel = UILabel()
    let _detailTextLabel = UILabel()
    lazy var selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.theme.tableView.selectedBackground
        return view
    }()

    // Override the default labels with our own to disable default UITableViewCell label behaviours like dynamic type
    override var textLabel: UILabel? {
        return _textLabel
    }

    override var detailTextLabel: UILabel? {
        return _detailTextLabel
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(_textLabel)
        contentView.addSubview(_detailTextLabel)

        twoLineHelper.setUpViews(self, textLabel: textLabel!, detailTextLabel: detailTextLabel!, imageView: imageView!)

        indentationWidth = 0
        layoutMargins = .zero
        selectedBackgroundView = selectedView

        separatorInset = UIEdgeInsets(top: 0, left: TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, bottom: 0, right: 0)

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews(accessoryWidth: self.contentView.frame.origin.x)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.textLabel!.alpha = 1
        self.imageView!.alpha = 1
        self.selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin, bottom: 0, right: 0)
        twoLineHelper.setupDynamicFonts()
        applyTheme()
    }

    func applyTheme() {
        twoLineHelper.applyTheme()
    }

    // Save background color on UITableViewCell "select" because it disappears in the default behavior
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = imageView?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        imageView?.backgroundColor = color
    }

    // Save background color on UITableViewCell "select" because it disappears in the default behavior
    override func setSelected(_ selected: Bool, animated: Bool) {
        let color = imageView?.backgroundColor
        super.setSelected(selected, animated: animated)
        imageView?.backgroundColor = color
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

class SiteTableViewCell: TwoLineTableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews(accessoryWidth: self.contentView.frame.origin.x)
    }
}

class TwoLineHeaderFooterView: UITableViewHeaderFooterView, Themeable {
    fileprivate let twoLineHelper = TwoLineCellHelper()
    fileprivate let bordersHelper = ThemedHeaderFooterViewBordersHelper()

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
        bordersHelper.initBorders(view: self)
        setDefaultBordersValues()

        contentView.addSubview(_textLabel)
        contentView.addSubview(_detailTextLabel)
        contentView.addSubview(imageView)

        layoutMargins = .zero

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        twoLineHelper.applyTheme()
        bordersHelper.applyTheme()
    }

    func showBorder(for location: ThemedHeaderFooterViewBordersHelper.BorderLocation, _ show: Bool) {
        bordersHelper.showBorder(for: location, show)
    }

    func setDefaultBordersValues() {
        bordersHelper.showBorder(for: .top, true)
        bordersHelper.showBorder(for: .bottom, true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        twoLineHelper.setUpViews(self, textLabel: _textLabel, detailTextLabel: _detailTextLabel, imageView: imageView)
        setDefaultBordersValues()
        applyTheme()
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
    var hasRightBadge: Bool = false

    // TODO: Not ideal. We should figure out a better way to get this initialized.
    func setUpViews(_ container: UIView, textLabel: UILabel, detailTextLabel: UILabel, imageView: UIImageView) {
        self.container = container
        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
        self.imageView = imageView

        setupDynamicFonts()

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 6 //hmm
        imageView.layer.masksToBounds = true
    }

    func applyTheme() {
        if let headerView = self.container as? UITableViewHeaderFooterView {
            headerView.contentView.backgroundColor = UIColor.clear
        } else {
            self.container?.backgroundColor = UIColor.clear
        }

        textLabel.textColor = UIColor.theme.tableView.rowText
        detailTextLabel.textColor = UIColor.theme.tableView.rowDetailText
    }

    func setupDynamicFonts() {
        textLabel.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        detailTextLabel.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
    }

    func layoutSubviews(accessoryWidth: CGFloat = 0) {
        guard let container = self.container else {
            return
        }
        let height = container.frame.height
        let textLeft = TwoLineCellUX.ImageSize + 2 * TwoLineCellUX.BorderViewMargin
        let textLabelHeight = textLabel.intrinsicContentSize.height
        let detailTextLabelHeight = detailTextLabel.intrinsicContentSize.height
        var contentHeight = textLabelHeight
        if detailTextLabelHeight > 0 {
            contentHeight += detailTextLabelHeight + TwoLineCellUX.DetailTextTopMargin
        }

        let textRightInset: CGFloat = hasRightBadge ? (TwoLineCellUX.BadgeSize + TwoLineCellUX.BadgeMargin) : 0

        textLabel.frame = CGRect(x: textLeft, y: (height - contentHeight) / 2,
                                 width: container.frame.width - textLeft - TwoLineCellUX.BorderViewMargin - textRightInset, height: textLabelHeight)
        detailTextLabel.frame = CGRect(x: textLeft, y: textLabel.frame.maxY + TwoLineCellUX.DetailTextTopMargin,
                                       width: container.frame.width - textLeft - TwoLineCellUX.BorderViewMargin - textRightInset, height: detailTextLabelHeight)

        // Like the comment above, this is not ideal. This code should probably be refactored to use autolayout. That will remove a lot of the pixel math and remove code duplication.

        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            imageView.frame = CGRect(x: TwoLineCellUX.BorderViewMargin, y: (height - TwoLineCellUX.ImageSize) / 2, width: TwoLineCellUX.ImageSize, height: TwoLineCellUX.ImageSize)
        } else {
            imageView.frame = CGRect(x: container.frame.width - TwoLineCellUX.ImageSize - TwoLineCellUX.BorderViewMargin, y: (height - TwoLineCellUX.ImageSize) / 2, width: TwoLineCellUX.ImageSize, height: TwoLineCellUX.ImageSize)

            textLabel.frame = textLabel.frame.offsetBy(dx: -(TwoLineCellUX.ImageSize + TwoLineCellUX.BorderViewMargin - textRightInset), dy: 0)
            detailTextLabel.frame = detailTextLabel.frame.offsetBy(dx: -(TwoLineCellUX.ImageSize + TwoLineCellUX.BorderViewMargin - textRightInset), dy: 0)

            // If the cell has an accessory, shift them all to the left even more. Only required on RTL.
            if accessoryWidth != 0 {
                imageView.frame = imageView.frame.offsetBy(dx: -accessoryWidth, dy: 0)
                textLabel.frame = textLabel.frame.offsetBy(dx: -accessoryWidth, dy: 0)
                detailTextLabel.frame = detailTextLabel.frame.offsetBy(dx: -accessoryWidth, dy: 0)
            }
        }
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

        let label = labels.map({ (label: AnyObject?) -> NSAttributedString? in
            var label = label
            if let view = label as? UIView {
                label = view.value(forKey: "accessibilityLabel") as (AnyObject?)
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
        }).reduce(NSMutableAttributedString(string: ""), {
            if $0.length > 0 {
                $0.append(NSAttributedString(string: ", "))
            }
            $0.append($1!)
            return $0
        })

        container?.isAccessibilityElement = true
        container?.setValue(NSAttributedString(attributedString: label), forKey: "accessibilityLabel")
    }
}
