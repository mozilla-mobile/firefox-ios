// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage
import Shared
import Account
import SiteImageView

struct BackForwardCellViewModel {
    var site: Site
    var connectingForwards: Bool
    var connectingBackwards: Bool
    var isCurrentTab: Bool
    var strokeBackgroundColor: UIColor

    var cellTittle: String {
        return !site.title.isEmpty ? site.title : site.url
    }
}

class BackForwardTableViewCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let faviconWidth: CGFloat = 29
        static let faviconPadding: CGFloat = 20
        static let faviconCornerRadius: CGFloat = 6
        static let labelPadding: CGFloat = 20
        static let iconSize = CGSize(width: 23, height: 23)
        static let fontSize: CGFloat = 12
    }

    private lazy var faviconView: FaviconImageView = .build { _ in }

    lazy var label: UILabel = .build { _ in }

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
            faviconView.heightAnchor.constraint(equalToConstant: UX.faviconWidth),
            faviconView.widthAnchor.constraint(equalToConstant: UX.faviconWidth),
            faviconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                 constant: UX.faviconPadding),

            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: faviconView.trailingAnchor, constant: UX.labelPadding),
            label.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -UX.labelPadding)
        ])
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        var startPoint = CGPoint(
            x: rect.origin.x + UX.faviconPadding + UX.faviconWidth * 0.5 + safeAreaInsets.left,
            y: rect.origin.y + (viewModel.connectingForwards ?  0 : rect.size.height/2))
        var endPoint   = CGPoint(
            x: rect.origin.x + UX.faviconPadding + UX.faviconWidth * 0.5 + safeAreaInsets.left,
            y: rect.origin.y + rect.size.height - (viewModel.connectingBackwards ? 0 : rect.size.height/2))

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
        label.text = nil
    }

    func configure(viewModel: BackForwardCellViewModel, theme: Theme) {
        self.viewModel = viewModel

        if let url = URL(string: viewModel.site.url, invalidCharacters: false),
           InternalURL(url)?.isAboutHomeURL == true {
            faviconView.manuallySetImage(UIImage(named: ImageIdentifiers.firefoxFavicon) ?? UIImage())
        } else {
            faviconView.setFavicon(FaviconImageViewModel(siteURLString: viewModel.site.url,
                                                         faviconCornerRadius: UX.faviconCornerRadius))
        }

        label.text = viewModel.cellTittle
        if viewModel.isCurrentTab {
            label.font = FXFontStyles.Bold.caption1.scaledFont()
        } else {
            label.font = FXFontStyles.Regular.caption1.scaledFont()
        }
        setNeedsLayout()
        applyTheme(theme: theme)
    }

    func applyTheme(theme: Theme) {
        label.textColor = theme.colors.textPrimary
        viewModel.strokeBackgroundColor = theme.colors.borderPrimary
        faviconView.layer.borderColor = theme.colors.borderPrimary.cgColor
        faviconView.tintColor = theme.colors.iconPrimary
    }
}
