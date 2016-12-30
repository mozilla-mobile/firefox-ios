#import <CommonCrypto/CommonHMAC.h>
#import "SwrveMessageController.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveCampaign.h"
#import "SwrveConversationCampaign.h"
#import "SwrveTalkQA.h"
#import "SwrveConversationsNavigationController.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationContainerViewController.h"
#import "SwrvePermissions.h"
#import "SwrveInternalAccess.h"
#import "SwrvePrivateBaseCampaign.h"
#import "SwrveTrigger.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSString* swrve_folder         = @"com.ngt.msgs";
static NSString* swrve_campaign_cache = @"cmcc2.json";
static NSString* swrve_campaign_cache_signature = @"cmccsgt2.txt";
static NSString* swrve_device_token_key = @"swrve_device_token";
static NSArray* SUPPORTED_DEVICE_FILTERS;
static NSArray* SUPPORTED_STATIC_DEVICE_FILTERS;
static NSArray* ALL_SUPPORTED_DYNAMIC_DEVICE_FILTERS;

const static int CAMPAIGN_VERSION            = 6;
const static int CAMPAIGN_RESPONSE_VERSION   = 2;
const static int DEFAULT_DELAY_FIRST_MESSAGE = 150;
const static int DEFAULT_MAX_SHOWS           = 99999;
const static int DEFAULT_MIN_DELAY           = 55;

@interface Swrve(PrivateMethodsForMessageController)
@property BOOL campaignsAndResourcesInitialized;
@property (atomic) int locationSegmentVersion;
-(void) setPushNotificationsDeviceToken:(NSData*)deviceToken;
-(void) pushNotificationReceived:(NSDictionary*)userInfo;
-(void) invalidateETag;
-(NSDate*) getNow;
@end

@interface Swrve (SwrveHelperMethods)
- (CGRect) getDeviceScreenBounds;
- (NSString*) getSignatureKey;
- (void) sendHttpGETRequest:(NSURL*)url completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;
@end

@interface SwrveCampaign(PrivateMethodsForMessageController)
-(void)messageWasShownToUser:(SwrveMessage*)message at:(NSDate*)timeShown;
@end

@interface SwrveMessageController()

@property (nonatomic, retain) NSString*             user;
@property (nonatomic, retain) NSString*             cdnRoot;
@property (nonatomic, retain) NSString*             apiKey;
@property (nonatomic, retain) NSArray*              campaigns; // List of campaigns available to the user.
@property (nonatomic, retain) NSMutableDictionary*  campaignsState; // Serializable state of the campaigns.
@property (nonatomic, retain) NSString*           	server;
@property (nonatomic, retain) NSMutableSet*         assetsOnDisk;
@property (nonatomic, retain) NSString*             cacheFolder;
@property (nonatomic, retain) NSString*             campaignCache;
@property (nonatomic, retain) NSString*             campaignCacheSignature;
@property (nonatomic, retain) SwrveSignatureProtectedFile* campaignFile;
@property (nonatomic, retain) NSString*             language; // ISO language code
@property (nonatomic, retain) NSFileManager*        manager;
@property (nonatomic, retain) NSMutableDictionary*  appStoreURLs;
@property (nonatomic, retain) NSMutableArray*       notifications;
@property (nonatomic, retain) NSString*             settingsPath;
@property (nonatomic, retain) NSDate*               initialisedTime; // SDK init time
@property (nonatomic, retain) NSDate*               showMessagesAfterLaunch; // Only show messages after this time.
@property (nonatomic, retain) NSDate*               showMessagesAfterDelay; // Only show messages after this time.
#if !defined(SWRVE_NO_PUSH)
@property (nonatomic)         bool                  pushEnabled; // Decide if push notification is enabled
@property (nonatomic, retain) NSSet*                pushNotificationEvents; // Events that trigger the push notification dialog
#endif //!defined(SWRVE_NO_PUSH)
@property (nonatomic, retain) NSMutableSet*         assetsCurrentlyDownloading;
@property (nonatomic)         bool                  autoShowMessagesEnabled;
@property (nonatomic, retain) UIWindow*             inAppMessageWindow;
@property (nonatomic, retain) UIWindow*             conversationWindow;
@property (nonatomic)         SwrveActionType       inAppMessageActionType;
@property (nonatomic, retain) NSString*             inAppMessageAction;
@property (nonatomic)         bool                  prefersIAMStatusBarHidden;

// Current Device Properties
@property (nonatomic) int device_width;
@property (nonatomic) int device_height;
@property (nonatomic) SwrveInterfaceOrientation orientation;


// Only ever show this many messages. This number is decremented each time a
// message is shown.
@property (atomic) long messagesLeftToShow;
@property (atomic) NSTimeInterval minDelayBetweenMessage;

// QA
@property (nonatomic) SwrveTalkQA* qaUser;

// Private functions
- (void) initCampaignsFromCacheFile;
@end

@implementation SwrveMessageController

@synthesize server, cdnRoot, apiKey;
@synthesize cacheFolder;
@synthesize campaignCache;
@synthesize campaignCacheSignature;
@synthesize campaignFile;
@synthesize manager;
@synthesize settingsPath;
@synthesize initialisedTime;
@synthesize showMessagesAfterLaunch;
@synthesize showMessagesAfterDelay;
@synthesize messagesLeftToShow;
@synthesize inAppMessageBackgroundColor;
@synthesize conversationLightboxColor;
@synthesize campaigns;
@synthesize campaignsState;
@synthesize user;
@synthesize assetsOnDisk;
@synthesize notifications;
@synthesize language;
@synthesize appStoreURLs;
#if !defined(SWRVE_NO_PUSH)
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize assetsCurrentlyDownloading;
@synthesize inAppMessageWindow;
@synthesize conversationWindow;
@synthesize inAppMessageActionType;
@synthesize inAppMessageAction;
@synthesize device_width;
@synthesize device_height;
@synthesize orientation;
@synthesize qaUser;
@synthesize autoShowMessagesEnabled;
@synthesize analyticsSDK;
@synthesize minDelayBetweenMessage;
@synthesize showMessageDelegate;
@synthesize customButtonCallback;
@synthesize installButtonCallback;
@synthesize showMessageTransition;
@synthesize hideMessageTransition;
@synthesize swrveConversationItemViewController;
@synthesize prefersIAMStatusBarHidden;

+ (void)initialize {
    ALL_SUPPORTED_DYNAMIC_DEVICE_FILTERS = [NSArray arrayWithObjects:
        [[swrve_permission_location_always stringByAppendingString:swrve_permission_requestable] lowercaseString],
        [[swrve_permission_location_when_in_use stringByAppendingString:swrve_permission_requestable] lowercaseString],
        [[swrve_permission_photos stringByAppendingString:swrve_permission_requestable] lowercaseString],
        [[swrve_permission_camera stringByAppendingString:swrve_permission_requestable] lowercaseString],
        [[swrve_permission_contacts stringByAppendingString:swrve_permission_requestable] lowercaseString],
        [[swrve_permission_push_notifications stringByAppendingString:swrve_permission_requestable] lowercaseString], nil];
    SUPPORTED_STATIC_DEVICE_FILTERS = [NSArray arrayWithObjects:@"ios", nil];
    SUPPORTED_DEVICE_FILTERS = [NSMutableArray arrayWithArray:SUPPORTED_STATIC_DEVICE_FILTERS];
    [(NSMutableArray*)SUPPORTED_DEVICE_FILTERS addObjectsFromArray:ALL_SUPPORTED_DYNAMIC_DEVICE_FILTERS];
}

