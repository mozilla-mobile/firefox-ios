//
//  LPMessageTemplates.m
//  Leanplum
//
//  Created by Andrew First on 9/12/13.
//  Copyright 2013 Leanplum, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  1. The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  2. This software and its derivatives may only be used in conjunction with the
//  Leanplum SDK within apps that have a valid subscription to the Leanplum platform,
//  at http://www.leanplum.com
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "LPMessageTemplates.h"
#import <QuartzCore/QuartzCore.h>
#import <StoreKit/StoreKit.h>
#import "LPCountAggregator.h"

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
#define LPMT_HTML_NAME @"HTML"
#define LPMT_APP_RATING_NAME @"Request App Rating"
#define LPMT_ICON_CHANGE_NAME @"Change App Icon"

#define LPMT_ARG_TITLE @"Title"
#define LPMT_ARG_MESSAGE @"Message"
#define LPMT_ARG_URL @"URL"
#define LPMT_ARG_URL_CLOSE @"Close URL"
#define LPMT_ARG_URL_OPEN @"Open URL"
#define LPMT_ARG_URL_TRACK @"Track URL"
#define LPMT_ARG_URL_ACTION @"Action URL"
#define LPMT_ARG_URL_TRACK_ACTION @"Track Action URL"
#define LPMT_ARG_DISMISS_ACTION @"Dismiss action"
#define LPMT_ARG_ACCEPT_ACTION @"Accept action"
#define LPMT_ARG_CANCEL_ACTION @"Cancel action"
#define LPMT_ARG_CANCEL_TEXT @"Cancel text"
#define LPMT_ARG_ACCEPT_TEXT @"Accept text"
#define LPMT_ARG_DISMISS_TEXT @"Dismiss text"
#define LPMT_HAS_DISMISS_BUTTON @"Has dismiss button"
#define LPMT_ARG_HTML_TEMPLATE @"__file__Template"

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
#define LPMT_ARG_HTML_HEIGHT @"HTML Height"
#define LPMT_ARG_HTML_WIDTH @"HTML Width"
#define LPMT_ARG_HTML_ALIGN @"HTML Align"
#define LPMT_ARG_HTML_Y_OFFSET @"HTML Y Offset"
#define LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE @"Tap Outside to Close"
#define LPMT_ARG_HTML_ALIGN_TOP @"Top"
#define LPMT_ARG_HTML_ALIGN_BOTTOM @"Bottom"
#define LPMT_ARG_APP_ICON @"__iOSAppIcon"

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
#define LPMT_DEFAULT_CLOSE_URL @"http://leanplum/close"
#define LPMT_DEFAULT_OPEN_URL @"http://leanplum/loadFinished"
#define LPMT_DEFAULT_TRACK_URL @"http://leanplum/track"
#define LPMT_DEFAULT_ACTION_URL @"http://leanplum/runAction"
#define LPMT_DEFAULT_TRACK_ACTION_URL @"http://leanplum/runTrackedAction"
#define LPMT_DEFAULT_HAS_DISMISS_BUTTON YES
#define LPMT_DEFAULT_APP_ICON @"__iOSAppIcon-PrimaryIcon.png"

#define LPMT_ICON_FILE_PREFIX @"__iOSAppIcon-"
#define LPMT_ICON_PRIMARY_NAME @"PrimaryIcon"

#define LPMT_POPUP_ANIMATION_LENGTH 0.35

#define LPMT_ACCEPT_BUTTON_WIDTH 50
#define LPMT_ACCEPT_BUTTON_HEIGHT 15
#define LPMT_ACCEPT_BUTTON_MARGIN 10
#define LPMT_TWO_BUTTON_PADDING 13

#define LPMT_DEFAULT_CENTER_POPUP_WIDTH 300
#define LPMT_DEFAULT_CENTER_POPUP_HEIGHT 250
#define LPMT_DEFAULT_HTML_HEIGHT 0
#define LPMT_DEFAULT_HTML_ALIGN LPMT_ARG_LAYOUT_ALIGN_TOP

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

