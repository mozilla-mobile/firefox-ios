//
//  LPMessageTemplates.m
//  Leanplum
//
//  Created by Andrew First on 9/12/13.
//  Copyright 2013 Leanplum, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// 1. The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 2. This software and its derivatives may only be used in conjunction with the
// Leanplum SDK within apps that have a valid subscription to the Leanplum platform,
// at http://www.leanplum.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LPMessageTemplates.h"
#import <QuartzCore/QuartzCore.h>

#define APP_NAME (([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]) ?: \
    ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]))

#define LPMT_ALERT_NAME @"Alert"
#define LPMT_CONFIRM_NAME @"Confirm"
#define LPMT_PUSH_ASK_TO_ASK @"Push Ask to Ask"
#define LPMT_REGISTER_FOR_PUSH @"Register For Push"
#define LPMT_CENTER_POPUP_NAME @"Center Popup"
#define LPMT_INTERSTITIAL_NAME @"Interstitial"
#define LPMT_WEB_INTERSTITIAL_NAME @"Web Interstitial"
#define LPMT_OPEN_URL_NAME @"Open URL"

#define LPMT_ARG_TITLE @"Title"
#define LPMT_ARG_MESSAGE @"Message"
#define LPMT_ARG_URL @"URL"
#define LPMT_ARG_URL_CLOSE @"Close URL"
#define LPMT_ARG_DISMISS_ACTION @"Dismiss action"
#define LPMT_ARG_ACCEPT_ACTION @"Accept action"
#define LPMT_ARG_CANCEL_ACTION @"Cancel action"
#define LPMT_ARG_CANCEL_TEXT @"Cancel text"
#define LPMT_ARG_ACCEPT_TEXT @"Accept text"
#define LPMT_ARG_DISMISS_TEXT @"Dismiss text"
#define LPMT_HAS_DISMISS_BUTTON @"Has dismiss button"

#define LPMT_ARG_TITLE_TEXT @"Title.Text"
#define LPMT_ARG_TITLE_COLOR @"Title.Color"
#define LPMT_ARG_MESSAGE_TEXT @"Message.Text"
#define LPMT_ARG_MESSAGE_COLOR @"Message.Color"
#define LPMT_ARG_ACCEPT_BUTTON_TEXT @"Accept button.Text"
#define LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR @"Accept button.Background color"
#define LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR @"Accept button.Text color"
#define LPMT_ARG_CANCEL_BUTTON_TEXT @"Cancel button.Text"
#define LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR @"Cancel button.Background color"
#define LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR @"Cancel button.Text color"
#define LPMT_ARG_BACKGROUND_IMAGE @"Background image"
#define LPMT_ARG_BACKGROUND_COLOR @"Background color"
#define LPMT_ARG_LAYOUT_WIDTH @"Layout.Width"
#define LPMT_ARG_LAYOUT_HEIGHT @"Layout.Height"

#define LPMT_DEFAULT_ALERT_MESSAGE @"Alert message goes here."
#define LPMT_DEFAULT_CONFIRM_MESSAGE @"Confirmation message goes here."
#define LPMT_DEFAULT_ASK_TO_ASK_MESSAGE @"Tap OK to receive important notifications from our app."
#define LPMT_DEFAULT_POPUP_MESSAGE @"Popup message goes here."
#define LPMT_DEFAULT_INTERSTITIAL_MESSAGE @"Interstitial message goes here."
#define LPMT_DEFAULT_OK_BUTTON_TEXT @"OK"
#define LPMT_DEFAULT_YES_BUTTON_TEXT @"Yes"
#define LPMT_DEFAULT_NO_BUTTON_TEXT @"No"
#define LPMT_DEFAULT_LATER_BUTTON_TEXT @"Maybe Later"
#define LPMT_DEFAULT_URL @"http://www.example.com"
#define LPMT_DEFAULT_CLOSE_URL @"http://leanplum:close"
#define LPMT_DEFAULT_HAS_DISMISS_BUTTON YES

#define LPMT_POPUP_ANIMATION_LENGTH 0.35

#define LPMT_ACCEPT_BUTTON_WIDTH 50
#define LPMT_ACCEPT_BUTTON_HEIGHT 15
#define LPMT_ACCEPT_BUTTON_MARGIN 10
#define LPMT_TWO_BUTTON_PADDING 13

#define LPMT_DEFAULT_CENTER_POPUP_WIDTH 300
#define LPMT_DEFAULT_CENTER_POPUP_HEIGHT 250

#define LPMT_TITLE_LABEL_HEIGHT 30

#define LPMT_DISMISS_BUTTON_SIZE 32

#define LIGHT_GRAY (246.0/255.0)

