// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit

@MainActor
final class TabGroupsTrayNativeToolbar: NSObject {
    final class GlassButtonContainer: UIView {
        let button = UIButton()

        init() {
            let size = TabGroupsTrayBarMetrics.glassButtonSize
            super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
            button.frame = bounds
            button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(button)
            translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: size),
                heightAnchor.constraint(equalToConstant: size)
            ])
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    @available(iOS 26.0, *)
    final class GlassRow: UIStackView {
        let panel: TabGroupsTrayGlassPanel
        private lazy var widthConstraint = widthAnchor.constraint(equalToConstant: 0)
        var preferredWidth: CGFloat? {
            didSet {
                guard preferredWidth != oldValue else { return }
                if let preferredWidth {
                    widthConstraint.constant = preferredWidth
                    widthConstraint.isActive = true
                } else {
                    widthConstraint.isActive = false
                }
                invalidateIntrinsicContentSize()
                sizeToFit()
            }
        }

        init(panel: TabGroupsTrayGlassPanel) {
            self.panel = panel
            super.init(frame: .zero)
            spacing = TabGroupsTrayBarMetrics.bottomBarSpacing
            alignment = .center
            translatesAutoresizingMaskIntoConstraints = false
            heightAnchor.constraint(equalToConstant: TabGroupsTrayBarMetrics.glassButtonSize).isActive = true
        }

        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            let width = panel.intrinsicContentSize.width
                + 2 * (TabGroupsTrayBarMetrics.glassButtonSize + spacing)
            return CGSize(width: preferredWidth ?? width, height: TabGroupsTrayBarMetrics.glassButtonSize)
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize { intrinsicContentSize }

        func update(add: UIView, done: UIView) {
            let views = [add, panel, done]
            guard arrangedSubviews != views else { return }
            arrangedSubviews.forEach { $0.removeFromSuperview() }
            views.forEach { addArrangedSubview($0) }
        }
    }

    final class PanelSelector: UISegmentedControl {
        var preferredWidth: CGFloat? {
            didSet {
                guard preferredWidth != oldValue else { return }
                invalidateIntrinsicContentSize()
                sizeToFit()
            }
        }

        override var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            size.width = preferredWidth ?? size.width
            return size
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            var size = super.sizeThatFits(size)
            size.width = preferredWidth ?? size.width
            return size
        }
    }

    let panelSelector = PanelSelector(items: ["", "", ""])
    private(set) var items: [UIBarButtonItem] = []
    private let onAction: (TabGroupsTrayBarAction) -> Void
    private var buttonSize = TabGroupsTrayBarMetrics.buttonSize

    private lazy var addButton = UIBarButtonItem(image: UIImage(named: "plusLarge"),
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(addTab))
    private lazy var doneButton = UIBarButtonItem(image: UIImage(named: "checkmarkLarge"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(done))
    private lazy var panelItem = UIBarButtonItem(customView: panelSelector)
    private var glassPanelItem: UIBarButtonItem?
    private var glassRowItem: UIBarButtonItem?
    private let leadingSpace = UIBarButtonItem(systemItem: .flexibleSpace)
    private let trailingSpace = UIBarButtonItem(systemItem: .flexibleSpace)

    func makeHostedItems() -> [UIBarButtonItem] {
        guard #available(iOS 26.0, *),
              let glassPanelItem, items.contains(glassPanelItem),
              let panel = glassPanelItem.customView as? TabGroupsTrayGlassPanel,
              let add = addButton.customView, let done = doneButton.customView else { return items }
        let row: GlassRow
        let item: UIBarButtonItem
        if let existingItem = glassRowItem, let existingRow = existingItem.customView as? GlassRow {
            row = existingRow
            item = existingItem
        } else {
            row = GlassRow(panel: panel)
            item = UIBarButtonItem(customView: row)
            item.hidesSharedBackground = true
            glassRowItem = item
        }
        row.update(add: add, done: done)
        row.preferredWidth = panel.preferredWidth.map {
            $0 + 2 * (TabGroupsTrayBarMetrics.glassButtonSize + TabGroupsTrayBarMetrics.bottomBarSpacing)
        }
        return [leadingSpace, item, trailingSpace]
    }

    init(onAction: @escaping (TabGroupsTrayBarAction) -> Void) {
        self.onAction = onAction
        super.init()
        panelSelector.apportionsSegmentWidthsByContent = true
        panelSelector.accessibilityIdentifier = "tabGroupsTray.panelSelector"
        panelSelector.addTarget(self, action: #selector(selectPanel), for: .valueChanged)
        if #available(iOS 26.0, *) {
            panelItem.hidesSharedBackground = true
        }
        addButton.accessibilityIdentifier = "tabGroupsTray.addTab"
        doneButton.accessibilityIdentifier = "tabGroupsTray.done"
    }

    func update(viewModel: TabGroupsTrayBarViewModel, usesGlassButtons: Bool) {
        configurePanels(viewModel: viewModel)
        configureButtons(viewModel: viewModel, usesGlassButtons: usesGlassButtons)

        items = standardItems(viewModel: viewModel, usesGlassButtons: usesGlassButtons)
    }

    private func standardItems(viewModel: TabGroupsTrayBarViewModel, usesGlassButtons: Bool) -> [UIBarButtonItem] {
        let panel: UIBarButtonItem
        if #available(iOS 26.0, *), usesGlassButtons {
            panel = glassItem(viewModel: viewModel)
        } else {
            panel = panelItem
        }
        return [addButton, leadingSpace, panel, trailingSpace, doneButton]
    }

    @available(iOS 26.0, *)
    private func glassItem(viewModel: TabGroupsTrayBarViewModel) -> UIBarButtonItem {
        let panel: TabGroupsTrayGlassPanel
        let item: UIBarButtonItem
        if let existingItem = glassPanelItem, let existingPanel = existingItem.customView as? TabGroupsTrayGlassPanel {
            panel = existingPanel
            item = existingItem
        } else {
            panel = TabGroupsTrayGlassPanel { [weak self] in self?.onAction(.selectPanel($0)) }
            item = UIBarButtonItem(customView: panel)
            item.hidesSharedBackground = true
            glassPanelItem = item
        }
        panel.update(viewModel: viewModel)
        panel.preferredWidth = panelSelector.preferredWidth
        return item
    }

    func updateLayout(availableWidth: CGFloat?) {
        let reservedWidth = 2 * (buttonSize + TabGroupsTrayBarMetrics.bottomBarSpacing)
        let width: CGFloat?
        if let availableWidth, availableWidth > reservedWidth {
            width = availableWidth - reservedWidth
        } else {
            width = nil
        }
        panelSelector.preferredWidth = width
        if #available(iOS 26.0, *), let panel = glassPanelItem?.customView as? TabGroupsTrayGlassPanel {
            panel.preferredWidth = width
            (glassRowItem?.customView as? GlassRow)?.preferredWidth = width == nil ? nil : availableWidth
        }
    }

    private func configurePanels(viewModel: TabGroupsTrayBarViewModel) {
        let titles = [viewModel.privateTitle, viewModel.tabsTitle, viewModel.syncedTitle]
        for (index, title) in titles.enumerated() {
            panelSelector.setTitle(title, forSegmentAt: index)
        }
        panelSelector.selectedSegmentIndex = switch viewModel.selectedPanel {
        case .privateTabs: 0
        case .tabs: 1
        case .syncedTabs: 2
        }
        panelSelector.selectedSegmentTintColor = UIColor(viewModel.colors.selectedPanelBackground)
        let textColor = UIColor(viewModel.colors.primaryText)
        panelSelector.setTitleTextAttributes([.foregroundColor: textColor], for: .normal)
        panelSelector.setTitleTextAttributes([.foregroundColor: textColor], for: .selected)
        panelSelector.sizeToFit()
    }

    private func configureButtons(viewModel: TabGroupsTrayBarViewModel, usesGlassButtons: Bool) {
        buttonSize = TabGroupsTrayBarMetrics.buttonSize
        addButton.accessibilityLabel = viewModel.addTabAccessibilityLabel
        doneButton.accessibilityLabel = viewModel.doneAccessibilityLabel
        addButton.style = .plain
        doneButton.style = .plain
        addButton.tintColor = UIColor(viewModel.colors.primaryText)
        doneButton.tintColor = UIColor(viewModel.colors.plainDoneTint ?? viewModel.activeTint)
        addButton.image = UIImage(named: "plusLarge")?.withRenderingMode(.alwaysTemplate)
        doneButton.image = UIImage(systemName: "checkmark.circle.fill")
        if #available(iOS 26.0, *), usesGlassButtons {
            buttonSize = TabGroupsTrayBarMetrics.glassButtonSize
            doneButton.style = .prominent
            doneButton.tintColor = UIColor(viewModel.activeTint)
            doneButton.image = UIImage(named: "checkmarkLarge")?
                .withTintColor(UIColor(viewModel.colors.onEmphasis), renderingMode: .alwaysOriginal)
            var addConfiguration = UIButton.Configuration.clearGlass()
            addConfiguration.image = addButton.image
            addConfiguration.baseForegroundColor = addButton.tintColor
            configureGlassButton(addButton, configuration: addConfiguration, action: #selector(addTab))
            var doneConfiguration = UIButton.Configuration.prominentClearGlass()
            doneConfiguration.image = doneButton.image
            doneConfiguration.baseBackgroundColor = doneButton.tintColor
            doneConfiguration.baseForegroundColor = UIColor(viewModel.colors.onEmphasis)
            configureGlassButton(doneButton, configuration: doneConfiguration, action: #selector(done))
        } else {
            addButton.customView = nil
            doneButton.customView = nil
            if #available(iOS 26.0, *) {
                addButton.hidesSharedBackground = false
                doneButton.hidesSharedBackground = false
            }
        }
    }

    @available(iOS 26.0, *)
    private func configureGlassButton(_ item: UIBarButtonItem, configuration: UIButton.Configuration, action: Selector) {
        let button: UIButton
        if let container = item.customView as? GlassButtonContainer {
            button = container.button
        } else {
            let container = GlassButtonContainer()
            button = container.button
            button.addTarget(self, action: action, for: .touchUpInside)
            item.customView = container
        }
        button.configuration = configuration
        button.tintColor = item.tintColor
        button.accessibilityIdentifier = item.accessibilityIdentifier
        button.accessibilityLabel = item.accessibilityLabel
        item.hidesSharedBackground = true
    }

    @objc private func addTab() { onAction(.addTab) }
    @objc private func done() { onAction(.done) }

    @objc private func selectPanel() {
        switch panelSelector.selectedSegmentIndex {
        case 0: onAction(.selectPanel(.privateTabs))
        case 1: onAction(.selectPanel(.tabs))
        case 2: onAction(.selectPanel(.syncedTabs))
        default: break
        }
    }
}

