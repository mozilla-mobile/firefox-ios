@class SwrveMessageController;

/*! PRIVATE: Base campaign methods. */
@interface SwrveBaseCampaign(SwrveBaseCampaignProtected)

@property (retain, nonatomic) NSMutableSet* triggers;
@property (retain, nonatomic) NSDate*       dateStart;
@property (retain, nonatomic) NSDate*       dateEnd;
@property (atomic) BOOL randomOrder;

/*! PRIVATE: Set the message mimimum delay time. */
-(void)setMessageMinDelayThrottle:(NSDate*)timeShown;

/*! PRIVATE: Log the reason for campaigns not being available. */
-(void)logAndAddReason:(NSString*)reason withReasons:(NSMutableDictionary*)campaignReasons;

/*! PRIVATE: Check if it is too soon to display a message after launch. */
-(BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate*)now;

/*! PRIVATE: Check if it is too soon to display a message after a delay. */
-(BOOL)isTooSoonToShowMessageAfterDelay:(NSDate*)now;

/*! PRIVATE: Check that rules pass. */
-(BOOL)checkCampaignRulesForEvent:(NSString*)event
                           atTime:(NSDate*)time
                      withReasons:(NSMutableDictionary*)campaignReasons;

/*! PRIVATE: Check that Triggers are valid. */
-(BOOL)canTriggerWithEvent:(NSString*)event andPayload:(NSDictionary*)payload;

/*! PRIVATE: Notify when the campaign was displayed. */
- (void)wasShownToUserAt:(NSDate *)timeShown;

/*! PRIVATE: Add the required assets to the given queue. */
-(void)addAssetsToQueue:(NSMutableSet*)assetsQueue;

/*! PRIVATE: Load the campaign settings. */
-(void)loadState:(NSDictionary*)settings;

/*! PRIVATE: Returns true if the campaign is active at a given time . */
-(BOOL)isActive:(NSDate*)date withReasons:(NSMutableDictionary*)campaignReasons;

@end
