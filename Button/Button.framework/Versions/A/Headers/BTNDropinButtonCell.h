@import UIKit;
#import "BTNDropinButton.h"
#import "BTNDropinButtonCell_Deprecated.h"

@class BTNDropinButton;

@interface BTNDropinButtonCell : UITableViewCell <BTNDropinButtonCellDeprecated, BTNDropinButtonAppearance>

/// The dropin button that displays the use case action (e.g. Get a ride).
@property (nullable, nonatomic, strong) IBOutlet BTNDropinButton *dropinButton;



///------------------------------
/// @name Rendering an App Action
///------------------------------


/**
 Tells the cell to render the passed app action.
 @param appAction A BTNAppAction loaded via `-[Button fetchAppActionWithButtonId:context:completion:]`
 @note passing nil will return the button to the loading state.
 */
- (void)prepareWithAppAction:(nullable BTNAppAction *)appAction;


///-----------------
/// @name Appearance
///-----------------

/**
 BTNDropinButtonCell conforms to BTNDropinButtonAppearance.
 For appearance properties @see BTNDropinButtonAppearance
 */

@end