#ifdef __IPHONE_6_0
# define ALIGN_CENTER NSTextAlignmentCenter
#else
# define ALIGN_CENTER UITextAlignmentCenter
#endif

#define LP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define LOG_LP_MESSAGE_EXCEPTION NSLog(@"Leanplum: Error in message template %@: %@\n%@", \
context.actionName, exception, [exception callStackSymbols])

static NSString *DEFAULTS_ASKED_TO_PUSH = @"__Leanplum_asked_to_push";
static NSString *DEFAULTS_LEANPLUM_ENABLED_PUSH = @"__Leanplum_enabled_push";

@implementation LPMessageTemplatesClass {
    NSMutableArray *_contexts;
    UIView *_popupView;
    UIImageView *_popupBackground;
    UILabel *_titleLabel;
    UILabel *_messageLabel;
    UIView *_popupGroup;
    UIButton *_acceptButton;
    UIButton *_cancelButton;
    UIButton *_dismissButton;
    UIButton *_overlayView;
    BOOL _webViewNeedsFade;
}

#pragma mark Initialization

+ (LPMessageTemplatesClass *)sharedTemplates
{
    static LPMessageTemplatesClass *sharedTemplates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTemplates = [[self alloc] init];
    });

    return sharedTemplates;
}

- (id)init
{
    if (self = [super init]) {
        _contexts = [NSMutableArray array];
        [self defineActions];
    }
    return self;
}

+ (UIViewController *)visibleViewController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

// Defines the preset in-app messaging and action templates.
// The presets are:
//   Alert: Displays a system UIAlertVIew with a single button
//   Confirm: Displays a system UIAlertView with two buttons
//   Open URL: Opens a URL, that can be either handled by the app or in the browser
//   Center Popup: Displays a custom message centered in the middle of the screen
//   Interstitial: Displays a full-screen message
//   Web Interstitial: Displays a full-screen web view.
// There are two types of actions: regular actions and message templates.
// Regular actions are indicated with the flag kLeanplumActionKindAction,
// and message templates are indicated with the flag kLeanplumActionKindMessage.
// These flags control where these options show up in the dashboard.
// Please give us suggestions for other types of messages!
- (void)defineActions
{
    [Leanplum defineAction:LPMT_ALERT_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                             [LPActionArg argNamed:LPMT_ARG_TITLE withString:APP_NAME],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE withString:LPMT_DEFAULT_ALERT_MESSAGE],
                             [LPActionArg argNamed:LPMT_ARG_DISMISS_TEXT withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                             [LPActionArg argNamed:LPMT_ARG_DISMISS_ACTION withAction:nil]
                             ]
             withResponder:^BOOL(LPActionContext *context) {
                 @try {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                     if (NSClassFromString(@"UIAlertController")) {
                         UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil) message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil) preferredStyle:UIAlertControllerStyleAlert];
                         UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_DISMISS_TEXT], nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                             [self alertDismissedWithButtonIndex:0];
                         }];
                         [alert addAction:action];
                         
                         [[LPMessageTemplatesClass visibleViewController]
                          presentViewController:alert animated:YES completion:nil];
                     } else
#endif
                     {
#if LP_NOT_TV
                         UIAlertView *alert = [[UIAlertView alloc]
                                               initWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                               message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                               delegate:self
                                               cancelButtonTitle:NSLocalizedString([context stringNamed:LPMT_ARG_DISMISS_TEXT], nil)
                                               otherButtonTitles:nil];
                         [alert show];
#endif
                     }

                     [self->_contexts addObject:context];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
    [Leanplum defineAction:LPMT_CONFIRM_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                             [LPActionArg argNamed:LPMT_ARG_TITLE withString:APP_NAME],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE withString:LPMT_DEFAULT_CONFIRM_MESSAGE],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_TEXT withString:LPMT_DEFAULT_YES_BUTTON_TEXT],
                             [LPActionArg argNamed:LPMT_ARG_CANCEL_TEXT withString:LPMT_DEFAULT_NO_BUTTON_TEXT],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_ACTION withAction:nil],
                             [LPActionArg argNamed:LPMT_ARG_CANCEL_ACTION withAction:nil],
                             ]
             withResponder:^BOOL(LPActionContext *context) {
                 @try {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                     if (NSClassFromString(@"UIAlertController")) {
                         UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil) message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil) preferredStyle:UIAlertControllerStyleAlert];
                         UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                             [self alertDismissedWithButtonIndex:0];
                         }];
                         [alert addAction:cancel];
                         UIAlertAction *accept = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                             [self alertDismissedWithButtonIndex:1];
                         }];
                         [alert addAction:accept];

                         [[LPMessageTemplatesClass visibleViewController]
                          presentViewController:alert animated:YES completion:nil];
                     } else
