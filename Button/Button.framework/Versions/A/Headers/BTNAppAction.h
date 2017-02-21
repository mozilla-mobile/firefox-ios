#import "BTNModelObject.h"
#import "BTNAppActionMeta.h"
#import "BTNPreview.h"
#import "BTNHeader.h"
#import "BTNGroup.h"
#import "BTNProduct.h"
#import "BTNFooter.h"

/// Enum represening result of `-appInstallState`.
typedef NS_ENUM(NSUInteger, BTNAppInstallState) {
    BTNAppInstallStateUnknown = 0,
    BTNAppInstallStateInstalled,
    BTNAppInstallStateNotInstalled,
    BTNAppInstallStateNotQueryable
};

/**
 An App Action represents a button (i.e. “preview”) and inventory typically rendered as a “commerce card”.
 */

@interface BTNAppAction : BTNModelObject

/// App action metadata (id, source token, expiry, etc).
@property (nullable, nonatomic, copy, readonly) BTNAppActionMeta *meta;


/// The button preview data.
@property (nullable, nonatomic, copy, readonly) BTNPreview *preview;


/// Heading information for the inventory.
@property (nullable, nonatomic, strong, readonly) BTNHeader *header;


/// Grouped inventory (note: one of `groups` or `product` will be non-nil).
@property (nullable, nonatomic, strong, readonly) NSArray<BTNGroup *> *groups;


/// A single product representation (note: one of `groups` or `product` will be non-nil).
@property (nullable, nonatomic, strong, readonly) BTNProduct *product;


/// Footer information for the inventory and default action.
@property (nullable, nonatomic, strong, readonly) BTNFooter *footer;



///-----------------------
/// @name Invoking Actions
///-----------------------


/**
 Invokes the Button commerce card flow or a preview action if one exists.
 @discussion For integrations that only customize the button preview, call 
 this method when a user taps your custom button preview.
 @see @c -invokeActionForListItem: If you've built out your own custom inventory UI.
 
 @note Users will be sent to the destination application or through the
 Attended Install flow if the destination application is not installed.
 */
- (void)invokePreviewAction;


/**
 Invokes the action of a specific inventory list item.
 @discussion If you've built out your own custom inventory UI, call this 
 method when a user taps a specific inventory item.
 
 @note Users will be sent to the destination application or through the
 Attended Install flow if the destination application is not installed.
 */
- (void)invokeActionForListItem:(nonnull BTNListItem *)listItem;


/**
 Invokes the footer action (i.e. default action).
 @discussion If your custom inventory UI includes BTNFooter data, call this
 method when you user taps on your custom footer view.

 @note Users will be sent to the destination application or through the 
 Attended Install flow if the destination application is not installed.
 */
- (void)invokeFooterAction;



///-----------------------------
/// @name Fetching Preview Image
///-----------------------------


/**
 Fetches the preview icon image data from the `preview.iconImage.URL` or the local cache.
 @param completionHandler A block to be executed once the image data has loaded.
 @note The completionHandler takes one argument, a UIImage or nil if an error occurred.
 */
- (void)fetchPreviewIconImageWithCompletion:(nonnull void(^)(UIImage * __nullable image))completionHandler;



///------------------------
/// @name App Install State
///------------------------


/**
 Determines whether the target app is installed, not installed or not queryable.
 @return BTNInstallStateNotInstalled if target application is NOT installed.
         BTNInstallStateInstalled    if target application is installed.
         BTNInstallStateNotQueryable if app scheme was not declared in LSApplicationQueriesSchemes of Info.plist (>= iOS9).
 */
- (BTNAppInstallState)appInstallState;



///---------------------
/// @name Event Tracking
///---------------------


/**
 Tracks a "button viewed" event each time this method is called.
 @note Invoke this method when your custom button is displayed to the user.
 @discussion Used to measure performance so make sure you report at the same
             interval across iOS and Android. We suggest that you report this
             right after you've configured your UI with the AppAction if those
             views will be visible.
 */
- (void)trackButtonViewed;

@end
