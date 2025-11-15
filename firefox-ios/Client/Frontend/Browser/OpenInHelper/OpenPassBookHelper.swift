// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PassKit
import Shared
import WebKit
import Common

final class OpenPassBookHelper: @unchecked Sendable {
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
    private lazy var session = makeURLSession(
        userAgent: UserAgent.fxaUserAgent,
        configuration: .ephemeralMPTCP
    )
    private let logger: Logger

    init(presenter: Presenter,
         logger: Logger = DefaultLogger.shared) {
        self.presenter = presenter
        self.logger = logger
    }

    @MainActor
    static func shouldOpenWithPassBook(mimeType: String, forceDownload: Bool = false) -> Bool {
        return mimeType == MIMEType.Passbook && PKAddPassesViewController.canAddPasses() && !forceDownload
    }

    @MainActor
    func open(data: Data) {
        do {
            try open(passData: data)
        } catch {
            sendLogError(with: error.localizedDescription)
            presentErrorAlert()
        }
    }

    func open(response: URLResponse, cookieStore: WKHTTPCookieStore) async {
        do {
            try await openPassWithContentsOfURL(url: response.url)
        } catch let error as InvalidPassError {
            sendLogError(with: error.description)
            let error = await openPassWithCookies(url: response.url, cookieStore: cookieStore)
            if error != nil {
                await presentErrorAlert()
            }
        } catch {
            sendLogError(with: error.localizedDescription)
            await presentErrorAlert()
        }
    }

    private func openPassWithCookies(
        url: URL?,
        cookieStore: WKHTTPCookieStore) async -> InvalidPassError? {
            await configureCookies(cookieStore: cookieStore)
            return await openPassFromDataTask(url: url)
    }

    @MainActor
    private func openPassFromDataTask(url: URL?) async -> InvalidPassError? {
        let data = await getData(url: url)
        guard let data = data else {
            return InvalidPassError.dataTaskURL
        }

        do {
            try self.open(passData: data)
            return nil
        } catch {
            self.sendLogError(with: error.localizedDescription)
            return InvalidPassError.dataTaskURL
        }
    }

    private func getData(url: URL?) async -> Data? {
        guard let url = url else {
            return nil
        }
        do {
            let (data, response) = try await session.data(from: url)
            if validatedHTTPResponse(response, statusCode: 200..<300) != nil {
                return data
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    /// Get webview cookies to add onto download session
    private func configureCookies(cookieStore: WKHTTPCookieStore) async {
        let cookies = await cookieStore.allCookies()
        for cookie in cookies {
            session.configuration.httpCookieStorage?.setCookie(cookie)
        }
    }

    @MainActor
    private func openPassWithContentsOfURL(url: URL?) async throws {
        guard let url = url else {
            throw InvalidPassError.contentsOfURL
        }

        do {
            let (passData, _) = try await URLSession.shared.data(from: url)
            try open(passData: passData)
        } catch {
            sendLogError(with: error.localizedDescription)
            throw InvalidPassError.contentsOfURL
        }
    }

    @MainActor
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
                Task { @MainActor in
                    presenter.present(addController, animated: true, completion: nil)
                }
            }
        } catch {
            sendLogError(with: error.localizedDescription)
            throw InvalidPassError.openError
        }
    }

    @MainActor
    private func presentErrorAlert() {
        let alertController = UIAlertController(title: .UnableToAddPassErrorTitle,
                                                message: .UnableToAddPassErrorMessage,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: .UnableToAddPassErrorDismiss,
                                                style: .cancel) { (action) in })
        presenter.present(alertController, animated: true, completion: nil)
    }

    private func sendLogError(with errorDescription: String) {
        // Log error to help debug https://github.com/mozilla-mobile/firefox-ios/issues/12331
        logger.log("Unknown error when adding pass to Apple Wallet",
                   level: .warning,
                   category: .webview,
                   description: errorDescription)
    }
}
