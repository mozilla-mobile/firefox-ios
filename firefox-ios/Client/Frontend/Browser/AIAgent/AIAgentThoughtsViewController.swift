// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common

private struct AIAgentBorderGlow: View {
    var color: Color
    private struct UX {
        static let borderWidth: CGFloat = 50
        static let cornerRadius: CGFloat = 55
        static let blurRadius: CGFloat = 25
    }
    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: UX.cornerRadius, style: .continuous)
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .overlay(Rectangle().stroke(color, lineWidth: UX.borderWidth))
                .overlay(shape.stroke(color, lineWidth: UX.borderWidth))
                .blur(radius: UX.blurRadius)
        }
        .ignoresSafeArea(.all)
        .background(Color.clear)
        .allowsHitTesting(false)
    }
}

final class AIAgentPanelView: UIView {
    var interactiveRect: (() -> CGRect)?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let rect = interactiveRect?() else {
            return super.point(inside: point, with: event)
        }
        return rect.contains(point)
    }
}

final class AIAgentThoughtsViewController: UIViewController, Themeable {
    private struct UX {
        static let revealPercentage: CGFloat = 0.13
        static let resultPanelPercentage: CGFloat = 0.5
        static let fadeBandFraction: CGFloat = 0.06
        static let cornerRadius: CGFloat = 20.0
        static let horizontalPadding: CGFloat = 20.0
        static let topPadding: CGFloat = 8.0
        static let closeButtonSize: CGFloat = 30.0
        static let animationDuration: TimeInterval = 0.5
        static let snapshotShadowRadius: CGFloat = 48.0
        static let snapshotShadowOffset = CGSize(width: 0, height: -8.0)
        static let snapshotShadowOpacity: Float = 0.6
        static let dismissTranslationThreshold: CGFloat = 80.0
        static let dismissVelocityThreshold: CGFloat = 700.0
        static let shimmerDarkAlpha: CGFloat = 0.35
    }

    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    let currentWindowUUID: WindowUUID?

    private let prompt: String
    private let snapshot: UIImage
    private let snapshotTopOffset: CGFloat
    private var thought: String

    private var revealDistance: CGFloat = 0
    private var snapshotTopConstraint: NSLayoutConstraint?
    private enum Phase { case reading, acting, done }
    private var phase: Phase = .reading

    private let backgroundGradient = CAGradientLayer()

    private lazy var borderGlowController: UIHostingController<AIAgentBorderGlow> = {
        let theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        let host = UIHostingController(rootView: AIAgentBorderGlow(color: Color(theme.colors.shadowBorder)))
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        return host
    }()

    private let snapshotContainer: UIView = .build { view in
        view.layer.shadowOffset = UX.snapshotShadowOffset
        view.layer.shadowRadius = UX.snapshotShadowRadius
        view.layer.shadowOpacity = UX.snapshotShadowOpacity
        view.layer.shadowColor = UIColor.black.cgColor
    }

    private let snapshotImageView: UIImageView = .build { imageView in
        imageView.contentMode = .top
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = UX.cornerRadius
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    private lazy var thoughtLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
    }

