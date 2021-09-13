import UIKit

class ShareTrackersViewController: UIViewController {
    
    private let trackerTitle: String
    private let shareTap: (UIButton) -> ()
    init(trackerTitle: String, shareTap: @escaping (UIButton) -> ()) {
        self.trackerTitle = trackerTitle
        self.shareTap = shareTap
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var trackerStatsLabel: SmartLabel = {
        let trackerStatsLabel = SmartLabel()
        trackerStatsLabel.font = UIConstants.fonts.shareTrackerStatsLabel
        trackerStatsLabel.textColor = UIConstants.colors.defaultFont
        trackerStatsLabel.numberOfLines = 0
        trackerStatsLabel.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        trackerStatsLabel.setContentHuggingPriority(.required, for: .horizontal)
        trackerStatsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return trackerStatsLabel
    }()
    
    private lazy var shieldLogo: UIImageView = {
        let shieldLogo = UIImageView()
        shieldLogo.image = #imageLiteral(resourceName: "tracking_protection")
        shieldLogo.tintColor = UIColor.white
        return shieldLogo
    }()
    
    private lazy var trackerStatsShareButton: UIButton = {
        var button = UIButton()
        button.setTitleColor(UIConstants.colors.defaultFont, for: .normal)
        button.titleLabel?.font = UIConstants.fonts.shareTrackerStatsLabel
        button.titleLabel?.textAlignment = .center
        button.setTitle(UIConstants.strings.share, for: .normal)
        button.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        button.titleLabel?.numberOfLines = 0
        button.layer.borderColor = UIConstants.colors.defaultFont.cgColor
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 4
        return button
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [shieldLogo, trackerStatsLabel, trackerStatsShareButton])
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.axis = .horizontal
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(stackView)
        trackerStatsLabel.text = trackerTitle
        trackerStatsShareButton.snp.makeConstraints {
            $0.width.equalTo(80)
            $0.height.equalTo(30)
        }
        shieldLogo.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        stackView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
        }
    }
    
    @objc private func shareTapped(sender: UIButton) {
        shareTap(sender)
    }
}
