// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import UIKit

/// An enum representing different device types and their corresponding `ViewImageConfig` configurations.
enum DeviceType: String, CaseIterable {
    case iPhoneSE_Portrait
    case iPhoneSE_Landscape
    case iPhone16Pro_Portrait
    case iPhone16Pro_Landscape
    case iPhone16ProMax_Portrait
    case iPhone16ProMax_Landscape
    case iPadPro_Portrait
    case iPadPro_Landscape

    var config: ViewImageConfig {
        switch self {
        case .iPhoneSE_Portrait:
            return ViewImageConfig.iPhone8(.portrait)
        case .iPhoneSE_Landscape:
            return ViewImageConfig.iPhone8(.landscape)
        case .iPhone16Pro_Portrait:
            return ViewImageConfig.iPhone13Pro(.portrait)
        case .iPhone16Pro_Landscape:
            return ViewImageConfig.iPhone13Pro(.landscape)
        case .iPhone16ProMax_Portrait:
            return ViewImageConfig.iPhone13ProMax(.portrait)
        case .iPhone16ProMax_Landscape:
            return ViewImageConfig.iPhone13ProMax(.landscape)
        case .iPadPro_Portrait:
            return ViewImageConfig.iPadPro11(.portrait)
        case .iPadPro_Landscape:
            return ViewImageConfig.iPadPro11(.landscape)
        }
    }

    var name: String {
        switch self {
        case .iPhoneSE_Portrait, .iPhoneSE_Landscape:
            return "iPhone SE (3rd generation)"
        case .iPhone16Pro_Portrait, .iPhone16Pro_Landscape:
            return "iPhone 16 Pro"
        case .iPhone16ProMax_Portrait, .iPhone16ProMax_Landscape:
            return "iPhone 16 Pro Max"
        case .iPadPro_Portrait, .iPadPro_Landscape:
            return "iPad Pro 11-inch (M4)"
        }
    }

    /// Returns a `DeviceType` based on the provided device name and orientation.
    ///
    /// - Parameters:
    ///   - deviceName: The name of the device (e.g., "iPhone 8").
    ///   - orientation: The orientation of the device (e.g., "portrait").
    /// - Returns: The corresponding `DeviceType` or crashes 💥 if the combination is not supported.
    static func from(deviceName: String, orientation: String) -> DeviceType {
        switch (deviceName, orientation) {
        case ("iPhone SE (3rd generation)", "portrait"):
            return .iPhoneSE_Portrait
        case ("iPhone SE (3rd generation)", "landscape"):
            return .iPhoneSE_Landscape
        case ("iPhone 16 Pro", "portrait"):
            return .iPhone16Pro_Portrait
        case ("iPhone 16 Pro", "landscape"):
            return .iPhone16Pro_Landscape
        case ("iPhone 16 Pro Max", "portrait"):
            return .iPhone16ProMax_Portrait
        case ("iPhone 16 Pro Max", "landscape"):
            return .iPhone16ProMax_Landscape
        case ("iPad Pro 11-inch (M4)", "portrait"):
            return .iPadPro_Portrait
        case ("iPad Pro 11-inch (M4)", "landscape"):
            return .iPadPro_Landscape
        default:
            fatalError("Device Name \(deviceName) and Orientation \(orientation) not found. Please add them correctly.")
        }
    }
}

// From: https://github.com/pointfreeco/swift-snapshot-testing/pull/839

extension ViewImageConfig {

    // https://useyourloaf.com/blog/iphone-15-screen-sizes/
    public static let iPhone15 = ViewImageConfig.iPhone15(.portrait)

