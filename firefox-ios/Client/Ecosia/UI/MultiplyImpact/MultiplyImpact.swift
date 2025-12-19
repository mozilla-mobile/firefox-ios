// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import UniformTypeIdentifiers
import MobileCoreServices
import LinkPresentation
import Common
import Ecosia

class MultiplyImpact: UIViewController, Themeable {

    // MARK: - UX

    private struct UX {
        private init() {}
        static let hardcodedDarkTextColor = EcosiaDarkTheme().colors.ecosia.textPrimary
        static let defaultPadding: CGFloat = 16
        static let subtitleMargin: CGFloat = 8
        static let defaultCornerRadius: CGFloat = 10

        struct Card {
            private init() {}
            static let distanceFromCardBottom: CGFloat = 32
            static let cardBottomMargin: CGFloat = 17
            static let cardIconTopMargin: CGFloat = 17
            static let cardTitleLeftMargin: CGFloat = 12
            static let cardTreeCountLeftMargin: CGFloat = 12
            static let cardTreeIconLeftMargin: CGFloat = 8
        }

        struct InviteFriendsFeature {
            private init() {}
            static let copyControlBorderWidth: CGFloat = 1
            static let copyLinkRightMargin: CGFloat = -10
            static let copyTextRightMargin: CGFloat = -12
            static let copyDividerLeftRightMargin: CGFloat = -10
            static let defaultTopMargin: CGFloat = 21
            static let cornerRadius: CGFloat = 22
            static let defaultHeight: CGFloat = 44
        }

        struct Flow {
            private init() {}
            static let flowTitleStackTopMargin: CGFloat = 36
            static let flowBackgroundBottomMargin: CGFloat = -20
            static let stackViewSpacing: CGFloat = 12
        }
    }

    // MARK: - Properties
    weak var delegate: SharedHomepageCellDelegate?

    private weak var subtitle: UILabel?
    private weak var topBackground: UIView?
    private weak var yourInvites: UILabel?
    private lazy var referralImpactRowView: NTPImpactRowView = {
        let view = NTPImpactRowView(info: referralInfo)
        view.forceHideActionButton = true
        view.position = (0, 1)
        return view
    }()

    var referralInfo: ClimateImpactInfo {
        .referral(value: User.shared.referrals.count)
    }

    private weak var sharingYourLink: UILabel?
    private weak var sharing: UIView?
    private(set) weak var copyControl: UIControl?
    private weak var copyLink: UILabel?
    private weak var copyText: UILabel?
    private weak var copyDividerLeft: UIView?
    private weak var copyDividerRight: UIView?
    private weak var moreSharingMethods: UILabel?
    private(set) weak var inviteButton: EcosiaPrimaryButton!

    private(set) weak var learnMoreButton: UIButton?

    private weak var flowTitle: UILabel?
    private weak var flowBackground: UIView?
    private weak var flowStack: UIStackView?

    private weak var firstStep: MultiplyImpactStep?
    private weak var secondStep: MultiplyImpactStep?
    private weak var thirdStep: MultiplyImpactStep?
    private weak var fourthStep: MultiplyImpactStep?

    private weak var referrals: Referrals!

    // MARK: - Themeable Properties

