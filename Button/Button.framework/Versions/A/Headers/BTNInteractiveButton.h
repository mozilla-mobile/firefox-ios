@import UIKit;

@class BTNAppAction;

@interface BTNInteractiveButton : UIView

///------------------------------
/// @name Rendering an App Action
///------------------------------


/**
 Tells the button to render the passed app action.
 @param appAction A BTNAppAction loaded via `-[Button fetchAppActionWithButtonId:context:completion:]`
 @note passing nil will return the button to the loading state.
 */
- (void)prepareWithAppAction:(BTNAppAction *)appAction;



///-----------------
/// @name Appearance
///-----------------


/**
 Adjusts the width and height of the icon (default: 16.0).
 @note The icon is 1:1 so the value set here applies to both dimensions.
 */
@property (nonatomic, assign) CGFloat iconSize;


/**
 Adjusts space between the left edge of the button and the icon (default: 15.0).
 */
@property (nonatomic, assign) CGFloat iconLeftPadding;


/**
 Adjusts the spacing between the icon the text label (default: 8.0).
 */
@property (nonatomic, assign) CGFloat iconLabelSpacing;


/**
 Adjusts the left resting position of the first inventory item (default: 15.0).
 */
@property (nonatomic, assign) CGFloat inventoryLeftPadding;


/**
 The font face name used for all text (default: System font).
 @note If the font name is not correct, the system font will be used.
 @see +[UIFont familyNames] and +[UIFont fontNamesForFamilyName:] to find the correct font name.
 */
@property (nonatomic, copy) NSString *fontName;


/**
 Adjusts the point size of all text up or down relative to the current point size.
 @discussion Some fonts may be a bit larger or smaller than the system font. This property provides 
 a way to make slight adjustments to the point size to accomodate such cases. It is not intended to be 
 used for large changes in either direction and doing so may have unexpected results.
 */
@property (nonatomic, assign) NSInteger relativeFontPointSize;

@end
