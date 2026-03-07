// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
import WebKit
@testable import Client

class DownloadHelperTests: XCTestCase {
    func test_isPassbook_whenPkpass_isTrue() {
        XCTAssertTrue(MIMEType.isPassbook(MIMEType.Passbook))
    }

    func test_isPassbook_whenPkpasses_isTrue() {
        XCTAssertTrue(MIMEType.isPassbook(MIMEType.PassbookBundle))
    }

    func test_isPassbook_whenOtherMimeType_isFalse() {
        XCTAssertFalse(MIMEType.isPassbook(MIMEType.PDF))
    }

    func test_pkpassBundleExtractor_whenArchiveContainsPkpass_extractsPassData() throws {
        let nestedPassData = Data([0x50, 0x4B, 0x50, 0x41, 0x53, 0x53]) // "PKPASS"
        let archiveData = makeStoredZipArchive(entries: [
            ("bundle/boarding.pkpass", nestedPassData),
            ("bundle/readme.txt", Data("ignore".utf8))
        ])

        let extracted = try PKPassBundleExtractor.extractPasses(from: archiveData)

        XCTAssertEqual(extracted, [nestedPassData])
    }

    func test_pkpassBundleExtractor_whenArchiveHasNoPkpass_throws() {
        let archiveData = makeStoredZipArchive(entries: [("bundle/readme.txt", Data("ignore".utf8))])

        XCTAssertThrowsError(try PKPassBundleExtractor.extractPasses(from: archiveData))
    }

