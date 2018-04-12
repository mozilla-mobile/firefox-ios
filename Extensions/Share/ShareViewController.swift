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
    private var actions = [UIGestureRecognizer: (() -> Void)]()
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
                make.left.right.equalToSuperview()
                make.height.equalTo(1)
            }
        }
    }

    private func makePageInfoRow() -> (row: UIView, pageTitleLabel: UILabel, urlLabel: UILabel) {
        let row = UIView()
        let pageTitleLabel = UILabel()
        let urlLabel = UILabel()

        [pageTitleLabel, urlLabel].forEach { label in
            row.addSubview(label)
            label.allowsDefaultTighteningForTruncation = true
            label.lineBreakMode = .byTruncatingMiddle
            label.font = UX.baseFont
        }

        pageTitleLabel.font = UIFont.boldSystemFont(ofSize: UX.baseFont.pointSize)
        pageTitleLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(UX.rowInset)
            make.left.equalToSuperview().inset(UX.pageInfoRowLeftInset)
            make.bottom.equalTo(row.snp.centerY)
        }

        urlLabel.snp.makeConstraints {
            make in
            make.right.equalToSuperview().inset(UX.rowInset)
            make.left.equalToSuperview().inset(UX.pageInfoRowLeftInset)
            make.top.equalTo(pageTitleLabel.snp.bottom).offset(4)
        }

        return (row, pageTitleLabel, urlLabel)
    }

    private func makeActionRow(label: String, imageName: String, action: @escaping (() -> Void), hasNavigation: Bool) -> UIView {
        let row = UIView()
        let icon = UIImageView(image: UIImage(named: imageName))
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.font = UX.baseFont

        title.text = label
        [icon, title].forEach { row.addSubview($0) }

        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(UX.rowInset)
            make.centerY.equalToSuperview()
            make.width.equalTo(34)
        }

        title.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.equalTo(icon.snp.right).offset(UX.actionRowSpacingBetweenIconAndTitle)
        }

        if hasNavigation {
            let navButton = UIImageView(image: UIImage(named: "menu-Disclosure"))
            navButton.contentMode = .scaleAspectFit
            row.addSubview(navButton)
            navButton.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(UX.rowInset)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(14)
            }
        }

        let gesture = UITapGestureRecognizer(target: self, action:  #selector(handleRowTapGesture))
        row.addGestureRecognizer(gesture)
        // map the gesture to the action func that will be called when the gesture is performed
        actions[gesture] = action

        actionRows.append(row)
        return row
    }

    @objc fileprivate func handleRowTapGesture(sender: UITapGestureRecognizer) {
        if let action = actions[sender] {
            actions.removeAll() // actions can only be called once
            action()
        }
    }

    fileprivate func animateToActionDoneView(withTitle title: String = "") {
        navigationItem.leftBarButtonItem = nil

        navigationController?.view.snp.updateConstraints {
            make in
            make.height.equalTo(UX.viewHeightForDoneState)
        }

        UIView.animate(withDuration: 0.2, animations: {
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

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.boldSystemFont(ofSize: 18)

        [label, checkmark].forEach {
            blue.addSubview($0)
            $0.textColor = .white
        }

        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(UX.pageInfoRowLeftInset)
            make.right.equalTo(checkmark.snp.left)
        }

        checkmark.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(UX.rowInset)
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
        stackView.distribution = .fill
        stackView.alignment = .fill
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
            makeActionRow(label: Strings.ShareLoadInBackground, imageName: "menu-Show-Tabs", action: actionLoadInBackground, hasNavigation: false),
            makeActionRow(label: Strings.ShareBookmarkThisPage, imageName: "AddToBookmarks", action: actionBookmarkThisPage, hasNavigation: false),
            makeActionRow(label: Strings.ShareAddToReadingList, imageName: "AddToReadingList", action: actionAddToReadingList, hasNavigation: false),
            makeSeparator(),
            makeActionRow(label: Strings.ShareSendToDevice, imageName: "menu-Send-to-Device", action: actionSendToDevice, hasNavigation: true),
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
                make.height.equalTo(UX.actionRowHeight)
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
    func actionLoadInBackground() {
        animateToActionDoneView(withTitle: Strings.ShareLoadInBackgroundDone)

        if let shareItem = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.queue.addToQueue(shareItem).uponQueue(.main) { _ in
                profile.shutdown()
            }
        }

        finish()
    }

    func actionBookmarkThisPage() {
        animateToActionDoneView(withTitle: Strings.ShareBookmarkThisPageDone)

        if let shareItem = shareItem {
            let profile = BrowserProfile(localName: "profile")
            _ = profile.bookmarks.shareItem(shareItem).value // Blocks until database has settled
            profile.shutdown()
        }

        finish()
    }

    func actionAddToReadingList() {
        animateToActionDoneView(withTitle: Strings.ShareAddToReadingListDone)

        if let shareItem = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.readingList.createRecordWithURL(shareItem.url, title: shareItem.title ?? "", addedBy: UIDevice.current.name)
            profile.shutdown()
        }

        finish()
    }

    func actionSendToDevice() {
        sendToDevice = SendToDevice()
        guard let sendToDevice = sendToDevice else { return }
        sendToDevice.sharedItem = shareItem
        sendToDevice.delegate = delegate
        let vc = sendToDevice.initialViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
