// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct EcosiaErrorToastMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let subtitle: String
    public let title: String?

    public init(id: UUID = UUID(), title: String? = nil, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }

    public var accessibilityAnnouncement: String {
        if let title, !title.isEmpty {
            return "\(title). \(subtitle)"
        }
        return subtitle
    }
}

/// Shared timing used by the toast stack and its UIKit host (e.g. VoiceOver delay).
public enum EcosiaErrorToastTiming {
    public static let entranceDuration: TimeInterval = 0.45
}

@MainActor
public final class EcosiaErrorToastStackModel: ObservableObject {
    @Published public var messages: [EcosiaErrorToastMessage] = []
    @Published fileprivate(set) var dismissingID: UUID?

    private enum UX {
        static let fadeDuration: TimeInterval = 0.28
        static let promoteDuration: TimeInterval = 0.35
    }

    public var onDismissCompleted: (() -> Void)?

    public init() {}

    public func append(subtitles: [String]) {
        append(messages: subtitles.map { EcosiaErrorToastMessage(subtitle: $0) })
    }

    public func append(messages newMessages: [EcosiaErrorToastMessage]) {
        guard !newMessages.isEmpty else { return }
        messages.append(contentsOf: newMessages)
    }

    public func requestDismiss(id: UUID) {
        guard dismissingID == nil,
              messages.contains(where: { $0.id == id }) else { return }

        withAnimation(.easeOut(duration: UX.fadeDuration)) {
            dismissingID = id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.fadeDuration) { [weak self] in
            guard let self else { return }
            withAnimation(.easeOut(duration: UX.promoteDuration)) {
                self.messages.removeAll { $0.id == id }
                self.dismissingID = nil
            }
            self.onDismissCompleted?()
        }
    }

    public func clear() {
        dismissingID = nil
        messages.removeAll()
    }
}

/// Wallet-style top toast stack (Figma 19211:4961).
/// Collapsed: overlapping peeks. Expanded: even vertical list. Tap to toggle.
@available(iOS 16.0, *)
public struct EcosiaErrorToastStack: View {
    @ObservedObject private var model: EcosiaErrorToastStackModel
    private let windowUUID: WindowUUID
    private let onDismiss: (EcosiaErrorToastMessage) -> Void
    private let onExpandChange: (Bool) -> Void

    @State private var isVisible = false
    @State private var isExpanded = false
    @State private var frontCardHeight = UX.minCardHeight
    @State private var measuredExpandedHeight: CGFloat?
    @State private var dismissalLayoutHeight: CGFloat?

    private enum UX {
        static let minCardHeight: CGFloat = 56
        static let stackPeek: CGFloat = .ecosia.space._1s
        static let listSpacing: CGFloat = .ecosia.space._1s
        static let fadeDuration: TimeInterval = 0.28
        static let entranceDuration = EcosiaErrorToastTiming.entranceDuration
        static let expandDuration: TimeInterval = 0.42
        static let promoteDuration: TimeInterval = 0.35
        static let maxVisibleDepth = 4
        static let depth1Scale: CGFloat = 327.0 / 343.0
        static let depth2Scale: CGFloat = 311.0 / 343.0
    }

    public init(
        model: EcosiaErrorToastStackModel,
        windowUUID: WindowUUID,
        onDismiss: @escaping (EcosiaErrorToastMessage) -> Void = { _ in },
        onExpandChange: @escaping (Bool) -> Void = { _ in }
    ) {
        self.model = model
        self.windowUUID = windowUUID
        self.onDismiss = onDismiss
        self.onExpandChange = onExpandChange
    }

    // MARK: - Body

