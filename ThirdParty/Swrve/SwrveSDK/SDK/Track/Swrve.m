#if !__has_feature(objc_arc)
    #error Please enable ARC for this project (Project Settings > Build Settings), or add the -fobjc-arc compiler flag to each of the files in the Swrve SDK (Project Settings > Build Phases > Compile Sources)
#endif

#include <sys/time.h>
#import "Swrve.h"
#include <sys/sysctl.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CommonCrypto/CommonHMAC.h>
#import <AdSupport/ASIdentifierManager.h>
#import "SwrveCampaign.h"
#import "SwrvePermissions.h"
#import "SwrveSwizzleHelper.h"
#import "SwrveCommonConnectionDelegate.h"
#import "SwrveFileManagement.h"

#if SWRVE_TEST_BUILD
#define SWRVE_STATIC_UNLESS_TEST_BUILD
#else
#define SWRVE_STATIC_UNLESS_TEST_BUILD static
#endif

#define NullableNSString(x) ((x == nil)? [NSNull null] : x)
#define KB(x) (1024*(x))
#define MB(x) (1024*KB((x)))

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

const static char* swrve_trailing_comma = ",\n";
static NSString* swrve_user_id_key = @"swrve_user_id";
static NSString* swrve_device_token_key = @"swrve_device_token";
static BOOL ignoreFirstDidBecomeActive = YES;

typedef void (*didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)(__strong id,SEL,UIApplication *, NSData*);
typedef void (*didFailToRegisterForRemoteNotificationsWithErrorImplSignature)(__strong id,SEL,UIApplication *, NSError*);
typedef void (*didReceiveRemoteNotificationImplSignature)(__strong id,SEL,UIApplication *, NSDictionary*);

@interface SwrveSendContext : NSObject
@property (atomic, weak)   Swrve* swrveReference;
@property (atomic) long    swrveInstanceID;
@property (atomic, retain) NSArray* buffer;
@property (atomic)         int bufferLength;
@end

@implementation SwrveSendContext
@synthesize swrveReference;
@synthesize swrveInstanceID;
@synthesize buffer;
@synthesize bufferLength;
@end

@interface SwrveSendLogfileContext : NSObject
@property (atomic, weak) Swrve* swrveReference;
@property (atomic) long swrveInstanceID;
@end

@implementation SwrveSendLogfileContext
@synthesize swrveReference;
@synthesize swrveInstanceID;
@end

enum
{
    SWRVE_TRUNCATE_FILE,
    SWRVE_APPEND_TO_FILE,
    SWRVE_TRUNCATE_IF_TOO_LARGE,
};

@interface SwrveConnectionDelegate : SwrveCommonConnectionDelegate

@property (atomic, weak) Swrve* swrve;

- (id)init:(Swrve*)swrve completionHandler:(ConnectionCompletionHandler)handler;

@end

@interface SwrveInstanceIDRecorder : NSObject
{
    NSMutableSet * swrveInstanceIDs;
    long nextInstanceID;
}

+(SwrveInstanceIDRecorder*) sharedInstance;

-(BOOL)hasSwrveInstanceID:(long)instanceID;
-(long)addSwrveInstanceID;
-(void)removeSwrveInstanceID:(long)instanceID;

@end

@interface SwrveResourceManager()

- (void)setResourcesFromArray:(NSArray*)json;

@end

@interface SwrveMessageController()

@property (nonatomic, retain) NSArray* campaigns;
@property (nonatomic) bool autoShowMessagesEnabled;

-(void) updateCampaigns:(NSDictionary*)campaignJson;
-(NSString*) getCampaignQueryString;
-(void) writeToCampaignCache:(NSData*)campaignData;
-(void) autoShowMessages;

@end

@interface Swrve()
{
    UInt64 install_time;
    NSDate *lastSessionDate;
    NSString* lastProcessedPushId;


    SwrveEventQueuedCallback event_queued_callback;

    // Used to retain user-blocks that are passed to C functions
    NSMutableDictionary *   blockStore;
    int                     blockStoreId;

    // The unique id associated with this instance of Swrve
    long    instanceID;

    didRegisterForRemoteNotificationsWithDeviceTokenImplSignature didRegisterForRemoteNotificationsWithDeviceTokenImpl;
    didFailToRegisterForRemoteNotificationsWithErrorImplSignature didFailToRegisterForRemoteNotificationsWithErrorImpl;
    didReceiveRemoteNotificationImplSignature didReceiveRemoteNotificationImpl;
}

-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback;
-(void) setupConfig:(SwrveConfig*)config;
+(NSString*) getAppVersion;
-(void) maybeFlushToDisk;
-(void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback;
-(void) removeBlockStoreItem:(int)blockId;
-(void) updateDeviceInfo;
-(void) registerForNotifications;
-(void) appDidBecomeActive:(NSNotification*)notification;
-(void) pushNotificationReceived:(NSDictionary*)userInfo;
-(void) appWillResignActive:(NSNotification*)notification;
-(void) appWillTerminate:(NSNotification*)notification;
-(void) queueUserUpdates;
- (NSString*) createSessionToken;
- (NSString*) createJSON:(NSString*)sessionToken events:(NSString*)rawEvents;
- (NSString*) copyBufferToJson:(NSArray*)buffer;
- (void) sendCrashlyticsMetadata;
- (BOOL) isValidJson:(NSData*) json;
- (void) initResources;
- (UInt64) getInstallTime:(NSString*)fileName withSecondaryFile:(NSString*)secondaryFileName;
- (void) sendLogfile;
- (NSOutputStream*) createLogfile:(int)mode;
- (UInt64) getTime;
- (NSString*) createStringWithMD5:(NSString*)source;
- (void) initBuffer;
- (void) addHttpPerformanceMetrics:(NSString*) metrics;
- (void) checkForCampaignAndResourcesUpdates:(NSTimer*)timer;

// Used to store the merged user updates
@property (atomic, strong) NSMutableDictionary * userUpdates;

// Device id, used for tracking event streams from different devices
@property (atomic) NSNumber* shortDeviceID;

// HTTP Request metrics that haven't been sent yet
@property (atomic) NSMutableArray* httpPerformanceMetrics;

// Flush values, ETag and timer for campaigns and resources update request
@property (atomic) NSString* campaignsAndResourcesETAG;
@property (atomic) double campaignsAndResourcesFlushFrequency;
@property (atomic) double campaignsAndResourcesFlushRefreshDelay;
@property (atomic) NSTimer* campaignsAndResourcesTimer;
@property (atomic) int campaignsAndResourcesTimerSeconds;
@property (atomic) NSDate* campaignsAndResourcesLastRefreshed;
@property (atomic) BOOL campaignsAndResourcesInitialized; // Set to true after first call to API returns

// Resource cache files
@property (atomic) SwrveSignatureProtectedFile* resourcesFile;
@property (atomic) SwrveSignatureProtectedFile* resourcesDiffFile;

// An in-memory buffer of messages that are ready to be sent to the Swrve
// server the next time sendQueuedEvents is called.
@property (atomic) NSMutableArray* eventBuffer;

@property (atomic) bool eventFileHasData;
@property (atomic) NSOutputStream* eventStream;
@property (atomic) NSURL* eventFilename;
@property (atomic) NSURL* eventSecondaryFilename;

// Count the number of UTF-16 code points stored in buffer
@property (atomic) int eventBufferBytes;

// keep track of whether any events were sent so we know whether to check for resources / campaign updates
@property (atomic) bool eventsWereSent;

// URLs
@property (atomic) NSURL* batchURL;
@property (atomic) NSURL* campaignsAndResourcesURL;

@property (atomic) int locationSegmentVersion;

@end

// Manages unique ids for each instance of Swrve
// This allows low-level c callbacks to know if it is safe to execute their callback functions.
// It is not safe to execute a callback function after a Swrve instance has been deallocated or shutdown.
@implementation SwrveInstanceIDRecorder

+(SwrveInstanceIDRecorder*) sharedInstance
{
    static dispatch_once_t pred;
    static SwrveInstanceIDRecorder *shared = nil;
    dispatch_once(&pred, ^{
        shared = [SwrveInstanceIDRecorder alloc];
    });
    return shared;
}

-(id)init
{
    if (self = [super init]) {
        nextInstanceID = 1;
    }
    return self;
}

-(BOOL)hasSwrveInstanceID:(long)instanceID
{
    @synchronized(self) {
        if (!swrveInstanceIDs) {
            return NO;
        }
        return [swrveInstanceIDs containsObject:[NSNumber numberWithLong:instanceID]];
    }
}

-(long)addSwrveInstanceID
{
    @synchronized(self) {
        if (!swrveInstanceIDs) {
            swrveInstanceIDs = [[NSMutableSet alloc]init];
        }
        long result = nextInstanceID++;
        [swrveInstanceIDs addObject:[NSNumber numberWithLong:result]];
        return result;
    }
}

-(void)removeSwrveInstanceID:(long)instanceID
{
    @synchronized(self) {
        if (swrveInstanceIDs) {
            [swrveInstanceIDs removeObject:[NSNumber numberWithLong:instanceID]];
        }
    }
}

@end


@implementation SwrveConfig

@synthesize userId;
@synthesize orientation;
@synthesize prefersIAMStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize useHttpsForEventServer;
@synthesize contentServer;
@synthesize useHttpsForContentServer;
@synthesize language;
@synthesize eventCacheFile;
@synthesize eventCacheSecondaryFile;
@synthesize eventCacheSignatureFile;
@synthesize locationCampaignCacheFile;
@synthesize locationCampaignCacheSecondaryFile;
@synthesize locationCampaignCacheSignatureFile;
@synthesize locationCampaignCacheSignatureSecondaryFile;
@synthesize userResourcesCacheFile;
@synthesize userResourcesCacheSecondaryFile;
@synthesize userResourcesCacheSignatureFile;
@synthesize userResourcesCacheSignatureSecondaryFile;
@synthesize userResourcesDiffCacheFile;
@synthesize userResourcesDiffCacheSignatureFile;
@synthesize installTimeCacheFile;
@synthesize installTimeCacheSecondaryFile;
@synthesize appVersion;
@synthesize receiptProvider;
@synthesize maxConcurrentDownloads;
@synthesize autoDownloadCampaignsAndResources;
@synthesize talkEnabled;
@synthesize defaultBackgroundColor;
@synthesize conversationLightBoxColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize autoShowMessagesMaxDelay;
@synthesize selectedStack;

-(id) init
{
    if ( self = [super init] ) {
        httpTimeoutSeconds = 60;
        autoDownloadCampaignsAndResources = YES;
        maxConcurrentDownloads = 2;
        orientation = SWRVE_ORIENTATION_BOTH;
        prefersIAMStatusBarHidden = YES;
        appVersion = [Swrve getAppVersion];
        language = [[NSLocale preferredLanguages] objectAtIndex:0];
        newSessionInterval = 30;

        NSString* caches = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* applicationSupport = [SwrveFileManagement applicationSupportPath];
        eventCacheFile = [applicationSupport stringByAppendingPathComponent: @"swrve_events.txt"];
        eventCacheSecondaryFile = [caches stringByAppendingPathComponent: @"swrve_events.txt"];

        locationCampaignCacheFile = [applicationSupport stringByAppendingPathComponent: @"lc.txt"];
        locationCampaignCacheSecondaryFile = [caches stringByAppendingPathComponent: @"lc.txt"];
        locationCampaignCacheSignatureFile = [applicationSupport stringByAppendingPathComponent: @"lcsgt.txt"];
        locationCampaignCacheSignatureSecondaryFile = [caches stringByAppendingPathComponent: @"lcsgt.txt"];

        userResourcesCacheFile = [applicationSupport stringByAppendingPathComponent: @"srcngt2.txt"];
        userResourcesCacheSecondaryFile = [caches stringByAppendingPathComponent: @"srcngt2.txt"];
        userResourcesCacheSignatureFile = [applicationSupport stringByAppendingPathComponent: @"srcngtsgt2.txt"];
        userResourcesCacheSignatureSecondaryFile = [caches stringByAppendingPathComponent: @"srcngtsgt2.txt"];

        
        userResourcesDiffCacheFile = [caches stringByAppendingPathComponent: @"rsdfngt2.txt"];
        userResourcesDiffCacheSignatureFile = [caches stringByAppendingPathComponent:@"rsdfngtsgt2.txt"];

        self.useHttpsForEventServer = YES;
        self.useHttpsForContentServer = YES;
        self.installTimeCacheFile = [documents stringByAppendingPathComponent: @"swrve_install.txt"];
        self.installTimeCacheSecondaryFile = [caches stringByAppendingPathComponent: @"swrve_install.txt"];
        self.autoSendEventsOnResume = YES;
        self.autoSaveEventsOnResign = YES;
        self.talkEnabled = YES;
#if !defined(SWRVE_NO_PUSH)
        self.pushEnabled = NO;
        self.pushNotificationEvents = [NSSet setWithObject:@"Swrve.session.start"];
        self.autoCollectDeviceToken = YES;
#endif //!defined(SWRVE_NO_PUSH)
        self.autoShowMessagesMaxDelay = 5000;
        self.receiptProvider = [[SwrveReceiptProvider alloc] init];
        self.resourcesUpdatedCallback = ^() {
            // Do nothing by default.
        };
        self.selectedStack = SWRVE_STACK_US;
        
        self.conversationLightBoxColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:0.70f];
    }
    return self;
}

