// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import ToolbarKit

@MainActor
final class StackedTabButtonTests: XCTestCase {
    private var button: StackedTabButton!
    private var previousImage: UIImage!
    private var nextImage: UIImage!

    override func setUp() async throws {
        try await super.setUp()
        button = StackedTabButton()
        previousImage = makeScreenshot(color: .red)
        nextImage = makeScreenshot(color: .blue)
    }

    override func tearDown() async throws {
        button = nil
        previousImage = nil
        nextImage = nil
        try await super.tearDown()
    }

    // MARK: - Screenshot Handling
    func testConfigure_withBothScreenshots_setsImages() {
        button.configure(element: makeElement(previousTabScreenshot: previousImage, nextTabScreenshot: nextImage))

        XCTAssertEqual(button.topImageView.image, nextImage)
        XCTAssertEqual(button.bottomImageView.image, previousImage)
    }

    func testConfigure_withNilScreenshots_clearsImages() {
        button.configure(element: makeElement())

        XCTAssertNil(button.topImageView.image)
        XCTAssertNil(button.bottomImageView.image)
    }

    // MARK: - Gradient Opacity
    func testConfigure_withScreenshots_hidesGradients() {
        button.configure(element: makeElement(previousTabScreenshot: previousImage, nextTabScreenshot: nextImage))

        XCTAssertEqual(button.topImageViewGradient.opacity, 0)
        XCTAssertEqual(button.bottomImageViewGradient.opacity, 0)
    }

    func testConfigure_withNilScreenshots_showsGradients() {
        button.configure(element: makeElement())

        XCTAssertEqual(button.topImageViewGradient.opacity, 1)
        XCTAssertEqual(button.bottomImageViewGradient.opacity, 1)
    }

    func testConfigure_withGroupBadge_framesAndShadowsThumbnails() throws {
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.configure(element: makeElement(groupBadge: UIImage(),
                                              previousTabScreenshot: previousImage,
                                              nextTabScreenshot: nextImage))
        button.layoutIfNeeded()

        for image in [button.topImageView, button.bottomImageView] {
            let card = try XCTUnwrap(image.superview)
            let expectedFrame = card.bounds
            let pixelTolerance = 1 / max(button.traitCollection.displayScale, 1)
            XCTAssertGreaterThan(card.bounds.height, card.bounds.width)
            XCTAssertEqual(image.frame.minX, expectedFrame.minX, accuracy: pixelTolerance)
            XCTAssertEqual(image.frame.minY, expectedFrame.minY, accuracy: pixelTolerance)
            XCTAssertEqual(image.frame.size, expectedFrame.size)
            XCTAssertTrue(image.clipsToBounds)
            XCTAssertFalse(card.clipsToBounds)
            XCTAssertFalse(card.isUserInteractionEnabled)
            XCTAssertEqual(image.layer.borderWidth, 1.5)
            XCTAssertEqual(card.layer.borderWidth, 0)
            XCTAssertEqual(card.layer.cornerRadius, image.layer.cornerRadius)
            XCTAssertGreaterThan(card.layer.shadowOpacity, 0)
            XCTAssertNotNil(card.layer.shadowPath)
        }
    }

    func testConfigure_whenGroupBadgeIsRemoved_restoresOrdinaryScreenshots() throws {
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.applyTheme(theme: NovaLightTheme())
        let element = makeElement(previousTabScreenshot: previousImage, nextTabScreenshot: nextImage)
        button.configure(element: element)
        button.layoutIfNeeded()
        let images = [button.topImageView, button.bottomImageView]
        let cards = try images.map { try XCTUnwrap($0.superview) }
        let originalFrames = cards.map(\.frame)
        let originalTransforms = cards.map(\.transform)
        let originalBorderColor = button.topImageView.layer.borderColor

        button.configure(element: makeElement(groupBadge: UIImage(),
                                              previousTabScreenshot: previousImage,
                                              nextTabScreenshot: nextImage))
        button.layoutIfNeeded()
        button.configure(element: element)
        button.layoutIfNeeded()

        for (index, card) in cards.enumerated() {
            let image = images[index]
            XCTAssertEqual(card.frame, originalFrames[index])
            XCTAssertEqual(card.transform, originalTransforms[index])
            XCTAssertEqual(image.frame, card.bounds)
            XCTAssertEqual(image.layer.cornerRadius, 4)
            XCTAssertEqual(image.layer.borderWidth, 0.5)
            XCTAssertEqual(image.layer.borderColor, originalBorderColor)
            XCTAssertEqual(card.backgroundColor, .clear)
            XCTAssertEqual(card.layer.shadowOpacity, 0)
            XCTAssertNil(card.layer.shadowPath)
        }
        XCTAssertEqual(button.topImageView.image, nextImage)
        XCTAssertEqual(button.bottomImageView.image, previousImage)
    }