- (id)initWithSwrve:(Swrve*)sdk
{
    self = [super init];
    CGRect screen_bounds = [sdk getDeviceScreenBounds];
    self.device_height = (int)screen_bounds.size.width;
    self.device_width  = (int)screen_bounds.size.height;
    self.orientation   = sdk.config.orientation;
    self.prefersIAMStatusBarHidden = sdk.config.prefersIAMStatusBarHidden;

    self.language           = sdk.config.language;
    self.user               = sdk.userID;
    self.apiKey             = sdk.apiKey;
    self.server             = sdk.config.contentServer;
    self.analyticsSDK       = sdk;
#if !defined(SWRVE_NO_PUSH)
    self.pushEnabled        = sdk.config.pushEnabled;
    self.pushNotificationEvents = sdk.config.pushNotificationEvents;
#endif //!defined(SWRVE_NO_PUSH)
    self.cdnRoot            = @"https://content-cdn.swrve.com/messaging/message_image/";
    self.appStoreURLs       = [[NSMutableDictionary alloc] init];
    self.assetsOnDisk       = [[NSMutableSet alloc] init];
    self.inAppMessageBackgroundColor    = sdk.config.defaultBackgroundColor;
    self.conversationLightboxColor = sdk.config.conversationLightBoxColor;
    [self migrateAndSetFileLocations];
    self.manager            = [NSFileManager defaultManager];
    self.notifications      = [[NSMutableArray alloc] init];
    self.assetsCurrentlyDownloading = [[NSMutableSet alloc] init];
    self.autoShowMessagesEnabled = YES;

    // Game rule defaults
    self.initialisedTime = [sdk getNow];
    self.showMessagesAfterLaunch  = [sdk getNow];
    self.messagesLeftToShow = LONG_MAX;

    DebugLog(@"Swrve Messaging System initialised: Server: %@ Game: %@",
             self.server,
             self.apiKey);

    SwrveMessageController * __weak weakSelf = self;
    [sdk setEventQueuedCallback:^(NSDictionary *eventPayload, NSString *eventsPayloadAsJSON) {
#pragma unused(eventsPayloadAsJSON)
        SwrveMessageController * strongSelf = weakSelf;
        if (strongSelf != nil) {
            [strongSelf eventRaised:eventPayload];
        }
    }];

    NSAssert1([self.language length] > 0, @"Invalid language specified %@", self.language);
    NSAssert1([self.user     length] > 0, @"Invalid username specified %@", self.user);
    NSAssert(self.analyticsSDK != NULL,   @"Swrve Analytics SDK is null", nil);

#if !defined(SWRVE_NO_PUSH)
    NSData* device_token = [[NSUserDefaults standardUserDefaults] objectForKey:swrve_device_token_key];
    if (self.pushEnabled && device_token) {
        // Once we have a device token, ask for it every time
        [self registerForPushNotifications];
        [self setDeviceToken:device_token];
    }
#endif //!defined(SWRVE_NO_PUSH)

    self.campaignsState = [[NSMutableDictionary alloc] init];
    // Initialize campaign cache file
    [self initCampaignsFromCacheFile];

    self.showMessageTransition = [CATransition animation];
    self.showMessageTransition.type = kCATransitionPush;
    self.showMessageTransition.subtype = kCATransitionFromBottom;
    self.showMessageTransition.duration = 0.25;
    self.showMessageTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    self.showMessageTransition.removedOnCompletion = YES;

    self.hideMessageTransition = [CATransition animation];
    self.hideMessageTransition.type = kCATransitionPush;
    self.hideMessageTransition.subtype = kCATransitionFromTop;
    self.hideMessageTransition.duration = 0.25;
    self.hideMessageTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    self.hideMessageTransition.removedOnCompletion = YES;
    self.hideMessageTransition.delegate = self;

    return self;
}

- (void)migrateAndSetFileLocations {
    NSString* cacheRoot     = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString* applicationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    self.cacheFolder        = [cacheRoot stringByAppendingPathComponent:swrve_folder];
    
    self.settingsPath       = [applicationSupport stringByAppendingPathComponent:@"com.swrve.messages.settings.plist"];
    self.campaignCache      = [applicationSupport stringByAppendingPathComponent:swrve_campaign_cache];
    self.campaignCacheSignature = [applicationSupport stringByAppendingPathComponent:swrve_campaign_cache_signature];
    
    // Files were in this locations in lower than 4.5.1 (caches dir) and we need to move them to the new location
    NSString* oldSettingsPath       = [cacheRoot stringByAppendingPathComponent:@"com.swrve.messages.settings.plist"];
    NSString* oldCampaignCache      = [cacheRoot stringByAppendingPathComponent:swrve_campaign_cache];
    NSString* oldCampaignCacheSignature = [cacheRoot stringByAppendingPathComponent:swrve_campaign_cache_signature];
    [SwrveMessageController migrateOldCacheFile:oldSettingsPath withNewPath:self.settingsPath];
    [SwrveMessageController migrateOldCacheFile:oldCampaignCache withNewPath:self.campaignCache];
    [SwrveMessageController migrateOldCacheFile:oldCampaignCacheSignature withNewPath:self.campaignCacheSignature];
}

+ (void) migrateOldCacheFile:(NSString*)oldPath withNewPath:(NSString*)newPath {
    // Old file defaults to cache directory, should be moved to new location
    if ([[NSFileManager defaultManager] isReadableFileAtPath:oldPath]) {
        [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:newPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:newPath error:nil];
    }
}

#if !defined(SWRVE_NO_PUSH)
-(void)registerForPushNotifications
{
    [SwrvePermissions requestPushNotifications:self.analyticsSDK withCallback:NO];
}
#endif //!defined(SWRVE_NO_PUSH)

- (void)campaignsStateFromDisk:(NSMutableDictionary*)states
{
    NSData* data = [NSData dataWithContentsOfFile:[self settingsPath]];
    if(!data)
    {
        DebugLog(@"Error: No campaigns states loaded. [Reading from %@]", [self settingsPath]);
        return;
    }

    NSError* error = NULL;
    NSArray* loadedStates = [NSPropertyListSerialization propertyListWithData:data
                                                                        options:NSPropertyListImmutable
                                                                         format:NULL
                                                                          error:&error];
    if (error) {
        DebugLog(@"Could not load campaign states from disk.\nError: %@\njson: %@", error, data);
    } else {
        for (NSDictionary* dicState in loadedStates)
        {
            SwrveCampaignState* state = [[SwrveCampaignState alloc] initWithJSON:dicState];
            NSString* stateKey = [NSString stringWithFormat:@"%lu", (unsigned long)state.campaignID];
            [states setValue:state forKey:stateKey];
        }
    }
}