@end

@implementation ImmutableSwrveConfig

@synthesize userId;
@synthesize orientation;
@synthesize prefersIAMStatusBarHidden;
@synthesize httpTimeoutSeconds;
@synthesize eventsServer;
@synthesize useHttpsForEventServer;
@synthesize contentServer;
@synthesize useHttpsForContentServer;
@synthesize language;
@synthesize eventCacheFile;
@synthesize eventCacheSecondaryFile;
@synthesize eventCacheSignatureFile;
@synthesize locationCampaignCacheFile;
@synthesize locationCampaignCacheSecondaryFile;
@synthesize locationCampaignCacheSignatureFile;
@synthesize locationCampaignCacheSignatureSecondaryFile;
@synthesize userResourcesCacheFile;
@synthesize userResourcesCacheSecondaryFile;
@synthesize userResourcesCacheSignatureFile;
@synthesize userResourcesCacheSignatureSecondaryFile;
@synthesize userResourcesDiffCacheFile;
@synthesize userResourcesDiffCacheSignatureFile;
@synthesize installTimeCacheFile;
@synthesize installTimeCacheSecondaryFile;
@synthesize appVersion;
@synthesize receiptProvider;
@synthesize maxConcurrentDownloads;
@synthesize autoDownloadCampaignsAndResources;
@synthesize talkEnabled;
@synthesize defaultBackgroundColor;
@synthesize conversationLightBoxColor;
@synthesize newSessionInterval;
@synthesize resourcesUpdatedCallback;
@synthesize autoSendEventsOnResume;
@synthesize autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
@synthesize pushEnabled;
@synthesize pushNotificationEvents;
@synthesize autoCollectDeviceToken;
@synthesize pushCategories;
#endif //!defined(SWRVE_NO_PUSH)
@synthesize autoShowMessagesMaxDelay;
@synthesize selectedStack;

- (id)initWithSwrveConfig:(SwrveConfig*)config
{
    if (self = [super init]) {
        userId = config.userId;
        orientation = config.orientation;
        prefersIAMStatusBarHidden = config.prefersIAMStatusBarHidden;
        httpTimeoutSeconds = config.httpTimeoutSeconds;
        eventsServer = config.eventsServer;
        useHttpsForEventServer = config.useHttpsForEventServer;
        contentServer = config.contentServer;
        useHttpsForContentServer = config.useHttpsForContentServer;
        language = config.language;
        eventCacheFile = config.eventCacheFile;
        eventCacheSecondaryFile = config.eventCacheSecondaryFile;
        locationCampaignCacheFile = config.locationCampaignCacheFile;
        locationCampaignCacheSecondaryFile = config.locationCampaignCacheSecondaryFile;
        locationCampaignCacheSignatureFile = config.locationCampaignCacheSignatureFile;
        locationCampaignCacheSignatureSecondaryFile = config.locationCampaignCacheSignatureSecondaryFile;
        userResourcesCacheFile = config.userResourcesCacheFile;
        userResourcesCacheSecondaryFile = config.userResourcesCacheSecondaryFile;
        userResourcesCacheSignatureFile = config.userResourcesCacheSignatureFile;
        userResourcesCacheSignatureSecondaryFile = config.userResourcesCacheSignatureSecondaryFile;
        userResourcesDiffCacheFile = config.userResourcesDiffCacheFile;
        userResourcesDiffCacheSignatureFile = config.userResourcesDiffCacheSignatureFile;
        installTimeCacheFile = config.installTimeCacheFile;
        installTimeCacheSecondaryFile = config.installTimeCacheSecondaryFile;
        appVersion = config.appVersion;
        receiptProvider = config.receiptProvider;
        maxConcurrentDownloads = config.maxConcurrentDownloads;
        autoDownloadCampaignsAndResources = config.autoDownloadCampaignsAndResources;
        talkEnabled = config.talkEnabled;
        defaultBackgroundColor = config.defaultBackgroundColor;
        conversationLightBoxColor = config.conversationLightBoxColor;
        newSessionInterval = config.newSessionInterval;
        resourcesUpdatedCallback = config.resourcesUpdatedCallback;
        autoSendEventsOnResume = config.autoSendEventsOnResume;
        autoSaveEventsOnResign = config.autoSaveEventsOnResign;
#if !defined(SWRVE_NO_PUSH)
        pushEnabled = config.pushEnabled;
        pushNotificationEvents = config.pushNotificationEvents;
        autoCollectDeviceToken = config.autoCollectDeviceToken;
        pushCategories = config.pushCategories;
#endif //!defined(SWRVE_NO_PUSH)
        autoShowMessagesMaxDelay = config.autoShowMessagesMaxDelay;
        selectedStack = config.selectedStack;
    }

    return self;
}

@end


@interface SwrveIAPRewards()
@property (nonatomic, retain) NSMutableDictionary* rewards;
@end

@implementation SwrveIAPRewards
@synthesize rewards;

- (id) init
{
    self = [super init];
    self.rewards = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) addItem:(NSString*) resourceName withQuantity:(long) quantity
{
    [self addObject:resourceName withQuantity: quantity ofType: @"item"];
}

- (void) addCurrency:(NSString*) currencyName withAmount:(long) amount
{
    [self addObject:currencyName withQuantity:amount ofType:@"currency"];
}

- (void) addObject:(NSString*) name withQuantity:(long) quantity ofType:(NSString*) type
{
    if (![self checkArguments:name andQuantity:quantity andType:type]) {
        DebugLog(@"ERROR: SwrveIAPRewards has not been added because it received an illegal argument", nil);
        return;
    }

    NSDictionary* item = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithLong:quantity], @"amount", type, @"type", nil];
    [[self rewards] setValue:item forKey:name];
}

- (bool) checkArguments:(NSString*) name andQuantity:(long) quantity andType:(NSString*) type
{
    if (name == nil || [name length] <= 0) {
        DebugLog(@"SwrveIAPRewards illegal argument: reward name cannot be empty", nil);
        return false;
    }
    if (quantity <= 0) {
        DebugLog(@"SwrveIAPRewards illegal argument: reward amount must be greater than zero", nil);
        return false;
    }
    if (type == nil || [type length] <= 0) {
        DebugLog(@"SwrveIAPRewards illegal argument: type cannot be empty", nil);
        return false;
    }

    return true;
}

- (NSDictionary*) rewards {
    return rewards;
}

@end


@implementation Swrve

static Swrve * _swrveSharedInstance = nil;
static dispatch_once_t sharedInstanceToken = 0;
#if !defined(SWRVE_NO_PUSH)
static bool didSwizzle = false;
#endif //!defined(SWRVE_NO_PUSH)

@synthesize config;
@synthesize appID;
@synthesize apiKey;
@synthesize userID;
@synthesize deviceInfo;
@synthesize talk;
@synthesize resourceManager;

@synthesize userUpdates;
@synthesize deviceToken = _deviceToken;
@synthesize shortDeviceID;
@synthesize httpPerformanceMetrics;
@synthesize campaignsAndResourcesETAG;
@synthesize campaignsAndResourcesFlushFrequency;
@synthesize campaignsAndResourcesFlushRefreshDelay;
@synthesize campaignsAndResourcesTimer;
@synthesize campaignsAndResourcesTimerSeconds;
@synthesize campaignsAndResourcesLastRefreshed;
@synthesize campaignsAndResourcesInitialized;
@synthesize resourcesFile;
@synthesize resourcesDiffFile;
@synthesize eventBuffer;
@synthesize eventFileHasData;
@synthesize eventStream;
@synthesize eventFilename;
@synthesize eventSecondaryFilename;
@synthesize eventBufferBytes;
@synthesize eventsWereSent;
@synthesize batchURL;
@synthesize campaignsAndResourcesURL;
@synthesize locationSegmentVersion;

+ (void) resetSwrveSharedInstance
{
    _swrveSharedInstance = nil;
    sharedInstanceToken = 0;
}

+ (void) addSharedInstance:(Swrve*)instance
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = instance;
    });
}

+(Swrve*) sharedInstance
{
    if (!_swrveSharedInstance) {
        DebugLog(@"Warning: [Swrve sharedInstance] called before sharedInstanceWithAppID:... method.", nil);
    }
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey];
    });
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig];
    });
    return _swrveSharedInstance;
}

// Init methods with launchOptions for push
+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey launchOptions:(NSDictionary*)launchOptions
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey launchOptions:launchOptions];
    });
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig launchOptions:(NSDictionary*)launchOptions
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig launchOptions:launchOptions];
    });
    return _swrveSharedInstance;
}

// Deprecated shared initialization methods
+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey userID:swrveUserID];
    });
    return _swrveSharedInstance;
}

+(Swrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedInstance = [Swrve alloc];
        _swrveSharedInstance = [_swrveSharedInstance initWithAppID:swrveAppID apiKey:swrveAPIKey userID:swrveUserID config:swrveConfig];
    });
    return _swrveSharedInstance;
}


// Non shared instance initialization methods
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey
{
    SwrveConfig* newConfig = [[SwrveConfig alloc] init];
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:newConfig launchOptions:nil];
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig
{
   return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig launchOptions:nil];
}

// Deprecated non shared instance initialization methods
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID
{
    SwrveConfig* newConfig = [[SwrveConfig alloc] init];
    newConfig.userId = swrveUserID;
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:newConfig launchOptions:nil];
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig
{
    swrveConfig.userId = swrveUserID;
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig launchOptions:nil];
}

