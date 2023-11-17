/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit
import Core

final class LoadingScreen: UIViewController {
    private weak var profile: Profile!
    private weak var progress: UIProgressView!
    private weak var referrals: Referrals!
    private var referralCode: String?

    let loadingGroup = DispatchGroup()
    
    required init?(coder: NSCoder) { nil }
    init(profile: Profile, referrals: Referrals, referralCode: String? = nil) {
        self.profile = profile
        self.referrals = referrals
        self.referralCode = referralCode
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.legacyTheme.ecosia.primaryBackground

        let logo = UIImageView(image: UIImage(named: "ecosiaLogoLaunch"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .center
        view.addSubview(logo)
        
        let progress = UIProgressView()
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progressTintColor = UIColor.legacyTheme.ecosia.primaryBrand
        view.addSubview(progress)
        self.progress = progress
        
        let message = UILabel()
        message.translatesAutoresizingMaskIntoConstraints = false
        message.text = .localized(.sitTightWeAre)
        message.font = .preferredFont(forTextStyle: .footnote)
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        message.textColor = UIColor.legacyTheme.ecosia.primaryText
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


        if User.shared.migrated != true {
            loadingGroup.enter()
            migrate()
        }
          
        if let code = referralCode {
            loadingGroup.enter()
            claimReferral(code)
        }

        loadingGroup.notify(queue: .main) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    // MARK: migration

    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    private func migrate() {
        guard !skip() else { return }

        NSSetUncaughtExceptionHandler { exception in
            EcosiaImport.Exception(reason: exception.reason ?? "Unknown").save()
        }

        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "Migration", expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID!)
            self.backgroundTaskID = .invalid
            // force shutting down profile to avoid crash by system
            self.profile.shutdown()
        })

        let ecosiaImport = EcosiaImport(profile: profile)
        ecosiaImport.migrate(progress: { [weak self] progress in
            self?.progress.setProgress(.init(progress), animated: true)
        }){ [weak self] migration in
            if case .succeeded = migration.favorites,
               case .succeeded = migration.history {
                
                Analytics.shared.migration(true)
                self?.cleanUp()
                self?.loadingGroup.leave()
            } else {
                Analytics.shared.migration(false)
                self?.showError()
            }
            
            Core.User.shared.migrated = true
            NSSetUncaughtExceptionHandler(nil)

            if let id = self?.backgroundTaskID {
                UIApplication.shared.endBackgroundTask(id)
            }

            if UIApplication.shared.applicationState != .active {
                self?.profile.shutdown()
            }
        }
    }



    private func skip() -> Bool {
        if let exception = EcosiaImport.Exception.load() {
            Analytics.shared.migrationError(in: .exception, message: exception.reason)
            Core.User.shared.migrated = true
            EcosiaImport.Exception.clear()
            cleanUp()

            DispatchQueue.main.async { [weak self] in
                self?.showError()
            }
            return true
        }
        return false
    }

    
    private func showError() {
        let alert = UIAlertController(title: .localized(.weHitAGlitch),
                                      message: .localized(.weAreMomentarilyUnable),
                                      preferredStyle: .alert)
        alert.addAction(.init(title: .localized(.continueMessage), style: .default) { [weak self] _ in
            self?.loadingGroup.leave()
        })
        
        present(alert, animated: true)
    }
    
    private func cleanUp() {
        History().deleteAll()
        Favourites().items = []
        Tabs().clear()
    }

    // MARK: Referrals
    private func claimReferral(_ code: String) {
        Task { [weak self] in
            do {
                try await referrals.claim(referrer: code)
                self?.loadingGroup.leave()
                Analytics.shared.inviteClaimSuccess()
            } catch {
                self?.showReferralError(error as? Referrals.Error ?? .genericError)
            }
            User.shared.referrals.pendingClaim = nil
        }
    }

    private func showReferralError(_ error: Referrals.Error) {
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
        }
    }
}
