/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SnapKit

struct DownloadToastUX {
    static let ToastBackgroundColor = UIColor.Photon.Blue40
    static let ToastProgressColor = UIColor.Photon.Blue50
}

class DownloadToast: Toast {
    lazy var progressView: UIView = {
        let progressView = UIView()
        progressView.backgroundColor = DownloadToastUX.ToastProgressColor
        return progressView
    }()

    var percent: CGFloat = 0.0 {
        didSet {
            UIView.animate(withDuration: 0.05) {
                self.descriptionLabel.text = self.descriptionText
                self.progressWidthConstraint?.update(offset: self.toastView.frame.width * self.percent)
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
        let descriptionText = expectedSize != nil ? String(format: Strings.DownloadProgressToastDescriptionText, downloadedSize, expectedSize!) : downloadedSize

        guard downloads.count > 1 else {
            return descriptionText
        }

        let fileCountDescription = String(format: Strings.DownloadMultipleFilesToastDescriptionText, downloads.count)

        return String(format: Strings.DownloadMultipleFilesAndProgressToastDescriptionText, fileCountDescription, descriptionText)
    }

    var downloads: [Download] = []

    let descriptionLabel = UILabel()
    var progressWidthConstraint: Constraint?

    init(download: Download, completion: @escaping (_ buttonPressed: Bool) -> Void) {
        super.init(frame: .zero)

        self.completionHandler = completion
        self.clipsToBounds = true

        self.combinedTotalBytesExpected = download.totalBytesExpected

        self.downloads.append(download)

        self.addSubview(createView(download.filename, descriptionText: self.descriptionText))

        self.toastView.snp.makeConstraints { make in
            make.left.right.height.equalTo(self)
            self.animationConstraint = make.top.equalTo(self).offset(ButtonToastUX.ToastHeight).constraint
        }

        self.snp.makeConstraints { make in
            make.height.equalTo(ButtonToastUX.ToastHeight)
        }
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
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = ButtonToastUX.ToastPadding

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

        progressView.snp.makeConstraints { make in
            make.left.equalTo(toastView)
            make.centerY.equalTo(toastView)
            make.height.equalTo(toastView)
            progressWidthConstraint = make.width.equalTo(0.0).constraint
        }

        horizontalStackView.snp.makeConstraints { make in
            make.centerX.equalTo(toastView)
            make.centerY.equalTo(toastView)
            make.width.equalTo(toastView.snp.width).offset(-2 * ButtonToastUX.ToastPadding)
        }

        return toastView
    }

    @objc func buttonPressed(_ gestureRecognizer: UIGestureRecognizer) {
        let alert = AlertController(title: Strings.CancelDownloadDialogTitle, message: Strings.CancelDownloadDialogMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.CancelDownloadDialogResume, style: .cancel, handler: nil), accessibilityIdentifier: "cancelDownloadAlert.resume")
        alert.addAction(UIAlertAction(title: Strings.CancelDownloadDialogCancel, style: .default, handler: { action in
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
