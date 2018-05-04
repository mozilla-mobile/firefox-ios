/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage

private struct DownloadsPanelUX {
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenItemTextColor = UIColor.gray
    static let WelcomeScreenItemWidth = 170
}

struct DownloadedFile {
    let path: URL
    let size: UInt64
    let lastModified: Date

    var canShowInWebView: Bool {
        return MIMEType.canShowInWebView(mimeType)
    }

    var filename: String {
        return path.lastPathComponent
    }

    var fileExtension: String {
        return path.pathExtension
    }

    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var mimeType: String {
        return MIMEType.mimeTypeFromFileExtension(fileExtension)
    }
}

class DownloadsPanel: UIViewController, UITableViewDelegate, UITableViewDataSource, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    var profile: Profile!
    var tableView = UITableView()

    private let events: [Notification.Name] = [.FileDidDownload, .PrivateDataClearedDownloadedFiles, .DynamicFontChanged]

    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()

    private var downloadedFiles: [DownloadedFile] = []
    private var fileExtensionIcons: [String : UIImage] = [:]

    // MARK: - Lifecycle
    init() {
        super.init(nibName: nil, bundle: nil)
        events.forEach { NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TwoLineTableViewCell.self, forCellReuseIdentifier: "TwoLineTableViewCell")
        tableView.layoutMargins = .zero
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.accessibilityIdentifier = "DownloadsTable"
        tableView.cellLayoutMarginsFollowReadableWidth = false

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()

        reloadData()
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    @objc func notificationReceived(_ notification: Notification) {
        DispatchQueue.main.async {
            self.reloadData()

            switch notification.name {
            case .FileDidDownload, .PrivateDataClearedDownloadedFiles:
                break
            case .DynamicFontChanged:
                if self.emptyStateOverlayView.superview != nil {
                    self.emptyStateOverlayView.removeFromSuperview()
                }
                self.emptyStateOverlayView = self.createEmptyStateOverlayView()
                break
            default:
                // no need to do anything at all
                print("Error: Received unexpected notification \(notification.name)")
                break
            }
        }
    }

    func reloadData() {
        downloadedFiles = fetchData()
        fileExtensionIcons = [:]
        tableView.reloadData()
        updateEmptyPanelState()
    }

    private func fetchData() -> [DownloadedFile] {
        var downloadedFiles: [DownloadedFile] = []
        do {
            let downloadsPath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Downloads")
            let files = try FileManager.default.contentsOfDirectory(at: downloadsPath, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])

            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path) as NSDictionary
                let downloadedFile = DownloadedFile(path: file, size: attributes.fileSize(), lastModified: attributes.fileModificationDate() ?? Date())
                downloadedFiles.append(downloadedFile)
            }
        } catch let error {
            print("Unable to get files in Downloads folder: \(error.localizedDescription)")
            return []
        }

        return downloadedFiles.sorted(by: { a, b -> Bool in
            return a.lastModified > b.lastModified
        })
    }

    private func deleteDownloadedFile(_ downloadedFile: DownloadedFile) -> Bool {
        do {
            try FileManager.default.removeItem(at: downloadedFile.path)
            return true
        } catch let error {
            print("Unable to delete downloaded file: \(error.localizedDescription)")
        }

        return false
    }

    private func shareDownloadedFile(_ downloadedFile: DownloadedFile, indexPath: IndexPath) {
        let helper = ShareExtensionHelper(url: downloadedFile.path, tab: nil)
        let controller = helper.createActivityViewController { completed, activityType in
            print("Shared downloaded file: \(completed)")
        }

        if let popoverPresentationController = controller.popoverPresentationController {
            guard let tableViewCell = tableView.cellForRow(at: indexPath) else {
                print("Unable to get table view cell at index path: \(indexPath)")
                return
            }

            popoverPresentationController.sourceView = tableViewCell
            popoverPresentationController.sourceRect = tableViewCell.bounds
            popoverPresentationController.permittedArrowDirections = .any
        }

        present(controller, animated: true, completion: nil)
    }

    private func iconForFileExtension(_ fileExtension: String) -> UIImage? {
        if let icon = fileExtensionIcons[fileExtension] {
            return icon
        }

        guard let icon = roundRectImageWithLabel(fileExtension, width: 29, height: 29) else {
            return nil
        }

        fileExtensionIcons[fileExtension] = icon
        return icon
    }

    private func roundRectImageWithLabel(_ label: String, width: CGFloat, height: CGFloat, radius: CGFloat = 5.0, strokeWidth: CGFloat = 1.0, strokeColor: UIColor = .darkGray, fontSize: CGFloat = 9.0) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(strokeColor.cgColor)

        let rect = CGRect(x: strokeWidth / 2, y: strokeWidth / 2, width: width - strokeWidth, height: height - strokeWidth)
        let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        bezierPath.lineWidth = strokeWidth
        bezierPath.stroke()

        let attributedString = NSAttributedString(string: label, attributes: [
            .baselineOffset: -(strokeWidth * 2),
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: strokeColor
            ])
        let stringHeight: CGFloat = fontSize * 2
        let stringWidth = attributedString.boundingRect(with: CGSize(width: width, height: stringHeight), options: .usesLineFragmentOrigin, context: nil).size.width
        attributedString.draw(at: CGPoint(x: (width - stringWidth) / 2 + strokeWidth, y: (height - stringHeight) / 2 + strokeWidth))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    // MARK: - Empty State
    private func updateEmptyPanelState() {
        if downloadedFiles.count == 0 {
            if emptyStateOverlayView.superview == nil {
                view.addSubview(emptyStateOverlayView)
                view.bringSubview(toFront: emptyStateOverlayView)
                emptyStateOverlayView.snp.makeConstraints { make in
                    make.edges.equalTo(self.tableView)
                }
            }
        } else {
            emptyStateOverlayView.removeFromSuperview()
        }
    }

    fileprivate func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white

        let logoImageView = UIImageView(image: UIImage(named: "emptyDownloads"))
        overlayView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(HomePanelUX.EmptyTabContentOffset).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
        }

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = Strings.DownloadsPanelEmptyStateTitle
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = DownloadsPanelUX.WelcomeScreenItemTextColor
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(logoImageView.snp.bottom).offset(DownloadsPanelUX.WelcomeScreenPadding)
            make.width.equalTo(DownloadsPanelUX.WelcomeScreenItemWidth)
        }

        return overlayView
    }

    fileprivate func downloadedFileForIndexPath(_ indexPath: IndexPath) -> DownloadedFile? {
        return downloadedFiles[safe: indexPath.row]
    }

    // MARK: - TableView Delegate / DataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TwoLineTableViewCell", for: indexPath) as! TwoLineTableViewCell

        return configureDownloadedFile(cell, for: indexPath)
    }

    func configureDownloadedFile(_ cell: UITableViewCell, for indexPath: IndexPath) -> UITableViewCell {
        if let downloadedFile = downloadedFileForIndexPath(indexPath), let cell = cell as? TwoLineTableViewCell {
            cell.setLines(downloadedFile.filename, detailText: downloadedFile.formattedSize)
            cell.imageView?.image = iconForFileExtension(downloadedFile.fileExtension)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let downloadedFile = downloadedFileForIndexPath(indexPath) {
            guard downloadedFile.canShowInWebView else {
                shareDownloadedFile(downloadedFile, indexPath: indexPath)
                return
            }

            homePanelDelegate?.homePanel(self, didSelectURL: downloadedFile.path, visitType: VisitType.typed)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadedFiles.count
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteTitle = NSLocalizedString("Delete", tableName: "DownloadsPanel", comment: "Action button for deleting downloaded files in the Downloads panel.")
        let shareTitle = NSLocalizedString("Share", tableName: "DownloadsPanel", comment: "Action button for sharing downloaded files in the Downloads panel.")
        let delete = UITableViewRowAction(style: .destructive, title: deleteTitle, handler: { (action, indexPath) in
            if let downloadedFile = self.downloadedFileForIndexPath(indexPath) {
                if self.deleteDownloadedFile(downloadedFile) {
                    self.downloadedFiles.remove(at: indexPath.row)
                    self.tableView.beginUpdates()
                    self.tableView.deleteRows(at: [indexPath], with: .right)
                    self.tableView.endUpdates()
                    self.updateEmptyPanelState()
                }
            }
        })
        let share = UITableViewRowAction(style: .normal, title: shareTitle, handler: { (action, indexPath) in
            if let downloadedFile = self.downloadedFileForIndexPath(indexPath) {
                self.shareDownloadedFile(downloadedFile, indexPath: indexPath)
            }
        })
        share.backgroundColor = view.tintColor
        return [delete, share]
    }
}
