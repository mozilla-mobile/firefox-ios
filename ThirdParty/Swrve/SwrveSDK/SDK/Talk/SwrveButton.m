#import "SwrveButton.h"

@interface SwrveButton()

@end

@implementation SwrveButton

@synthesize name;
@synthesize image;
@synthesize actionString;
@synthesize controller;
@synthesize message;
@synthesize center;
@synthesize size;
@synthesize messageID;
@synthesize appID;
@synthesize actionType;

static CGPoint scaled(CGPoint point, float scale)
{
    return CGPointMake(point.x * scale, point.y * scale);
}

-(id)init
{
    self = [super init];
    self.name         = NULL;
    self.image        = @"buttonup.png";
    self.actionString = @"";
    self.appID       = 0;
    self.actionType   = kSwrveActionDismiss;
    self.center   = CGPointMake(100, 100);
    self.size     = CGSizeMake(100, 20);
    return self;
}

-(UIButton*)createButtonWithDelegate:(id)delegate
                            andSelector:(SEL)selector
                               andScale:(float)scale
                             andCenterX:(float)cx
                             andCenterY:(float)cy
{
    NSString* cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString* swrve_folder = @"com.ngt.msgs";
    
    NSURL* url_up = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cache, swrve_folder, image, nil]];
    UIImage* up   = [UIImage imageWithData:[NSData dataWithContentsOfURL:url_up]];

    UIButton* result;
    if (up) {
        result = [UIButton buttonWithType:UIButtonTypeCustom];
        [result setBackgroundImage:up forState:UIControlStateNormal];
    }
    else {
        result = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    }
    
    [result  addTarget:delegate action:selector forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat width  = self.size.width;
    CGFloat height = self.size.height;

    if (up) {
        width  = [up size].width;
        height = [up size].height;
    }

    CGPoint position = scaled(self.center, scale);
    [result setFrame:CGRectMake(0, 0, width * scale, height * scale)];
    [result setCenter: CGPointMake(position.x + cx, position.y + cy)];

    return result;
}

-(void)wasPressedByUser
{
    SwrveMessageController* c = self.controller;
    if (c != nil) {
        [c buttonWasPressedByUser:self];
    }
}

@end
