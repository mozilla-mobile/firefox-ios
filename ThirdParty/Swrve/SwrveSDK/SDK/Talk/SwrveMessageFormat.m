#import "Swrve.h"
#import "SwrveMessageFormat.h"
#import "SwrveMessageController.h"
#import "SwrveButton.h"
#import "SwrveImage.h"

@implementation SwrveMessageFormat

@synthesize images;
@synthesize text;
@synthesize size;
@synthesize buttons;
@synthesize name;
@synthesize scale;
@synthesize language;
@synthesize orientation;
@synthesize backgroundColor;

+(CGPoint)getCenterFrom:(NSDictionary*)data
{
    NSNumber* x = [(NSDictionary*)[data objectForKey:@"x"] objectForKey:@"value"];
    NSNumber* y = [(NSDictionary*)[data objectForKey:@"y"] objectForKey:@"value"];
    return CGPointMake(x.floatValue, y.floatValue);
}

+(CGSize)getSizeFrom:(NSDictionary*)data
{
    NSNumber* w = [(NSDictionary*)[data objectForKey:@"w"] objectForKey:@"value"];
    NSNumber* h = [(NSDictionary*)[data objectForKey:@"h"] objectForKey:@"value"];
    return CGSizeMake(w.floatValue, h.floatValue);
}

+(float)getFontSizeFrom:(NSDictionary*)json
{
    NSDictionary* fontSize = [json objectForKey:@"font_size"];
    id value    = [fontSize objectForKey:@"value"];
    return [value floatValue];
}

+(SwrveImage*)createImage:(NSDictionary*)imageData
{
    SwrveImage* image = [[SwrveImage alloc] init];
    image.file = [(NSDictionary*)[imageData objectForKey:@"image"] objectForKey:@"value"];
    image.center = [SwrveMessageFormat getCenterFrom:imageData];
    image.size   = [SwrveMessageFormat getSizeFrom:imageData];

    DebugLog(@"Image Loaded: Asset: \"%@\" (w: %g h: %g x: %g y: %g)",
          image.file,
          image.size.width,
          image.size.height,
          image.center.x,
          image.center.y);

    return image;
}

+(SwrveButton*)createButton:(NSDictionary*)buttonData
              forController:(SwrveMessageController*)controller
                 forMessage:(SwrveMessage*)message
{
    SwrveButton* button = [[SwrveButton alloc] init];
    button.controller = controller;
    button.message = message;
    
    button.name       = [buttonData objectForKey:@"name"];
    button.center     = [SwrveMessageFormat getCenterFrom:buttonData];
    button.size       = [SwrveMessageFormat getSizeFrom:buttonData];
    button.image      = [(NSDictionary*)[buttonData objectForKey:@"image_up"] objectForKey:@"value"];
    button.messageID  = [message.messageID integerValue];

    // Set up the action for the button.
    button.actionType   = kSwrveActionDismiss;
    button.appID       = 0;
    button.actionString = @"";

    NSString* buttonType = [(NSDictionary*)[buttonData objectForKey:@"type"] objectForKey:@"value"];
    if ([buttonType isEqualToString:@"INSTALL"]){
        button.actionType   = kSwrveActionInstall;
        button.appID       = [[(NSDictionary*)[buttonData objectForKey:@"game_id"] objectForKey:@"value"] integerValue];
        button.actionString = [controller getAppStoreURLForGame:button.appID];

    } else if ([buttonType isEqualToString:@"CUSTOM"]) {
        button.actionType   = kSwrveActionCustom;
        button.actionString = [(NSDictionary*)[buttonData objectForKey:@"action"] objectForKey:@"value"];
    }

    return button;
}

static CGFloat extractHex(NSString* color, NSUInteger index) {
    NSString* componentString = [color substringWithRange:NSMakeRange(index, 2)];
    unsigned hexResult;
    [[NSScanner scannerWithString:componentString] scanHexInt: &hexResult];
    return hexResult / 255.0f;
}

