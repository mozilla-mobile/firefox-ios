/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

final class TreeCounterCell: UICollectionViewCell, Themeable {

    private let treeCounter = TreeCounter()
    private weak var descriptionLabel: UILabel!
    private weak var logo: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setup() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        let logo = UIImageView(image: UIImage(themed: "ecosiaLogo"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.clipsToBounds = true
        logo.contentMode = .scaleAspectFit
        contentView.addSubview(logo)
        self.logo = logo

        let counter = UILabel()
        counter.translatesAutoresizingMaskIntoConstraints = false
        counter.textColor = UIColor.theme.ecosia.primaryBrand
        counter.font = .init(descriptor:
            UIFont.systemFont(ofSize: 24, weight: .medium).fontDescriptor.addingAttributes(
                [.featureSettings: [[UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                                     .typeIdentifier: kMonospacedNumbersSelector]]]), size: 0)
        contentView.addSubview(counter)

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = .localized(.treesPlantedWithEcosia)
        descriptionLabel.textColor = UIColor.theme.ecosia.highContrastText
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        contentView.addSubview(descriptionLabel)
        self.descriptionLabel = descriptionLabel

        logo.bottomAnchor.constraint(equalTo: counter.topAnchor, constant: -10).isActive = true
        logo.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        logo.heightAnchor.constraint(equalTo: logo.widthAnchor, multiplier: 0.71).isActive = true
        logo.widthAnchor.constraint(lessThanOrEqualToConstant: 95).isActive = true
        logo.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.33).isActive = true
        let logoWidth = logo.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.33)
        logoWidth.priority = .defaultHigh
        logoWidth.isActive = true

        counter.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true

        descriptionLabel.topAnchor.constraint(equalTo: counter.bottomAnchor, constant: 2).isActive = true
        descriptionLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        descriptionLabel.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 20).isActive = true
        descriptionLabel.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -20).isActive = true

        descriptionLabel.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor).isActive = true
        let descriptionBottom = descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        descriptionBottom.priority = .defaultLow
        descriptionBottom.isActive = true

        treeCounter.subscribe(self) { count in
            UIView.transition(with: counter, duration: 0.65, options: .transitionCrossDissolve, animations: {
                counter.text = formatter.string(from: .init(value: count))
            })
        }

        treeCounter.update(session: .shared) {
            UserDefaults.statistics = try? JSONEncoder().encode($0)
        }
    }

    func applyTheme() {
        descriptionLabel?.textColor = UIColor.theme.ecosia.highContrastText
        logo.image = UIImage(themed: "ecosiaLogo")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
}
