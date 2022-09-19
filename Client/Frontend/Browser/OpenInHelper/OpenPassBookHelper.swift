// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PassKit
import Shared
import WebKit

class OpenPassBookHelper {

    private enum InvalidPassError: Error {
        case contentsOfURL
        case dataTaskURL
        case openError
    }

    private var response: URLResponse
    private var url: URL?
    private let presenter: Presenter
    private let cookieStore: WKHTTPCookieStore
    private lazy var session = makeURLSession(userAgent: UserAgent.fxaUserAgent,
                                              configuration: .ephemeral)

    init(response: URLResponse,
         cookieStore: WKHTTPCookieStore,
         presenter: Presenter) {
        self.response = response
        self.url = response.url
        self.cookieStore = cookieStore
        self.presenter = presenter
    }

    static func shouldOpenWithPassBook(response: URLResponse,
                                       forceDownload: Bool) -> Bool {
        guard let mimeType = response.mimeType, response.url != nil else { return false }
        return mimeType == MIMEType.Passbook && PKAddPassesViewController.canAddPasses() && !forceDownload
    }

    func open(completion: @escaping () -> Void) {
        do {
            try openPassWithContentsOfURL()
            completion()

        } catch InvalidPassError.contentsOfURL {
            openPassWithCookies { error in
                if error != nil {
                    self.presentErrorAlert(completion: completion)
                } else {
                    completion()
                }
            }

        } catch {
            presentErrorAlert(completion: completion)
        }
    }

    private func openPassWithCookies(completion: @escaping (InvalidPassError?) -> Void) {
        configureCookies { [weak self] in
            self?.openPassfromDataTask(completion: completion)
        }
    }

    private func openPassfromDataTask(completion: @escaping (InvalidPassError?) -> Void) {
        getData(completion: { data in
            guard let data = data else {
                completion(InvalidPassError.dataTaskURL)
                return
            }

            do {
                try self.open(passData: data)
            } catch {
                completion(InvalidPassError.dataTaskURL)
            }
        })
    }

    private func getData(completion: @escaping (Data?) -> Void) {
        guard let url = url else {
            completion(nil)
            return
        }

        session.dataTask(with: url) { (data, response, error) in
            guard let _ = validatedHTTPResponse(response, statusCode: 200..<300),
                  let data = data
            else {
                completion(nil)
                return
            }

            completion(data)
        }.resume()
    }

    /// Get webview cookies to add onto download session
    private func configureCookies(completion: @escaping () -> Void) {
        cookieStore.getAllCookies { [weak self] cookies in
            for cookie in cookies {
                self?.session.configuration.httpCookieStorage?.setCookie(cookie)
            }

            completion()
        }
    }

    private func openPassWithContentsOfURL() throws {
        guard let url = url, let passData = try? Data(contentsOf: url) else {
            throw InvalidPassError.contentsOfURL
        }

        do {
            try open(passData: passData)
        } catch {
            throw InvalidPassError.contentsOfURL
        }
    }

    private func open(passData: Data) throws {
        do {
            let pass = try PKPass(data: passData)
            let passLibrary = PKPassLibrary()
            if passLibrary.containsPass(pass) {
                UIApplication.shared.open(pass.passURL!, options: [:])
            } else {
                guard let addController = PKAddPassesViewController(pass: pass) else {
                    throw InvalidPassError.openError
                }
                presenter.present(addController, animated: true, completion: nil)
            }
        } catch {
            throw InvalidPassError.openError
        }
    }

    private func presentErrorAlert(completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: .UnableToAddPassErrorTitle,
                                                message: .UnableToAddPassErrorMessage,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: .UnableToAddPassErrorDismiss,
                                                style: .cancel) { (action) in })
        presenter.present(alertController, animated: true, completion: {
            completion()
        })
    }
}
