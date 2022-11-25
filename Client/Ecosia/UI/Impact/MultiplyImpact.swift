/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import UniformTypeIdentifiers
import MobileCoreServices

final class MultiplyImpact: UIViewController, NotificationThemeable {
    private weak var subtitle: UILabel?
    private weak var topBackground: UIView?
    private weak var waves: UIImageView?
    private weak var card: UIView?
    private weak var cardIcon: UIImageView?
    private weak var cardTitle: UILabel?
    private weak var cardTreeCount: UILabel?
    private weak var cardTreeIcon: UIImageView?
    private weak var yourInvites: UILabel?
    
    private weak var sharingYourLink: UILabel?
    private weak var sharing: UIView?
    private weak var copyControl: UIControl?
    private weak var copyLink: UILabel?
    private weak var copyText: UILabel?
    private weak var copyDividerLeft: UIView?
    private weak var copyDividerRight: UIView?
    private weak var moreSharingMethods: UILabel?
    private weak var inviteButton: EcosiaPrimaryButton!
    
    private weak var learnMoreButton: UIButton?
    
    private weak var flowTitle: UILabel?
    private weak var flowBackground: UIView?
    private weak var flowStack: UIStackView?

    private weak var firstStep: MultiplyImpactStep?
    private weak var secondStep: MultiplyImpactStep?
    private weak var thirdStep: MultiplyImpactStep?
    private weak var fourthStep: MultiplyImpactStep?

    private weak var delegate: YourImpactDelegate?
    private weak var referrals: Referrals!
    
