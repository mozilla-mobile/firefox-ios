#import "SwrveConversationResourceManagement.h"
#import "SwrveSetup.h"

#if defined(__IPHONE_8_0)
#import <UIKit/UITraitCollection.h>
#endif

@implementation SwrveConversationResourceManagement

+ (UIImage *) imageWithName:(NSString *)imageName {
    
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return [UIImage imageNamed:imageName];
    }
        
    return [UIImage imageNamed:imageName inBundle:[NSBundle bundleForClass:[SwrveConversationResourceManagement class]] compatibleWithTraitCollection: nil];
}

@end
