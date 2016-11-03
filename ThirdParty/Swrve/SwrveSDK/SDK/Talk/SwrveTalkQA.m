#import "SwrveTalkQA.h"
#import "SwrveCampaign.h"
#import "SwrveConversationCampaign.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

enum
{
    // The API version of this file.
    // This is sent to the server on each call, and should not be modified.
    QA_API_VERSION = 1,
    
    // This is the minimum time between session requests
    REST_SESSION_INTERVAL = 1000,

    // This is the minimum time between trigger requests
    REST_TRIGGER_INTERVAL = 500
};


@interface Swrve (SwrveTalkQATests)

- (void) sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

@end

@interface SwrveTalkQA()

@property (nonatomic) Swrve* swrve;
@property (nonatomic) NSOperationQueue* queue;
@property (nonatomic, retain) NSString* loggingUrl;
@property (nonatomic) double lastSessionRequestTime;
@property (nonatomic) double lastTriggerRequestTime;

@end

@implementation SwrveTalkQA

@synthesize resetDevice;
@synthesize logging;
@synthesize swrve;
@synthesize queue;
@synthesize loggingUrl;
@synthesize lastSessionRequestTime;
@synthesize lastTriggerRequestTime;

-(id)initWithJSON:(NSDictionary*)qaJson withAnalyticsSDK:(Swrve*)_swrve
{
    self = [super init];
    self.swrve = _swrve;
    
    self.resetDevice = [[qaJson objectForKey:@"reset_device_state"] boolValue];
    self.logging = [[qaJson objectForKey:@"logging"] boolValue];
    if (self.logging) {
        self.loggingUrl = [qaJson objectForKey:@"logging_url"];;
        self.queue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

-(BOOL)canMakeRequest {
    return (self.swrve && self.logging);
}

-(BOOL)canMakeSessionRequest {
    if ([self canMakeRequest]) {
        double currentTime = [NSDate timeIntervalSinceReferenceDate] * 1000;
        if (self.lastSessionRequestTime == 0 || (currentTime - self.lastSessionRequestTime) > REST_SESSION_INTERVAL) {
            self.lastSessionRequestTime = currentTime;
            return TRUE;
        }
    }
    
    return NO;
}

-(BOOL)canMakeTriggerRequest {
    if ([self canMakeRequest]) {
        double currentTime = [NSDate timeIntervalSinceReferenceDate] * 1000;
        if (self.lastTriggerRequestTime == 0 || (currentTime - self.lastTriggerRequestTime) > REST_TRIGGER_INTERVAL) {
            self.lastTriggerRequestTime = currentTime;
            return TRUE;
        }
    }
    
    return NO;
}

-(void)talkSession:(NSDictionary*)campaignsDownloaded
{
    if ([self canMakeSessionRequest]) {
        NSString* endpoint = [NSString stringWithFormat:@"%@/talk/game/%@/user/%@/session", self.loggingUrl, self.swrve.apiKey, self.swrve.userID];
        NSMutableDictionary* talkSessionJson = [[NSMutableDictionary alloc] init];
        
        // Add campaigns (downloaded or not) to request
        NSMutableArray* campaignsJson = [[NSMutableArray alloc] init];
        
        for (id campaignId in campaignsDownloaded) {
            NSString* reason = [campaignsDownloaded objectForKey:campaignId];
            
            NSMutableDictionary* campaignInfo = [[NSMutableDictionary alloc] init];
            [campaignInfo setValue:campaignId forKey:@"id"];
            [campaignInfo setValue:((reason == NULL)? @"" : reason) forKey:@"reason"];
            [campaignInfo setValue:[NSNumber numberWithBool:(reason == NULL || [reason length] == 0)] forKey:@"loaded"];
            
            [campaignsJson addObject:campaignInfo];
        }
        
        [talkSessionJson setValue:campaignsJson forKey:@"campaigns"];
        // Add device info to request
        NSDictionary* deviceJson = self.swrve.deviceInfo;
        [talkSessionJson setValue:deviceJson forKey:@"device"];
        [self makeRequest:endpoint withJSON:talkSessionJson];
    }
}

-(void)triggerFailure:(NSString*)event withReason:(NSString*)globalReason
{
    if ([self canMakeTriggerRequest]) {
        NSString* endpoint = [NSString stringWithFormat:@"%@/talk/game/%@/user/%@/trigger", self.loggingUrl, self.swrve.apiKey, self.swrve.userID];
        
        NSMutableArray* emptyCampaigns = [[NSMutableArray alloc] init];
        NSMutableDictionary* triggerJson = [[NSMutableDictionary alloc] init];
        [triggerJson setValue:event forKey:@"trigger_name"];
        [triggerJson setValue:[NSNumber numberWithBool:NO] forKey:@"displayed"];
        [triggerJson setValue:globalReason forKey:@"reason"];
        [triggerJson setValue:emptyCampaigns forKey:@"campaigns"];
        [self makeRequest:endpoint withJSON:triggerJson];
    }
}

-(void)trigger:(NSString*)event withMessage:(SwrveMessage*)messageShown withReason:(NSDictionary*)campaignReasons withMessages:(NSDictionary*)campaignMessages
{
    if ([self canMakeTriggerRequest]) {
        NSString* endpoint = [NSString stringWithFormat:@"%@/talk/game/%@/user/%@/trigger", self.loggingUrl, self.swrve.apiKey, self.swrve.userID];
        
        NSMutableDictionary* triggerJson = [[NSMutableDictionary alloc] init];
        [triggerJson setValue:event forKey:@"trigger_name"];
        [triggerJson setValue:[NSNumber numberWithBool:(messageShown != NULL)] forKey:@"displayed"];
        [triggerJson setValue:(messageShown == NULL)? @"The loaded campaigns returned no message" : @"" forKey:@"reason"];
        
        // Add campaigns that were not displayed
        NSMutableArray* campaignsJson = [[NSMutableArray alloc] init];
        for (id campaignId in campaignReasons) {
            NSString* reason = [campaignReasons objectForKey:campaignId];
            NSNumber* messageId = [campaignMessages objectForKey:campaignId];
            if(messageId == NULL) {
                messageId = [NSNumber numberWithInt:-1];
            }

            NSMutableDictionary* campaignInfo = [[NSMutableDictionary alloc] init];
            [campaignInfo setValue:campaignId forKey:@"id"];
            [campaignInfo setValue:[NSNumber numberWithBool:NO] forKey:@"displayed"];
            [campaignInfo setValue:messageId forKey:@"message_id"];
            [campaignInfo setValue:reason forKey:@"reason"];
            [campaignsJson addObject:campaignInfo];
        }
        
        // Add campaign that was shown, if available
        if (messageShown != NULL) {
            NSMutableDictionary* campaignInfo = [[NSMutableDictionary alloc] init];
            SwrveCampaign* c = messageShown.campaign;
            if (c != nil) {
                [campaignInfo setValue:[NSNumber numberWithUnsignedInteger:c.ID] forKey:@"id"];
            }
            [campaignInfo setValue:[NSNumber numberWithBool:TRUE] forKey:@"displayed"];
            [campaignInfo setValue:messageShown.messageID forKey:@"message_id"];
            [campaignInfo setValue:@"" forKey:@"reason"];
            [campaignsJson addObject:campaignInfo];
        }
        
        [triggerJson setValue:campaignsJson forKey:@"campaigns"];
        [self makeRequest:endpoint withJSON:triggerJson];
    }
}

-(void)trigger:(NSString*)event withConversation:(SwrveConversation*)conversationShow withReason:(NSDictionary*)campaignReasons
{
    if ([self canMakeTriggerRequest]) {
        NSString* endpoint = [NSString stringWithFormat:@"%@/talk/game/%@/user/%@/trigger", self.loggingUrl, self.swrve.apiKey, self.swrve.userID];
        
        NSMutableDictionary* triggerJson = [[NSMutableDictionary alloc] init];
        [triggerJson setValue:event forKey:@"trigger_name"];
        [triggerJson setValue:[NSNumber numberWithBool:(conversationShow != NULL)] forKey:@"displayed"];
        [triggerJson setValue:(conversationShow == NULL)? @"The loaded campaigns returned no conversation" : @"" forKey:@"reason"];
        
        // Add campaigns that were not displayed
        NSMutableArray* campaignsJson = [[NSMutableArray alloc] init];
        for (id campaignId in campaignReasons) {
            NSString* reason = [campaignReasons objectForKey:campaignId];
            NSMutableDictionary* campaignInfo = [[NSMutableDictionary alloc] init];
            [campaignInfo setValue:campaignId forKey:@"id"];
            [campaignInfo setValue:[NSNumber numberWithBool:NO] forKey:@"displayed"];
            [campaignInfo setValue:reason forKey:@"reason"];
            [campaignsJson addObject:campaignInfo];
        }
        
        // Add campaign that was shown, if available
        if (conversationShow != NULL) {
            NSMutableDictionary* campaignInfo = [[NSMutableDictionary alloc] init];
            SwrveConversationCampaign* c = conversationShow.campaign;
            if (c != nil) {
                [campaignInfo setValue:[NSNumber numberWithUnsignedInteger:c.ID] forKey:@"id"];
            }
            [campaignInfo setValue:[NSNumber numberWithBool:TRUE] forKey:@"displayed"];
            [campaignInfo setValue:conversationShow.conversationID forKey:@"message_id"];
            [campaignInfo setValue:@"" forKey:@"reason"];
            [campaignsJson addObject:campaignInfo];
        }
        
        [triggerJson setValue:campaignsJson forKey:@"campaigns"];
        [self makeRequest:endpoint withJSON:triggerJson];
    }
}

-(void)updateDeviceInfo
{
    if ([self canMakeRequest]) {
        NSString* endpoint = [NSString stringWithFormat:@"%@/talk/game/%@/user/%@/device_info", self.loggingUrl, self.swrve.apiKey, self.swrve.userID];
        NSMutableDictionary* deviceJson = [NSMutableDictionary dictionaryWithDictionary:self.swrve.deviceInfo];
        [self makeRequest:endpoint withJSON:deviceJson];
    }
}

-(void)pushNotification:(NSDictionary*)notification
{
    if ([self canMakeTriggerRequest]) {

        NSString* redirect = self.loggingUrl;
        NSString* endpoint = [NSString stringWithFormat:@"%@/talk/game/%@/user/%@/push", redirect, self.swrve.apiKey, self.swrve.userID];

        NSDictionary* aps = [notification valueForKey:@"aps"];
        NSMutableDictionary* note = [[NSMutableDictionary alloc] init];
        [note setValue:[aps valueForKey:@"alert"] forKey:@"alert"];
        [note setValue:[aps valueForKey:@"sound"] forKey:@"sound"];
        [note setValue:[aps valueForKey:@"badge"] forKey:@"badge"];

        // Notify push notification id if available
        id push_identifier = [notification objectForKey:@"_p"];
        if (push_identifier && ![push_identifier isKindOfClass:[NSNull class]]) {
            [note setValue:push_identifier forKey:@"id"];
        }
    
        [self makeRequest:endpoint withJSON:note];
    }
}

-(NSString*)getTimeFormatted {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *now = [NSDate date];
    return [dateFormatter stringFromDate:now];
}

-(void)makeRequest:(NSString*)endpoint withJSON:(NSMutableDictionary*)json
{
    // Add common parameters
    [json setValue:[NSNumber numberWithInt:QA_API_VERSION] forKey:@"version"];
    [json setValue:[self getTimeFormatted] forKey:@"client_time"];
    
    NSURL* requestURL = [NSURL URLWithString:endpoint];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    
    [[self swrve] sendHttpPOSTRequest:requestURL
                             jsonData:jsonData
                    completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
                    {
                        if (error) {
                            DebugLog(@"Talk QA Error: %@", error);
                        } else if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
                            DebugLog(@"Talk QA response was not a HTTP response: %@", response);
                        } else {
                            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                            long status = [httpResponse statusCode];
                            NSString* responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            DebugLog(@"HTTP Send to QA Log %ld", status);
                                           
                            if (status != 200){
                                #pragma unused(responseBody)
                                DebugLog(@"HTTP Error %ld while doing Talk QA", status);
                                DebugLog(@"  %@", responseBody);
                            }
                        }
                    }];
}

@end