#pragma mark Helper View Class
@interface LPHitView : UIView
@property (strong, nonatomic) void (^callback)(void);
@end

@implementation LPHitView
- (id)initWithCallback:(void (^)(void))callback
{
    if (self = [super init]) {
        self.callback = [callback copy];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        if (self.callback) {
            self.callback();
        }
        return nil;
    }
    return hitView;
}
@end

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
    LPHitView *_closePopupView;
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
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"shared_templates"];
    
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
                     if (NSClassFromString(@"UIAlertController")) {
                         UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil) message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil) preferredStyle:UIAlertControllerStyleAlert];
                         UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_DISMISS_TEXT], nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                             [self alertDismissedWithButtonIndex:0];
                         }];
                         [alert addAction:action];
                         
                         [[LPMessageTemplatesClass visibleViewController]
                          presentViewController:alert animated:YES completion:nil];
                     } else
                     {
                         UIAlertView *alert = [[UIAlertView alloc]
                                               initWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                               message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                               delegate:self
                                               cancelButtonTitle:NSLocalizedString([context stringNamed:LPMT_ARG_DISMISS_TEXT], nil)
                                               otherButtonTitles:nil];
                         [alert show];
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
                     {
                         UIAlertView *alert = [[UIAlertView alloc]
                                               initWithTitle:NSLocalizedString([context stringNamed:LPMT_ARG_TITLE], nil)
                                               message:NSLocalizedString([context stringNamed:LPMT_ARG_MESSAGE], nil)
                                               delegate:self
                                               cancelButtonTitle:NSLocalizedString([context stringNamed:LPMT_ARG_CANCEL_TEXT], nil)
                                               otherButtonTitles:NSLocalizedString([context stringNamed:LPMT_ARG_ACCEPT_TEXT], nil),nil];
                         [alert show];
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
                     dispatch_async(dispatch_get_main_queue(), ^{
                         NSString *encodedURLString = [[self class] urlEncodedStringFromString:[context stringNamed:LPMT_ARG_URL]];
                         NSURL *url = [NSURL URLWithString: encodedURLString];
                         if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                             if (@available(iOS 10.0, *)) {
                                 [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                             } else {
                                 // Fallback on earlier versions
                             }
                         } else {
                             [[UIApplication sharedApplication] openURL:url];
                         }
                     });
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];
    
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
                         [self closePopupWithAnimation:NO];
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
    
    BOOL (^messageResponder)(LPActionContext *) = ^(LPActionContext *context) {
        if ([context hasMissingFiles]) {
            return NO;
        }

        @try {
            [self closePopupWithAnimation:NO];
            [self->_contexts addObject:context];
            [self showPopup];
            return YES;
        }
        @catch (NSException *exception) {
            LOG_LP_MESSAGE_EXCEPTION;
            return NO;
        }
    };

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
             withResponder:messageResponder];
    
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
             withResponder:messageResponder];

    [Leanplum defineAction:LPMT_WEB_INTERSTITIAL_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                    [LPActionArg argNamed:LPMT_ARG_URL withString:LPMT_DEFAULT_URL],
                    [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
                    [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON
                                 withBool:LPMT_DEFAULT_HAS_DISMISS_BUTTON]]
             withResponder:^BOOL(LPActionContext *context) {
                 @try {
                     [self closePopupWithAnimation:NO];
                     [self->_contexts addObject:context];
                     [self showPopup];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                     return NO;
                 }
             }];

    [Leanplum defineAction:LPMT_HTML_NAME
                    ofKind:kLeanplumActionKindMessage | kLeanplumActionKindAction
             withArguments:@[
                    [LPActionArg argNamed:LPMT_ARG_URL_CLOSE withString:LPMT_DEFAULT_CLOSE_URL],
                    [LPActionArg argNamed:LPMT_ARG_URL_OPEN withString:LPMT_DEFAULT_OPEN_URL],
                    [LPActionArg argNamed:LPMT_ARG_URL_TRACK withString:LPMT_DEFAULT_TRACK_URL],
                    [LPActionArg argNamed:LPMT_ARG_URL_ACTION withString:LPMT_DEFAULT_ACTION_URL],
                    [LPActionArg argNamed:LPMT_ARG_URL_TRACK_ACTION
                               withString:LPMT_DEFAULT_TRACK_ACTION_URL],
                    [LPActionArg argNamed:LPMT_ARG_HTML_ALIGN withString:LPMT_ARG_HTML_ALIGN_TOP],
                    [LPActionArg argNamed:LPMT_ARG_HTML_HEIGHT withNumber:@0],
                    [LPActionArg argNamed:LPMT_ARG_HTML_WIDTH withString:@"100%"],
                    [LPActionArg argNamed:LPMT_ARG_HTML_Y_OFFSET withString:@"0px"],
                    [LPActionArg argNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE withBool:NO],
                    [LPActionArg argNamed:LPMT_HAS_DISMISS_BUTTON withBool:NO],
                    [LPActionArg argNamed:LPMT_ARG_HTML_TEMPLATE withFile:nil]]
             withResponder:messageResponder];

    [Leanplum defineAction:LPMT_APP_RATING_NAME
                    ofKind:kLeanplumActionKindAction withArguments:@[]
             withResponder:^BOOL(LPActionContext *context) {
                 @try {
                     [self appStorePrompt];
                     return YES;
                 }
                 @catch (NSException *exception) {
                     LOG_LP_MESSAGE_EXCEPTION;
                 }
                 return NO;
             }];

    if ([self hasAlternateIcon]) {
        [Leanplum defineAction:LPMT_ICON_CHANGE_NAME
                        ofKind:kLeanplumActionKindAction
                 withArguments:@[
                                 [LPActionArg argNamed:LPMT_ARG_APP_ICON
                                              withFile:LPMT_DEFAULT_APP_ICON]
                                 ]
                 withResponder:^BOOL(LPActionContext *context) {
                     @try {
                         NSString *filename = [context stringNamed:LPMT_ARG_APP_ICON];
                         [self setAlternateIconWithFilename:filename];
                         return YES;
                     }
                     @catch (NSException *exception) {
                         LOG_LP_MESSAGE_EXCEPTION;
                     }
                     return NO;
                 }];
    }
}

