// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage
import Shared

struct BackForwardCellViewModel {
    var site: Site
    var connectingForwards: Bool
    var connectingBackwards: Bool
    var strokeBackgroundColor = UIColor.white
    var isCurrentTab: Bool

    var cellTittle: String {
        return !site.title.isEmpty ? site.title : site.url
    }
}

class BackForwardTableViewCell: UITableViewCell, ThemeApplicable {
    private struct UX {
        static let faviconWidth = 29
        static let faviconPadding: CGFloat = 20
        static let labelPadding = 20
        static let borderSmall = 2
        static let borderBold = 5
        static let iconSize = CGSize(width: 23, height: 23)
        static let fontSize: CGFloat = 12.0
    }

    lazy var faviconView: UIImageView = .build { imageView in
        imageView.image = FaviconFetcher.defaultFavicon
        imageView.layer.cornerRadius = 6
        imageView.layer.borderWidth = 0.5
        imageView.layer.masksToBounds = true
        imageView.contentMode = .center
    }

    lazy var label: UILabel = .build { label in
        label.font = label.font.withSize(UX.fontSize)
    }

    var viewModel: BackForwardCellViewModel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    func setupLayout() {
        backgroundColor = UIColor.clear
        selectionStyle = .none

        contentView.addSubview(faviconView)
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            faviconView.heightAnchor.constraint(equalToConstant: CGFloat(UX.faviconWidth)),
            faviconView.widthAnchor.constraint(equalToConstant: CGFloat(UX.faviconWidth)),
            faviconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: CGFloat(UX.faviconPadding)),

            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: faviconView.trailingAnchor, constant: CGFloat(UX.labelPadding)),
            label.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: CGFloat(-UX.labelPadding))
        ])
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        var startPoint = CGPoint(
            x: rect.origin.x + UX.faviconPadding + CGFloat(Double(UX.faviconWidth) * 0.5) + safeAreaInsets.left,
            y: rect.origin.y + (viewModel.connectingForwards ?  0 : rect.size.height/2))
        var endPoint   = CGPoint(
            x: rect.origin.x + UX.faviconPadding + CGFloat(Double(UX.faviconWidth) * 0.5) + safeAreaInsets.left,
            y: rect.origin.y + rect.size.height - (viewModel.connectingBackwards  ? 0 : rect.size.height/2))

        // flip the x component if RTL
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            startPoint.x = rect.origin.x - startPoint.x + rect.size.width
            endPoint.x = rect.origin.x - endPoint.x + rect.size.width
        }

        context.saveGState()
        context.setLineCap(.square)
        context.setStrokeColor(viewModel.strokeBackgroundColor.cgColor)
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
        label.font = UIFont.systemFont(ofSize: UX.fontSize)
    }

    func configure(viewModel: BackForwardCellViewModel, theme: Theme) {
        self.viewModel = viewModel

        faviconView.setFavicon(forSite: viewModel.site) { [weak self] in
            if InternalURL.isValid(url: viewModel.site.tileURL) {
                self?.faviconView.image = UIImage(named: "faviconFox")
                self?.faviconView.image = self?.faviconView.image?.createScaled(UX.iconSize)
                return
            }

            self?.faviconView.image = self?.faviconView.image?.createScaled(UX.iconSize)
        }

        label.text = viewModel.cellTittle
        setNeedsLayout()
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        label.textColor = theme.colors.textPrimary
        viewModel.strokeBackgroundColor = theme.colors.layer5
    }
}
