// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PassKit
import Shared
import WebKit
import Common
import zlib

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
        return MIMEType.isPassbook(mimeType) && PKAddPassesViewController.canAddPasses() && !forceDownload
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
            try openSinglePass(passData: passData)
            return
        } catch {
            // .pkpasses archives contain multiple .pkpass files and cannot be opened as a single PKPass.
            // Fall through to bundle extraction and multi-pass handling.
        }

        do {
            let bundledPassData = try PKPassBundleExtractor.extractPasses(from: passData)
            let passes = try bundledPassData.map { try PKPass(data: $0) }
            try open(passes: passes)
        } catch {
            sendLogError(with: error.localizedDescription)
            throw InvalidPassError.openError
        }
    }

    @MainActor
    private func openSinglePass(passData: Data) throws {
        do {
            let pass = try PKPass(data: passData)
            try open(passes: [pass])
        } catch {
            throw error
        }
    }

    @MainActor
    private func open(passes: [PKPass]) throws {
        guard !passes.isEmpty else {
            throw InvalidPassError.openError
        }

        let passLibrary = PKPassLibrary()
        let passesToAdd = passes.filter { !passLibrary.containsPass($0) }

        if passesToAdd.isEmpty {
            // If all passes are already in Wallet, open the first pass.
            if let passURL = passes.first?.passURL {
                UIApplication.shared.open(passURL, options: [:])
            }
            return
        }

        let addController: PKAddPassesViewController?
        if passesToAdd.count == 1 {
            addController = PKAddPassesViewController(pass: passesToAdd[0])
        } else {
            addController = PKAddPassesViewController(passes: passesToAdd)
        }

        guard let addController else {
            throw InvalidPassError.openError
        }

        presenter.present(addController, animated: true, completion: nil)
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

enum PKPassBundleExtractor {
    enum ExtractionError: Error {
        case invalidArchive
        case unsupportedCompressionMethod(UInt16)
        case encryptedEntry
        case invalidCompressedData
    }

    private struct CentralDirectoryEntry {
        let filename: String
        let compressionMethod: UInt16
        let generalPurposeBitFlag: UInt16
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let localHeaderOffset: UInt32
    }

    static func extractPasses(from archiveData: Data) throws -> [Data] {
        let entries = try readCentralDirectoryEntries(from: archiveData)
        let passEntries = entries.filter { $0.filename.lowercased().hasSuffix(".pkpass") }
        guard !passEntries.isEmpty else {
            throw ExtractionError.invalidArchive
        }

        return try passEntries.map { try extractEntryData(from: archiveData, entry: $0) }
    }

    private static func readCentralDirectoryEntries(from data: Data) throws -> [CentralDirectoryEntry] {
        guard let eocdOffset = findEndOfCentralDirectory(in: data) else {
            throw ExtractionError.invalidArchive
        }

        guard let totalEntries = data.readUInt16LE(at: eocdOffset + 10),
              let centralDirectoryOffset = data.readUInt32LE(at: eocdOffset + 16) else {
            throw ExtractionError.invalidArchive
        }

        var entries: [CentralDirectoryEntry] = []
        var cursor = Int(centralDirectoryOffset)

        for _ in 0..<Int(totalEntries) {
            guard data.readUInt32LE(at: cursor) == 0x02014b50 else {
                throw ExtractionError.invalidArchive
            }

            guard let generalPurposeBitFlag = data.readUInt16LE(at: cursor + 8),
                  let compressionMethod = data.readUInt16LE(at: cursor + 10),
                  let compressedSize = data.readUInt32LE(at: cursor + 20),
                  let uncompressedSize = data.readUInt32LE(at: cursor + 24),
                  let fileNameLength = data.readUInt16LE(at: cursor + 28),
                  let extraFieldLength = data.readUInt16LE(at: cursor + 30),
                  let fileCommentLength = data.readUInt16LE(at: cursor + 32),
                  let localHeaderOffset = data.readUInt32LE(at: cursor + 42) else {
                throw ExtractionError.invalidArchive
            }

            let filenameOffset = cursor + 46
            let filenameLength = Int(fileNameLength)
            guard let filenameData = data.readData(at: filenameOffset, length: filenameLength),
                  let filename = String(data: filenameData, encoding: .utf8) else {
                throw ExtractionError.invalidArchive
            }

            entries.append(CentralDirectoryEntry(
                filename: filename,
                compressionMethod: compressionMethod,
                generalPurposeBitFlag: generalPurposeBitFlag,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localHeaderOffset: localHeaderOffset
            ))

            cursor += 46 + Int(fileNameLength) + Int(extraFieldLength) + Int(fileCommentLength)
        }

        return entries
    }

    private static func extractEntryData(from data: Data, entry: CentralDirectoryEntry) throws -> Data {
        if (entry.generalPurposeBitFlag & 0x0001) != 0 {
            throw ExtractionError.encryptedEntry
        }

        let localHeaderOffset = Int(entry.localHeaderOffset)
        guard data.readUInt32LE(at: localHeaderOffset) == 0x04034b50,
              let fileNameLength = data.readUInt16LE(at: localHeaderOffset + 26),
              let extraFieldLength = data.readUInt16LE(at: localHeaderOffset + 28) else {
            throw ExtractionError.invalidArchive
        }

        let compressedDataOffset = localHeaderOffset + 30 + Int(fileNameLength) + Int(extraFieldLength)
        guard let compressedData = data.readData(at: compressedDataOffset, length: Int(entry.compressedSize)) else {
            throw ExtractionError.invalidArchive
        }

        switch entry.compressionMethod {
        case 0: // stored
            return compressedData
        case 8: // deflate
            return try inflateRawDeflate(compressedData, expectedSize: Int(entry.uncompressedSize))
        default:
            throw ExtractionError.unsupportedCompressionMethod(entry.compressionMethod)
        }
    }

    private static func inflateRawDeflate(_ data: Data, expectedSize: Int) throws -> Data {
        guard expectedSize >= 0 else {
            throw ExtractionError.invalidCompressedData
        }

        if expectedSize == 0 {
            return Data()
        }

        var stream = z_stream()
        let initStatus = inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else {
            throw ExtractionError.invalidCompressedData
        }
        defer { inflateEnd(&stream) }

        var output = Data(count: expectedSize)
        let status = output.withUnsafeMutableBytes { outputBytes in
            data.withUnsafeBytes { inputBytes -> Int32 in
                guard let outBase = outputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                      let inBase = inputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return Z_BUF_ERROR
                }

                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inBase)
                stream.avail_in = UInt32(data.count)
                stream.next_out = outBase
                stream.avail_out = UInt32(expectedSize)

                return inflate(&stream, Z_FINISH)
            }
        }

        guard status == Z_STREAM_END, Int(stream.total_out) == expectedSize else {
            throw ExtractionError.invalidCompressedData
        }

        return output
    }

    private static func findEndOfCentralDirectory(in data: Data) -> Int? {
        // EOCD record is at least 22 bytes and may have a variable length comment (up to UInt16.max).
        let minimumEOCDLength = 22
        guard data.count >= minimumEOCDLength else { return nil }

        let maxCommentLength = Int(UInt16.max)
        let scanStart = max(0, data.count - minimumEOCDLength - maxCommentLength)
        var cursor = data.count - minimumEOCDLength

        while cursor >= scanStart {
            if data.readUInt32LE(at: cursor) == 0x06054b50 {
                return cursor
            }
            cursor -= 1
        }
        return nil
    }
}

private extension Data {
    func readUInt16LE(at offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= count else { return nil }
        return withUnsafeBytes { bytes in
            let base = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return UInt16(base[offset]) | (UInt16(base[offset + 1]) << 8)
        }
    }

    func readUInt32LE(at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= count else { return nil }
        return withUnsafeBytes { bytes in
            let base = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return UInt32(base[offset])
                | (UInt32(base[offset + 1]) << 8)
                | (UInt32(base[offset + 2]) << 16)
                | (UInt32(base[offset + 3]) << 24)
        }
    }

    func readData(at offset: Int, length: Int) -> Data? {
        guard offset >= 0, length >= 0, offset + length <= count else { return nil }
        return subdata(in: offset..<(offset + length))
    }
}
