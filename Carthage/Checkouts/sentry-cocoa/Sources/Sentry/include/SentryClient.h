//
//  SentryClient.h
//  Sentry
//
//  Created by Daniel Griesser on 02/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryDefines.h>

#else
#import "SentryDefines.h"
#endif

@class SentryEvent, SentryBreadcrumbStore, SentryUser, SentryThread;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Client)
@interface SentryClient : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 * Return a version string e.g: 1.2.3 (3)
 */
@property(nonatomic, class, readonly, copy) NSString *versionString;

/**
 * Return a string sentry-cocoa
 */
@property(nonatomic, class, readonly, copy) NSString *sdkName;

/**
 * Set logLevel for the current client default kSentryLogLevelError
 */
@property(nonatomic, class) SentryLogLevel logLevel;

/**
 * Set global user -> thus will be sent with every event
 */
@property(nonatomic, strong) SentryUser *_Nullable user;

/**
 * Set global tags -> these will be sent with every event
 */
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *_Nullable tags;

/**
 * Set global extra -> these will be sent with every event
 */
@property(nonatomic, strong) NSDictionary<NSString *, id> *_Nullable extra;

/**
 * This property will be filled before the event is sent.
 */
@property(nonatomic, copy) NSString *_Nullable releaseName;

/**
 * This property will be filled before the event is sent.
 */
@property(nonatomic, copy) NSString *_Nullable dist;

/**
 * The environment used for this event
 */
@property(nonatomic, copy) NSString *_Nullable environment;
    
/**
 * This will be filled on every startup with a dictionary with extra, tags, user which will be used
 * when sending the crashreport
 */
@property(nonatomic, strong) NSDictionary<NSString *, id> *_Nullable lastContext;

/**
 * Contains the last successfully sent event
 */
@property(nonatomic, strong) SentryEvent *_Nullable lastEvent;

/**
 * Contains the breadcrumbs which will be sent with the event
 */
@property(nonatomic, strong) SentryBreadcrumbStore *breadcrumbs;
    
/**
 * Is the client enabled?. Default is @YES, if set @NO sending of events will be prevented.
 */
@property(nonatomic, copy) NSNumber *enabled;

/**
 * This block can be used to modify the event before it will be serialized and sent
 */
@property(nonatomic, copy) SentryBeforeSerializeEvent _Nullable beforeSerializeEvent;

/**
 * This block can be used to modify the request before its put on the request queue.
 * Can be used e.g. to set additional http headers before sending
 */
@property(nonatomic, copy) SentryBeforeSendRequest _Nullable beforeSendRequest;

/**
 * This block can be used to prevent the event from being sent.
 * @return BOOL
 */
@property(nonatomic, copy) SentryShouldSendEvent _Nullable shouldSendEvent;

/**
 * Returns the shared sentry client
 * @return sharedClient if it was set before
 */
@property(nonatomic, class) SentryClient *_Nullable sharedClient;

/**
 * Defines the sample rate of SentryClient, should be a float between 0.0 and 1.0
 * Setting this property sets shouldSendEvent callback and applies a random event sampler.
 */
@property(nonatomic) float sampleRate;

/**
 * This block can be used to prevent the event from being deleted after a failed send attempt.
 * Default is it will only be stored once after you hit a rate limit or there is no internet connect/cannot connect.
 * Also note that if an event fails to be sent again after it was queued, it will be discarded regardless.
 * @return BOOL YES = store and try again later, NO = delete
 */
@property(nonatomic, copy) SentryShouldQueueEvent _Nullable shouldQueueEvent;

/**
 * Increase the max number of events we store offline.
 * Be careful with this setting since too high numbers may cause your quota to exceed.
 */
@property(nonatomic, assign) NSUInteger maxEvents;
/**
 * Increase the max number of breadcrumbs we store offline.
 */
@property(nonatomic, assign) NSUInteger maxBreadcrumbs;

