/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Combine
import UIComponents

class TrackingHeaderView: UIView {
    private lazy var faviImageView: AsyncImageView = {
        let image = AsyncImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    private lazy var domainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .callout)
        label.textColor = .primaryText
        label.numberOfLines = 0
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [faviImageView, domainLabel])
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addSubview(separator)
        addSubview(stackView)
        backgroundColor = .systemGroupedBackground

        faviImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
        }
        separator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.leading.trailing.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).inset(16)
            make.leading.bottom.equalToSuperview().inset(16)
        }
    }

    var cancellable: AnyCancellable?

    func configure(domain: String, publisher: AnyPublisher<URL?, Never>) {
        self.domainLabel.text = domain
        cancellable = publisher
            .sink { [weak self] url in
                guard let self = self else { return }
                guard let url = url else {
                    self.faviImageView.defaultImage = .defaultFavicon
                    return
                }
                self.faviImageView.load(imageURL: url, defaultImage: .defaultFavicon)
            }
    }
}
