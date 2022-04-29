// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage
import Shared

class BackForwardTableViewCell: UITableViewCell {

    private struct BackForwardViewCellUX {
        static let bgColor = UIColor.Photon.Grey50
        static let faviconWidth = 29
        static let faviconPadding: CGFloat = 20
        static let labelPadding = 20
        static let borderSmall = 2
        static let borderBold = 5
        static let IconSize = 23
        static let fontSize: CGFloat = 12.0
        static let textColor = UIColor.Photon.Grey80
    }
    lazy var faviconView: UIImageView = .build { imageView in
        imageView.image = FaviconFetcher.defaultFavicon
        imageView.backgroundColor = UIColor.Photon.White100
        imageView.layer.cornerRadius = 6
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
        imageView.layer.masksToBounds = true
        imageView.contentMode = .center
    }

    lazy var label: UILabel = .build { label in
        label.text = " "
        label.font = label.font.withSize(BackForwardViewCellUX.fontSize)
        label.textColor = UIColor.theme.tabTray.tabTitleText
    }

    var connectingForwards = true
    var connectingBackwards = true

    var isCurrentTab = false {
        didSet {
            if isCurrentTab {
                label.font = UIFont.boldSystemFont(ofSize: BackForwardViewCellUX.fontSize)
            }
        }
    }

    var site: Site? {
        didSet {
            if let s = site {
                faviconView.setFavicon(forSite: s) { [weak self] in
                    if InternalURL.isValid(url: s.tileURL) {
                        self?.faviconView.image = UIImage(named: "faviconFox")
                        self?.faviconView.image = self?.faviconView.image?.createScaled(CGSize(width: BackForwardViewCellUX.IconSize, height: BackForwardViewCellUX.IconSize))
                        self?.faviconView.backgroundColor = UIColor.Photon.White100
                        return
                    }

                    self?.faviconView.image = self?.faviconView.image?.createScaled(CGSize(width: BackForwardViewCellUX.IconSize, height: BackForwardViewCellUX.IconSize))
                    if self?.faviconView.backgroundColor == .clear {
                        self?.faviconView.backgroundColor = .white
                    }
                }
                var title = s.title
                if title.isEmpty {
                    title = s.url
                }
                label.text = title
                setNeedsLayout()
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        selectionStyle = .none

        contentView.addSubview(faviconView)
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            faviconView.heightAnchor.constraint(equalToConstant: CGFloat(BackForwardViewCellUX.faviconWidth)),
            faviconView.widthAnchor.constraint(equalToConstant: CGFloat(BackForwardViewCellUX.faviconWidth)),
            faviconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: CGFloat(BackForwardViewCellUX.faviconPadding)),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: faviconView.trailingAnchor, constant: CGFloat(BackForwardViewCellUX.labelPadding)),
            label.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: CGFloat(-BackForwardViewCellUX.labelPadding))
        ])

    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        var startPoint = CGPoint(x: rect.origin.x + BackForwardViewCellUX.faviconPadding + CGFloat(Double(BackForwardViewCellUX.faviconWidth)*0.5) + safeAreaInsets.left,
                                     y: rect.origin.y + (connectingForwards ?  0 : rect.size.height/2))
        var endPoint   = CGPoint(x: rect.origin.x + BackForwardViewCellUX.faviconPadding + CGFloat(Double(BackForwardViewCellUX.faviconWidth)*0.5) + safeAreaInsets.left,
                                     y: rect.origin.y + rect.size.height - (connectingBackwards  ? 0 : rect.size.height/2))

        // flip the x component if RTL
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            startPoint.x = rect.origin.x - startPoint.x + rect.size.width
            endPoint.x = rect.origin.x - endPoint.x + rect.size.width
        }

        context.saveGState()
        context.setLineCap(.square)
        context.setStrokeColor(BackForwardViewCellUX.bgColor.cgColor)
        context.setLineWidth(1.0)
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()
        context.restoreGState()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = UIColor(white: 0, alpha: 0.1)
        } else {
            self.backgroundColor = UIColor.clear
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        connectingForwards = true
        connectingBackwards = true
        isCurrentTab = false
        label.font = UIFont.systemFont(ofSize: BackForwardViewCellUX.fontSize)
    }
}