    let windowUUID: WindowUUID
    var currentWindowUUID: WindowUUID? { windowUUID }
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    required init?(coder: NSCoder) { nil }
    init(referrals: Referrals,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.referrals = referrals
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .localized(.growingTogether)

        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        navigationItem.rightBarButtonItem = done

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.contentInsetAdjustmentBehavior = .scrollableAxes
        view.addSubview(scroll)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        let topBackground = UIView()
        topBackground.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(topBackground)
        self.topBackground = topBackground

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.numberOfLines = 0
        subtitle.text = .localized(.inviteYourFriendsToCheck)
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitle.adjustsFontForContentSizeCategory = true
        content.addSubview(subtitle)
        self.subtitle = subtitle

        let yourInvites = UILabel()
        yourInvites.text = .localized(.yourInvites)
        content.addSubview(yourInvites)
        self.yourInvites = yourInvites

        content.addSubview(referralImpactRowView)

        let sharingYourLink = UILabel()
        sharingYourLink.text = .localized(.sharingYourLink)
        content.addSubview(sharingYourLink)
        self.sharingYourLink = sharingYourLink

        let sharing = UIView()
        self.sharing = sharing

        let copyControl = UIControl()
        copyControl.layer.cornerRadius = UX.defaultCornerRadius
        copyControl.layer.borderWidth = UX.InviteFriendsFeature.copyControlBorderWidth
        copyControl.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
        copyControl.addTarget(self, action: #selector(hover), for: .touchDown)
        copyControl.addTarget(self, action: #selector(unhover), for: .touchUpInside)
        copyControl.addTarget(self, action: #selector(unhover), for: .touchUpOutside)
        copyControl.addTarget(self, action: #selector(unhover), for: .touchCancel)
        self.copyControl = copyControl

        let copyLink = UILabel()
        copyLink.translatesAutoresizingMaskIntoConstraints = false
        copyLink.adjustsFontForContentSizeCategory = true
        copyLink.font = .preferredFont(forTextStyle: .body)
        copyLink.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        copyLink.numberOfLines = 1
        copyControl.addSubview(copyLink)
        self.copyLink = copyLink

        let copyText = UILabel()
        copyText.translatesAutoresizingMaskIntoConstraints = false
        copyText.text = .localized(.copy)
        copyText.font = .preferredFont(forTextStyle: .body)
        copyText.adjustsFontForContentSizeCategory = true
        copyControl.addSubview(copyText)
        self.copyText = copyText

        let copyDividerLeft = UIView()
        self.copyDividerLeft = copyDividerLeft

        let copyDividerRight = UIView()
        self.copyDividerRight = copyDividerRight

        let moreSharingMethods = UILabel()
        moreSharingMethods.translatesAutoresizingMaskIntoConstraints = false
        moreSharingMethods.adjustsFontForContentSizeCategory = true
        moreSharingMethods.font = .systemFont(ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize, weight: .semibold)
        moreSharingMethods.text = .localized(.moreSharingMethods)
        sharing.addSubview(moreSharingMethods)
        self.moreSharingMethods = moreSharingMethods

        let inviteFriends = EcosiaPrimaryButton(windowUUID: windowUUID)
        inviteFriends.setTitle(.localized(.inviteFriends), for: [])
        inviteFriends.titleLabel!.font = .preferredFont(forTextStyle: .callout)
        inviteFriends.titleLabel!.adjustsFontForContentSizeCategory = true
        inviteFriends.layer.cornerRadius = UX.InviteFriendsFeature.cornerRadius
        inviteFriends.addTarget(self, action: #selector(self.inviteFriends), for: .touchUpInside)
        self.inviteButton = inviteFriends

        let flowTitleStack = UIStackView()
        flowTitleStack.translatesAutoresizingMaskIntoConstraints = false
        flowTitleStack.alignment = .fill
        flowTitleStack.axis = .horizontal
        content.addSubview(flowTitleStack)

        let flowTitle = UILabel()
        flowTitle.text = .localized(.howItWorks)
        flowTitleStack.addArrangedSubview(flowTitle)
        self.flowTitle = flowTitle

        let learnMoreButton = UIButton(type: .system)
        learnMoreButton.addTarget(self, action: #selector(learnMore), for: .primaryActionTriggered)
        learnMoreButton.translatesAutoresizingMaskIntoConstraints = false
        learnMoreButton.setTitle(.localized(.learnMore), for: .normal)
        learnMoreButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        learnMoreButton.titleLabel?.adjustsFontForContentSizeCategory = true
        learnMoreButton.setContentHuggingPriority(.required, for: .horizontal)
        flowTitleStack.addArrangedSubview(learnMoreButton)
        self.learnMoreButton = learnMoreButton

        let flowBackground = UIView()
        self.flowBackground = flowBackground

        let flowStack = UIStackView()
        flowStack.translatesAutoresizingMaskIntoConstraints = false
        flowStack.axis = .vertical
        flowStack.alignment = .leading
        flowStack.spacing = UX.Flow.stackViewSpacing
        flowBackground.addSubview(flowStack)

        let firstStep = MultiplyImpactStep(title: .localized(.inviteYourFriends), subtitle: .localized(.sendAnInvite), image: "paperplane")
        flowStack.addArrangedSubview(firstStep)
        self.firstStep = firstStep

        let secondStep = MultiplyImpactStep(title: .localized(.theyDownloadTheApp), subtitle: .localized(.viaTheAppStore), image: "libraryDownloads")
        flowStack.addArrangedSubview(secondStep)
        self.secondStep = secondStep

        let thirdStep = MultiplyImpactStep(title: .localized(.theyOpenYourInviteLink), subtitle: .localized(.yourFriendClicks), image: "menu-Copy-Link")
        flowStack.addArrangedSubview(thirdStep)
        self.thirdStep = thirdStep

        let fourthStep = MultiplyImpactStep(title: .localized(.eachOfYouHelpsPlant), subtitle: .localized(.whenAFriendUses), image: "myImpact")
        flowStack.addArrangedSubview(fourthStep)
        self.fourthStep = fourthStep

        [yourInvites, sharingYourLink, flowTitle].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = .preferredFont(forTextStyle: .headline).bold()
            $0.adjustsFontForContentSizeCategory = true
            $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
        }

        [sharing, flowBackground].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = UX.defaultCornerRadius
            content.addSubview($0)

            $0.leftAnchor.constraint(equalTo: content.leftAnchor, constant: UX.defaultPadding).isActive = true
            $0.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -UX.defaultPadding).isActive = true
        }

        [copyControl, inviteFriends].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            sharing.addSubview($0)

            $0.leftAnchor.constraint(equalTo: sharing.leftAnchor, constant: UX.defaultPadding).isActive = true
            $0.rightAnchor.constraint(equalTo: sharing.rightAnchor, constant: -UX.defaultPadding).isActive = true
            $0.heightAnchor.constraint(equalToConstant: UX.InviteFriendsFeature.defaultHeight).isActive = true
        }

        [copyDividerLeft, copyDividerRight].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.isUserInteractionEnabled = false
            sharing.addSubview($0)

            $0.topAnchor.constraint(equalTo: copyControl.bottomAnchor, constant: UX.InviteFriendsFeature.defaultTopMargin).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 1).isActive = true
        }

        scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scroll.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        scroll.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor).isActive = true
        content.leftAnchor.constraint(equalTo: scroll.frameLayoutGuide.leftAnchor).isActive = true
        content.rightAnchor.constraint(equalTo: scroll.frameLayoutGuide.rightAnchor).isActive = true
        content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor).isActive = true

        subtitle.topAnchor.constraint(equalTo: content.topAnchor, constant: UX.subtitleMargin).isActive = true
        subtitle.leftAnchor.constraint(equalTo: content.leftAnchor, constant: UX.defaultPadding).isActive = true
        subtitle.rightAnchor.constraint(lessThanOrEqualTo: content.rightAnchor, constant: -UX.defaultPadding).isActive = true

        topBackground.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
        topBackground.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
        topBackground.topAnchor.constraint(equalTo: content.topAnchor).isActive = true
        topBackground.bottomAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: UX.subtitleMargin).isActive = true

        yourInvites.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: UX.defaultPadding).isActive = true
        yourInvites.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -UX.defaultPadding).isActive = true
        yourInvites.topAnchor.constraint(equalTo: topBackground.bottomAnchor, constant: UX.defaultPadding).isActive = true

        referralImpactRowView.leftAnchor.constraint(equalTo: content.leftAnchor, constant: UX.defaultPadding).isActive = true
        referralImpactRowView.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -UX.defaultPadding).isActive = true
        referralImpactRowView.topAnchor.constraint(equalTo: yourInvites.bottomAnchor, constant: UX.defaultPadding).isActive = true

        sharingYourLink.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: UX.defaultPadding).isActive = true
        sharingYourLink.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -UX.defaultPadding).isActive = true
        sharingYourLink.topAnchor.constraint(equalTo: referralImpactRowView.bottomAnchor, constant: UX.Card.distanceFromCardBottom).isActive = true

        sharing.topAnchor.constraint(equalTo: sharingYourLink.bottomAnchor, constant: UX.defaultPadding).isActive = true

        copyControl.topAnchor.constraint(equalTo: sharing.topAnchor, constant: UX.defaultPadding).isActive = true

        copyLink.centerYAnchor.constraint(equalTo: copyControl.centerYAnchor).isActive = true
        copyLink.leftAnchor.constraint(equalTo: copyControl.leftAnchor, constant: UX.defaultPadding).isActive = true
        copyLink.rightAnchor.constraint(lessThanOrEqualTo: copyText.leftAnchor, constant: UX.InviteFriendsFeature.copyLinkRightMargin).isActive = true

        copyText.centerYAnchor.constraint(equalTo: copyControl.centerYAnchor).isActive = true
        copyText.rightAnchor.constraint(equalTo: copyControl.rightAnchor, constant: UX.InviteFriendsFeature.copyTextRightMargin).isActive = true

        copyDividerLeft.leftAnchor.constraint(equalTo: copyControl.leftAnchor).isActive = true
        copyDividerLeft.rightAnchor.constraint(equalTo: moreSharingMethods.leftAnchor, constant: UX.InviteFriendsFeature.copyDividerLeftRightMargin).isActive = true
        copyDividerRight.rightAnchor.constraint(equalTo: copyControl.rightAnchor).isActive = true
        copyDividerRight.leftAnchor.constraint(equalTo: moreSharingMethods.rightAnchor, constant: UX.InviteFriendsFeature.copyDividerLeftRightMargin).isActive = true

        moreSharingMethods.centerXAnchor.constraint(equalTo: sharing.centerXAnchor).isActive = true
        moreSharingMethods.centerYAnchor.constraint(equalTo: copyDividerLeft.centerYAnchor).isActive = true

        inviteFriends.topAnchor.constraint(equalTo: copyDividerLeft.bottomAnchor, constant: UX.InviteFriendsFeature.defaultTopMargin).isActive = true
        inviteFriends.bottomAnchor.constraint(equalTo: sharing.bottomAnchor, constant: -UX.defaultPadding).isActive = true

        flowTitleStack.leftAnchor.constraint(equalTo: content.leftAnchor, constant: UX.defaultPadding).isActive = true
        flowTitleStack.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -UX.defaultPadding).isActive = true
        flowTitleStack.topAnchor.constraint(equalTo: sharing.bottomAnchor, constant: UX.Flow.flowTitleStackTopMargin).isActive = true

        flowBackground.topAnchor.constraint(equalTo: flowTitleStack.bottomAnchor, constant: UX.defaultPadding).isActive = true
        flowBackground.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: UX.Flow.flowBackgroundBottomMargin).isActive = true

        flowStack.leftAnchor.constraint(equalTo: flowBackground.leftAnchor, constant: UX.defaultPadding).isActive = true
        flowStack.rightAnchor.constraint(equalTo: flowBackground.rightAnchor, constant: -UX.defaultPadding).isActive = true
        flowStack.topAnchor.constraint(equalTo: flowBackground.topAnchor, constant: UX.defaultPadding).isActive = true
        flowStack.bottomAnchor.constraint(equalTo: flowBackground.bottomAnchor, constant: -UX.defaultPadding).isActive = true

        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateInviteLink()
        refreshReferrals()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.shared.referral(action: .view, label: .inviteScreen)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)

        view.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        inviteButton.backgroundColor = theme.colors.ecosia.buttonBackgroundFeatured
        inviteButton.setTitleColor(theme.colors.ecosia.buttonContentSecondaryStatic, for: .normal)
        learnMoreButton?.setTitleColor(theme.colors.ecosia.brandPrimary, for: .normal)
        topBackground?.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        subtitle?.textColor = theme.colors.ecosia.textSecondary
        copyControl?.backgroundColor = theme.colors.ecosia.backgroundSecondary
        copyControl?.layer.borderColor = theme.colors.ecosia.borderDecorative.cgColor
        moreSharingMethods?.textColor = theme.colors.ecosia.textSecondary
        copyText?.textColor = theme.colors.ecosia.brandPrimary

        [yourInvites, sharingYourLink, flowTitle, copyLink].forEach {
            $0?.textColor = theme.colors.ecosia.textPrimary
        }

        [sharing, flowBackground].forEach {
            $0?.backgroundColor = theme.colors.ecosia.backgroundElevation1
        }

        [firstStep, secondStep, thirdStep, fourthStep].forEach {
            $0?.applyTheme(theme: theme)
        }

        [copyDividerLeft, copyDividerRight].forEach {
            $0?.backgroundColor = theme.colors.ecosia.borderDecorative
        }

        referralImpactRowView.customBackgroundColor = theme.colors.ecosia.backgroundElevation1
        referralImpactRowView.applyTheme(theme: theme)

        updateBarAppearance(theme: theme)
    }

    private func updateBarAppearance(theme: Theme) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: theme.colors.ecosia.textPrimary]
        appearance.titleTextAttributes = [.foregroundColor: theme.colors.ecosia.textPrimary]
        appearance.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        appearance.shadowColor = nil
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        navigationController?.navigationBar.tintColor = theme.colors.ecosia.buttonContentSecondary
    }

    private func updateInviteLink() {
        copyLink?.text = inviteLink ?? inviteLinkPlaceholder
    }

    private func refreshReferrals() {
        Task { [weak self] in
            do {
                try await self?.referrals.refresh(force: true, createCode: true)
                guard let self = self else { return }
                self.updateInviteLink()
                self.referralImpactRowView.info = self.referralInfo
            } catch {
                self?.showRefreshReferralsError(error as? Referrals.Error ?? .genericError)
            }
        }
    }

    @objc private func learnMore() {
        delegate?.openLink(url: EcosiaEnvironment.current.urlProvider.referHelp)
        dismiss(animated: true)
        Analytics.shared.referral(action: .click, label: .learnMore)
    }

    @objc private func hover() {
        copyControl?.alpha = 0.3
    }

    @objc private func unhover() {
        copyControl?.alpha = 1
    }

    @objc private func copyCode() {
        unhover()
        guard let message = inviteMessage else { return }
        UIPasteboard.general.setValue(message, forPasteboardType: UTType.plainText.identifier)
        copyText?.text = .localized(.copied)
        Analytics.shared.referral(action: .click, label: .linkCopying)
    }

    @objc private func inviteFriends() {
        guard let message = inviteMessage else {
            Task { [weak self] in
                do {
                    try await self?.referrals.refresh(createCode: true)
                    guard let self = self else { return }
                    self.share(message: self.inviteMessage!)
                } catch {
                    self?.showInviteFriendsError(error as? Referrals.Error ?? .genericError)
                }
            }
            return
        }
        share(message: message)
    }

    private func share(message: String) {
        let share = UIActivityViewController(activityItems: [SharingMessage(message: message)],
                                             applicationActivities: nil)
        share.popoverPresentationController?.sourceView = inviteButton
        share.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                Analytics.shared.referral(action: .send, label: .invite)
            }
        }
        present(share, animated: true)

        Analytics.shared.referral(action: .click, label: .invite)
    }

    private func showInviteFriendsError(_ error: Referrals.Error) {
        let alert = UIAlertController(title: error.title,
                                      message: error.message,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: .localized(.continueMessage), style: .cancel))
        alert.addAction(.init(title: .localized(.retryMessage), style: .default) { [weak self] _ in
            self?.inviteFriends()
        })
        present(alert, animated: true)
    }

    private func showRefreshReferralsError(_ error: Referrals.Error) {
        let alert = UIAlertController(title: error.title,
                                      message: error.message,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: .localized(.continueMessage), style: .cancel))
        alert.addAction(.init(title: .localized(.retryMessage), style: .default) { [weak self] _ in
            self?.refreshReferrals()
        })
        present(alert, animated: true)
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }

    private var inviteMessage: String? {
        guard let inviteDeepLink, let inviteDeepLinkUrl = URL(string: inviteDeepLink) else { return nil }
        guard let inviteLink else { return nil }

        return """
\(String(format: .localized(.messageMentioningActiveUsers), activeUsers))

\(inviteLink)

\(String.localized(.tapLinkToConfirm))

\(inviteDeepLinkUrl.absoluteString)
"""
    }

    private let inviteLinkPlaceholder = "-"

    private var inviteLink: String? {
        guard let code = User.shared.referrals.code else { return nil }
        return "\(Referrals.sharingLinkRoot)\(code)"
    }

    private var inviteDeepLink: String? {
        guard let code = User.shared.referrals.code else { return nil }
        return "\(Referrals.deepLinkPath)\(code)"
    }

    // MARK: Number formatting
    private var activeUsers: String {
        let activeUsers = Int(Statistics.shared.activeUsers)
        let oneMillion = 1000000
        let million = activeUsers / oneMillion
        return "\(million)"
    }
}

private final class SharingMessage: NSObject, UIActivityItemSource {
    private let message: String

    init(message: String) {
        self.message = message
        super.init()
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        String()
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType: UIActivity.ActivityType?) -> Any? {
        message
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType: UIActivity.ActivityType?) -> String {
        .localized(.plantTreesWithMe)
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = .localized(.plantTreesWithMe)
        return metadata
    }
}