    @MainActor
    func test_init_whenMIMETypeIsNil_initializeCorrectly() {
        let response = anyResponse(mimeType: nil)

        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())
        XCTAssertNotNil(subject)
    }

    @MainActor
    func test_shouldDownloadFile_whenMIMETypeOctetStream_isTrue() {
        let mimeType = MIMEType.OctetStream

        let response = anyResponse(mimeType: mimeType)
        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())
        let shouldDownload = subject?.shouldDownloadFile(canShowInWebView: true,
                                                         forceDownload: false,
                                                         isForMainFrame: false)
        XCTAssertTrue(shouldDownload ?? false)
    }

    @MainActor
    func test_shouldDownloadFile_whenMIMETypeIsNotOctetStream_isFalse() {
        let mimeType = MIMEType.GIF

        let response = anyResponse(mimeType: mimeType)
        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    @MainActor
    func test_shouldDownloadFile_whenContentDispositionAttachmentHeader_isTrue() {
        let response = httpURLResponse(mimeType: MIMEType.JPEG,
                                       contentDispositionHeader: true)
        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertTrue(shouldDownload)
        }
    }

    @MainActor
    func test_shouldDownloadFile_whenContentDispositionAttachmentHeader_isFalse() {
        let response = httpURLResponse(mimeType: MIMEType.JPEG,
                                       contentDispositionHeader: false)
        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    @MainActor
    func test_shouldDownloadFile_whenCanShowInWebview_isFalse() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    @MainActor
    func test_shouldDownloadFile_whenCanNotShowInWebview_isTrue() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: false,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertTrue(shouldDownload)
        }
    }

    @MainActor
    func test_shouldDownloadFile_whenNotForceDownload_isFalse() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: true,
                                                            forceDownload: false,
                                                            isForMainFrame: false)
            XCTAssertFalse(shouldDownload)
        }
    }

    @MainActor
    func test_shouldDownloadFile_whenForceDownload_isTrue() {
        let response = anyResponse(mimeType: MIMEType.GIF)

        if let subject = createSubject(request: anyRequest(),
                                       response: response,
                                       cookieStore: cookieStore()) {
            let shouldDownload = subject.shouldDownloadFile(canShowInWebView: false,
                                                            forceDownload: true,
                                                            isForMainFrame: false)
            XCTAssertTrue(shouldDownload)
        }
    }

    @MainActor
    func test_downloadViewModel_whenRequestURLIsWrong_deliversEmptyResult() {
        let request = anyRequest(urlString: "wrong-url.com")
        let subject = createSubject(request: request,
                                    response: anyResponse(mimeType: nil),
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertNil(downloadViewModel)
    }

    @MainActor
    func test_downloadViewModel_deliversCorrectTitle() {
        let response = anyResponse(urlString: "http://some-domain.com/some-image.jpg")
        let subject = createSubject(request: anyRequest(),
                                    response: response,
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertEqual(downloadViewModel!.title!, "some-image.jpg")
    }

    @MainActor
    func test_downloadViewModel_deliversCorrectCancelButtonTitle() {
        let subject = createSubject(request: anyRequest(),
                                    response: anyResponse(mimeType: nil),
                                    cookieStore: cookieStore())

        let downloadViewModel = subject?.downloadViewModel(windowUUID: .XCTestDefaultUUID, okAction: { _ in })

        XCTAssertEqual(downloadViewModel!.closeButtonTitle, .CancelString)
    }

    // MARK: - Helpers

    private func createSubject(request: URLRequest,
                               response: URLResponse,
                               cookieStore: WKHTTPCookieStore) -> DownloadHelper? {
        return DownloadHelper(request: request,
                              response: response,
                              cookieStore: cookieStore)
    }

    private func anyRequest(urlString: String = "http://any-url.com") -> URLRequest {
        return URLRequest(url: URL(string: urlString)!, cachePolicy: anyCachePolicy(), timeoutInterval: 60.0)
    }

    private func anyResponse(mimeType: String?) -> URLResponse {
        return URLResponse(
            url: URL(string: "http://any-url.com")!,
            mimeType: mimeType,
            expectedContentLength: 10,
            textEncodingName: nil
        )
    }

    private func httpURLResponse(mimeType: String,
                                 contentDispositionHeader: Bool) -> MockHTTPURLResponse {
        return MockHTTPURLResponse(forcedMimeType: mimeType,
                                   url: URL(string: "http://any-url.com")!,
                                   statusCode: 200,
                                   httpVersion: "HTTP/1.1",
                                   headerFields: contentDispositionHeader ? ["Content-Disposition": "attachment"] : nil)!
    }

    private func anyResponse(urlString: String) -> URLResponse {
        return URLResponse(
            url: URL(string: urlString)!,
            mimeType: nil,
            expectedContentLength: 10,
            textEncodingName: nil
        )
    }

    @MainActor
    private func cookieStore() -> WKHTTPCookieStore {
        return WKWebsiteDataStore.`default`().httpCookieStore
    }

    private func anyCachePolicy() -> URLRequest.CachePolicy {
        return .useProtocolCachePolicy
    }

    private func makeStoredZipArchive(entries: [(String, Data)]) -> Data {
        var archive = Data()
        var centralDirectory = Data()
        var localHeaderOffsets: [UInt32] = []

        for (filename, fileData) in entries {
            let fileNameData = Data(filename.utf8)
            let localHeaderOffset = UInt32(archive.count)
            localHeaderOffsets.append(localHeaderOffset)

            // Local file header signature
            archive.appendLE32(0x04034b50)
            archive.appendLE16(20) // version needed
            archive.appendLE16(0) // flags
            archive.appendLE16(0) // compression: stored
            archive.appendLE16(0) // mod time
            archive.appendLE16(0) // mod date
            archive.appendLE32(0) // crc32 not required by extractor tests
            archive.appendLE32(UInt32(fileData.count))
            archive.appendLE32(UInt32(fileData.count))
            archive.appendLE16(UInt16(fileNameData.count))
            archive.appendLE16(0) // extra length
            archive.append(fileNameData)
            archive.append(fileData)
        }

        let centralDirectoryOffset = UInt32(archive.count)
        for (index, entry) in entries.enumerated() {
            let fileNameData = Data(entry.0.utf8)
            let fileData = entry.1

            // Central directory file header signature
            centralDirectory.appendLE32(0x02014b50)
            centralDirectory.appendLE16(20) // version made by
            centralDirectory.appendLE16(20) // version needed
            centralDirectory.appendLE16(0) // flags
            centralDirectory.appendLE16(0) // compression: stored
            centralDirectory.appendLE16(0) // mod time
            centralDirectory.appendLE16(0) // mod date
            centralDirectory.appendLE32(0) // crc32 not required by extractor tests
            centralDirectory.appendLE32(UInt32(fileData.count))
            centralDirectory.appendLE32(UInt32(fileData.count))
            centralDirectory.appendLE16(UInt16(fileNameData.count))
            centralDirectory.appendLE16(0) // extra length
            centralDirectory.appendLE16(0) // comment length
            centralDirectory.appendLE16(0) // disk number start
            centralDirectory.appendLE16(0) // internal attrs
            centralDirectory.appendLE32(0) // external attrs
            centralDirectory.appendLE32(localHeaderOffsets[index])
            centralDirectory.append(fileNameData)
        }

        archive.append(centralDirectory)

        // End of central directory record
        archive.appendLE32(0x06054b50)
        archive.appendLE16(0) // disk number
        archive.appendLE16(0) // central dir start disk
        archive.appendLE16(UInt16(entries.count))
        archive.appendLE16(UInt16(entries.count))
        archive.appendLE32(UInt32(centralDirectory.count))
        archive.appendLE32(centralDirectoryOffset)
        archive.appendLE16(0) // zip comment length

        return archive
    }
}

class MockHTTPURLResponse: HTTPURLResponse, @unchecked Sendable {
    private var forcedMimeType: String
    init?(forcedMimeType: String,
          url: URL,
          statusCode: Int,
          httpVersion HTTPVersion: String?,
          headerFields: [String: String]?) {
        self.forcedMimeType = forcedMimeType
        super.init(url: url,
                   statusCode: statusCode,
                   httpVersion: HTTPVersion,
                   headerFields: headerFields)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var mimeType: String? { forcedMimeType }
}

private extension Data {
    mutating func appendLE16(_ value: UInt16) {
        append(UInt8(value & 0x00ff))
        append(UInt8((value >> 8) & 0x00ff))
    }

    mutating func appendLE32(_ value: UInt32) {
        append(UInt8(value & 0x000000ff))
        append(UInt8((value >> 8) & 0x000000ff))
        append(UInt8((value >> 16) & 0x000000ff))
        append(UInt8((value >> 24) & 0x000000ff))
    }
}
