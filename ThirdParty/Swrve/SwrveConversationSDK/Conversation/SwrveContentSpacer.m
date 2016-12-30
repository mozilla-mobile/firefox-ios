#import "SwrveContentSpacer.h"
#import "SwrveSetup.h"
#import "SwrveConversationStyler.h"

@interface SwrveContentSpacer () {
    NSString *_height;
}
@end

@implementation SwrveContentSpacer

@synthesize height = _height;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentSpacer andDictionary:dict];
    _height = [dict objectForKey:@"height"];
    return self;
}

-(void) loadViewWithContainerView:(UIView*)containerView {
    // Height is defined as 'pixels' so we need to transform it to the point space
    float screenScale = (float)[[UIScreen mainScreen] scale];
    float spacer_height = (_height) ? ([_height floatValue] / screenScale) : 0.0f;
    _view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerView.frame.size.width, spacer_height)];
    [SwrveConversationStyler styleView:_view withStyle:self.style];
    // Notify that the view is ready to be displayed
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

@end
