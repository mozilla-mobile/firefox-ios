// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common

enum UX {
    enum CardView {
        static let baseWidth: CGFloat = 375
        static let baseHeight: CGFloat = 812
        static let landscapeWidthRatio: CGFloat = 0.75
        static let portraitWidthRatio: CGFloat = 0.7
        static let maxWidth: CGFloat = 508
        static let landscapeHeightRatio: CGFloat = 0.85
        static let portraitHeightRatio: CGFloat = 0.7
        static let maxHeight: CGFloat = 712

        static func cardSecondaryContainerPadding(for sizeCategory: ContentSizeCategory) -> CGFloat {
            switch sizeCategory {
            case .accessibilityExtraExtraExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraLarge:
                return 0
            default:
                return 32
            }
        }
        static let titleCompactTopPadding: CGFloat = 40.0
        static let titleTopPadding: CGFloat = 80
        static let contentSpacing: CGFloat = 34.0
        static let buttonsSpacing: CGFloat = 10.0
        static let buttonsBottomPadding: CGFloat = 16.0
        static let minContentSpacing: CGFloat = 20.0

        static let titleAlignmentMinHeightPadding: CGFloat = 80
        static let cardHorizontalPadding: CGFloat = 16.0
        static let spacing: CGFloat = 24
        static let regularSizeSpacing: CGFloat = 48
        static let tosSpacing: CGFloat = 48
        static let pageControlHeight: CGFloat = 20
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 24
        static let imageHeight: CGFloat = 150
        static let maxImageHeight: CGFloat = 250
        static let tosImageHeight: CGFloat = 70
        static let cornerRadius: CGFloat = 20
        static let secondaryButtonBottomPadding: CGFloat = 24
        static let primaryButtonWidthiPad: CGFloat = 313
        static let cardTopPadding: CGFloat = 20.0
        static let cardBottomPadding: CGFloat = 60.0
        static let carouselDotBottomPadding: CGFloat = 16

        // Font sizes for base metrics
        static let titleFontSize: CGFloat = 28
        static let bodyFontSize: CGFloat = 16

        static let titleFont = FXFontStyles.Bold.title1.scaledSwiftUIFont()
        static let titleFontRegular = FXFontStyles.Regular.title1.scaledSwiftUIFont()
        static let bodyFont = FXFontStyles.Regular.subheadline.scaledSwiftUIFont()
        // TODO: FXIOS-14022 Check Japanese alignment depeding on the experiment branch
        static func isJapanLocale(languageCode: String? = Locale.current.languageCode) -> Bool {
            languageCode == "ja"
        }

        static func titleFont(forLanguageCode languageCode: String? = Locale.current.languageCode) -> DynamicFont {
            isJapanLocale(languageCode: languageCode) ? titleFontRegular : titleFont
        }

        static func textAlignment(forLanguageCode languageCode: String? = Locale.current.languageCode) -> TextAlignment {
            isJapanLocale(languageCode: languageCode) ? .leading : .center
        }

        static func horizontalAlignment(
            forLanguageCode languageCode: String? = Locale.current.languageCode
        ) -> HorizontalAlignment {
            isJapanLocale(languageCode: languageCode) ? .leading : .center
        }

        static func frameAlignment(forLanguageCode languageCode: String? = Locale.current.languageCode) -> Alignment {
            isJapanLocale(languageCode: languageCode) ? .leading : .center
        }

        static func linksTextAlignment(for variant: OnboardingVariant) -> TextAlignment {
            return (variant == .brandRefresh || isJapanLocale()) ? .leading : .center
        }

        static func linksHorizontalAlignment(for variant: OnboardingVariant) -> HorizontalAlignment {
            return (variant == .brandRefresh || isJapanLocale()) ? .leading : .center
        }

        static func tosImageHeight(for variant: OnboardingVariant) -> CGFloat {
            if variant == .brandRefresh {
                return 180
            } else {
                return tosImageHeight
            }
        }

        static let primaryActionFont = FXFontStyles.Bold.callout.scaledSwiftUIFont()
        static let primaryActionGlassFont = FXFontStyles.Bold.headline.scaledSwiftUIFont()
        static let secondaryActionFont = FXFontStyles.Bold.callout.scaledSwiftUIFont()
    }

    enum SegmentedControl {
        static let outerVStackSpacing: CGFloat = 20
        static let innerVStackSpacing: CGFloat = 6
        static let imageHeight: CGFloat = 150
        static let verticalPadding: CGFloat = 10
        static let checkmarkFontSize: CGFloat = 20
        static let selectedColorOpacity: CGFloat = 0.8
        static let buttonMinHeight: CGFloat = 140
        static let textAreaMinHeight: CGFloat = 60
        static let containerSpacing: CGFloat = 0
    }

    struct Onboarding {
        struct Spacing {
            static let standard: CGFloat = 20
            static let small: CGFloat = 10
            static let contentPadding: CGFloat = 24
            static let buttonHeight: CGFloat = 44
            static let vertical: CGFloat = 16
        }

        struct Font {
            static let skipButtonSizeCap: CGFloat = 23
        }

        struct Layout {
            static let logoSize = CGSize(width: 150, height: 150)
            static let buttonCornerRadius: CGFloat = 12
        }
    }

    struct LaunchScreen {
        struct Logo {
            static let rotationDuration: TimeInterval = 2.0
            static let rotationAngle: Double = .pi * 2.0
            static let animationKey = "rotationAnimation"
            static let animationKeyPath = "transform.rotation.z"
        }
    }

    enum Button {
        static let verticalPadding: CGFloat = 12
        static let verticalGlassPadding: CGFloat = 6
        static let horizontalPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 8
        static let glassCornerRadius: CGFloat = 25
    }

    enum Image {
        static let welcomeBrandRefreshName = "onboardingWelcomeBrandRefresh"

        static func tosImage(for variant: OnboardingVariant, fallback: UIImage?) -> UIImage? {
            if variant == .brandRefresh {
                return UIImage(named: welcomeBrandRefreshName, in: .module, with: nil)
            }
            return fallback
        }
    }
}