#pragma mark Alert and Confirm Logic

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self alertDismissedWithButtonIndex:buttonIndex];
}

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
    // UI can't be modified in background.
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self showPopup];
        });
        return;
    }
    
    LPActionContext *context = _contexts.lastObject;
    BOOL isFullscreen = [context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME];
    BOOL isWeb = [context.actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME] ||
                 [context.actionName isEqualToString:LPMT_HTML_NAME];
    BOOL isPushAskToAsk = [context.actionName isEqualToString:LPMT_PUSH_ASK_TO_ASK];
    
    if (isWeb) {
        WKWebViewConfiguration* configuration = [WKWebViewConfiguration new];
        configuration.allowsInlineMediaPlayback = YES;
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

        _popupView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    } else {
        _popupView = [[UIView alloc] init];
    }
    
    _popupGroup = [[UIView alloc] init];
    _popupGroup.backgroundColor = [UIColor clearColor];
    if ([context.actionName isEqualToString:LPMT_HTML_NAME]) {
        _popupView.backgroundColor = [UIColor clearColor];
        [_popupView setOpaque:NO];
        ((WKWebView *)_popupView).scrollView.scrollEnabled = NO;
        ((WKWebView *)_popupView).scrollView.bounces = NO;
    }
    
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
                                                 name:UIDeviceOrientationDidChangeNotification
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
    _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
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

- (void)closePopupWithAnimation:(BOOL)animated
{
    [self closePopupWithAnimation:animated actionNamed:nil track:NO];
}