-(id)initFromJson:(NSDictionary*)json forController:(SwrveMessageController*)controller forMessage:(SwrveMessage*)message
{
    self = [super init];

    self.name     = [json objectForKey:@"name"];
    self.language = [json objectForKey:@"language"];
    
    NSString* jsonOrientation = [json objectForKey:@"orientation"];
    if (jsonOrientation)
    {
        self.orientation = ([jsonOrientation caseInsensitiveCompare:@"landscape"] == NSOrderedSame)? SWRVE_ORIENTATION_LANDSCAPE : SWRVE_ORIENTATION_PORTRAIT;
    }
    
    NSString* jsonColor = [json objectForKey:@"color"];
    if (jsonColor)
    {
        NSString* hexColor = [jsonColor uppercaseString];
        CGFloat alpha = 0, red = 0, blue = 0, green = 0;
        switch ([hexColor length]) {
            case 6: // #RRGGBB
                alpha = 1.0f;
                red   = extractHex(hexColor, 0);
                green = extractHex(hexColor, 2);
                blue  = extractHex(hexColor, 4);
                break;
            case 8: // #AARRGGBB
                alpha = extractHex(hexColor, 0);
                red   = extractHex(hexColor, 2);
                green = extractHex(hexColor, 4);
                blue  = extractHex(hexColor, 6);
                break;
        }
        self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }
    
    // If doesn't exist default to 1.0
    NSNumber * jsonScale = [json objectForKey:@"scale"];
    if (jsonScale != nil)
    {
        self.scale = [jsonScale floatValue];
    }
    else
    {
        self.scale = 1.0;
    }
    
    self.size = [SwrveMessageFormat getSizeFrom:[json objectForKey:@"size"]];

    DebugLog(@"Format %@ Scale: %g  Size: %gx%g", self.name, self.scale, self.size.width, self.size.height);
    
    NSArray* jsonButtons = [json objectForKey:@"buttons"];
    NSMutableArray* loadedButtons = [[NSMutableArray alloc] init];
    
    for (NSDictionary* jsonButton in jsonButtons)
    {
        [loadedButtons addObject:[SwrveMessageFormat createButton:jsonButton forController:controller forMessage:message]];
    }

    self.buttons = [NSArray arrayWithArray:loadedButtons];

    self.text = [[NSArray alloc]init];

    NSMutableArray* loadedImages = [[NSMutableArray alloc] init];

    NSArray* jsonImages = [json objectForKey:@"images"];
    for (NSDictionary* jsonImage in jsonImages) {

        [loadedImages addObject:[SwrveMessageFormat createImage:jsonImage]];
    }

    self.images = [NSArray arrayWithArray:loadedImages];

    return self;
}

-(UIView*)createViewToFit:(UIView*)view
              thatDelegatesTo:(UIViewController*)delegate
                     withSize:(CGSize)sizeParent
                      rotated:(BOOL)rotated
{
    CGRect containerViewSize = CGRectMake(0, 0, sizeParent.width, sizeParent.height);
    if (rotated) {
        containerViewSize = CGRectMake(0, 0, sizeParent.height, sizeParent.width);
    }
    UIView* containerView = [[UIView alloc] initWithFrame:containerViewSize];
    
    // Find the center point of the view
    CGFloat half_screen_width = sizeParent.width/2;
    CGFloat half_screen_height = sizeParent.height/2;
    
    CGFloat logical_half_screen_width = (rotated)? half_screen_height : half_screen_width;
    CGFloat logical_half_screen_height = (rotated)? half_screen_width : half_screen_height;
    
    // Adjust scale, accounting for retina devices
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGFloat renderScale = self.scale / screenScale;
    
    DebugLog(@"MessageViewFormat scale :%g", self.scale);
    DebugLog(@"UI scale :%g", screenScale);
    
    NSString* cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString* swrve_folder = @"com.ngt.msgs";
    [self addImageViews:containerView cachePath:cache swrveFolderPath:swrve_folder centerX:logical_half_screen_width centerY:logical_half_screen_height scale:renderScale];
    [self addButtonViews:containerView delegate:delegate centerX:logical_half_screen_width centerY:logical_half_screen_height scale:renderScale];
    
    if (rotated) {
        containerView.transform = CGAffineTransformMakeRotation((CGFloat)M_PI_2);
    }
    [containerView setCenter:CGPointMake(half_screen_width, half_screen_height)];
    [view addSubview:containerView];
    return containerView;
}

