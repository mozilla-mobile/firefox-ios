/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private extension BlocklistName {
    var labelText: String {
        switch self {
        case .advertising: return UIConstants.strings.adTrackerLabel
        case .analytics: return UIConstants.strings.analyticTrackerLabel
        case .social: return UIConstants.strings.socialTrackerLabel
        case .content: return UIConstants.strings.contentTrackerLabel
        }
    }

    var color: UIColor {
        switch self {
        case .advertising: return UIColor(rgb: 0x8000D7)
        case .analytics: return UIColor(rgb: 0xED00B5)
        case .social: return UIColor(rgb: 0xD7B600)
        case .content: return UIColor(rgb: 0x00C8D7)
        }
    }
}

protocol TrackingProtectionSummaryDelegate: class {
    func trackingProtectionSummaryControllerDidToggleTrackingProtection(_ enabled: Bool)
    func trackingProtectionSummaryControllerDidTapClose(_ controller: TrackingProtectionSummaryViewController)
}

class TrackingProtectionBreakdownVisualizer: UIView {
    private let adSection = UIView()
    private let analyticSection = UIView()
    private let socialSection = UIView()
    private let contentSection = UIView()

    var trackingProtectionStatus = TrackingProtectionStatus.off {
        didSet {
            render(status: trackingProtectionStatus)
        }
    }

    convenience init() {
        self.init(frame: .zero)

        backgroundColor = UIConstants.colors.trackingProtectionBreakdownBackground

        adSection.backgroundColor = BlocklistName.advertising.color
        addSubview(adSection)

        analyticSection.backgroundColor = BlocklistName.analytics.color
        addSubview(analyticSection)

        socialSection.backgroundColor = BlocklistName.social.color
        addSubview(socialSection)

        contentSection.backgroundColor = BlocklistName.content.color
        addSubview(contentSection)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }

    private func render(status: TrackingProtectionStatus) {
        updateConstraints()

        switch status {
        case .on: showSections()
        case .off: hideSections()
        }
    }

    private func showSections() {
        adSection.isHidden = false
        analyticSection.isHidden = false
        socialSection.isHidden = false
        contentSection.isHidden = false
    }


    private func hideSections() {
        adSection.isHidden = true
        analyticSection.isHidden = true
        socialSection.isHidden = true
        contentSection.isHidden = true
    }

    override func updateConstraints() {
        super.updateConstraints()
        guard case .on(let info) = trackingProtectionStatus else { hideSections(); return }
        let calculateMultiplier: (Int) -> Double = { return $0 > 0 ? Double($0) / Double(info.total) : 0 }

        adSection.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(calculateMultiplier(info.adCount))
            make.leading.equalToSuperview()
        }

        analyticSection.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(calculateMultiplier(info.analyticCount))
            make.leading.equalTo(adSection.snp.trailing)
        }

        socialSection.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(calculateMultiplier(info.socialCount))
            make.leading.equalTo(analyticSection.snp.trailing)
        }

        contentSection.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(0).priority(500)
            make.width.equalToSuperview().multipliedBy(calculateMultiplier(info.contentCount))
            make.trailing.equalToSuperview().priority(500)
        }
    }
}

class TrackingProtectionBreakdownItem: UIView {
    private let indicatorView = UIView()
    private let titleLabel = SmartLabel()
    private let counterLabel = SmartLabel()

    override var intrinsicContentSize: CGSize { return CGSize(width: 0, height: 56) }

    convenience init(text: String, color: UIColor) {
        self.init(frame: .zero)

        indicatorView.backgroundColor = color
        indicatorView.layer.cornerRadius = 4
        addSubview(indicatorView)

        titleLabel.text = text
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = UIConstants.colors.trackingProtectionPrimary
        addSubview(titleLabel)

        counterLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        counterLabel.textColor = UIConstants.colors.trackingProtectionPrimary
        counterLabel.accessibilityIdentifier = "TrackingProtectionBreakdownItem.counterLabel"
        addSubview(counterLabel)

        indicatorView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(-4)
            make.width.equalTo(8)
        }

        let counterWidth = NSString(string: "1000").size(withAttributes: [NSAttributedStringKey.font: counterLabel.font]).width

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(indicatorView.snp.centerY)
            make.leading.equalTo(indicatorView.snp.trailing).offset(12)
            // Leave space on the right for the label to grow
            make.trailing.equalToSuperview().inset(counterWidth)
        }

        counterLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
    }

    func setCounter(to value: Int) {
        counterLabel.text = String(value)
        counterLabel.textColor = UIConstants.colors.trackingProtectionPrimary
    }

    func disable() {
        counterLabel.text = "--"
        counterLabel.textColor = UIConstants.colors.trackingProtectionBreakdownBackground
    }
}