#endif
                     {
#if LP_NOT_TV
                         UIAlertView *alert = [[UIAlertView alloc]
                                               initWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                               message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                               delegate:self
                                               cancelButtonTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil)
                                               otherButtonTitles:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil),nil];
                         [alert show];
#endif
                     }
                     [self->_contexts addObject:context];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
    [Leanplum defineAction:LPMT_OPEN_URL_NAME
                    ofKind:kLeanplumActionKindAction
             withArguments:@[[LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL]]
             withResponder:^BOOL(LPActionContext *context) {
                 @try {
                     [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[context stringNamed:LPMT_ARG_URL]]];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
#if LP_NOT_TV
    UIColor *defaultButtonTextColor = [UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1];
    
    [Leanplum defineAction:LPMT_PUSH_ASK_TO_ASK
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                             [LPActionArg argNamed:LPMT_ARG_TITLE_TEXT withString:APP_NAME],
                             [LPActionArg argNamed:LPMT_ARG_TITLE_COLOR
                                         withColor:[UIColor blackColor]],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE_TEXT
                                        withString:LPMT_DEFAULT_ASK_TO_ASK_MESSAGE],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE_COLOR
                                         withColor:[UIColor blackColor]],
                             [LPActionArg argNamed:LPMT_ARG_BACKGROUND_IMAGE withFile:nil],
                             [LPActionArg argNamed:LPMT_ARG_BACKGROUND_COLOR
                                         withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT
                                        withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR
                                         withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR
                                         withColor:defaultButtonTextColor],
                             [LPActionArg argNamed:LPMT_ARG_CANCEL_ACTION withAction:nil],
                             [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_TEXT
                                        withString:LPMT_DEFAULT_LATER_BUTTON_TEXT],
                             [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR
                                         withColor:[UIColor colorWithWhite:LIGHT_GRAY alpha:1.0]],
                             [LPActionArg argNamed:LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR
                                         withColor:[UIColor grayColor]],
                             [LPActionArg argNamed:LPMT_ARG_LAYOUT_WIDTH
                                        withNumber:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH)],
                             [LPActionArg argNamed:LPMT_ARG_LAYOUT_HEIGHT
                                        withNumber:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT)]
                             ]
             withResponder:^BOOL(LPActionContext *context) {
                 if ([Leanplum isPreLeanplumInstall]) {
                     NSLog(@"Leanplum: 'Ask to ask' conservatively falls back to just 'ask' for pre-Leanplum installs");
                     [self enableSystemPush];
                     return NO;
                 } else if ([self isPushEnabled]) {
                     NSLog(@"Leanplum: Pushes already enabled");
                     return NO;
                 } else if ([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_ASKED_TO_PUSH]) {
                         NSLog(@"Leanplum: Already asked to push");
                         return NO;
                 } else {
                     if ([context hasMissingFiles]) {
                         return NO;
                     }

                     @try {
                         [self closePopup:NO withAction:LPMT_ARG_CANCEL_ACTION trackAction:NO];
                         [self->_contexts addObject:context];
                         [self showPopup];
                         return YES;
                     }
                     @catch (NSException *exception) {
                         NSLog(@"Leanplum: Error in pushAskToAsk: %@\n%@", exception,
                               [exception callStackSymbols]);
                         return NO;
                     }
                 }
             }];
    
    [Leanplum defineAction:LPMT_REGISTER_FOR_PUSH
                    ofKind:kLeanplumActionKindAction
             withArguments:@[]
             withResponder:^BOOL(LPActionContext *context) {
                 [self enableSystemPush];
                 return YES;
             }];
    
    [Leanplum defineAction:LPMT_CENTER_POPUP_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                             [LPActionArg argNamed:LPMT_ARG_TITLE_TEXT withString:APP_NAME],
                             [LPActionArg argNamed:LPMT_ARG_TITLE_COLOR withColor:[UIColor blackColor]],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE_TEXT withString:LPMT_DEFAULT_POPUP_MESSAGE],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE_COLOR withColor:[UIColor blackColor]],
                             [LPActionArg argNamed:LPMT_ARG_BACKGROUND_IMAGE withFile:nil],
                             [LPActionArg argNamed:LPMT_ARG_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR withColor:defaultButtonTextColor],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_ACTION withAction:nil],
                             [LPActionArg argNamed:LPMT_ARG_LAYOUT_WIDTH withNumber:@(LPMT_DEFAULT_CENTER_POPUP_WIDTH)],
                             [LPActionArg argNamed:LPMT_ARG_LAYOUT_HEIGHT withNumber:@(LPMT_DEFAULT_CENTER_POPUP_HEIGHT)]
                             ]
             withResponder:^BOOL(LPActionContext *context) {
                 if ([context hasMissingFiles]) {
                     return NO;
                 }

                 @try {
                     [self closePopup:NO withAction:LPMT_ARG_CANCEL_ACTION trackAction:NO];
                     [self->_contexts addObject:context];
                     [self showPopup];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
    [Leanplum defineAction:LPMT_INTERSTITIAL_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                             [LPActionArg argNamed:LPMT_ARG_TITLE_TEXT withString:APP_NAME],
                             [LPActionArg argNamed:LPMT_ARG_TITLE_COLOR withColor:[UIColor blackColor]],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE_TEXT withString:LPMT_DEFAULT_INTERSTITIAL_MESSAGE],
                             [LPActionArg argNamed:LPMT_ARG_MESSAGE_COLOR withColor:[UIColor blackColor]],
                             [LPActionArg argNamed:LPMT_ARG_BACKGROUND_IMAGE withFile:nil],
                             [LPActionArg argNamed:LPMT_ARG_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT withString:LPMT_DEFAULT_OK_BUTTON_TEXT],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR withColor:[UIColor whiteColor]],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR withColor:defaultButtonTextColor],
                             [LPActionArg argNamed:LPMT_ARG_ACCEPT_ACTION withAction:nil]
                             ]
             withResponder:^BOOL(LPActionContext *context) {
                 if ([context hasMissingFiles]) {
                     return NO;
                 }

                 @try {
                     [self closePopup:NO withAction:LPMT_ARG_CANCEL_ACTION trackAction:NO];
                     [self->_contexts addObject:context];
                     [self showPopup];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];

    [Leanplum defineAction:LPMT_WEB_INTERSTITIAL_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[[LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL],
                             [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
                             [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON withBool:LPMT_DEFAULT_HAS_DISMISS_BUTTON]]
             withResponder:^BOOL(LPActionContext *context) {
                 @try {
                     [self closePopup:NO withAction:LPMT_ARG_CANCEL_ACTION trackAction:NO];
                     [self->_contexts addObject:context];
                     [self showPopup];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
    [Leanplum addVariablesChangedResponder:self withSelector:@selector(refreshPopupContent)];
#endif
}

#pragma mark Alert and Confirm Logic

#if LP_NOT_TV
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self alertDismissedWithButtonIndex:buttonIndex];
}
#endif

- (void)alertDismissedWithButtonIndex:(NSInteger)buttonIndex
{
    LPActionContext *context = _contexts.lastObject;
    @try {
        [_contexts removeLastObject];
        
        if ([context.actionName isEqualToString:LPMT_ALERT_NAME]) {
            [context runActionNamed:LPMT_ARG_DISMISS_ACTION];
        } else {
            if (buttonIndex == 1) {
                [context runTrackedActionNamed:LPMT_ARG_ACCEPT_ACTION];
            } else {
                [context runActionNamed:LPMT_ARG_CANCEL_ACTION];
            }
        }
    }
    @catch (NSException *exception) {
        LOG_LP_MESSAGE_EXCEPTION;
    }
}

#if LP_NOT_TV

#pragma mark Center Popup and Interstitial Logic

// Creates a 1x1 image with the specified color.
+ (UIImage *)imageFromColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Creates the X icon used in the popup's dismiss button.
+ (UIImage *)dismissImage:(UIColor *)color withSize:(int)size
{
    CGRect rect = CGRectMake(0, 0, size, size);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    int margin = size * 3 / 8;
    
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetLineWidth(context, 1.5);
    CGContextMoveToPoint(context, margin, margin);
    CGContextAddLineToPoint(context, size - margin, size - margin);
    CGContextMoveToPoint(context, size - margin, margin);
    CGContextAddLineToPoint(context, margin, size - margin);
    CGContextStrokePath(context);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

// Displays the Center Popup, Interstitial and Web Interstitial.
- (void)showPopup
{
    LPActionContext *context = _contexts.lastObject;
    BOOL isFullscreen = [context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME];
    BOOL isWeb = [context.actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME];
    BOOL isPushAskToAsk = [context.actionName isEqualToString:LPMT_PUSH_ASK_TO_ASK];
    
    if (isWeb) {
        _popupView = [[UIWebView alloc] init];
    } else {
        _popupView = [[UIView alloc] init];
    }
    
    // Group.
    _popupGroup = [[UIView alloc] init];
    _popupGroup.backgroundColor = [UIColor clearColor];
    
    if (!isWeb) {
        [self setupPopupLayout:isFullscreen isPushAskToAsk:isPushAskToAsk];
    }
    
    [_popupGroup addSubview:_popupView];
    if ((!isWeb || [context boolNamed:LPMT_HAS_DISMISS_BUTTON]) && !isPushAskToAsk) {
        // Dismiss button.
        _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _dismissButton.bounds = CGRectMake(0, 0, LPMT_DISMISS_BUTTON_SIZE, LPMT_DISMISS_BUTTON_SIZE);
        [_dismissButton setBackgroundImage:[LPMessageTemplatesClass dismissImage:[UIColor colorWithWhite:.9 alpha:.9]
                                                                        withSize:LPMT_DISMISS_BUTTON_SIZE] forState:UIControlStateNormal];
        [_dismissButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _dismissButton.adjustsImageWhenHighlighted = YES;
        _dismissButton.layer.masksToBounds = YES;
        _dismissButton.titleLabel.font = [UIFont systemFontOfSize:13];
        _dismissButton.layer.borderWidth = 0;
        _dismissButton.layer.cornerRadius = LPMT_DISMISS_BUTTON_SIZE / 2;
        [_popupGroup addSubview:_dismissButton];
    }
    
    [_dismissButton addTarget:self action:@selector(dismiss)
             forControlEvents:UIControlEventTouchUpInside];
    
    [self refreshPopupContent];
    [self updatePopupLayout];
    
    [_popupGroup setAlpha:0.0];
    [[UIApplication sharedApplication].keyWindow addSubview:_popupGroup];
    [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
        [self->_popupGroup setAlpha:1.0];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)setupPopupLayout:(BOOL)isFullscreen isPushAskToAsk:(BOOL)isPushAskToAsk
{
    _popupBackground = [[UIImageView alloc] init];
    [_popupView addSubview:_popupBackground];
    _popupBackground.contentMode = UIViewContentModeScaleAspectFill;
    if (!isFullscreen) {
        _popupView.layer.cornerRadius = 12;
    }
    _popupView.clipsToBounds = YES;
    
    // Accept button.
    _acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _acceptButton.layer.cornerRadius = 6;
    _acceptButton.adjustsImageWhenHighlighted = YES;
    _acceptButton.layer.masksToBounds = YES;
    _acceptButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_popupView addSubview:_acceptButton];
    
    if (isPushAskToAsk) {
        _acceptButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _acceptButton.layer.cornerRadius = 0;
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.layer.cornerRadius = 0;
        _cancelButton.adjustsImageWhenHighlighted = YES;
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [_popupView addSubview:_cancelButton];
    }
    
    // Title.
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = ALIGN_CENTER;
    _titleLabel.font = [UIFont boldSystemFontOfSize:20];
    _titleLabel.backgroundColor = [UIColor clearColor];
    [_popupView addSubview:_titleLabel];
    
    // Message.
    _messageLabel = [[UILabel alloc] init];
    _messageLabel.textAlignment = ALIGN_CENTER;
    _messageLabel.numberOfLines = 0;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
#endif
    _messageLabel.backgroundColor = [UIColor clearColor];
    [_popupView addSubview:_messageLabel];
    
    // Overlay.
    _overlayView = [UIButton buttonWithType:UIButtonTypeCustom];
    _overlayView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.7];
    
    if (!isFullscreen) {
        [_popupGroup addSubview:_overlayView];
    }
    
    if (isPushAskToAsk) {
        [_acceptButton addTarget:self action:@selector(enablePush)
                forControlEvents:UIControlEventTouchUpInside];
        [_cancelButton addTarget:self action:@selector(deferPush)
                forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_acceptButton addTarget:self action:@selector(accept)
                forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)orientationDidChange:(NSNotification *)notification
{
    [self updatePopupLayout];
    
    // isStatusBarHidden is not updated synchronously
    LPActionContext *conteext = _contexts.lastObject;
    if ([conteext.actionName isEqualToString:LPMT_INTERSTITIAL_NAME]) {
        [self performSelector:@selector(updatePopupLayout) withObject:nil afterDelay:0];
    }
}

- (void)closePopup:(BOOL)animated withAction:(NSString *)action trackAction:(BOOL)track
{
    if (!_popupGroup) {
        return;
    }
    
    LPActionContext *context = _contexts.lastObject;
    [_contexts removeLastObject];
    
    if (animated) {
        [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
            [self->_popupGroup setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self->_popupGroup removeFromSuperview];
            if (track) {
                [context runTrackedActionNamed:action];
            }
        }];
    } else {
        [_popupGroup removeFromSuperview];
        if (track) {
            [context runTrackedActionNamed:action];
        }
    }
    
    if ([[context actionName] isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
        ((UIWebView *)_popupView).delegate = nil;
    }

    _popupView = nil;
    _popupBackground = nil;
    _acceptButton = nil;
    _cancelButton = nil;
    _titleLabel = nil;
    _messageLabel = nil;
    _popupGroup = nil;
    _dismissButton = nil;
    _overlayView = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}

- (void)accept
{
    [self closePopup:YES withAction:LPMT_ARG_ACCEPT_ACTION trackAction:YES];
}

- (void)dismiss
{
    [self closePopup:YES withAction:LPMT_ARG_CANCEL_ACTION trackAction:NO];
}

- (void)enablePush
{
    [self accept];
    [self enableSystemPush];
}

- (void)deferPush
{
    [self closePopup:YES withAction:LPMT_ARG_CANCEL_ACTION trackAction:YES];
}

- (BOOL)isPushEnabled
{
    UIApplication *application = [UIApplication sharedApplication];
    BOOL enabled;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    // Try to use the newer isRegisteredForRemoteNotifications otherwise use the enabledRemoteNotificationTypes.
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
        enabled = [application isRegisteredForRemoteNotifications];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
        enabled = types & UIRemoteNotificationTypeAlert;
#pragma clang diagnostic pop
    }
#else
    UIRemoteNotificationType types = [application enabledRemoteNotificationTypes];
    enabled = types & UIRemoteNotificationTypeAlert;
#endif
    return enabled;
}

- (void)enableSystemPush
{
    // The commented lines below are an alternative for iOS 8 that will deep link to the app in
    // device Settings.
    //    NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    //    [[UIApplication sharedApplication] openURL:appSettings];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_LEANPLUM_ENABLED_PUSH];
    LeanplumPushSetupBlock block = [Leanplum pushSetupBlock];
    if (block) {
        // If the app used [Leanplum setPushSetup:...], call the block.
        block();
        return;
    }
    // Otherwise use boilerplate code from docs.
    id notificationCenterClass = NSClassFromString(@"UNUserNotificationCenter");
    if (notificationCenterClass) {
        // iOS 10.
        SEL selector = NSSelectorFromString(@"currentNotificationCenter");
        id notificationCenter =
        ((id (*)(id, SEL)) [notificationCenterClass methodForSelector:selector])
        (notificationCenterClass, selector);
        if (notificationCenter) {
            selector = NSSelectorFromString(@"requestAuthorizationWithOptions:completionHandler:");
            IMP method = [notificationCenter methodForSelector:selector];
            void (*func)(id, SEL, unsigned long long, void (^)(BOOL, NSError *__nullable)) =
            (void *) method;
            func(notificationCenter, selector,
                 0b111, /* badges, sounds, alerts */
                 ^(BOOL granted, NSError *__nullable error) {
                     if (error) {
                         NSLog(@"Leanplum: Failed to request authorization for user "
                               "notifications: %@", error);
                     }
                 });
        }
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else if ([[UIApplication sharedApplication] respondsToSelector:
                @selector(registerUserNotificationSettings:)]) {
        // iOS 8-9.
        UIUserNotificationSettings *settings = [UIUserNotificationSettings
                                                settingsForTypes:UIUserNotificationTypeAlert |
                                                UIUserNotificationTypeBadge |
                                                UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        // iOS 7 and below.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
#pragma clang diagnostic pop
         UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge];
    }
}

// If notification were enabled by Leanplum's "Push Ask to Ask" or "Register For Push",
// refreshPushPermissions will do the same registration for subsequent app sessions.
// refreshPushPermissions is called by [Leanplum start].
- (void)refreshPushPermissions
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_LEANPLUM_ENABLED_PUSH]) {
        [self enableSystemPush];
    }
}

- (void)disableAskToAsk
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_ASKED_TO_PUSH];
}