- (void)closePopupWithAnimation:(BOOL)animated
                    actionNamed:(NSString *)actionName
                          track:(BOOL)track
{
    if (!_popupGroup) {
        return;
    }
    
    // UI can't be modified in background.
    if (![NSThread isMainThread]) { 
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self closePopupWithAnimation:animated actionNamed:actionName track:track];
        });
        return;
    }
    
    LPActionContext *context = _contexts.lastObject;
    [_contexts removeLastObject];
    
    if ([[context actionName] isEqualToString:LPMT_WEB_INTERSTITIAL_NAME] ||
        [[context actionName] isEqualToString:LPMT_HTML_NAME] ) {
        ((WKWebView *)_popupView).navigationDelegate = nil;
        [(WKWebView *)_popupView stopLoading];
    }
    
    void (^finishCallback)(void) = ^() {
        [self removeAllViewsFrom:self->_popupGroup];
        
        if (actionName) {
            if (track) {
                [context runTrackedActionNamed:actionName];
            } else {
                [context runActionNamed:actionName];
            }
        }
    };

    if (animated) {
        [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
            [self->_popupGroup setAlpha:0.0];
        } completion:^(BOOL finished) {
            finishCallback();
        }];
    } else {
        finishCallback();
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}

- (void)removeAllViewsFrom:(UIView *)view
{
    [view.subviews enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [self removeAllViewsFrom:obj];
    }];
    [view removeFromSuperview];
    view = nil;
}

- (void)accept
{
    [self closePopupWithAnimation:YES actionNamed:LPMT_ARG_ACCEPT_ACTION track:YES];
}

- (void)dismiss
{
    LP_TRY
    [self closePopupWithAnimation:YES];
    LP_END_TRY
}

- (void)enablePush
{
    [self accept];
    [self enableSystemPush];
}

- (void)deferPush
{
    [self closePopupWithAnimation:YES actionNamed:LPMT_ARG_CANCEL_ACTION track:YES];
}

- (BOOL)isPushEnabled
{
    // Run on main thread.
    if (![NSThread isMainThread]) {
        BOOL __block output = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            output = [self isPushEnabled];
        });
        return output;
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    BOOL enabled;
    
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
    return enabled;
}

- (void)enableSystemPush
{
    // The commented lines below are an alternative for iOS 8 that will deep link to the app in
    // device Settings.
    //    NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    //    [[UIApplication sharedApplication] openURL:appSettings];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_LEANPLUM_ENABLED_PUSH];
    
    // When system asks user for push notification we should also disable our dialog, because
    // if users accept/declines we don't want to show dialog anymore since system will block default one.
    [self disableAskToAsk];
    
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
                       [context.actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME] ||
                       [context.actionName isEqualToString:LPMT_HTML_NAME]);
    BOOL isWeb = [context.actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME] ||
                 [context.actionName isEqualToString:LPMT_HTML_NAME];
    
    BOOL isPushAskToAsk = [context.actionName isEqualToString:LPMT_PUSH_ASK_TO_ASK];

    UIEdgeInsets safeAreaInsets = [self safeAreaInsets];

    CGFloat statusBarHeight = ([[UIApplication sharedApplication] isStatusBarHidden] || !fullscreen) ? safeAreaInsets.top
    : MIN([UIApplication sharedApplication].statusBarFrame.size.height,
          [UIApplication sharedApplication].statusBarFrame.size.width);

    UIInterfaceOrientation orientation;
    orientation = UIInterfaceOrientationPortrait;
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
    
    CGFloat screenWidth = screenSize.width;
    CGFloat screenHeight = screenSize.height;

    if (orientation == UIDeviceOrientationLandscapeLeft ||
        orientation == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenSize.height;
        screenHeight = screenSize.width;
    }
    _popupView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    if (!fullscreen) {
        _popupView.frame = CGRectMake(0, 0, [[context numberNamed:LPMT_ARG_LAYOUT_WIDTH] doubleValue],
                                      [[context numberNamed:LPMT_ARG_LAYOUT_HEIGHT] doubleValue]);
    }
    _popupView.center = CGPointMake(screenWidth / 2.0, screenHeight / 2.0);
    
    if ([context.actionName isEqualToString:LPMT_HTML_NAME]) {
        [self updateHtmlLayoutWithContext:context
                          statusBarHeight:statusBarHeight
                              screenWidth:screenWidth
                             screenHeight:screenHeight];
    }

    if (!isWeb) {
        [self updateNonWebPopupLayout:statusBarHeight isPushAskToAsk:isPushAskToAsk];
        _overlayView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    }
    CGFloat leftSafeAreaX = safeAreaInsets.left;
    CGFloat dismissButtonX = screenWidth - _dismissButton.frame.size.width - LPMT_ACCEPT_BUTTON_MARGIN / 2;
    CGFloat dismissButtonY = statusBarHeight + LPMT_ACCEPT_BUTTON_MARGIN / 2;
    if (!fullscreen) {
        dismissButtonX = _popupView.frame.origin.x + _popupView.frame.size.width - 3 * _dismissButton.frame.size.width / 4;
        dismissButtonY = _popupView.frame.origin.y - _dismissButton.frame.size.height / 4;
    }

    _dismissButton.frame = CGRectMake(dismissButtonX - leftSafeAreaX, dismissButtonY, _dismissButton.frame.size.width,
                                      _dismissButton.frame.size.height);
}

