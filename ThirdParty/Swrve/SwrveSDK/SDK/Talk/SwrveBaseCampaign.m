#import "Swrve.h"
#import "SwrveBaseCampaign.h"
#import "SwrvePrivateBaseCampaign.h"
#import "SwrveTrigger.h"

const static int  DEFAULT_MAX_IMPRESSIONS        = 99999;
const static int  DEFAULT_DELAY_FIRST_MSG        = 180;
const static int  DEFAULT_MIN_DELAY_BETWEEN_MSGS = 60;

@implementation SwrveCampaignState

@synthesize campaignID;
@synthesize next;
@synthesize impressions;
@synthesize status;
@synthesize showMsgsAfterDelay;

-(id)initWithID:(NSUInteger)ID {
    if (self = [super init]) {
        self.campaignID = ID;
        self.status = SWRVE_CAMPAIGN_STATUS_UNSEEN;
    }
    return self;
}

-(id)initWithJSON:(NSDictionary*)data {
    if (self = [super init]) {
        NSNumber* idJson = [data objectForKey:@"ID"];
        if (idJson != nil) {
            self.campaignID = idJson.unsignedIntegerValue;
        }        
        NSNumber* nextJson = [data objectForKey:@"next"];
        if (nextJson != nil) {
            self.next = nextJson.unsignedIntegerValue;
        }
        NSNumber* impressionsJson = [data objectForKey:@"impressions"];
        if (impressionsJson != nil) {
            self.impressions = impressionsJson.unsignedIntegerValue;
        }
        NSNumber* statusJson = [data objectForKey:@"status"];
        if (statusJson != nil) {
            self.status = (SwrveCampaignStatus)statusJson.unsignedIntegerValue;
        }
    }
    
    return self;
}

-(NSDictionary*)asDictionary {
    NSMutableDictionary* state = [[NSMutableDictionary alloc] init];
    [state setValue:[NSNumber numberWithUnsignedInteger:self.campaignID] forKey:@"ID"];
    [state setValue:[NSNumber numberWithUnsignedInteger:self.impressions] forKey:@"impressions"];
    [state setValue:[NSNumber numberWithUnsignedInteger:self.status] forKey:@"status"];
    [state setValue:[NSNumber numberWithUnsignedInteger:self.next] forKey:@"next"];
    return state;
}

@end

@interface SwrveBaseCampaign()
@property (retain, nonatomic) NSDate*       dateEnd;
@property (retain, nonatomic) NSMutableSet* triggers;
@property (retain, nonatomic) NSDate* initialisedTime;
@property (atomic) BOOL randomOrder;
@end

@implementation SwrveBaseCampaign

@synthesize ID;
@synthesize maxImpressions;
@synthesize minDelayBetweenMsgs;
@synthesize state;
@synthesize showMsgsAfterLaunch;
@synthesize name;
@synthesize dateStart;
@synthesize dateEnd;
@synthesize triggers;
@synthesize initialisedTime;
@synthesize randomOrder;
@synthesize messageCenter;
@synthesize subject;

-(id)initAtTime:(NSDate*)time fromJSON:(NSDictionary *)dict withAssetsQueue:(NSMutableSet*)assetsQueue forController:(SwrveMessageController*)controller
{
    #pragma unused(assetsQueue, controller)
    if (self = [super init]) {
        // Default both dates to now
        NSDate* now = [NSDate date];
        [self setDateStart:now];
        [self setDateEnd:now];
        
        [self setMaxImpressions:DEFAULT_MAX_IMPRESSIONS];
        [self setMinDelayBetweenMsgs:DEFAULT_MIN_DELAY_BETWEEN_MSGS];
        [self setInitialisedTime:time];
        [self setShowMsgsAfterLaunch:[[self initialisedTime] dateByAddingTimeInterval:DEFAULT_DELAY_FIRST_MSG]];
        
        [self setTriggers:[[NSMutableSet alloc] init]];
        
        // Load from JSON
        self.ID   = [[dict objectForKey:@"id"] unsignedIntegerValue];
        self.name = [dict objectForKey:@"name"];
        self.messageCenter = [[dict objectForKey:@"message_center"] boolValue];
        NSString* subjectString = [dict objectForKey:@"subject"];
        self.subject = (subjectString == (id)[NSNull null])? @"" : subjectString;
        self.state = [[SwrveCampaignState alloc] initWithID:self.ID];
        
        [self loadTriggersFrom:dict];
        [self loadRulesFrom:   dict];
        [self loadDatesFrom:   dict];
    }
    return self;
}

-(void)setMessageMinDelayThrottle:(NSDate*)timeShown
{
    self.state.showMsgsAfterDelay = [timeShown dateByAddingTimeInterval:self.minDelayBetweenMsgs];
}

-(void)wasShownToUserAt:(NSDate*)timeShown
{
    self.state.impressions += 1;
    [self setMessageMinDelayThrottle:timeShown];
    self.state.status = SWRVE_CAMPAIGN_STATUS_SEEN;
}

static NSDate* read_date(id d, NSDate* default_date)
{
    double millis = [d doubleValue];
    
    if (millis > 0){
        double seconds = millis / 1000.0;
        return [NSDate dateWithTimeIntervalSince1970:seconds];
    } else {
        return default_date;
    }
}

