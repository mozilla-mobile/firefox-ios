#import "Swrve.h"
#import "SwrveMessageViewController.h"
#import "SwrveButton.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface SwrveMessageViewController ()

@property (nonatomic, retain) SwrveMessageFormat* current_format;
@property (nonatomic) BOOL wasShownToUserNotified;
@property (nonatomic) CGFloat viewportWidth;
@property (nonatomic) CGFloat viewportHeight;

@end

@implementation SwrveMessageViewController

@synthesize block;
@synthesize message;
@synthesize current_format;
@synthesize wasShownToUserNotified;
@synthesize viewportWidth;
@synthesize viewportHeight;
@synthesize prefersIAMStatusBarHidden;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    // Default viewport size to whole screen
    CGRect screenRect = [[[UIApplication sharedApplication] keyWindow] bounds];
    self.viewportWidth = screenRect.size.width;
    self.viewportHeight = screenRect.size.height;
    if(SYSTEM_VERSION_LESS_THAN(@"8.0")){
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateBounds];
    [self removeAllViews];
    if(SYSTEM_VERSION_LESS_THAN(@"9.0")){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self addViewForOrientation:[self interfaceOrientation]];
#pragma clang diagnostic pop
    } else {
        [self displayForViewportOfSize:CGSizeMake(self.viewportWidth, self.viewportHeight)];
    }
    if (self.wasShownToUserNotified == NO) {
        [self.message wasShownToUser];
        self.wasShownToUserNotified = YES;
    }
}

-(void)updateBounds
{
    // Update the bounds to the new screen size
    [self.view setFrame:[[UIScreen mainScreen] bounds]];
}

-(void)removeAllViews
{
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
}

-(void)addViewForOrientation:(UIInterfaceOrientation)orientation
{
    current_format = [self.message getBestFormatFor:orientation];
    if (!current_format) {
        // Never leave the screen without a format
        current_format = [self.message.formats objectAtIndex:0];
    }
    
    if (current_format) {
        DebugLog(@"Selected message format: %@", current_format.name);
        [current_format createViewToFit:self.view
                                  thatDelegatesTo:self
                                         withSize:self.view.bounds.size
                                          rotated:false];
        
        // Update background color
        if (current_format.backgroundColor != nil) {
            self.view.backgroundColor = current_format.backgroundColor;
        }
    } else {
        DebugLog(@"Couldn't find a format for message: %@", message.name);
    }
}

-(IBAction)onButtonPressed:(id)sender
{
    UIButton* button = sender;

    SwrveButton* pressed = [current_format.buttons objectAtIndex:(NSUInteger)button.tag];
    [pressed wasPressedByUser];

    self.block(pressed.actionType, pressed.actionString, pressed.appID);
}

#if defined(__IPHONE_8_0)
-(BOOL)prefersStatusBarHidden
{
    if (prefersIAMStatusBarHidden) {
        return YES;
    } else {
        return [super prefersStatusBarHidden];
    }
}
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    self.viewportWidth = size.width;
    self.viewportHeight = size.height;
    [self removeAllViews];
    [self displayForViewportOfSize:CGSizeMake(self.viewportWidth, self.viewportHeight)];    
}
#endif //defined(__IPHONE_8_0)

- (void) displayForViewportOfSize:(CGSize)size
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        float viewportRatio = (float)(size.width/size.height);
        float closestRatio = -1;
        SwrveMessageFormat* closestFormat = nil;
        for (SwrveMessageFormat* format in self.message.formats) {
            float formatRatio = (float)(format.size.width/format.size.height);
            float diffRatio = fabsf(formatRatio - viewportRatio);
            if (closestFormat == nil || (diffRatio < closestRatio)) {
                closestFormat = format;
                closestRatio = diffRatio;
            }
        }
    
        current_format = closestFormat;
        DebugLog(@"Selected message format: %@", current_format.name);
        [current_format createViewToFit:self.view
                       thatDelegatesTo:self
                              withSize:size];
    } else {
        UIInterfaceOrientation currentOrientation = (size.width > size.height)? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait;
        
        BOOL mustRotate = false;
        current_format = [self.message getBestFormatFor:currentOrientation];
        if (!current_format) {
            // Never leave the screen without a format
            current_format = [self.message.formats objectAtIndex:0];
            mustRotate = true;
        }
        
        if (current_format) {
            DebugLog(@"Selected message format: %@", current_format.name);
            [current_format createViewToFit:self.view
                           thatDelegatesTo:self
                                  withSize:size
                                   rotated:mustRotate];
        } else {
            DebugLog(@"Couldn't find a format for message: %@", message.name);
        }
    }
    // Update background color
    if (current_format.backgroundColor != nil) {
        self.view.backgroundColor = current_format.backgroundColor;
    }
}

// iOS 6 and iOS 7 (to be deprecated)
#if defined(__IPHONE_9_0)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif //defined(__IPHONE_9_0)
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        return UIInterfaceOrientationMaskAll;
    } else {
        BOOL portrait = [self.message supportsOrientation:UIInterfaceOrientationPortrait];
        BOOL landscape = [self.message supportsOrientation:UIInterfaceOrientationLandscapeLeft];
        
        if (portrait && landscape) {
            return UIInterfaceOrientationMaskAll;
        }
        
        if (landscape) {
            return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
        }
    }
    
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (void)orientationChanged:(NSNotification *)notification {
    #pragma unused (notification)
    //After a given delay to allow for the correct orientation and view.frame to be calculated. Redraw the Message
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (u_int64_t)0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self viewDidAppear:NO];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    if(SYSTEM_VERSION_LESS_THAN(@"8.0")){
        [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
}

@end
