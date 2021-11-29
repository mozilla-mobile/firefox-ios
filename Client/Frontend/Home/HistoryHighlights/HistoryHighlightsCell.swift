// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private struct RecentlyVisitedCellUX {
    static let generalCornerRadius: CGFloat = 10
    static let heroImageDimension: CGFloat = 24
}

struct RecentlyVisitedCellOptions {
    let title: String
    let heroImage: UIImage?
    let corners: UIRectCorner?
    let hideBottomLine: Bool
    let isFillerCell: Bool

    init(title: String,
         shouldHideBottomLine: Bool,
         with corners: UIRectCorner? = nil,
         and heroImage: UIImage? = nil,
         andIsFillerCell: Bool) {

        self.title = title
        self.hideBottomLine = shouldHideBottomLine
        self.corners = corners
        self.heroImage = heroImage
        self.isFillerCell = andIsFillerCell
    }

    init(shouldHideBottomLine: Bool,
         with corners: UIRectCorner? = nil,
         andIsFillerCell: Bool) {

        self.init(title: "",
                  shouldHideBottomLine: shouldHideBottomLine,
                  with: corners,
                  and: nil,
                  andIsFillerCell: andIsFillerCell)
    }
}

/// A cell used in FxHomeScreen's History Highlights section.
class HistoryHighlightsCell: UICollectionViewCell, ReusableCell {

    // MARK: - UI Elements
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = RecentlyVisitedCellUX.generalCornerRadius
        imageView.image = UIImage.templateImageNamed("recently_closed")
    }

    let itemTitle: UILabel = .build { label in
        // Limiting max size to accomodate for non-self-sizing parent cell.
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   maxSize: 23)
        label.adjustsFontForContentSizeCategory = true
    }

    let itemDescription: UILabel = .build { label in
        // Limiting max size to accomodate for non-self-sizing parent cell.
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: 18)
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [itemTitle, itemDescription])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        stack.alignment = .leading

        return stack
    }()

    let bottomLine: UIView = .build { line in
        line.isHidden = false
    }

    var isFillerCell: Bool = false {
        didSet {
            itemTitle.isHidden = isFillerCell
            heroImage.isHidden = isFillerCell
            bottomLine.isHidden = isFillerCell
//            self.isUserInteractionEnabled = isFillerCell
        }
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        applyTheme()
        setupObservers()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public methods
    public func updateCell(with options: RecentlyVisitedCellOptions) {
        itemTitle.text = options.title
        bottomLine.alpha = options.hideBottomLine ? 0 : 1
        isFillerCell = options.isFillerCell
        itemDescription.isHidden = itemDescription.text?.isEmpty ?? false

        if let corners = options.corners {
            contentView.addRoundedCorners([corners], radius: RecentlyVisitedCellUX.generalCornerRadius)
        }
    }

    // MARK: - Setup Helper methods
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }

    private func setupLayout() {
        contentView.addSubview(heroImage)
        contentView.addSubview(textStack)
        contentView.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImage.heightAnchor.constraint(equalToConstant: RecentlyVisitedCellUX.heroImageDimension),
            heroImage.widthAnchor.constraint(equalToConstant: RecentlyVisitedCellUX.heroImageDimension),
            heroImage.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
            bottomLine.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),
            bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Nofications
    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}

extension HistoryHighlightsCell: Themeable {
    func applyTheme() {
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        heroImage.tintColor = UIColor.theme.homePanel.recentlyVisitedCellGroupImage
        bottomLine.backgroundColor = UIColor.theme.homePanel.recentlyVisitedCellBottomLine
    }
}

