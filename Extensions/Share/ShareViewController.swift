/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared
import Storage
import Deferred

extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }

    func rightLeftEdges(inset: CGFloat) {
        layoutMargins = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        isLayoutMarginsRelativeArrangement = true
    }
}

extension UILabel {
    // Ensures labels can span a second line and will compress to fit text
    func handleLongLabels() {
        numberOfLines = 2
        adjustsFontSizeToFitWidth = true
        allowsDefaultTighteningForTruncation = true
    }
}

protocol ShareControllerDelegate: class {
    func finish(afterDelay: TimeInterval)
    func getValidExtensionContext() -> NSExtensionContext?
    func getShareItem() -> Deferred<ShareItem?>
}

class ShareViewController: UIViewController {
    private var shareItem: ShareItem?
    private var viewsShownDuringDoneAnimation = [UIView]()
    private var stackView: UIStackView!
    private var sendToDevice: SendToDevice?
    private var actionDoneRow: (row: UIStackView, label: UILabel)!

    weak var delegate: ShareControllerDelegate?

    override var extensionContext: NSExtensionContext? {
        get {
            return delegate?.getValidExtensionContext()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        setupNavBar()
        setupStackView()

        let pageInfoRow = makePageInfoRow(addTo: stackView)
        makeSeparator(addTo: stackView)
        makeActionRow(addTo: stackView, label: Strings.ShareLoadInBackground, imageName: "menu-Show-Tabs", action: #selector(actionLoadInBackground), hasNavigation: false)
        makeActionRow(addTo: stackView, label: Strings.ShareBookmarkThisPage, imageName: "AddToBookmarks", action: #selector(actionBookmarkThisPage), hasNavigation: false)
        makeActionRow(addTo: stackView, label: Strings.ShareAddToReadingList, imageName: "AddToReadingList", action: #selector(actionAddToReadingList), hasNavigation: false)
        makeSeparator(addTo: stackView)
        makeActionRow(addTo: stackView, label: Strings.ShareSendToDevice, imageName: "menu-Send-to-Device", action: #selector(actionSendToDevice), hasNavigation: true)

        let footerSpaceRow = UIView()
        stackView.addArrangedSubview(footerSpaceRow)
        // Without some growable space at the bottom there are constraint errors because the UIView space doesn't subdivide equally, and none of the rows are growable.
        // Also, during the animation to the done state, without this space, the page info label moves down slightly.
        footerSpaceRow.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(0)
        }

        actionDoneRow = makeActionDoneRow(addTo: stackView)
        // Fully constructing and pre-adding as a subview ensures that only the show operation will animate during the UIView.animate(),
        // and other animatable properties will not unexpectedly animate because they are modified in the same event loop as the animation.
        actionDoneRow.row.isHidden = true

        // All other views are hidden for the done animation.
        viewsShownDuringDoneAnimation += [pageInfoRow.row, footerSpaceRow, actionDoneRow.row]

        delegate?.getShareItem().uponQueue(.main) { shareItem in
            guard let shareItem = shareItem, shareItem.isShareable else {
                let alert = UIAlertController(title: Strings.SendToErrorTitle, message: Strings.SendToErrorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Strings.SendToErrorOKButton, style: .default) { _ in self.finish(afterDelay: 0) })
                self.present(alert, animated: true, completion: nil)
                return
            }

            self.shareItem = shareItem
            pageInfoRow.urlLabel.text = shareItem.url
            pageInfoRow.pageTitleLabel.text = shareItem.title
        }
    }

    private func makeSeparator(addTo parent: UIStackView) {
        let view = UIView()
        view.backgroundColor = UX.separatorColor
        parent.addArrangedSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    private func makePageInfoRow(addTo parent: UIStackView) -> (row: UIStackView, pageTitleLabel: UILabel, urlLabel: UILabel) {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        row.snp.makeConstraints { make in
            make.height.equalTo(UX.pageInfoRowHeight)
        }

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = UX.pageInfoLineSpacing

        row.addArrangedSubview(verticalStackView)

        let pageTitleLabel = UILabel()
        let urlLabel = UILabel()
        [pageTitleLabel, urlLabel].forEach { label in
            verticalStackView.addArrangedSubview(label)
            label.allowsDefaultTighteningForTruncation = true
            label.lineBreakMode = .byTruncatingMiddle
            label.font = UX.baseFont
        }

        pageTitleLabel.font = UIFont.boldSystemFont(ofSize: UX.baseFont.pointSize)

        return (row, pageTitleLabel, urlLabel)
    }

    private func makeActionRow(addTo parent: UIStackView, label: String, imageName: String, action: Selector, hasNavigation: Bool) {

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = UX.actionRowSpacingBetweenIconAndTitle
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        row.snp.makeConstraints { make in
            make.height.equalTo(UX.actionRowHeight)
        }

        let icon = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = UX.actionRowTextAndIconColor

        let title = UILabel()
        title.font = UX.baseFont
        title.handleLongLabels()
        title.textColor = UX.actionRowTextAndIconColor
        title.text = label
        [icon, title].forEach { row.addArrangedSubview($0) }

        icon.snp.makeConstraints { make in
            make.width.equalTo(UX.actionRowIconSize)
        }

        if hasNavigation {
            let navButton = UIImageView(image: UIImage(named: "menu-Disclosure")?.withRenderingMode(.alwaysTemplate))
            navButton.contentMode = .scaleAspectFit
            navButton.tintColor = UX.actionRowTextAndIconColor
            row.addArrangedSubview(navButton)
            navButton.snp.makeConstraints { make in
                make.width.equalTo(14)
            }
        }

        let gesture = UITapGestureRecognizer(target: self, action: action)
        row.addGestureRecognizer(gesture)
    }

    fileprivate func animateToActionDoneView(withTitle title: String = "") {
        navigationItem.leftBarButtonItem = nil

        navigationController?.view.snp.updateConstraints { make in
            make.height.equalTo(UX.viewHeightForDoneState)
        }

        actionDoneRow.label.text = title

        UIView.animate(withDuration: UX.doneDialogAnimationDuration) {
            self.actionDoneRow.row.isHidden = false
            self.stackView.arrangedSubviews
                .filter { !self.viewsShownDuringDoneAnimation.contains($0) }
                .forEach { $0.removeFromSuperview() }

            self.navigationController?.view.superview?.layoutIfNeeded()
        }
    }

    @objc func finish(afterDelay: TimeInterval = UX.durationToShowDoneDialog) {
        delegate?.finish(afterDelay: afterDelay)
    }

    private func makeActionDoneRow(addTo parent: UIStackView) -> (row: UIStackView, label: UILabel) {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.addBackground(color: UX.doneLabelBackgroundColor)
        stackView.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.height.equalTo(UX.pageInfoRowHeight)
        }

        let label = UILabel()
        label.font = UX.doneLabelFont
        label.handleLongLabels()

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.boldSystemFont(ofSize: 22)

        [label, checkmark].forEach {
            stackView.addArrangedSubview($0)
            $0.textColor = .white
        }

        checkmark.snp.makeConstraints { make in
            make.width.equalTo(20)
        }

        return (stackView, label)
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

