// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PassKit
import Shared
import WebKit
import Common

class OpenPassBookHelper {
    private enum InvalidPassError: Error {
        case contentsOfURL
        case dataTaskURL
        case openError

        public var description: String {
            switch self {
            case .contentsOfURL:
                return "Failed to open pass with content of URL"
            case .dataTaskURL:
                return "Failed to open pass from dataTask"
            case .openError:
                return "Failed to prompt or open pass"
            }
        }
    }

    private let presenter: Presenter
    private lazy var session = makeURLSession(userAgent: UserAgent.fxaUserAgent,
                                              configuration: .ephemeralMPTCP)
    private let logger: Logger

    init(presenter: Presenter,
         logger: Logger = DefaultLogger.shared) {
        self.presenter = presenter
        self.logger = logger
    }

    static func shouldOpenWithPassBook(mimeType: String, forceDownload: Bool = false) -> Bool {
        return mimeType == MIMEType.Passbook && PKAddPassesViewController.canAddPasses() && !forceDownload
    }

    func open(data: Data, completion: @escaping () -> Void) {
        do {
            try open(passData: data)
        } catch {
            sendLogError(with: error.localizedDescription)
            presentErrorAlert(completion: completion)
        }
    }

    func open(response: URLResponse, cookieStore: WKHTTPCookieStore, completion: @escaping () -> Void) {
        do {
            try openPassWithContentsOfURL(url: response.url)
            completion()
        } catch let error as InvalidPassError {
            sendLogError(with: error.description)
            openPassWithCookies(url: response.url, cookieStore: cookieStore) { error in
                if error != nil {
                    self.presentErrorAlert(completion: completion)
                } else {
                    completion()
                }
            }
        } catch {
            sendLogError(with: error.localizedDescription)
            presentErrorAlert(completion: completion)
        }
    }

    private func openPassWithCookies(
        url: URL?,
        cookieStore: WKHTTPCookieStore,
        completion: @escaping (InvalidPassError?) -> Void) {
        configureCookies(cookieStore: cookieStore) { [weak self] in
            self?.openPassFromDataTask(url: url, completion: completion)
        }
    }

    private func openPassFromDataTask(url: URL?, completion: @escaping (InvalidPassError?) -> Void) {
        getData(url: url, completion: { data in
            guard let data = data else {
                completion(InvalidPassError.dataTaskURL)
                return
            }

            do {
                try self.open(passData: data)
            } catch {
                self.sendLogError(with: error.localizedDescription)
                completion(InvalidPassError.dataTaskURL)
            }
        })
    }

    private func getData(url: URL?, completion: @escaping (Data?) -> Void) {
        guard let url = url else {
            completion(nil)
            return
        }

        session.dataTask(with: url) { (data, response, error) in
            guard validatedHTTPResponse(response, statusCode: 200..<300) != nil,
                  let data = data
            else {
                completion(nil)
                return
            }

            completion(data)
        }.resume()
    }

    /// Get webview cookies to add onto download session
    private func configureCookies(cookieStore: WKHTTPCookieStore, completion: @escaping () -> Void) {
        cookieStore.getAllCookies { [weak self] cookies in
            for cookie in cookies {
                self?.session.configuration.httpCookieStorage?.setCookie(cookie)
            }

            completion()
        }
    }

    private func openPassWithContentsOfURL(url: URL?) throws {
        guard let url = url, let passData = try? Data(contentsOf: url) else {
            throw InvalidPassError.contentsOfURL
        }

        do {
            try open(passData: passData)
        } catch {
            sendLogError(with: error.localizedDescription)
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
            sendLogError(with: error.localizedDescription)
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

    private func sendLogError(with errorDescription: String) {
        // Log error to help debug https://github.com/mozilla-mobile/firefox-ios/issues/12331
        logger.log("Unknown error when adding pass to Apple Wallet",
                   level: .warning,
                   category: .webview,
                   description: errorDescription)
    }
}
