#import "SwrveCommon.h"

static id<SwrveCommonDelegate> _sharedInstance = NULL;

@implementation SwrveCommon

+(void) addSharedInstance:(id<SwrveCommonDelegate>)sharedInstance
{
    _sharedInstance = sharedInstance;
}

+(id<SwrveCommonDelegate>) sharedInstance
{
    return _sharedInstance;
}

@end