- (void)updatePopupLayout
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    LPActionContext *context = _contexts.lastObject;
    
    BOOL fullscreen = ([context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME] ||
                       [context.actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]);
    BOOL isWeb = [context.actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME];
    
    int statusBarHeight = ([[UIApplication sharedApplication] isStatusBarHidden] || !fullscreen) ? 0
    : MIN([UIApplication sharedApplication].statusBarFrame.size.height,
          [UIApplication sharedApplication].statusBarFrame.size.width);
    
    UIInterfaceOrientation orientation;
    if (LP_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        orientation = UIInterfaceOrientationPortrait;
    } else {
        UIViewController *emptyViewController = [[UIViewController alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        orientation = [emptyViewController interfaceOrientation];
#pragma clang diagnostic pop
#if !__has_feature(objc_arc)
        [emptyViewController release];
#endif
    }
    CGAffineTransform orientationTransform;
    switch (orientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            orientationTransform = CGAffineTransformMakeRotation(M_PI);
            break;
        case UIDeviceOrientationLandscapeLeft:
            orientationTransform = CGAffineTransformMakeRotation(M_PI / 2);
            break;
        case UIDeviceOrientationLandscapeRight:
            orientationTransform = CGAffineTransformMakeRotation(-M_PI / 2);
            break;
        default:
            orientationTransform = CGAffineTransformIdentity;
    }
    _popupGroup.transform = orientationTransform;
    CGSize screenSize = window.screen.bounds.size;
    _popupGroup.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
    
    int screenWidth;
    int screenHeight;
    if (orientation == UIDeviceOrientationLandscapeLeft ||
        orientation == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenSize.height;
        screenHeight = screenSize.width;
    } else {
        screenWidth = screenSize.width;
        screenHeight = screenSize.height;
    }
    CGRect popupFrame;
    if (fullscreen) {
        popupFrame = CGRectMake(0, 0, screenWidth, screenHeight);
    } else {
        popupFrame = CGRectMake(0, 0,
                                [[context numberNamed:LPMT_ARG_LAYOUT_WIDTH] doubleValue],
                                [[context numberNamed:LPMT_ARG_LAYOUT_HEIGHT] doubleValue]);
    }
    
    _popupView.frame = popupFrame;
    _popupView.center = CGPointMake(screenWidth / 2.0, screenHeight / 2.0);
    
    if (!isWeb) {
        [self updateNonWebPopupLayout:statusBarHeight];
    }
    
    if (fullscreen) {
        _dismissButton.frame = CGRectMake(screenWidth - _dismissButton.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN / 2,
                                          statusBarHeight + LPMT_ACCEPT_BUTTON_MARGIN / 2,
                                          _dismissButton.frame.size.width,
                                          _dismissButton.frame.size.height);
    } else {
        _dismissButton.frame = CGRectMake(_popupView.frame.origin.x + _popupView.frame.size.width - 3 * _dismissButton.frame.size.width / 4,
                                          _popupView.frame.origin.y - _dismissButton.frame.size.height / 4,
                                          _dismissButton.frame.size.width,
                                          _dismissButton.frame.size.height);
    }
    
    if (!isWeb) {
        _overlayView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    }
}

- (CGSize)getTextSizeFromButton:(UIButton *)button
{
    UIFont* font = button.titleLabel.font;
    NSString *text = button.titleLabel.text;
    CGSize textSize = CGSizeZero;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([text respondsToSelector:@selector(sizeWithAttributes:)]) {
        textSize = [text sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:font.fontName size:font.pointSize]}];
    } else
