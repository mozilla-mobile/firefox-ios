// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct SeedCounterView: View {

    // MARK: - Properties

    private let progressManagerType: SeedProgressManagerProtocol.Type
    @State private var seedsCollected: Int = 0
    @State private var level: Int = 1
    @State private var progressValue: CGFloat = 0.0
    @StateObject var theme = ArcTheme()
    let windowUUID: WindowUUID?
    @Environment(\.themeManager) var themeManager
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // MARK: - Init

    init(progressManagerType: SeedProgressManagerProtocol.Type, windowUUID: WindowUUID?) {
        self.progressManagerType = progressManagerType
        self.windowUUID = windowUUID
        _seedsCollected = State(initialValue: progressManagerType.loadTotalSeedsCollected())
        _level = State(initialValue: progressManagerType.loadCurrentLevel())
        _progressValue = State(initialValue: progressManagerType.calculateInnerProgress())
    }

    // MARK: - View

    var body: some View {
        VStack(spacing: 0) {
            SeedProgressView(progressValue: progressValue, theme: theme)

            Text("\(Int(seedsCollected))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .scaledToFill()
                .modifier(TextAnimationModifier(seedsCollected: seedsCollected, reduceMotionEnabled: reduceMotion))
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: progressManagerType.progressUpdatedNotification, object: nil, queue: .main) { _ in
                self.triggerUpdateValues()
            }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: progressManagerType.progressUpdatedNotification, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    // MARK: - Helpers

    func applyTheme(theme: Theme) {
        self.theme.backgroundColor = Color(.legacyTheme.ecosia.primaryBackground)
        self.theme.progressColor = Color(.legacyTheme.ecosia.primaryButtonActive)
    }

    private func triggerUpdateValues() {
        executeOnMainThreadWithDelayForNonReleaseBuild {
            self.updateValues()
        }
    }

    private func updateValues() {
        self.seedsCollected = progressManagerType.loadTotalSeedsCollected()
        self.level = progressManagerType.loadCurrentLevel()
        self.progressValue = progressManagerType.calculateInnerProgress()
    }
}
struct NewSeedCollectedCircleView: View {
    var seedsCollected: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.legacyTheme.ecosia.peach))
            Text("+\(seedsCollected)")
                .font(.caption)
        }
    }
}

struct AppearFromBottomEffectModifier: ViewModifier {
    @State private var isAppeared: Bool = false
    var reduceMotionEnabled: Bool
    var duration: Double
    var parentViewHeight: Double

    func body(content: Content) -> some View {
        content
            .offset(y: isAppeared ? -parentViewHeight/2 : 0)
            .scaleEffect(isAppeared ? 1.0 : 0.5)
            .opacity(isAppeared ? 1.0 : 0.0)
            .onAppear {
                // Animate appearance
                withAnimation(reduceMotionEnabled ? .none : .easeInOut(duration: duration)) {
                    self.isAppeared = true
                }
                // Animate disappearance after duration
                DispatchQueue.main.asyncAfter(deadline: .now() + duration/2) {
                    withAnimation(reduceMotionEnabled ? .none : .easeInOut(duration: duration)) {
                        self.isAppeared = false
                    }
                }
            }
    }
}

struct TextAnimationModifier: ViewModifier {
    var seedsCollected: Int
    var reduceMotionEnabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            if reduceMotionEnabled {
                content
            } else {
                content
                    .contentTransition(.numericText(value: Double(seedsCollected)))
                    .animation(.default, value: seedsCollected)
            }
        } else {
            content
                .animation(!UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 3) : .none, value: seedsCollected)
        }
    }
}