// Init methods with launchOptions for push
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey launchOptions:(NSDictionary*)launchOptions
{
    SwrveConfig* newConfig = [[SwrveConfig alloc] init];
    return [self initWithAppID:swrveAppID apiKey:swrveAPIKey config:newConfig launchOptions:launchOptions];
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig launchOptions:(NSDictionary*)launchOptions
{
    NSCAssert(self.config == nil, @"Do not initialize Swrve instance more than once!", nil);
    if ( self = [super init] ) {
        if (self.config) {
            DebugLog(@"Swrve may not be initialized more than once.", nil);
            return self;
        }

        [SwrveCommon addSharedInstance:self];
        NSString* swrveUserID = swrveConfig.userId;
        // Auto generate user id if necessary
        if (!swrveUserID) {
            swrveUserID = [[NSUserDefaults standardUserDefaults] stringForKey:swrve_user_id_key];
            if(!swrveUserID) {
                swrveUserID = [[NSUUID UUID] UUIDString];
            }
        }

        instanceID = [[SwrveInstanceIDRecorder sharedInstance] addSwrveInstanceID];
        [self sendCrashlyticsMetadata];

        NSCAssert(swrveConfig, @"Null config object given to Swrve", nil);

        appID = swrveAppID;
        apiKey = swrveAPIKey;
        userID = swrveUserID;

        NSCAssert(appID > 0, @"Invalid app ID given (%ld)", appID);
        NSCAssert(apiKey.length > 1, @"API Key is invalid (too short): %@", apiKey);
        NSCAssert(userID != nil, @"@UserID must not be nil.", nil);

        BOOL didSetUserId = [[NSUserDefaults standardUserDefaults] stringForKey:swrve_user_id_key] == nil;
        [[NSUserDefaults standardUserDefaults] setValue:userID forKey:swrve_user_id_key];

        [self setupConfig:swrveConfig];

        [self setHttpPerformanceMetrics:[[NSMutableArray alloc] init]];

        event_queued_callback = nil;

        blockStore = [[NSMutableDictionary alloc] init];
        blockStoreId = 0;

        locationSegmentVersion = 0; // init to zero

        config = [[ImmutableSwrveConfig alloc] initWithSwrveConfig:swrveConfig];
        [self initBuffer];
        deviceInfo = [NSMutableDictionary dictionary];

        install_time = [self getInstallTime:swrveConfig.installTimeCacheFile withSecondaryFile:swrveConfig.installTimeCacheSecondaryFile];
        lastSessionDate = [self getNow];

        NSURL* base_events_url = [NSURL URLWithString:swrveConfig.eventsServer];
        [self setBatchURL:[NSURL URLWithString:@"1/batch" relativeToURL:base_events_url]];

        NSURL* base_content_url = [NSURL URLWithString:self.config.contentServer];
        [self setCampaignsAndResourcesURL:[NSURL URLWithString:@"api/1/user_resources_and_campaigns" relativeToURL:base_content_url]];

        [self initResources];
        [self initResourcesDiff];

        [self setEventFilename:[NSURL fileURLWithPath:swrveConfig.eventCacheFile]];
        [self setEventSecondaryFilename:[NSURL fileURLWithPath:swrveConfig.eventCacheSecondaryFile]];
        [self setEventStream:[self createLogfile:SWRVE_TRUNCATE_IF_TOO_LARGE]];

        [self generateShortDeviceId];

        // Set up empty user attributes store
        self.userUpdates = [[NSMutableDictionary alloc]init];
        [self.userUpdates setValue:@"user" forKey:@"type"];
        [self.userUpdates setValue:[[NSMutableDictionary alloc]init] forKey:@"attributes"];

#if !defined(SWRVE_NO_PUSH)
        if(swrveConfig.autoCollectDeviceToken && _swrveSharedInstance == self && !didSwizzle){
            Class appDelegateClass = [[UIApplication sharedApplication].delegate class];

            SEL didRegisterSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
            SEL didFailSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
            SEL didReceiveSelector = @selector(application:didReceiveRemoteNotification:);

            // Cast to actual method signature
            didRegisterForRemoteNotificationsWithDeviceTokenImpl = (didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)[SwrveSwizzleHelper swizzleMethod:didRegisterSelector inClass:appDelegateClass withImplementationIn:self];
            didFailToRegisterForRemoteNotificationsWithErrorImpl = (didFailToRegisterForRemoteNotificationsWithErrorImplSignature)[SwrveSwizzleHelper swizzleMethod:didFailSelector inClass:appDelegateClass withImplementationIn:self];
            didReceiveRemoteNotificationImpl = (didReceiveRemoteNotificationImplSignature)[SwrveSwizzleHelper swizzleMethod:didReceiveSelector inClass:appDelegateClass withImplementationIn:self];

            didSwizzle = true;
        } else {
            didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;
            didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;
            didReceiveRemoteNotificationImpl = NULL;
        }

        [self registerForNotifications];
#endif //!defined(SWRVE_NO_PUSH)
        [self updateDeviceInfo];

        if (swrveConfig.talkEnabled) {
            talk = [[SwrveMessageController alloc] initWithSwrve:self];
            [self disableAutoShowAfterDelay];
        }

        [self queueSessionStart];
        [self queueDeviceProperties];

        // If this is the first time this user has been seen send install analytics
        if(didSetUserId) {
            [self eventInternal:@"Swrve.first_session" payload:nil triggerCallback:true];
        }

        [self setCampaignsAndResourcesInitialized:NO];

        self.campaignsAndResourcesFlushFrequency = [[NSUserDefaults standardUserDefaults] doubleForKey:@"swrve_cr_flush_frequency"];
        if (self.campaignsAndResourcesFlushFrequency <= 0) {
            self.campaignsAndResourcesFlushFrequency = SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_FREQUENCY / 1000;
        }

        self.campaignsAndResourcesFlushRefreshDelay = [[NSUserDefaults standardUserDefaults] doubleForKey:@"swrve_cr_flush_delay"];
        if (self.campaignsAndResourcesFlushRefreshDelay <= 0) {
            self.campaignsAndResourcesFlushRefreshDelay = SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_REFRESH_DELAY / 1000;
        }

        [self startCampaignsAndResourcesTimer];

#if !defined(SWRVE_NO_PUSH)
        // Check if the launch options of the app has any push notification in it
        if (launchOptions != nil) {
            NSDictionary * remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if (remoteNotification) {
                [self.talk pushNotificationReceived:remoteNotification];
            }
        }
#else
#pragma unused(launchOptions)
#endif //!defined(SWRVE_NO_PUSH)
    }

    [self sendQueuedEvents];

    return self;
}

#if !defined(SWRVE_NO_PUSH)
- (void)_deswizzlePushMethods
{
    if(_swrveSharedInstance == self && didSwizzle) {
        Class appDelegateClass = [[UIApplication sharedApplication].delegate class];

        SEL didRegister = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [SwrveSwizzleHelper deswizzleMethod:didRegister inClass:appDelegateClass originalImplementation:(IMP)didRegisterForRemoteNotificationsWithDeviceTokenImpl];
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;

        SEL didFail = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        [SwrveSwizzleHelper deswizzleMethod:didFail inClass:appDelegateClass originalImplementation:(IMP)didFailToRegisterForRemoteNotificationsWithErrorImpl];
        didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;

        SEL didReceive = @selector(application:didReceiveRemoteNotification:);
        [SwrveSwizzleHelper deswizzleMethod:didReceive inClass:appDelegateClass originalImplementation:(IMP)didReceiveRemoteNotificationImpl];
        didReceiveRemoteNotificationImpl = NULL;

        didSwizzle = false;
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    #pragma unused(application)
    Swrve* swrveInstance = [Swrve sharedInstance];
    if( swrveInstance == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {
        if (swrveInstance.talk != nil) {
            [swrveInstance.talk setDeviceToken:newDeviceToken];
        }

        if( swrveInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl != NULL ) {
            id target = [UIApplication sharedApplication].delegate;
            swrveInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl(target, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), application, newDeviceToken);
        }
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    #pragma unused(application)
    Swrve* swrveInstance = [Swrve sharedInstance];
    if( swrveInstance == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {
        DebugLog(@"Could not auto collected device token.", nil);

        if( swrveInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl != NULL ) {
            id target = [UIApplication sharedApplication].delegate;
            swrveInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl(target, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), application, error);
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
#pragma unused(application)
    Swrve* swrveInstance = [Swrve sharedInstance];
    if( swrveInstance == NULL) {
        DebugLog(@"Error: Push notification can only be automatically reported if you are using the Swrve instance singleton.", nil);
    } else {
        if (swrveInstance.talk != nil) {
            [swrveInstance.talk pushNotificationReceived:userInfo];
        }

        if( swrveInstance->didReceiveRemoteNotificationImpl != NULL ) {
            id target = [UIApplication sharedApplication].delegate;
            swrveInstance->didReceiveRemoteNotificationImpl(target, @selector(application:didReceiveRemoteNotification:), application, userInfo);
        }
    }
}

#endif //!defined(SWRVE_NO_PUSH)

-(void) queueSessionStart
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [self queueEvent:@"session_start" data:json triggerCallback:true];
}

-(int) sessionStart
{
    [self queueSessionStart];
    [self sendQueuedEvents];
    return SWRVE_SUCCESS;
}

-(int) sessionEnd
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [self queueEvent:@"session_end" data:json triggerCallback:true];
    return SWRVE_SUCCESS;
}

-(int) purchaseItem:(NSString*)itemName currency:(NSString*)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(itemName) forKey:@"item"];
    [json setValue:NullableNSString(itemCurrency) forKey:@"currency"];
    [json setValue:[NSNumber numberWithInt:itemCost] forKey:@"cost"];
    [json setValue:[NSNumber numberWithInt:itemQuantity] forKey:@"quantity"];
    [self queueEvent:@"purchase" data:json triggerCallback:true];
    return SWRVE_SUCCESS;
}

-(int) event:(NSString*)eventName
{
    if( [self isValidEventName:eventName]) {
        return [self eventInternal:eventName payload:nil triggerCallback:true];
    } else {
        return SWRVE_FAILURE;
    }
}

-(int) event:(NSString*)eventName payload:(NSDictionary*)eventPayload
{
    if( [self isValidEventName:eventName]) {
        return [self eventInternal:eventName payload:eventPayload triggerCallback:true];
    } else {
        return SWRVE_FAILURE;
    }
}

-(int) eventWithNoCallback:(NSString*)eventName payload:(NSDictionary*)eventPayload
{
    if( [self isValidEventName:eventName]) {
        return [self eventInternal:eventName payload:eventPayload triggerCallback:false];
    } else {
        return SWRVE_FAILURE;
    }
}

- (BOOL)isValidEventName:(NSString *)eventName {
    NSMutableArray *restrictedNamesStartWith = [NSMutableArray arrayWithObjects:@"Swrve.", @"swrve.", nil];
    for (NSString *restricted in restrictedNamesStartWith) {
        if (eventName == nil || [eventName hasPrefix:restricted]) {
            DebugLog(@"Event names cannot begin with %@* This event will not be sent. Eventname:%@", restricted, eventName);
            return false;
        }
    }
    return true;
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product
{
    return [self iap:transaction product:product rewards:nil];
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product rewards:(SwrveIAPRewards*)rewards
{
    NSString* product_id = @"unknown";
    switch(transaction.transactionState) {
        case SKPaymentTransactionStatePurchased:
        {
            if( transaction.payment != nil && transaction.payment.productIdentifier != nil){
                product_id = transaction.payment.productIdentifier;
            }

            NSString* transactionId  = [transaction transactionIdentifier];
            #pragma unused(transactionId)

            SwrveReceiptProviderResult* receipt = [self.config.receiptProvider obtainReceiptForTransaction:transaction];
            if ( !receipt || !receipt.encodedReceipt) {
                DebugLog(@"No transaction receipt could be obtained for %@", transactionId);
                return SWRVE_FAILURE;
            }
            DebugLog(@"Swrve building IAP event for transaction %@ (product %@)", transactionId, product_id);
            NSString* encodedReceipt = receipt.encodedReceipt;
            NSString* localCurrency = [product.priceLocale objectForKey:NSLocaleCurrencyCode];
            double localCost = [[product price] doubleValue];

            // Construct the IAP event
            NSString* store = @"apple";
            if( encodedReceipt == nil ) {
                store = @"unknown";
            }
            if ( rewards == nil ) {
                rewards = [[SwrveIAPRewards alloc] init];
            }

            [self maybeFlushToDisk];
            NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
            [json setValue:store forKey:@"app_store"];
            [json setValue:localCurrency forKey:@"local_currency"];
            [json setValue:[NSNumber numberWithDouble:localCost] forKey:@"cost"];
            [json setValue:[rewards rewards] forKey:@"rewards"];
            [json setValue:encodedReceipt forKey:@"receipt"];
            // Payload data
            NSMutableDictionary* eventPayload = [[NSMutableDictionary alloc] init];
            [eventPayload setValue:product_id forKey:@"product_id"];
            [json setValue:eventPayload forKey:@"payload"];
            if ( receipt.transactionId ) {
                // Send transactionId only for iOS7+. This is how the server knows it is an iOS7 receipt!
                [json setValue:receipt.transactionId forKey:@"transaction_id"];
            }
            [self queueEvent:@"iap" data:json triggerCallback:true];

            // After IAP event we want to immediately flush the event buffer and update campaigns and resources if necessary
            if ([self.config autoDownloadCampaignsAndResources]) {
                [self checkForCampaignAndResourcesUpdates:nil];
            }
        }
            break;
        case SKPaymentTransactionStateFailed:
        {
            if( transaction.payment != nil && transaction.payment.productIdentifier != nil){
                product_id = transaction.payment.productIdentifier;
            }
            NSString* error = @"unknown";
            if( transaction.error != nil && transaction.error.description != nil ) {
                error = transaction.error.description;
            }
            NSDictionary *payload = @{@"product_id" : product_id, @"error" : error};
            [self eventInternal:@"Swrve.iap.transaction_failed_on_client" payload:payload triggerCallback:true];
        }
            break;
        case SKPaymentTransactionStateRestored:
        {
            if( transaction.originalTransaction != nil && transaction.originalTransaction.payment != nil && transaction.originalTransaction.payment.productIdentifier != nil){
                product_id = transaction.originalTransaction.payment.productIdentifier;
            }
            NSDictionary *payload = @{@"product_id" : product_id};
            [self eventInternal:@"Swrve.iap.restored_on_client" payload:payload triggerCallback:true];
        }
            break;
        default:
            break;
    }

    return SWRVE_SUCCESS;
}

-(int) unvalidatedIap:(SwrveIAPRewards*) rewards localCost:(double) localCost localCurrency:(NSString*) localCurrency productId:(NSString*) productId productIdQuantity:(int) productIdQuantity
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:@"unknown" forKey:@"app_store"];
    [json setValue:localCurrency forKey:@"local_currency"];
    [json setValue:[NSNumber numberWithDouble:localCost] forKey:@"cost"];
    [json setValue:productId forKey:@"product_id"];
    [json setValue:[NSNumber numberWithInteger:productIdQuantity] forKey:@"quantity"];
    [json setValue:[rewards rewards] forKey:@"rewards"];
    [self queueEvent:@"iap" data:json triggerCallback:true];
    // After IAP event we want to immediately flush the event buffer and update campaigns and resources if necessary
    if ([self.config autoDownloadCampaignsAndResources]) {
        [self checkForCampaignAndResourcesUpdates:nil];
    }

    return SWRVE_SUCCESS;
}

-(int) currencyGiven:(NSString*)givenCurrency givenAmount:(double)givenAmount
{
    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(givenCurrency) forKey:@"given_currency"];
    [json setValue:[NSNumber numberWithDouble:givenAmount] forKey:@"given_amount"];
    [self queueEvent:@"currency_given" data:json triggerCallback:true];
    return SWRVE_SUCCESS;
}

