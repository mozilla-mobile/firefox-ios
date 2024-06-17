/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TipViewController: UIViewController {
    // Mark dependency explicit
    private let nimbus = NimbusWrapper.shared

    private lazy var tipTitleLabel: UILabel = {
        let label = UILabel()
        let config = AppNimbus.shared.features.nimbusValidation.value()
        label.textColor = .secondaryLabel
        label.font = config.boldTipTitle ? .footnote14Bold : .footnote14Medium
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var tipDescriptionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.accent, for: .normal)
        button.setTitleColor(.secondaryLabel, for: .disabled)
        button.titleLabel?.font = .footnote14Light
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.numberOfLines = 0
        button.isEnabled = self.tip.action != nil
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [UIView(), tipTitleLabel, tipDescriptionButton])
        stackView.spacing = 0
        stackView.alignment = .center
        stackView.axis = .vertical
        return stackView
    }()

    public let tip: TipManager.Tip
    private let tipTappedAction: (TipManager.Tip) -> Void
    private let tapOutsideAction: () -> Void

    init(
        tip: TipManager.Tip,
        tipTappedAction: @escaping (TipManager.Tip) -> Void,
        tapOutsideAction: @escaping () -> Void) {
            self.tip = tip
            self.tipTappedAction = tipTappedAction
            self.tapOutsideAction = tapOutsideAction
            super.init(nibName: nil, bundle: nil)
        }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(stackView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
        view.addGestureRecognizer(tap)

        tipTitleLabel.text = tip.title

        tipDescriptionButton.setTitle(tip.description, for: .normal)
        tipDescriptionButton.addTarget(self, action: #selector(tapTip), for: .touchUpInside)

        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.layout.tipViewPadding)
            make.top.bottom.equalToSuperview()
        }
    }

    @objc
    private func tapTip() {
        tipTappedAction(tip)
    }

    @objc
    private func tapOutside() {
        tapOutsideAction()
    }
}
