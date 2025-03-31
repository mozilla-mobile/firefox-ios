// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public protocol BasicAnimationControllerDelegate: AnyObject {
  /// Animate the presentation of a controller
  ///
  /// - parameter context: The transitioning context
  func animatePresentation(context: UIViewControllerContextTransitioning)

  func animateDismissal(context: UIViewControllerContextTransitioning)
}

/// Defines an animation controller which simply redirects presentation/dismissal animations to its delegate.
///
/// This allows us to create complex animations within the controller which needs to be animated without having to mark
/// state for whether or not its being dismissed or presented.
///
/// It also allows us to access private variables/properties without having to expose them to the animation controller.
public class BasicAnimationController: NSObject {
  /// The animation direction
  public enum Direction {
    /// The controller is being presented
    case presenting
    /// The controller is being dismissed
    case dismissing
  }

  /// Whether or not this animation controller is being used for presentation or dismissal
  public let direction: Direction

  /// The controller to handle animating
  private(set) weak var delegate: BasicAnimationControllerDelegate?

  public init(delegate: BasicAnimationControllerDelegate, direction: Direction) {
    self.direction = direction
    self.delegate = delegate
  }
}

extension BasicAnimationController: UIViewControllerAnimatedTransitioning {
  public func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?
  ) -> TimeInterval {
    return 0.2
  }

  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    switch direction {
    case .presenting:
      delegate?.animatePresentation(context: transitionContext)
    case .dismissing:
       delegate?.animateDismissal(context: transitionContext)
    }
  }
}