-(int) userUpdate:(NSDictionary*)attributes
{
    [self maybeFlushToDisk];

    // Merge attributes with current set of attributes
    if (attributes) {
        NSMutableDictionary * currentAttributes = (NSMutableDictionary*)[self.userUpdates objectForKey:@"attributes"];
        [self.userUpdates setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
        for (id attributeKey in attributes) {
            id attribute = [attributes objectForKey:attributeKey];
            [currentAttributes setObject:attribute forKey:attributeKey];
        }
    }

    return SWRVE_SUCCESS;
}

-(SwrveResourceManager*) getSwrveResourceManager
{
    return [self resourceManager];
}

-(void) refreshCampaignsAndResources:(NSTimer*)timer
{
    #pragma unused(timer)
    [self refreshCampaignsAndResources];
}

-(void) refreshCampaignsAndResources
{
    // When campaigns need to be downloaded manually, enforce max. flush frequency
    if (!self.config.autoDownloadCampaignsAndResources) {
        NSDate* now = [self getNow];

        if (self.campaignsAndResourcesLastRefreshed != nil) {
            NSDate* nextAllowedTime = [NSDate dateWithTimeInterval:self.campaignsAndResourcesFlushFrequency sinceDate:self.campaignsAndResourcesLastRefreshed];
            if ([now compare:nextAllowedTime] == NSOrderedAscending) {
                // Too soon to call refresh again
                DebugLog(@"Request to retrieve campaign and user resource data was rate-limited.", nil);
                return;
            }
        }

        self.campaignsAndResourcesLastRefreshed = [self getNow];
    }

    NSMutableString* queryString = [NSMutableString stringWithFormat:@"?user=%@&api_key=%@&app_version=%@&joined=%llu",
                             self.userID, self.apiKey, self.config.appVersion, self->install_time];
    if (self.talk && [self.config talkEnabled]) {
        NSString* campaignQueryString = [self.talk getCampaignQueryString];
        [queryString appendFormat:@"&%@", campaignQueryString];
    }

    NSString* etagValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"campaigns_and_resources_etag"];
    if (etagValue != nil) {
        [queryString appendFormat:@"&etag=%@", etagValue];
    }


    NSURL* url = [NSURL URLWithString:queryString relativeToURL:[self campaignsAndResourcesURL]];
    DebugLog(@"Refreshing campaigns from URL %@", url);
    [self sendHttpGETRequest:url completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        if (!error) {
            NSInteger statusCode = 200;
            enum HttpStatus status = HTTP_SUCCESS;

            NSDictionary* headers = [[NSDictionary alloc] init];
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                statusCode = [httpResponse statusCode];
                status = [self getHttpStatus:httpResponse];
                headers = [httpResponse allHeaderFields];
            }

            if (status == SWRVE_SUCCESS) {
                if ([self isValidJson:data]) {
                    NSString* etagHeader = [headers objectForKey:@"ETag"];
                    if (etagHeader != nil) {
                        [[NSUserDefaults standardUserDefaults] setValue:etagHeader forKey:@"campaigns_and_resources_etag"];
                    }

                    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                    NSNumber* flushFrequency = [responseDict objectForKey:@"flush_frequency"];
                    if (flushFrequency != nil) {
                        self.campaignsAndResourcesFlushFrequency = [flushFrequency integerValue] / 1000;
                        [[NSUserDefaults standardUserDefaults] setDouble:self.campaignsAndResourcesFlushFrequency forKey:@"swrve_cr_flush_frequency"];
                    }

                    NSNumber* flushDelay = [responseDict objectForKey:@"flush_refresh_delay"];
                    if (flushDelay != nil) {
                        self.campaignsAndResourcesFlushRefreshDelay = [flushDelay integerValue] / 1000;
                        [[NSUserDefaults standardUserDefaults] setDouble:self.campaignsAndResourcesFlushRefreshDelay forKey:@"swrve_cr_flush_delay"];
                    }

                    if (self.talk && [self.config talkEnabled]) {
                        NSDictionary* campaignJson = [responseDict objectForKey:@"campaigns"];
                        if (campaignJson != nil) {
                            [self.talk updateCampaigns:campaignJson];

                            NSData* campaignData = [NSJSONSerialization dataWithJSONObject:campaignJson options:0 error:nil];
                            [[self talk] writeToCampaignCache:campaignData];

                            [[self talk] autoShowMessages];

                            // Notify campaigns have been downloaded
                            NSMutableArray* campaignIds = [[NSMutableArray alloc] init];
                            for( SwrveCampaign* campaign in self.talk.campaigns ){
                                [campaignIds addObject:[NSNumber numberWithUnsignedInteger:campaign.ID]];
                            }

                            NSDictionary* payload = @{ @"ids" : [campaignIds componentsJoinedByString:@","],
                                                       @"count" : [NSString stringWithFormat:@"%lu", (unsigned long)[self.talk.campaigns count]] };

                            [self eventInternal:@"Swrve.Messages.campaigns_downloaded" payload:payload triggerCallback:true];
                        }
                    }

                    NSDictionary* locationCampaignJson = [responseDict objectForKey:@"location_campaigns"];
                    if (locationCampaignJson != nil) {
                        NSDictionary* campaignsJson = [locationCampaignJson objectForKey:@"campaigns"];
                        [self saveLocationCampaignsInCache:campaignsJson];
                    }

                    NSArray* resourceJson = [responseDict objectForKey:@"user_resources"];
                    if (resourceJson != nil) {
                        [self updateResources:resourceJson writeToCache:YES];
                    }
                } else {
                    DebugLog(@"Invalid JSON received for user resources and campaigns", nil);
                }
            } else if (statusCode == 429) {
                DebugLog(@"Request to retrieve campaign and user resource data was rate-limited.", nil);
            } else {
                DebugLog(@"Request to retrieve campaign and user resource data failed", nil);
            }
        }

        if (![self campaignsAndResourcesInitialized]) {
            [self setCampaignsAndResourcesInitialized:YES];

            // Only called first time API call returns - whether failed or successful, whether new campaigns were returned or not;
            // this ensures that if API call fails or there are no changes, we call autoShowMessages with cached campaigns
            if ([self talk]) {
                [[self talk] autoShowMessages];
            }

            // Invoke listeners once to denote that the first attempt at downloading has finished
            // independent of whether the resources or campaigns have changed from cached values
            if ([[self config] resourcesUpdatedCallback]) {
                [[[self config] resourcesUpdatedCallback] invoke];
            }
        }
    }];
}

- (void) checkForCampaignAndResourcesUpdates:(NSTimer*)timer
{
    // If this wasn't called from the timer then reset the timer
    if (timer == nil) {
        NSDate* now = [self getNow];
        NSDate* nextInterval = [now dateByAddingTimeInterval:self.campaignsAndResourcesFlushFrequency];
        @synchronized([self campaignsAndResourcesTimer]) {
            [self.campaignsAndResourcesTimer setFireDate:nextInterval];
        }
    }

    // Check if there are events in the buffer or in the cache
    if ([self eventFileHasData] || [[self eventBuffer] count] > 0 || [self eventsWereSent]) {
        [self sendQueuedEvents];
        [self setEventsWereSent:NO];

        [NSTimer scheduledTimerWithTimeInterval:self.campaignsAndResourcesFlushRefreshDelay target:self selector:@selector(refreshCampaignsAndResources:) userInfo:nil repeats:NO];
    }
}

-(NSData*) getCampaignData:(int)category {
    if(SWRVE_CAMPAIGN_LOCATION == category) {
        return [[self getLocationCampaignFile] readFromFile];
    }
    return nil;
}

