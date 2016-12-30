#ifndef SwrveDemoFramework_SwrveConversationEvents_h
#define SwrveDemoFramework_SwrveConversationEvents_h

#include <Foundation/Foundation.h>

@class SwrveBaseConversation;
@class SwrveConversationPane;

@interface SwrveConversationEvents : NSObject

// Conversation related
+(void)started:(SwrveBaseConversation*)conversation onStartPage:(NSString*)startPageTag;
+(void)done:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)cancel:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag;

// Page related
+(void)impression:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag;
+(void)pageTransition:(SwrveBaseConversation*)conversation fromPage:(NSString*)originPage toPage:(NSString*)toPage withControl:(NSString*)controlTag;

// Actions
+(void)linkVisit:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)callNumber:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)deeplinkVisit:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)permissionRequest:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;

// Atom actions
+(void)gatherAndSendUserInputs:(SwrveConversationPane*)pane forConversation:(SwrveBaseConversation*)conversation;

// Errors
+(void)error:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag;
+(void)error:(SwrveBaseConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
 
@end

#endif
