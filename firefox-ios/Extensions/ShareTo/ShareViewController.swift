// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage
import Account
import Common

import class MozillaAppServices.Viaduct
import enum MozillaAppServices.BookmarkRoots

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

// Credit: https://stackoverflow.com/a/48860391/490488
extension String {
    static var quotes: (String, String) {
        guard
            let bQuote = Locale.current.quotationBeginDelimiter,
            let eQuote = Locale.current.quotationEndDelimiter
            else { return ("“", "”") }

        return (bQuote, eQuote)
    }

    var quoted: String {
        let (bQuote, eQuote) = String.quotes
        return bQuote + self + eQuote
    }
}

protocol ShareControllerDelegate: AnyObject {
    func finish(afterDelay: TimeInterval)
    func getValidExtensionContext() -> NSExtensionContext?
    func hidePopupWhenShowingAlert()
}

// Telemetry events are written to NSUserDefaults, and then the host app reads and clears this list.
func addAppExtensionTelemetryEvent(forMethod method: String) {
    let profile = BrowserProfile(localName: "profile")
    var events = profile.prefs.arrayForKey(PrefsKeys.AppExtensionTelemetryEventArray) ?? [[String]]()
    // Currently, only URL objects are shared.
    let event = ["method": method, "object": "url"]
    events.append(event)
    profile.prefs.setObject(events, forKey: PrefsKeys.AppExtensionTelemetryEventArray)
}

