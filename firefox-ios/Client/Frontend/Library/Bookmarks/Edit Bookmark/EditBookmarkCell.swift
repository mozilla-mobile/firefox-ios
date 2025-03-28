// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SiteImageView
import Common
import ComponentLibrary

class EditBookmarkCell: UITableViewCell,
                        ReusableCell,
                        ThemeApplicable {
    private struct UX {
        static let textFieldDividerHeight: CGFloat = 0.5
        static let textFieldDividerTrailingPadding: CGFloat = 24.0
        static let faviconSize: CGFloat = 64.0
        static let faviconVerticalPadding: CGFloat = 12.0
        static let faviconLeadingPadding: CGFloat = 16.0
        static let textFieldContainerLeadingPadding: CGFloat = 8.0
        static let textFieldContainerTrailingPadding: CGFloat = 16.0
        static let textFieldContainerVerticalPadding: CGFloat = 12.0
    }
    private lazy var faviconImageView: FaviconImageView = .build()
    private lazy var textFieldsContainerView: UIStackView = .build { view in
        view.axis = .vertical
        view.distribution = .fillProportionally
        view.spacing = 10.0
    }
    private lazy var textFieldsDivider: UIView = .build()
    private lazy var titleTextfield: TextField = .build { view in
        view.addAction(UIAction(handler: { [weak self] _ in
            self?.titleTextFieldDidChange()
        }), for: .editingChanged)
        view.adjustsFontSizeToFitWidth = true
        view.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.titleTextField
    }
    private lazy var urlTextfield: TextField = .build { view in
        view.keyboardType = .URL
        view.addAction(UIAction(handler: { [weak self] _ in
            self?.urlTextFieldDidChange()
        }), for: .editingChanged)
        view.adjustsFontSizeToFitWidth = true
        view.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.urlTextField
        view.autocapitalizationType = .none
    }
    var onTitleFieldUpdate: ((String) -> Void)?
    var onURLFieldUpdate: ((String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        typealias A11y = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel
        let textFieldViewModel = TextFieldViewModel(
            formA11yId: A11y.titleTextField,
            clearButtonA11yId: A11y.titleTextFieldClearButton,
            clearButtonA11yLabel: String.Bookmarks.Menu.ClearTextFieldButtonA11yLabel
        )
        titleTextfield.configure(viewModel: textFieldViewModel)
        let urlTextFieldViewModel = TextFieldViewModel(
            formA11yId: A11y.urlTextField,
            clearButtonA11yId: A11y.urlTextFieldClearButton,
            clearButtonA11yLabel: String.Bookmarks.Menu.ClearTextFieldButtonA11yLabel
        )
        urlTextfield.configure(viewModel: urlTextFieldViewModel)
        textFieldsContainerView.addArrangedSubview(titleTextfield)
        textFieldsContainerView.addArrangedSubview(textFieldsDivider)
        textFieldsContainerView.addArrangedSubview(urlTextfield)
        contentView.addSubviews(faviconImageView, textFieldsContainerView)

        let faviconDynamicSize = min(UIFontMetrics.default.scaledValue(for: UX.faviconSize),
                                     2 * UX.faviconSize)
        NSLayoutConstraint.activate([
            faviconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                      constant: UX.faviconLeadingPadding),
            faviconImageView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                  constant: UX.faviconVerticalPadding),
            faviconImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                     constant: -UX.faviconVerticalPadding),
            faviconImageView.widthAnchor.constraint(equalToConstant: faviconDynamicSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: faviconDynamicSize),

            textFieldsDivider.heightAnchor.constraint(equalToConstant: UX.textFieldDividerHeight),
            textFieldsDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                        constant: -UX.textFieldDividerTrailingPadding),

            textFieldsContainerView.leadingAnchor.constraint(equalTo: faviconImageView.trailingAnchor,
                                                             constant: UX.textFieldContainerLeadingPadding),
            textFieldsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                              constant: -UX.textFieldContainerTrailingPadding),
            textFieldsContainerView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                         constant: UX.textFieldContainerVerticalPadding),
            textFieldsContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                            constant: -UX.textFieldContainerVerticalPadding)
        ])
    }

    func setData(siteURL: String?, title: String?) {
        titleTextfield.text = title
        urlTextfield.text = siteURL
        faviconImageView.setFavicon(FaviconImageViewModel(siteURLString: siteURL))
    }

    func focusTitleTextField() {
        titleTextfield.becomeFirstResponder()
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: any Theme) {
        urlTextfield.applyTheme(theme: theme)
        titleTextfield.applyTheme(theme: theme)
        textFieldsDivider.backgroundColor = theme.colors.borderPrimary
        backgroundColor = theme.colors.layer5
    }

    private func urlTextFieldDidChange() {
        onURLFieldUpdate?(urlTextfield.text ?? "")
    }

    private func titleTextFieldDidChange() {
        onTitleFieldUpdate?(titleTextfield.text ?? "")
    }
}
