// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import WebKit
import Common
import Shared

class OpenMobileConfigHelper {
    private enum InvalidConfigError: Error {
        case contentsOfURL
        case dataTaskURL
        case openError

        public var description: String {
            switch self {
            case .contentsOfURL:
                return "Failed to open mobile config with content of URL"
            case .dataTaskURL:
                return "Failed to open mobile config from dataTask"
            case .openError:
                return "Failed to prompt or open mobile config"
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

    static func shouldOpenWithMobileConfig(mimeType: String, forceDownload: Bool = false) -> Bool {
        return MIMEType.shouldOpenWithMobileConfig(mimeType: mimeType, forceDownload: forceDownload)
    }

    func open(data: Data, completion: @escaping () -> Void) {
        do {
            try open(configData: data)
            completion()
        } catch {
            sendLogError(with: error.localizedDescription)
            presentErrorAlert(completion: completion)
        }
    }

    func open(response: URLResponse, cookieStore: WKHTTPCookieStore, completion: @escaping () -> Void) {
        Task {
            do {
                try await openConfigWithContentsOfURL(url: response.url)
                completion()
            } catch let error as InvalidConfigError {
                sendLogError(with: error.description)
                openConfigWithCookies(url: response.url, cookieStore: cookieStore) { error in
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
    }

    private func openConfigWithCookies(
        url: URL?,
        cookieStore: WKHTTPCookieStore,
        completion: @escaping (InvalidConfigError?) -> Void) {
        configureCookies(cookieStore: cookieStore) { [weak self] in
            self?.openConfigFromDataTask(url: url, completion: completion)
        }
    }

    private func openConfigFromDataTask(url: URL?, completion: @escaping (InvalidConfigError?) -> Void) {
        getData(url: url, completion: { data in
            guard let data = data else {
                completion(InvalidConfigError.dataTaskURL)
                return
            }

            do {
                try self.open(configData: data)
                completion(nil)
            } catch {
                self.sendLogError(with: error.localizedDescription)
                completion(InvalidConfigError.dataTaskURL)
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

    private func openConfigWithContentsOfURL(url: URL?) async throws {
        guard let url = url else {
            throw InvalidConfigError.contentsOfURL
        }

        do {
            let (configData, _) = try await URLSession.shared.data(from: url)
            try open(configData: configData)
        } catch {
            sendLogError(with: error.localizedDescription)
            throw InvalidConfigError.contentsOfURL
        }
    }

    private func open(configData: Data) throws {
        // Create a temporary file to save the configuration data
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("config.mobileconfig")

        do {
            try configData.write(to: tempFileURL)

            // Open the configuration profile using the system
            Task { @MainActor in
                if UIApplication.shared.canOpenURL(tempFileURL) {
                    UIApplication.shared.open(tempFileURL, options: [:]) { success in
                        if !success {
                            self.sendLogError(with: "Failed to open mobile config file")
                        }
                        // Clean up temporary file
                        try? FileManager.default.removeItem(at: tempFileURL)
                    }
                } else {
                    self.sendLogError(with: "Cannot open mobile config file")
                    // Clean up temporary file
                    try? FileManager.default.removeItem(at: tempFileURL)
                    throw InvalidConfigError.openError
                }
            }
        } catch {
            sendLogError(with: error.localizedDescription)
            throw InvalidConfigError.openError
        }
    }

    private func presentErrorAlert(completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: .UnableToOpenConfigErrorTitle,
                                                message: .UnableToOpenConfigErrorMessage,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: .UnableToOpenConfigErrorDismiss,
                                                style: .cancel) { (action) in })
        Task { @MainActor in
            presenter.present(alertController, animated: true, completion: {
                completion()
            })
        }
    }

    private func sendLogError(with errorDescription: String) {
        logger.log("Error when opening mobile configuration profile",
                   level: .warning,
                   category: .webview,
                   description: errorDescription)
    }
}

