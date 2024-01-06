// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import AuthenticationServices

enum CredentialState {
    case emptyCredentialList
    case emptySearchResult
    case selectPassword
    case displayItem(ASPasswordCredentialIdentity)
}

class CredentialListPresenter {
    weak var view: CredentialListViewProtocol?
    var loginsData = [(ASPasswordCredentialIdentity, ASPasswordCredential)]()
    private var filteredCredentials = [(ASPasswordCredentialIdentity, ASPasswordCredential)]()

    init(view: CredentialListViewProtocol) {
        self.view = view
    }

    func filterCredentials(for searchText: String) {
        filteredCredentials = loginsData.filter { item in
            item.0.serviceIdentifier.identifier.titleFromHostname.lowercased().contains(searchText.lowercased())
            || item.0.user.lowercased().contains(searchText.lowercased())
        }
    }

    func numberOfSections() -> Int {
        guard let view = view else { return 1 }
        return loginsData.isEmpty || (view.searchIsActive && filteredCredentials.isEmpty) ? 1 : 2
    }

    func numberOfRows(for section: Int) -> Int {
        guard let view = view else { return 1 }

        if loginsData.isEmpty || (view.searchIsActive && filteredCredentials.isEmpty) {
            return 1
        } else if section == 1 {
            return view.searchIsActive ? filteredCredentials.count : loginsData.count
        } else {
            return 1
        }
    }

    func getItemsType(in section: Int, for index: Int) -> CredentialState {
        if loginsData.isEmpty {
            return .emptyCredentialList
        } else if let view = view, view.searchIsActive && filteredCredentials.isEmpty {
            return .emptySearchResult
        } else if section == 0 {
            return .selectPassword
        } else {
            var credential: ASPasswordCredentialIdentity
            if let view = view, view.searchIsActive {
                credential = filteredCredentials[index].0
            } else {
                credential = loginsData[index].0
            }
            return .displayItem(credential)
        }
    }

    func selectItem(for index: Int) {
        guard let view = view else { return }
        var passwordCredential: ASPasswordCredential
        if view.searchIsActive {
            passwordCredential = filteredCredentials[index].1
        } else {
            passwordCredential = loginsData[index].1
        }
        view.credentialExtensionContext?.completeRequest(
            withSelectedCredential: passwordCredential,
            completionHandler: nil
        )
    }

    func cancelRequest() {
        view?.credentialExtensionContext?.cancelRequest(
            withError: NSError(domain: ASExtensionErrorDomain, code: ASExtensionError.userCanceled.rawValue)
        )
    }
}