    public static func iPhone15(_ orientation: Orientation) -> ViewImageConfig {
        let safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 59, bottom: 21, right: 59)
            size = .init(width: 852, height: 393)
        case .portrait:
            safeArea = .init(top: 59, left: 0, bottom: 34, right: 0)
            size = .init(width: 393, height: 852)
        }

        return .init(safeArea: safeArea, size: size, traits: .iPhone15(orientation))
    }

    public static let iPhone15Plus = ViewImageConfig.iPhone15Plus(.portrait)

    public static func iPhone15Plus(_ orientation: Orientation) -> ViewImageConfig {
        let safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .init(top: 0, left: 59, bottom: 21, right: 59)
            size = .init(width: 932, height: 430)
        case .portrait:
            safeArea = .init(top: 59, left: 0, bottom: 34, right: 0)
            size = .init(width: 430, height: 932)
        }

        return .init(safeArea: safeArea, size: size, traits: .iPhone15Plus(orientation))
    }

    public static let iPhone15Pro = ViewImageConfig.iPhone15Pro(.portrait)

    public static func iPhone15Pro(_ orientation: Orientation) -> ViewImageConfig {
      let safeArea: UIEdgeInsets
      let size: CGSize
      switch orientation {
      case .landscape:
        safeArea = .init(top: 0, left: 59, bottom: 21, right: 59)
        size = .init(width: 852, height: 393)
      case .portrait:
        safeArea = .init(top: 59, left: 0, bottom: 34, right: 0)
         size = .init(width: 393, height: 852)
      }

      return .init(safeArea: safeArea, size: size, traits: .iPhone15Pro(orientation))
    }

    public static let iPhone15ProMax = ViewImageConfig.iPhone15ProMax(.portrait)

    public static func iPhone15ProMax(_ orientation: Orientation) -> ViewImageConfig {
      let safeArea: UIEdgeInsets
      let size: CGSize
      switch orientation {
      case .landscape:
        safeArea = .init(top: 0, left: 59, bottom: 21, right: 59)
        size = .init(width: 932, height: 430)
      case .portrait:
        safeArea = .init(top: 59, left: 0, bottom: 34, right: 0)
        size = .init(width: 430, height: 932)
      }

      return .init(safeArea: safeArea, size: size, traits: .iPhone15ProMax(orientation))
    }
}

extension UITraitCollection {

    public static func iPhone15(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        let base: [UITraitCollection] = [
          .init(forceTouchCapability: .unavailable),
          .init(layoutDirection: .leftToRight),
          .init(preferredContentSizeCategory: .medium),
          .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .regular),
              .init(verticalSizeClass: .compact)
            ]
          )
        case .portrait:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .compact),
              .init(verticalSizeClass: .regular)
            ]
          )
        }
      }

      public static func iPhone15Plus(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        let base: [UITraitCollection] = [
          .init(forceTouchCapability: .unavailable),
          .init(layoutDirection: .leftToRight),
          .init(preferredContentSizeCategory: .medium),
          .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .regular),
              .init(verticalSizeClass: .compact)
            ]
          )
        case .portrait:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .compact),
              .init(verticalSizeClass: .regular)
            ]
          )
        }
      }

      public static func iPhone15Pro(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        let base: [UITraitCollection] = [
          .init(forceTouchCapability: .unavailable),
          .init(layoutDirection: .leftToRight),
          .init(preferredContentSizeCategory: .medium),
          .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .regular),
              .init(verticalSizeClass: .compact)
            ]
          )
        case .portrait:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .compact),
              .init(verticalSizeClass: .regular)
            ]
          )
        }
      }

      public static func iPhone15ProMax(_ orientation: ViewImageConfig.Orientation) -> UITraitCollection {
        let base: [UITraitCollection] = [
          .init(forceTouchCapability: .unavailable),
          .init(layoutDirection: .leftToRight),
          .init(preferredContentSizeCategory: .medium),
          .init(userInterfaceIdiom: .phone)
        ]
        switch orientation {
        case .landscape:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .regular),
              .init(verticalSizeClass: .compact)
            ]
          )
        case .portrait:
          return .init(
            traitsFrom: base + [
              .init(horizontalSizeClass: .compact),
              .init(verticalSizeClass: .regular)
            ]
          )
        }
      }
}