@available(iOS 26.0, *)
final class TabGroupsTrayGlassPanel: UIVisualEffectView {
    let buttons: [UIButton]
    let selectionIndicator = UIView()
    private let stack = UIStackView()
    private var selectedIndex = 1
    private var panOffset: CGFloat?
    private lazy var widthConstraint = widthAnchor.constraint(equalToConstant: 0)
    var preferredWidth: CGFloat? {
        didSet {
            guard preferredWidth != oldValue else { return }
            if let preferredWidth {
                widthConstraint.constant = preferredWidth
                widthConstraint.isActive = true
            } else {
                widthConstraint.isActive = false
            }
            invalidateIntrinsicContentSize()
            sizeToFit()
        }
    }

    init(onSelect: @escaping (TabGroupsTrayBarViewModel.Panel) -> Void) {
        buttons = ["privateTabs", "tabs", "syncedTabs"].enumerated().map { index, name in
            let button = UIButton(configuration: .plain())
            button.tag = index
            button.accessibilityIdentifier = "tabGroupsTray.panel.\(name)"
            button.addAction(UIAction { action in
                guard let sender = action.sender as? UIButton else { return }
                switch sender.tag {
                case 0: onSelect(.privateTabs)
                case 1: onSelect(.tabs)
                case 2: onSelect(.syncedTabs)
                default: break
                }
            }, for: .touchUpInside)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            return button
        }
        let glass = UIGlassEffect(style: .clear)
        glass.isInteractive = true
        super.init(effect: glass)
        translatesAutoresizingMaskIntoConstraints = false
        cornerConfiguration = .capsule()
        selectionIndicator.isUserInteractionEnabled = false
        selectionIndicator.cornerConfiguration = .capsule()
        contentView.addSubview(selectionIndicator)
        buttons.forEach { stack.addArrangedSubview($0) }
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        pan.maximumNumberOfTouches = 1
        contentView.addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let direction: UISemanticContentAttribute = effectiveUserInterfaceLayoutDirection == .rightToLeft
            ? .forceRightToLeft : .forceLeftToRight
        if stack.semanticContentAttribute != direction { stack.semanticContentAttribute = direction }
        contentView.layoutIfNeeded()
        guard panOffset == nil else { return }
        let frame = selectionFrame(for: buttons[selectedIndex])
        guard !frame.isEmpty, !frame.isNull else { return }
        selectionIndicator.frame = frame
    }