class TrackingProtectionBreakdownView: UIView {
    private let titleLabel = SmartLabel()
    private let counterLabel = SmartLabel()
    private let breakdown = TrackingProtectionBreakdownVisualizer()
    private let adItem = TrackingProtectionBreakdownItem(text: UIConstants.strings.adTrackerLabel, color: BlocklistName.advertising.color)
    private let analyticItem = TrackingProtectionBreakdownItem(text: UIConstants.strings.analyticTrackerLabel, color: BlocklistName.analytics.color)
    private let contentItem = TrackingProtectionBreakdownItem(text: UIConstants.strings.contentTrackerLabel, color: BlocklistName.content.color)
    private let socialItem = TrackingProtectionBreakdownItem(text: UIConstants.strings.socialTrackerLabel, color: BlocklistName.social.color)
    private var stackView: UIStackView?
    private let learnMoreWrapper = UIView()
    fileprivate let learnMoreButton = UIButton()

    var trackingProtectionStatus = TrackingProtectionStatus.off {
        didSet {
            breakdown.trackingProtectionStatus = trackingProtectionStatus
            if case .on(let info) = trackingProtectionStatus {
                titleLabel.text = UIConstants.strings.trackersBlocked
                counterLabel.text = String(info.total)

                adItem.setCounter(to: info.adCount)
                analyticItem.setCounter(to: info.analyticCount)
                contentItem.setCounter(to: info.contentCount)
                socialItem.setCounter(to: info.socialCount)
            } else {
                titleLabel.text = UIConstants.strings.trackingProtectionDisabledLabel
                counterLabel.text = ""

                adItem.disable()
                analyticItem.disable()
                contentItem.disable()
                socialItem.disable()
            }
        }
    }

    convenience init() {
        self.init(frame: .zero)

        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = UIConstants.colors.trackingProtectionPrimary
        titleLabel.text = UIConstants.strings.trackersBlocked
        addSubview(titleLabel)

        counterLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        counterLabel.textColor = UIConstants.colors.trackingProtectionPrimary
        addSubview(counterLabel)
        
        addSubview(breakdown)

        let stackView = UIStackView(arrangedSubviews: [adItem, analyticItem, socialItem, contentItem])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        addSubview(stackView)
        self.stackView = stackView

        learnMoreButton.setTitle(UIConstants.strings.trackingProtectionLearnMore, for: .normal)
        learnMoreButton.setTitleColor(UIConstants.colors.trackingProtectionLearnMore, for: .normal)
        learnMoreButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        learnMoreButton.contentHorizontalAlignment = .leading
        learnMoreWrapper.addSubview(learnMoreButton)
        stackView.addArrangedSubview(learnMoreWrapper)

        setupConstraints()
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.top.equalToSuperview()
            make.leading.equalTo(safeAreaLayoutGuide).offset(16)
            make.trailing.equalTo(counterLabel.snp.leading)
        }

        counterLabel.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalToSuperview().offset(-16)
        }

        breakdown.snp.makeConstraints { make in
            make.height.equalTo(3)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.top.equalTo(titleLabel.snp.bottom)
        }

        stackView?.snp.makeConstraints { make in
            make.top.equalTo(breakdown.snp.bottom).offset(8)
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }

        stackView?.arrangedSubviews.forEach { view in
            view.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
        }

        learnMoreWrapper.snp.makeConstraints { make in
            make.height.equalTo(56)
            make.leading.trailing.equalToSuperview()
        }

        learnMoreButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.trailing.bottom.equalToSuperview()
        }
    }
}