- (void)updateHtmlLayoutWithContext:(LPActionContext *)context
                    statusBarHeight:(CGFloat)statusBarHeight
                        screenWidth:(CGFloat)screenWidth
                       screenHeight:(CGFloat)screenHeight
{
    // Calculate the height. Fullscreen by default.
    CGFloat htmlHeight = [[context numberNamed:LPMT_ARG_HTML_HEIGHT] doubleValue];
    BOOL isFullscreen = htmlHeight < 1;
    UIEdgeInsets safeAreaInsets = [self safeAreaInsets];
    CGFloat bottomSafeAreaHeight = safeAreaInsets.bottom;
    BOOL isIPhoneX = statusBarHeight > 40 || safeAreaInsets.left > 40 || safeAreaInsets.right > 40;
    
    // Banner logic.
    if (!isFullscreen) {
        // Calculate Y Offset.
        CGFloat yOffset = 0;
        NSString *contextArgYOffset = [context stringNamed:LPMT_ARG_HTML_Y_OFFSET];
        if (contextArgYOffset && [contextArgYOffset length] > 0) {
            CGFloat percentRange = screenHeight - htmlHeight - statusBarHeight;
            yOffset = [self valueFromHtmlString:contextArgYOffset percentRange:percentRange];
        }
        
        // HTML banner logic to support top/bottom alignment with dynamic size.
        CGFloat htmlY = yOffset + statusBarHeight;
        NSString *htmlAlign = [context stringNamed:LPMT_ARG_HTML_ALIGN];
        if ([htmlAlign isEqualToString:LPMT_ARG_HTML_ALIGN_BOTTOM]) {
            htmlY = screenHeight - htmlHeight - yOffset;
        }
        
        // Calculate HTML width by percentage or px (it parses any suffix for extra protection).
        NSString *contextArgWidth = [context stringNamed:LPMT_ARG_HTML_WIDTH] ?: @"100%";
        CGFloat htmlWidth = screenWidth;
        if (contextArgWidth && [contextArgWidth length] > 0) {
            htmlWidth = [self valueFromHtmlString:contextArgWidth percentRange:screenWidth];
        }
        
        // Tap outside to close Banner
        if ([context boolNamed:LPMT_ARG_HTML_TAP_OUTSIDE_TO_CLOSE]) {
            _closePopupView = [[LPHitView alloc] initWithCallback:^{
                [self dismiss];
                [self->_closePopupView removeFromSuperview];
            }];
            _closePopupView.frame = CGRectMake(0, 0, screenWidth, screenHeight);
            [[UIApplication sharedApplication].keyWindow addSubview:_closePopupView];
            [[UIApplication sharedApplication].keyWindow bringSubviewToFront:_popupGroup];
        }
        
        CGFloat htmlX = (screenWidth - htmlWidth) / 2.;
        // Offset iPhoneX's safe area.
        if (isIPhoneX) {
            CGFloat bottomDistance = screenHeight - (htmlY + htmlHeight);
            if (bottomDistance < bottomSafeAreaHeight) {
                htmlHeight += bottomSafeAreaHeight;
            }
        }
        _popupGroup.frame = CGRectMake(htmlX, htmlY, htmlWidth, htmlHeight);
        
    } else if (isIPhoneX) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            safeAreaInsets.left = 0;
            safeAreaInsets.right = 0;
            bottomSafeAreaHeight = 0;
        }

        _popupGroup.frame = CGRectMake(safeAreaInsets.left, safeAreaInsets.top,
                                       screenWidth - safeAreaInsets.left - safeAreaInsets.right,
                                       screenHeight - safeAreaInsets.top - bottomSafeAreaHeight);
        
        NSLog(@"frame dim %@ %@", NSStringFromCGRect(_popupGroup.frame), NSStringFromCGSize(_popupGroup.frame.size));
        NSLog(@"screen %f, %f", screenWidth, screenHeight);
        NSLog(@"insets %@", NSStringFromUIEdgeInsets(safeAreaInsets));
    }
    
    _popupView.frame = _popupGroup.bounds;
}