- (void)saveCampaignsState
{
    NSMutableArray* newStates = [[NSMutableArray alloc] initWithCapacity:self.campaignsState.count];
    [self.campaignsState enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop)
    {
#pragma unused(key, stop)
        [newStates addObject:[value asDictionary]];
    }];

    NSError*  error = NULL;
    NSData*   data = [NSPropertyListSerialization dataWithPropertyList:newStates
                                                                format:NSPropertyListXMLFormat_v1_0
                                                               options:0
                                                                 error:&error];

    if (error) {
        DebugLog(@"Could not serialize campaign states.\nError: %@\njson: %@", error, newStates);
    } else if(data)
    {
        BOOL success = [data writeToFile:[self settingsPath] atomically:YES];
        if (!success)
        {
            DebugLog(@"Error saving campaigns state to: %@", [self settingsPath]);
        }
    }
    else
    {
        DebugLog(@"Error saving campaigns state: %@ writing to %@", error, [self settingsPath]);
    }
}

- (void) initCampaignsFromCacheFile
{
    // Create campaign cache folder
    NSError* error;
    if (![manager createDirectoryAtPath:self.cacheFolder
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error])
    {
        DebugLog(@"Error creating %@: %@", self.cacheFolder, error);
    }

    // Create signature protected cache file
    NSURL* fileURL = [NSURL fileURLWithPath:self.campaignCache];
    NSURL* signatureURL = [NSURL fileURLWithPath:self.campaignCacheSignature];
    campaignFile = [[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:[self.analyticsSDK getSignatureKey]];

    // Read from cache the state of campaigns
    [self campaignsStateFromDisk:self.campaignsState];

    // Read content of campaigns file and update campaigns
    NSData* content = [campaignFile readFromFile];
    if (content != nil) {
        NSError* jsonError;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:0 error:&jsonError];
        if (!jsonError) {
            [self updateCampaigns:jsonDict];
        }
    } else {
        [self.analyticsSDK invalidateETag];
    }
}

static NSNumber* numberFromJsonWithDefault(NSDictionary* json, NSString* key, int defaultValue)
{
    NSNumber* result = [json objectForKey:key];
    if (result == nil) {
        result = [NSNumber numberWithInt:defaultValue];
    }
    return result;
}

-(void) writeToCampaignCache:(NSData*)campaignData
{
    [[self campaignFile] writeToFile:campaignData];
}

-(BOOL) canSupportDeviceFilter:(NSString*)filter {
    // Used to check all global filters this SDK supports
    return [SUPPORTED_DEVICE_FILTERS containsObject:[filter lowercaseString]];
}

-(NSString*) supportsDeviceFilters:(NSArray*)filters {
    // Update device filters to the current status
    NSArray* currentFilters = [self getCurrentlySupportedDeviceFilters];

    // Used to check the current enabled filters
    if (filters != nil) {
        for (NSString* filter in filters) {
            NSString* lowercaseFilter = [filter lowercaseString];
            if (![currentFilters containsObject:lowercaseFilter]) {
                return lowercaseFilter;
            }
        }
    }
    return nil;
}

-(NSArray*)getCurrentlySupportedDeviceFilters {
    NSMutableArray* supported = [NSMutableArray arrayWithArray:SUPPORTED_STATIC_DEVICE_FILTERS];
    NSArray* currentPermissionFilters = [SwrvePermissions currentPermissionFiltersWithSDK:analyticsSDK];
    [supported addObjectsFromArray:currentPermissionFilters];
    return supported;
}

-(void) updateCampaigns:(NSDictionary*)campaignJson
{
    if (campaignJson == nil) {
        DebugLog(@"Error parsing campaign JSON", nil);
        return;
    }

    if ([campaignJson count] == 0) {
        DebugLog(@"Campaign JSON empty, no campaigns downloaded", nil);
        self.campaigns = [[NSArray alloc] init];
        return;
    }

    NSMutableSet* assetsQueue = [[NSMutableSet alloc] init];
    NSMutableArray* result    = [[NSMutableArray alloc] init];

    // Version check
    NSNumber* version = [campaignJson objectForKey:@"version"];
    if ([version integerValue] != CAMPAIGN_RESPONSE_VERSION){
        DebugLog(@"Campaign JSON has the wrong version. No campaigns loaded.", nil);
        return;
    }

    // CDN
    self.cdnRoot = [campaignJson objectForKey:@"cdn_root"];
    DebugLog(@"CDN URL %@", self.cdnRoot);

    // Game Data
    NSDictionary* gameData = [campaignJson objectForKey:@"game_data"];
    if (gameData){
        for (NSString* game  in gameData) {
            NSString* url = [(NSDictionary*)[gameData objectForKey:game] objectForKey:@"app_store_url"];
            [self.appStoreURLs setValue:url forKey:game];
            DebugLog(@"App Store link %@: %@", game, url);
        }
    }

    NSDictionary* rules = [campaignJson objectForKey:@"rules"];
    {
        NSNumber* delay    = numberFromJsonWithDefault(rules, @"delay_first_message", DEFAULT_DELAY_FIRST_MESSAGE);
        NSNumber* maxShows = numberFromJsonWithDefault(rules, @"max_messages_per_session", DEFAULT_MAX_SHOWS);
        NSNumber* minDelay = numberFromJsonWithDefault(rules, @"min_delay_between_messages", DEFAULT_MIN_DELAY);

        self.showMessagesAfterLaunch  = [self.initialisedTime dateByAddingTimeInterval:delay.doubleValue];
        self.minDelayBetweenMessage = minDelay.doubleValue;
        self.messagesLeftToShow = maxShows.longValue;

        DebugLog(@"Game rules OK: Delay Seconds: %@ Max shows: %@ ", delay, maxShows);
        DebugLog(@"Time is %@ show messages after %@", [self.analyticsSDK getNow], [self showMessagesAfterLaunch]);
    }

    // QA
    NSMutableDictionary* campaignsDownloaded = nil;

    BOOL wasPreviouslyQAUser = (self.qaUser != nil);
    NSDictionary* jsonQa = [campaignJson objectForKey:@"qa"];
    if(jsonQa) {
        DebugLog(@"You are a QA user!", nil);
        campaignsDownloaded = [[NSMutableDictionary alloc] init];
        self.qaUser = [[SwrveTalkQA alloc] initWithJSON:jsonQa withAnalyticsSDK:self.analyticsSDK];

        NSArray* json_qa_campaigns = [jsonQa objectForKey:@"campaigns"];
        if(json_qa_campaigns) {
            for (NSDictionary* json_qa_campaign in json_qa_campaigns) {
                NSNumber* campaign_id = [json_qa_campaign objectForKey:@"id"];
                NSString* campaign_reason = [json_qa_campaign objectForKey:@"reason"];

                DebugLog(@"Campaign %@ not downloaded because: %@", campaign_id, campaign_reason);

                // Add campaign for QA purposes
                [campaignsDownloaded setValue:campaign_reason forKey:[campaign_id stringValue]];
            }
        }

        // Process any remote notifications
        for (NSDictionary* notification in self.notifications) {
            [self.qaUser pushNotification:notification];
        }
    } else {
        self.qaUser = nil;
    }

    // Empty saved push notifications
    [self.notifications removeAllObjects];

    NSArray* jsonCampaigns = [campaignJson objectForKey:@"campaigns"];
    for (NSDictionary* dict in jsonCampaigns)
    {
        BOOL conversationCampaign = ([dict objectForKey:@"conversation"] != nil);
        SwrveBaseCampaign* campaign = nil;
        if (conversationCampaign) {
            // Check device filters (permission requests, platform)
            NSArray* filters = [dict objectForKey:@"filters"];
            BOOL passesAllFilters = TRUE;
            NSString* lastCheckedFilter = nil;
            if (filters != nil) {
                for (NSString* filter in filters) {
                    lastCheckedFilter = filter;
                    if (![self canSupportDeviceFilter:filter]) {
                        passesAllFilters = NO;
                        break;
                    }
                }
            }

            if (passesAllFilters) {
                // Conversation version check
                NSNumber* conversationVersion = [dict objectForKey:@"conversation_version"];
                if (conversationVersion == nil || [conversationVersion integerValue] <= CONVERSATION_VERSION) {
                    campaign = [[SwrveConversationCampaign alloc] initAtTime:self.initialisedTime fromJSON:dict withAssetsQueue:assetsQueue forController:self];
                } else {
                    DebugLog(@"Conversation version %@ cannot be loaded with this SDK.", conversationVersion);
                }
            } else {
                DebugLog(@"Not all requirements were satisfied for this campaign: %@", lastCheckedFilter);
            }
        } else {
            campaign = [[SwrveCampaign alloc] initAtTime:self.initialisedTime fromJSON:dict withAssetsQueue:assetsQueue forController:self];
        }

        if (campaign != nil) {
            NSString* campaignIDStr = [NSString stringWithFormat:@"%lu", (unsigned long)campaign.ID];
            DebugLog(@"Got campaign with id %@", campaignIDStr);
            if(!(!wasPreviouslyQAUser && self.qaUser != nil && self.qaUser.resetDevice)) {
                SwrveCampaignState* campaignState = [self.campaignsState objectForKey:campaignIDStr];
                if(campaignState) {
                    [campaign setState:campaignState];
                }
            }
            [self.campaignsState setValue:campaign.state forKey:campaignIDStr];
            [result addObject:campaign];

            if(self.qaUser) {
                // Add campaign for QA purposes
                [campaignsDownloaded setValue:@"" forKey:[NSString stringWithFormat:@"%ld", (long)campaign.ID]];
            }
        }
    }

    // QA logging
    if (self.qaUser != nil) {
        [self.qaUser talkSession:campaignsDownloaded];
    }

    // Obtain assets we don't have yet
    NSSet* downloadQueue = [self withOutExistingFiles:assetsQueue];
    for (NSString* asset in downloadQueue) {
        [self downloadAsset:asset];
    }

    self.campaigns = [result copy];
}

