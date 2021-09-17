/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TipViewController: UIViewController {
    
    private lazy var tipTitleLabel: SmartLabel = {
        let label = SmartLabel()
        label.textColor = UIConstants.colors.defaultFont
        label.font = UIConstants.fonts.shareTrackerStatsLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        return label
    }()
    
    private let tipDescriptionLabel: SmartLabel = {
        let label = SmartLabel()
        label.textColor = .accent
        label.font = UIConstants.fonts.shareTrackerStatsLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        return label
    }()
    
    public let tip: TipManager.Tip
    private let tipTapped: (TipManager.Tip) -> ()
    
    init(tip: TipManager.Tip, tipTapped: @escaping (TipManager.Tip) -> ()) {
        self.tip = tip
        self.tipTapped = tipTapped
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.addSubview(tipTitleLabel)
        view.addSubview(tipDescriptionLabel)
        
        tipTitleLabel.text = tip.title
        tipDescriptionLabel.text = tip.description

        tipTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.snp.centerY)
        }

        tipDescriptionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(self.view.snp.centerY)
        }

        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapTip)))
    }
    
    @objc private func tapTip() {
        tipTapped(tip)
    }
}