    override var intrinsicContentSize: CGSize {
        let naturalWidth = buttons.reduce(CGFloat.zero) { $0 + $1.intrinsicContentSize.width } + 8
        return CGSize(width: preferredWidth ?? naturalWidth, height: 48)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    func update(viewModel: TabGroupsTrayBarViewModel) {
        let titles = [viewModel.privateTitle, viewModel.tabsTitle, viewModel.syncedTitle]
        selectedIndex = switch viewModel.selectedPanel {
        case .privateTabs: 0
        case .tabs: 1
        case .syncedTabs: 2
        }
        selectionIndicator.backgroundColor = UIColor(viewModel.colors.selectedPanelBackground)
        for (index, button) in buttons.enumerated() {
            button.isSelected = index == selectedIndex
            button.accessibilityLabel = titles[index]
            var configuration = UIButton.Configuration.plain()
            configuration.title = titles[index]
            let weight: UIFont.Weight = button.isSelected ? .semibold : .medium
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = DefaultDynamicFontHelper.preferredFont(
                    withTextStyle: .subheadline,
                    size: 15,
                    weight: weight)
                return attributes
            }
            configuration.baseForegroundColor = UIColor(viewModel.colors.primaryText)
            configuration.background.backgroundColor = .clear
            configuration.cornerStyle = .capsule
            button.configuration = configuration
        }
        let glass = UIGlassEffect(style: .clear)
        glass.isInteractive = true
        effect = glass
        invalidateIntrinsicContentSize()
        sizeToFit()
        setNeedsLayout()
    }

