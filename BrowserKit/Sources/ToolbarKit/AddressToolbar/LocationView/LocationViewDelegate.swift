// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// `LocationViewDelegate` protocol defines the delegate methods that respond
/// to user interactions with a location view.
protocol LocationViewDelegate: AnyObject {
    /// Called when the user enters text into the location view.
    ///
    /// - Parameter text: The text that was entered.
    func locationViewDidEnterText(_ text: String)

    /// Called when the user begins editing text in the location view.
    ///
    /// - Parameter text: The initial text in the location view when the user began editing.
    func locationViewDidBeginEditing(_ text: String)

    /// Called when the location view should perform a search based on the entered text.
    ///
    /// - Parameter text: The text for which the location view should search.
    func locationViewShouldSearchFor(_ text: String)

    /// Called when requesting custom accessibility actions to be performed on the location view.
    ///
    /// - Returns: An optional array of `UIAccessibilityCustomAction` objects.
    /// Return `nil` if no custom actions are provided.
    func locationViewAccessibilityActions() -> [UIAccessibilityCustomAction]?
}
