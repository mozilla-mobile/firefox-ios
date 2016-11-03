#import "SwrveBaseCampaign.h"
#import "SwrveConversation.h"

@class SwrveMessageController;

/*! In-app conversation campaign. */
@interface SwrveConversationCampaign : SwrveBaseCampaign

@property (atomic, retain)    SwrveConversation*  conversation;     /*!< Conversation attached to this campaign. */
@property (nonatomic, retain) NSArray* filters;                     /*!< Filters needed to display this campaign. */


/*! Check if the campaign has any conversation setup for the
 * given trigger and parameters associated
 *
 * \param event Trigger event.
 * \returns TRUE if the campaign contains a conversation for the
 * given trigger.
 */
-(BOOL)hasConversationForEvent:(NSString*)event;

/*! Check if the campaign has any conversation setup for the
 * given trigger and parameters associated
 *
 * \param event Trigger event.
 * \param paramters Dictionary of parameters associated (nullable)
 * \returns TRUE if the campaign contains a conversation for the
 * given trigger.
 */
-(BOOL)hasConversationForEvent:(NSString*)event withPayload:(NSDictionary *)payload;

/*! Search for a conversation with the given trigger event and that satisfies
 * the specific rules for the campaign.
 *
 * \param event Trigger event.
 * \param withAssets Set of downloaded assets.
 * \param time Device time.
 * \returns Conversation setup for the given trigger or nil.
 */
-(SwrveConversation*)getConversationForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time;

/*! Search for a message with the given trigger event and that satisfies
 * the specific rules for the campaign.
 *
 * \param event Trigger event.
 * \param withAssets Set of downloaded assets.
 * \param time Device time.
 * \param campaignReasons Will contain the reason the campaign returned no message.
 * \returns Message setup for the given trigger or nil.
 */
-(SwrveConversation*)getConversationForEvent:(NSString*)event
                                 withPayload:(NSDictionary*)payload
                                  withAssets:(NSSet*)assets
                                      atTime:(NSDate*)time
                                 withReasons:(NSMutableDictionary*)campaignReasons;

/*! Notify that a conversation was shown to the user.
 *
 * \param conversation Conversation that was shown to the user.
 */
-(void)conversationWasShownToUser:(SwrveConversation*)conversation;

-(void)conversationWasShownToUser:(SwrveConversation*)conversation at:(NSDate*)timeShown;

/*! Notify that a conversation was dismissed.
 *
 * \param timeDismissed When was the conversation dismissed.
 */
-(void)conversationDismissed:(NSDate*)timeDismissed;

@end
