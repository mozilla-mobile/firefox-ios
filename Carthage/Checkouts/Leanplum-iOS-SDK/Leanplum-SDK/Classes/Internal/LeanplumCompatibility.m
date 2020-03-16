//
//  LeanplumCompatibility.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"
#import "LeanplumCompatibility.h"
#import "LPConstants.h"
#import "LPCountAggregator.h"

@implementation LeanplumCompatibility

NSString *TYPE = @"&t";
NSString *EVENT_CATEGORY = @"&ec";
NSString *EVENT_ACTION = @"&ea";
NSString *EVENT_LABEL = @"&el";
NSString *EVENT_VALUE = @"&ev";
NSString *EXCEPTION_DESCRIPTION = @"&exd";
NSString *TRANSACTION_AFFILIATION = @"&ta";
NSString *ITEM_NAME = @"&in";
NSString *ITEM_CATEGORY = @"&iv";
NSString *SOCIAL_NETWORK = @"&sn";
NSString *SOCIAL_ACTION = @"&sa";
NSString *SOCIAL_TARGET = @"&st";
NSString *TIMING_NAME = @"&utv";
NSString *TIMING_CATEGORY = @"&utc";
NSString *TIMING_LABEL = @"&utl";
NSString *TIMING_VALUE = @"&utt";
NSString *CAMPAIGN_SOURCE = @"&cs";
NSString *CAMPAIGN_NAME = @"&cn";
NSString *CAMPAIGN_MEDUIM = @"&cm";
NSString *CAMPAIGN_CONTENT = @"&cc";

+ (NSString *)getEventNameFromParams:(NSMutableDictionary *)params andKeys:(NSArray *)keys
{
    NSMutableArray *resultValues = [[NSMutableArray alloc] init];
    for (NSString *key in keys) {
        if(params[key] && ![params[key] isKindOfClass:[NSNull class]]) {
            [resultValues addObject:params[key]];
            [params removeObjectForKey:key];
        }
    }
    return [resultValues componentsJoinedByString:@" "];
}

+ (void)gaTrack:(NSObject *)trackingObject
{
    [[LPCountAggregator sharedAggregator] incrementCount:@"ga_track"];
    
    LP_TRY
    if ([trackingObject isKindOfClass:[NSString class]]) {
        [Leanplum track:(NSString *)trackingObject];
    } else if ([trackingObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *trackingObjectDict = [trackingObject mutableCopy];
        NSString *event = @"";
        NSNumber *value = nil;
        
        // Event.
        if (trackingObjectDict[EVENT_CATEGORY] ||
            trackingObjectDict[EVENT_ACTION] ||
            trackingObjectDict[EVENT_LABEL]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                     @[ EVENT_CATEGORY, EVENT_ACTION, EVENT_LABEL ]];
            if (trackingObjectDict[EVENT_VALUE] &&
                ![trackingObjectDict[EVENT_VALUE] isKindOfClass:[NSNull class]]) {
                value = (NSNumber *)trackingObjectDict[EVENT_VALUE];
            }
            if (value) {
                [trackingObjectDict removeObjectForKey:EVENT_VALUE];
            }
            // Exception.
        } else if (trackingObjectDict[EXCEPTION_DESCRIPTION]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                     @[ EXCEPTION_DESCRIPTION, TYPE ]];
            // Transaction.
        } else if (trackingObjectDict[TRANSACTION_AFFILIATION]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                     @[ TRANSACTION_AFFILIATION, TYPE ]];
            // Item.
        } else if (trackingObjectDict[ITEM_CATEGORY] ||
                   trackingObjectDict[ITEM_NAME]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                     @[ ITEM_CATEGORY, ITEM_NAME, TYPE ]];
            // Social.
        } else if (trackingObjectDict[SOCIAL_NETWORK] ||
                   trackingObjectDict[SOCIAL_ACTION] ||
                   trackingObjectDict[SOCIAL_TARGET]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                     @[ SOCIAL_NETWORK, SOCIAL_ACTION, SOCIAL_TARGET ]];
            // Timing.
        } else if (trackingObjectDict[TIMING_CATEGORY] ||
                   trackingObjectDict[TIMING_NAME] ||
                   trackingObjectDict[TIMING_LABEL]) {
            event = [LeanplumCompatibility getEventNameFromParams:trackingObjectDict andKeys:
                     @[ TIMING_CATEGORY, TIMING_NAME, TIMING_LABEL, TYPE ]];
            if (trackingObjectDict[TIMING_VALUE] &&
                ![trackingObjectDict[TIMING_VALUE] isKindOfClass:[NSNull class]]) {
                value = (NSNumber *)trackingObjectDict[TIMING_VALUE];
            }
            if (value) {
                [trackingObjectDict removeObjectForKey:TIMING_VALUE];
            }
            // We are skipping traffic source events.
        } else if (trackingObjectDict[CAMPAIGN_MEDUIM] ||
                   trackingObjectDict[CAMPAIGN_CONTENT] ||
                   trackingObjectDict[CAMPAIGN_NAME] ||
                   trackingObjectDict[CAMPAIGN_SOURCE]) {
            return;
        } else {
            return;
        }
        
        // Clear NSNull values
        for(NSString *key in trackingObjectDict.allKeys) {
            if ([trackingObjectDict[key] isKindOfClass:[NSNull class]]) {
                [trackingObjectDict removeObjectForKey:key];
            }
        }
        
        // Event value.
        if (value) {
            [Leanplum track:event
                  withValue:value.doubleValue
              andParameters:trackingObjectDict];
        } else {
            [Leanplum track:event withParameters:trackingObjectDict];
        }
    }
    LP_END_TRY
}


@end
