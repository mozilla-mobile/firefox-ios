// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common

protocol NTPSeedCounterDelegate: NSObjectProtocol {
    func didTapSeedCounter()
}

final class NTPSeedCounterCell: UICollectionViewCell, ThemeApplicable, ReusableCell {

    // MARK: - UX Constants
    private enum UX {
        static let cornerRadius: CGFloat = 24
        static let containerWidthHeight: CGFloat = 48
        static let insetMargin: CGFloat = 16
        static let twinkleSizeOffset: CGFloat = 16
        static let newSeedCircleSize: CGFloat = 20
        static let newSeedCircleAnimationDuration = 2.5
    }

    // MARK: - Properties
    private var hostingController: UIHostingController<SeedCounterView>?
    private var containerStackView = UIStackView()
    weak var delegate: NTPSeedCounterDelegate?
    private var sparklesAnimationDuration: Double {
        SeedCounterNTPExperiment.sparklesAnimationDuration
    }
    private var isTwinkleActive: Bool = false
    @State private var showNewSeedCollectedCircleView = false

    // Transparent button and TwinkleView
    private var button = UIButton()
    private var twinkleHostingController: UIHostingController<TwinkleView>?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        listenForLevelUpNotification()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UserDefaultsSeedProgressManager.levelUpNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UserDefaultsSeedProgressManager.progressUpdatedNotification, object: nil)
    }

    // MARK: - Setup

    private func setup() {
        contentView.addSubview(containerStackView)
        setupContainerStackView()
        setupSeedCounterViewHostingController()
        setupTwinkleViewHostingController()
        setupTransparentButton()
    }

    private func setupTransparentButton() {
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(openClimateImpactCounter), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            button.topAnchor.constraint(equalTo: containerStackView.topAnchor),
            button.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor)
        ])
    }

    private func setupTwinkleViewHostingController() {
        let twinkleView = TwinkleView(active: isTwinkleActive)
        twinkleHostingController = UIHostingController(rootView: twinkleView)

        guard let twinkleHostingController else { return }

        twinkleHostingController.view.backgroundColor = .clear
        twinkleHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        twinkleHostingController.view.isUserInteractionEnabled = false
        twinkleHostingController.view.clipsToBounds = true
        contentView.addSubview(twinkleHostingController.view)

        NSLayoutConstraint.activate([
            twinkleHostingController.view.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor, constant: -UX.twinkleSizeOffset),
            twinkleHostingController.view.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: UX.twinkleSizeOffset),
            twinkleHostingController.view.topAnchor.constraint(equalTo: containerStackView.topAnchor, constant: -UX.twinkleSizeOffset),
            twinkleHostingController.view.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor, constant: UX.twinkleSizeOffset)
        ])
    }

    private func setupSeedCounterViewHostingController() {
        let swiftUIView = SeedCounterView(progressManagerType: SeedCounterNTPExperiment.progressManagerType.self,
                                          windowUUID: currentWindowUUID)
        hostingController = UIHostingController(rootView: swiftUIView)

        guard let hostingController else { return }

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        containerStackView.addArrangedSubview(hostingController.view)
    }

    private func setupContainerStackView() {
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.layer.masksToBounds = true
        containerStackView.layer.cornerRadius = UX.cornerRadius
        NSLayoutConstraint.activate([
            containerStackView.heightAnchor.constraint(equalToConstant: UX.containerWidthHeight),
            containerStackView.widthAnchor.constraint(equalToConstant: UX.containerWidthHeight),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.insetMargin)
        ])
    }

    // MARK: - New Seed Collected Circle

    private func addNewSeedCollectedCircleView() {
        let duration = UX.newSeedCircleAnimationDuration
        let newSeedView = NewSeedCollectedCircleView(windowUUID: currentWindowUUID, seedsCollected: 1)
            .frame(width: UX.newSeedCircleSize, height: UX.newSeedCircleSize)
            .modifier(AppearFromBottomEffectModifier(reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
                                                     duration: duration,
                                                     parentViewHeight: UX.containerWidthHeight))

        let newSeedHostingController = UIHostingController(rootView: newSeedView)
        newSeedHostingController.view.backgroundColor = .clear
        newSeedHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(newSeedHostingController.view)

        // Position the NewSeedCollectedCircleView at the top-right corner of the SeedCounterView
        NSLayoutConstraint.activate([
            newSeedHostingController.view.widthAnchor.constraint(equalToConstant: UX.newSeedCircleSize),
            newSeedHostingController.view.heightAnchor.constraint(equalToConstant: UX.newSeedCircleSize),
            newSeedHostingController.view.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            newSeedHostingController.view.topAnchor.constraint(equalTo: containerStackView.topAnchor)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            newSeedHostingController.view.removeFromSuperview()
        }
    }

    // MARK: - Seed Collection Circle helpers

    func showSeedCollectionCircleViewAndAnimateIfNeeded() {
        executeOnMainThreadWithDelayForNonReleaseBuild { [weak self] in
            self?.addNewSeedCollectedCircleView()
        }
    }

    // MARK: - Twinkle helpers

    func triggerTwinkleEffect() {
        if UIAccessibility.isReduceMotionEnabled {
            return  // Skip the animation if Reduce Motion is enabled
        }

        isTwinkleActive = true
        updateTwinkleView()

        DispatchQueue.main.asyncAfter(deadline: .now() + sparklesAnimationDuration) {
            self.isTwinkleActive = false
            self.updateTwinkleView()
        }
    }

    private func updateTwinkleView() {
        twinkleHostingController?.rootView = TwinkleView(active: isTwinkleActive)
    }

    // MARK: - Observer

    private func listenForLevelUpNotification() {
        NotificationCenter.default.addObserver(forName: UserDefaultsSeedProgressManager.progressUpdatedNotification, object: nil, queue: .main) { [weak self] _ in
            self?.showSeedCollectionCircleViewAndAnimateIfNeeded()
        }

        NotificationCenter.default.addObserver(forName: UserDefaultsSeedProgressManager.levelUpNotification, object: nil, queue: .main) { [weak self] _ in
            self?.triggerTwinkleEffect()
        }
    }

    // MARK: - Action

    @objc private func openClimateImpactCounter() {
        delegate?.didTapSeedCounter()
    }

    // MARK: - Theming
    func applyTheme(theme: Theme) {
        containerStackView.backgroundColor = theme.colors.ecosia.backgroundSecondary
    }
}
