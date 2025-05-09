// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

protocol TabTraySelectorDelegate: AnyObject {
    func didSelectSection(panelType: TabTrayPanelType)
}

// MARK: - UX Constants
struct TabTraySelectorUX {
    static let horizontalPadding: CGFloat = 40
    static let cornerRadius: CGFloat = 12
    static let verticalInsets: CGFloat = 4
    static let maxFontSize: CGFloat = 30
    static let horizontalInsets: CGFloat = 10
}

class TabTraySelectorView: UIView,
                           ThemeApplicable {
    weak var delegate: TabTraySelectorDelegate?

    private var theme: Theme
    private var selectedIndex: Int
    private var buttons: [UIButton] = []
    private lazy var selectionBackgroundView: UIView = .build { _ in }
    private var hasAppliedInitialTransform = false

    var items: [String] = ["", "", ""] {
        didSet {
            updateLabels()
        }
    }

    init(selectedIndex: Int,
         theme: Theme) {
        self.selectedIndex = selectedIndex
        self.theme = theme
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard !hasAppliedInitialTransform else { return }
        applyInitalSelectionBackgroundFrame()
    }

    /// Width of the `selectionBackground` needs to be larger than the widest button. Due to translations, we need
    /// to search for this widest button between the three available.
    private func applyInitalSelectionBackgroundFrame() {
        guard let widestButton = buttons.max(by: {
            $0.intrinsicContentSize.width < $1.intrinsicContentSize.width
        }) else { return }

        let selectionBackgroundWidth = widestButton.intrinsicContentSize.width + (TabTraySelectorUX.horizontalInsets * 2)
        if let widthConstraint = selectionBackgroundView.constraints.first(where: { $0.firstAttribute == .width }) {
            widthConstraint.constant = selectionBackgroundWidth
        } else {
            selectionBackgroundView.widthAnchor.constraint(equalToConstant: selectionBackgroundWidth).isActive = true
        }

        hasAppliedInitialTransform = true
    }

    func updateSelectionProgress(fromIndex: Int, toIndex: Int, progress: CGFloat) {
        guard buttons.indices.contains(fromIndex),
              buttons.indices.contains(toIndex) else { return }

        let fromX = buttons[fromIndex].center.x
        let toX = buttons[toIndex].center.x
        let interpolatedX = fromX + (toX - fromX) * abs(progress)

        let stackCenterX = buttons[fromIndex].superview!.convert(CGPoint(x: interpolatedX, y: 0), to: self).x
        let targetOffset = stackCenterX - selectionBackgroundView.center.x

        selectionBackgroundView.transform = CGAffineTransform(translationX: targetOffset, y: 0)
    }

    func didFinishSelection(to index: Int) {
        selectedIndex = index
        adjustSelectedButtonFont()
    }

    private func setup() {
        selectionBackgroundView.backgroundColor = theme.colors.actionSecondary
        selectionBackgroundView.layer.cornerRadius = TabTraySelectorUX.cornerRadius
        addSubview(selectionBackgroundView)

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = TabTraySelectorUX.horizontalPadding
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        for (index, title) in items.enumerated() {
            let button = UIButton()
            button.setTitle(title, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(sectionSelected(_:)), for: .touchUpInside)

            button.titleLabel?.font = index == selectedIndex ?
                FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize) :
                FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)

            button.accessibilityIdentifier = "\(AccessibilityIdentifiers.TabTray.selectorCell)\(index)"
            button.accessibilityHint = String(format: .TabsTray.TabTraySelectorAccessibilityHint,
                                              NSNumber(value: index + 1),
                                              NSNumber(value: items.count))
            button.translatesAutoresizingMaskIntoConstraints = false
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectionBackgroundView.heightAnchor.constraint(equalTo: stackView.heightAnchor,
                                                            constant: TabTraySelectorUX.verticalInsets * 2),
            selectionBackgroundView.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),
            selectionBackgroundView.centerXAnchor.constraint(equalTo: buttons[selectedIndex].centerXAnchor)
        ])

        applyTheme(theme: theme)
    }

    private func updateLabels() {
        for (index, title) in items.enumerated() {
            buttons[safe: index]?.setTitle(title, for: .normal)
        }
    }

    @objc
    private func sectionSelected(_ sender: UIButton) {
        let oldValue = selectedIndex
        selectedIndex = sender.tag
        selectNewSection(from: oldValue, to: selectedIndex)
    }

    private func selectNewSection(from fromIndex: Int, to toIndex: Int) {
        guard buttons.indices.contains(fromIndex),
              buttons.indices.contains(toIndex) else { return }

        let fromX = buttons[fromIndex].center.x
        let toX = buttons[toIndex].center.x
        let interpolatedX = fromX + (toX - fromX)
        let stackCenterX = buttons[fromIndex].superview!.convert(CGPoint(x: interpolatedX, y: 0), to: self).x
        let targetOffset = stackCenterX - selectionBackgroundView.center.x

        adjustSelectedButtonFont()

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.selectionBackgroundView.transform = CGAffineTransform(translationX: targetOffset, y: 0)
        }, completion: nil)

        let panelType = TabTrayPanelType.getExperimentConvert(index: selectedIndex)
        delegate?.didSelectSection(panelType: panelType)
    }

    private func adjustSelectedButtonFont() {
        for (index, button) in buttons.enumerated() {
            if index == selectedIndex {
                button.titleLabel?.font = FXFontStyles.Bold.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
            } else {
                button.titleLabel?.font = FXFontStyles.Regular.body.scaledFont(sizeCap: TabTraySelectorUX.maxFontSize)
            }
        }
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.layer1
        selectionBackgroundView.backgroundColor = theme.colors.actionSecondary

        for button in buttons {
            button.setTitleColor(theme.colors.textPrimary, for: .normal)
        }
    }
}
