// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import XCTest
import Shared
import Storage

class OpenSearchEngineTests: XCTestCase {
    func testEncodeDecodeOpenSearchEngine_withBundledImages_Single() throws {
        let searchEngine = try Self.generateOpenSearchEngine(type: .wikipedia)

        // Encode the data
        let data = try NSKeyedArchiver.archivedData(withRootObject: searchEngine, requiringSecureCoding: true)

        // Decode the data
        let unarchiveClasses = [OpenSearchEngine.self, UIImage.self]
        let customEngine = try NSKeyedUnarchiver.unarchivedObject(ofClasses: unarchiveClasses,
                                                                  from: data) as? OpenSearchEngine

        // Test encode/decode works as expected without changing the data
        XCTAssertNotNil(customEngine)
        XCTAssertEqual(
            searchEngine.image.pngData()?.count,
            customEngine?.image.pngData()?.count,
            "Sizes should match"
        )
    }

    func testEncodeDecodeOpenSearchEngine_withBundledImages_Array() throws {
        let searchEngine1 = try Self.generateOpenSearchEngine(type: .wikipedia)
        let searchEngine2 = try Self.generateOpenSearchEngine(type: .youtube)

        let dataToEncode = [searchEngine1, searchEngine2]

        // Encode the data
        let data = try NSKeyedArchiver.archivedData(withRootObject: dataToEncode, requiringSecureCoding: true)

        // Decode the data
        let unarchiveClasses = [NSArray.self, OpenSearchEngine.self, NSString.self, UIImage.self]
        let searchEngines = try NSKeyedUnarchiver.unarchivedObject(ofClasses: unarchiveClasses,
                                                                   from: data) as? [OpenSearchEngine]

        // Test encode/decode works as expected without changing the data
        XCTAssertNotNil(searchEngines)
        XCTAssertEqual(searchEngines?.count, dataToEncode.count)
        XCTAssertEqual(searchEngines?[safe: 0]?.image.pngData()?.count, searchEngine1.image.pngData()?.count)
        XCTAssertEqual(searchEngines?[safe: 1]?.image.pngData()?.count, searchEngine2.image.pngData()?.count)
    }

    func testCustomSearchEnginesSavedToFile_canRetrievesImageData() throws {
        // Test reading and writing OpenSearchEngines to the same customEngines plist file as done within the app.
        let searchEngine1 = try Self.generateOpenSearchEngine(type: .wikipedia)
        let searchEngine2 = try Self.generateOpenSearchEngine(type: .youtube)

        // Encode the data
        let searchEngines = [searchEngine1, searchEngine2]
        let encodedData = try NSKeyedArchiver.archivedData(
            withRootObject: searchEngines,
            requiringSecureCoding: true
        )

        // Test write
        try encodedData.write(to: URL(fileURLWithPath: customFileEnginePath))

        // Test read
        guard let readData = try? Data(contentsOf: URL(fileURLWithPath: customFileEnginePath)) else {
            throw OpenSearchEngineError.failedReadingPlist
        }

        // Decode the data
        let unarchiveClasses = [NSArray.self, OpenSearchEngine.self, NSString.self, UIImage.self]
        let parsedSearchEngines = try NSKeyedUnarchiver.unarchivedObject(ofClasses: unarchiveClasses,
                                                                         from: readData) as? [OpenSearchEngine]

        // Test encode/decode works as expected without changing the data after file write
        XCTAssertNotNil(parsedSearchEngines)
        XCTAssertEqual(searchEngines.count, parsedSearchEngines?.count)
        // NOTE: UIImages initialized from the bundle will not contain the underlying Data, just the asset name.
        // `OpenSearchEngine`'s encode method should handle this, which is how we can guarantee the size of the data
        // returned from the `NSKEyedUnarchiver` is greater than the approximate size of the two images. If the
        // images are not properly encoded, the returned data will only be around 2 kB.
        XCTAssertGreaterThan(
            readData.count,
            6000,
            "Expect the file data to be at LEAST greater than 6 kB (images alone are over 6 kB)"
        )
    }

    /// For generating test `OpenSearchEngine` data.
    public enum TestSearchEngine {
        case youtube, wikipedia

        var engineID: String {
            switch self {
            case .wikipedia:
                return "Wiki"
            case .youtube:
                return "YT"
            }
        }
        var name: String {
            return imageName.capitalized
        }
        var imageName: String {
            switch self {
            case .wikipedia:
                return "wikipedia"
            case .youtube:
                return "youtube"
            }
        }
    }

    private enum OpenSearchEngineError: Error {
        case imageNotInBundle, failedReadingPlist
    }

    /// Creates a single `OpenSearchEngine` with valid image data pulled from the test's asset catalog.
    public static func generateOpenSearchEngine(type: TestSearchEngine) throws -> OpenSearchEngine {
        guard let testImage = UIImage(
            named: type.imageName,
            in: Bundle(for: OpenSearchEngineTests.self),
            compatibleWith: nil
        ) else {
            throw OpenSearchEngineError.imageNotInBundle
        }

        return generateOpenSearchEngine(type: type, withImage: testImage)
    }

    public static func generateOpenSearchEngine(type: TestSearchEngine, withImage testImage: UIImage) -> OpenSearchEngine {
        return OpenSearchEngine(
            engineID: type.engineID,
            shortName: type.name,
            image: testImage,
            searchTemplate: "some link",
            suggestTemplate: nil,
            isCustomEngine: true
        )
    }

    private var customFileEnginePath: String {
        get throws {
            let sharedContainerIdentifier = "group.org.mozilla.ios.Fennec"
            let profileDirName = "profile.profile"
            let customSearchEnginesFileName = "customEngines.plist"

            var directoryPath: String
            if let url = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: sharedContainerIdentifier
            ) {
                directoryPath = url.appendingPathComponent(profileDirName).path
            } else {
                directoryPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
            }

            let fileAccessor = FileAccessor(rootPath: directoryPath)
            let profilePath = try fileAccessor.getAndEnsureDirectory() as NSString
            return profilePath.appendingPathComponent(customSearchEnginesFileName)
        }
    }
}
