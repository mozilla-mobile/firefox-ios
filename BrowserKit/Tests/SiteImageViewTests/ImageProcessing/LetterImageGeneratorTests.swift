// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

final class LetterImageGeneratorTests: XCTestCase {
    func testEmptyDomain_throws() async {
        let subject = DefaultLetterImageGenerator()
        let siteString = ""

        do {
            _ = try await subject.generateLetterImage(siteString: siteString)
            XCTFail("Call should have thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, SiteImageError.noLetterImage.localizedDescription)
        }
    }

    func testGenerateLetter_fromEmptyString_throws() async {
        let subject = DefaultLetterImageGenerator()
        let siteString = ""

        do {
            _ = try subject.generateLetter(fromSiteString: siteString)
            XCTFail("Call should have thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, SiteImageError.noLetterImage.localizedDescription)
        }
    }

    func testGenerateLetter_fromString_returnsCapitalizedLetter() async throws {
        let subject = DefaultLetterImageGenerator()
        let siteString = "mozilla.org"
        let expectedLetter = "M"

        let letter = try subject.generateLetter(fromSiteString: siteString)
        XCTAssertEqual(letter, expectedLetter)
    }

    func testGenerateLetter_fromNonAlphanumericString_returnsFirstCharacter() async throws {
        let subject = DefaultLetterImageGenerator()
        let siteString = "?$!@"
        let expectedLetter = "?"

        let letter = try subject.generateLetter(fromSiteString: siteString)
        XCTAssertEqual(letter, expectedLetter)
    }

    func testGenerateImageFromLetter_returnsNonEmptyImage() async {
        let subject = DefaultLetterImageGenerator()

        let image = await subject.generateImage(fromLetter: "H", color: .red)
        XCTAssertNotEqual(image, UIImage())
    }

    func testGenerateImageFromLetter_returnsImageWithCorrectBackgroundColor() async {
        let subject = DefaultLetterImageGenerator()
        let letter = "H"
        let backgroundColor = UIColor.red
        let pixelSamplePoint = CGPoint(x: 5, y: 5)

        let image = await subject.generateImage(fromLetter: letter, color: backgroundColor)
        XCTAssertEqual(try? image.cgImage?.getPixelColor(pixelSamplePoint), backgroundColor)
    }

    func testGenerateLetterImage_returnsImageWithCorrectBackgroundColor_forM() async throws {
        let subject = DefaultLetterImageGenerator()
        let siteString = "mozilla.com"
        let expectedBackgroundColor = UIColor(red: 0.223, green: 0.576, blue: 0.125, alpha: 1.0)
        let pixelSamplePoint = CGPoint(x: 5, y: 5)

        let image = try await subject.generateLetterImage(siteString: siteString)
        let capturedColor = try XCTUnwrap(try? image.cgImage?.getPixelColor(pixelSamplePoint))

        testColor(capturedColor: capturedColor, expectedColor: expectedBackgroundColor)
    }

    func testGenerateLetterImage_returnsImageWithCorrectBackgroundColor_forF() async throws {
        let subject = DefaultLetterImageGenerator()
        let siteString = "firefox.com"
        let expectedBackgroundColor = UIColor(red: 0.584, green: 0.803, blue: 1.0, alpha: 1.0)
        let pixelSamplePoint = CGPoint(x: 5, y: 5)

        let image = try await subject.generateLetterImage(siteString: siteString)
        let capturedColor = try XCTUnwrap(try? image.cgImage?.getPixelColor(pixelSamplePoint))

        testColor(capturedColor: capturedColor, expectedColor: expectedBackgroundColor)
    }

    func testGenerateLetterImage_returnsImageWithCorrectBackgroundColor_forNonAlphaCharacter() async throws {
        let subject = DefaultLetterImageGenerator()
        let siteString = "?$%^"
        let expectedBackgroundColor = UIColor(red: 0.003, green: 0.639, blue: 0.615, alpha: 1.0)
        let pixelSamplePoint = CGPoint(x: 5, y: 5)

        let image = try await subject.generateLetterImage(siteString: siteString)
        let capturedColor = try XCTUnwrap(try? image.cgImage?.getPixelColor(pixelSamplePoint))

        testColor(capturedColor: capturedColor, expectedColor: expectedBackgroundColor)
    }
}

private extension LetterImageGeneratorTests {
    /// Performs `XCTAssertEqual` color comparison on hex values accurate to the 0.001 place. We can't precisely compare
    /// floating point values.
    func testColor(capturedColor: UIColor,
                   expectedColor: UIColor,
                   file: StaticString = #filePath,
                   line: UInt = #line) {
        var capturedRed: CGFloat = 0
        var capturedGreen: CGFloat = 0
        var capturedBlue: CGFloat = 0
        var capturedAlpha: CGFloat = 0
        capturedColor.getRed(&capturedRed,
                             green: &capturedGreen,
                             blue: &capturedBlue,
                             alpha: &capturedAlpha)

        var resultRed: CGFloat = 0
        var resultGreen: CGFloat = 0
        var resultBlue: CGFloat = 0
        var resultAlpha: CGFloat = 0
        expectedColor.getRed(&resultRed,
                             green: &resultGreen,
                             blue: &resultBlue,
                             alpha: &resultAlpha)

        XCTAssertEqual(resultRed, capturedRed, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(resultGreen, capturedGreen, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(resultBlue, capturedBlue, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(resultAlpha, capturedAlpha, accuracy: 0.001, file: file, line: line)
    }
}

// MARK: - Helper Methods
enum ImageError: Error {
    case BadData
    case BadChannelCount
    case IncorrectByteSize
}

extension UIImage {
    /// Tests for UIImage equality by comparing the underlying data
    /// - Parameter inputImage: The image to compare against.
    /// - Returns: Returns true if the images contain underlying equal PNG data.
    func isSameData(asImage inputImage: UIImage) -> Bool {
        return self.pngData() == inputImage.pngData()
    }
}

// `CGBitmapInfo` and `CGImage` helper logic adapted from:
// https://stackoverflow.com/a/49087310
// https://stackoverflow.com/a/36236716
extension CGBitmapInfo {
    enum ComponentLayout {
        case bgra, abgr, argb, rgba, bgr, rgb

        var count: Int {
            switch self {
            case .bgr, .rgb: return 3
            default: return 4
            }
        }
    }

    var componentLayout: ComponentLayout? {
        guard let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) else { return nil }
        let isLittleEndian = contains(.byteOrder32Little)

        if alphaInfo == .none {
            return isLittleEndian ? .bgr : .rgb
        }
        let alphaIsFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst

        if isLittleEndian {
            return alphaIsFirst ? .bgra : .abgr
        } else {
            return alphaIsFirst ? .argb : .rgba
        }
    }

    var isAlphaPremultiplied: Bool {
        let alphaInfo = CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue)
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

extension CGImage {
    /// Gets the color of a pixel in a 4-channel image
    /// - Parameter point: The pixel to sample
    /// - Returns: The UIColor at the pixel. Throws an error if the image does not have 4 channels (RGB and alpha).
    func getPixelColor(_ point: CGPoint) throws -> UIColor {
        let x = Int(point.x)
        let y = Int(point.y)
        let width = self.width
        let index = width * y + x

        guard let pixelData = self.dataProvider?.data,
              let layout = bitmapInfo.componentLayout,
              let data = CFDataGetBytePtr(pixelData) else {
            throw ImageError.BadData
        }

        let isAlphaPremultiplied = bitmapInfo.isAlphaPremultiplied
        let numComponents = layout.count

        switch numComponents {
        case 3:
            let c0 = CGFloat((data[3*index])) / 255
            let c1 = CGFloat((data[3*index+1])) / 255
            let c2 = CGFloat((data[3*index+2])) / 255
            if layout == .bgr {
                return UIColor(red: c2, green: c1, blue: c0, alpha: 1.0)
            }
            return UIColor(red: c0, green: c1, blue: c2, alpha: 1.0)
        case 4:
            let c0 = CGFloat((data[4*index])) / 255
            let c1 = CGFloat((data[4*index+1])) / 255
            let c2 = CGFloat((data[4*index+2])) / 255
            let c3 = CGFloat((data[4*index+3])) / 255
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            switch layout {
            case .abgr:
                a = c0; b = c1; g = c2; r = c3
            case .argb:
                a = c0; r = c1; g = c2; b = c3
            case .bgra:
                b = c0; g = c1; r = c2; a = c3
            case .rgba:
                r = c0; g = c1; b = c2; a = c3
            default:
                break
            }
            if isAlphaPremultiplied && a > 0 {
                r = r / a
                g = g / a
                b = b / a
            }
            return UIColor(red: r, green: g, blue: b, alpha: a)
        default:
            throw ImageError.BadChannelCount
        }
    }
}
