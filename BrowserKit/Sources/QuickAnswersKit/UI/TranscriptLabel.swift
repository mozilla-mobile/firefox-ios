// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreImage.CIFilterBuiltins
import UIKit
import Common

/// A label that reveals the characters appended by each transcript update by fading them in
/// from the bottom while they sharpen out of a blur.
final class TranscriptLabel: UILabel {
    private enum UX {
        static let animationDuration: TimeInterval = 0.2
        static let chunkInitialOffset: CGFloat = 6.0
        /// The radius the appended text is blurred by when it starts animating in. It ramps down
        /// to zero over the animation.
        static let blurRadius: CGFloat = 5.0
        /// The padding around the snapshot, so the blur isn't clipped by the snapshot bounds.
        static let blurPadding = blurRadius * 3.0
        /// The ramp is rounded to this step to avoid useless blur re compute.
        static let blurRadiusStep: CGFloat = 1
    }

    /// Overlays the label with the appended characters only, so they animate on their own while
    /// the text already transcribed stays in place. A Core Image filter can't be animated, so the
    /// snapshot it shows is blurred again on every frame with a smaller radius until it is sharp.
    private let blurredTextView = UIImageView()
    private lazy var ciContext = CIContext()
    /// The unblurred snapshot every blurred frame is rendered from.
    private var appendedTextSnapshot: UIImage?
    private var blurDisplayLink: CADisplayLink?
    private var blurStartTimestamp: CFTimeInterval = 0
    private var lastRenderedRadius: CGFloat = -1
    /// The last transcript reported by the transcriber.
    private var transcript = ""
    /// The part of `transcript` that has already been animated in.
    private var revealedTranscript = ""
    private var isAnimatingAppendedText = false

    /// The range of the transcript that hasn't been revealed yet.
    private var appendedTextRange: NSRange {
        let currentTranscript = transcript as NSString
        let revealedLength = min(revealedTranscript.utf16.count, currentTranscript.length)
        guard revealedLength < currentTranscript.length else {
            // return an empty range in case the displayed transcript and the current one as the same length.
            // in this case the text is shown without animation, this can happen if the transcriber adjust the whole text
            // in case of a revision.
            return NSRange(location: 0, length: 0)
        }
        // Don't split a composed character sequence, like an emoji, in half.
        let location = currentTranscript.rangeOfComposedCharacterSequence(at: revealedLength).location
        return NSRange(location: location, length: currentTranscript.length - location)
    }