/**
 * Get float value by parsing the html string that can have either % or px as a suffix.
 */
- (CGFloat)valueFromHtmlString:(NSString *)htmlString percentRange:(CGFloat)percentRange
{
    if (!htmlString || [htmlString length] == 0) {
        return 0;
    }

    if ([htmlString hasSuffix:@"%"]) {
        NSString *percentageValue = [htmlString stringByReplacingOccurrencesOfString:@"%"
                                                                          withString:@""];
        return percentRange * [percentageValue floatValue] / 100.;
    }
    
    NSCharacterSet *letterSet = [NSCharacterSet letterCharacterSet];
    NSArray *components = [htmlString componentsSeparatedByCharactersInSet:letterSet];
    return [[components componentsJoinedByString:@""] floatValue];
}

- (CGSize)getTextSizeFromButton:(UIButton *)button
{
    UIFont* font = button.titleLabel.font;
    NSString *text = button.titleLabel.text;
    CGSize textSize = CGSizeZero;
    if ([text respondsToSelector:@selector(sizeWithAttributes:)]) {
        textSize = [text sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:font.fontName size:font.pointSize]}];
    } else
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

- (void)updateNonWebPopupLayout:(int)statusBarHeight isPushAskToAsk:(BOOL)isPushAskToAsk
{
    _popupBackground.frame = CGRectMake(0, 0, _popupView.frame.size.width, _popupView.frame.size.height);
    CGSize textSize = [self getTextSizeFromButton:_acceptButton];

    if (isPushAskToAsk) {
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
        CGFloat acceptButtonY;
        LPActionContext *context = _contexts.lastObject;
        if ([context.actionName isEqualToString:LPMT_INTERSTITIAL_NAME]) {
            acceptButtonY = _popupView.frame.size.height - textSize.height - 3*LPMT_ACCEPT_BUTTON_MARGIN - [self safeAreaInsets].bottom;
        } else {
            acceptButtonY = _popupView.frame.size.height - textSize.height - 3*LPMT_ACCEPT_BUTTON_MARGIN;
        }
        _acceptButton.frame = CGRectMake(
                                         (_popupView.frame.size.width - textSize.width - 2*LPMT_ACCEPT_BUTTON_MARGIN) / 2,
                                         acceptButtonY,
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
        } else if ([actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME] ||
                   [actionName isEqualToString:LPMT_HTML_NAME]) {
            if (_popupGroup) {
                [_popupGroup setHidden:YES];  // Keep hidden until load is done
                WKWebView *webView = (WKWebView *)_popupView;
                _webViewNeedsFade = YES;
                webView.navigationDelegate = self;
                if (@available(iOS 11.0, *)) {
                    webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                }
                if ([actionName isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
                    [webView loadRequest:[NSURLRequest requestWithURL:
                                        [NSURL URLWithString:[context stringNamed:LPMT_ARG_URL]]]];
                } else {
                    if (@available(iOS 9.0, *))
                    {
                        NSURL *htmlURL = [context htmlWithTemplateNamed:LPMT_ARG_HTML_TEMPLATE];
                        // Allow access to base folder.
                        NSString *path = [LPFileManager documentsPath];
                        NSURL* baseURL = [NSURL fileURLWithPath:path isDirectory:YES];

                        [webView loadFileURL:htmlURL allowingReadAccessToURL:baseURL];
                    }
                    else
                    {
                        NSURL *htmlURL = [context htmlWithTemplateNamed:LPMT_ARG_HTML_TEMPLATE];
                        [webView loadRequest:[NSURLRequest requestWithURL:htmlURL]];
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        LOG_LP_MESSAGE_EXCEPTION;
    }
}

-(UIEdgeInsets)safeAreaInsets
{
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    if (@available(iOS 11.0, *)) {
        insets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    } else {
        insets.top = [[UIApplication sharedApplication] isStatusBarHidden] ? 0 : 20.0;
    }
    return insets;
}


- (void)appStorePrompt
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (NSClassFromString(@"SKStoreReviewController")) {
            if (@available(iOS 10.3, *)) {
                [SKStoreReviewController requestReview];
            } else {
                // Fallback on earlier versions
            }
        }
    });
}

- (BOOL)hasAlternateIcon
{
    NSDictionary *bundleIcons = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIcons"];
    NSDictionary *alternativeIconsBundle = bundleIcons[@"CFBundleAlternateIcons"];
    return alternativeIconsBundle && alternativeIconsBundle.count > 0;
}

- (void)setAlternateIconWithFilename:(NSString *)filename
{
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self setAlternateIconWithFilename:filename];
            return;
        });
    }
    
    NSString *iconName = [filename stringByReplacingOccurrencesOfString:LPMT_ICON_FILE_PREFIX
                                                             withString:@""];
    iconName = [iconName stringByReplacingOccurrencesOfString:@".png" withString:@""];

    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(setAlternateIconName:completionHandler:)] &&
        [app respondsToSelector:@selector(alternateIconName)]) {
        // setAlternateIconName:nil sets to the default icon.
        if (iconName && (iconName.length == 0 ||
                         [iconName isEqualToString:LPMT_ICON_PRIMARY_NAME])) {
            iconName = nil;
        }

        if (@available(iOS 10.3, *)) {
            NSString *currentIconName = [app alternateIconName];
            if ((iconName && [iconName isEqualToString:currentIconName]) ||
                (iconName == nil && currentIconName == nil)) {
                return;
            }
        } else {
            // Fallback on earlier versions
        }

        if (@available(iOS 10.3, *)) {
            [app setAlternateIconName:iconName completionHandler:^(NSError * _Nullable error) {
                if (!error) {
                    return;
                }

                // Common failure is when setAlternateIconName: is called right upon start.
                // Try again after 1 second.
                NSLog(@"Fail to change app icon: %@. Trying again.", error);
                dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
                dispatch_after(dispatchTime, dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] setAlternateIconName:iconName
                                                          completionHandler:^(NSError *error) {
                                                              NSLog(@"Fail to change app icon: %@", error);
                                                          }];
                });
            }];
        } else {
            // Fallback on earlier versions
        }
    }
}