-(NSSet*)withOutExistingFiles:(NSSet*)assetSet
{
    NSMutableSet* result = [[NSMutableSet alloc] initWithCapacity:[assetSet count]];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    for (NSString* file in assetSet)
    {
        NSString* target = [self.cacheFolder stringByAppendingPathComponent:file];
        if (![fileManager fileExistsAtPath:target])
        {
            [result addObject:file];
        }
        else
        {
            [self.assetsOnDisk addObject:file];
        }
    }

    return [result copy];
}

-(void)downloadAsset:(NSString*)asset
{
    BOOL mustDownload = YES;
    @synchronized([self assetsCurrentlyDownloading]) {
        mustDownload = ![assetsCurrentlyDownloading containsObject:asset];
        if (mustDownload) {
            [[self assetsCurrentlyDownloading] addObject:asset];
        }
    }

    if (mustDownload) {
        NSURL* url = [NSURL URLWithString: asset relativeToURL:[NSURL URLWithString:self.cdnRoot]];
        DebugLog(@"Downloading asset: %@", url);
        [self.analyticsSDK sendHttpGETRequest:url
                            completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
         {
    #pragma unused(response)
             if (error)
             {
                 DebugLog(@"Could not download asset: %@", error);
             }
             else
             {
                 if (![SwrveMessageController verifySHA:data against:asset]){
                     DebugLog(@"Error downloading %@ – SHA1 does not match.", asset);
                 } else {

                     NSURL* dst = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:self.cacheFolder, asset, nil]];

                     [data writeToURL:dst atomically:YES];

                     // Add the asset to the set of assets that we know are downloaded.
                     [self.assetsOnDisk addObject:asset];
                     DebugLog(@"Asset downloaded: %@", asset);
                 }
             }

             // This asset has finished downloading
             // Check if all assets are finished and if so call autoShowMessage
             @synchronized([self assetsCurrentlyDownloading]) {
                 [[self assetsCurrentlyDownloading] removeObject:asset];
                 if ([[self assetsCurrentlyDownloading] count] == 0) {
                     [self autoShowMessages];
                 }
             }
         }];
    }
}

-(void) appDidBecomeActive {
    // Obtain all assets required for the available campaigns
    NSMutableSet* assetsQueue = [[NSMutableSet alloc] init];
    for (SwrveBaseCampaign* campaign in self.campaigns) {
        [campaign addAssetsToQueue:assetsQueue];
    }

    // Obtain assets we don't have yet
    NSSet* downloadQueue = [self withOutExistingFiles:assetsQueue];
    for (NSString* asset in downloadQueue) {
        [self downloadAsset:asset];
    }
}

-(void)autoShowMessages {

    // Don't do anything if we've already shown a message or if it is too long after session start
    if (![self autoShowMessagesEnabled]) {
        return;
    }

    // Only execute if at least 1 call to the /user_resources_and_campaigns api endpoint has been completed
    if (![self.analyticsSDK campaignsAndResourcesInitialized]) {
        return;
    }

    for (SwrveBaseCampaign* campaign in self.campaigns) {
        if ([campaign isKindOfClass:[SwrveCampaign class]]) {
            SwrveCampaign* specificCampaign = (SwrveCampaign*)campaign;
            if ([specificCampaign hasMessageForEvent:AUTOSHOW_AT_SESSION_START_TRIGGER withPayload:nil]) {
                @synchronized(self) {
                    if ([self autoShowMessagesEnabled]) {
                        NSDictionary* event = @{@"type": @"event", @"name": AUTOSHOW_AT_SESSION_START_TRIGGER};
                        if ([self eventRaised:event]) {
                            // If a message was shown we want to disable autoshow
                            [self setAutoShowMessagesEnabled:NO];
                        }
                    }
                }
                break;
            }
        } else if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
            SwrveConversationCampaign* specificCampaign = (SwrveConversationCampaign*)campaign;
            if ([specificCampaign hasConversationForEvent:AUTOSHOW_AT_SESSION_START_TRIGGER withPayload:nil]) {
                @synchronized(self) {
                    if ([self autoShowMessagesEnabled]) {
                        NSDictionary* event = @{@"type": @"event", @"name": AUTOSHOW_AT_SESSION_START_TRIGGER};
                        if ([self eventRaised:event]) {
                            // If a conversation was shown we want to disable autoshow
                            [self setAutoShowMessagesEnabled:NO];
                        }
                    }
                }
                break;
            }
        }
    }
}

-(BOOL)isTooSoonToShowMessageAfterLaunch:(NSDate*)now
{
    return [now compare:[self showMessagesAfterLaunch]] == NSOrderedAscending;
}

-(BOOL)isTooSoonToShowMessageAfterDelay:(NSDate*)now
{
    return [now compare:[self showMessagesAfterDelay]] == NSOrderedAscending;
}

