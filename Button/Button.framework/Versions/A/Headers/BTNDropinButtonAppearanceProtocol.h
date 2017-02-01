@import Foundation;
#import "BTNDropinButtonConstants.h"

@protocol BTNDropinButtonAppearance <NSObject>

@optional

///-----------------
/// @name Appearance
///-----------------


/// Defines the insets of the dropin button's content view.
@property (nonatomic, assign) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;


/// Defines the alignment of the button's content. This supercedes any left/right content inset.
@property (nonatomic, assign) BTNDropinContentAlignment contentAlignment UI_APPEARANCE_SELECTOR;


/// Defines the corner radius of the dropin button (default is 0).
@property (nonatomic, assign) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;


/// Defines the border width of the dropin button border (default is 0).
@property (nonatomic, assign) CGFloat borderWidth UI_APPEARANCE_SELECTOR;


/// Defines the color of the dropin button border.
@property (nullable, nonatomic, strong) UIColor *borderColor UI_APPEARANCE_SELECTOR;


/// Defines the size of the icon view in the dropin button (applied to height and width).
@property (nonatomic, assign) CGFloat iconSize UI_APPEARANCE_SELECTOR;


/// Defines the spacing between the icon view and the text label in the dropin button.
@property (nonatomic, assign) CGFloat iconLabelSpacing UI_APPEARANCE_SELECTOR;


/// Defines the font used in the dropin button.
@property (nullable, nonatomic, strong) UIFont *font UI_APPEARANCE_SELECTOR;


/// Defines the font used on the title label in the dropin button.
@property (nullable, nonatomic, strong) UIFont *titleFont UI_APPEARANCE_SELECTOR;


/// Defines the font used on the subtitle label in the dropin button.
@property (nullable, nonatomic, strong) UIFont *subtitleFont UI_APPEARANCE_SELECTOR;


/// Defines the string case of all dropin button text.
@property (nonatomic, assign) BTNDropinButtonTextCase textCase UI_APPEARANCE_SELECTOR;


/// Defines the string case of the dropin button title text.
@property (nonatomic, assign) BTNDropinButtonTextCase titleTextCase UI_APPEARANCE_SELECTOR;


/// Defines the string case of the dropin button subtitle text.
@property (nonatomic, assign) BTNDropinButtonTextCase subtitleTextCase UI_APPEARANCE_SELECTOR;


/// Defines the color of the dropin text.
@property (nullable, nonatomic, strong) UIColor *tintColor UI_APPEARANCE_SELECTOR;


/// Defines the highlighted tint color of the dropin button, text.
@property (nullable, nonatomic, strong) UIColor *highlightedTintColor UI_APPEARANCE_SELECTOR;


/// Defines the color of the dropin button title text (supersedes tintColor).
@property (nullable, nonatomic, strong) UIColor *titleTextColor UI_APPEARANCE_SELECTOR;


/// Defines the color of the dropin button subtitle text (supersedes tintColor).
@property (nullable, nonatomic, strong) UIColor *subtitleTextColor UI_APPEARANCE_SELECTOR;


/// Defines the color of all dropin button text (supersedes tintColor).
@property (nullable, nonatomic, strong) UIColor *textColor UI_APPEARANCE_SELECTOR;


/// Defines the highlighted color of all dropin button text (supersedes highlightedTintColor).
@property (nullable, nonatomic, strong) UIColor *highlightedTextColor UI_APPEARANCE_SELECTOR;


/// Defines the normal background color for the button.
@property (nullable, nonatomic, strong) UIColor *normalBackgroundColor UI_APPEARANCE_SELECTOR;


/// Defines the highlighted background color for the button.
@property (nullable, nonatomic, strong) UIColor *highlightedBackgroundColor UI_APPEARANCE_SELECTOR;

@end
