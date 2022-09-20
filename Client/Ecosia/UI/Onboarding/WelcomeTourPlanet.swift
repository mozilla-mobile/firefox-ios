/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class WelcomeTourPlanet: UIView, NotificationThemeable {
    private weak var searchLabel: UILabel!
    private weak var impactLabel: UILabel!
    private weak var treesLabel: UILabel!
    private weak var numTreesLabel: UILabel!

    init() {
        super.init(frame: .zero)
        setup()
        applyTheme()
    }

    required init?(coder: NSCoder) {  nil }

    func setup() {
        let iPadOffset: CGFloat = traitCollection.userInterfaceIdiom == .pad ? 30 : 0

        let topImage = UIImageView(image: .init(named: "tourSearch"))
        topImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topImage)

        topImage.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -25).isActive = true
        topImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -90 - iPadOffset).isActive = true

        let searchLabel = UILabel()
        searchLabel.translatesAutoresizingMaskIntoConstraints = false
        searchLabel.text = .localized(.sustainableShoes)
        searchLabel.font = .systemFont(ofSize: 12)
        searchLabel.numberOfLines = 1
        searchLabel.textAlignment = .left
        topImage.addSubview(searchLabel)
        self.searchLabel = searchLabel

        searchLabel.leadingAnchor.constraint(equalTo: topImage.leadingAnchor, constant: 44).isActive = true
        searchLabel.topAnchor.constraint(equalTo: topImage.topAnchor, constant: 22).isActive = true
        searchLabel.trailingAnchor.constraint(equalTo: topImage.trailingAnchor, constant: -40).isActive = true

        topImage.transform = .init(rotationAngle: Double.pi / -25)

        let bottomImage = UIImageView(image: .init(named: "tourCounter"))
        bottomImage.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomImage)

        bottomImage.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 25).isActive = true
        bottomImage.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 40 + iPadOffset).isActive = true

        let impactLabel = UILabel()
        impactLabel.translatesAutoresizingMaskIntoConstraints = false
        impactLabel.text = .localized(.yourImpact)
        impactLabel.numberOfLines = 1
        impactLabel.textAlignment = .left
        impactLabel.font = .systemFont(ofSize: 10)
        bottomImage.addSubview(impactLabel)
        self.impactLabel = impactLabel

        let treesLabel = UILabel()
        treesLabel.translatesAutoresizingMaskIntoConstraints = false
        treesLabel.text = .localized(.treesPlanted)
        treesLabel.numberOfLines = 1
        treesLabel.textAlignment = .left
        treesLabel.font = .boldSystemFont(ofSize: 13)
        bottomImage.addSubview(treesLabel)
        self.treesLabel = treesLabel

        let numTreesLabel = UILabel()
        numTreesLabel.translatesAutoresizingMaskIntoConstraints = false
        numTreesLabel.text = "10"
        numTreesLabel.numberOfLines = 1
        numTreesLabel.textAlignment = .left
        numTreesLabel.font = .boldSystemFont(ofSize: 17)
        bottomImage.addSubview(numTreesLabel)
        self.numTreesLabel = numTreesLabel

        impactLabel.leadingAnchor.constraint(equalTo: bottomImage.leadingAnchor, constant: 20).isActive = true
        impactLabel.topAnchor.constraint(equalTo: bottomImage.topAnchor, constant: 34).isActive = true

        treesLabel.leadingAnchor.constraint(equalTo: impactLabel.leadingAnchor, constant: 0).isActive = true
        treesLabel.topAnchor.constraint(equalTo: impactLabel.bottomAnchor, constant: 4).isActive = true

        numTreesLabel.topAnchor.constraint(equalTo: bottomImage.topAnchor, constant: 48).isActive = true
        numTreesLabel.trailingAnchor.constraint(equalTo: bottomImage.trailingAnchor, constant: -36).isActive = true

        bottomImage.transform = .init(rotationAngle: Double.pi / 40)

        // upscale images for iPad
        if traitCollection.userInterfaceIdiom == .pad {
            bottomImage.transform = bottomImage.transform.scaledBy(x: 1.5, y: 1.5)
            topImage.transform = topImage.transform.scaledBy(x: 1.5, y: 1.5)
        }
    }

    func applyTheme() {
        searchLabel.textColor = .theme.ecosia.primaryText
        impactLabel.textColor = .theme.ecosia.secondaryText
        treesLabel.textColor = .theme.ecosia.primaryText
    }
}