#endif
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        textSize = [text sizeWithFont:[UIFont fontWithName:font.fontName size:font.pointSize]];
#pragma clang diagnostic pop
    }
    textSize.width = textSize.width > 50 ? textSize.width : LPMT_ACCEPT_BUTTON_WIDTH;
    textSize.height = textSize.height > 15 ? textSize.height : LPMT_ACCEPT_BUTTON_HEIGHT;
    return textSize;
}

- (void)updateNonWebPopupLayout:(int)statusBarHeight
{
    _popupBackground.frame = CGRectMake(0, 0, _popupView.frame.size.width, _popupView.frame.size.height);
    CGSize textSize = [self getTextSizeFromButton:_acceptButton];

    if (_cancelButton) {
        CGSize cancelTextSize = [self getTextSizeFromButton:_cancelButton];
        textSize = CGSizeMake(MAX(textSize.width, cancelTextSize.width),
                              MAX(textSize.height, cancelTextSize.height));
        _cancelButton.frame = CGRectMake(0,
                                         _popupView.frame.size.height - textSize.height - 2*LPMT_TWO_BUTTON_PADDING,
                                         _popupView.frame.size.width / 2,
                                         textSize.height + 2*LPMT_TWO_BUTTON_PADDING);
        _acceptButton.frame = CGRectMake(_popupView.frame.size.width / 2,
                                         _popupView.frame.size.height - textSize.height - 2*LPMT_TWO_BUTTON_PADDING,
                                         _popupView.frame.size.width / 2,
                                         textSize.height + 2*LPMT_TWO_BUTTON_PADDING);
    } else {
        _acceptButton.frame = CGRectMake(
                                         (_popupView.frame.size.width - textSize.width - 2*LPMT_ACCEPT_BUTTON_MARGIN) / 2,
                                         _popupView.frame.size.height - textSize.height - 3*LPMT_ACCEPT_BUTTON_MARGIN,
                                         textSize.width + 2*LPMT_ACCEPT_BUTTON_MARGIN,
                                         textSize.height + 2*LPMT_ACCEPT_BUTTON_MARGIN);
    }
    _titleLabel.frame = CGRectMake(LPMT_ACCEPT_BUTTON_MARGIN, LPMT_ACCEPT_BUTTON_MARGIN + statusBarHeight,
                                   _popupView.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN * 2, LPMT_TITLE_LABEL_HEIGHT);
    _messageLabel.frame = CGRectMake(LPMT_ACCEPT_BUTTON_MARGIN,
                                     LPMT_ACCEPT_BUTTON_MARGIN * 2 + LPMT_TITLE_LABEL_HEIGHT + statusBarHeight,
                                     _popupView.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN * 2,
                                     _popupView.frame.size.height - LPMT_ACCEPT_BUTTON_MARGIN * 4 - LPMT_TITLE_LABEL_HEIGHT - LPMT_ACCEPT_BUTTON_HEIGHT - statusBarHeight);
}