- (BOOL)processPermissionRequest:(NSString*)action {
    return [SwrvePermissions processPermissionRequest:action withSDK:self];
}

-(void) setPushNotificationsDeviceToken:(NSData*)newDeviceToken
{
    NSCAssert(newDeviceToken, @"The device token cannot be null", nil);
    NSString* newTokenString = [[[newDeviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    _deviceToken = newTokenString;
    [[NSUserDefaults standardUserDefaults] setValue:newTokenString forKey:swrve_device_token_key];
    [self queueDeviceProperties];
    [self sendQueuedEvents];
}

-(void) sendQueuedEvents
{
    if (!self.userID)
    {
        DebugLog(@"Swrve user_id is null. Not sending data.", nil);
        return;
    }

    DebugLog(@"Sending queued events", nil);
    if ([self eventFileHasData])
    {
        [self sendLogfile];
    }

    [self queueUserUpdates];

    // Early out if length is zero.
    if ([[self eventBuffer] count] == 0) return;

    // Swap buffers
    NSArray* buffer = [self eventBuffer];
    int bytes = [self eventBufferBytes];
    [self initBuffer];

    NSString* session_token = [self createSessionToken];
    NSString* array_body = [self copyBufferToJson:buffer];
    NSString* json_string = [self createJSON:session_token events:array_body];

    NSData* json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];

    [self setEventsWereSent:YES];

    [self sendHttpPOSTRequest:[self batchURL]
                     jsonData:json_data
            completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {

                if (error){
                    DebugLog(@"Error opening HTTP stream: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                    [self setEventBufferBytes:[self eventBufferBytes] + bytes];
                    [[self eventBuffer] addObjectsFromArray:buffer];
                    return;
                }

                // Schedule the stream on the current run loop, then open the stream (which
                // automatically sends the request).  Wait for at least one byte of data to
                // be returned by the server.  As soon as at least one byte is available,
                // the full HTTP response header is available.  If no data is returned
                // within the timeout period, give up.
                SwrveSendContext* sendContext = [[SwrveSendContext alloc] init];
                [sendContext setSwrveReference:self];
                [sendContext setSwrveInstanceID:self->instanceID];
                [sendContext setBuffer:buffer];
                [sendContext setBufferLength:bytes];

                enum HttpStatus status = HTTP_SUCCESS;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                    status = [self getHttpStatus:httpResponse];
                }
                [self eventsSentCallback:status withData:data andContext:sendContext];
    }];
}

-(void) saveEventsToDisk
{
    DebugLog(@"Writing unsent event data to file", nil);

    [self queueUserUpdates];

    if ([self eventStream] && [[self eventBuffer] count] > 0)
    {
        NSString* json = [self copyBufferToJson:[self eventBuffer]];
        NSData* buffer = [json dataUsingEncoding:NSUTF8StringEncoding];
        [[self eventStream] write:(const uint8_t *)[buffer bytes] maxLength:[buffer length]];
        [[self eventStream] write:(const uint8_t *)swrve_trailing_comma maxLength:strlen(swrve_trailing_comma)];
        [self setEventFileHasData:YES];
    }

    // Always empty the buffer
    [self initBuffer];
}

-(void) setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock
{
    event_queued_callback = callbackBlock;
}

-(void) shutdown
{
    NSLog(@"shutting down swrveInstance..");
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:instanceID] == NO)
    {
        DebugLog(@"Swrve shutdown: called on invalid instance.", nil);
        return;
    }
    
    [self stopCampaignsAndResourcesTimer];

    //ensure UI isn't displaying during shutdown
    [self.talk cleanupConversationUI];
    [self.talk dismissMessageWindow];
    talk = nil;
    
    resourceManager = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [[SwrveInstanceIDRecorder sharedInstance]removeSwrveInstanceID:instanceID];

    if ([self eventStream]) {
        [[self eventStream] close];
        [self setEventStream:nil];
    }

    [self setEventBuffer:nil];
}

// Deprecated
- (BOOL) appInBackground {
    UIApplicationState swrveState = [[UIApplication sharedApplication] applicationState];
    return (swrveState == UIApplicationStateInactive || swrveState == UIApplicationStateBackground);
}

#pragma mark -
#pragma mark Private methods

-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback
{
    if (!eventPayload) {
        eventPayload = [[NSDictionary alloc]init];
    }

    [self maybeFlushToDisk];
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(eventName) forKey:@"name"];
    [json setValue:eventPayload forKey:@"payload"];
    [self queueEvent:@"event" data:json triggerCallback:triggerCallback];
    return SWRVE_SUCCESS;
}

-(void) dealloc
{
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:instanceID] == YES)
    {
        [self shutdown];
    }
}

-(void) removeBlockStoreItem:(int)blockId
{
    [blockStore removeObjectForKey:[NSNumber numberWithInt:blockId ]];
}

-(void) updateDeviceInfo
{
    NSMutableDictionary * mutableInfo = (NSMutableDictionary*)self.deviceInfo;
    [mutableInfo removeAllObjects];
    [mutableInfo addEntriesFromDictionary:[self getDeviceProperties]];
    // Send permission events
    [SwrvePermissions compareStatusAndQueueEventsWithSDK:self];
}

-(void) registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification object:nil];
}

-(void) appDidBecomeActive:(NSNotification*)notification
{
#pragma unused(notification)
    // Ignore the first call when the SDK is initialised at app start
    if (ignoreFirstDidBecomeActive) {
        ignoreFirstDidBecomeActive = NO;
        return;
    }

    NSDate* now = [self getNow];
    NSTimeInterval secondsPassed = [now timeIntervalSinceDate:lastSessionDate];
    if (secondsPassed >= self.config.newSessionInterval) {
        // We consider this a new session as more than newSessionInterval seconds
        // have passed.
        [self sessionStart];
        // Re-enable auto show messages at session start
        if ([self talk]) {
            [[self talk] setAutoShowMessagesEnabled:YES];
            [self disableAutoShowAfterDelay];
        }
    }

    [self queueDeviceProperties];
    if (self.config.autoSendEventsOnResume) {
        [self sendQueuedEvents];
    }

    if (self.config.talkEnabled) {
        [self.talk appDidBecomeActive];
    }
    [self resumeCampaignsAndResourcesTimer];
    lastSessionDate = [self getNow];
}

-(void) appWillResignActive:(NSNotification*)notification
{
    #pragma unused(notification)
    lastSessionDate = [self getNow];
    [self suspend:NO];
}

-(void) appWillTerminate:(NSNotification*)notification
{
    #pragma unused(notification)
    [self suspend:YES];
}

-(void) suspend:(BOOL)terminating
{
    if (terminating) {
        if (self.config.autoSaveEventsOnResign) {
            [self saveEventsToDisk];
        }
    } else {
        [self sendQueuedEvents];
    }

    if(self.config.talkEnabled) {
        [self.talk saveCampaignsState];
    }
    [self stopCampaignsAndResourcesTimer];
}

-(void) startCampaignsAndResourcesTimer
{
    if (!self.config.autoDownloadCampaignsAndResources) {
        return;
    }

    [self refreshCampaignsAndResources];
    // Start repeating timer
    [self setCampaignsAndResourcesTimer:[NSTimer scheduledTimerWithTimeInterval:1
                                                                         target:self
                                                                       selector:@selector(campaignsAndResourcesTimerTick:)
                                                                       userInfo:nil
                                                                        repeats:YES]];

    // Call refresh once after refresh delay to ensure campaigns are reloaded after initial events have been sent
    [NSTimer scheduledTimerWithTimeInterval:[self campaignsAndResourcesFlushRefreshDelay]
                                     target:self
                                   selector:@selector(refreshCampaignsAndResources:)
                                   userInfo:nil
                                    repeats:NO];
}

-(void)campaignsAndResourcesTimerTick:(NSTimer*)timer
{
    self.campaignsAndResourcesTimerSeconds++;
    if (self.campaignsAndResourcesTimerSeconds >= self.campaignsAndResourcesFlushFrequency) {
        self.campaignsAndResourcesTimerSeconds = 0;
        [self checkForCampaignAndResourcesUpdates:timer];
    }
}

- (void) resumeCampaignsAndResourcesTimer
{
    if (!self.config.autoDownloadCampaignsAndResources) {
        return;
    }

    @synchronized(self.campaignsAndResourcesTimer) {
        [self stopCampaignsAndResourcesTimer];
        [self setCampaignsAndResourcesTimer:[NSTimer scheduledTimerWithTimeInterval:1
                                                                             target:self
                                                                           selector:@selector(campaignsAndResourcesTimerTick:)
                                                                           userInfo:nil
                                                                            repeats:YES]];
    }
}

- (void) stopCampaignsAndResourcesTimer
{
    @synchronized(self.campaignsAndResourcesTimer) {
        if (self.campaignsAndResourcesTimer && [self.campaignsAndResourcesTimer isValid]) {
            [self.campaignsAndResourcesTimer invalidate];
        }
    }
}

//If talk enabled ensure that after SWRVE_DEFAULT_AUTOSHOW_MESSAGES_MAX_DELAY autoshow is disabled
-(void) disableAutoShowAfterDelay
{
    if ([self talk]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
        SEL authoShowSelector = @selector(setAutoShowMessagesEnabled:);
#pragma clang diagnostic pop

        NSInvocation* disableAutoshowInvocation = [NSInvocation invocationWithMethodSignature:
                                                   [[self talk] methodSignatureForSelector:authoShowSelector]];

        bool arg = NO;
        [disableAutoshowInvocation setSelector:authoShowSelector];
        [disableAutoshowInvocation setTarget:[self talk]];
        [disableAutoshowInvocation setArgument:&arg atIndex:2];
        [NSTimer scheduledTimerWithTimeInterval:(self.config.autoShowMessagesMaxDelay/1000) invocation:disableAutoshowInvocation repeats:NO];
    }
}


-(void) queueUserUpdates
{
    NSMutableDictionary * currentAttributes = (NSMutableDictionary*)[self.userUpdates objectForKey:@"attributes"];
    if (currentAttributes.count > 0) {
        [self.userUpdates setValue:[NSNumber numberWithInteger:[self nextEventSequenceNumber]] forKey:@"seqnum"];
        [self queueEvent:@"user" data:self.userUpdates triggerCallback:true];
        [currentAttributes removeAllObjects];
    }
}

