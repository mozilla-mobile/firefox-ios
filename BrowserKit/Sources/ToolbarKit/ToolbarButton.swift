//
//  File.swift
//  
//
//  Created by Winnie Teichmann on 2024-03-22.
//

import Common
import UIKit

class ToolbarButton: UIButton, ThemeApplicable {
    public struct UX {
        public static let verticalInset: CGFloat = 8
        public static let horizontalInset: CGFloat = 8
    }

    var foregroundColorNormal: UIColor = .clear
    var foregroundColorHighlighted: UIColor = .clear
    var foregroundColorDisabled: UIColor = .clear
    var backgroundColorNormal: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        configuration = UIButton.Configuration.plain()
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                               leading: UX.horizontalInset,
                                                               bottom: UX.verticalInset,
                                                               trailing: UX.horizontalInset)
    }

    open func configure(element: ToolbarElement) {
        guard let config = configuration else {
            return
        }
        var updatedConfiguration = config

        let image = UIImage(named: element.iconName)?.withRenderingMode(.alwaysTemplate)
        let action = UIAction(title: element.a11yLabel,
                              image: image,
                              handler: { _ in
            guard let closure = element.onSelected else { return }
            closure()
        })

        updatedConfiguration.image = image
        accessibilityIdentifier = element.a11yId
        accessibilityLabel = element.a11yLabel
        addAction(action, for: .touchUpInside)

        showsLargeContentViewer = true
        largeContentTitle = element.a11yLabel
        largeContentImage = image

        configuration = updatedConfiguration
        layoutIfNeeded()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfiguration() {
        guard var updatedConfiguration = configuration else {
            return
        }

        switch state {
        case [.highlighted]:
            updatedConfiguration.baseForegroundColor = foregroundColorHighlighted
        case [.disabled]:
            updatedConfiguration.baseForegroundColor = foregroundColorDisabled
        default:
            updatedConfiguration.baseForegroundColor = foregroundColorNormal
        }

        updatedConfiguration.background.backgroundColor = backgroundColorNormal
        configuration = updatedConfiguration
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        foregroundColorNormal = theme.colors.iconPrimary
        foregroundColorHighlighted = theme.colors.iconPrimary
        foregroundColorDisabled = theme.colors.iconDisabled
        backgroundColorNormal = .clear
        setNeedsUpdateConfiguration()
    }

}
