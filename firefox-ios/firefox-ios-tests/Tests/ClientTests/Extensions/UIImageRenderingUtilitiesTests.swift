// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class UIImageRenderingUtilitiesTests: XCTestCase {
    // MARK: copiedIntoOwnedBitmap

    func testCopiedIntoOwnedBitmap_preservesSizeAndScale() {
        let subject = makeImage(color: .red, size: CGSize(width: 40, height: 20), scale: 2)

        let result = subject.copiedIntoOwnedBitmap()

        XCTAssertEqual(result.size, subject.size)
        XCTAssertEqual(result.scale, subject.scale)
    }

    func testCopiedIntoOwnedBitmap_preservesPixelDimensions() throws {
        let subject = makeImage(color: .red, size: CGSize(width: 40, height: 20), scale: 2)
        let sourceBacking = try XCTUnwrap(subject.cgImage)

        let resultBacking = try XCTUnwrap(subject.copiedIntoOwnedBitmap().cgImage)

        XCTAssertEqual(resultBacking.width, sourceBacking.width)
        XCTAssertEqual(resultBacking.height, sourceBacking.height)
    }

    func testCopiedIntoOwnedBitmap_returnsDistinctBacking() throws {
        let subject = makeImage(color: .red, size: CGSize(width: 40, height: 20), scale: 2)
        let originalBacking = try XCTUnwrap(subject.cgImage)

        let resultBacking = try XCTUnwrap(subject.copiedIntoOwnedBitmap().cgImage)

        XCTAssertFalse(originalBacking === resultBacking)
    }

    func testCopiedIntoOwnedBitmap_preservesPixelContent() throws {
        let subject = makeImage(color: .red, size: CGSize(width: 40, height: 20), scale: 2)

        let result = try XCTUnwrap(firstPixel(of: subject.copiedIntoOwnedBitmap()))

        XCTAssertEqual(Int(result.red), 255, accuracy: 2)
        XCTAssertEqual(Int(result.green), 0, accuracy: 2)
        XCTAssertEqual(Int(result.blue), 0, accuracy: 2)
        XCTAssertEqual(Int(result.alpha), 255, accuracy: 2)
    }

    func testCopiedIntoOwnedBitmap_withZeroSizeImage_returnsSameImage() {
        let subject = UIImage()

        let result = subject.copiedIntoOwnedBitmap()

        XCTAssertTrue(result === subject)
    }

    // MARK: - Helpers

    private func makeImage(color: UIColor, size: CGSize, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private struct Pixel {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8
    }

    /// Averages the image down to a single pixel, which is the image's uniform color for the solid
    /// fills these tests use.
    private func firstPixel(of image: UIImage) -> Pixel? {
        guard let cgImage = image.cgImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(data: &pixel,
                                      width: 1,
                                      height: 1,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return Pixel(red: pixel[0], green: pixel[1], blue: pixel[2], alpha: pixel[3])
    }
}
