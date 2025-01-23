// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

class DownloadToast: Toast {
    struct UX {
        static let buttonSize: CGFloat = 40
    }

    lazy var progressView: UIView = .build { view in
    }

    private var horizontalStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = ButtonToast.UX.padding
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
        label.font = FXFontStyles.Bold.subheadline.scaledFont()
        label.numberOfLines = 0
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.footnote.scaledFont()
        label.numberOfLines = 0
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Medium.cross), for: [])
        button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
    }

    var progressWidthConstraint: NSLayoutConstraint?

    var downloads: [Download] = []

    // Returns true if one or more downloads have encoded data (indicated via response `Content-Encoding` header).
    // If at least one download has encoded data, we cannot get a correct total estimate for all the downloads.
    // In that case, we do not show descriptive text. This will be improved in a later rework of the download manager.
    // FXIOS-9039
    var hasContentEncoding: Bool {
        return downloads.contains(where: { $0.hasContentEncoding ?? false })
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

    var combinedBytesDownloaded: Int64 = 0 {
        didSet {
            updatePercent()
        }
    }

    var combinedTotalBytesExpected: Int64? {
        didSet {
            updatePercent()
        }
    }

    var descriptionText: String {
        guard !hasContentEncoding else {
            // We cannot get a correct estimate of encoded downloaded bytes (FXIOS-9039)
            return String()
        }

        let downloadedSize = ByteCountFormatter.string(
            fromByteCount: combinedBytesDownloaded,
            countStyle: .file
        )
        let expectedSize = combinedTotalBytesExpected != nil ? ByteCountFormatter.string(
            fromByteCount: combinedTotalBytesExpected!,
            countStyle: .file
        ) : nil
        let descriptionText = expectedSize != nil ? String(
            format: .DownloadProgressToastDescriptionText,
            downloadedSize,
            expectedSize!
        ) : downloadedSize

        guard downloads.count > 1 else {
            return descriptionText
        }

        let fileCountDescription = String(format: .DownloadMultipleFilesToastDescriptionText, downloads.count)

        return String(
            format: .DownloadMultipleFilesAndProgressToastDescriptionText,
            fileCountDescription,
            descriptionText
        )
    }

    init(download: Download,
         theme: Theme,
         completion: @escaping (_ buttonPressed: Bool) -> Void) {
        super.init(frame: .zero)

        self.completionHandler = completion
        self.clipsToBounds = true

        self.combinedTotalBytesExpected = download.totalBytesExpected

        self.downloads.append(download)

        self.addSubview(createView(download.filename, descriptionText: self.descriptionText))

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: leadingAnchor),
            toastView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toastView.heightAnchor.constraint(equalTo: heightAnchor),

            heightAnchor.constraint(equalToConstant: Toast.UX.toastHeight)
        ])

        animationConstraint = toastView.topAnchor.constraint(equalTo: topAnchor, constant: Toast.UX.toastHeight)
        animationConstraint?.isActive = true
        applyTheme(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addDownload(_ download: Download) {
        downloads.append(download)

        if let combinedTotalBytesExpected = self.combinedTotalBytesExpected {
            if let totalBytesExpected = download.totalBytesExpected {
                self.combinedTotalBytesExpected = combinedTotalBytesExpected + totalBytesExpected
            } else {
                self.combinedTotalBytesExpected = nil
            }
        }
    }

    func updatePercent() {
        DispatchQueue.main.async {
            guard !self.hasContentEncoding else {
                // We cannot get a correct estimate of encoded downloaded bytes (FXIOS-9039)
                self.percent = nil
                return
            }

            guard let combinedTotalBytesExpected = self.combinedTotalBytesExpected else {
                self.percent = 0.0
                return
            }

            self.percent = CGFloat(self.combinedBytesDownloaded) / CGFloat(combinedTotalBytesExpected)
        }
    }

    func createView(_ labelText: String, descriptionText: String) -> UIView {
        horizontalStackView.addArrangedSubview(imageView)

        titleLabel.text = labelText
        descriptionLabel.text = descriptionText

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(descriptionLabel)

        horizontalStackView.addArrangedSubview(labelStackView)
        horizontalStackView.addArrangedSubview(closeButton)

        toastView.addSubview(progressView)
        toastView.addSubview(horizontalStackView)

        NSLayoutConstraint.activate(
            [
                progressView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor),
                progressView.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
                progressView.heightAnchor.constraint(equalTo: toastView.heightAnchor),

                horizontalStackView.leadingAnchor.constraint(
                    equalTo: toastView.leadingAnchor,
                    constant: ButtonToast.UX.padding
                ),
                horizontalStackView.trailingAnchor.constraint(
                    equalTo: toastView.trailingAnchor,
                    constant: -ButtonToast.UX.padding
                ),
                horizontalStackView.bottomAnchor.constraint(equalTo: toastView.safeAreaLayoutGuide.bottomAnchor),
                horizontalStackView.topAnchor.constraint(equalTo: toastView.topAnchor),
                horizontalStackView.heightAnchor.constraint(equalToConstant: Toast.UX.toastHeight),

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

    override func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        // Intentional NOOP to override superclass behaviour for dismissing the toast.
    }
}
