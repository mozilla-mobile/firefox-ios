// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UIKit

@testable import Client

final class GoogleLensImageProcessorTests: XCTestCase {
    func test_process_downscalesLongestDimensionToMax_preservingAspectRatio() throws {
        let subject = GoogleLensImageProcessor()
        let image = makeImage(width: 2000, height: 1000)

        let result = try XCTUnwrap(subject.process(image))

        XCTAssertEqual(result.dimensions, CGSize(width: 1000, height: 500))
    }

    func test_process_downscalesPortraitImage() throws {
        let subject = GoogleLensImageProcessor()
        let image = makeImage(width: 1000, height: 2000)

        let result = try XCTUnwrap(subject.process(image))

        XCTAssertEqual(result.dimensions, CGSize(width: 500, height: 1000))
    }

    func test_process_doesNotUpscaleImagesSmallerThanMax() throws {
        let subject = GoogleLensImageProcessor()
        let image = makeImage(width: 400, height: 300)

        let result = try XCTUnwrap(subject.process(image))

        XCTAssertEqual(result.dimensions, CGSize(width: 400, height: 300))
    }

    func test_process_encodedDataDecodesToReportedDimensions() throws {
        let subject = GoogleLensImageProcessor()
        let image = makeImage(width: 1600, height: 800)

        let result = try XCTUnwrap(subject.process(image))
        let decoded = try XCTUnwrap(UIImage(data: result.jpegData))

        // 1600 (longest side) scaled to the 1000px max → 1000x500.
        XCTAssertEqual(result.dimensions, CGSize(width: 1000, height: 500))
        // UIImage(data:) for JPEG has scale 1, so points equal pixels here.
        XCTAssertEqual(decoded.size.width, 1000, accuracy: 1)
        XCTAssertEqual(decoded.size.height, 500, accuracy: 1)
    }

    func test_process_producesNonEmptyJpegData() throws {
        let subject = GoogleLensImageProcessor()
        let image = makeImage(width: 500, height: 500)

        let result = try XCTUnwrap(subject.process(image))

        XCTAssertFalse(result.jpegData.isEmpty)
    }

    // MARK: - Helpers
    private func makeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height),
                                               format: format)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
