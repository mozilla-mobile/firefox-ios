@import UIKit;

@interface BTNView : UIView

/**
 Indicates whether the view should ignore a clear color background.
 @discussion Default is NO. Set to YES to prevent the background color from being set to clearColor by Apple
 when used as a subview of a highlightable UITableViewCell.
 */
@property (nonatomic, assign, getter = shouldForceOpacity) BOOL forceOpacity;


/**
 Initializes the view. Called from -initWithFrame: and -initWithCoder:
 @discussion You should never call this method directly. Subclasses can override this method to initialize subviews.
 @note You must call super in your implementation.
 */
- (void)initializeView NS_REQUIRES_SUPER;


/**
 Indicates whether the constraints need updating.
 @discussion Subclasses can override this method to return whether a constraint pass should occur. 
 The default implementation returns YES if the views bounds have changed since the last constraint pass.
 @note You must call super in your implementation.
 
 @code
 - (BOOL)shouldUpdateConstraints {
    return [super shouldUpdateConstraints] || self.currentIndicator != self.newIndicator;
 }
 @endcode
 */
- (BOOL)shouldUpdateConstraints NS_REQUIRES_SUPER;


/**
 Indicates whether the view is currently visible on the screen.
 @discussion This method will return YES if the view's frame, converted to the logical coordinate system of the screen, is contained by the screen bounds and the view and its window have an alpha greater than 0.0 and are not hidden.
 @note There are a couple caveats. 1) The method does not take into account any of its ancestors hidden or alpha values. 2) The method does not take into account whether the view is obscured by another view.
 */
- (BOOL)isVisible NS_REQUIRES_SUPER;


/**
 Notifies the view that it is about to appear in the view heirarchy.
 @discussion You should never call this method directly. Subclasses can override this method to be notified 
 that the view is about to be added to the view heirarchy.
 @note You must call super in your implementation.
 */
- (void)willAppear NS_REQUIRES_SUPER;


/**
 Notifies the view that it has appeared in the view heirarchy.
 @discussion You should never call this method directly. Subclasses can override this method to be notified
 that the view has been added to the view heirarchy.
 @note You must call super in your implementation.
 */
- (void)didAppear NS_REQUIRES_SUPER;


/**
 Notifies the view that it is about to be removed from a view hierarchy.
 @discussion You should never call this method directly. Subclasses can override this method to be notified
 that the view is about to be removed from the view heirarchy.
 @note You must call super in your implementation.
 */
- (void)willDisappear NS_REQUIRES_SUPER;


/**
 Notifies the view that it has been removed from a view hierarchy.
 @discussion You should never call this method directly. Subclasses can override this method to be notified
 that the view has been removed from the view heirarchy.
 @note You must call super in your implementation.
 */
- (void)didDisappear NS_REQUIRES_SUPER;

@end
