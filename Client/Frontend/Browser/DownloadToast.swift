// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit

struct DownloadToastUX {
    static let ToastBackgroundColor = UIColor.Photon.Blue40
    static let ToastProgressColor = UIColor.Photon.Blue50
}

class DownloadToast: Toast {
    lazy var progressView: UIView = .build { view in
        view.backgroundColor = DownloadToastUX.ToastProgressColor
    }

    var percent: CGFloat = 0.0 {
        didSet {
            UIView.animate(withDuration: 0.05) {
                self.descriptionLabel.text = self.descriptionText
                self.progressWidthConstraint?.constant = self.toastView.frame.width * self.percent
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
        let downloadedSize = ByteCountFormatter.string(fromByteCount: combinedBytesDownloaded, countStyle: .file)
        let expectedSize = combinedTotalBytesExpected != nil ? ByteCountFormatter.string(fromByteCount: combinedTotalBytesExpected!, countStyle: .file) : nil
        let descriptionText = expectedSize != nil ? String(format: .DownloadProgressToastDescriptionText, downloadedSize, expectedSize!) : downloadedSize

        guard downloads.count > 1 else {
            return descriptionText
        }

        let fileCountDescription = String(format: .DownloadMultipleFilesToastDescriptionText, downloads.count)

        return String(format: .DownloadMultipleFilesAndProgressToastDescriptionText, fileCountDescription, descriptionText)
    }

    var downloads: [Download] = []

    let descriptionLabel = UILabel()
    var progressWidthConstraint: NSLayoutConstraint?

    init(download: Download, completion: @escaping (_ buttonPressed: Bool) -> Void) {
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

            heightAnchor.constraint(equalToConstant: ButtonToastUX.ToastHeight)
        ])

        animationConstraint = toastView.topAnchor.constraint(equalTo: topAnchor, constant: ButtonToastUX.ToastHeight)
        animationConstraint?.isActive = true
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
            guard let combinedTotalBytesExpected = self.combinedTotalBytesExpected else {
                self.percent = 0.0
                return
            }

            self.percent = CGFloat(self.combinedBytesDownloaded) / CGFloat(combinedTotalBytesExpected)
        }
    }

    func createView(_ labelText: String, descriptionText: String) -> UIView {
        let horizontalStackView: UIStackView = .build { stackView in
            stackView.axis = .horizontal
            stackView.alignment = .center
            stackView.spacing = ButtonToastUX.ToastPadding
        }

        let icon = UIImageView(image: UIImage.templateImageNamed("download"))
        icon.tintColor = UIColor.Photon.White100
        horizontalStackView.addArrangedSubview(icon)

        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading

        let label = UILabel()
        label.textColor = UIColor.Photon.White100
        label.font = ButtonToastUX.ToastLabelFont
        label.text = labelText
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        labelStackView.addArrangedSubview(label)

        descriptionLabel.textColor = UIColor.Photon.White100
        descriptionLabel.font = ButtonToastUX.ToastDescriptionFont
        descriptionLabel.text = descriptionText
        descriptionLabel.lineBreakMode = .byTruncatingTail
        labelStackView.addArrangedSubview(descriptionLabel)

        horizontalStackView.addArrangedSubview(labelStackView)

        let cancel = UIImageView(image: UIImage.templateImageNamed("close-medium"))
        cancel.tintColor = UIColor.Photon.White100
        cancel.isUserInteractionEnabled = true
        cancel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(buttonPressed)))
        horizontalStackView.addArrangedSubview(cancel)

        toastView.backgroundColor = DownloadToastUX.ToastBackgroundColor

        toastView.addSubview(progressView)
        toastView.addSubview(horizontalStackView)

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: toastView.leadingAnchor),
            progressView.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
            progressView.heightAnchor.constraint(equalTo: toastView.heightAnchor),

            horizontalStackView.centerXAnchor.constraint(equalTo: toastView.centerXAnchor),
            horizontalStackView.centerYAnchor.constraint(equalTo: toastView.centerYAnchor),
            horizontalStackView.widthAnchor.constraint(equalTo: toastView.widthAnchor, constant: -2 * ButtonToastUX.ToastPadding)
        ])

        progressWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
        progressWidthConstraint?.isActive = true

        return toastView
    }

    @objc func buttonPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let alert = AlertController(title: .CancelDownloadDialogTitle, message: .CancelDownloadDialogMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: .CancelDownloadDialogResume, style: .cancel, handler: nil), accessibilityIdentifier: "cancelDownloadAlert.resume")
        alert.addAction(UIAlertAction(title: .CancelDownloadDialogCancel, style: .default, handler: { action in
            self.completionHandler?(true)
            self.dismiss(true)
            TelemetryWrapper.recordEvent(category: .action, method: .cancel, object: .download)
        }), accessibilityIdentifier: "cancelDownloadAlert.cancel")

        viewController?.present(alert, animated: true, completion: nil)
    }

    @objc override func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        // Intentional NOOP to override superclass behavior for dismissing the toast.
    }
}