    public var body: some View {
        if !model.messages.isEmpty {
            ZStack(alignment: .top) {
                // Hidden sizing pass keeps GeometryReader off the visible list
                // (per-row readers inflate the first expanded gap).
                sizingPass

                ZStack(alignment: .top) {
                    // Both layouts stay mounted so the expand/collapse transition can
                    // cross-fade, but only the visible one belongs in the accessibility
                    // tree — otherwise VoiceOver (and UI automation) sees every card twice.
                    collapsedStack
                        .opacity(isExpanded ? 0 : 1)
                        .allowsHitTesting(!isExpanded)
                        .accessibilityHidden(isExpanded)
                        .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.ErrorToast.collapsedStack)

                    expandedStack
                        .opacity(isExpanded ? 1 : 0)
                        .allowsHitTesting(isExpanded)
                        .accessibilityHidden(!isExpanded)
                        .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.ErrorToast.expandedStack)
                }
                .frame(height: containerHeight, alignment: .top)
                .animation(expandAnimation, value: isExpanded)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .onTapGesture(perform: toggleExpanded)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.ErrorToast.container)
            .offset(y: isVisible ? 0 : -(frontCardHeight + .ecosia.space._1l))
            .opacity(isVisible ? 1 : 0)
            .animation(entranceAnimation, value: isVisible)
            .onPreferenceChange(ToastLayoutMetricsKey.self, perform: applyLayoutMetrics)
            .onAppear {
                withAnimation(entranceAnimation) { isVisible = true }
            }
            .onChange(of: model.dismissingID, perform: handleDismissingIDChange)
            .onChange(of: model.messages.count, perform: handleMessageCountChange)
        }
    }

    // MARK: - Stacks

    private var collapsedStack: some View {
        ZStack(alignment: .top) {
            ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
                let depthFromFront = visibleMessages.count - 1 - index
                let isFront = depthFromFront == 0
                let isDismissing = message.id == model.dismissingID

                walletCard(
                    for: message,
                    depthFromFront: depthFromFront,
                    isFront: isFront,
                    isDismissing: isDismissing
                )
                .offset(y: CGFloat(index) * UX.stackPeek)
                .dismissChrome(isDismissing: isDismissing, duration: UX.fadeDuration)
                .allowsHitTesting(isFront && !isDismissing)
                .zIndex(Double(index))
            }
        }
        .animation(promoteAnimation, value: layoutAnimationKey)
    }

    private var expandedStack: some View {
        VStack(spacing: UX.listSpacing) {
            ForEach(visibleMessages) { message in
                let isDismissing = message.id == model.dismissingID
                // Natural height only — minHeight leaves empty space below short cards
                // and makes the first gap look larger than the rest.
                errorCard(for: message, showsCloseButton: !isDismissing)
                    .dismissChrome(isDismissing: isDismissing, duration: UX.fadeDuration)
                    .allowsHitTesting(!isDismissing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// Sibling pass that reports natural front-card and expanded-stack heights.
    /// GeometryReaders stay here (not on the visible VStack) so they cannot inflate row spacing.
    private var sizingPass: some View {
        VStack(spacing: UX.listSpacing) {
            ForEach(Array(visibleMessages.enumerated()), id: \.element.id) { index, message in
                let isFront = index == visibleMessages.count - 1
                errorCard(for: message, showsCloseButton: true)
                    .overlay {
                        if isFront {
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ToastLayoutMetricsKey.self,
                                    value: ToastLayoutMetrics(frontCardHeight: geometry.size.height)
                                )
                            }
                        }
                    }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .top)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ToastLayoutMetricsKey.self,
                    value: ToastLayoutMetrics(expandedHeight: geometry.size.height)
                )
            }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Cards

    @ViewBuilder
    private func walletCard(
        for message: EcosiaErrorToastMessage,
        depthFromFront: Int,
        isFront: Bool,
        isDismissing: Bool
    ) -> some View {
        let card = errorCard(
            for: message,
            showsCloseButton: isFront && !isDismissing,
            fillsMinHeight: true,
            showsShadow: isFront
        )

        if isFront {
            card.scaleEffect(1, anchor: .top)
        } else {
            card
                .scaleEffect(scaleForDepth(depthFromFront), anchor: .top)
                .frame(height: UX.stackPeek, alignment: .top)
                .clipped()
        }
    }

    @ViewBuilder
    private func errorCard(
        for message: EcosiaErrorToastMessage,
        showsCloseButton: Bool,
        fillsMinHeight: Bool = false,
        showsShadow: Bool = false
    ) -> some View {
        let content = EcosiaErrorView(
            title: message.title,
            subtitle: message.subtitle,
            windowUUID: windowUUID,
            showsCloseButton: true,
            onCloseTapped: showsCloseButton ? { dismiss(message) } : nil
        )
        .padding(.horizontal, .ecosia.space._m)

        Group {
            if fillsMinHeight {
                content
                    .frame(minHeight: UX.minCardHeight, alignment: .top)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                content
            }
        }
        // Repeats once per message. The hidden sizing pass renders these too, but it is
        // `.accessibilityHidden(true)`, so its copies never reach the query tree.
        .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.ErrorToast.card)
        .shadow(
            color: showsShadow ? Color.black.opacity(0.12) : .clear,
            radius: showsShadow ? 8 : 0,
            x: 0,
            y: showsShadow ? 4 : 0
        )
    }

    // MARK: - Layout

    private var visibleMessages: [EcosiaErrorToastMessage] {
        Array(model.messages.suffix(UX.maxVisibleDepth))
    }

    private var containerHeight: CGFloat {
        dismissalLayoutHeight ?? (isExpanded ? expandedHeight : collapsedHeight)
    }

    private var collapsedHeight: CGFloat {
        frontCardHeight + CGFloat(max(0, visibleMessages.count - 1)) * UX.stackPeek
    }

    private var expandedHeight: CGFloat {
        if let measuredExpandedHeight, measuredExpandedHeight > 0 {
            return measuredExpandedHeight
        }
        let cards = CGFloat(visibleMessages.count) * UX.minCardHeight
        let spacing = UX.listSpacing * CGFloat(max(0, visibleMessages.count - 1))
        return cards + spacing
    }

    private var layoutAnimationKey: String {
        let ids = visibleMessages.map(\.id.uuidString).joined(separator: "-")
        return "\(ids)-\(model.dismissingID?.uuidString ?? "none")"
    }

    private func scaleForDepth(_ depth: Int) -> CGFloat {
        switch depth {
        case 0: return 1
        case 1: return UX.depth1Scale
        default: return UX.depth2Scale
        }
    }

    private func applyLayoutMetrics(_ metrics: ToastLayoutMetrics) {
        updateWithoutAnimation {
            if let height = metrics.frontCardHeight, abs(frontCardHeight - height) > 0.5 {
                frontCardHeight = max(height, UX.minCardHeight)
            }
            if let height = metrics.expandedHeight, abs((measuredExpandedHeight ?? 0) - height) > 0.5 {
                measuredExpandedHeight = height
            }
        }
    }

    // MARK: - Actions

    private func toggleExpanded() {
        guard visibleMessages.count > 1 else { return }
        let willExpand = !isExpanded
        withAnimation(expandAnimation) { isExpanded = willExpand }
        onExpandChange(willExpand)
    }

    private func dismiss(_ message: EcosiaErrorToastMessage) {
        guard model.dismissingID == nil else { return }
        onDismiss(message)
        model.requestDismiss(id: message.id)
    }

    private func handleDismissingIDChange(_ dismissingID: UUID?) {
        if dismissingID != nil {
            dismissalLayoutHeight = containerHeight
        } else if dismissalLayoutHeight != nil {
            withAnimation(promoteAnimation) { dismissalLayoutHeight = nil }
        }
    }

    private func handleMessageCountChange(_ count: Int) {
        if count == 0 { dismissalLayoutHeight = nil }
        if count == 1, isExpanded {
            withAnimation(expandAnimation) { isExpanded = false }
            onExpandChange(false)
        }
    }

    private func updateWithoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, updates)
    }

    // MARK: - Animations

    private var entranceAnimation: Animation {
        .timingCurve(0.16, 1, 0.3, 1, duration: UX.entranceDuration)
    }

    private var expandAnimation: Animation {
        .spring(response: UX.expandDuration, dampingFraction: 0.92)
    }

    private var promoteAnimation: Animation {
        .easeOut(duration: UX.promoteDuration)
    }
}

