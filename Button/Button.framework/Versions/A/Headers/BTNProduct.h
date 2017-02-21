#import "BTNModelObject.h"
#import "BTNBackground.h"
#import "BTNImage.h"
#import "BTNText.h"

/**
 BTNProduct objects specify information about rendering a single product.
 */

@interface BTNProduct : BTNModelObject

/// The card background.
@property (nullable, nonatomic, copy, readonly) BTNBackground *background;


/// An array of product images.
@property (nullable, nonatomic, copy, readonly) NSArray <BTNImage *> *images;


/// The main title text.
@property (nullable, nonatomic, copy, readonly) BTNText *titleText;


/// Secondary text representing the item.
@property (nullable, nonatomic, copy, readonly) BTNText *subtitleText;


/// A potentially multi-line description text.
@property (nullable, nonatomic, copy, readonly) BTNText *descriptionText;

@end
