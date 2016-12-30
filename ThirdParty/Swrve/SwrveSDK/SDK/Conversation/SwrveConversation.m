#import "Swrve.h"
#import "SwrveContentItem.h"
#import "SwrveConversation.h"
#import "SwrveConversationPane.h"

@interface SwrveConversation()

@property (nonatomic, weak)     SwrveMessageController* controller;

@end

@implementation SwrveConversation

@synthesize controller, campaign, conversationID, name, pages, priority;

-(SwrveConversation*) updateWithJSON:(NSDictionary*)json
                         forCampaign:(SwrveConversationCampaign*)_campaign
                       forController:(SwrveMessageController*)_controller
{
    [self updateWithJSON:json forController:_controller];
    self.campaign       = _campaign;
    
    if ([json objectForKey:@"priority"]) {
        self.priority   = [json objectForKey:@"priority"];
    } else {
        self.priority   = [NSNumber numberWithInt:9999];
    }
    return self;
}

+(SwrveConversation*) fromJSON:(NSDictionary*)json
                   forCampaign:(SwrveConversationCampaign*)campaign
                 forController:(SwrveMessageController*)controller
{
    return [[[SwrveConversation alloc] init] updateWithJSON:json forCampaign:campaign forController:controller];
}

@end
