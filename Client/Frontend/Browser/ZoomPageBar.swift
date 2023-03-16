// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

protocol ZoomPageBarDelegate: AnyObject {
    func zoomPageDidPressClose()
}

class ZoomPageBar: UIView {
    struct UX {
        static let leadingTrailingPadding: CGFloat = 26
        static let topBottomPadding: CGFloat = 18
        static let stepperWidth: CGFloat = 222
        static let stepperHeight: CGFloat = 36
        static let stepperLeadingTrailingMargin: CGFloat = 12
        static let stepperTopBottomMargin: CGFloat = 6
        static let fontSize: CGFloat = 16
        static let lowerZoomLimit: CGFloat = 0.5
        static let upperZoomLimit: CGFloat = 2.0
    }

    weak var delegate: ZoomPageBarDelegate?

    var tab: Tab
    var isIpad: Bool

    private let stepperContainer: UIStackView = .build { view in
        view.axis = .horizontal
        view.alignment = .center
        view.distribution = .fillProportionally
        view.layer.cornerRadius = 8
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.layer.shadowOpacity = 1
        view.clipsToBounds = false
    }

    private let zoomOutButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.subtract), for: [])
        button.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomOutButton
        button.contentEdgeInsets = UIEdgeInsets(top: UX.stepperTopBottomMargin,
                                                left: UX.stepperLeadingTrailingMargin,
                                                bottom: UX.stepperTopBottomMargin,
                                                right: UX.stepperLeadingTrailingMargin)
    }

    private let zoomInButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.add), for: [])
        button.accessibilityIdentifier = AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomInButton
        button.contentEdgeInsets = UIEdgeInsets(top: UX.stepperTopBottomMargin,
                                                left: UX.stepperLeadingTrailingMargin,
                                                bottom: UX.stepperTopBottomMargin,
                                                right: UX.stepperLeadingTrailingMargin)
    }

    private let zoomLevel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .callout,
                                                                       size: UX.fontSize)
        label.isUserInteractionEnabled = true
    }

    private let gestureRecognizer = UITapGestureRecognizer()

    private let closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(ImageIdentifiers.xMark), for: [])
        button.accessibilityLabel = .FindInPageDoneAccessibilityLabel
        button.accessibilityIdentifier = AccessibilityIdentifiers.FindInPage.findInPageCloseButton
    }

    init(tab: Tab, isIpad: Bool) {
        self.tab = tab
        self.isIpad = isIpad

        super.init(frame: .zero)

        setupViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        zoomInButton.addTarget(self, action: #selector(didPressZoomIn), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(didPressZoomOut), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(didPressClose), for: .touchUpInside)

        gestureRecognizer.addTarget(self, action: #selector(didPressReset))
        zoomLevel.addGestureRecognizer(gestureRecognizer)

        updateZoomLabel()

        if tab.pageZoom <= UX.lowerZoomLimit {
            zoomInButton.isEnabled = false
        }

        [zoomOutButton, zoomLevel, zoomInButton].forEach {
            stepperContainer.addArrangedSubview($0)
        }

        addSubviews(stepperContainer, closeButton)
    }

    func setupLayout() {
        if isIpad {
            stepperContainer.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        } else {
            stepperContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.leadingTrailingPadding).isActive = true
        }

        NSLayoutConstraint.activate([
            stepperContainer.heightAnchor.constraint(equalToConstant: UX.stepperHeight),
            stepperContainer.widthAnchor.constraint(equalToConstant: UX.stepperWidth),
            stepperContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            zoomInButton.centerYAnchor.constraint(equalTo: stepperContainer.centerYAnchor),
            zoomOutButton.centerYAnchor.constraint(equalTo: stepperContainer.centerYAnchor),
            zoomLevel.leadingAnchor.constraint(equalTo: zoomOutButton.trailingAnchor, constant: UX.stepperLeadingTrailingMargin),
            zoomLevel.trailingAnchor.constraint(equalTo: zoomInButton.leadingAnchor, constant: -UX.stepperLeadingTrailingMargin),
            zoomLevel.centerYAnchor.constraint(equalTo: stepperContainer.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.leadingTrailingPadding),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func updateZoomLabel() {
        zoomLevel.text = String(format: "%.0f%%", tab.pageZoom * 100.0)
        gestureRecognizer.isEnabled = !(tab.pageZoom == 1.0)
    }

    @objc private func didPressZoomIn(_ sender: UIButton) {
        tab.zoomIn()
        updateZoomLabel()

        zoomOutButton.isEnabled = true
        if tab.pageZoom >= UX.upperZoomLimit {
            zoomInButton.isEnabled = false
        }
    }

    @objc private func didPressZoomOut(_ sender: UIButton) {
        tab.zoomOut()
        updateZoomLabel()

        zoomInButton.isEnabled = true
        if tab.pageZoom <= UX.lowerZoomLimit {
            zoomOutButton.isEnabled = false
        }
    }

    @objc private func didPressReset(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .began {
            tab.resetZoom()
            updateZoomLabel()
        }
    }

    @objc private func didPressClose(_ sender: UIButton) {
        delegate?.zoomPageDidPressClose()
    }
}

extension ZoomPageBar: ThemeApplicable {
    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer1
        stepperContainer.backgroundColor = theme.colors.layer5
        stepperContainer.layer.shadowColor = theme.colors.shadowDefault.cgColor

        zoomLevel.tintColor = theme.colors.textPrimary

        zoomInButton.tintColor = zoomInButton.isEnabled ? theme.colors.iconPrimary : theme.colors.iconDisabled
        zoomOutButton.tintColor = zoomOutButton.isEnabled ? theme.colors.iconPrimary : theme.colors.iconDisabled
        closeButton.tintColor = theme.colors.iconPrimary
    }
}