-(BOOL)hasShowTooManyMessagesAlready
{
    return self.messagesLeftToShow <= 0;
}

-(BOOL)checkGlobalRules:(NSString *)event {
    NSDate* now = [self.analyticsSDK getNow];
    if ([self.campaigns count] == 0)
    {
        [self noMessagesWereShown:event withReason:@"No campaigns available"];
        return FALSE;
    }

    // Ignore delay after launch throttle limit for auto show messages
    if ([event caseInsensitiveCompare:AUTOSHOW_AT_SESSION_START_TRIGGER] != NSOrderedSame && [self isTooSoonToShowMessageAfterLaunch:now])
    {
        [self noMessagesWereShown:event withReason:[NSString stringWithFormat:@"{App throttle limit} Too soon after launch. Wait until %@", [[self class] getTimeFormatted:self.showMessagesAfterLaunch]]];
        return FALSE;
    }

    if ([self isTooSoonToShowMessageAfterDelay:now])
    {
        [self noMessagesWereShown:event withReason:[NSString stringWithFormat:@"{App throttle limit} Too soon after last message. Wait until %@", [[self class] getTimeFormatted:self.showMessagesAfterDelay]]];
        return FALSE;
    }

    if ([self hasShowTooManyMessagesAlready])
    {
        [self noMessagesWereShown:event withReason:@"{App throttle limit} Too many messages shown"];
        return FALSE;
    }
    return TRUE;
}

- (SwrveMessage*)findMessageForEvent:(NSString*) eventName withPayload:(NSDictionary *)payload
{
    NSDate* now = [self.analyticsSDK getNow];
    SwrveMessage* result = nil;
    SwrveCampaign* campaign = nil;

    if (self.campaigns != nil) {
        if (![self checkGlobalRules:eventName]) {
            return nil;
        }

        NSMutableDictionary* campaignReasons = nil;
        NSMutableDictionary* campaignMessages = nil;
        if (self.qaUser != nil) {
            campaignReasons = [[NSMutableDictionary alloc] init];
            campaignMessages = [[NSMutableDictionary alloc] init];
        }

        NSMutableArray* availableMessages = [[NSMutableArray alloc] init];
        // Select messages with higher priority that have the current orientation
        NSNumber* minPriority = [NSNumber numberWithInteger:INT_MAX];
        NSMutableArray* candidateMessages = [[NSMutableArray alloc] init];
        // Get current orientation
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        for (SwrveBaseCampaign* baseCampaignIt in self.campaigns)
        {
            if ([baseCampaignIt isKindOfClass:[SwrveCampaign class]]) {
                SwrveCampaign* campaignIt = (SwrveCampaign*)baseCampaignIt;
                SwrveMessage* nextMessage = [campaignIt getMessageForEvent:eventName withPayload:payload withAssets:self.assetsOnDisk atTime:now withReasons:campaignReasons];
                if (nextMessage != nil) {
                    BOOL canBeChosen = YES;
                    // iOS9+ will display with local scale
                    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
                        canBeChosen = [nextMessage supportsOrientation:currentOrientation];
                    }
                    if (canBeChosen) {
                        // Add to list of returned messages
                        [availableMessages addObject:nextMessage];
                        // Check if it is a candidate to be shown
                        long nextMessagePriorityLong = [nextMessage.priority longValue];
                        long minPriorityLong = [minPriority longValue];
                        if (nextMessagePriorityLong <= minPriorityLong) {
                            if (nextMessagePriorityLong < minPriorityLong) {
                                // If it is lower than any of the previous ones
                                // remove those from being candidates
                                [candidateMessages removeAllObjects];
                            }
                            minPriority = nextMessage.priority;
                            [candidateMessages addObject:nextMessage];
                        }
                    } else {
                        if (self.qaUser != nil) {
                            NSString* campaignIdString = [[NSNumber numberWithUnsignedInteger:campaignIt.ID] stringValue];
                            [campaignMessages setValue:nextMessage.messageID forKey:campaignIdString];
                            [campaignReasons setValue:@"Message didn't support the given orientation" forKey:campaignIdString];
                        }
                    }
                }
            }
        }

        NSArray* shuffledCandidates = [SwrveMessageController shuffled:candidateMessages];
        if ([shuffledCandidates count] > 0) {
            result = [shuffledCandidates objectAtIndex:0];
            campaign = result.campaign;
        }

        if (self.qaUser != nil && campaign != nil && result != nil) {
            // A message was chosen, set the reason for the others
            for (SwrveMessage* otherMessage in availableMessages)
            {
                if (result != otherMessage)
                {
                    SwrveCampaign* c = otherMessage.campaign;
                    if (c != nil)
                    {
                        NSString* campaignIdString = [[NSNumber numberWithUnsignedInteger:c.ID] stringValue];
                        [campaignMessages setValue:otherMessage.messageID forKey:campaignIdString];
                        [campaignReasons setValue:[NSString stringWithFormat:@"Campaign %ld was selected for display ahead of this campaign", (long)campaign.ID] forKey:campaignIdString];
                    }
                }
            }
        }

        // If QA enabled, send message selection information
        if(self.qaUser != nil) {
            [self.qaUser trigger:eventName withMessage:result withReason:campaignReasons withMessages:campaignMessages];
        }
    }

    if (result == nil) {
        DebugLog(@"Not showing message: no candidate messages for %@", eventName);
    } else {
        // Notify message has been returned
        NSDictionary *returningPayload = [NSDictionary dictionaryWithObjectsAndKeys:[result.messageID stringValue], @"id", nil];
        NSString *returningEventName = @"Swrve.Messages.message_returned";
        [self.analyticsSDK eventInternal:returningEventName payload:returningPayload triggerCallback:true];
    }
    return result;


}

-(SwrveMessage*)getMessageForEvent:(NSString *)event
{
    // By default does a simple by name look up.
    return [self findMessageForEvent:event withPayload:nil];
}