// MARK: - Layout metrics

@available(iOS 16.0, *)
private struct ToastLayoutMetrics: Equatable {
    var frontCardHeight: CGFloat?
    var expandedHeight: CGFloat?

    init(frontCardHeight: CGFloat? = nil, expandedHeight: CGFloat? = nil) {
        self.frontCardHeight = frontCardHeight
        self.expandedHeight = expandedHeight
    }
}

@available(iOS 16.0, *)
private struct ToastLayoutMetricsKey: PreferenceKey {
    static let defaultValue = ToastLayoutMetrics()

    static func reduce(value: inout ToastLayoutMetrics, nextValue: () -> ToastLayoutMetrics) {
        let next = nextValue()
        if let height = next.frontCardHeight { value.frontCardHeight = height }
        if let height = next.expandedHeight { value.expandedHeight = height }
    }
}

@available(iOS 16.0, *)
private extension View {
    func dismissChrome(isDismissing: Bool, duration: TimeInterval) -> some View {
        self
            .opacity(isDismissing ? 0 : 1)
            .animation(.easeOut(duration: duration), value: isDismissing)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorToastStack_Previews: PreviewProvider {
    struct PreviewHost: View {
        @StateObject private var model = EcosiaErrorToastStackModel()

        var body: some View {
            EcosiaErrorToastStack(
                model: model,
                windowUUID: .XCTestDefaultUUID
            )
            .padding()
            .onAppear {
                model.append(subtitles: [
                    "You can upload up to 5 files per chat.",
                    "The file is too large, the maximum file size is 5MB.",
                    "The file type is not supported. Please upload a JPG, PNG, PDF or text file."
                ])
            }
        }
    }

    static var previews: some View {
        PreviewHost()
            .previewLayout(.sizeThatFits)
    }
}
#endif