    func testApplyTheme_withGroupBadge_updatesFrameColors() throws {
        button.configure(element: makeElement(groupBadge: UIImage()))
        let cards = try [button.topImageView, button.bottomImageView].map { try XCTUnwrap($0.superview) }
        let themes: [any Theme] = [NovaLightTheme(), NovaDarkTheme()]

        for theme in themes {
            button.applyTheme(theme: theme)

            for (card, image) in zip(cards, [button.topImageView, button.bottomImageView]) {
                XCTAssertEqual(card.backgroundColor, theme.colors.borderPrimary)
                XCTAssertEqual(image.layer.borderColor, theme.colors.borderPrimary.cgColor)
                XCTAssertEqual(image.layer.borderColor?.alpha, 1)
            }
        }
    }

    func testConfigure_withGroupBadge_preservesScreenshotAndGradientFallback() {
        button.configure(element: makeElement(groupBadge: UIImage(), nextTabScreenshot: nextImage))

        XCTAssertEqual(button.topImageView.image, nextImage)
        XCTAssertEqual(button.topImageViewGradient.opacity, 0)
        XCTAssertNil(button.bottomImageView.image)
        XCTAssertEqual(button.bottomImageViewGradient.opacity, 1)
    }

    func testConfigure_withGroupBadge_rendersOpaqueFramesInToolbarHierarchy() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        let controller = UIViewController()
        window.rootViewController = controller
        controller.view.backgroundColor = .systemPink
        button.translatesAutoresizingMaskIntoConstraints = false
        let toolbar = UIStackView(arrangedSubviews: [button])
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(toolbar)
        NSLayoutConstraint.activate([
            toolbar.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            toolbar.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
        ])
        window.isHidden = false
        defer { window.isHidden = true }
        let screenshot = makeScreenshot(color: .black)
        let element = makeElement(groupBadge: UIImage(),
                                  previousTabScreenshot: screenshot,
                                  nextTabScreenshot: screenshot)
        let themes: [any Theme] = [NovaLightTheme(), NovaDarkTheme()]

        for theme in themes {
            window.overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
            for appliesThemeFirst in [true, false] {
                UIView.performWithoutAnimation {
                    button.configure(element: makeElement())
                    if appliesThemeFirst { button.applyTheme(theme: theme) }
                    button.configure(element: element)
                    if !appliesThemeFirst { button.applyTheme(theme: theme) }
                    window.layoutIfNeeded()
                }
                let format = UIGraphicsImageRendererFormat()
                format.scale = 3
                let rendered = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { context in
                    window.layer.render(in: context.cgContext)
                }
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                XCTAssertTrue(theme.colors.borderPrimary.getRed(&red, green: &green, blue: &blue, alpha: &alpha))

                for image in [button.bottomImageView, button.topImageView] {
                    let card = try XCTUnwrap(image.superview)
                    let point = card.convert(CGPoint(x: card.bounds.midX, y: 0.75), to: window)
                    let pixel = try rgbaPixel(at: point, in: rendered)
                    let cardName = image === button.bottomImageView ? "back" : "front"
                    let message = "\(theme.type) \(cardName) frame, theme first: \(appliesThemeFirst)"
                    for (actual, expected) in zip(pixel, [red, green, blue, alpha]) {
                        XCTAssertEqual(CGFloat(actual) / 255, expected, accuracy: 0.03, message)
                    }
                }
            }
        }
    }

    // MARK: - Helper
    private func rgbaPixel(at point: CGPoint, in image: UIImage) throws -> [UInt8] {
        let source = try XCTUnwrap(image.cgImage)
        let rect = CGRect(x: floor(point.x * image.scale), y: floor(point.y * image.scale), width: 1, height: 1)
        let pixel = try XCTUnwrap(source.cropping(to: rect))
        var rgba = [UInt8](repeating: 0, count: 4)
        try rgba.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(data: bytes.baseAddress,
                                                  width: 1,
                                                  height: 1,
                                                  bitsPerComponent: 8,
                                                  bytesPerRow: 4,
                                                  space: CGColorSpaceCreateDeviceRGB(),
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue |
                                                    CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return rgba
    }

    private func makeScreenshot(color: UIColor) -> UIImage {
        let bounds = CGRect(x: 0, y: 0, width: 120, height: 200)
        return UIGraphicsImageRenderer(size: bounds.size).image { _ in
            color.setFill()
            UIRectFill(bounds)
        }
    }

    private func makeElement(
        groupBadge: UIImage? = nil,
        previousTabScreenshot: UIImage? = nil,
        nextTabScreenshot: UIImage? = nil
    ) -> ToolbarElement {
        return ToolbarElement(
            bottomLeadingBadgeImage: groupBadge,
            isEnabled: true,
            a11yLabel: "Tabs",
            a11yHint: nil,
            a11yId: "testId",
            previousTabScreenshot: previousTabScreenshot,
            nextTabScreenshot: nextTabScreenshot,
            onSelected: nil
        )
    }
}