- (void)refreshPopupContent
{
    LPActionContext *context = _contexts.lastObject;
    @try {
        NSString *actionName = [context actionName];
        if ([actionName isEqualToString:LPMT_CENTER_POPUP_NAME]
            || [actionName isEqualToString:LPMT_INTERSTITIAL_NAME]
            || [actionName isEqualToString:LPMT_PUSH_ASK_TO_ASK]) {
            if (_popupGroup) {
                _popupBackground.image = [UIImage imageWithContentsOfFile:
                                          [context fileNamed:LPMT_ARG_BACKGROUND_IMAGE]];
                _popupBackground.backgroundColor = [context colorNamed:LPMT_ARG_BACKGROUND_COLOR];
                [_acceptButton setTitle:[context stringNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT]
                               forState:UIControlStateNormal];
                [_acceptButton setBackgroundImage:[LPMessageTemplatesClass imageFromColor:
                                                   [context colorNamed:LPMT_ARG_ACCEPT_BUTTON_BACKGROUND_COLOR]]
                                         forState:UIControlStateNormal];
                [_acceptButton setTitleColor:[context colorNamed:LPMT_ARG_ACCEPT_BUTTON_TEXT_COLOR]
                                    forState:UIControlStateNormal];
                if (_cancelButton) {
                    [_cancelButton setTitle:[context stringNamed:LPMT_ARG_CANCEL_BUTTON_TEXT]
                                   forState:UIControlStateNormal];
                    [_cancelButton setBackgroundImage:[LPMessageTemplatesClass imageFromColor:
                                                       [context colorNamed:LPMT_ARG_CANCEL_BUTTON_BACKGROUND_COLOR]]
                                             forState:UIControlStateNormal];
                    [_cancelButton setTitleColor:[context colorNamed:LPMT_ARG_CANCEL_BUTTON_TEXT_COLOR]
                                        forState:UIControlStateNormal];
                }
                _titleLabel.text = [context stringNamed:LPMT_ARG_TITLE_TEXT];
                _titleLabel.textColor = [context colorNamed:LPMT_ARG_TITLE_COLOR];
                _messageLabel.text = [context stringNamed:LPMT_ARG_MESSAGE_TEXT];
                _messageLabel.textColor = [context colorNamed:LPMT_ARG_MESSAGE_COLOR];
                [self updatePopupLayout];
            }
        } else if ([actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
            if (_popupGroup) {
                [_popupGroup setHidden:YES];  // Keep hidden until load is done
                UIWebView *webView = (UIWebView *) _popupView;
                _webViewNeedsFade = YES;
                webView.delegate = self;
                [webView loadRequest:[NSURLRequest requestWithURL:
                                      [NSURL URLWithString:[context stringNamed:LPMT_ARG_URL]]]];
            }
        }
    }
    @catch (NSException *exception) {
        LOG_LP_MESSAGE_EXCEPTION;
    }
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (webView.isLoading) {
        return;
    }
    [_popupGroup setHidden:NO];
    if (_webViewNeedsFade) {
        _webViewNeedsFade = NO;
        [_popupGroup setAlpha:0.0];
        [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
            [self->_popupGroup setAlpha:1.0];
        }];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    LPActionContext *context = _contexts.lastObject;
    @try {
        NSString *url = request.URL.absoluteString;
        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_CLOSE]].location != NSNotFound) {
            [self dismiss];
            NSArray *urlComponents = [url componentsSeparatedByString:@"?"];
            if ([urlComponents count] > 1) {
                NSString *queryString = urlComponents[1];
                NSArray *parameters = [queryString componentsSeparatedByString:@"&"];
                for (NSString *parameter in parameters) {
                    NSArray *parameterComponents = [parameter componentsSeparatedByString:@"="];
                    if ([parameterComponents count] > 1) {
                        if ([parameterComponents[0] isEqualToString:@"result"]) {
                            [Leanplum track:parameterComponents[1]];
                        }
                    }
                }
            }
            return NO;
        }
    }
    @catch (NSException *exception) {
        LOG_LP_MESSAGE_EXCEPTION;
    }
    return YES;
}

#endif

@end
