// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Every bullet in one card as a single attributed string, so the dots scale and wrap with the text.
final class WebCompatPreviewBulletListCell: UICollectionViewListCell, ThemeApplicable, ReusableCell, Notifiable {
    private var bullets: [WebCompatReportPreviewViewModel.Bullet] = []
    /// Colours are attributes, not `textColor`, so a theme change has to re-render.
    private var theme: Theme?

    private lazy var bulletsLabel: UILabel = .build { label in
        label.numberOfLines = 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let horizontalInset = WebCompatReporterUX.Card.contentInset
        let verticalInset = WebCompatReporterUX.Card.verticalInset
        contentView.addSubview(bulletsLabel)
        NSLayoutConstraint.activate([
            bulletsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalInset),
            bulletsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalInset),
            bulletsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalInset),
            bulletsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -verticalInset)
        ])
    }

    func configure(bullets: [WebCompatReportPreviewViewModel.Bullet], accessibilityIdentifier: String) {
        self.bullets = bullets
        self.accessibilityIdentifier = accessibilityIdentifier
        isAccessibilityElement = true
        // Otherwise VoiceOver announces the dot attachment before every line.
        accessibilityLabel = bullets.map { $0.text }.joined(separator: ". ")
        renderBullets()
    }

    /// Attributed text ignores `adjustsFontForContentSizeCategory`, so font and indent are
    /// re-resolved on every render.
    private func renderBullets() {
        let font = FXFontStyles.Regular.footnote.scaledFont()
        let indent = UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Preview.bulletIndent)
        let paragraphStyle = NSMutableParagraphStyle()
        // Wrapped lines align to the text, not under the dot.
        paragraphStyle.headIndent = indent
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
        // One paragraph per bullet, so this is the gap between them.
        paragraphStyle.paragraphSpacing = UIFontMetrics.default.scaledValue(
            for: WebCompatReporterUX.Spacing.rowVertical
        )

        // A nil colour removes the key rather than storing nil.
        var textAttributes: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraphStyle]
        textAttributes[.foregroundColor] = theme?.colors.textPrimary

        let dot = dotRun(alignedTo: font, attributes: textAttributes)
        let text = NSMutableAttributedString()
        for bullet in bullets {
            if text.length > 0 {
                text.append(NSAttributedString(string: "\n", attributes: textAttributes))
            }
            text.append(dot)
            text.append(NSAttributedString(string: "\t\(bullet.text)", attributes: textAttributes))
        }
        bulletsLabel.attributedText = text
    }

    /// A drawn circle rather than `•`, which renders under half the designed diameter.
    private func dotRun(
        alignedTo font: UIFont,
        attributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        guard let theme else { return NSAttributedString() }
        let diameter = UIFontMetrics.default.scaledValue(for: WebCompatReporterUX.Preview.bulletDiameter)
        let size = CGSize(width: diameter, height: diameter)

        let attachment = NSTextAttachment()
        // Baked into the image: a label doesn't tint attachments the way it colours text runs.
        attachment.image = UIGraphicsImageRenderer(size: size).image { context in
            theme.colors.iconSecondary.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        // Centred on the x-height, so it sits with the bullet's first line.
        attachment.bounds = CGRect(x: 0, y: (font.xHeight - diameter) / 2, width: diameter, height: diameter)

        // TextKit reads paragraph attributes off the paragraph's first character, so the attachment
        // has to carry the style or the bullet loses its indent and gap.
        let run = NSMutableAttributedString(attachment: attachment)
        run.addAttributes(attributes, range: NSRange(location: 0, length: run.length))
        return run
    }

    // MARK: - Notifiable

    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == UIContentSizeCategory.didChangeNotification else { return }
        ensureMainThread { [weak self] in
            self?.renderBullets()
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = theme.colors.layer5
        background.cornerRadius = WebCompatReporterUX.Card.largeCornerRadius
        backgroundConfiguration = background
        self.theme = theme
        renderBullets()
    }
}