- (void) pushNotificationReceived:(NSDictionary *)userInfo {
    
    // Try to get the identifier _p
    id pushIdentifier = [userInfo objectForKey:@"_p"];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
        NSString* pushId = @"-1";
        if ([pushIdentifier isKindOfClass:[NSString class]]) {
            pushId = (NSString*)pushIdentifier;
        }
        else if ([pushIdentifier isKindOfClass:[NSNumber class]]) {
            pushId = [((NSNumber*)pushIdentifier) stringValue];
        }
        else {
            DebugLog(@"Unknown Swrve notification ID class for _p attribute", nil);
            return;
        }

        // Only process this push if we haven't seen it before
        if (lastProcessedPushId == nil || ![pushId isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = pushId;

            // Process deeplink _sd (and old _d)
            id pushDeeplinkRaw = [userInfo objectForKey:@"_sd"];
            if (pushDeeplinkRaw == nil || ![pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                // Retrieve old push deeplink for backwards compatibility
                pushDeeplinkRaw = [userInfo objectForKey:@"_d"];
            }
            if ([pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                NSString* pushDeeplink = (NSString*)pushDeeplinkRaw;
                NSURL* url = [NSURL URLWithString:pushDeeplink];
                BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
                if( url != nil && canOpen ) {
                    DebugLog(@"Action - %@ - handled.  Sending to application as URL", pushDeeplink);
                    [[UIApplication sharedApplication] openURL:url];
                } else {
                    DebugLog(@"Could not process push deeplink - %@", pushDeeplink);
                }
            }

            NSString* eventName = [NSString stringWithFormat:@"Swrve.Messages.Push-%@.engaged", pushId];
            [self eventInternal:eventName payload:nil triggerCallback:true];
            DebugLog(@"Got Swrve notification with ID %@", pushId);
        } else {
            DebugLog(@"Got Swrve notification with ID %@ but it was already processed", pushId);
        }
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }
}

// Get a string that represents the current App Version
// The implementation intentionally is unspecified, the rest of the SDK is not aware
// of the details of this.
+(NSString*) getAppVersion
{
    NSString * appVersion = nil;
    @try {
        appVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    }
    @catch (NSException * e) {}
    if (!appVersion)
    {
        return @"error";
    }

    return appVersion;
}

static NSString* httpScheme(bool useHttps)
{
    return useHttps ? @"https" : @"http";
}

-(void) setupConfig:(SwrveConfig *)newConfig
{
    NSString *prefix = [self getStackHostPrefixFromConfig:newConfig];

    // Set up default server locations
    if (nil == newConfig.eventsServer) {
        newConfig.eventsServer = [NSString stringWithFormat:@"%@://%ld.%@api.swrve.com", httpScheme(newConfig.useHttpsForEventServer), self.appID, prefix];
    }

    if (nil == newConfig.contentServer) {
        newConfig.contentServer = [NSString stringWithFormat:@"%@://%ld.%@content.swrve.com", httpScheme(newConfig.useHttpsForContentServer), self.appID, prefix];
    }

    // Validate other values
    NSCAssert(newConfig.httpTimeoutSeconds > 0, @"httpTimeoutSeconds must be greater than zero or requests will fail immediately.", nil);
}

-(NSString *) getStackHostPrefixFromConfig:(SwrveConfig *)newConfig {
    if (newConfig.selectedStack == SWRVE_STACK_EU) {
        return @"eu-";
    } else {
        return @""; // default to US which has no prefix
    }
}


-(void) maybeFlushToDisk
{
    if ([self eventBufferBytes] > SWRVE_MEMORY_QUEUE_MAX_BYTES) {
        [self saveEventsToDisk];
    }
}

-(void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback
{
    if ([self eventBuffer]) {
        // Add common attributes (if not already present)
        if (![eventData objectForKey:@"type"]) {
            [eventData setValue:eventType forKey:@"type"];
        }
        if (![eventData objectForKey:@"time"]) {
            [eventData setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
        }
        if (![eventData objectForKey:@"seqnum"]) {
            [eventData setValue:[NSNumber numberWithInteger:[self nextEventSequenceNumber]] forKey:@"seqnum"];
        }

        // Convert to string
        NSData* json_data = [NSJSONSerialization dataWithJSONObject:eventData options:0 error:nil];
        if (json_data) {
            NSString* json_string = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
            [self setEventBufferBytes:[self eventBufferBytes] + (int)[json_string length]];
            [[self eventBuffer] addObject:json_string];

            if (triggerCallback && event_queued_callback != NULL )
            {
                event_queued_callback(eventData, json_string);
            }
        }
    }
}

-(NSString*) swrveSDKVersion {
    return @SWRVE_SDK_VERSION;
}

-(NSString*) appVersion {
    return self.config.appVersion;
}

-(NSSet*) pushCategories {
#if !defined(SWRVE_NO_PUSH)
    return self.config.pushCategories;
#else
    return nil;
#endif
}

- (float) _estimate_dpi
{
    float scale = (float)[[UIScreen mainScreen] scale];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 132.0f * scale;
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 163.0f * scale;
    }

    return 160.0f * scale;
}

- (void) sendCrashlyticsMetadata
{
    // Check if Crashlytics is used in this project
    Class crashlyticsClass = NSClassFromString(@"Crashlytics");
    if (crashlyticsClass != nil) {
        SEL setObjectValueSelector = NSSelectorFromString(@"setObjectValue:forKey:");
        if ([crashlyticsClass respondsToSelector:setObjectValueSelector]) {
            IMP imp = [crashlyticsClass methodForSelector:setObjectValueSelector];
            void (*func)(__strong id, SEL, id, NSString*) = (void(*)(__strong id, SEL, id, NSString*))imp;
            func(crashlyticsClass, setObjectValueSelector, @SWRVE_SDK_VERSION, @"Swrve_version");
        }
    }
}

- (CGRect) getDeviceScreenBounds
{
    UIScreen* screen   = [UIScreen mainScreen];
    CGRect bounds = [screen bounds];
    float screen_scale = (float)[[UIScreen mainScreen] scale];
    bounds.size.width  = bounds.size.width  * screen_scale;
    bounds.size.height = bounds.size.height * screen_scale;
    const int side_a = (int)bounds.size.width;
    const int side_b = (int)bounds.size.height;
    bounds.size.width  = (side_a > side_b)? side_b : side_a;
    bounds.size.height = (side_a > side_b)? side_a : side_b;
    return bounds;
}

- (NSString *) getHWMachineName {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

- (NSDictionary*) getDeviceProperties
{
    NSMutableDictionary* deviceProperties = [[NSMutableDictionary alloc] init];

    UIDevice* device = [UIDevice currentDevice];
    CGRect screen_bounds = [self getDeviceScreenBounds];
    NSNumber* device_width = [NSNumber numberWithFloat: (float)screen_bounds.size.width];
    NSNumber* device_height = [NSNumber numberWithFloat: (float)screen_bounds.size.height];
    NSNumber* dpi = [NSNumber numberWithFloat:[self _estimate_dpi]];
    [deviceProperties setValue:[self getHWMachineName] forKey:@"swrve.device_name"];
    [deviceProperties setValue:[device systemName]    forKey:@"swrve.os"];
    [deviceProperties setValue:[device systemVersion] forKey:@"swrve.os_version"];
    [deviceProperties setValue:dpi                    forKey:@"swrve.device_dpi"];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self->install_time];
    [deviceProperties setValue:[dateFormatter stringFromDate:date] forKey:@"swrve.install_date"];

    [deviceProperties setValue:[NSNumber numberWithInteger:CONVERSATION_VERSION] forKey:@"swrve.conversation_version"];

    // Carrier info
    CTCarrier *carrier = [self getCarrierInfo];
    if (carrier != nil) {
        NSString* mobileCountryCode = [carrier mobileCountryCode];
        NSString* mobileNetworkCode = [carrier mobileNetworkCode];
        if (mobileCountryCode != nil && mobileNetworkCode != nil) {
            NSMutableString* carrierCode = [[NSMutableString alloc] initWithString:mobileCountryCode];
            [carrierCode appendString:mobileNetworkCode];
            [deviceProperties setValue:carrierCode           forKey:@"swrve.sim_operator.code"];
        }
        [deviceProperties setValue:[carrier carrierName]     forKey:@"swrve.sim_operator.name"];
        [deviceProperties setValue:[carrier isoCountryCode]  forKey:@"swrve.sim_operator.iso_country_code"];
    }

    // Get current state of permissions
    NSDictionary* permissionStatus = [SwrvePermissions currentStatusWithSDK:self];
    [deviceProperties addEntriesFromDictionary:permissionStatus];

    NSTimeZone* tz     = [NSTimeZone localTimeZone];
    NSNumber* min_os = [NSNumber numberWithInt: __IPHONE_OS_VERSION_MIN_REQUIRED];
    NSString *sdk_language = self.config.language;
    NSNumber* secondsFromGMT = [NSNumber numberWithInteger:[tz secondsFromGMT]];
    NSString* timezone_name = [tz name];
    NSString* regionCountry = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];

    [deviceProperties setValue:min_os                 forKey:@"swrve.ios_min_version"];
    [deviceProperties setValue:sdk_language           forKey:@"swrve.language"];
    [deviceProperties setValue:device_height          forKey:@"swrve.device_height"];
    [deviceProperties setValue:device_width           forKey:@"swrve.device_width"];
    [deviceProperties setValue:@SWRVE_SDK_VERSION     forKey:@"swrve.sdk_version"];
    [deviceProperties setValue:@"apple"               forKey:@"swrve.app_store"];
    [deviceProperties setValue:secondsFromGMT         forKey:@"swrve.utc_offset_seconds"];
    [deviceProperties setValue:timezone_name          forKey:@"swrve.timezone_name"];
    [deviceProperties setValue:regionCountry          forKey:@"swrve.device_region"];

    // Push properties
    if (self.deviceToken) {
        [deviceProperties setValue:self.deviceToken forKey:@"swrve.ios_token"];
    }

    // Optional identifiers
#if defined(SWRVE_LOG_IDFA)
    if([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled])
    {
        NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        [deviceProperties setValue:idfa               forKey:@"swrve.IDFA"];
    }
#endif //defined(SWRVE_LOG_IDFA)
#if defined(SWRVE_LOG_IDFV)
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [deviceProperties setValue:idfv               forKey:@"swrve.IDFV"];
#endif //defined(SWRVE_LOG_IDFV)

    return deviceProperties;
}

- (CTCarrier*) getCarrierInfo
{
    // Obtain carrier info from the device
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    return [netinfo subscriberCellularProvider];
}

- (void) queueDeviceProperties
{
    NSDictionary* deviceProperties = [self getDeviceProperties];
    NSMutableString* formattedDeviceData = [[NSMutableString alloc] initWithFormat:
    @"                      User: %@\n"
     "                   API Key: %@\n"
     "                    App ID: %ld\n"
     "               App Version: %@\n"
     "                  Language: %@\n"
     "              Event Server: %@\n"
     "            Content Server: %@\n",
          self.userID,
          self.apiKey,
          self.appID,
          self.config.appVersion,
          self.config.language,
          self.config.eventsServer,
          self.config.contentServer];

    for (NSString* key in deviceProperties) {
        [formattedDeviceData appendFormat:@"  %24s: %@\n", [key UTF8String], [deviceProperties objectForKey:key]];
    }
    
    if (!getenv("RUNNING_UNIT_TESTS")) {
        DebugLog(@"Swrve config:\n%@", formattedDeviceData);
    }
    [self updateDeviceInfo];
    [self userUpdate:self.deviceInfo];
}

// Get the time that the application was first installed.
// This value is stored in a file. If this file is not available in any of the files (new and legacy),
// then we assume that the application was installed now, and save the current time to the file.
- (UInt64) getInstallTime:(NSString*)fileName withSecondaryFile:(NSString*)secondaryFileName
{
    unsigned long long seconds = 0;

    // Primary install file (defaults to documents path)
    NSError* error = NULL;
    NSString* file_contents = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];

    if (!error && file_contents) {
        seconds = (unsigned long long)[file_contents longLongValue];
    } else {
        DebugLog(@"could not read file: %@", fileName);
    }

    // Migration from Cache folder to Documents to prevent the file from being deleted
    // Secondary install file (defaults to cache path, legacy from < iOS SDK 4.5)
    if (seconds <= 0) {
        error = NULL;
        file_contents = [[NSString alloc] initWithContentsOfFile:secondaryFileName encoding:NSUTF8StringEncoding error:&error];
        if (!error && file_contents) {
            seconds = (unsigned long long)[file_contents longLongValue];
            if (seconds > 0) {
                // Write to new path
                [file_contents writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
        } else {
            DebugLog(@"could not read file: %@", fileName);
        }
    }

    // If we loaded a non-zero value we're done.
    if (seconds > 0)
    {
        UInt64 result = seconds;
        return result * 1000;
    }

    UInt64 time = [self getTime];
    NSString* currentTime = [NSString stringWithFormat:@"%llu", time/(UInt64)1000L];
    [currentTime writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    return (time / 1000 * 1000);
}

/*
 * Invalidates the currently stored ETag
 * Should be called when a refresh of campaigns and resources needs to be forced (eg. when cached data cannot be read)
 */
- (void) invalidateETag
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"campaigns_and_resources_etag"];
}


- (void) saveLocationCampaignsInCache:(NSDictionary*)campaignsJson
{
    NSError* error = nil;
    NSData* locationCampaignsData = [NSJSONSerialization dataWithJSONObject:campaignsJson options:0 error:&error];
    if (error) {
        DebugLog(@"Error parsing/writing location campaigns.\nError: %@\njson: %@", error, campaignsJson);
    } else {
        [[self getLocationCampaignFile] writeToFile:locationCampaignsData];
    }
}

+ (void) migrateOldCacheFile:(NSString*)oldPath withNewPath:(NSString*)newPath {
    // Old file defaults to cache directory, should be moved to new location
    if ([[NSFileManager defaultManager] isReadableFileAtPath:oldPath]) {
        [[NSFileManager defaultManager] copyItemAtPath:oldPath toPath:newPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
    }
}

- (SwrveSignatureProtectedFile *)getLocationCampaignFile {
    // Migrate event data from cache to application data (4.5.1+)
    [SwrveFileManagement applicationSupportPath];
    
    [Swrve migrateOldCacheFile:self.config.locationCampaignCacheSecondaryFile withNewPath:self.config.locationCampaignCacheFile];
    [Swrve migrateOldCacheFile:self.config.locationCampaignCacheSignatureSecondaryFile withNewPath:self.config.locationCampaignCacheSignatureFile];
    
    NSURL *fileURL = [NSURL fileURLWithPath:self.config.locationCampaignCacheFile];
    NSURL *signatureURL = [NSURL fileURLWithPath:self.config.locationCampaignCacheSignatureFile];
    NSString *signatureKey = [self getSignatureKey];
    SwrveSignatureProtectedFile *locationCampaignFile = [[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:signatureKey];
    return locationCampaignFile;
}

- (void) initResources
{
    // Migrate event data from cache to application data (4.5.1+)
    [Swrve migrateOldCacheFile:self.config.userResourcesCacheSecondaryFile withNewPath:self.config.userResourcesCacheFile];
    [Swrve migrateOldCacheFile:self.config.userResourcesCacheSignatureSecondaryFile withNewPath:self.config.userResourcesCacheSignatureFile];
    
    // Create signature protected cache file
    NSURL* fileURL = [NSURL fileURLWithPath:self.config.userResourcesCacheFile];
    NSURL* signatureURL = [NSURL fileURLWithPath:self.config.userResourcesCacheSignatureFile];
    [self setResourcesFile:[[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:[self getSignatureKey] signatureErrorListener:self]];

    // Initialize resource manager
    resourceManager = [[SwrveResourceManager alloc] init];

    // read content of resources file and update resource manager if signature valid
    NSData* content = [[self resourcesFile] readFromFile];

    if (content != nil) {
        NSError* error = nil;
        NSArray* resourcesArray = [NSJSONSerialization JSONObjectWithData:content options:NSJSONReadingMutableContainers error:&error];
        if (!error) {
            [self updateResources:resourcesArray writeToCache:NO];
        }
    } else {
        [self invalidateETag];
    }
}

- (void) updateResources:(NSArray*)resourceJson writeToCache:(BOOL)writeToCache
{
    [[self resourceManager] setResourcesFromArray:resourceJson];

    if (writeToCache) {
        NSData* resourceData = [NSJSONSerialization dataWithJSONObject:resourceJson options:0 error:nil];
        [[self resourcesFile] writeToFile:resourceData];
    }

    if ([[self config] resourcesUpdatedCallback] != nil) {
        [[[self config] resourcesUpdatedCallback] invoke];
    }
}

enum HttpStatus {
    HTTP_SUCCESS,
    HTTP_REDIRECTION,
    HTTP_CLIENT_ERROR,
    HTTP_SERVER_ERROR
};

- (enum HttpStatus) getHttpStatus:(NSHTTPURLResponse*) httpResponse
{
    long code = [httpResponse statusCode];

    if (code < 300) {
        return HTTP_SUCCESS;
    }

    if (code < 400) {
        return HTTP_REDIRECTION;
    }

    if (code < 500) {
        return HTTP_CLIENT_ERROR;
    }

    // 500+
    return HTTP_SERVER_ERROR;
}

- (NSOutputStream*) createLogfile:(int)mode
{
    // If the file already exists, close it.
    if ([self eventStream])
    {
        [[self eventStream] close];
    }
    
    // Migrate event data from cache to application data (4.5.1+)
    // Old file defaults to cache directory, should be moved to new location
    if ([[NSFileManager defaultManager] isReadableFileAtPath:[self.eventSecondaryFilename path]]) {
        [[NSFileManager defaultManager] copyItemAtURL:self.eventSecondaryFilename toURL:self.eventFilename error:nil];
        [[NSFileManager defaultManager] removeItemAtURL:self.eventSecondaryFilename error:nil];
    }
    

    NSOutputStream* newFile = NULL;
    [self setEventFileHasData:NO];

    switch (mode)
    {
        case SWRVE_TRUNCATE_FILE:
            newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:NO];
            break;

        case SWRVE_APPEND_TO_FILE:
            newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:YES];
            break;

        case SWRVE_TRUNCATE_IF_TOO_LARGE:
        {
            NSData* cacheContent = [NSData dataWithContentsOfURL:[self eventFilename]];

            if (cacheContent == nil)
            {
                newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:NO];
            } else {
                NSUInteger cacheLength = [cacheContent length];
                [self setEventFileHasData:(cacheLength > 0)];

                if (cacheLength < SWRVE_DISK_MAX_BYTES) {
                    newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:YES];
                } else {
                    newFile = [NSOutputStream outputStreamWithURL:[self eventFilename] append:NO];
                    DebugLog(@"Swrve log file too large (%lu)... truncating", (unsigned long)cacheLength);
                    [self setEventFileHasData:NO];
                }
            }

            break;
        }
    }

    [newFile open];

    return newFile;
}

- (void) eventsSentCallback:(enum HttpStatus)status withData:(NSData*)data andContext:(SwrveSendContext*)client_info
{
    #pragma unused(data)
    Swrve* swrve = [client_info swrveReference];
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:[client_info swrveInstanceID]] == YES) {

        switch (status) {
            case HTTP_REDIRECTION:
            case HTTP_SUCCESS:
                DebugLog(@"Success sending events to Swrve", nil);
                break;
            case HTTP_CLIENT_ERROR:
                DebugLog(@"HTTP Error - not adding events back into the queue: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                break;
            case HTTP_SERVER_ERROR:
                DebugLog(@"Error sending event data to Swrve (%@) Adding data back onto unsent message buffer", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                [[swrve eventBuffer] addObjectsFromArray:[client_info buffer]];
                [swrve setEventBufferBytes:[swrve eventBufferBytes] + [client_info bufferLength]];
                break;
        }
    }
}

// Convert the array of strings into a json array.
// This does not add the square brackets.
- (NSString*) copyBufferToJson:(NSArray*) buffer
{
    return [buffer componentsJoinedByString:@",\n"];
}

- (NSString*) createJSON:(NSString*)sessionToken events:(NSString*)rawEvents
{
    NSString *eventArray = [NSString stringWithFormat:@"[%@]", rawEvents];
    NSData *bodyData = [eventArray dataUsingEncoding:NSUTF8StringEncoding];
    NSArray* body = [NSJSONSerialization
                     JSONObjectWithData:bodyData
                     options:NSJSONReadingMutableContainers
                     error:nil];

    NSMutableDictionary* jsonPacket = [[NSMutableDictionary alloc] init];
    [jsonPacket setValue:self.userID forKey:@"user"];
    [jsonPacket setValue:self.shortDeviceID forKey:@"short_device_id"];
    [jsonPacket setValue:[NSNumber numberWithInt:SWRVE_VERSION] forKey:@"version"];
    [jsonPacket setValue:NullableNSString(self.config.appVersion) forKey:@"app_version"];
    [jsonPacket setValue:NullableNSString(sessionToken) forKey:@"session_token"];
    [jsonPacket setValue:body forKey:@"data"];

    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonPacket options:0 error:nil];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return json;
}