    func handlePan(state: UIGestureRecognizer.State, location: CGPoint) {
        switch state {
        case .began:
            layoutIfNeeded()
            guard !selectionIndicator.bounds.isEmpty else { return }
            let offset = selectionIndicator.frame.contains(location) ? selectionIndicator.center.x - location.x : 0
            panOffset = offset
            moveSelection(to: location.x + offset)
        case .changed:
            guard let panOffset else { return }
            moveSelection(to: location.x + panOffset)
        case .ended:
            guard let panOffset else { return }
            moveSelection(to: location.x + panOffset)
            let index = buttons.indices.min {
                abs(selectionFrame(for: buttons[$0]).midX - selectionIndicator.center.x)
                    < abs(selectionFrame(for: buttons[$1]).midX - selectionIndicator.center.x)
            } ?? selectedIndex
            self.panOffset = nil
            selectedIndex = index
            setNeedsLayout()
            layoutIfNeeded()
            buttons[index].sendActions(for: .touchUpInside)
        case .cancelled, .failed:
            guard panOffset != nil else { return }
            panOffset = nil
            setNeedsLayout()
            layoutIfNeeded()
        default: break
        }
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        handlePan(state: gesture.state, location: gesture.location(in: contentView))
    }

    private func moveSelection(to centerX: CGFloat) {
        let centers = buttons.map { selectionFrame(for: $0).midX }
        guard let minX = centers.min(), let maxX = centers.max() else { return }
        selectionIndicator.center.x = min(max(centerX, minX), maxX)
    }

    private func selectionFrame(for button: UIButton) -> CGRect {
        button.convert(button.bounds, to: contentView).insetBy(dx: 0, dy: 4)
    }
}
