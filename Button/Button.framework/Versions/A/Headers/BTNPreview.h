#import "BTNModelObject.h"
#import "BTNBackground.h"
#import "BTNImage.h"
#import "BTNText.h"

/**
 This class represents the data for rendering a button “preview”.
 BTNPreview objects specify information about how a button should appear and behave.
 */
@interface BTNPreview : BTNModelObject

/// An optional title text.
@property (nullable, nonatomic, copy, readonly) BTNText *titleText;


/// The button text.
@property (nullable, nonatomic, copy, readonly) BTNText *labelText;


/// The background fill details of the button.
@property (nullable, nonatomic, copy, readonly) BTNBackground *background;


/// An icon image to be renderd on the button.
@property (nullable, nonatomic, copy, readonly) BTNImage *iconImage;

@end
