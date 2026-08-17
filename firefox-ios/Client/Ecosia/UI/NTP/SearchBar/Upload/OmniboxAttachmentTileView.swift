// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

/// Single attachment preview tile in the omnibox strip — loading spinner, file card, or image thumbnail.
final class OmniboxAttachmentTileView: UIView, ThemeApplicable {

    enum UX {
        static let fileSize = CGSize(width: 136, height: 74)
        static let imageSize = CGSize(width: 74, height: 74)
        static let cornerRadius: CGFloat = .ecosia.borderRadius._l
        static let imageBorderWidth: CGFloat = 1
        static let fileContentPadding = UIEdgeInsets(
            top: .ecosia.space._1s,
            left: .ecosia.space._1s,
            bottom: .ecosia.space._1s,
            right: .ecosia.space._1s
        )
        static let fileLabelGap: CGFloat = .ecosia.space._2s
        static let removeButtonInset: CGFloat = .ecosia.space._2s
        static let removeButtonContainerSize: CGFloat = 32
        static let removeButtonIconSize: CGFloat = 16
        static let glassBorderWidth: CGFloat = 1
    }

    var onRemove: (() -> Void)?

    private let containerView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private let loader = OmniboxUploadLoaderView()

    private let fileNameLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
    }

    private let fileSizeLabel: UILabel = .build { label in
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
    }

    private let fileContentStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.fileLabelGap
        stack.alignment = .fill
        stack.distribution = .equalSpacing
    }

    private let imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
    }

    private let imageLoadingOverlay: UIView = .build { view in
        view.isHidden = true
        view.isUserInteractionEnabled = false
    }

    private let removeButtonContainer: UIView = .build { view in
        view.layer.cornerRadius = UX.removeButtonContainerSize / 2
        view.clipsToBounds = true
    }

    private let removeGlassBlur: UIVisualEffectView = .build { blur in
        blur.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blur.isUserInteractionEnabled = false
    }

    private let removeGlassTint: UIView = .build { view in
        view.isUserInteractionEnabled = false
    }

    private let removeIconView: UIImageView = .build { imageView in
        imageView.image = UIImage.ecosia(named: "close")?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
    }

    private lazy var removeButton: UIButton = .build { _ in }

    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var currentLayout: OmniboxAttachment.Layout = .file
    private var currentTheme: Theme?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(containerView)
        // ZStack-style layering inside the rounded tile: image, overlays, then remove control.
        containerView.addSubviews(
            imageView,
            imageLoadingOverlay,
            loader,
            fileContentStack,
            removeButtonContainer,
            removeButton
        )
        fileContentStack.addArrangedSubview(fileNameLabel)
        fileContentStack.addArrangedSubview(fileSizeLabel)
        removeButtonContainer.addSubviews(removeGlassBlur, removeGlassTint, removeIconView)
        removeButton.accessibilityLabel = String.localized(.cancel)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        configureAccessibility()

        widthConstraint = widthAnchor.constraint(equalToConstant: UX.fileSize.width)
        heightConstraint = heightAnchor.constraint(equalToConstant: UX.fileSize.height)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            imageLoadingOverlay.topAnchor.constraint(equalTo: imageView.topAnchor),
            imageLoadingOverlay.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            imageLoadingOverlay.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            imageLoadingOverlay.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            loader.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            fileContentStack.topAnchor.constraint(
                equalTo: containerView.topAnchor,
                constant: UX.fileContentPadding.top
            ),
            fileContentStack.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor,
                constant: UX.fileContentPadding.left
            ),
            fileContentStack.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -UX.fileContentPadding.right
            ),
            fileContentStack.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor,
                constant: -UX.fileContentPadding.bottom
            ),

            removeButtonContainer.topAnchor.constraint(
                equalTo: containerView.topAnchor,
                constant: UX.removeButtonInset
            ),
            removeButtonContainer.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor,
                constant: -UX.removeButtonInset
            ),
            removeButtonContainer.widthAnchor.constraint(equalToConstant: UX.removeButtonContainerSize),
            removeButtonContainer.heightAnchor.constraint(equalToConstant: UX.removeButtonContainerSize),

            removeGlassBlur.topAnchor.constraint(equalTo: removeButtonContainer.topAnchor),
            removeGlassBlur.leadingAnchor.constraint(equalTo: removeButtonContainer.leadingAnchor),
            removeGlassBlur.trailingAnchor.constraint(equalTo: removeButtonContainer.trailingAnchor),
            removeGlassBlur.bottomAnchor.constraint(equalTo: removeButtonContainer.bottomAnchor),

            removeGlassTint.topAnchor.constraint(equalTo: removeButtonContainer.topAnchor),
            removeGlassTint.leadingAnchor.constraint(equalTo: removeButtonContainer.leadingAnchor),
            removeGlassTint.trailingAnchor.constraint(equalTo: removeButtonContainer.trailingAnchor),
            removeGlassTint.bottomAnchor.constraint(equalTo: removeButtonContainer.bottomAnchor),

            removeIconView.centerXAnchor.constraint(equalTo: removeButtonContainer.centerXAnchor),
            removeIconView.centerYAnchor.constraint(equalTo: removeButtonContainer.centerYAnchor),
            removeIconView.widthAnchor.constraint(equalToConstant: UX.removeButtonIconSize),
            removeIconView.heightAnchor.constraint(equalToConstant: UX.removeButtonIconSize),

            removeButton.topAnchor.constraint(equalTo: removeButtonContainer.topAnchor),
            removeButton.leadingAnchor.constraint(equalTo: removeButtonContainer.leadingAnchor),
            removeButton.trailingAnchor.constraint(equalTo: removeButtonContainer.trailingAnchor),
            removeButton.bottomAnchor.constraint(equalTo: removeButtonContainer.bottomAnchor),

            widthConstraint,
            heightConstraint
        ].compactMap { $0 })
    }

    /// Identifiers for the tile and its state-bearing subviews. The spinner and the
    /// preview image are otherwise invisible to UI automation: a plain `UIView` and a
    /// `UIImageView` are not accessibility elements by default, so neither would appear
    /// in the query tree. Promoting them also gives VoiceOver something to announce for
    /// an upload that is still in flight.
    private func configureAccessibility() {
        accessibilityIdentifier = EcosiaAccessibilityIdentifiers.OmniboxUpload.attachmentTile

        loader.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.OmniboxUpload.attachmentSpinner
        loader.isAccessibilityElement = true
        loader.accessibilityLabel = String.localized(.uploadAttachmentUploadingAccessibilityLabel)
        loader.accessibilityTraits = .updatesFrequently

        imageView.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.OmniboxUpload.attachmentImage
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = String.localized(.uploadAttachmentImageAccessibilityLabel)
        imageView.accessibilityTraits = .image

        fileNameLabel.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.OmniboxUpload.attachmentFileName
        fileSizeLabel.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.OmniboxUpload.attachmentFileSize
        removeButton.accessibilityIdentifier = EcosiaAccessibilityIdentifiers.OmniboxUpload.attachmentRemoveButton
    }

    func configure(attachment: OmniboxAttachment, previewImage: UIImage?) {
        currentLayout = attachment.layout
        let size = attachment.layout == .image ? UX.imageSize : UX.fileSize
        widthConstraint?.constant = size.width
        heightConstraint?.constant = size.height

        resetVisibility()

        switch attachment.layout {
        case .image:
            configureImageTile(attachment: attachment, previewImage: previewImage)
        case .file:
            configureFileTile(attachment: attachment)
        }

        applyRemoveButtonStyle(for: attachment.layout)
        if let currentTheme { applyTheme(theme: currentTheme) }
    }

    func applyTheme(theme: any Theme) {
        currentTheme = theme
        let colors = theme.colors
        let ecosia = (colors as? EcosiaThemeColourPalette)?.ecosia

        if currentLayout == .image {
            containerView.backgroundColor = colors.ecosia.backgroundQuaternary
            applyImageBorder(failed: false)
        } else {
            containerView.backgroundColor = colors.ecosia.backgroundQuaternary
            containerView.layer.borderWidth = 0
        }

        fileNameLabel.textColor = colors.ecosia.textPrimary
        fileSizeLabel.textColor = colors.ecosia.textSecondary
        loader.applyTheme(theme: theme, onDarkBackground: !imageLoadingOverlay.isHidden)
        imageLoadingOverlay.backgroundColor = colors.ecosia.textPrimary.withAlphaComponent(0.35)

        removeGlassTint.backgroundColor = ecosia?.buttonBgGlassStatic
            ?? EcosiaColor.Gray90.withAlphaComponent(0.32)
        removeButtonContainer.layer.borderColor = (ecosia?.borderGlassStatic
            ?? EcosiaColor.White.withAlphaComponent(0x3D / 255.0)).cgColor

        applyRemoveButtonStyle(for: currentLayout)
    }

    private func resetVisibility() {
        loader.stopAnimating()
        loader.isHidden = true
        fileContentStack.isHidden = true
        fileNameLabel.isHidden = true
        fileSizeLabel.isHidden = true
        imageView.isHidden = true
        imageLoadingOverlay.isHidden = true
        removeButton.isHidden = false
        removeButtonContainer.isHidden = false
    }

    private func configureImageTile(attachment: OmniboxAttachment, previewImage: UIImage?) {
        switch attachment.state {
        case .loading:
            if let previewImage {
                showImagePreview(previewImage, uploading: true, failed: false)
            } else {
                showLoader(onDarkBackground: false)
                removeButton.isHidden = true
                removeButtonContainer.isHidden = true
            }
        case .ready:
            showImagePreview(previewImage, uploading: false, failed: false)
        case .failed:
            showImagePreview(previewImage, uploading: false, failed: true)
        }
    }

    private func showImagePreview(_ image: UIImage?, uploading: Bool, failed: Bool) {
        imageView.isHidden = false
        imageView.image = image
        imageLoadingOverlay.isHidden = !uploading
        applyImageBorder(failed: failed)
        if uploading {
            showLoader(onDarkBackground: true)
        }
    }

    private func showLoader(onDarkBackground: Bool) {
        loader.isHidden = false
        if let currentTheme {
            loader.applyTheme(theme: currentTheme, onDarkBackground: onDarkBackground)
        }
        loader.startAnimating()
    }

    private func applyImageBorder(failed: Bool) {
        containerView.layer.borderWidth = UX.imageBorderWidth
        containerView.layer.borderColor = failed
            ? (currentTheme?.colors.ecosia.stateError.cgColor)
            : (currentTheme?.colors.borderPrimary.cgColor)
    }

    private func configureFileTile(attachment: OmniboxAttachment) {
        fileContentStack.isHidden = false
        switch attachment.state {
        case .loading:
            fileContentStack.isHidden = true
            showLoader(onDarkBackground: false)
            removeButton.isHidden = true
            removeButtonContainer.isHidden = true
        case .failed:
            fileNameLabel.isHidden = false
            fileNameLabel.text = attachment.fileName
            fileSizeLabel.isHidden = false
            fileSizeLabel.text = String.localized(.uploadAttachmentFailed)
        case .ready(let byteCount, _, _):
            fileNameLabel.isHidden = false
            fileNameLabel.text = attachment.fileName
            fileSizeLabel.isHidden = false
            fileSizeLabel.text = Self.formattedByteCount(byteCount)
        }
    }

    private func applyRemoveButtonStyle(for layout: OmniboxAttachment.Layout) {
        guard let colors = currentTheme?.colors else { return }
        switch layout {
        case .file:
            removeGlassBlur.isHidden = true
            removeGlassTint.isHidden = true
            removeButtonContainer.backgroundColor = .clear
            removeButtonContainer.layer.borderWidth = 0
            removeIconView.tintColor = colors.ecosia.buttonContentSecondary
        case .image:
            removeGlassBlur.isHidden = false
            removeGlassTint.isHidden = false
            removeButtonContainer.backgroundColor = .clear
            removeButtonContainer.layer.borderWidth = UX.glassBorderWidth
            removeIconView.tintColor = colors.ecosia.buttonContentPrimary
        }
    }

    @objc private func removeTapped() {
        onRemove?()
    }

    private static func formattedByteCount(_ byteCount: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }
}