- (SwrveConversation*)getConversationForEvent:(NSString*) eventName withPayload:(NSDictionary *)payload {

    NSDate* now = [self.analyticsSDK getNow];
    SwrveConversation* result = nil;
    SwrveConversationCampaign* campaign = nil;

    if (self.campaigns != nil) {
        if (![self checkGlobalRules:eventName])
        {
            return nil;
        }

        NSMutableDictionary* campaignReasons = nil;
        NSMutableDictionary* campaignMessages = nil;
        if (self.qaUser != nil) {
            campaignReasons = [[NSMutableDictionary alloc] init];
            campaignMessages = [[NSMutableDictionary alloc] init];
        }

        NSMutableArray* availableConversations = [[NSMutableArray alloc] init];
        // Select conversations with higher priority
        NSNumber* minPriority = [NSNumber numberWithInteger:INT_MAX];
        NSMutableArray* candidateConversations = [[NSMutableArray alloc] init];
        for (SwrveBaseCampaign* baseCampaignIt in self.campaigns)
        {
            if ([baseCampaignIt isKindOfClass:[SwrveConversationCampaign class]]) {
                SwrveConversationCampaign* campaignIt = (SwrveConversationCampaign*)baseCampaignIt;
                SwrveConversation* nextConversation = [campaignIt getConversationForEvent:eventName withPayload:payload withAssets:self.assetsOnDisk atTime:now withReasons:campaignReasons];
                if (nextConversation != nil) {
                    [availableConversations addObject:nextConversation];
                    // Check if it is a candidate to be shown
                    long nextMessagePriorityLong = [nextConversation.priority longValue];
                    long minPriorityLong = [minPriority longValue];
                    if (nextMessagePriorityLong <= minPriorityLong) {
                        if (nextMessagePriorityLong < minPriorityLong) {
                            // If it is lower than any of the previous ones
                            // remove those from being candidates
                            [candidateConversations removeAllObjects];
                        }
                        minPriority = nextConversation.priority;
                        [candidateConversations addObject:nextConversation];
                    }
                }
            }
        }

        NSArray* shuffledCandidates = [SwrveMessageController shuffled:candidateConversations];
        if ([shuffledCandidates count] > 0) {
            result = [shuffledCandidates objectAtIndex:0];
            campaign = result.campaign;
        }

        if (self.qaUser != nil && campaign != nil && result != nil) {
            // A message was chosen, set the reason for the others
            for (SwrveConversation* otherConversation in availableConversations)
            {
                if (result != otherConversation)
                {
                    SwrveConversationCampaign* c = otherConversation.campaign;
                    if (c != nil)
                    {
                        NSString* campaignIdString = [[NSNumber numberWithUnsignedInteger:c.ID] stringValue];
                        [campaignMessages setValue:otherConversation.conversationID forKey:campaignIdString];
                        [campaignReasons setValue:[NSString stringWithFormat:@"Campaign %ld was selected for display ahead of this campaign", (long)campaign.ID] forKey:campaignIdString];
                    }
                }
            }
        }

        // If QA enabled, send message selection information
        if(self.qaUser != nil) {
            [self.qaUser trigger:eventName withConversation:result withReason:campaignReasons];
        }
    }

    if (result == nil) {
        DebugLog(@"Not showing message: no candidate messages for %@", eventName);
    }
    return result;
}

-(SwrveConversation*)getConversationForEvent:(NSString *)event {

    return [self getConversationForEvent:event withPayload:nil];
}

-(void)noMessagesWereShown:(NSString*)event withReason:(NSString*)reason
{
    DebugLog(@"Not showing message for %@: %@", event, reason);
    if (self.qaUser != nil) {
        [self.qaUser triggerFailure:event withReason:reason];
    }
}

+(NSString*)getTimeFormatted:(NSDate*)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"HH:mm:ss Z"];

    return [dateFormatter stringFromDate:date];
}

+(NSArray*)shuffled:(NSArray*)source;
{
    unsigned long count = [source count];

    // Early out if there is 0 or 1 elements.
    if (count < 2)
    {
        return source;
    }

    // Copy
    NSMutableArray* result = [NSMutableArray arrayWithArray:source];

    for (unsigned long i = 0; i < count; i++)
    {
        unsigned long remain = count - i;
        unsigned long n = (arc4random() % remain) + i;
        [result exchangeObjectAtIndex:i withObjectAtIndex:n];
    }

    return result;
}

+(bool)verifySHA:(NSData*)data against:(NSString*)expectedDigest
{
    const static char hex[] = {'0', '1', '2', '3',
        '4', '5', '6', '7',
        '8', '9', 'a', 'b',
        'c', 'd', 'e', 'f'};

    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    // SHA-1 hash has been calculated and stored in 'digest'
    unsigned int length = (unsigned int)[data length];
    if (CC_SHA1([data bytes], length, digest)) {
        for (unsigned int i = 0; i < [expectedDigest length]; i++) {
            unichar c = [expectedDigest characterAtIndex:i];
            unsigned char e = digest[i>>1];

            if (i&1) {
                e = e & 0xF;
            } else {
                e = e >> 4;
            }

            e = (unsigned char)hex[e];

            if (c != e) {
                DebugLog(@"Wrong asset SHA[%d]. Expected: %d Computed %d", i, e, c);
                return false;
            }
        }
    }

    return true;
}

-(void)setMessageMinDelayThrottle
{
    NSDate* now = [self.analyticsSDK getNow];
    [self setShowMessagesAfterDelay:[now dateByAddingTimeInterval:[self minDelayBetweenMessage]]];
}

-(void)messageWasShownToUser:(SwrveMessage*)message
{
    NSDate* now = [self.analyticsSDK getNow];
    // The message was shown. Take the current time so that we can throttle messages
    // from being shown too quickly.
    [self setMessageMinDelayThrottle];
    [self setMessagesLeftToShow:self.messagesLeftToShow - 1];

    SwrveCampaign* c = message.campaign;
    if (c != nil) {
        [c messageWasShownToUser:message at:now];
    }
    [self saveCampaignsState];

    NSString* viewEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%d.impression", [message.messageID intValue]];
    DebugLog(@"Sending view event: %@", viewEvent);

    [self.analyticsSDK eventInternal:viewEvent payload:nil triggerCallback:false];
}

-(void)conversationWasShownToUser:(SwrveConversation*)conversation
{
    NSDate* now = [self.analyticsSDK getNow];
    // The message was shown. Take the current time so that we can throttle messages
    // from being shown too quickly.
    [self setMessageMinDelayThrottle];
    [self setMessagesLeftToShow:self.messagesLeftToShow - 1];

    SwrveConversationCampaign* c = conversation.campaign;
    if (c != nil) {
        [c conversationWasShownToUser:conversation at:now];
    }
    [self saveCampaignsState];
}

-(void)buttonWasPressedByUser:(SwrveButton*)button
{
    if (button.actionType != kSwrveActionDismiss) {
        NSString* clickEvent = [NSString stringWithFormat:@"Swrve.Messages.Message-%ld.click", button.messageID];
        DebugLog(@"Sending click event: %@", clickEvent);
        [self.analyticsSDK eventInternal:clickEvent payload:@{@"name" : button.name} triggerCallback:false];
    }
}

-(NSString*)getAppStoreURLForGame:(long)game
{
    return [self.appStoreURLs objectForKey:[NSString stringWithFormat:@"%ld", game]];
}

-(NSString*) getEventName:(NSDictionary*)eventParameters
{
    NSString* eventName = @"";

    NSString* eventType = [eventParameters objectForKey:@"type"];
    if( [eventType isEqualToString:@"session_start"])
    {
        eventName = @"Swrve.session.start";
    }
    else if( [eventType isEqualToString:@"session_end"])
    {
        eventName = @"Swrve.session.end";
    }
    else if( [eventType isEqualToString:@"buy_in"])
    {
        eventName = @"Swrve.buy_in";
    }
    else if( [eventType isEqualToString:@"iap"])
    {
        eventName = @"Swrve.iap";
    }
    else if( [eventType isEqualToString:@"event"])
    {
        eventName = [eventParameters objectForKey:@"name"];
    }
    else if( [eventType isEqualToString:@"purchase"])
    {
        eventName = @"Swrve.user_purchase";
    }
    else if( [eventType isEqualToString:@"currency_given"])
    {
        eventName = @"Swrve.currency_given";
    }
    else if( [eventType isEqualToString:@"user"])
    {
        eventName = @"Swrve.user_properties_changed";
    }

    return eventName;
}

