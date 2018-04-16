/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared
import Storage
import Deferred

protocol ShareControllerDelegate: class {
    func finish(afterDelay: TimeInterval)
    func getValidExtensionContext() -> NSExtensionContext?
    func getShareItem() -> Deferred<ShareItem?>
}

class ShareViewController: UIViewController {
    private var shareItem: ShareItem?
    private var separators = [UIView]()
    private var actionRows = [UIView]()

    private var stackView: UIStackView!
    private var sendToDevice: SendToDevice?
    weak var delegate: ShareControllerDelegate?

    override var extensionContext: NSExtensionContext? {
        get {
            return delegate?.getValidExtensionContext()
        }
    }

    private func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = UX.separatorColor
        separators.append(view)
        return view
    }

    private func layoutSeparators() {
        separators.forEach {
            $0.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(1)
            }
        }
    }

    private func makePageInfoRow() -> (row: UIView, pageTitleLabel: UILabel, urlLabel: UILabel) {
        let row = UIView()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UX.pageInfoLineSpacing

        row.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(UX.pageInfoRowLeftInset)
        }

        let pageTitleLabel = UILabel()
        let urlLabel = UILabel()
        [pageTitleLabel, urlLabel].forEach { label in
            stackView.addArrangedSubview(label)
            label.allowsDefaultTighteningForTruncation = true
            label.lineBreakMode = .byTruncatingMiddle
            label.font = UX.baseFont
        }

        pageTitleLabel.font = UIFont.boldSystemFont(ofSize: UX.baseFont.pointSize)

        return (row, pageTitleLabel, urlLabel)
    }

    private func makeActionRow(label: String, imageName: String, action: Selector, hasNavigation: Bool) -> UIView {
        let row = UIView()

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = UX.actionRowSpacingBetweenIconAndTitle
        row.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(UX.pageInfoRowLeftInset)
        }

        let icon = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = UX.actionRowTextAndIconColor

        let title = UILabel()
        title.font = UX.baseFont
        title.numberOfLines = 2
        title.adjustsFontSizeToFitWidth = true
        title.allowsDefaultTighteningForTruncation = true
        title.textColor = UX.actionRowTextAndIconColor
        title.text = label
        [icon, title].forEach { stackView.addArrangedSubview($0) }

        icon.snp.makeConstraints { make in
            make.size.equalTo(UX.actionRowIconSize)
        }

        if hasNavigation {
            let navButton = UIImageView(image: UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate))
            navButton.contentMode = .scaleAspectFit
            navButton.tintColor = UX.actionRowTextAndIconColor
            stackView.addArrangedSubview(navButton)
            navButton.snp.makeConstraints { make in
                make.size.equalTo(14)
            }
        }

        let gesture = UITapGestureRecognizer(target: self, action: action)
        row.addGestureRecognizer(gesture)

        actionRows.append(row)
        return row
    }

    fileprivate func animateToActionDoneView(withTitle title: String = "") {
        navigationItem.leftBarButtonItem = nil

        navigationController?.view.snp.updateConstraints { make in
            make.height.equalTo(UX.viewHeightForDoneState)
        }

        UIView.animate(withDuration: UX.doneDialogAnimationDuration, animations: {
            self.actionRows.forEach { $0.removeFromSuperview() }
            self.separators.forEach { $0.removeFromSuperview() }
            self.navigationController?.view.superview?.layoutIfNeeded()
        }, completion: { _ in
            self.showActionDoneView(withTitle: title)
        })
    }

    @objc func finish(afterDelay: TimeInterval = UX.durationToShowDoneDialog) {
        delegate?.finish(afterDelay: afterDelay)
    }

    private func showActionDoneView(withTitle title: String) {
        let blue = UIView()
        blue.backgroundColor = UX.doneLabelBackgroundColor
        self.stackView.addArrangedSubview(blue)
        blue.snp.makeConstraints { make in
            make.height.equalTo(UX.pageInfoRowHeight)
        }

        let label = UILabel()
        label.text = title
        label.font = UX.doneLabelFont

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.boldSystemFont(ofSize: 22)

        [label, checkmark].forEach {
            blue.addSubview($0)
            $0.textColor = .white
        }

        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().inset(UX.pageInfoRowLeftInset)
            make.trailing.equalTo(checkmark.snp.leading)
        }

        checkmark.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(UX.rowInset)
            make.width.equalTo(20)
        }
    }

    private func setupNavBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow") // hide separator line
        navigationItem.titleView = UIImageView(image: UIImage(named: "Icon-Small"))
        navigationItem.titleView?.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.SendToCancelButton, style: .plain, target: self, action: #selector(finish))
    }

    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupNavBar()
        setupStackView()

        let (currentPageInfoRow, pageTitleLabel, urlLabel) = makePageInfoRow()

        let trailingSpace = UIView()

        let rows = [
            currentPageInfoRow,
            makeSeparator(),
            makeActionRow(label: Strings.ShareLoadInBackground, imageName: "menu-Show-Tabs", action: #selector(actionLoadInBackground), hasNavigation: false),
            makeActionRow(label: Strings.ShareBookmarkThisPage, imageName: "AddToBookmarks", action: #selector(actionBookmarkThisPage), hasNavigation: false),
            makeActionRow(label: Strings.ShareAddToReadingList, imageName: "AddToReadingList", action: #selector(actionAddToReadingList), hasNavigation: false),
            makeSeparator(),
            makeActionRow(label: Strings.ShareSendToDevice, imageName: "menu-Send-to-Device", action: #selector(actionSendToDevice), hasNavigation: true),
            trailingSpace
        ]

        rows.forEach {
            stackView.addArrangedSubview($0)
        }

        // Without some growable space at the bottom there are constraint errors because the UIView space doesn't subdivide equally, and none of the rows are growable
        trailingSpace.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(1)
        }

        layoutSeparators()

        actionRows.forEach {
            $0.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(UX.actionRowHeight)
            }
        }

        currentPageInfoRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(UX.pageInfoRowHeight)
        }

        delegate?.getShareItem().uponQueue(.main) { shareItem in
            guard let shareItem = shareItem, shareItem.isShareable else {
                let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.finish(afterDelay: 0) })
                self.present(alert, animated: true, completion: nil)
                return
            }

            self.shareItem = shareItem
            urlLabel.text = shareItem.url
            pageTitleLabel.text = shareItem.title
        }
    }
}

extension ShareViewController {
    @objc func actionLoadInBackground(gesture: UIGestureRecognizer) {
        // To avoid re-rentry deom double tap, each action function disables the gesture
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: Strings.ShareLoadInBackgroundDone)

        if let shareItem = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.queue.addToQueue(shareItem).uponQueue(.main) { _ in
                profile.shutdown()
            }
        }

        finish()
    }

    @objc func actionBookmarkThisPage(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: Strings.ShareBookmarkThisPageDone)

        if let shareItem = shareItem {
            let profile = BrowserProfile(localName: "profile")
            _ = profile.bookmarks.shareItem(shareItem).value // Blocks until database has settled
            profile.shutdown()
        }

        finish()
    }

    @objc func actionAddToReadingList(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: Strings.ShareAddToReadingListDone)

        if let shareItem = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.readingList.createRecordWithURL(shareItem.url, title: shareItem.title ?? "", addedBy: UIDevice.current.name)
            profile.shutdown()
        }

        finish()
    }

    @objc func actionSendToDevice(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false
        sendToDevice = SendToDevice()
        guard let sendToDevice = sendToDevice else { return }
        sendToDevice.sharedItem = shareItem
        sendToDevice.delegate = delegate
        let vc = sendToDevice.initialViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