/**
 * Initializes a SentryClient. Pass your private DSN string.
 *
 * @param dsn DSN string of sentry
 * @param error NSError reference object
 * @return SentryClient
 */
- (_Nullable instancetype)initWithDsn:(NSString *)dsn
                     didFailWithError:(NSError *_Nullable *_Nullable)error;
    
/**
 * Initializes a SentryClient. Pass in an dictionary of options.
 *
 * @param options Options dictionary
 * @param error NSError reference object
 * @return SentryClient
 */
- (_Nullable instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options
                         didFailWithError:(NSError *_Nullable *_Nullable)error;

/**
 * This automatically adds breadcrumbs for different user actions.
 */
- (void)enableAutomaticBreadcrumbTracking;

/**
 * Track memory pressure notifcation on UIApplications and send an event for it to Sentry.
 */
- (void)trackMemoryPressureAsEvent;

/**
 * Sends and event to sentry. Internally calls @selector(sendEvent:useClientProperties:withCompletionHandler:) with
 * useClientProperties: YES. CompletionHandler will be called if set.
 * @param event SentryEvent that should be sent
 * @param completionHandler SentryRequestFinished
 */
- (void)sendEvent:(SentryEvent *)event withCompletionHandler:(_Nullable SentryRequestFinished)completionHandler
NS_SWIFT_NAME(send(event:completion:));

/**
 * This function stores an event to disk. It will be sent with the next batch.
 * This function is mainly used for react native.
 * @param event SentryEvent that should be sent
 */
- (void)storeEvent:(SentryEvent *)event;

/**
 * Clears all context related variables: tags, extra and user
 */
- (void)clearContext;

/// SentryCrash
/// Functions below will only do something if SentryCrash is linked

/**
 * This forces a crash, useful to test the SentryCrash integration
 *
 */
- (void)crash;

/**
 * This function tries to start the SentryCrash handler, return YES if successfully started
 * otherwise it will return false and set error
 *
 * @param error if SentryCrash is not available error will be set
 * @return successful
 */
- (BOOL)startCrashHandlerWithError:(NSError *_Nullable *_Nullable)error;

/**
 * Report a custom, user defined exception. Only works if SentryCrash is linked.
 * This can be useful when dealing with scripting languages.
 *
 * If terminateProgram is true, all sentries will be uninstalled and the application will
 * terminate with an abort().
 *
 * @param name The exception name (for namespacing exception types).
 * @param reason A description of why the exception occurred.
 * @param language A unique language identifier.
 * @param lineOfCode A copy of the offending line of code (nil = ignore).
 * @param stackTrace An array of frames (dictionaries or strings) representing the call stack leading to the exception (nil = ignore).
 * @param logAllThreads If YES, suspend all threads and log their state. Note that this incurs a
 *                      performance penalty, so it's best to use only on fatal errors.
 * @param terminateProgram If YES, do not return from this function call. Terminate the program instead.
 */
- (void)reportUserException:(NSString *)name
                     reason:(NSString *)reason
                   language:(NSString *)language
                 lineOfCode:(NSString *)lineOfCode
                 stackTrace:(NSArray *)stackTrace
              logAllThreads:(BOOL)logAllThreads
           terminateProgram:(BOOL)terminateProgram;

/**
 * Returns true if the app crashed before launching now
 */
- (BOOL)crashedLastLaunch;

/**
 * This will snapshot the whole stacktrace at the time when its called. This stacktrace will be attached with the next sent event.
 * Please note to also call appendStacktraceToEvent in the callback in order to send the stacktrace with the event.
 */
- (void)snapshotStacktrace:(void (^)(void))snapshotCompleted;

/**
 * This appends the stored stacktrace (if existant) to the event.
 *
 * @param event SentryEvent event
 */
- (void)appendStacktraceToEvent:(SentryEvent *)event;

@end

NS_ASSUME_NONNULL_END
