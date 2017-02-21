#import "BTNModelObject.h"
#import "BTNText.h"
#import "BTNImage.h"

/**
 BTNListItem objects specify information for rendering an inventory item.
 */
@interface BTNListItem : BTNModelObject

/// The line item main text of the item.
@property (nullable, nonatomic, copy, readonly) BTNText *titleText;


/// Secondary text for the item.
@property (nullable, nonatomic, copy, readonly) BTNText *subtitleText;


/// Text to be rendered at the icon position (e.g. right aligned).
@property (nullable, nonatomic, copy, readonly) BTNText *iconText;


/// A small preview icon representing the item.
@property (nullable, nonatomic, copy, readonly) BTNImage *iconImage;

@end