    required init?(coder: NSCoder) { nil }
    init(delegate: YourImpactDelegate?, referrals: Referrals) {
        self.referrals = referrals
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
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
        topBackground.backgroundColor = .theme.ecosia.primaryBrand.withAlphaComponent(0.2)
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

        let forest = UIImageView(image: .init(named: "forestIcons"))
        forest.translatesAutoresizingMaskIntoConstraints = false
        forest.contentMode = .bottom
        content.addSubview(forest)

        let waves = UIImageView(image: .init(named: "ntpIntroWaves"))
        waves.translatesAutoresizingMaskIntoConstraints = false
        waves.contentMode = .scaleToFill
        content.addSubview(waves)
        self.waves = waves

        let yourInvites = UILabel()
        yourInvites.text = .localized(.yourInvites)
        content.addSubview(yourInvites)
        self.yourInvites = yourInvites
        
        let card = UIView()
        card.isUserInteractionEnabled = false
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 10
        content.addSubview(card)
        self.card = card
        
        let cardIcon = UIImageView(image: .init(named: "impactReferrals"))
        cardIcon.translatesAutoresizingMaskIntoConstraints = false
        cardIcon.setContentHuggingPriority(.required, for: .vertical)
        cardIcon.contentMode = .center
        card.addSubview(cardIcon)
        self.cardIcon = cardIcon
        
        let cardTitle = UILabel()
        cardTitle.translatesAutoresizingMaskIntoConstraints = false
        cardTitle.numberOfLines = 0
        cardTitle.text = .localizedPlural(.acceptedInvites, num: User.shared.referrals.count)
        cardTitle.font = .preferredFont(forTextStyle: .body)
        cardTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cardTitle.setContentHuggingPriority(.defaultLow, for: .horizontal)
        cardTitle.adjustsFontForContentSizeCategory = true
        card.addSubview(cardTitle)
        self.cardTitle = cardTitle
        
        let cardTreeCount = UILabel()
        cardTreeCount.translatesAutoresizingMaskIntoConstraints = false
        cardTreeCount.numberOfLines = 0
        cardTreeCount.text = "\(User.shared.referrals.impact)"
        cardTreeCount.font = .preferredFont(forTextStyle: .subheadline).bold()
        cardTreeCount.setContentCompressionResistancePriority(.required, for: .horizontal)
        cardTreeCount.setContentCompressionResistancePriority(.required, for: .vertical)
        cardTreeCount.setContentHuggingPriority(.required, for: .horizontal)
        cardTreeCount.adjustsFontForContentSizeCategory = true
        card.addSubview(cardTreeCount)
        self.cardTreeCount = cardTreeCount

        let cardTreeIcon = UIImageView(image: .init(named: "yourImpact")?.withRenderingMode(.alwaysTemplate))
        cardTreeIcon.translatesAutoresizingMaskIntoConstraints = false
        cardTreeIcon.setContentHuggingPriority(.required, for: .horizontal)
        card.addSubview(cardTreeIcon)
        self.cardTreeIcon = cardTreeIcon

        let sharingYourLink = UILabel()
        sharingYourLink.text = .localized(.sharingYourLink)
        content.addSubview(sharingYourLink)
        self.sharingYourLink = sharingYourLink
        
        let sharing = UIView()
        self.sharing = sharing
        
        let copyControl = UIControl()
        copyControl.layer.cornerRadius = 10
        copyControl.layer.borderWidth = 1
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
        copyLink.text = inviteLink ?? "ecosia://invite/"
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
        
        let inviteFriends = EcosiaPrimaryButton(type: .custom)
        inviteFriends.setTitle(.localized(.inviteFriends), for: [])
        inviteFriends.titleLabel!.font = .preferredFont(forTextStyle: .callout)
        inviteFriends.titleLabel!.adjustsFontForContentSizeCategory = true
        inviteFriends.layer.cornerRadius = 22
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
        flowStack.spacing = 12
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
        
        [card, sharing, flowBackground].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = 10
            content.addSubview($0)
            
            $0.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
            $0.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -16).isActive = true
        }
        
        [copyControl, inviteFriends].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            sharing.addSubview($0)
            
            $0.leftAnchor.constraint(equalTo: sharing.leftAnchor, constant: 16).isActive = true
            $0.rightAnchor.constraint(equalTo: sharing.rightAnchor, constant: -16).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        [copyDividerLeft, copyDividerRight].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.isUserInteractionEnabled = false
            sharing.addSubview($0)
            
            $0.topAnchor.constraint(equalTo: copyControl.bottomAnchor, constant: 21).isActive = true
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

        subtitle.topAnchor.constraint(equalTo: content.topAnchor, constant: 8).isActive = true
        subtitle.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
        subtitle.rightAnchor.constraint(lessThanOrEqualTo: content.rightAnchor, constant: -16).isActive = true

        forest.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        forest.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 24).isActive = true

        if view.traitCollection.userInterfaceIdiom == .pad {
            forest.widthAnchor.constraint(equalToConstant: 544).isActive = true
            forest.heightAnchor.constraint(equalToConstant: 135).isActive = true
            forest.contentMode = .scaleAspectFit
        } else {
            forest.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
            forest.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
        }

        waves.bottomAnchor.constraint(equalTo: forest.bottomAnchor, constant: 16).isActive = true
        waves.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
        waves.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
        waves.heightAnchor.constraint(equalToConstant: 34).isActive = true

        topBackground.leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
        topBackground.trailingAnchor.constraint(equalTo: content.trailingAnchor).isActive = true
        topBackground.topAnchor.constraint(equalTo: content.topAnchor).isActive = true
        topBackground.bottomAnchor.constraint(equalTo: waves.bottomAnchor).isActive = true

        yourInvites.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16).isActive = true
        yourInvites.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16).isActive = true
        yourInvites.topAnchor.constraint(equalTo: waves.bottomAnchor, constant: 16).isActive = true

        card.topAnchor.constraint(equalTo: yourInvites.bottomAnchor, constant: 16).isActive = true
        card.bottomAnchor.constraint(equalTo: cardIcon.bottomAnchor, constant: 17).isActive = true

        cardIcon.topAnchor.constraint(equalTo: card.topAnchor, constant: 17).isActive = true
        cardIcon.leftAnchor.constraint(equalTo: card.leftAnchor, constant: 16).isActive = true

        cardTitle.centerYAnchor.constraint(equalTo: cardIcon.centerYAnchor).isActive = true
        cardTitle.leftAnchor.constraint(equalTo: cardIcon.rightAnchor, constant: 12).isActive = true

        cardTreeCount.leftAnchor.constraint(equalTo: cardTitle.rightAnchor, constant: 12).isActive = true
        cardTreeCount.centerYAnchor.constraint(equalTo: cardTitle.centerYAnchor).isActive = true

        cardTreeIcon.leftAnchor.constraint(equalTo: cardTreeCount.rightAnchor, constant: 8).isActive = true
        cardTreeIcon.rightAnchor.constraint(equalTo: card.rightAnchor, constant: -16).isActive = true
        cardTreeIcon.centerYAnchor.constraint(equalTo: cardTreeCount.centerYAnchor).isActive = true

        sharingYourLink.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16).isActive = true
        sharingYourLink.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16).isActive = true
        sharingYourLink.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 32).isActive = true
        
        sharing.topAnchor.constraint(equalTo: sharingYourLink.bottomAnchor, constant: 16).isActive = true
        
        copyControl.topAnchor.constraint(equalTo: sharing.topAnchor, constant: 16).isActive = true
        
        copyLink.centerYAnchor.constraint(equalTo: copyControl.centerYAnchor).isActive = true
        copyLink.leftAnchor.constraint(equalTo: copyControl.leftAnchor, constant: 16).isActive = true
        copyLink.rightAnchor.constraint(lessThanOrEqualTo: copyText.leftAnchor, constant: -10).isActive = true
        
        copyText.centerYAnchor.constraint(equalTo: copyControl.centerYAnchor).isActive = true
        copyText.rightAnchor.constraint(equalTo: copyControl.rightAnchor, constant: -12).isActive = true
        
        copyDividerLeft.leftAnchor.constraint(equalTo: copyControl.leftAnchor).isActive = true
        copyDividerLeft.rightAnchor.constraint(equalTo: moreSharingMethods.leftAnchor, constant: -10).isActive = true
        copyDividerRight.rightAnchor.constraint(equalTo: copyControl.rightAnchor).isActive = true
        copyDividerRight.leftAnchor.constraint(equalTo: moreSharingMethods.rightAnchor, constant: 10).isActive = true
        
        moreSharingMethods.centerXAnchor.constraint(equalTo: sharing.centerXAnchor).isActive = true
        moreSharingMethods.centerYAnchor.constraint(equalTo: copyDividerLeft.centerYAnchor).isActive = true
        
        inviteFriends.topAnchor.constraint(equalTo: copyDividerLeft.bottomAnchor, constant: 21).isActive = true
        inviteFriends.bottomAnchor.constraint(equalTo: sharing.bottomAnchor, constant: -16).isActive = true
        
        flowTitleStack.leftAnchor.constraint(equalTo: content.leftAnchor, constant: 16).isActive = true
        flowTitleStack.rightAnchor.constraint(equalTo: content.rightAnchor, constant: -16).isActive = true
        flowTitleStack.topAnchor.constraint(equalTo: sharing.bottomAnchor, constant: 36).isActive = true

        flowBackground.topAnchor.constraint(equalTo: flowTitleStack.bottomAnchor,constant: 16).isActive = true
        flowBackground.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20).isActive = true

        flowStack.leftAnchor.constraint(equalTo: flowBackground.leftAnchor, constant: 16).isActive = true
        flowStack.rightAnchor.constraint(equalTo: flowBackground.rightAnchor, constant: -16).isActive = true
        flowStack.topAnchor.constraint(equalTo: flowBackground.topAnchor, constant: 16).isActive = true
        flowStack.bottomAnchor.constraint(equalTo: flowBackground.bottomAnchor, constant: -16).isActive = true

        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.shared.openInvitations()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }
    
    func applyTheme() {
        view.backgroundColor = .theme.ecosia.modalBackground
        inviteButton.backgroundColor = .theme.ecosia.primaryBrand
        inviteButton.setTitleColor(.theme.ecosia.primaryTextInverted, for: .normal)
        inviteButton.setTitleColor(.theme.ecosia.primaryTextInverted, for: .highlighted)
        inviteButton.setTitleColor(.theme.ecosia.primaryTextInverted, for: .selected)
        learnMoreButton?.setTitleColor(.theme.ecosia.primaryBrand, for: .normal)
        waves?.tintColor = .theme.ecosia.modalBackground
        topBackground?.backgroundColor = .theme.ecosia.modalHeader
        subtitle?.textColor = .Dark.Text.primary
        copyControl?.backgroundColor = .theme.ecosia.secondaryBackground
        copyControl?.layer.borderColor = UIColor.theme.ecosia.border.cgColor
        moreSharingMethods?.textColor = .theme.ecosia.secondaryText
        copyText?.textColor = .theme.ecosia.primaryBrand
        
        [yourInvites, sharingYourLink, flowTitle, cardTitle, cardTreeCount, copyLink].forEach {
            $0?.textColor = .theme.ecosia.primaryText
        }
        
        [card, sharing, flowBackground].forEach {
            $0?.backgroundColor = .theme.ecosia.impactMultiplyCardBackground
        }
        
        [cardIcon, cardTreeIcon].forEach {
            $0?.tintColor = .theme.ecosia.primaryBrand
        }
        
        [firstStep, secondStep, thirdStep, fourthStep].forEach {
            $0?.applyTheme()
        }
        
        [copyDividerLeft, copyDividerRight].forEach {
            $0?.backgroundColor = .theme.ecosia.border
        }
        
        updateBarAppearance()
    }

    private func updateBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.Dark.Text.primary]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.Dark.Text.primary]
        appearance.backgroundColor = .theme.ecosia.modalHeader
        appearance.shadowColor = nil
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.backgroundColor = .theme.ecosia.modalHeader
        navigationController?.navigationBar.tintColor = UIColor.Dark.Text.primary
    }
    
    @objc private func learnMore() {
        delegate?.yourImpact(didSelectURL: URL(string: "https://ecosia.helpscoutdocs.com/article/358-refer-a-friend-ios-only")!)
        dismiss(animated: true)
        Analytics.shared.inviteLearnMore()
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
        
        if #available(iOS 14.0, *) {
            UIPasteboard.general.setValue(message, forPasteboardType: UTType.plainText.identifier)
        } else {
            UIPasteboard.general.setValue(message, forPasteboardType: kUTTypePlainText as String)
        }
        
        copyText?.text = .localized(.copied)
    }
    
    @objc private func inviteFriends() {
        guard let message = inviteMessage else {
            referrals.refresh(createCode: true) { error in
                if let error = error {
                    self.showReferralError(error)
                } else {
                    self.share(message: self.inviteMessage!)
                }
            }
            return
        }
        share(message: message)
    }

    private func share(message: String) {
        let share = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = inviteButton
        share.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                Analytics.shared.sendInvite()
            }
        }
        present(share, animated: true)

        Analytics.shared.startInvite()
    }

    private func showReferralError(_ error: Referrals.Error) {
        let alert = UIAlertController(title: error.title,
                                      message: error.message,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: .localized(.continueMessage), style: .cancel))
        alert.addAction(.init(title: .localized(.retryMessage), style: .default) { [weak self] _ in
            self?.inviteFriends()
        })
        present(alert, animated: true)
    }

    @objc private func doneTapped() {
        dismiss(animated: true)
    }
    
    private var inviteMessage: String? {
        guard let link = inviteLink else { return nil }
        
        return """
🌳🔗 \(String.localized(.heyThereWantToPlant))

\(String.localized(.downloadEcosiaOn))
https://apps.apple.com/app/apple-store/id670881887?pt=2188920&ct=referrals&mt=8

\(String.localized(.afterInstalling))
\(link)

\(String.localized(.letsGrowTogether)) 😊
"""
    }
    
    private var inviteLink: String? {
        guard let code = User.shared.referrals.code else { return nil }
        return "ecosia://\(Referrals.host)/" + code
    }
}
