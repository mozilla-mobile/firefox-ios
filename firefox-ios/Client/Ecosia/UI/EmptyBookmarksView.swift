// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

final class EmptyBookmarksView: UIView, ThemeApplicable {

    private enum UX {
        static let TitleLabelFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        static let SectionLabelFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let SectionEnumerationFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .monospacedDigitSystemFont(ofSize: 16, weight: .regular))
        static let LearnMoreButtonLabelFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let ImportButtonLabelFont = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16))
        static let ImportButtonPaddingInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        static let LayoutMargingsInset: CGFloat = 12
        static let ImportButtonBorderWidth: CGFloat = 1
        static let ImportButtonCornerRadius: CGFloat = 20
        static let TitleSpacerHeight: CGFloat = 24
        static let InBetweenSpacerWidth: CGFloat = 8
        static let SectionSpacerWidth: CGFloat = 36
        static let SectionIconLabelSpacerWidth: CGFloat = 24
        static let SectionEndSpacerHeight: CGFloat = 16
        static let SectionIconWidth: CGFloat = 18
        static let SectionContainerMaxWidth: CGFloat = 450
        static let ButtonAreaHeight: CGFloat = 50
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = .localized(.noBookmarksYet)
        label.textAlignment = .center
        label.font = UX.TitleLabelFont
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    private let learnMoreButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.localized(.learnMore), for: .normal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private let importBookmarksButton: UIButton = {
       let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.localized(.importBookmarks), for: .normal)
        button.layer.borderWidth = UX.ImportButtonBorderWidth
        button.layer.cornerRadius = UX.ImportButtonCornerRadius
        button.setInsets(
            forContentPadding: UX.ImportButtonPaddingInset,
            imageTitlePadding: 0
        )
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    weak var delegate: EmptyBookmarksViewDelegate?

    var bottomMarginConstraint: NSLayoutConstraint?

    // MARK: - Init

    required init?(coder: NSCoder) {
        assertionFailure("This view is only supposed to be instantiated programmatically")
        return nil
    }

    init(
        initialBottomMargin: CGFloat
    ) {
        super.init(frame: .zero)
        setup(initialBottomMargin)
    }

    private func setup(_ initialBottomMargin: CGFloat) {
        addSubview(containerStackView)

        bottomMarginConstraint = containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: initialBottomMargin)

        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor, constant: UX.LayoutMargingsInset),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor, constant: -UX.LayoutMargingsInset),
            containerStackView.widthAnchor.constraint(lessThanOrEqualToConstant: UX.SectionContainerMaxWidth),
            bottomMarginConstraint,
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ].compactMap { $0 })

        // title
        containerStackView.addArrangedSubview(titleLabel)

        // space between title and first section
        let spacerOne = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: UX.TitleSpacerHeight).isActive = true
        }
        containerStackView.addArrangedSubview(spacerOne)

        addSection(imageNamed: "bookmarkAdd", text: .localized(.bookmarksEmptyViewItem0))
        addSection(imageNamed: "exportShare", text: .localized(.bookmarksEmptyViewItem1), listItems: [
            .localized(.bookmarksEmptyViewItem1NumberedItem0),
            .localized(.bookmarksEmptyViewItem1NumberedItem1)
        ])

        let buttonsContainerCenterView = UIView.build { centerView in
            let buttonsContainer = UIView.build { view in
                view.addSubview(self.learnMoreButton)
                view.addSubview(self.importBookmarksButton)
                NSLayoutConstraint.activate([
                    self.learnMoreButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    self.importBookmarksButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    self.learnMoreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    self.learnMoreButton.trailingAnchor.constraint(equalTo: self.importBookmarksButton.leadingAnchor, constant: -UX.InBetweenSpacerWidth).priority(.defaultHigh),
                    self.importBookmarksButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    view.heightAnchor.constraint(equalToConstant: UX.ButtonAreaHeight)
                ])
            }
            centerView.addSubview(buttonsContainer)
            NSLayoutConstraint.activate([
                buttonsContainer.centerXAnchor.constraint(equalTo: centerView.centerXAnchor),
                buttonsContainer.bottomAnchor.constraint(equalTo: centerView.bottomAnchor),
                buttonsContainer.topAnchor.constraint(equalTo: centerView.topAnchor)
            ])
        }

        containerStackView.addArrangedSubview(buttonsContainerCenterView)

        // setup buttons
        learnMoreButton.addTarget(self, action: #selector(onLearnMoreTapped), for: .touchUpInside)
        importBookmarksButton.addTarget(self, action: #selector(onImportTapped), for: .touchUpInside)
    }

    private func addSection(imageNamed: String, text: String, listItems: [String]? = nil) {
        // first section (tap the bookmark icon when you find a page you want to share)
        let sectionStackView = UIStackView()
        sectionStackView.axis = .horizontal
        sectionStackView.alignment = .top

        if traitCollection.userInterfaceIdiom == .pad {
            sectionStackView.addArrangedSubview(createSpacerView(width: UX.SectionSpacerWidth))
        }

        let sectionIcon = UIImageView()
        sectionIcon.contentMode = .scaleAspectFit
        sectionIcon.image = UIImage.templateImageNamed(imageNamed)
        sectionIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        sectionIcon.setContentHuggingPriority(.required, for: .horizontal)
        sectionIcon.translatesAutoresizingMaskIntoConstraints = false
        sectionIcon.widthAnchor.constraint(equalToConstant: UX.SectionIconWidth).priority(.required).isActive = true

        sectionStackView.addArrangedSubview(sectionIcon)

        let sectionOneIconLabelSpacer = UIView.build {
            $0.widthAnchor.constraint(equalToConstant: UX.SectionIconLabelSpacerWidth).isActive = true
        }
        sectionStackView.addArrangedSubview(sectionOneIconLabelSpacer)

        let sectionLabelsStackView = UIStackView()
        sectionLabelsStackView.axis = .vertical
        sectionStackView.addArrangedSubview(sectionLabelsStackView)

        let sectionLabel = UILabel()
        sectionLabel.font = UX.SectionLabelFont
        sectionLabel.numberOfLines = 0
        sectionLabel.text = text
        sectionLabel.adjustsFontForContentSizeCategory = true
        sectionLabelsStackView.addArrangedSubview(sectionLabel)

        if let listItems = listItems {
            for (index, listItem) in listItems.enumerated() {
                let enumerationLabel = UILabel()
                enumerationLabel.font = UX.SectionEnumerationFont
                enumerationLabel.text = " \(index+1). "

                let textLabel = UILabel()
                textLabel.font = UX.SectionLabelFont
                textLabel.text = listItem

                [enumerationLabel, textLabel].forEach {
                    $0.setContentHuggingPriority(.required, for: .horizontal)
                    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
                    $0.numberOfLines = 0
                    $0.adjustsFontForContentSizeCategory = true
                }

                let listItemStackView = UIStackView()
                listItemStackView.axis = .horizontal
                listItemStackView.alignment = .leading
                listItemStackView.distribution = .fill

                listItemStackView.addArrangedSubview(enumerationLabel)
                listItemStackView.addArrangedSubview(textLabel)

                listItemStackView.addArrangedSubview(UIView.build {
                    $0.setContentHuggingPriority(.required, for: .horizontal)
                    $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                })

                sectionLabelsStackView.addArrangedSubview(listItemStackView)
            }
        }

        if traitCollection.userInterfaceIdiom == .pad {
            sectionStackView.addArrangedSubview(createSpacerView(width: UX.SectionSpacerWidth))
        }

        containerStackView.addArrangedSubview(sectionStackView)

        let sectionEndSpacer = UIView.build {
            $0.heightAnchor.constraint(equalToConstant: UX.SectionEndSpacerHeight).isActive = true
        }

        containerStackView.addArrangedSubview(sectionEndSpacer)
    }

    private func createSpacerView(width: CGFloat) -> UIView {
        UIView.build {
            $0.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            $0.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }

    @objc func onLearnMoreTapped() {
        Analytics.shared.bookmarksEmptyLearnMoreClicked()
        delegate?.emptyBookmarksViewLearnMoreTapped(self)
    }

    @objc private func onImportTapped() {
        delegate?.emptyBookmarksViewImportBookmarksTapped(self)
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        importBookmarksButton.layer.borderColor = theme.colors.ecosia.textPrimary.cgColor
        learnMoreButton.setTitleColor(theme.colors.ecosia.textPrimary, for: .normal)
        learnMoreButton.titleLabel?.font = UX.LearnMoreButtonLabelFont
        importBookmarksButton.setTitleColor(theme.colors.ecosia.textPrimary, for: .normal)
        importBookmarksButton.titleLabel?.font = UX.ImportButtonLabelFont
        titleLabel.textColor = theme.colors.ecosia.textPrimary
        applyThemeToSectionsIn(containerStackView, theme: theme)
    }

    func applyThemeToSectionsIn(_ stackView: UIStackView, theme: Theme) {
        var finalResult = [UIView]()
        var iterateThroughSubviews: ((UIStackView) -> Void)?

        iterateThroughSubviews = { stackView in
            for subview in stackView.arrangedSubviews {
                if let subStackView = subview as? UIStackView {
                    iterateThroughSubviews?(subStackView)
                } else {
                    finalResult.append(subview)
                }
            }
        }

        stackView.arrangedSubviews.forEach {
            if let stackView = $0 as? UIStackView {
                iterateThroughSubviews?(stackView)
            }
        }

        finalResult.forEach {
            switch $0 {
            case let label as UILabel:
                label.textColor = theme.colors.ecosia.textSecondary
            default:
                $0.tintColor = theme.colors.ecosia.textSecondary
                break
            }
        }
    }
}