class ShareViewController: UIViewController {
    var shareItem: ExtensionUtils.ExtractedShareItem?
    private var viewsShownDuringDoneAnimation = [UIView]()
    private var stackView: UIStackView!
    private var spinner: UIActivityIndicatorView?
    private var actionDoneRow: (row: UIStackView, label: UILabel)!
    private var sendToDevice: SendToDevice?
    private var pageInfoHeight: NSLayoutConstraint?
    private var actionRowHeights = [NSLayoutConstraint]()
    private var pageInfoRowTitleLabel: UILabel?
    private var pageInfoRowUrlLabel: UILabel?
    private let themeManager = DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)

    weak var delegate: ShareControllerDelegate?

    override var extensionContext: NSExtensionContext? {
        return delegate?.getValidExtensionContext()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func currentTheme() -> Theme {
        return themeManager.windowNonspecificTheme()
    }

    func setupUI() {
        let theme = currentTheme()
        view.backgroundColor = theme.colors.layer2
        view.subviews.forEach({ $0.removeFromSuperview() })

        setupNavBar()
        setupStackView()

        if RustFirefoxAccounts.shared.accountManager == nil {
            // Show brief spinner in UI while startup is finishing
            showProgressIndicator()

            let profile = BrowserProfile(localName: "profile")
            Viaduct.shared.useReqwestBackend()
            RustFirefoxAccounts.startup(prefs: profile.prefs) { [weak self] _ in
                // Hide spinner and finish UI setup (Note: this completion
                // block is currently guaranteed to arrive on main thread.)
                self?.hideProgressIndicator()
                self?.finalizeUISetup()
            }
        } else {
            finalizeUISetup()
        }
    }

    private func finalizeUISetup() {
        setupRows()

        guard let shareItem = shareItem else { return }

        switch shareItem {
        case .shareItem(let item):
            self.pageInfoRowUrlLabel?.text = item.url
            self.pageInfoRowTitleLabel?.text = item.title
        case .rawText(let text):
            self.pageInfoRowTitleLabel?.text = text.quoted
        }
    }

    private func setupRows() {
        let theme = currentTheme()
        let pageInfoRow = makePageInfoRow(addTo: stackView)
        pageInfoRowTitleLabel = pageInfoRow.titleLabel
        pageInfoRowTitleLabel?.textColor = theme.colors.textPrimary
        pageInfoRowUrlLabel = pageInfoRow.urlLabel
        pageInfoRowUrlLabel?.textColor = theme.colors.textPrimary
        makeSeparator(addTo: stackView)

        if shareItem?.isUrlType() ?? true {
            makeActionRow(
                addTo: stackView,
                label: .ShareOpenInFirefox,
                imageName: StandardImageIdentifiers.Large.logoFirefox,
                action: #selector(actionOpenInFirefoxNow),
                hasNavigation: false
            )
            makeActionRow(
                addTo: stackView,
                label: .ShareLoadInBackground,
                imageName: StandardImageIdentifiers.Large.tabTray,
                action: #selector(actionLoadInBackground),
                hasNavigation: false
            )
            makeActionRow(
                addTo: stackView,
                label: .ShareBookmarkThisPage,
                imageName: StandardImageIdentifiers.Large.bookmark,
                action: #selector(actionBookmarkThisPage),
                hasNavigation: false
            )
            makeActionRow(
                addTo: stackView,
                label: .ShareAddToReadingList,
                imageName: StandardImageIdentifiers.Large.readingListAdd,
                action: #selector(actionAddToReadingList),
                hasNavigation: false
            )
            makeSeparator(addTo: stackView)
            makeActionRow(
                addTo: stackView,
                label: .ShareSendToDevice,
                imageName: StandardImageIdentifiers.Large.deviceDesktopSend,
                action: #selector(actionSendToDevice),
                hasNavigation: true
            )
        } else {
            pageInfoRowUrlLabel?.removeFromSuperview()
            makeActionRow(
                addTo: stackView,
                label: .ShareSearchInFirefox,
                imageName: StandardImageIdentifiers.Large.search,
                action: #selector(actionSearchInFirefox),
                hasNavigation: false
            )
        }

        let footerSpaceRow = UIView()
        footerSpaceRow.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(footerSpaceRow)
        // Without some growable space at the bottom there are constraint errors because the UIView space
        // doesn't subdivide equally, and none of the rows are growable. Also, during the animation to the
        // done state, without this space, the page info label moves down slightly.
        footerSpaceRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true

        actionDoneRow = makeActionDoneRow(addTo: stackView)
        // Fully constructing and pre-adding as a subview ensures that only the show operation will animate
        // during the UIView.animate(), and other animatable properties will not unexpectedly animate because
        // they are modified in the same event loop as the animation.
        actionDoneRow.row.isHidden = true

        // All other views are hidden for the done animation.
        viewsShownDuringDoneAnimation += [pageInfoRow.row, footerSpaceRow, actionDoneRow.row]
    }

    private func makeSeparator(addTo parent: UIStackView) {
        let theme = currentTheme()
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = theme.colors.borderPrimary
        parent.addArrangedSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            view.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func layout(forTraitCollection traitCollection: UITraitCollection) {
        let isSearchMode = !(shareItem?.isUrlType() ?? true) // Dialog doesn't change size in search mode
        if !UX.enableResizeRowsForSmallScreens || isSearchMode {
            return
        }

        let pageInfoHeightAdjustment = UX.pageInfoRowHeight - UX.perRowShrinkageForLandscape
        pageInfoHeight?.constant = CGFloat(
            isLandscapeSmallScreen(traitCollection) ? pageInfoHeightAdjustment : UX.pageInfoRowHeight
        )
        let actionRowHeightAdjustment = UX.actionRowHeight - UX.perRowShrinkageForLandscape
        actionRowHeights.forEach {
            $0.constant = CGFloat(
                isLandscapeSmallScreen(traitCollection) ? actionRowHeightAdjustment : UX.actionRowHeight
            )
        }
    }

    struct PageInfoRow {
        let row: UIStackView
        let titleLabel: UILabel
        let urlLabel: UILabel
    }

    private func makePageInfoRow(addTo parent: UIStackView) -> PageInfoRow {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        let pageInfoHeightAdjustment = UX.pageInfoRowHeight - UX.perRowShrinkageForLandscape
        pageInfoHeight = row.heightAnchor.constraint(
            equalToConstant: CGFloat(
                isLandscapeSmallScreen(traitCollection) ? pageInfoHeightAdjustment : UX.pageInfoRowHeight
            )
        )
        pageInfoHeight?.isActive = true

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

        return PageInfoRow(row: row, titleLabel: pageTitleLabel, urlLabel: urlLabel)
    }

    private func makeActionRow(
        addTo parent: UIStackView,
        label: String,
        imageName: String,
        action: Selector,
        hasNavigation: Bool
    ) {
        let theme = currentTheme()
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = UX.actionRowSpacingBetweenIconAndTitle
        row.translatesAutoresizingMaskIntoConstraints = false
        row.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(row)
        let heightAdjustment = UX.actionRowHeight - UX.perRowShrinkageForLandscape
        let heightConstraint = row.heightAnchor.constraint(
            equalToConstant: CGFloat(isLandscapeSmallScreen(traitCollection) ? heightAdjustment : UX.actionRowHeight)
        )
        heightConstraint.isActive = true
        actionRowHeights.append(heightConstraint)

        let icon = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
        icon.contentMode = .scaleAspectFit
        icon.tintColor = theme.colors.iconPrimary
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.font = UX.baseFont
        title.handleLongLabels()
        title.textColor = theme.colors.textPrimary
        title.text = label
        [icon, title].forEach { row.addArrangedSubview($0) }
        icon.widthAnchor.constraint(equalToConstant: CGFloat(UX.actionRowIconSize)).isActive = true

        if hasNavigation {
            let navButton = UIImageView(
                image: UIImage(named: StandardImageIdentifiers.Large.chevronRight)?.withRenderingMode(.alwaysTemplate)
            )
            navButton.contentMode = .scaleAspectFit
            navButton.tintColor = theme.colors.textPrimary
            navButton.translatesAutoresizingMaskIntoConstraints = false
            row.addArrangedSubview(navButton)
            navButton.widthAnchor.constraint(equalToConstant: 14).isActive = true
        }

        let gesture = UITapGestureRecognizer(target: self, action: action)
        row.addGestureRecognizer(gesture)
    }

    fileprivate func animateToActionDoneView(withTitle title: String = "") {
        navigationItem.leftBarButtonItem = nil

        navigationController?.view.translatesAutoresizingMaskIntoConstraints = false
        navigationController?.view.heightAnchor.constraint(
            equalToConstant: CGFloat(UX.viewHeightForDoneState)
        ).isActive = true

        actionDoneRow.label.text = title

        UIView.animate(withDuration: UX.doneDialogAnimationDuration) {
            self.actionDoneRow.row.isHidden = false
            self.stackView.arrangedSubviews
                .filter { !self.viewsShownDuringDoneAnimation.contains($0) }
                .forEach { $0.removeFromSuperview() }

            self.navigationController?.view.superview?.layoutIfNeeded()
        }
    }

    @objc
    func finish(afterDelay: TimeInterval = UX.durationToShowDoneDialog) {
        delegate?.finish(afterDelay: afterDelay)
    }

    private func makeActionDoneRow(addTo parent: UIStackView) -> (row: UIStackView, label: UILabel) {
        let theme = currentTheme()
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addBackground(color: theme.colors.iconAccent)
        stackView.rightLeftEdges(inset: UX.rowInset)
        parent.addArrangedSubview(stackView)
        stackView.heightAnchor.constraint(equalToConstant: CGFloat(UX.pageInfoRowHeight)).isActive = true

        let label = UILabel()
        label.font = UX.doneLabelFont
        label.handleLongLabels()

        let checkmark = UILabel()
        checkmark.text = "✓"
        checkmark.font = UIFont.boldSystemFont(ofSize: 22)
        checkmark.translatesAutoresizingMaskIntoConstraints = false

        [label, checkmark].forEach {
            stackView.addArrangedSubview($0)
            $0.textColor = .white
        }

        checkmark.widthAnchor.constraint(equalToConstant: 20).isActive = true

        return (stackView, label)
    }

    private func setupNavBar() {
        let theme = currentTheme()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = theme.colors.layer2
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.titleView = UIImageView(image: UIImage(named: "Icon-Small"))
        navigationItem.titleView?.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: .SendToCancelButton,
            style: .plain,
            target: self,
            action: #selector(finish)
        )
    }

    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
         ])
    }

    private func showProgressIndicator() {
        let indicator = UIActivityIndicatorView(style: .large)
        let defaultSize = CGSize(width: 40.0, height: 40.0)
        view.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicator.widthAnchor.constraint(equalToConstant: defaultSize.width),
            indicator.heightAnchor.constraint(equalToConstant: defaultSize.height),
         ])
        indicator.startAnimating()
        spinner = indicator
    }

    private func hideProgressIndicator() {
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
        spinner = nil
    }
}

