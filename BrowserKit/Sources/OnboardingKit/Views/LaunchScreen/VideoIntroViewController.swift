// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Common
import UIKit

/// Full-screen video playback screen shown before the Terms of Service during onboarding.
/// The video loops silently. Tapping the continue button calls `didFinishFlow`.
public final class VideoIntroViewController: UIViewController, ThemeApplicable {
    // MARK: - UX
    private struct UX {
        static let buttonHorizontalPadding: CGFloat = 24
        static let buttonBottomPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 13
        static let buttonFontSize: CGFloat = 17
    }

    // MARK: - Properties
    // Pre-initialized in init() so buffering starts before the VC is presented.
    private let player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var readyForDisplayObservation: NSKeyValueObservation?

    // Solid overlay shown until the first video frame is ready, preventing a flash of the background.
    private let loadingOverlay: UIView = .build()

    private lazy var continueButton: UIButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .body,
            size: UX.buttonFontSize
        )
        button.setTitle("Title", for: .normal)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.addAction(
            UIAction(
                handler: {
                    [weak self] _ in self?.dismiss(
                        animated: true
                    )
                }),
            for: .touchUpInside
        )
    }

    // MARK: - Init

    public init() {
        guard let url = Bundle.module.url(forResource: "IntroVideo", withExtension: "mp4") else {
            player = nil
            super.init(nibName: nil, bundle: nil)
            return
        }
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        // Start buffering immediately — by the time the VC is presented the first frame is likely ready.
        player.play()
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerLayer()
        setupLayout()
        observeReadyForDisplay()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    // MARK: - Setup

    private func setupPlayerLayer() {
        guard let player else { return }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(layer, at: 0)
        playerLayer = layer
    }

    private func setupLayout() {
        view.addSubview(loadingOverlay)
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            continueButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: UX.buttonHorizontalPadding
            ),
            continueButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -UX.buttonHorizontalPadding
            ),
            continueButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -UX.buttonBottomPadding
            ),
            continueButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight)
        ])
    }

    /// Observes `AVPlayerLayer.isReadyForDisplay` and fades out the overlay once the first frame is decoded.
    private func observeReadyForDisplay() {
        guard let playerLayer else { return }

        readyForDisplayObservation = playerLayer.observe(
            \.isReadyForDisplay,
            options: [.new]
        ) { [weak self] layer, _ in
            guard layer.isReadyForDisplay else { return }
            self?.readyForDisplayObservation = nil
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2) {
                    self?.loadingOverlay.alpha = 0
                } completion: { _ in
                    self?.loadingOverlay.removeFromSuperview()
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func playerItemDidReachEnd() {
        player?.seek(to: .zero)
        player?.play()
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: any Theme) {
        view.backgroundColor = theme.colors.layer1
        loadingOverlay.backgroundColor = theme.colors.layer1
        continueButton.backgroundColor = theme.colors.actionPrimary
        continueButton.setTitleColor(theme.colors.textInverted, for: .normal)
    }
}
