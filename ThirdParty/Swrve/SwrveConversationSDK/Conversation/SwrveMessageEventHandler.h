#import <Foundation/Foundation.h>

@class SwrveBaseConversation;

@protocol SwrveMessageEventHandler <NSObject>

/*! Notify that a message was shown to the user.
 *
 * \param message Message that was shown to the user.
 */
- (void)conversationWasShownToUser:(SwrveBaseConversation*)conversation;

/*! Notify that the latest conversation was dismissed. */
- (void) conversationClosed;

@end