- (NSInteger) nextEventSequenceNumber
{
    NSInteger seqno;
    @synchronized(self) {
        // Defaults to 0 if this value is not available
        seqno = [[NSUserDefaults standardUserDefaults] integerForKey:@"swrve_event_seqnum"];
        seqno += 1;
        [[NSUserDefaults standardUserDefaults] setInteger:seqno forKey:@"swrve_event_seqnum"];
    }

    return seqno;
}

- (void) logfileSentCallback:(enum HttpStatus)status withData:(NSData*)data andContext:(SwrveSendLogfileContext*)context
{
    #pragma unused(data)
    Swrve* swrve = [context swrveReference];
    if ([[SwrveInstanceIDRecorder sharedInstance]hasSwrveInstanceID:[context swrveInstanceID]] == YES) {
        int mode = SWRVE_TRUNCATE_FILE;

        switch (status) {
            case HTTP_SUCCESS:
            case HTTP_CLIENT_ERROR:
            case HTTP_REDIRECTION:
                DebugLog(@"Received a valid HTTP POST response. Truncating event log file", nil);
                break;
            case HTTP_SERVER_ERROR:
                DebugLog(@"Error sending log file - reopening in append mode: status", nil);
                mode = SWRVE_APPEND_TO_FILE;
                break;
        }

        // close, truncate and re-open the file.
        [swrve setEventStream:[swrve createLogfile:mode]];
    }
}

- (void) sendLogfile
{
    if (![self eventStream]) return;
    if (![self eventFileHasData]) return;

    DebugLog(@"Sending log file %@", [self eventFilename]);

    // Close the write stream and set it to null
    // No more appending will happen while it is null
    [[self eventStream] close];
    [self setEventStream:NULL];

    NSMutableData* contents = [[NSMutableData alloc] initWithContentsOfURL:[self eventFilename]];
    if (contents == nil)
    {
        [self resetEventCache];
        return;
    }

    const NSUInteger length = [contents length];
    if (length <= 2)
    {
        [self resetEventCache];
        return;
    }

    // Remove trailing comma
    [contents setLength:[contents length] - 2];
    NSString* file_contents = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
    NSString* session_token = [self createSessionToken];
    NSString* json_string = [self createJSON:session_token events:file_contents];

    NSData* json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];

    [self sendHttpPOSTRequest:[self batchURL]
                      jsonData:json_data
             completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            DebugLog(@"Error opening HTTP stream", nil);
            return;
        }

        SwrveSendLogfileContext* logfileContext = [[SwrveSendLogfileContext alloc] init];
        [logfileContext setSwrveReference:self];
        [logfileContext setSwrveInstanceID:self->instanceID];

        enum HttpStatus status = HTTP_SUCCESS;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            status = [self getHttpStatus:(NSHTTPURLResponse*)response];
        }
        [self logfileSentCallback:status withData:data andContext:logfileContext];
    }];
}

- (void) resetEventCache
{
    [self setEventStream:[self createLogfile:SWRVE_TRUNCATE_FILE]];
}