    private lazy var resultTextView: UITextView = .build { textView in
        textView.font = FXFontStyles.Regular.headline.scaledFont()
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.showsVerticalScrollIndicator = true
        textView.adjustsFontForContentSizeCategory = true
        textView.alpha = 0
        textView.textContainerInset = .zero
    }

    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.addAction(UIAction(handler: { _ in self?.dismissPanel() }), for: .touchUpInside)
    }

    init(prompt: String,
         snapshot: UIImage,
         snapshotTopOffset: CGFloat,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.prompt = prompt
        self.snapshot = snapshot
        self.snapshotTopOffset = snapshotTopOffset
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.thought = "Reading the page…"
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let panel = AIAgentPanelView()
        panel.interactiveRect = { [weak self] in
            guard let self else { return .zero }
            return self.phase == .reading ? self.view.bounds : self.bannerRect
        }
        view = panel
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundGradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundGradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(backgroundGradient, at: 0)
        setupViews()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradient()
        if phase != .done { restartShimmer() }
    }

    private var cardTopFraction: CGFloat {
        switch phase {
        case .reading: return 1.0
        case .acting: return UX.revealPercentage
        case .done: return UX.resultPanelPercentage
        }
    }

    private var bannerRect: CGRect {
        let height = (phase == .reading) ? view.bounds.height
                                         : view.bounds.height * cardTopFraction
        return CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
    }

    private func updateGradient() {
        guard let uuid = currentWindowUUID else { return }
        let solid = themeManager.getCurrentTheme(for: uuid).colors.layerGradientSummary.cgColors
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }

        if phase != .acting {
            backgroundGradient.frame = view.bounds
            backgroundGradient.colors = solid
            backgroundGradient.locations = nil
            return
        }
        let cardTop = bannerRect.height
        let overlap = view.bounds.height * UX.fadeBandFraction
        let total = cardTop + overlap
        backgroundGradient.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: total)
        guard let last = solid.last else { return }
        let lastClear = last.copy(alpha: 0) ?? last
        backgroundGradient.colors = solid + [last, lastClear]
        let fadeStart = cardTop / total
        backgroundGradient.locations = [0, 0.5, NSNumber(value: Float(fadeStart)), 1.0]
    }

    private func setupViews() {
        view.addSubview(closeButton)
        view.addSubview(thoughtLabel)
        view.addSubview(resultTextView)
        view.addSubview(snapshotContainer)
        snapshotContainer.addSubview(snapshotImageView)
        snapshotImageView.image = snapshot
        thoughtLabel.text = thought

        addChild(borderGlowController)
        borderGlowController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(borderGlowController.view)
        borderGlowController.didMove(toParent: self)

        snapshotImageView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = snapshotContainer.topAnchor.constraint(equalTo: view.topAnchor,
                                                                   constant: snapshotTopOffset)
        snapshotTopConstraint = topConstraint

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                             constant: UX.topPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.horizontalPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            thoughtLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            thoughtLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                  constant: UX.horizontalPadding),
            thoughtLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                   constant: -UX.horizontalPadding),

            resultTextView.topAnchor.constraint(equalTo: closeButton.bottomAnchor,
                                                constant: UX.topPadding),
            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                    constant: UX.horizontalPadding),
            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                     constant: -UX.horizontalPadding),
            resultTextView.heightAnchor.constraint(equalTo: view.heightAnchor,
                                                   multiplier: UX.resultPanelPercentage,
                                                   constant: -UX.closeButtonSize),

            snapshotContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            snapshotContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            snapshotContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            topConstraint,

            snapshotImageView.leadingAnchor.constraint(equalTo: snapshotContainer.leadingAnchor),
            snapshotImageView.trailingAnchor.constraint(equalTo: snapshotContainer.trailingAnchor),
            snapshotImageView.topAnchor.constraint(equalTo: snapshotContainer.topAnchor),
            snapshotImageView.bottomAnchor.constraint(equalTo: snapshotContainer.bottomAnchor),

            borderGlowController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderGlowController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            borderGlowController.view.topAnchor.constraint(equalTo: view.topAnchor),
            borderGlowController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        snapshotContainer.addGestureRecognizer(pan)
    }

    private func restartShimmer() {
        guard thoughtLabel.bounds.width > 0, thoughtLabel.alpha > 0 else { return }
        let onGradient = themeManager.getCurrentTheme(for: currentWindowUUID).colors.textOnDark
        thoughtLabel.startShimmering(light: onGradient,
                                     dark: onGradient.withAlphaComponent(UX.shimmerDarkAlpha))
    }

    func animateIn() {
        view.layoutIfNeeded()
        revealDistance = view.bounds.height * UX.revealPercentage
        snapshotTopConstraint?.constant = snapshotTopOffset + revealDistance
        UIView.animate(withDuration: UX.animationDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.82,
                       initialSpringVelocity: 0.4,
                       options: .curveEaseOut) {
            self.view.layoutIfNeeded()
        }
    }

    func revealLivePage() {
        guard phase == .reading else { return }
        phase = .acting
        view.layoutIfNeeded()
        snapshotTopConstraint?.constant = view.bounds.height * UX.revealPercentage
        UIView.animate(withDuration: UX.animationDuration,
                       delay: 0,
                       options: .curveEaseInOut) {
            self.updateGradient()
            self.view.layoutIfNeeded()
        }
    }

    func updateSnapshot(_ image: UIImage) {
        guard phase != .done else { return }
        snapshotImageView.image = image
    }

    func dismissPanel() {
        thoughtLabel.stopShimmering()
        snapshotTopConstraint?.constant = snapshotTopOffset
        UIView.animate(withDuration: UX.animationDuration,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.3,
                       options: .curveEaseInOut,
                       animations: { self.view.layoutIfNeeded() },
                       completion: { _ in
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        })
    }

    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view).y
        switch gesture.state {
        case .changed:
            let resting = snapshotTopOffset + revealDistance
            snapshotTopConstraint?.constant = max(snapshotTopOffset, resting + min(0, translation))
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            if translation < -UX.dismissTranslationThreshold || velocity < -UX.dismissVelocityThreshold {
                dismissPanel()
            } else {
                animateIn()
            }
        default:
            break
        }
    }

    func applyTheme() {
        guard let uuid = currentWindowUUID else { return }
        let theme = themeManager.getCurrentTheme(for: uuid)
        view.backgroundColor = .clear
        updateGradient()
        let onGradient = theme.colors.textOnDark
        thoughtLabel.textColor = onGradient
        resultTextView.textColor = onGradient
        closeButton.tintColor = onGradient
        borderGlowController.rootView = AIAgentBorderGlow(color: Color(theme.colors.shadowBorder))
        restartShimmer()
    }

    private func setThought(_ text: String) {
        guard phase != .done else { return }
        thought = text
        thoughtLabel.text = text
        view.setNeedsLayout()
        view.layoutIfNeeded()
        restartShimmer()
    }

    func update(with map: AgentPageMap) {
        setThought(AIAgentThoughtsViewController.firstLine(for: prompt, map: map))
    }

    func update(with result: AgentStepResult) {
        if let d = result.decision {
            setThought(d.thought)
        } else {
            setThought("Couldn't parse response")
        }
    }

    func update(error: Error) {
        setThought("Error: \(error.localizedDescription)")
    }

    func finish(with result: AgentStepResult) {
        guard phase != .done else { return }
        let answer = result.decision?.answer ?? result.decision?.thought ?? "Done"
        showResult(answer)
    }

    private func showResult(_ text: String) {
        guard phase != .done else { return }
        phase = .done
        thoughtLabel.stopShimmering()
        resultTextView.text = text

        let transition = CATransition()
        transition.type = .fade
        transition.duration = UX.animationDuration
        resultTextView.layer.add(transition, forKey: "fade")

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UIView.animate(withDuration: UX.animationDuration,
                       delay: 0,
                       options: .curveEaseInOut) {
            self.thoughtLabel.alpha = 0
            self.resultTextView.alpha = 1
            self.snapshotContainer.alpha = 0
            self.updateGradient()
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.snapshotContainer.isHidden = true
        }
    }

    private static func firstLine(for prompt: String, map: AgentPageMap) -> String {
        let s = map.summary
        if s.total == 0 && (s.title == "Firefox Home" || s.url.hasPrefix("internal://")) {
            return "Looking at: \(prompt)"
        }
        return "Reading \(s.title ?? s.url)…"
    }
}
