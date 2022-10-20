/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class NTPImpactCell: UICollectionViewCell, NotificationThemeable, ReusableCell {

    static let topMargin = CGFloat(10)

    private(set) var model: Model?
    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private weak var background: UIView!
    private weak var container: UIStackView!

    private weak var impactBackground: UIView!
    private weak var impactStack: UIStackView!
    private weak var personalImpactStack: UIStackView!
    private weak var personalImpactLabelStack: UIStackView!
    private weak var yourImpact: UILabel!
    private weak var treesPlanted: UILabel!

    private weak var globalCountStack: UIStackView!
    private weak var globalCount: UILabel!
    private weak var globalCountDescription: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let background = UIView()
        background.setContentHuggingPriority(.defaultLow, for: .horizontal)
        background.translatesAutoresizingMaskIntoConstraints = false
        background.layer.cornerRadius = 8
        contentView.addSubview(background)
        self.background = background

        let container = UIStackView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .vertical
        container.distribution = .fill
        container.alignment = .fill
        container.setContentHuggingPriority(.required, for: .horizontal)
        container.backgroundColor = .clear
        contentView.addSubview(container)
        self.container = container

        addImpact()
        addProgress()
        addConstraints()
        applyTheme()
    }

    func display(_ model: Model) {
        self.model = model

        currentProgress.value = User.shared.progress

        if #available(iOS 15.0, *) {
            treesCount.text = model.trees.formatted()
        } else {
            treesCount.text = "\(model.trees)"
        }

        applyTheme()
        updateGlobalCount()
    }

    private func updateGlobalCount() {
        // don't subscribe and animate for reduced motion
        guard !UIAccessibility.isReduceMotionEnabled else {
            TreeCounter.shared.unsubscribe(self)
            let count = TreeCounter.shared.statistics.treesAt(.init())
            self.globalCount.text = self.formatter.string(from: .init(value: count))
            return
        }

        TreeCounter.shared.subscribe(self) { [weak self] count in
            guard let self = self else { return }

            UIView.transition(with: self.globalCount, duration: 0.65, options: .transitionCrossDissolve, animations: {
                self.globalCount.text = self.formatter.string(from: .init(value: count))
            })
            self.model.map({ self.display($0) })
        }
    }

    private func addImpact() {
        let impactBackground = UIView()
        impactBackground.setContentHuggingPriority(.defaultLow, for: .horizontal)
        impactBackground.translatesAutoresizingMaskIntoConstraints = false
        impactBackground.layer.cornerRadius = 8
        container.addArrangedSubview(impactBackground)
        self.impactBackground = impactBackground

        let impactStack = UIStackView()
        impactStack.axis = .vertical
        impactStack.spacing = 16
        impactStack.translatesAutoresizingMaskIntoConstraints = false
        impactBackground.addSubview(impactStack)
        self.impactStack = impactStack

        let personalImpactStack = UIStackView()
        personalImpactStack.axis = .horizontal
        personalImpactStack.spacing = 16
        personalImpactStack.translatesAutoresizingMaskIntoConstraints = false
        impactStack.addArrangedSubview(personalImpactStack)
        self.personalImpactStack = personalImpactStack

        let personalImpactLabelStack = UIStackView()
        personalImpactLabelStack.axis = .vertical
        personalImpactLabelStack.spacing = 4
        personalImpactLabelStack.translatesAutoresizingMaskIntoConstraints = false
        personalImpactStack.addArrangedSubview(personalImpactLabelStack)
        self.personalImpactLabelStack = personalImpactLabelStack

        personalImpactLabelStack.addArrangedSubview(UIView())

        let yourImpact = UILabel()
        yourImpact.text = .localized(.yourImpact)
        yourImpact.translatesAutoresizingMaskIntoConstraints = false
        yourImpact.font = .preferredFont(forTextStyle: .footnote)
        yourImpact.adjustsFontForContentSizeCategory = true
        yourImpact.setContentHuggingPriority(.defaultLow, for: .horizontal)
        yourImpact.setContentCompressionResistancePriority(.required, for: .vertical)
        yourImpact.setContentHuggingPriority(.init(751), for: .vertical) // to counter ambiguity
        personalImpactLabelStack.addArrangedSubview(yourImpact)
        self.yourImpact = yourImpact

        let treesPlanted = UILabel()
        treesPlanted.text = .localized(.treesPlanted)
        treesPlanted.translatesAutoresizingMaskIntoConstraints = false
        treesPlanted.font = .preferredFont(forTextStyle: .title3).bold()
        treesPlanted.setContentCompressionResistancePriority(.required, for: .vertical)
        treesPlanted.setContentHuggingPriority(.defaultHigh, for: .vertical)
        treesPlanted.adjustsFontForContentSizeCategory = true
        treesPlanted.numberOfLines = 0
        personalImpactLabelStack.addArrangedSubview(treesPlanted)
        self.treesPlanted = treesPlanted

        let globalCountStack = UIStackView()
        globalCountStack.axis = .vertical
        globalCountStack.distribution = .fill
        globalCountStack.spacing = 4
        impactStack.addArrangedSubview(globalCountStack)
        self.globalCountStack = globalCountStack

        let globalCountDescription = UILabel()
        globalCountDescription.textAlignment = .left
        globalCountDescription.translatesAutoresizingMaskIntoConstraints = false
        globalCountDescription.text = .localized(.treesPlantedByTheCommunity)
        globalCountDescription.font = .preferredFont(forTextStyle: .footnote)
        globalCountDescription.adjustsFontForContentSizeCategory = true
        globalCountDescription.setContentHuggingPriority(.defaultLow, for: .horizontal)
        globalCountDescription.numberOfLines = 0
        globalCountDescription.textAlignment = .left
        globalCountStack.addArrangedSubview(globalCountDescription)
        self.globalCountDescription = globalCountDescription

        let globalCountInnerStack = UIStackView()
        globalCountInnerStack.axis = .horizontal
        globalCountInnerStack.distribution = .fill
        globalCountInnerStack.spacing = 4
        globalCountStack.addArrangedSubview(globalCountInnerStack)

        let treesImage = UIImageView(image: .init(named: "trees"))
        treesImage.setContentHuggingPriority(.required, for: .horizontal)
        globalCountInnerStack.addArrangedSubview(treesImage)

        let globalCount = UILabel()
        globalCount.translatesAutoresizingMaskIntoConstraints = false
        globalCount.setContentCompressionResistancePriority(.required, for: .horizontal)
        globalCount.setContentCompressionResistancePriority(.required, for: .vertical)
        globalCount.setContentHuggingPriority(.defaultLow, for: .horizontal)
        globalCount.font = .preferredFont(forTextStyle: .subheadline).bold().monospace()
        globalCount.adjustsFontForContentSizeCategory = true
        globalCount.textAlignment = .left

        globalCountInnerStack.addArrangedSubview(globalCount)
        self.globalCount = globalCount
    }

    // MARK: Progress
    private weak var totalProgress: MyImpactCell.Progress!
    private weak var currentProgress: MyImpactCell.Progress!
    private weak var outline: UIView!
    private weak var treesCount: UILabel!
    private weak var treesIcon: UIImageView!

    private func addProgress() {
        let outline = UIView()
        outline.translatesAutoresizingMaskIntoConstraints = false
        personalImpactStack.addArrangedSubview(outline)
        self.outline = outline

        let progressSize = CGSize(width: 80, height: 50)

        let totalProgress = MyImpactCell.Progress(size: progressSize, lineWidth: 3)
        outline.addSubview(totalProgress)
        self.totalProgress = totalProgress

        let currentProgress = MyImpactCell.Progress(size: progressSize, lineWidth: 3)
        outline.addSubview(currentProgress)
        self.currentProgress = currentProgress

        let treesIcon = UIImageView()
        treesIcon.translatesAutoresizingMaskIntoConstraints = false
        treesIcon.contentMode = .center
        treesIcon.clipsToBounds = true
        outline.addSubview(treesIcon)
        self.treesIcon = treesIcon

        let treesCount = UILabel()
        treesCount.translatesAutoresizingMaskIntoConstraints = false
        treesCount.font = .preferredFont(forTextStyle: .subheadline).bold()
        treesCount.adjustsFontForContentSizeCategory = true
        self.treesCount = treesCount
        outline.addSubview(treesCount)

        outline.widthAnchor.constraint(equalToConstant: progressSize.width).isActive = true
        outline.heightAnchor.constraint(equalToConstant: progressSize.height).isActive = true

        totalProgress.topAnchor.constraint(equalTo: outline.topAnchor, constant: 0).isActive = true
        totalProgress.centerXAnchor.constraint(equalTo: outline.centerXAnchor).isActive = true

        currentProgress.centerYAnchor.constraint(equalTo: totalProgress.centerYAnchor).isActive = true
        currentProgress.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true

        treesIcon.topAnchor.constraint(equalTo: totalProgress.topAnchor, constant: 10).isActive = true
        treesIcon.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true

        treesCount.topAnchor.constraint(equalTo: treesIcon.bottomAnchor, constant: 2).isActive = true
        treesCount.centerXAnchor.constraint(equalTo: totalProgress.centerXAnchor).isActive = true
    }

    private func addConstraints() {
        // Constraints for stack views to their backgrounds
        background.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.topMargin).isActive = true
        let bottom = background.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        bottom.priority = .defaultHigh
        bottom.isActive = true

        let right = background.rightAnchor.constraint(equalTo: contentView.rightAnchor)
        right.priority = .defaultHigh
        right.isActive = true

        background.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true

        container.rightAnchor.constraint(equalTo: background.rightAnchor).isActive = true
        container.topAnchor.constraint(equalTo: background.topAnchor).isActive = true
        container.leftAnchor.constraint(equalTo: background.leftAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: background.bottomAnchor).isActive = true

        impactStack.rightAnchor.constraint(equalTo: impactBackground.rightAnchor, constant: -16).isActive = true
        impactStack.topAnchor.constraint(equalTo: impactBackground.topAnchor, constant: 16).isActive = true
        impactStack.leftAnchor.constraint(equalTo: impactBackground.leftAnchor, constant: 16).isActive = true
        impactStack.bottomAnchor.constraint(equalTo: impactBackground.bottomAnchor, constant: -16).isActive = true

    }

    func applyTheme() {
        background.backgroundColor = UIColor.theme.ecosia.primaryBackground

        let backgroundColor: UIColor = model?.style == .ntp ? .theme.ecosia.ntpImpactBackground : .theme.ecosia.impactBackground
        let selectedBackgroundColor: UIColor = model?.style == .ntp ? .theme.ecosia.primarySelectedBackground : .theme.ecosia.secondarySelectedBackground
        impactBackground.backgroundColor = (isHighlighted || isSelected) ? selectedBackgroundColor : backgroundColor

        globalCountDescription.textColor = .theme.ecosia.secondaryText
        globalCount.textColor = .theme.ecosia.primaryText

        yourImpact.textColor = .theme.ecosia.secondaryText
        treesPlanted.textColor = .theme.ecosia.primaryText

        totalProgress.update(color: .theme.ecosia.ntpBackground)
        currentProgress.update(color: .theme.ecosia.treeCounterProgressCurrent)
        treesCount.textColor = .theme.ecosia.primaryText
        treesPlanted.textColor = .theme.ecosia.primaryText
        treesIcon.image = .init(themed: "yourImpact")
    }

    // MARK: Overrides
    override var isHighlighted: Bool {
        set {
            super.isHighlighted = newValue
            applyTheme()
        }
        get {
            return super.isHighlighted
        }
    }

    override var isSelected: Bool {
        set {
            super.isSelected = newValue
            applyTheme()
        }
        get {
            return super.isSelected
        }
    }
}