- (UInt64) getTime
{
    // Get the time since the epoch in seconds
    struct timeval time;
    gettimeofday(&time, NULL);
    return (((UInt64)time.tv_sec) * 1000) + (((UInt64)time.tv_usec) / 1000);
}

- (BOOL) isValidJson:(NSData*) jsonNSData {
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:jsonNSData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        DebugLog(@"Error with json.\nError:%@", err);
    }
    return obj != nil;
}

- (void) sendHttpGETRequest:(NSURL*)url queryString:(NSString*)query
{
    [self sendHttpGETRequest:url queryString:query completionHandler:nil];
}

- (void) sendHttpGETRequest:(NSURL*)url
{
    [self sendHttpGETRequest:url completionHandler:nil];
}

- (void) sendHttpGETRequest:(NSURL*)baseUrl queryString:(NSString*)query completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    NSURL* url = [NSURL URLWithString:query relativeToURL:baseUrl];
    [self sendHttpGETRequest:url completionHandler:handler];
}

- (void) sendHttpGETRequest:(NSURL*)url completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.config.httpTimeoutSeconds];
    if (handler == nil) {
        [request setHTTPMethod:@"HEAD"];
    } else {
        [request setHTTPMethod:@"GET"];
    }
    [self sendHttpRequest:request completionHandler:handler];
}

- (void) sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json
{
    [self sendHttpPOSTRequest:url jsonData:json completionHandler:nil];
}

- (void) sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:self.config.httpTimeoutSeconds];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:json];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[json length]] forHTTPHeaderField:@"Content-Length"];

    [self sendHttpRequest:request completionHandler:handler];
}

- (void) sendHttpRequest:(NSMutableURLRequest*)request completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    // Add http request performance metrics for any previous requests into the header of this request (see JIRA SWRVE-5067 for more details)
    NSArray* allMetricsToSend;

    @synchronized([self httpPerformanceMetrics]) {
        allMetricsToSend = [[self httpPerformanceMetrics] copy];
        [[self httpPerformanceMetrics] removeAllObjects];
    }

    if (allMetricsToSend != nil && [allMetricsToSend count] > 0) {
        NSString* fullHeader = [allMetricsToSend componentsJoinedByString:@";"];
        [request addValue:fullHeader forHTTPHeaderField:@"Swrve-Latency-Metrics"];
    }

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            handler(response, data, error);
        }];
        [task resume];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        SwrveConnectionDelegate* connectionDelegate = [[SwrveConnectionDelegate alloc] init:self completionHandler:handler];
        [NSURLConnection connectionWithRequest:request delegate:connectionDelegate];
#pragma clang diagnostic pop
    }
}

- (void) addHttpPerformanceMetrics:(NSString*) metrics
{
    @synchronized([self httpPerformanceMetrics]) {
        [[self httpPerformanceMetrics] addObject:metrics];
    }
}

- (void) initBuffer
{
    [self setEventBuffer:[[NSMutableArray alloc] initWithCapacity:SWRVE_MEMORY_QUEUE_INITIAL_SIZE]];
    [self setEventBufferBytes:0];
}

- (NSString*) createStringWithMD5:(NSString*)source
{
#define C "%02x"
#define CCCC C C C C
#define DIGEST_FORMAT CCCC CCCC CCCC CCCC

    NSString* digestFormat = [NSString stringWithFormat:@"%s", DIGEST_FORMAT];

    NSData* buffer = [source dataUsingEncoding:NSUTF8StringEncoding];

    unsigned char digest[CC_MD5_DIGEST_LENGTH] = {0};
    unsigned int length = (unsigned int)[buffer length];
    CC_MD5_CTX context;
    CC_MD5_Init(&context);
    CC_MD5_Update(&context, [buffer bytes], length);
    CC_MD5_Final(digest, &context);

    NSString* result = [NSString stringWithFormat:digestFormat,
                            digest[ 0], digest[ 1], digest[ 2], digest[ 3],
                            digest[ 4], digest[ 5], digest[ 6], digest[ 7],
                            digest[ 8], digest[ 9], digest[10], digest[11],
                            digest[12], digest[13], digest[14], digest[15]];

    return result;
}

- (NSString*) createSessionToken
{
    // Get the time since the epoch in seconds
    struct timeval time; gettimeofday(&time, NULL);
    const long session_start = time.tv_sec;

    NSString* source = [NSString stringWithFormat:@"%@%ld%@", self.userID, session_start, self.apiKey];

    NSString* digest = [self createStringWithMD5:source];

    // $session_token = "$app_id=$user_id=$session_start=$md5_hash";
    NSString* session_token = [NSString stringWithFormat:@"%ld=%@=%ld=%@",
                                                         self.appID,
                                                         self.userID,
                                                         session_start,
                                                         digest];
    return session_token;
}

- (NSString*) getSignatureKey
{
    return [NSString stringWithFormat:@"%@%llu", self.apiKey, self->install_time];
}

- (void)signatureError:(NSURL*)file
{
    #pragma unused(file)
    DebugLog(@"Signature check failed for file %@", file);
    [self eventInternal:@"Swrve.signature_invalid" payload:nil triggerCallback:true];
}

- (void) initResourcesDiff
{
    // Create signature protected cache file
    NSURL* fileURL = [NSURL fileURLWithPath:self.config.userResourcesDiffCacheFile];
    NSURL* signatureURL = [NSURL fileURLWithPath:self.config.userResourcesDiffCacheSignatureFile];

    [self setResourcesDiffFile:[[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:[self getSignatureKey] signatureErrorListener:self]];
}

-(void) getUserResources:(SwrveUserResourcesCallback)callbackBlock
{
    NSCAssert(callbackBlock, @"getUserResources: callbackBlock must not be nil.", nil);

    NSDictionary* resourcesDict = [[self resourceManager] getResources];
    NSMutableString* jsonString = [[NSMutableString alloc] initWithString:@"["];
    BOOL first = YES;
    for (NSString* resourceName in resourcesDict) {
        if (!first) {
            [jsonString appendString:@","];
        }
        first = NO;

        NSDictionary* resource = [resourcesDict objectForKey:resourceName];
        NSData* resourceData = [NSJSONSerialization dataWithJSONObject:resource options:0 error:nil];
        [jsonString appendString:[[NSString alloc] initWithData:resourceData encoding:NSUTF8StringEncoding]];
    }
    [jsonString appendString:@"]"];

    if (callbackBlock != nil) {
        @try {
            callbackBlock(resourcesDict, jsonString);
        }
        @catch (NSException * e) {
            DebugLog(@"Exception in getUserResources callback. %@", e);
        }
    }
}

-(void) getUserResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock
{
    NSCAssert(callbackBlock, @"getUserResourcesDiff: callbackBlock must not be nil.", nil);

    NSURL* base_content_url = [NSURL URLWithString:self.config.contentServer];
    NSURL* resourcesDiffURL = [NSURL URLWithString:@"api/1/user_resources_diff" relativeToURL:base_content_url];
    NSString* queryString = [NSString stringWithFormat:@"user=%@&api_key=%@&app_version=%@&joined=%llu",
                             self.userID, self.apiKey, self.config.appVersion, self->install_time];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"?%@", queryString] relativeToURL:resourcesDiffURL];

    [self sendHttpGETRequest:url completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        NSData* resourcesDiffCacheContent = [[self resourcesDiffFile] readFromFile];

        if (!error) {
            enum HttpStatus status = HTTP_SUCCESS;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                status = [self getHttpStatus:(NSHTTPURLResponse*)response];
            }

            if (status == SWRVE_SUCCESS) {
                if ([self isValidJson:data]) {
                    resourcesDiffCacheContent = data;
                    [[self resourcesDiffFile] writeToFile:data];
                } else {
                    DebugLog(@"Invalid JSON received for user resources diff", nil);
                }
            }
        }

        // At this point the cached content has been updated with the http response if a valid response was received
        // So we can call the callbackBlock with the cached content
        @try {
            NSArray* resourcesArray = [NSJSONSerialization JSONObjectWithData:resourcesDiffCacheContent options:NSJSONReadingMutableContainers error:nil];

            NSMutableDictionary* oldResourcesDict = [[NSMutableDictionary alloc] init];
            NSMutableDictionary* newResourcesDict = [[NSMutableDictionary alloc] init];

            for (NSDictionary* resourceObj in resourcesArray) {
                NSString* itemName = [resourceObj objectForKey:@"uid"];
                NSDictionary* itemDiff = [resourceObj objectForKey:@"diff"];

                NSMutableDictionary* oldValues = [[NSMutableDictionary alloc] init];
                NSMutableDictionary* newValues = [[NSMutableDictionary alloc] init];

                for (NSString* propertyKey in itemDiff) {
                    NSDictionary* propertyVals = [itemDiff objectForKey:propertyKey];
                    [oldValues setObject:[propertyVals objectForKey:@"old"] forKey:propertyKey];
                    [newValues setObject:[propertyVals objectForKey:@"new"] forKey:propertyKey];
                }

                [oldResourcesDict setObject:oldValues forKey:itemName];
                [newResourcesDict setObject:newValues forKey:itemName];
            }

            NSString* jsonString = [[NSString alloc] initWithData:resourcesDiffCacheContent encoding:NSUTF8StringEncoding];
            callbackBlock(oldResourcesDict, newResourcesDict, jsonString);
        }
        @catch (NSException* e) {
            DebugLog(@"Exception in getUserResourcesDiff callback. %@", e);
        }
    }];
}

// Overwritten for unit tests
- (NSDate*)getNow
{
    return [NSDate date];
}

- (void) generateShortDeviceId {
    // Read old short device id or generate a new short one
    NSString* oldShortDeviceId = [[NSUserDefaults standardUserDefaults] stringForKey:@"swrve_device_id"];
    if (oldShortDeviceId != nil) {
        // Reproduce old behaviour, remove key when finished
        NSUInteger shortDeviceIDInteger = [oldShortDeviceId hash];
        if (shortDeviceIDInteger > 10000) {
            shortDeviceIDInteger = shortDeviceIDInteger / 1000;
        }
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"swrve_device_id"];
        self.shortDeviceID = [NSNumber numberWithInteger:(NSInteger)shortDeviceIDInteger];
        [[NSUserDefaults standardUserDefaults] setObject:self.shortDeviceID forKey:@"short_device_id"];
    } else {
        id shortDeviceIdDisk = [[NSUserDefaults standardUserDefaults] objectForKey:@"short_device_id"];
        if (shortDeviceIdDisk == nil || ![shortDeviceIdDisk isKindOfClass:[NSNumber class]]) {
            // This is the first time we see this device, assign a UUID to it
            NSUInteger deviceUUID = [[[NSUUID UUID] UUIDString] hash];
            unsigned short newShortDeviceID = (unsigned short)deviceUUID;
            self.shortDeviceID = [NSNumber numberWithUnsignedShort:newShortDeviceID];
            [[NSUserDefaults standardUserDefaults] setObject:self.shortDeviceID forKey:@"short_device_id"];
        } else {
            self.shortDeviceID = shortDeviceIdDisk;
        }
    }
}

@end

// This connection delegate tracks performance metrics for each request (see JIRA SWRVE-5067 for more details)
@implementation SwrveConnectionDelegate

@synthesize swrve;

- (id)init:(Swrve*)_swrve completionHandler:(ConnectionCompletionHandler)_handler
{
    self = [super init:_handler];
    if (self) {
        [self setSwrve:_swrve];
    }
    return self;
}

- (void)addHttpPerformanceMetrics:(NSString *)metricsString
{
    Swrve* swrveStrong = self.swrve;
    if (swrveStrong) {
        [swrveStrong addHttpPerformanceMetrics:metricsString];
    }
}

@end
