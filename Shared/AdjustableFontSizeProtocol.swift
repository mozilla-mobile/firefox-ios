//
//  AdjustableFontSizeProtocol.swift
//  Client
//
//  Created by Mykola Aleshchenko on 07.10.2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import UIKit

public protocol AdjustableFontSizeProtocol: UIView {
    func adjustFonts()
    func resize(size: CGFloat)
}

public extension AdjustableFontSizeProtocol {
    func adjustFonts() {
        let size = traitCollection.preferredContentSizeCategory
        switch size {
        case let size where size >= .accessibilityMedium:
            resize(size: 25)
        case let size where size <= .extraExtraExtraLarge && size > .extraLarge:
            resize(size: 15)
        case let size where size >= .large && size <= .extraLarge:
            resize(size: 14)
        case let size where size == .medium:
            resize(size: 12)
        case let size where size >= .extraSmall && size <= .small:
            resize(size: 8)
        default:
            resize(size: UIFont.systemFontSize)
        }
    }
}
