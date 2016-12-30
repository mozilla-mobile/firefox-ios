#import "SwrveContentItem.h"
#import "SwrveSetup.h"

@implementation SwrveContentItem
@synthesize value = _value;

#define kSwrveKeyValue @"value" 

-(id) initWithTag:(NSString *)tag type:(NSString *)type andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:type];
    if(self) {
        _value = [dict objectForKey:kSwrveKeyValue];
        self.delegate = self;
    }
    return self;
}

- (void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
#pragma unused (orientation)
}

+(UIScrollView*) scrollView:(UIWebView*)web {
    if ([web respondsToSelector:@selector(scrollView)]) {
        return [web scrollView];
    } else {
        UIScrollView *v = nil;
        for (UIView* subview in [web subviews]) {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                v = (UIScrollView*)subview;
                break;
            }
        }
        return v;
    }
}
@end
