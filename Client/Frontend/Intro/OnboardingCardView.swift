// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct OnboardingCardViewModel {
    let image: UIImage
    let title: String
    let description: String?
    let primaryAction: String
    let secondaryAction: String?
}

class OnboardingCardView: UIView, CardTheme {
    let viewModel: OnboardingCardViewModel?

    private lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fillProportionally
        stack.alignment = .center
        stack.axis = .vertical
    }

    private lazy var image: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImageView(image: )
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textColor = UIColor.red
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.textColor = UIColor.red
    }

    init(viewModel: OnboardingCardViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        contentStackView.addArrangedSubview(image)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)

        addSubviews(contentStackView)
    }

}
