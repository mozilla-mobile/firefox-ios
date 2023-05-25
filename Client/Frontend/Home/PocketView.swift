// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class PocketFooterView: UICollectionReusableView, ReusableCell {
    private let pocketImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.zoomIn)
    }

    private let topLabel: UILabel = .build { label in
        label.text = "Powered by Pocket."
    }

    private let midLabel: UILabel = .build { label in
        label.text = "Part of the Firefox family."
    }

    private let learnMoreLabel: UILabel = .build { label in
        label.text = "Learn more"
        label.isUserInteractionEnabled = true
    }

    private let labelsContainer: UIStackView = .build()
    
    private let mainContainer: UIStackView = .build { stackView in
        stackView.axis = .horizontal
    }

    init() {
        super.init(frame: .zero)
        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLearnMore))
        learnMoreLabel.addGestureRecognizer(tapGesture)

        [topLabel, midLabel, learnMoreLabel].forEach {
            labelsContainer.addArrangedSubview($0)
        }

        [pocketImageView, labelsContainer].forEach {
            mainContainer.addArrangedSubview($0)
        }

        addSubview(mainContainer)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            mainContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainContainer.topAnchor.constraint(equalTo: topAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc
    func didTapLearnMore() {

    }
}