#pragma mark - WKWebViewDelegate methods

- (void)showWebview:(WKWebView *)webview {
    [_popupGroup setHidden:NO];
    if (_webViewNeedsFade) {
        _webViewNeedsFade = NO;
        [_popupGroup setAlpha:0.0];
        [UIView animateWithDuration:LPMT_POPUP_ANIMATION_LENGTH animations:^{
            [self->_popupGroup setAlpha:1.0];
        }];
    }
}

- (NSDictionary *)queryComponentsFromUrl:(NSString *)url {
    NSMutableDictionary *components = [NSMutableDictionary new];
    NSArray *urlComponents = [url componentsSeparatedByString:@"?"];
    if ([urlComponents count] > 1) {
        NSString *queryString = urlComponents[1];
        NSArray *parameters = [queryString componentsSeparatedByString:@"&"];
        for (NSString *parameter in parameters) {
            NSArray *parameterComponents = [parameter componentsSeparatedByString:@"="];
            if ([parameterComponents count] > 1) {
                components[parameterComponents[0]] = [parameterComponents[1]
                    stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
            }
        }
    }
    return components;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (webView.isLoading) {
        return;
    }

    // Show for WEB INSTERSTITIAL. HTML will show after js loads the template.
    LPActionContext *context = _contexts.lastObject;
    if ([[context actionName] isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
        [self showWebview:webView];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    LPActionContext *context = _contexts.lastObject;
    @try {

        NSString *url = [navigationAction request].URL.absoluteString;
        NSDictionary *queryComponents = [self queryComponentsFromUrl:url];
        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_CLOSE]].location != NSNotFound) {
            [self dismiss];
            if (queryComponents[@"result"]) {
                [Leanplum track:queryComponents[@"result"]];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        // Only continue for HTML Template. Web Insterstitial will be deprecated.
        if ([[context actionName] isEqualToString:LPMT_WEB_INTERSTITIAL_NAME]) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }

        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_OPEN]].location != NSNotFound) {
            [self showWebview:webView];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_TRACK]].location != NSNotFound) {
            NSString *event = queryComponents[@"event"];
            if (event) {
                double value = [queryComponents[@"value"] doubleValue];
                NSString *info = queryComponents[@"info"];
                NSDictionary *parameters = [self JSONFromString:queryComponents[@"parameters"]];

                if (queryComponents[@"isMessageEvent"]) {
                    [context trackMessageEvent:event
                                     withValue:value
                                       andInfo:info
                                 andParameters: parameters];
                } else {
                    [Leanplum track:event withValue:value andInfo:info andParameters:parameters];
                }
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([url rangeOfString:[context stringNamed:LPMT_ARG_URL_ACTION]].location != NSNotFound) {
            if (queryComponents[@"action"]) {
                [self closePopupWithAnimation:YES actionNamed:queryComponents[@"action"] track:NO];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }

        if ([url rangeOfString:
             [context stringNamed:LPMT_ARG_URL_TRACK_ACTION]].location != NSNotFound) {
            if (queryComponents[@"action"]) {
                [self closePopupWithAnimation:YES actionNamed:queryComponents[@"action"] track:YES];
            }
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    @catch (id exception) {
        // In case we catch exception here, hide the overlaying message.
        [self dismiss];
        // Handle the exception message.
        LOG_LP_MESSAGE_EXCEPTION;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

/**
 * Copied from LPJSON. TODO: Remove when we open source.
 */
- (id)JSONFromString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        return nil;
    }
    return json;
}

/**
 * Helper method
 */

+ (NSString *)urlEncodedStringFromString:(NSString *)urlString {
    NSString *unreserved = @":-._~/?&=";
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet
                                      alphanumericCharacterSet];
    [allowed addCharactersInString:unreserved];
    return [urlString
            stringByAddingPercentEncodingWithAllowedCharacters:
            allowed];
}

@end
