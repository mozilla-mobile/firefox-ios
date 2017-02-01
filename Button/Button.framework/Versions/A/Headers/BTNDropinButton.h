#import "BTNView.h"
#import "BTNDropinButtonAppearanceProtocol.h"
#import "BTNContext.h"
#import "BTNDropinButton_Deprecated.h"

@class BTNAppAction;

@interface BTNDropinButton : UIControl <BTNDropinButtonDeprecated, BTNDropinButtonAppearance>

///------------------------------
/// @name Rendering an App Action
///------------------------------


/**
 Tells the button to render the passed app action.
 @param appAction A BTNAppAction loaded via `-[Button fetchAppActionWithButtonId:context:completion:]`
 @note passing nil will return the button to the loading state.
 */
- (void)prepareWithAppAction:(nullable BTNAppAction *)appAction;


///-----------------
/// @name Appearance
///-----------------

/**
 BTNDropinButton conforms to BTNDropinButtonAppearance.
 For appearance properties @see BTNDropinButtonAppearance
 */

@end