-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)sizeParent
{
    // Calculate the scale needed to fit the format in the current viewport
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    float wscale = (float)((sizeParent.width * screenScale)/self.size.width);
    float hscale = (float)((sizeParent.height * screenScale)/self.size.height);
    float viewportScale = (wscale < hscale)? wscale : hscale;
    
    CGRect containerViewSize = CGRectMake(0, 0, sizeParent.width, sizeParent.height);
    UIView* containerView = [[UIView alloc] initWithFrame:containerViewSize];
    
    // Find the center point of the view
    CGFloat centerX = sizeParent.width/2;
    CGFloat centerY = sizeParent.height/2;
    
    // Adjust scale, accounting for retina devices
    CGFloat renderScale = (self.scale / screenScale) * viewportScale;
    
    DebugLog(@"MessageViewFormat scale :%g", self.scale);
    DebugLog(@"UI scale :%g", screenScale);
    
    NSString* cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString* swrve_folder = @"com.ngt.msgs";
    [self addImageViews:containerView cachePath:cache swrveFolderPath:swrve_folder centerX:centerX centerY:centerY scale:renderScale];
    [self addButtonViews:containerView delegate:delegate centerX:centerX centerY:centerY scale:renderScale];
    
    [containerView setCenter:CGPointMake(centerX, centerY)];
    [view addSubview:containerView];
    return containerView;
}

-(void)addButtonViews:(UIView*)containerView delegate:(UIViewController*)delegate centerX:(CGFloat)centerX centerY:(CGFloat)centerY scale:(CGFloat)renderScale
{
    SEL buttonPressedSelector = NSSelectorFromString(@"onButtonPressed:");
    int buttonTag = 0;
    for (SwrveButton* button in self.buttons)
    {
        UIButton* buttonView = [button createButtonWithDelegate:delegate
                                                    andSelector:buttonPressedSelector
                                                        andScale:(float)renderScale
                                                      andCenterX:(float)centerX
                                                      andCenterY:(float)centerY];
        buttonView.tag = buttonTag;
        
        NSString * buttonType;
        switch (button.actionType) {
            case kSwrveActionInstall:
                buttonType = @"Install";
                break;
            case kSwrveActionDismiss:
                buttonType = @"Dismiss";
                break;
            default:
                buttonType = @"Custom";
        }
        
        buttonView.accessibilityLabel = [NSString stringWithFormat:@"TalkButton_%d_%@", buttonTag, buttonType];
        [containerView addSubview:buttonView];
        buttonTag++;
    }
}

-(void)addImageViews:(UIView*)containerView cachePath:(NSString*)cachePath swrveFolderPath:(NSString*)swrveFolderPath centerX:(CGFloat)centerX centerY:(CGFloat)centerY scale:(CGFloat)renderScale
{
    for (SwrveImage* backgroundImage in self.images)
    {
        NSURL* bgurl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cachePath, swrveFolderPath, backgroundImage.file, nil]];
        UIImage* background = [UIImage imageWithData:[NSData dataWithContentsOfURL:bgurl]];
        
        CGRect frame = CGRectMake(0, 0,
                                  background.size.width * renderScale,
                                  background.size.height * renderScale);
        
        
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.image = background;
        [imageView setCenter:CGPointMake(centerX + (backgroundImage.center.x * renderScale),
                                         centerY + (backgroundImage.center.y * renderScale))];
        [containerView addSubview:imageView];
    }
}
@end