    /// The text color for this label.
    ///
    /// This property is needed since when applying custom attributed strings the value of `textColor` is not preserved
    /// and thus we need to save it in a separate variable.
    var foregroundColor: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(blurredTextView)
    }

    func setTranscript(_ text: String, animated: Bool) {
        guard text != transcript else { return }
        transcript = text

        guard animated, !UIAccessibility.isReduceMotionEnabled else {
            showFullTranscript()
            return
        }
        // The accumulated text is revealed once the animation in progress settles.
        guard !isAnimatingAppendedText else {
            return
        }
        animateAppendedText()
    }

    private func animateAppendedText() {
        let appendedRange = appendedTextRange
        guard appendedRange.length > 0 else {
            showFullTranscript()
            return
        }
        revealedTranscript = transcript
        isAnimatingAppendedText = true

        // Display the transcript hiding the text the needs to be appended and animated.
        attributedText = attributedTranscript(hiding: appendedRange)
        let appendedText = attributedTranscript(hiding: NSRange(location: 0, length: appendedRange.location))
        startBlurRamp(of: appendedText)

        UIView.animate(withDuration: UX.animationDuration, delay: 0.0, options: .curveEaseIn) { [self] in
            blurredTextView.transform = .identity
            blurredTextView.alpha = 1.0
        } completion: { [weak self] _ in
            ensureMainThread {
                self?.settleAppendedText()
            }
        }
    }

    private func settleAppendedText() {
        isAnimatingAppendedText = false
        guard transcript == revealedTranscript else {
            animateAppendedText()
            return
        }
        showFullTranscript()
    }

    private func showFullTranscript() {
        stopBlurRamp()
        revealedTranscript = transcript
        blurredTextView.image = nil
        attributedText = attributedTranscript(hiding: NSRange(location: 0, length: 0))
    }

    /// Makes the `appendedText` snapshots and blurs it with the initial `UX.blurRadius`
    /// then starts the ramp on the blurred image.
    private func startBlurRamp(of appendedText: NSAttributedString) {
        stopBlurRamp()
        appendedTextSnapshot = snapshot(of: appendedText)
        blurredTextView.image = blurred(appendedTextSnapshot, radius: UX.blurRadius)
        lastRenderedRadius = UX.blurRadius
        // The snapshot is padded on every side, so it's offset to overlap the text it blurs.
        blurredTextView.frame = CGRect(
            origin: CGPoint(x: -UX.blurPadding, y: -UX.blurPadding),
            size: appendedTextSnapshot?.size ?? .zero
        )
        blurredTextView.alpha = 0.1
        blurredTextView.transform = CGAffineTransform(translationX: 0.0, y: UX.chunkInitialOffset)

        let displayLink = CADisplayLink(target: self, selector: #selector(updateBlurRamp))
        displayLink.add(to: .main, forMode: .common)
        blurDisplayLink = displayLink
    }

    @objc
    private func updateBlurRamp(_ displayLink: CADisplayLink) {
        if blurStartTimestamp == 0 {
            blurStartTimestamp = displayLink.timestamp
        }
        let progress = min((displayLink.timestamp - blurStartTimestamp) / UX.animationDuration, 1.0)
        // Calculate the new blur radius based on the progress and normalize it with the step.
        let radius = (UX.blurRadius * (1.0 - progress) / UX.blurRadiusStep).rounded() * UX.blurRadiusStep
        if radius != lastRenderedRadius {
            lastRenderedRadius = radius
            blurredTextView.image = blurred(appendedTextSnapshot, radius: radius)
        }
        if progress >= 1.0 {
            stopBlurRamp()
        }
    }

    private func stopBlurRamp() {
        blurDisplayLink?.invalidate()
        blurDisplayLink = nil
        blurStartTimestamp = 0
    }

    /// Draws the appended text on a padded transparent canvas, laid out like the label draws it.
    /// The characters already revealed are transparent, so only the appended ones show.
    private func snapshot(of appendedText: NSAttributedString) -> UIImage? {
        let textWidth = bounds.width
        guard textWidth > 0 else { return nil }
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let constraint = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let textHeight = ceil(appendedText.boundingRect(with: constraint, options: options, context: nil).height)
        let canvas = CGSize(width: textWidth + UX.blurPadding * 2, height: textHeight + UX.blurPadding * 2)
        return UIGraphicsImageRenderer(size: canvas).image { _ in
            let textRect = CGRect(x: UX.blurPadding, y: UX.blurPadding, width: textWidth, height: textHeight)
            appendedText.draw(with: textRect, options: options, context: nil)
        }
    }

    private func blurred(_ image: UIImage?, radius: CGFloat) -> UIImage? {
        guard let image else { return nil }
        guard radius > 0, let input = CIImage(image: image) else { return image }
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = input
        blur.radius = Float(radius * image.scale)
        guard let output = blur.outputImage?.cropped(to: input.extent),
              let blurredImage = ciContext.createCGImage(output, from: input.extent) else { return image }
        return UIImage(cgImage: blurredImage, scale: image.scale, orientation: .up)
    }

    private func attributedTranscript(hiding range: NSRange) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        var attributes: [NSAttributedString.Key: Any] = [.paragraphStyle: paragraphStyle]
        if let font {
            attributes[.font] = font
        }
        attributes[.foregroundColor] = foregroundColor
        let attributedString = NSMutableAttributedString(string: transcript, attributes: attributes)
        attributedString.addAttribute(.foregroundColor, value: UIColor.clear, range: range)
        return attributedString
    }
}
