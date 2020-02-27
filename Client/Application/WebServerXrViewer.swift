//
//  File.swift
//  Client
//
//  Created by Blair MacIntyre on 2/25/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation
import GCDWebServers
import Shared

class WebServerXrViewer {
#if XRVIEWERDEV

    private let log = Logger.browserLogger

    static let WebServerSharedInstance = WebServerXrViewer()

    class var sharedInstance: WebServerXrViewer {
        return WebServerSharedInstance
    }

    let server: GCDWebServer = GCDWebServer()
    let documentsPath = URL(fileURLWithPath: Bundle.main.resourcePath ?? "").appendingPathComponent("Web").path

    init() {
    }

    @discardableResult func start() throws -> Bool {
        if !server.isRunning {
            if FileManager.default.fileExists(atPath: documentsPath) {
                server.addGETHandler(forBasePath: "/", directoryPath: documentsPath, indexFilename: "index.html", cacheAge: 0, allowRangeRequests: true)
                do {
                    try server.start(options: [
                        GCDWebServerOption_Port: 8080,
                    ])
                    print("GCDWebServer running locally on port \(server.port)")
                } catch {
                    print("GCDWebServer not running! Error: \(error.localizedDescription)")
                }
            } else {
                print("No Web directory, GCDWebServer not running!")
            }
        }
        return server.isRunning
    }
#endif
}
