#import "BTNModelObject.h"
#import "BTNListItem.h"
#import "BTNText.h"

/**
 BTNGroup objects specify information for rendering an inventory group.
 */
@interface BTNGroup : BTNModelObject

/// The title of the group.
@property (nullable, nonatomic, copy, readonly) BTNText *titleText;

/// An array of items in the group.
@property (nullable, nonatomic, copy, readonly) NSArray <BTNListItem *> *items;

@end
