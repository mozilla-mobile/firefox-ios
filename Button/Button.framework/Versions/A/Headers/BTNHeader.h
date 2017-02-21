#import "BTNModelObject.h"
#import "BTNBackground.h"
#import "BTNText.h"

/**
 BTNHeader objects specify heading information about inventory.
 */
@interface BTNHeader : BTNModelObject

/// The main heading text.
@property (nullable, nonatomic, copy, readonly) BTNText *titleText;


/// An optional smaller subheading text.
@property (nullable, nonatomic, copy, readonly) BTNText *subtitleText;


/// The header background.
@property (nullable, nonatomic, copy, readonly) BTNBackground *background;

@end
