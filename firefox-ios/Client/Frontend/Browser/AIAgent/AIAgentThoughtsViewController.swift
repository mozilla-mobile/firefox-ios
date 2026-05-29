// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Shows the AI agent's "thought process" using the same visual language as the
/// shake-to-summarize panel: a snapshot of the current page slides DOWN to reveal the
/// thoughts in the freed space at the top — the page is not just covered by an overlay.
/// Currently renders mock thoughts; meant to be driven by the real agent loop later.
///
/// It is added as a child view controller over the browser content. The page snapshot is
/// captured by the caller and passed in (mirrors `SummarizeCoordinator`'s
/// `browserSnapshot` / `browserSnapshotTopOffset`).
final class AIAgentThoughtsViewController: UIViewController, Themeable {
    private struct UX {
        /// How far down the page snapshot slides (fraction of screen height).
        static let revealPercentage: CGFloat = 0.13
        static let cornerRadius: CGFloat = 20.0
        static let horizontalPadding: CGFloat = 20.0
        static let topPadding: CGFloat = 8.0
        static let stackSpacing: CGFloat = 6.0
        static let closeButtonSize: CGFloat = 30.0
        static let animationDuration: TimeInterval = 0.5
        static let snapshotShadowRadius: CGFloat = 48.0
        static let snapshotShadowOffset = CGSize(width: 0, height: -8.0)
        static let snapshotShadowOpacity: Float = 0.6
        static let dismissTranslationThreshold: CGFloat = 80.0
        static let dismissVelocityThreshold: CGFloat = 700.0
    }

    // MARK: - Themeable
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: NotificationProtocol
    let currentWindowUUID: WindowUUID?

    private let prompt: String
    private let snapshot: UIImage
    private let snapshotTopOffset: CGFloat
    private let thoughts: [String]

    private var revealDistance: CGFloat = 0
    private var snapshotTopConstraint: NSLayoutConstraint?

    // Red gradient behind the thoughts, mirroring the shake-to-summarize panel.
    private let backgroundGradient = CAGradientLayer()

    private let snapshotContainer: UIView = .build { view in
        view.layer.shadowOffset = UX.snapshotShadowOffset
        view.layer.shadowRadius = UX.snapshotShadowRadius
        view.layer.shadowOpacity = UX.snapshotShadowOpacity
        view.layer.shadowColor = UIColor.black.cgColor
    }

    private let snapshotImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = UX.cornerRadius
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.text = "Thinking…"
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.numberOfLines = 1
    }

    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.addAction(UIAction(handler: { _ in self?.dismissPanel() }), for: .touchUpInside)
    }

    private lazy var thoughtsStack: UIStackView = .build { stack in
        stack.axis = .vertical
        stack.spacing = UX.stackSpacing
        stack.alignment = .leading
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
        self.thoughts = AIAgentThoughtsViewController.mockThoughts(for: prompt)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        backgroundGradient.frame = view.bounds
    }

    private func setupViews() {
        // Thoughts live underneath the snapshot; revealed as the snapshot slides down.
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(thoughtsStack)
        view.addSubview(snapshotContainer)
        snapshotContainer.addSubview(snapshotImageView)
        snapshotImageView.image = snapshot

        for thought in thoughts {
            let label: UILabel = .build { label in
                label.text = thought
                label.font = FXFontStyles.Regular.body.scaledFont()
                label.numberOfLines = 0
            }
            thoughtsStack.addArrangedSubview(label)
        }

        snapshotImageView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = snapshotContainer.topAnchor.constraint(equalTo: view.topAnchor,
                                                                   constant: snapshotTopOffset)
        snapshotTopConstraint = topConstraint

        NSLayoutConstraint.activate([
            // Thoughts header in the top area that the snapshot reveals.
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                            constant: UX.topPadding),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                constant: UX.horizontalPadding),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                  constant: -UX.horizontalPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            thoughtsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                               constant: UX.stackSpacing),
            thoughtsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                   constant: UX.horizontalPadding),
            thoughtsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -UX.horizontalPadding),

            // Snapshot fills the screen (covers the page) and slides down on appear.
            snapshotContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            snapshotContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            snapshotContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            topConstraint,

            snapshotImageView.leadingAnchor.constraint(equalTo: snapshotContainer.leadingAnchor),
            snapshotImageView.trailingAnchor.constraint(equalTo: snapshotContainer.trailingAnchor),
            snapshotImageView.topAnchor.constraint(equalTo: snapshotContainer.topAnchor),
            snapshotImageView.bottomAnchor.constraint(equalTo: snapshotContainer.bottomAnchor)
        ])

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        snapshotContainer.addGestureRecognizer(pan)
    }

    /// Slides the page snapshot down to reveal the thoughts above it.
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

    func dismissPanel() {
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
            // Allow dragging the snapshot back up toward dismissal.
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
        backgroundGradient.colors = theme.colors.layerGradientSummary.cgColors
        // Light text on the red gradient, matching the summarize panel.
        let onGradient = theme.colors.textOnDark
        titleLabel.textColor = onGradient
        closeButton.tintColor = onGradient
        thoughtsStack.arrangedSubviews
            .compactMap { $0 as? UILabel }
            .forEach { $0.textColor = onGradient.withAlphaComponent(0.9) }
    }

    private static func mockThoughts(for prompt: String) -> [String] {
        return [
            "Reading the page…",
            "Indexed interactive elements (search box, links, buttons)",
            "Planning: type \"\(prompt)\" → submit → read results",
            "Locating the best match for \"\(prompt)\"…"
        ]
    }
}