-(void) showMessage:(SwrveMessage *)message
{
    @synchronized(self) {
        if ( message && self.inAppMessageWindow == nil && self.conversationWindow == nil ) {
            SwrveMessageViewController* messageViewController = [[SwrveMessageViewController alloc] init];
            messageViewController.view.backgroundColor = self.inAppMessageBackgroundColor;
            messageViewController.message = message;
            messageViewController.prefersIAMStatusBarHidden = self.prefersIAMStatusBarHidden;
            messageViewController.block = ^(SwrveActionType type, NSString* action, NSInteger appId) {
    #pragma unused(appId)
                // Save button type and action for processing later
                self.inAppMessageActionType = type;
                self.inAppMessageAction = action;

                if( [self.showMessageDelegate respondsToSelector:@selector(beginHideMessageAnimation:)]) {
                    [self.showMessageDelegate beginHideMessageAnimation:(SwrveMessageViewController*)self.inAppMessageWindow.rootViewController];
                }
                else {
                    [self beginHideMessageAnimation:(SwrveMessageViewController*)self.inAppMessageWindow.rootViewController];
                }
            };

            [self showMessageWindow:messageViewController];
        }
    }
}

-(void) showConversation:(SwrveConversation*)conversation
{
    @synchronized(self) {
        if ( conversation && self.inAppMessageWindow == nil && self.conversationWindow == nil ) {
            // Create a view to show the conversation

            @try {
                UIStoryboard* storyBoard = [SwrveBaseConversation loadStoryboard];
                SwrveConversationItemViewController* scivc = [storyBoard instantiateViewControllerWithIdentifier:@"SwrveConversationItemViewController"];
                self.swrveConversationItemViewController = scivc;
            }
            @catch (NSException *exception) {
                DebugLog(@"Unable to load Conversation Item View Controller. %@", exception);
                return;
            }

            self.conversationWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            [self.swrveConversationItemViewController setConversation:conversation andMessageController:self];

            // Create a navigation controller in which to push the conversation, and choose iPad presentation style
            SwrveConversationsNavigationController *svnc = [[SwrveConversationsNavigationController alloc] initWithRootViewController:self.swrveConversationItemViewController];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
            // Attach cancel button to the conversation navigation options
            UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.swrveConversationItemViewController action:@selector(cancelButtonTapped:)];
#pragma clang diagnostic pop
            self.swrveConversationItemViewController.navigationItem.leftBarButtonItem = cancelButton;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                SwrveConversationContainerViewController* rootController = [[SwrveConversationContainerViewController alloc] initWithChildViewController:svnc];
                self.conversationWindow.rootViewController = rootController;
                [self.conversationWindow makeKeyAndVisible];
                [self.conversationWindow.rootViewController.view endEditing:YES];
            });
        }
    }
}


- (void) cleanupConversationUI {
    if(self.swrveConversationItemViewController != nil){
        [self.swrveConversationItemViewController dismiss];
    }
}


- (void) conversationClosed {
    self.conversationWindow.hidden = YES;
    self.conversationWindow = nil;
    self.swrveConversationItemViewController = nil;
}

- (void) showMessageWindow:(SwrveMessageViewController*) messageViewController {
    if( messageViewController == nil ) {
        DebugLog(@"Cannot show a nil view.", nil);
        return;
    }

    if( self.inAppMessageWindow != nil ) {
        DebugLog(@"A message is already displayed, ignoring second message.", nil);
        return;
    }

    if( [self.showMessageDelegate respondsToSelector:@selector(messageWillBeShown:)]) {
        [self.showMessageDelegate messageWillBeShown:messageViewController];
    }

    self.inAppMessageWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.inAppMessageWindow.rootViewController.view.alpha = 0.0f;
    self.inAppMessageWindow.rootViewController = messageViewController;
    self.inAppMessageWindow.windowLevel = UIWindowLevelAlert + 1;
    [self.inAppMessageWindow makeKeyAndVisible];

    if( [self.showMessageDelegate respondsToSelector:@selector(beginShowMessageAnimation:)]) {
        [self.showMessageDelegate beginShowMessageAnimation:messageViewController];
    }
    else {
        [self beginShowMessageAnimation:messageViewController];
    }
}

- (void) dismissMessageWindow {
    if( self.inAppMessageWindow == nil ) {
        DebugLog(@"No message to dismiss.", nil);
        return;
    }
    [self setMessageMinDelayThrottle];
    NSDate* now = [self.analyticsSDK getNow];
    SwrveCampaign* dismissedCampaign = ((SwrveMessageViewController*)self.inAppMessageWindow.rootViewController).message.campaign;
    [dismissedCampaign messageDismissed:now];

    if( [self.showMessageDelegate respondsToSelector:@selector(messageWillBeHidden:)]) {
        [self.showMessageDelegate messageWillBeHidden:(SwrveMessageViewController*)self.inAppMessageWindow.rootViewController];
    }

    NSString* action = self.inAppMessageAction;
    NSString* nonProcessedAction = nil;
    switch(self.inAppMessageActionType)
    {
        case kSwrveActionDismiss: break;
        case kSwrveActionInstall:
        {
            BOOL standardEvent = true;
            if (self.installButtonCallback != nil) {
                standardEvent = self.installButtonCallback(action);
            }

            if (standardEvent) {
                nonProcessedAction = action;
            }
        }
            break;
        case kSwrveActionCustom:
        {
            if (self.customButtonCallback != nil) {
                self.customButtonCallback(action);
            } else {
                nonProcessedAction = action;
            }
        }
            break;
    }

    if(nonProcessedAction != nil) {
        NSURL* url = [NSURL URLWithString:nonProcessedAction];
        if( url != nil ) {
            DebugLog(@"Action - %@ - handled.  Sending to application as URL", nonProcessedAction);
            [[UIApplication sharedApplication] openURL:url];
        } else {
            DebugLog(@"Action - %@ -  not handled. Override the customButtonCallback to customize message actions", nonProcessedAction);
        }
    }

    self.inAppMessageWindow.hidden = YES;
    self.inAppMessageWindow = nil;
    self.inAppMessageAction = nil;
}

- (void) beginShowMessageAnimation:(SwrveMessageViewController*) viewController {
    viewController.view.alpha = 0.0f;
    [UIView animateWithDuration:0.25
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.inAppMessageWindow.rootViewController.view.alpha = 1.0f;
                     }
                     completion:nil];
}

- (void) beginHideMessageAnimation:(SwrveMessageViewController*) viewController {
#pragma unused(viewController)
    [UIView animateWithDuration:0.25
                          delay:0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.inAppMessageWindow.rootViewController.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
#pragma unused(finished)
                         [self dismissMessageWindow];
                     }];
}

-(void) userPressedButton:(SwrveActionType) actionType action:(NSString*) action {
#pragma unused(actionType, action)
    if( self.inAppMessageWindow != nil && self.inAppMessageWindow.hidden == YES ) {
        self.inAppMessageWindow.hidden = YES;
        self.inAppMessageWindow = nil;
    }
}

