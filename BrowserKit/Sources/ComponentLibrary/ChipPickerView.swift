// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A horizontally scrolling picker that renders selectable options as chip buttons.
public final class ChipPickerView: UIView, ThemeApplicable, UIScrollViewDelegate {
    public struct UX {
        public static let itemSpacing: CGFloat = 10
    }

    private lazy var scrollView: UIScrollView = .build { scrollView in
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
    }

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = UX.itemSpacing
    }

    private var currentTheme: Theme?
    private var items = [ChipPickerItem]()
    private var selectedID: String?
    private var onSelection: (@MainActor (String) -> Void)?
    private var onScroll: ((CGFloat) -> Void)?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        setupLayout()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(
        items: [ChipPickerItem],
        selectedID: String?,
        contentOffsetX: CGFloat = 0,
        onScroll: ((CGFloat) -> Void)? = nil,
        onSelection: (@MainActor (String) -> Void)? = nil
    ) {
        self.items = items
        self.selectedID = selectedID
        self.onSelection = onSelection
        self.onScroll = onScroll
        rebuildButtons()
        updateContentOffsetX(contentOffsetX)
    }

    public func applyTheme(theme: Theme) {
        currentTheme = theme
        chipButtons.forEach { $0.applyTheme(theme: theme) }
    }

    public func updateSelectedID(_ selectedID: String?) {
        self.selectedID = selectedID
        rebuildButtons()
        scrollView.layoutIfNeeded()
    }

    public func updateContentOffsetX(_ contentOffsetX: CGFloat) {
        scrollView.setContentOffset(CGPoint(x: contentOffsetX, y: 0), animated: false)
    }

    private var chipButtons: [ChipButton] {
        stackView.arrangedSubviews.compactMap { $0 as? ChipButton }
    }

    private func setupLayout() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.delegate = self

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])
    }

    private func rebuildButtons() {
        stackView.removeAllArrangedViews()

        items.forEach { item in
            let chipButton = ChipButton()
            chipButton.configure(
                viewModel: ChipButtonViewModel(
                    title: item.title,
                    a11yIdentifier: item.a11yIdentifier,
                    isSelected: item.id == selectedID,
                    touchUpAction: { [weak self] _ in
                        self?.handleSelection(id: item.id)
                    }
                )
            )

            if let currentTheme {
                chipButton.applyTheme(theme: currentTheme)
            }
            stackView.addArrangedSubview(chipButton)
        }

        isHidden = items.isEmpty
    }

    private func handleSelection(id: String) {
        selectedID = id
        rebuildButtons()
        onSelection?(id)
    }

    // MARK: = UIScrollViewDelegate

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?(scrollView.contentOffset.x)
    }
}
