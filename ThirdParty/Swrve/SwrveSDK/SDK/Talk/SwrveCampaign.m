#import "Swrve.h"
#import "SwrveBaseCampaign.h"
#import "SwrveCampaign.h"
#import "SwrvePrivateBaseCampaign.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#import "SwrveTrigger.h"

@implementation SwrveCampaign

@synthesize messages;

-(id)initAtTime:(NSDate*)time fromJSON:(NSDictionary *)dict withAssetsQueue:(NSMutableSet*)assetsQueue forController:(SwrveMessageController*)controller
{
    id instance = [super initAtTime:time fromJSON:dict withAssetsQueue:assetsQueue forController:controller];
    NSMutableArray* loadedMessages = [[NSMutableArray alloc] init];
    NSArray* campaign_messages = [dict objectForKey:@"messages"];
    for (NSDictionary* messageDict in campaign_messages)
    {
        SwrveMessage* message = [SwrveMessage fromJSON:messageDict forCampaign:self forController:controller];
        [loadedMessages addObject:message];
    }
    self.messages = [loadedMessages copy];
    [self addAssetsToQueue:assetsQueue];
    return instance;
}

-(void)addAssetsToQueue:(NSMutableSet*)assetsQueue
{
    for (SwrveMessage* message in self.messages) {
        for (SwrveMessageFormat* format in message.formats)
        {
            // Add all images to the download queue
            for (SwrveButton* button in format.buttons)
            {
                [assetsQueue addObject:button.image];
            }
            
            for (SwrveImage* image in format.images)
            {
                [assetsQueue addObject:image.file];
            }
        }
    }
}

-(void)messageWasShownToUser:(SwrveMessage *)message
{
    [self messageWasShownToUser:message at:[NSDate date]];
}

-(void)messageWasShownToUser:(SwrveMessage*)message at:(NSDate*)timeShown
{
#pragma unused(message)
    [self wasShownToUserAt:timeShown];

    if (![self randomOrder])
    {
        NSUInteger count = [[self messages] count];
        NSUInteger nextMessage = (self.state.next + 1) % count;
        DebugLog(@"Round Robin message in campaign %ld is %ld (next will be %ld)", (unsigned long)[self ID], (unsigned long)self.state.next, (unsigned long)nextMessage);
        [self.state setNext:nextMessage];
    }
}

-(void)messageDismissed:(NSDate *)timeDismissed
{
    [self setMessageMinDelayThrottle:timeDismissed];
}

static SwrveMessage* firstFormatFrom(NSArray* messages, NSSet* assets)
{
    // Return the first fully downloaded format
    for (SwrveMessage* message in messages) {
        if ([message assetsReady:assets]){
            return message;
        }
    }
    return nil;
}

/**
 * Quick check to see if this campaign might have messages matching this event trigger
 * This is used to decide if the campaign is a valid candidate for automatically showing at session start
 */
-(BOOL)hasMessageForEvent:(NSString*)event {
    
    return [self hasMessageForEvent:event withPayload:nil];
}

-(BOOL)hasMessageForEvent:(NSString*)event withPayload:(NSDictionary *)payload {
    
    return [self canTriggerWithEvent:event andPayload:payload];
}

-(SwrveMessage*)getMessageForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
{
    return [self getMessageForEvent:event withPayload:nil withAssets:assets atTime:time withReasons:nil];
}


-(SwrveMessage*)getMessageForEvent:(NSString*)event
                       withPayload:(NSDictionary *)payload
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
                       withReasons:(NSMutableDictionary*)campaignReasons {
    
    if (![self hasMessageForEvent:event withPayload:payload]){
        
        DebugLog(@"There is no trigger in %ld that matches %@", (long)self.ID, event);
        [self logAndAddReason:[NSString stringWithFormat:@"There is no trigger in %ld that matches %@ with conditions %@", (long)self.ID, event, payload] withReasons:campaignReasons];
        return nil;
    }

    if ([[self messages] count] == 0)
    {
        [self logAndAddReason:[NSString stringWithFormat:@"No messages in campaign %ld", (long)self.ID] withReasons:campaignReasons];
        return nil;
    }

    if (![self checkCampaignRulesForEvent:event atTime:time withReasons:campaignReasons]) {
        return nil;
    }

    SwrveMessage* message = nil;
    if (self.randomOrder)
    {
        DebugLog(@"Random Message in %ld", (long)self.ID);
        NSArray* shuffled = [SwrveMessageController shuffled:self.messages];
        message = firstFormatFrom(shuffled, assets);
    }

    if (message == nil)
    {
        message = [self.messages objectAtIndex:(NSUInteger)self.state.next];
    }
    
    if ([message assetsReady:assets]) {
        DebugLog(@"%@ matches a trigger in %ld", event, (long)self.ID);
        return message;
    }
    
    [self logAndAddReason:[NSString stringWithFormat:@"Campaign %ld hasn't finished downloading", (long)self.ID] withReasons:campaignReasons];
    return nil;
}

-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationUnknown) {
        return YES;
    }
    
    for (SwrveMessage* message in self.messages) {
        if ([message supportsOrientation:orientation]){
            return YES;
        }
    }
    return NO;
}

-(BOOL)assetsReady:(NSSet *)assets
{
    for (SwrveMessage* message in self.messages) {
        if (![message assetsReady:assets]){
            return NO;
        }
    }
    return YES;
}

@end
