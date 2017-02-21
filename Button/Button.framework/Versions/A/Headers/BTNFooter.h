#import "BTNModelObject.h"
#import "BTNBackground.h"
#import "BTNImage.h"
#import "BTNText.h"

/**
 BTNFooter objects specify footer information about inventory and a default action that may be executed.
 */
@interface BTNFooter : BTNModelObject

/// The footer text.
@property (nullable, nonatomic, copy, readonly) BTNText *labelText;


/// An icon image.
@property (nullable, nonatomic, copy, readonly) BTNImage *iconImage;


/// The footer background.
@property (nullable, nonatomic, copy, readonly) BTNBackground *background;

@end
