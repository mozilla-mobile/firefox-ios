#import "SwrveCommon.h"
#import "SwrveMessageEventHandler.h"
#import "SwrveContentItem.h"
#import "SwrveBaseConversation.h"
#import "SwrveConversationPane.h"

@interface SwrveBaseConversation()

@property (nonatomic, weak)     id<SwrveMessageEventHandler> controller;

@end

@implementation SwrveBaseConversation

@synthesize controller, conversationID, name, pages;

-(SwrveBaseConversation*) updateWithJSON:(NSDictionary*)json
                             forController:(id<SwrveMessageEventHandler>)_controller
{
    self.controller     = _controller;
    self.conversationID = [json objectForKey:@"id"];
    self.name           = [json objectForKey:@"name"];
    
    NSArray* jsonPages  = [json objectForKey:@"pages"];
    NSMutableArray* loadedPages = [[NSMutableArray alloc] init];
    for (NSDictionary* pageJson in jsonPages) {
        [loadedPages addObject:[[SwrveConversationPane alloc] initWithDictionary:pageJson]];
    }
    self.pages = loadedPages;
    return self;
}

+(SwrveBaseConversation*) fromJSON:(NSDictionary*)json
                       forController:(id<SwrveMessageEventHandler>)controller
{
    SwrveBaseConversation* conversation = [[[SwrveBaseConversation alloc] init] updateWithJSON:json forController:controller];
    
    if((nil == controller) || (nil == conversation.conversationID) || (nil == conversation.name) || (nil == conversation.pages)) {
        return nil;
    }
    
    return conversation;
}

+(UIStoryboard*) loadStoryboard
{
    return [UIStoryboard storyboardWithName:@"SwrveConversation" bundle:[NSBundle bundleForClass:[SwrveBaseConversation class]]];
}

-(BOOL)assetsReady:(NSSet*)assets {
    for (SwrveConversationPane* page in self.pages) {
        for (SwrveContentItem* contentItem in page.content) {
            if([contentItem.type isEqualToString:kSwrveContentTypeImage]) {
                if (![assets containsObject:contentItem.value]) {
                    DebugLog(@"Conversation asset not yet downloaded: %@", contentItem.value);
                    return false;
                }
            }
        }
    }
    return true;
}

-(void)wasShownToUser {
    id<SwrveMessageEventHandler> c = self.controller;
    if (c != nil) {
        [c conversationWasShownToUser:self];
    }
}

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index {
    if (index > self.pages.count - 1) {
        return nil;
    } else {
        return [self.pages objectAtIndex:index];
    }
}

-(SwrveConversationPane*)pageForTag:(NSString*)tag {
    for (SwrveConversationPane *page in self.pages) {
        if ([tag isEqualToString:page.tag]) {
            return page;
        }
    }
    return nil;
}

@end
