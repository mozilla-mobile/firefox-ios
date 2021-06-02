//
//  CredentialProviderPresenter.swift
//  CredentialProvider
//
//  Created by razvan.litianu on 28.05.2021.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit
import AuthenticationServices

@available(iOS 12, *)
class CredentialProviderPresenter {
    weak var view: CredentialProviderViewProtocol?
    private let profile: Profile
    
    init(view: CredentialProviderViewProtocol, profile: Profile = ExtensionProfile(localName: "profile")) {
        self.view = view
        self.profile = profile
    }
    
    func extensionConfigurationRequested() {
        view?.displayWelcome()
        
        if let openError = self.profile.logins.reopenIfClosed() {
            displayNotLoggedInMessage()
        } else {
            self.view?.displaySpinner(message: "Syncing your logins")
            profile.syncCredentialIdentities().upon { result in
                sleep(2)
                self.view?.hideSpinner(completionMessage: "Done Syncing your logins")
                self.cancelWith(.userCanceled)
            }
        }
        
        //        self.dataStore.locked
        //                .bind { [weak self] locked in
        //                    if locked {
        //                        self?.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
        //                    } else {
        //                        self?.dispatcher.dispatch(action: CredentialProviderAction.refresh)
        //                    }
        //                }
        //                .disposed(by: self.disposeBag)
        //
        //        self.view?.displayWelcome()
    }
    
    func credentialProvisionRequested(for credentialIdentity: ASPasswordCredentialIdentity) {
        
        let openError = self.profile.logins.reopenIfClosed()
        if let error = openError {
            cancelWith(.failed)
        } else if let id = credentialIdentity.recordIdentifier {
            
            profile.logins.get(id: id).upon { result in
                switch result {
                case .failure(_):
                    ()
                case .success(let record):
                    if let passwordCredential = record?.passwordCredential {
                        self.view?.extensionContext.completeRequest(withSelectedCredential: passwordCredential, completionHandler: nil)
                    } else {
                        self.cancelWith(.userInteractionRequired)
                    }
                }
            }
        }
        //        self.dataStore.locked
        //                .take(1)
        //                .bind { [weak self] locked in
        //                    if locked {
        //                        self?.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
        //                        self?.dispatcher.dispatch(action: CredentialStatusAction.cancelled(error: .userInteractionRequired))
        //                    } else {
        //                        self?.provideCredential(for: credentialIdentity)
        //                    }
        //                }
        //                .disposed(by: self.credentialProvisionBag)
    }
    
    func prepareAuthentication(for credentialIdentity: ASPasswordCredentialIdentity) {
        //        self.dataStore.locked
        //                .asDriver(onErrorJustReturn: true)
        //                .drive(onNext: { [weak self] locked in
        //                    if locked {
        //                        self?.view?.displayWelcome()
        //                    } else {
        //                        self?.provideCredential(for: credentialIdentity)
        //                    }
        //                })
        //                .disposed(by: self.credentialProvisionBag)
    }
    
    func credentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        
        let openError = self.profile.logins.reopenIfClosed()
        if let error = openError {
            cancelWith(.failed)
        } else {
            profile.logins.list().upon {[weak self] result in
                switch result {
                case .failure(_):
                    ()
                case .success(let loginRecods):
                    let dataSource = loginRecods.map { ($0.passwordCredentialIdentity, $0.passwordCredential) }
                    DispatchQueue.main.async {
                        self?.view?.display(itemList: dataSource)
                    }
                }
            }
        }
        
        
        
        //        self.dataStore.locked
        //                .asDriver(onErrorJustReturn: true)
        //                .drive(onNext: { [weak self] locked in
        //                    if locked {
        //                        self?.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
        //                        self?.view?.displayWelcome()
        //                    } else {
        //                        self?.view?.displayItemList()
        //                    }
        //                })
        //                .disposed(by: self.credentialProvisionBag)
        //
        //        self.dataStore.storageState
        //                .filter { $0 == .Unprepared }
        //                .asDriver(onErrorJustReturn: .Unprepared)
        //                .drive(onNext: { [weak self] _ in
        //                    self?.view?.displayWelcome()
        //                })
        //                .disposed(by: self.credentialProvisionBag)
    }
}

@available(iOS 12, *)
private extension CredentialProviderPresenter {
    
    func displayNotLoggedInMessage() {
        view?.displayAlertController(
            buttons: [
                AlertActionButtonConfiguration(
                    title: "OK",
                    tapAction: { [weak self] in self?.cancelWith(.userCanceled) },
                    style: .default)
            ],
            title: "NOt signed in",
            message: String(format: "needs sign in", "prodname", "maess"),
            style: .alert,
            barButtonItem: nil)
    }
    
    func cancelWith(_ errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain,
                            code: errorCode.rawValue,
                            userInfo: nil)
        
        self.view?.extensionContext.cancelRequest(withError: error)
    }
    
    func provideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        //        self.credentialProvisionBag = DisposeBag()
        //
        //        guard let id = credentialIdentity.recordIdentifier else {
        //            self.dispatcher.dispatch(action: CredentialStatusAction.cancelled(error: .credentialIdentityNotFound))
        //            return
        //        }
        //
        //        self.dataStore.locked
        //                .filter { !$0 }
        //                .take(1)
        //                .flatMap { _ in self.dataStore.get(id) }
        //                .map { login -> Action in
        //                    guard let login = login else {
        //                        return CredentialStatusAction.cancelled(error: .credentialIdentityNotFound)
        //                    }
        //
        //                    return CredentialStatusAction.loginSelected(login: login)
        //                }
        //                .subscribe(onNext: { self.dispatcher.dispatch(action: $0) })
        //                .disposed(by: self.disposeBag)
    }
}
