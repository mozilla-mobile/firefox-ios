// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol LoggerFileManager {
    /// Get the URL of a new log file
    func getLogDestination() -> URL?

    /// Copy logs files from the cache to the documents folder so the user can access them
    func copyLogsToDocuments()
}

class DefaultLoggerFileManager: LoggerFileManager {
    private static let TwoMBsInBytes: Int64 = 2 * 100000
    private var fileManager: FileManagerProtocol
    private let fileNameRoot: String
    private let sizeLimit: Int64

    var logDirectoryPath: String?

    init(fileNameRoot: String = "Firefox",
         fileManager: FileManagerProtocol = FileManager.default,
         sizeLimit: Int64 = TwoMBsInBytes) {
        self.fileNameRoot = fileNameRoot
        self.fileManager = fileManager
        self.sizeLimit = sizeLimit
        self.logDirectoryPath = logFileDirectoryPath(inDocuments: false)
    }

    func getLogDestination() -> URL? {
        guard let path = logFileDirectoryPath(inDocuments: false) else { return nil }

        let pathComponent = "\(fileNameRoot).log"
        return URL(fileURLWithPath: path, isDirectory: true).appendingPathComponent(pathComponent)
    }

    func copyLogsToDocuments() {
        deleteOldLogs()
        copyLogs()
    }

    // MARK: - Private

    private func deleteOldLogs() {
        guard let logDirectoryPath = logDirectoryPath,
              let logFiles = try? fileManager.contentsOfDirectoryAtPath(logDirectoryPath,
                                                                        withFilenamePrefix: fileNameRoot)
        else { return }

        for logFile in logFiles {
            try? fileManager.removeItem(atPath: "\(logDirectoryPath)/\(logFile)")
        }
    }

    private func copyLogs() {
        guard let defaultLogDirectoryPath = logFileDirectoryPath(inDocuments: false),
              let documentsLogDirectoryPath = logFileDirectoryPath(inDocuments: true),
              let previousLogFiles = try? fileManager.contentsOfDirectory(atPath: defaultLogDirectoryPath)
        else { return }

        let defaultLogDirectoryURL = URL(fileURLWithPath: defaultLogDirectoryPath, isDirectory: true)
        let documentsLogDirectoryURL = URL(fileURLWithPath: documentsLogDirectoryPath, isDirectory: true)
        for previousLogFile in previousLogFiles {
            let previousLogFileURL = defaultLogDirectoryURL.appendingPathComponent(previousLogFile)
            let targetLogFileURL = documentsLogDirectoryURL.appendingPathComponent(previousLogFile)
            try? fileManager.copyItem(at: previousLogFileURL, to: targetLogFileURL)
        }
    }

    private func logFileDirectoryPath(inDocuments: Bool) -> String? {
        let searchPathDirectory: FileManager.SearchPathDirectory = inDocuments ? .documentDirectory : .cachesDirectory
        guard let targetDirectory = NSSearchPathForDirectoriesInDomains(searchPathDirectory,
                                                                        .userDomainMask,
                                                                        true).first
        else { return nil }

        let logsDirectory = "\(targetDirectory)/Logs"
        if !fileManager.fileExists(atPath: logsDirectory) {
            try? fileManager.createDirectory(atPath: logsDirectory,
                                             withIntermediateDirectories: true,
                                             attributes: nil)
        }

        return logsDirectory
    }
}
