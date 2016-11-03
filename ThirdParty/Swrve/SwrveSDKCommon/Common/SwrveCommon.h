#import <UIKit/UIKit.h>

/*! Swrve SDK shared protocol (interface) definition */
@protocol SwrveCommonDelegate <NSObject>

@required
-(NSData*) getCampaignData:(int)category;
-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback;
-(int) userUpdate:(NSDictionary*)attributes;
-(BOOL) processPermissionRequest:(NSString*)action;
- (void) sendQueuedEvents;
- (void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback;

-(NSString*) swrveSDKVersion;
-(NSString*) appVersion;
-(NSSet*) pushCategories;

@property(atomic, readonly) long appID;
@property(atomic, readonly) NSString *userID;
@property(atomic, readonly) NSDictionary *deviceInfo;
@property (atomic, readonly) NSString* deviceToken;

@end

@interface SwrveCommon : NSObject

+(id<SwrveCommonDelegate>) sharedInstance;
+(void) addSharedInstance:(id<SwrveCommonDelegate>)swrveCommon;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"

#ifndef SWRVE_DISABLE_LOGS
#define DebugLog( s, ... ) NSLog(s, ##__VA_ARGS__)
#else
#define DebugLog( s, ... )
#endif

#pragma clang diagnostic pop

#define NullableNSString(x) ((x == nil)? [NSNull null] : x)

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

/*! Result codes for Swrve methods. */
enum
{
    SWRVE_SUCCESS = 0,  /*!< Method executed successfully. */
    SWRVE_FAILURE = -1  /*!< Method did not execute successfully. */
};

enum
{
    SWRVE_CAMPAIGN_LOCATION = 0
};

#define KB(x) (1024*(x))
#define MB(x) (1024*KB((x)))

enum
{
    // The API version of this file.
    // This is sent to the server on each call, and should not be modified.
    SWRVE_VERSION = 2,
    
    // Initial size of the in-memory queue
    // Tweak this to avoid fragmenting memory when the queue is growing.
    SWRVE_MEMORY_QUEUE_INITIAL_SIZE = 16,
    
    // This is the largest number of bytes that the in-memory queue will use
    // If more than this number of bytes are used, the entire queue will be written
    // to disk, and the queue will be emptied.
    SWRVE_MEMORY_QUEUE_MAX_BYTES = KB(100),
    
    // This is the largest size that the disk-cache persists between runs of the
    // application. The file may grow larger than this size over a very long run
    // of the app, but then next time the app is run, the file will be truncated.
    // To avoid losing data, you should allow enough disk space here for your app's
    // messages.
    SWRVE_DISK_MAX_BYTES = MB(4),
    
    // Flush frequency for automatic campaign/user resources updates
    SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_FREQUENCY = 60000,
    
    // Delay between flushing events and refreshing campaign/user resources
    SWRVE_DEFAULT_CAMPAIGN_RESOURCES_FLUSH_REFRESH_DELAY = 5000,
};

//
//#ifndef DEBUG
//
//#define DEBUG
//
//#endif