-(BOOL) eventRaised:(NSDictionary*)event;
{
    // Get event name
    NSString* eventName = [self getEventName:event];
    NSDictionary *payload = [event objectForKey:@"payload"];

#if !defined(SWRVE_NO_PUSH)
    if (self.pushEnabled) {
        if (self.pushNotificationEvents != nil && [self.pushNotificationEvents containsObject:eventName]) {
            // Ask for push notification permission
            [self registerForPushNotifications];
        }
    }
#endif //!defined(SWRVE_NO_PUSH)

    // Find a conversation that should be displayed
    SwrveConversation* conversation = nil;

    if( [self.showMessageDelegate respondsToSelector:@selector(getConversationForEvent: withPayload:)]) {
        conversation = [self.showMessageDelegate getConversationForEvent:eventName withPayload:payload];
    }
    else {
        conversation = [self getConversationForEvent:eventName withPayload:payload];
    }

    if (conversation != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if( [self.showMessageDelegate respondsToSelector:@selector(showConversation:)]) {
                [self.showMessageDelegate showConversation:conversation];
            } else {
                [self showConversation:conversation];
            }
        });
        return YES;
    } else {
        // Find a message that should be displayed
        SwrveMessage* message = nil;
        if( [self.showMessageDelegate respondsToSelector:@selector(findMessageForEvent: withPayload:)]) {
            message = [self.showMessageDelegate findMessageForEvent:eventName withPayload:payload];
        }
        else {
            message = [self findMessageForEvent:eventName withPayload:payload];
        }

        // iOS9+ will display with local scale
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            // Only show the message if it supports the given orientation
            if ( message != nil && ![message supportsOrientation:[[UIApplication sharedApplication] statusBarOrientation]] ) {
                DebugLog(@"The message doesn't support the current orientation", nil);
                return NO;
            }
        }

        // Show the message if it exists
        if( message != nil ) {
            dispatch_block_t showMessageBlock = ^{
                if( [self.showMessageDelegate respondsToSelector:@selector(showMessage:)]) {
                    [self.showMessageDelegate showMessage:message];
                }
                else {
                    [self showMessage:message];
                }
            };


            if ([NSThread isMainThread]) {
                showMessageBlock();
            } else {
                // Run in the main thread as we have been called from other thread
                dispatch_async(dispatch_get_main_queue(), showMessageBlock);
            }
        }

        return ( message != nil );
    }
}

#if !defined(SWRVE_NO_PUSH)
- (void) setDeviceToken:(NSData*)deviceToken
{
    if (self.pushEnabled && deviceToken) {
        [self.analyticsSDK setPushNotificationsDeviceToken:deviceToken];

        if (self.qaUser) {
            // If we are a QA user then send a device info update
            [self.qaUser updateDeviceInfo];
        }
    }
}

- (void) pushNotificationReceived:(NSDictionary*)userInfo
{
    [self pushNotificationReceived:userInfo atApplicationState:[UIApplication sharedApplication].applicationState];
}

- (void) pushNotificationReceived:(NSDictionary*)userInfo atApplicationState:(UIApplicationState)applicationState
{
    if (self.pushEnabled) {
        // Do not process the push notification if the app was on the foreground
        BOOL appInBackground = applicationState != UIApplicationStateActive;
        if (appInBackground) {
            [self.analyticsSDK pushNotificationReceived:userInfo];
            if (self.qaUser) {
                [self.qaUser pushNotification:userInfo];
            } else {
                DebugLog(@"Queuing push notification for later", nil);
                [self.notifications addObject:userInfo];
            }
        }
    }
}
#endif //!defined(SWRVE_NO_PUSH)

- (BOOL) isQaUser
{
    return self.qaUser != nil;
}

- (NSString*) orientationName
{
    switch (orientation) {
        case SWRVE_ORIENTATION_LANDSCAPE:
            return @"landscape";
        case SWRVE_ORIENTATION_PORTRAIT:
            return @"portrait";
        default:
            return @"both";
    }
}

- (NSString*) getCampaignQueryString
{
    const NSString* orientationName = [self orientationName];
    UIDevice* device = [UIDevice currentDevice];
    NSString* encodedDeviceName;
    NSString* encodedSystemName;
#if defined(__IPHONE_9_0)
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        encodedDeviceName = [[device model] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        encodedSystemName = [[device systemName] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    } else
#endif //defined(__IPHONE_9_0)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        encodedDeviceName = [[device model] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        encodedSystemName = [[device systemName] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
#pragma clang diagnostic pop
    }
    return [NSString stringWithFormat:@"version=%d&orientation=%@&language=%@&app_store=%@&device_width=%d&device_height=%d&os_version=%@&device_name=%@&conversation_version=%d&location_version=%d",
            CAMPAIGN_VERSION, orientationName, self.language, @"apple", self.device_width, self.device_height, encodedSystemName, encodedDeviceName, CONVERSATION_VERSION, self.analyticsSDK.locationSegmentVersion];
}

-(NSArray*) messageCenterCampaigns
{
    // iOS9+ will display with local scale
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        return [self messageCenterCampaignsThatSupportOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    }
    return [self messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationUnknown];
}

-(NSArray*) messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)messageOrientation
{
    NSDate* now = [self.analyticsSDK getNow];
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for(SwrveBaseCampaign* campaign in self.campaigns) {
        if (campaign.messageCenter && campaign.state.status != SWRVE_CAMPAIGN_STATUS_DELETED && [campaign isActive:now withReasons:nil] && [campaign supportsOrientation:messageOrientation] && [campaign assetsReady:self.assetsOnDisk]) {
            [result addObject:campaign];
        }
    }
    return result;
}

-(BOOL)showMessageCenterCampaign:(SwrveBaseCampaign *)campaign
{
    if (!campaign.messageCenter || ![campaign assetsReady:self.assetsOnDisk]) {
        return NO;
    }
    if ([campaign isKindOfClass:[SwrveConversationCampaign class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SwrveConversation* conversation = ((SwrveConversationCampaign*)campaign).conversation;
            if( [self.showMessageDelegate respondsToSelector:@selector(showConversation:)]) {
                [self.showMessageDelegate showConversation:conversation];
            } else {
                [self showConversation:conversation];
            }
        });
        return YES;
    } else if ([campaign isKindOfClass:[SwrveCampaign class]]) {
        SwrveMessage* message = [((SwrveCampaign*)campaign).messages objectAtIndex:0];

        // iOS9+ will display with local scale
        if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
            // Only show the message if it supports the given orientation
            if ( message != nil && ![message supportsOrientation:[[UIApplication sharedApplication] statusBarOrientation]] ) {
                DebugLog(@"The message doesn't support the current orientation", nil);
                return NO;
            }
        }

        // Show the message if it exists
        if( message != nil ) {
            dispatch_block_t showMessageBlock = ^{
                if( [self.showMessageDelegate respondsToSelector:@selector(showMessage:)]) {
                    [self.showMessageDelegate showMessage:message];
                }
                else {
                    [self showMessage:message];
                }
            };


            if ([NSThread isMainThread]) {
                showMessageBlock();
            } else {
                // Run in the main thread as we have been called from other thread
                dispatch_async(dispatch_get_main_queue(), showMessageBlock);
            }
        }

        return YES;
    }

    return NO;
}

-(void)removeMessageCenterCampaign:(SwrveBaseCampaign*)campaign
{
    if (campaign.messageCenter) {
        [campaign.state setStatus:SWRVE_CAMPAIGN_STATUS_DELETED];
        [self saveCampaignsState];
    }
}

@end
