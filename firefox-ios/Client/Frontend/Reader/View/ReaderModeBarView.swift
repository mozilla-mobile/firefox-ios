// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

enum ReaderModeBarButtonType {
    case markAsRead
    case markAsUnread
    case settings
    case addToReadingList
    case removeFromReadingList
    case summarizer

    private var localizedDescription: String {
        switch self {
        case .markAsRead: return .ReaderModeBarMarkAsRead
        case .markAsUnread: return .ReaderModeBarMarkAsUnread
        case .settings: return .ReaderModeBarSettings
        case .addToReadingList: return .ReaderModeBarAddToReadingList
        case .removeFromReadingList: return .ReaderModeBarRemoveFromReadingList
        case .summarizer: return .ReaderModeBar.SummarizeButtonAccessibilityLabel
        }
    }

    private var imageName: String {
        switch self {
        case .markAsRead: return StandardImageIdentifiers.Large.notificationDotFill
        case .markAsUnread: return StandardImageIdentifiers.Large.notificationDot
        case .settings: return "SettingsSerif"
        case .addToReadingList: return StandardImageIdentifiers.Large.readingListAdd
        case .removeFromReadingList: return StandardImageIdentifiers.Large.delete
        case .summarizer: return StandardImageIdentifiers.Large.lightning
        }
    }

    @MainActor
    var image: UIImage? {
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        image?.accessibilityLabel = localizedDescription
        return image
    }
}

protocol ReaderModeBarViewDelegate: AnyObject {
    @MainActor
    func readerModeBar(_ readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType)
}

class ReaderModeBarView: UIView, AlphaDimmable, TopBottomInterchangeable, SearchBarLocationProvider, ThemeApplicable {
    weak var delegate: ReaderModeBarViewDelegate?

    var parent: UIStackView?

    var contextStrokeColor: UIColor?

    private lazy var readStatusButton: UIButton = {
        let button = createButton(.markAsRead, action: #selector(tappedReadStatusButton))
        button.accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.BarView.readStatusButton
        return button
    }()
    private lazy var settingsButton: UIButton = {
        let button = createButton(.settings, action: #selector(tappedSettingsButton))
        button.accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.BarView.settingsButton
        return button
    }()
    private lazy var listStatusButton: UIButton = {
        let button = createButton(.addToReadingList, action: #selector(tappedListStatusButton))
        button.accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.BarView.listStatusButton
        return button
    }()
    private lazy var summarizerButton: UIButton = {
        let button = createButton(.summarizer, action: #selector(tappedSummarizerButton))
        button.accessibilityIdentifier = AccessibilityIdentifiers.ReaderMode.BarView.summarizerButton
        return button
    }()
    private let buttonStackView: UIStackView = .build {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
    }

    lazy var toolbarHelper: ToolbarHelperInterface = ToolbarHelper()

    private var toolbarLayoutType: ToolbarLayoutType? {
        return FxNimbus.shared.features.toolbarRefactorFeature.value().layout
    }
    private let summarizerNimbusUtils: SummarizerNimbusUtils

    init(
        frame: CGRect,
        summarizerNimbusUtils: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils()
    ) {
        self.summarizerNimbusUtils = summarizerNimbusUtils
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext(),
              let contextStrokeColor = contextStrokeColor else { return }

        context.setLineWidth(0.5)
        context.setStrokeColor(contextStrokeColor.cgColor)
        context.beginPath()
        let yPosition = isBottomSearchBar ? 0 : frame.height
        context.move(to: CGPoint(x: 0, y: yPosition))
        context.addLine(to: CGPoint(x: frame.width, y: yPosition))
        context.strokePath()
    }

    private func setupSubviews() {
        buttonStackView.addArrangedSubview(readStatusButton)
        buttonStackView.addArrangedSubview(settingsButton)
        buttonStackView.addArrangedSubview(listStatusButton)
        addSubview(buttonStackView)
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func createButton(_ type: ReaderModeBarButtonType, action: Selector) -> UIButton {
        let button: UIButton = .build { button in
            button.setImage(type.image, for: .normal)
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        return button
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        self.alpha = alpha
    }

    @objc
    private func tappedReadStatusButton(_ sender: UIButton?) {
        delegate?.readerModeBar(self, didSelectButton: unread ? .markAsRead : .markAsUnread)
    }

    @objc
    private func tappedSettingsButton(_ sender: UIButton?) {
        delegate?.readerModeBar(self, didSelectButton: .settings)
    }

    @objc
    private func tappedListStatusButton(_ sender: UIButton?) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: added ? .delete : .add,
            object: .readingListItem,
            value: .readerModeToolbar
        )
        delegate?.readerModeBar(self, didSelectButton: added ? .removeFromReadingList : .addToReadingList)
    }

    @objc
    private func tappedSummarizerButton() {
        delegate?.readerModeBar(self, didSelectButton: .summarizer)
    }

    /// Updates the reader mode bar content by dynamically adding or removing the summarize button.
    func updateContent(shouldShowSummarizerButton: Bool) {
        guard shouldShowSummarizerButton else {
            summarizerButton.removeFromSuperview()
            return
        }
        // Add the button only if it is not already in the view hierarchy
        guard summarizerButton.superview == nil else { return }
        buttonStackView.addArrangedSubview(summarizerButton)
    }

    var unread = true {
        didSet {
            let buttonType: ReaderModeBarButtonType = unread && added ? .markAsRead : .markAsUnread
            readStatusButton.setImage(buttonType.image, for: .normal)
            readStatusButton.isEnabled = added
            readStatusButton.alpha = added ? 1.0 : 0.6
        }
    }

    var added = false {
        didSet {
            let buttonType: ReaderModeBarButtonType = added ? .removeFromReadingList : .addToReadingList
            listStatusButton.setImage(buttonType.image, for: .normal)
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let colors = theme.colors

        let backgroundAlpha = toolbarHelper.glassEffectAlpha

        backgroundColor = colors.layerSurfaceLow.withAlphaComponent(backgroundAlpha)
        readStatusButton.tintColor = colors.textPrimary
        settingsButton.tintColor = colors.textPrimary
        listStatusButton.tintColor = colors.textPrimary
        summarizerButton.tintColor = colors.textPrimary
        contextStrokeColor = colors.textSecondary
    }
}
