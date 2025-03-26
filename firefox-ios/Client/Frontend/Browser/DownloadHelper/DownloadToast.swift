// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

class DownloadToast: Toast, DownloadProgressDelegate {
    struct UX {
        static let buttonSize: CGFloat = 40
    }

    lazy var progressView: UIView = .build { view in
        view.layer.cornerRadius = Toast.UX.toastCornerRadius
    }

    private var contentStackView: UIStackView = .build { stackView in
        stackView.spacing = ButtonToast.UX.stackViewSpacing
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
    }

    private var imageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.download)
    }

    private var labelStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
    }

    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Medium.cross), for: [])
        button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
    }

    var progressWidthConstraint: NSLayoutConstraint?

    var downloadProgressManager: DownloadProgressManager

    // Returns true if one or more downloads have encoded data (indicated via response `Content-Encoding` header).
    // If at least one download has encoded data, we cannot get a correct total estimate for all the downloads.
    // In that case, we do not show descriptive text. This will be improved in a later rework of the download manager.
    // FXIOS-9039
    var hasContentEncoding: Bool {
        return downloadProgressManager.downloads.contains(where: { $0.hasContentEncoding ?? false })
    }

    var percent: CGFloat? = 0.0 {
        didSet {
            UIView.animate(withDuration: 0.05) {
                self.descriptionLabel.text = self.descriptionText

                if let percent = self.percent {
                    self.progressView.isHidden = false
                    self.progressWidthConstraint?.constant = self.toastView.frame.width * percent
                } else {
                    self.progressView.isHidden = true
                }

                self.layoutIfNeeded()
            }
        }
    }

    var descriptionText: String {
        guard !hasContentEncoding else {
            // We cannot get a correct estimate of encoded downloaded bytes (FXIOS-9039)
            return String()
        }

        let downloadedSize = ByteCountFormatter.string(
            fromByteCount: downloadProgressManager.combinedBytesDownloaded,
            countStyle: .file
        )
        let expectedSize = downloadProgressManager.combinedTotalBytesExpected != nil ? ByteCountFormatter.string(
            fromByteCount: downloadProgressManager.combinedTotalBytesExpected!,
            countStyle: .file
        ) : nil
        let descriptionText = expectedSize != nil ? String(
            format: .DownloadProgressToastDescriptionText,
            downloadedSize,
            expectedSize!
        ) : downloadedSize

        guard downloadProgressManager.downloads.count > 1 else {
            return descriptionText
        }

        let fileCountDescription = String(format: .DownloadMultipleFilesToastDescriptionText,
                                          downloadProgressManager.downloads.count)

        return String(
            format: .DownloadMultipleFilesAndProgressToastDescriptionText,
            fileCountDescription,
            descriptionText
        )
    }

    init(downloadProgressManager: DownloadProgressManager,
         theme: Theme,

         completion: @escaping (Bool) -> Void) {
        self.downloadProgressManager = downloadProgressManager
        super.init(frame: .zero)

        self.completionHandler = completion
        self.clipsToBounds = true

        let download = downloadProgressManager.downloads[0]

        updatePercent()

        self.addSubview(createView(download.filename, descriptionText: self.descriptionText))

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Toast.UX.shadowVerticalSpacing),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Toast.UX.shadowVerticalSpacing),
            toastView.heightAnchor.constraint(equalTo: heightAnchor, constant: -Toast.UX.shadowHorizontalSpacing),

            heightAnchor.constraint(greaterThanOrEqualToConstant: Toast.UX.toastHeightWithShadow)
        ])

        animationConstraint = toastView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor,
                                                             constant: Toast.UX.toastHeightWithShadow)
        animationConstraint?.isActive = true
        applyTheme(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updatePercent() {
        DispatchQueue.main.async {
            guard !self.hasContentEncoding else {
                // We cannot get a correct estimate of encoded downloaded bytes (FXIOS-9039)
                self.percent = nil
                return
            }

            guard let combinedTotalBytesExpected = self.downloadProgressManager.combinedTotalBytesExpected else {
                self.percent = 0.0
                return
            }
            let combinedBytesDownloaded = self.downloadProgressManager.combinedBytesDownloaded

            self.percent = CGFloat(combinedBytesDownloaded) / CGFloat(combinedTotalBytesExpected)
        }
    }

    func createView(_ labelText: String, descriptionText: String) -> UIView {
        contentStackView.addArrangedSubview(imageView)

        titleLabel.text = labelText
        descriptionLabel.text = descriptionText

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(descriptionLabel)

        contentStackView.addArrangedSubview(labelStackView)
        contentStackView.addArrangedSubview(closeButton)

        toastView.addSubview(progressView)
        toastView.addSubview(contentStackView)

        NSLayoutConstraint.activate(
            [
                progressView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor),
                progressView.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
                progressView.heightAnchor.constraint(equalTo: toastView.heightAnchor),

                contentStackView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor,
                                                          constant: ButtonToast.UX.spacing),
                contentStackView.trailingAnchor.constraint(equalTo: toastView.trailingAnchor,
                                                           constant: -ButtonToast.UX.spacing),
                contentStackView.bottomAnchor.constraint(equalTo: toastView.bottomAnchor,
                                                         constant: -ButtonToast.UX.spacing),
                contentStackView.topAnchor.constraint(equalTo: toastView.topAnchor,
                                                      constant: ButtonToast.UX.spacing),

                closeButton.heightAnchor.constraint(equalToConstant: UX.buttonSize),
                closeButton.widthAnchor.constraint(equalToConstant: UX.buttonSize),
            ]
        )

        progressWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
        progressWidthConstraint?.isActive = true

        return toastView
    }

    @objc
    func buttonPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let alert = AlertController(title: .CancelDownloadDialogTitle,
                                    message: .CancelDownloadDialogMessage,
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: .CancelDownloadDialogResume, style: .cancel, handler: nil),
                        accessibilityIdentifier: AccessibilityIdentifiers.Alert.cancelDownloadResume)
        alert.addAction(UIAlertAction(title: .CancelDownloadDialogCancel,
                                      style: .default,
                                      handler: { action in
            self.completionHandler?(true)
            self.dismiss(true)
            TelemetryWrapper.recordEvent(category: .action, method: .cancel, object: .download)
        }), accessibilityIdentifier: AccessibilityIdentifiers.Alert.cancelDownloadCancel)

        viewController?.present(alert, animated: true, completion: nil)
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)

        titleLabel.textColor = theme.colors.textInverted
        descriptionLabel.textColor = theme.colors.textInverted
        imageView.tintColor = theme.colors.textInverted
        closeButton.tintColor = theme.colors.textInverted
        progressView.backgroundColor = theme.colors.actionPrimaryHover
    }

    override func adjustLayoutForA11ySizeCategory() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        if contentSizeCategory.isAccessibilityCategory {
            // Description label changes with progress and if this isn't clipped the height of the
            // toast changes continually while loading
            descriptionLabel.numberOfLines = 1
            descriptionLabel.lineBreakMode = .byTruncatingTail
        } else {
            descriptionLabel.numberOfLines = 0
            descriptionLabel.lineBreakMode = .byWordWrapping
        }

        setNeedsLayout()
    }

    override func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        // Intentional NOOP to override superclass behaviour for dismissing the toast.
    }

    override func dismiss(_ buttonPressed: Bool) {
        // Delay toast dismiss to handle download of small files
        // where the toast is presented and dismiss right away
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            super.dismiss(buttonPressed)
        }
    }

    func updateCombinedBytesDownloaded(value: Int64) {
        updatePercent()
    }
}
