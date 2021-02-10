/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

final class Welcome: UIViewController {
    private weak var image: UIImageView!
    
    required init?(coder: NSCoder) { nil }
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.theme.ecosia.primaryBackground

        let container = UIView()
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let image = UIImageView(image: UIImage(named: "obTrees")!)
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        container.addSubview(image)
        self.image = image
        
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.numberOfLines = 0
        title.font = .preferredFont(forTextStyle: .largeTitle)
        title.textColor = UIColor.theme.ecosia.highContrastText
        title.text = .localized(.plantTreesWhile)
        title.textAlignment = .center
        container.addSubview(title)
        
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.numberOfLines = 0
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.textColor = UIColor.theme.ecosia.highContrastText
        subtitle.text = .localized(.weUseTheProfit)
        subtitle.textAlignment = .center
        container.addSubview(subtitle)
        
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.localized(.getStarted), for: [])
        button.setBackgroundColor(UIColor.theme.ecosia.primaryButton, forState: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.init(white: 1, alpha: 0.3), for: .highlighted)
        button.titleLabel!.font = .preferredFont(forTextStyle: .headline)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        container.addSubview(button)

        container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        container.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        container.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
        container.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true

        image.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        image.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        image.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 0).isActive = true
        let imageToTitle = image.bottomAnchor.constraint(equalTo: title.topAnchor, constant: -68)
        imageToTitle.priority = .defaultHigh
        imageToTitle.isActive = true
        image.heightAnchor.constraint(equalTo: image.widthAnchor, multiplier: 1).isActive = true
        image.bottomAnchor.constraint(lessThanOrEqualTo: title.topAnchor, constant: -16).isActive = true


        title.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32).isActive = true
        title.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32).isActive = true
        title.bottomAnchor.constraint(equalTo: subtitle.topAnchor, constant: -12).isActive = true
        title.setContentCompressionResistancePriority(.required, for: .vertical)

        subtitle.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32).isActive = true
        subtitle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32).isActive = true
        subtitle.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -52).isActive = true
        subtitle.setContentCompressionResistancePriority(.required, for: .vertical)

        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        
        button.leadingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        button.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true

        // TODO: Analytics.shared.onboarding(view: .intro)
    }
    
    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
}