extension ShareViewController {
    @objc
    func actionLoadInBackground(gesture: UIGestureRecognizer) {
        // To avoid re-rentry from double tap, each action function disables the gesture
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: .ShareLoadInBackgroundDone)

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.queue.addToQueue(item).uponQueue(.main) { _ in
                profile.shutdown()
            }

            addAppExtensionTelemetryEvent(forMethod: "load-in-background")
        }

        finish()
    }

    @objc
    func actionBookmarkThisPage(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: .ShareBookmarkThisPageDone)

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.reopen()
            // Intentionally block thread with database call.
            // Add new mobile bookmark at the top of the list
            _ = profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID,
                                              url: item.url,
                                              title: item.title,
                                              position: 0).value
            profile.shutdown()

            addAppExtensionTelemetryEvent(forMethod: "bookmark-this-page")
        }

        finish()
    }

    @objc
    func actionAddToReadingList(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false
        animateToActionDoneView(withTitle: .ShareAddToReadingListDone)

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            let profile = BrowserProfile(localName: "profile")
            profile.reopen()
            profile.readingList.createRecordWithURL(item.url, title: item.title ?? "", addedBy: UIDevice.current.name)
            profile.shutdown()

            addAppExtensionTelemetryEvent(forMethod: "add-to-reading-list")
        }

        finish()
    }

    @objc
    func actionSendToDevice(gesture: UIGestureRecognizer) {
        guard let shareItem = shareItem, case .shareItem(let item) = shareItem else { return }

        gesture.isEnabled = false
        self.sendToDevice = SendToDevice()
        guard let sendToDevice = self.sendToDevice else { return }
        sendToDevice.sharedItem = item
        sendToDevice.delegate = self.delegate
        let vc = sendToDevice.initialViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    func openFirefox(withUrl url: String, isSearch: Bool) {
        // Telemetry is handled in the app delegate that receives this event.
        let profile = BrowserProfile(localName: "profile")
        profile.prefs.setBool(true, forKey: PrefsKeys.AppExtensionTelemetryOpenUrl)

        func firefoxUrl(_ url: String) -> String {
            let encoded = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.alphanumerics) ?? ""
            if isSearch {
                return "firefox://open-text?text=\(encoded)"
            }
            return "firefox://open-url?url=\(encoded)"
        }

        guard let url = URL(string: firefoxUrl(url), invalidCharacters: false) else { return }
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        while let current = responder {
            if current.responds(to: selectorOpenURL) {
                current.perform(selectorOpenURL, with: url, afterDelay: 0)
                break
            }

            responder = current.next
        }
    }

    @objc
    func actionSearchInFirefox(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false

        if let shareItem = shareItem, case .rawText(let text) = shareItem {
            openFirefox(withUrl: text, isSearch: true)
        }

        finish(afterDelay: 0)
    }

    @objc
    func actionOpenInFirefoxNow(gesture: UIGestureRecognizer) {
        gesture.isEnabled = false

        if let shareItem = shareItem, case .shareItem(let item) = shareItem {
            openFirefox(withUrl: item.url, isSearch: false)
        }

        finish(afterDelay: 0)
    }
}