-(void)loadDatesFrom:(NSDictionary*)json
{
    self.dateStart = read_date([json objectForKey:@"start_date"], self.dateStart);
    self.dateEnd   = read_date([json objectForKey:@"end_date"],   self.dateEnd);
}

-(void)loadRulesFrom:(NSDictionary*)json
{
    NSDictionary* rules = [json objectForKey:@"rules"];
    DebugLog(@"Rules: %@", rules);
    self.randomOrder = [[rules objectForKey:@"display_order"] isEqualToString: @"random"];
    NSNumber* jsonMaxImpressions = [rules objectForKey:@"dismiss_after_views"];
    if (jsonMaxImpressions != nil)
    {
        self.maxImpressions = jsonMaxImpressions.unsignedIntegerValue;
    }
    
    NSNumber* delayFirstMsg = [rules objectForKey:@"delay_first_message"];
    if (delayFirstMsg != nil)
    {
        self.showMsgsAfterLaunch = [self.initialisedTime dateByAddingTimeInterval:delayFirstMsg.integerValue];
    }
    
    NSNumber* jsonMinDelayBetweenMsgs = [rules objectForKey:@"min_delay_between_messages"];
    if (jsonMinDelayBetweenMsgs != nil)
    {
        self.minDelayBetweenMsgs = [jsonMinDelayBetweenMsgs doubleValue];
    }
}

-(void)loadTriggersFrom:(NSDictionary*)json {
    
    NSArray *triggerArray = [SwrveTrigger initTriggersFromDictionary:json];
    if (!triggerArray){
        DebugLog(@"Error loading triggers", nil);
        return;
    }else{
        [self.triggers addObjectsFromArray:triggerArray];
    }
}

-(BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate*)now
{
    return [now compare:[self showMsgsAfterLaunch]] == NSOrderedAscending;
}

-(BOOL)isTooSoonToShowMessageAfterDelay:(NSDate*)now
{
    return [now compare:self.state.showMsgsAfterDelay] == NSOrderedAscending;
}

-(void)logAndAddReason:(NSString*)reason withReasons:(NSMutableDictionary*)campaignReasons
{
    if(campaignReasons != nil) {
        [campaignReasons setValue:reason forKey:[[NSNumber numberWithUnsignedInteger:self.ID] stringValue]];
        DebugLog(@"%@",reason);
    }
}

-(BOOL)isActive:(NSDate*)time withReasons:(NSMutableDictionary*)campaignReasons
{
    if ([self.dateStart compare:time] != NSOrderedAscending)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld has not started yet", (long)self.ID] withReasons:campaignReasons];
        return FALSE;
    }
    
    if ([time compare:self.dateEnd] != NSOrderedAscending)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld has finished", (long)self.ID] withReasons:campaignReasons];
        return FALSE;
    }
    
    return TRUE;
}

-(BOOL)checkCampaignRulesForEvent:(NSString*)event
                           atTime:(NSDate*)time
                      withReasons:(NSMutableDictionary*)campaignReasons
{
    if (![self isActive:time withReasons:campaignReasons])
    {
        return FALSE;
    }
    
    // Ignore delay after launch throttle limit for auto show messages
    if ([event caseInsensitiveCompare:AUTOSHOW_AT_SESSION_START_TRIGGER] != NSOrderedSame && [self isTooSoonToShowMessageAfterLaunch:time])
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Too soon after launch. Wait until %@", [SwrveMessageController getTimeFormatted:self.showMsgsAfterLaunch]] withReasons:campaignReasons];
        return FALSE;
    }
    
    if ([self isTooSoonToShowMessageAfterDelay:time])
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Too soon after last message. Wait until %@", [SwrveMessageController getTimeFormatted:self.state.showMsgsAfterDelay]] withReasons:campaignReasons];
        return FALSE;
    }
    
    if (self.state.impressions >= self.maxImpressions)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"{Campaign throttle limit} Campaign %ld has been shown %ld times already", (long)self.ID, (long)self.maxImpressions] withReasons:campaignReasons];
        return FALSE;
    }
    
    return TRUE;
}

-(BOOL)canTriggerWithEvent:(NSString*)event andPayload:(NSDictionary*)payload {
    
    if([self triggers] != nil) {
        for (SwrveTrigger *trigger in [self triggers]) {
            
            if([trigger.eventName isEqualToString:[event lowercaseString]]) {
                
                DebugLog(@"checking conditions for %@", event);
                if([trigger.conditions count] > 0) {
                    
                    if([trigger canTriggerWithPayload:payload]) {
                        return YES;
                    }
                }else {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

-(void)addAssetsToQueue:(NSMutableSet*)assetsQueue
{
#pragma unused(assetsQueue)
    // Implemented in sub classes
}

-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
#pragma unused(orientation)
    return NO;
}

-(BOOL)assetsReady:(NSSet *)assets
{
#pragma unused(assets)
    // Implemented in sub classes
    return NO;
}

-(NSDictionary*)stateDictionary
{
    return [self.state asDictionary];
}

@end
