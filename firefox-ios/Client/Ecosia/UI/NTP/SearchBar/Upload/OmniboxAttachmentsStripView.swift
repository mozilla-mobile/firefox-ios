// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

/// Horizontally scrollable row of attachment previews above the omnibox text field.
/// Scrolling is locked to the horizontal axis and clipped to this view's bounds.
final class OmniboxAttachmentsStripView: UIView, ThemeApplicable, UIScrollViewDelegate {

    enum UX {
        static let tileSpacing: CGFloat = .ecosia.space._1s
        static var tileHeight: CGFloat {
            OmniboxAttachmentTileView.UX.imageSize.height
        }
    }

    var onRemoveAttachment: ((UUID) -> Void)?

    private let scrollView: HorizontalAttachmentsScrollView = .build { scrollView in
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.clipsToBounds = true
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    private let stackView: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.spacing = UX.tileSpacing
        stack.alignment = .center
    }

    private var previewImages: [UUID: UIImage] = [:]
    private var tileViews: [UUID: OmniboxAttachmentTileView] = [:]
    private var currentTheme: Theme?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        clipsToBounds = true
        accessibilityIdentifier = EcosiaAccessibilityIdentifiers.OmniboxUpload.attachmentsStrip
        addSubview(scrollView)
        scrollView.delegate = self
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: UX.tileHeight),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.alwaysBounceHorizontal = stackView.bounds.width > scrollView.bounds.width
    }

    func setAttachments(_ attachments: [OmniboxAttachment], previewImages: [UUID: UIImage]) {
        self.previewImages = previewImages

        let attachmentIDs = Set(attachments.map(\.id))
        tileViews.keys.filter { !attachmentIDs.contains($0) }.forEach { id in
            tileViews[id]?.removeFromSuperview()
            tileViews.removeValue(forKey: id)
        }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for attachment in attachments {
            let tile = tileViews[attachment.id] ?? makeTile(for: attachment.id)
            tile.configure(attachment: attachment, previewImage: previewImages[attachment.id])
            if let theme = currentTheme {
                tile.applyTheme(theme: theme)
            }
            stackView.addArrangedSubview(tile)
        }

        isHidden = attachments.isEmpty
    }

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        tileViews.values.forEach { $0.applyTheme(theme: theme) }
    }

    private func makeTile(for id: UUID) -> OmniboxAttachmentTileView {
        let tile = OmniboxAttachmentTileView()
        tile.translatesAutoresizingMaskIntoConstraints = false
        tile.onRemove = { [weak self] in
            self?.onRemoveAttachment?(id)
        }
        tileViews[id] = tile
        return tile
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y != 0 else { return }
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
    }
}

// MARK: - Horizontal-only scroll view

/// Rejects predominantly vertical pans so attachment dragging stays on the horizontal axis.
private final class HorizontalAttachmentsScrollView: UIScrollView, UIGestureRecognizerDelegate {
    override init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGestureRecognizer,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        let velocity = pan.velocity(in: self)
        // Velocity is often zero at touch-down; directional lock + y-offset clamp handle the axis.
        guard velocity == .zero || abs(velocity.x) >= abs(velocity.y) else { return false }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }
}