class TrackingProtectionToggleView: UIView {
    private let icon = UIImageView(image: #imageLiteral(resourceName: "tracking_protection").imageFlippedForRightToLeftLayoutDirection())
    private let label = SmartLabel(frame: .zero)
    let toggle = UISwitch()
    private let borderView = UIView()
    private let descriptionLabel = SmartLabel()

    var trackingProtectionStatus = TrackingProtectionStatus.off {
        didSet {
            switch trackingProtectionStatus {
            case .on: toggle.isOn = true
            case .off: toggle.isOn = false
            }
        }
    }

    convenience init() {
        self.init(frame: .zero)

        icon.tintColor = .white
        addSubview(icon)

        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.text = UIConstants.strings.trackingProtectionToggleLabel
        label.textColor = UIConstants.colors.trackingProtectionPrimary
        addSubview(label)

        toggle.onTintColor = UIConstants.colors.toggleOn
        toggle.accessibilityIdentifier = "TrackingProtectionToggleView.toggleTrackingProtection"
        addSubview(toggle)

        borderView.backgroundColor = UIConstants.colors.settingsSeparator
        addSubview(borderView)

        descriptionLabel.text = String(format: UIConstants.strings.trackingProtectionToggleDescription, AppInfo.productName)
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIConstants.colors.trackingProtectionSecondary
        descriptionLabel.numberOfLines = 2
        addSubview(descriptionLabel)
        setupConstraints()
    }

    private func setupConstraints() {
        icon.snp.makeConstraints { make in
            make.height.width.equalTo(24)
            make.leading.equalTo(safeAreaLayoutGuide).offset(16)
            make.centerY.equalToSuperview()
        }

        label.snp.makeConstraints {make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(toggle.snp.leading).offset(-8)
        }

        toggle.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(safeAreaLayoutGuide).offset(-16)
        }

        toggle.setContentCompressionResistancePriority(.required, for: .horizontal)

        borderView.snp.makeConstraints { make in
            make.top.equalTo(toggle.snp.bottom).offset(8)
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide).offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(borderView.snp.bottom).offset(8)
        }
    }
}

class TrackingProtectionView: UIView {
    fileprivate let closeButton = UIButton()
    fileprivate let scrollView = UIScrollView()
    fileprivate let toggleView = TrackingProtectionToggleView()
    fileprivate let breakdownView = TrackingProtectionBreakdownView()

    var toggle: UISwitch { return toggleView.toggle }
    var learnMoreButton: UIButton { return breakdownView.learnMoreButton }

    var trackingProtectionStatus = TrackingProtectionStatus.off {
        didSet {
            toggleView.trackingProtectionStatus = trackingProtectionStatus
            breakdownView.trackingProtectionStatus = trackingProtectionStatus
        }
    }

    convenience init() {
        self.init(frame: .zero)
        backgroundColor = UIConstants.colors.background

        closeButton.setImage(#imageLiteral(resourceName: "icon_stop_menu"), for: .normal)
        closeButton.accessibilityIdentifier = "TrackingProtectionView.closeButton"
        addSubview(closeButton)
        addSubview(scrollView)

        scrollView.addSubview(toggleView)
        scrollView.addSubview(breakdownView)

        setupConstraints()
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints { make in
            make.height.width.equalTo(24)
            make.top.equalTo(safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(UIConstants.layout.urlBarHeight)
            make.width.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }

        toggleView.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.top.equalToSuperview().offset(76 - UIConstants.layout.urlBarHeight)
            make.leading.trailing.equalTo(self)
        }

        breakdownView.snp.makeConstraints { make in
            make.top.equalTo(toggleView.snp.bottom).offset(40)
            make.leading.trailing.equalTo(self)
            make.bottom.equalToSuperview()
        }
    }
}

class TrackingProtectionSummaryViewController: UIViewController {
    weak var delegate: TrackingProtectionSummaryDelegate?
    
    var trackingProtectionStatus = TrackingProtectionStatus.on(TPPageStats()) {
        didSet {
            trackingProtectionView.trackingProtectionStatus = trackingProtectionStatus
        }
    }

    private let trackingProtectionView = TrackingProtectionView()
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        trackingProtectionView.closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        trackingProtectionView.toggle.addTarget(self, action: #selector(didToggle(sender:)), for: .touchUpInside)
        trackingProtectionView.learnMoreButton.addTarget(self, action: #selector(didTapLearnMore(sender:)), for: .touchUpInside)
    }

    override func loadView() {
        self.view = trackingProtectionView
    }

    @objc private func didTapLearnMore(sender: UIButton) {
        guard let url = SupportUtils.URLForTopic(topic: "tracking-protection-focus-ios") else { return }
        let contentViewController = SettingsContentViewController(url: url)
        let navigationController = UINavigationController(rootViewController: contentViewController)
        let navigationBar = navigationController.navigationBar
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = UIConstants.colors.background
        navigationBar.tintColor = UIConstants.colors.navigationButton
        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIConstants.colors.navigationTitle]

        let button = UIBarButtonItem(image: #imageLiteral(resourceName: "icon_stop_menu"), landscapeImagePhone: #imageLiteral(resourceName: "icon_stop_menu"), style: .done, target: self, action: #selector(closeModal))

        contentViewController.navigationItem.rightBarButtonItem = button
        present(navigationController, animated: true, completion: nil)
    }

    @objc private func closeModal() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func didToggle(sender: UISwitch) {
        delegate?.trackingProtectionSummaryControllerDidToggleTrackingProtection(sender.isOn)
    }

    @objc private func didTapClose() {
        delegate?.trackingProtectionSummaryControllerDidTapClose(self)
    }
}
