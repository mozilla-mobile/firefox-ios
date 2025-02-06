// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class LoadingScreen: UIViewController {
    private weak var profile: Profile!
    private weak var progress: UIProgressView!
    private weak var referrals: Referrals!
    private var referralCode: String?

    var themeManager: ThemeManager
    let windowUUID: WindowUUID
    let loadingGroup = DispatchGroup()

    required init?(coder: NSCoder) { nil }
    init(profile: Profile,
         referrals: Referrals,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         referralCode: String? = nil) {
        self.profile = profile
        self.referrals = referrals
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.referralCode = referralCode
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.ecosia.backgroundPrimary

        let logo = UIImageView(image: UIImage(named: "ecosiaLogoLaunch"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .center
        view.addSubview(logo)

        let progress = UIProgressView()
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = theme.colors.ecosia.brandPrimary
        view.addSubview(progress)
        self.progress = progress

        let message = UILabel()
        message.translatesAutoresizingMaskIntoConstraints = false
        message.text = .localized(.sitTightWeAre)
        message.font = .preferredFont(forTextStyle: .footnote)
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        message.textColor = theme.colors.ecosia.textPrimary
        message.textAlignment = .center
        view.addSubview(message)

        logo.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        logo.bottomAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        progress.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        progress.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 24).isActive = true
        progress.widthAnchor.constraint(equalToConstant: 173).isActive = true
        progress.heightAnchor.constraint(equalToConstant: 3).isActive = true

        message.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        message.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: 25).isActive = true
        message.widthAnchor.constraint(lessThanOrEqualToConstant: 280).isActive = true

        if let code = referralCode {
            loadingGroup.enter()
            claimReferral(code)
        }

        loadingGroup.notify(queue: .main) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    // MARK: Referrals
    private func claimReferral(_ code: String) {
        Task { [weak self] in
            do {
                try await self?.referrals.claim(referrer: code)
                self?.loadingGroup.leave()
                Analytics.shared.referral(action: .claim)
            } catch {
                self?.showReferralError(error as? Referrals.Error ?? .genericError)
            }
            User.shared.referrals.pendingClaim = nil
        }
    }

    private func showReferralError(_ error: Referrals.Error) {
        guard !error.title.isEmpty else { return }
        let alert = UIAlertController(title: error.title,
                                      message: error.message,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: .localized(.continueMessage), style: .cancel) { [weak self] _ in
            self?.loadingGroup.leave()
        })
        alert.addAction(.init(title: .localized(.retryMessage), style: .default) { [weak self] _ in
            guard let code = self?.referralCode else { return }
            self?.claimReferral(code)
        })
        present(alert, animated: true)
    }
}

extension Referrals.Error {
    var title: String {
        switch self {
        case .badRequest, .invalidCode, .genericError:
            return .localized(.invalidReferralLink)
        case .alreadyUsed:
            return .localized(.linkAlreadyUsedTitle)
        case .noConnection:
            return .localized(.networkError)
        case .notFound:
            return ""
        }
    }

    var message: String {
        switch self {
        case .badRequest, .invalidCode, .genericError:
            return .localized(.invalidReferralLinkMessage)
        case .alreadyUsed:
            return .localized(.linkAlreadyUsedMessage)
        case .noConnection:
            return .localized(.noConnectionMessage)
        case .notFound:
            return ""
        }
    }
}
