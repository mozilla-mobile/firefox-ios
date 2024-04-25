/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import DesignSystem
import UIComponents
import Combine

@available(iOS 14, *)
public class ShortcutView: UIView {
    public var contextMenuIsDisplayed = false
    public private(set) var viewModel: ShortcutViewModel

    public private(set) lazy var outerView: UIView = {
        let outerView = UIView()
        outerView.backgroundColor = .above
        outerView.accessibilityIdentifier = "outerView"
        outerView.layer.cornerRadius = 8
        outerView.translatesAutoresizingMaskIntoConstraints = false
        return outerView
    }()

    private lazy var innerView: UIView = {
        let innerView = UIView()
        innerView.backgroundColor = .foundation
        innerView.layer.cornerRadius = 4
        innerView.translatesAutoresizingMaskIntoConstraints = false
        innerView.addSubview(letterLabel)
        NSLayoutConstraint.activate([
            letterLabel.centerXAnchor.constraint(equalTo: innerView.centerXAnchor),
            letterLabel.centerYAnchor.constraint(equalTo: innerView.centerYAnchor)
        ])
        return innerView
    }()

    private lazy var letterLabel: UILabel = {
        let letterLabel = UILabel()
        letterLabel.textColor = .primaryText
        letterLabel.font = .title20
        letterLabel.translatesAutoresizingMaskIntoConstraints = false
        return letterLabel
    }()

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = .primaryText
        nameLabel.font = .footnote12
        nameLabel.numberOfLines = 2
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        return nameLabel
    }()

    private lazy var faviImageView: AsyncImageView = {
        let image = AsyncImageView()
        image.layer.cornerRadius = 4
        image.clipsToBounds = true
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    public struct LayoutConfiguration {
        public var width: CGFloat
        public var height: CGFloat
        public var inset: CGFloat

        public static let iPad = LayoutConfiguration(
            width: .shortcutViewWidthIPad,
            height: .shortcutViewHeightIPad,
            inset: .shortcutViewInnerDimensionIPad
        )
        public static let `default` = LayoutConfiguration(
            width: .shortcutViewWidth,
            height: .shortcutViewHeight,
            inset: .shortcutViewInnerDimension
        )
    }

    private var cancellables: Set<AnyCancellable> = []

    public init(shortcutViewModel: ShortcutViewModel,
                layoutConfiguration: LayoutConfiguration = .default) {
        self.viewModel = shortcutViewModel

        super.init(frame: CGRect.zero)

        viewModel
            .$shortcut
            .sink { [weak self] in
                guard let self = self else { return }
                self.nameLabel.text = $0.name

                if let url = $0.imageURL {
                    let shortcutImage = $0.capital.flatMap { self.viewModel.faviconWithLetter?($0) } ?? .defaultFavicon
                    self.faviImageView.load(imageURL: url, defaultImage: shortcutImage)
                } else {
                    self.letterLabel.text = $0.capital
                }
            }
            .store(in: &cancellables)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.addGestureRecognizer(tap)
        self.addInteraction(UIPointerInteraction(delegate: self))

        addSubview(outerView)

        NSLayoutConstraint.activate([
            outerView.widthAnchor.constraint(equalToConstant: layoutConfiguration.width),
            outerView.heightAnchor.constraint(equalToConstant: layoutConfiguration.width),
            outerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            outerView.topAnchor.constraint(equalTo: topAnchor)
        ])

        let centerView = viewModel.shortcut.imageURL != nil ? faviImageView : innerView
        outerView.addSubview(centerView)
        NSLayoutConstraint.activate([
            centerView.widthAnchor.constraint(equalToConstant: layoutConfiguration.inset),
            centerView.heightAnchor.constraint(equalToConstant: layoutConfiguration.inset),
            centerView.centerXAnchor.constraint(equalTo: outerView.centerXAnchor),
            centerView.centerYAnchor.constraint(equalTo: outerView.centerYAnchor)
        ])

        addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: outerView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 8)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTap() {
        viewModel.send(action: .tapped)
    }
}

@available(iOS 14, *)
extension ShortcutView: UIPointerInteractionDelegate {
    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        interaction
            .view
            .map { UITargetedPreview(view: $0) }
            .map { UIPointerEffect.lift($0) }
            .map { UIPointerStyle(effect: $0) }
    }
}

// MARK: Constants

fileprivate extension CGFloat {
    static let shortcutViewWidth: CGFloat = 60
    static let shortcutViewWidthIPad: CGFloat = 80
    static let shortcutViewInnerDimension: CGFloat = 36
    static let shortcutViewInnerDimensionIPad: CGFloat = 48
    static let shortcutViewHeight: CGFloat = 84
    static let shortcutViewHeightIPad: CGFloat = 100
}
