//
//  SentryClient.m
//  Sentry
//
//  Created by Daniel Griesser on 02/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryClient.h>
#import <Sentry/SentryClient+Internal.h>
#import <Sentry/SentryLog.h>
#import <Sentry/SentryDsn.h>
#import <Sentry/SentryError.h>
#import <Sentry/SentryUser.h>
#import <Sentry/SentryQueueableRequestManager.h>
#import <Sentry/SentryEvent.h>
#import <Sentry/SentryNSURLRequest.h>
#import <Sentry/SentryInstallation.h>
#import <Sentry/SentryBreadcrumbStore.h>
#import <Sentry/SentryFileManager.h>
#import <Sentry/SentryBreadcrumbTracker.h>
#import <Sentry/SentryCrash.h>
#import <Sentry/SentryOptions.h>
#else
#import "SentryClient.h"
#import "SentryClient+Internal.h"
#import "SentryLog.h"
#import "SentryDsn.h"
#import "SentryError.h"
#import "SentryUser.h"
#import "SentryQueueableRequestManager.h"
#import "SentryEvent.h"
#import "SentryNSURLRequest.h"
#import "SentryInstallation.h"
#import "SentryBreadcrumbStore.h"
#import "SentryFileManager.h"
#import "SentryBreadcrumbTracker.h"
#import "SentryCrash.h"
#import "SentryOptions.h"
#endif

#if SENTRY_HAS_UIKIT
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

NSString *const SentryClientVersionString = @"4.4.3";
NSString *const SentryClientSdkName = @"sentry-cocoa";

static SentryClient *sharedClient = nil;
static SentryLogLevel logLevel = kSentryLogLevelError;

static SentryInstallation *installation = nil;

@interface SentryClient ()

@property(nonatomic, strong) SentryDsn *dsn;
@property(nonatomic, strong) SentryFileManager *fileManager;
@property(nonatomic, strong) id <SentryRequestManager> requestManager;

@end

@implementation SentryClient

@synthesize environment = _environment;
@synthesize releaseName = _releaseName;
@synthesize dist = _dist;
@synthesize tags = _tags;
@synthesize extra = _extra;
@synthesize user = _user;
@synthesize sampleRate = _sampleRate;
@synthesize maxEvents = _maxEvents;
@synthesize maxBreadcrumbs = _maxBreadcrumbs;
@dynamic logLevel;

#pragma mark Initializer

- (_Nullable instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options
                         didFailWithError:(NSError *_Nullable *_Nullable)error {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    return [self initWithOptions:options
                  requestManager:[[SentryQueueableRequestManager alloc] initWithSession:session]
                didFailWithError:error];
}
    
    
- (_Nullable instancetype)initWithDsn:(NSString *)dsn
                     didFailWithError:(NSError *_Nullable *_Nullable)error {
    return [self initWithOptions:@{@"dsn": dsn}
                didFailWithError:error];
}

- (_Nullable instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options
                           requestManager:(id <SentryRequestManager>)requestManager
                         didFailWithError:(NSError *_Nullable *_Nullable)error {
    self = [super init];
    if (self) {
        [self restoreContextBeforeCrash];
        [self setupQueueing];
        _extra = [NSDictionary new];
        _tags = [NSDictionary new];
        
        SentryOptions *sentryOptions = [[SentryOptions alloc] initWithOptions:options didFailWithError:error];
        if (nil != error && nil != *error) {
            [SentryLog logWithMessage:(*error).localizedDescription andLevel:kSentryLogLevelError];
            return nil;
        }
        
        if (nil == sentryOptions.enabled) {
            self.enabled = @YES;
        } else {
            self.enabled = sentryOptions.enabled;
        }
        self.dsn = sentryOptions.dsn;
        self.environment = sentryOptions.environment;
        self.releaseName = sentryOptions.releaseName;
        self.dist = sentryOptions.dist;
        
        self.requestManager = requestManager;
        if (logLevel > 1) { // If loglevel is set > None
            NSLog(@"Sentry Started -- Version: %@", self.class.versionString);
        }
        self.fileManager = [[SentryFileManager alloc] initWithDsn:self.dsn didFailWithError:error];
        self.breadcrumbs = [[SentryBreadcrumbStore alloc] initWithFileManager:self.fileManager];
        if (nil != error && nil != *error) {
            [SentryLog logWithMessage:(*error).localizedDescription andLevel:kSentryLogLevelError];
            return nil;
        }
        
        // We want to send all stored events on start up
        if ([self.enabled boolValue] && [self.requestManager isReady]) {
            [self sendAllStoredEvents];
        }
    }
    return self;
}

- (void)setupQueueing {
    self.shouldQueueEvent = ^BOOL(SentryEvent *_Nonnull event, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        // Taken from Apple Docs:
        // If a response from the server is received, regardless of whether the request completes successfully or fails,
        // the response parameter contains that information.
        if (response == nil) {
            // In case response is nil, we want to queue the event locally since this
            // indicates no internet connection
            return YES;
        } else if ([response statusCode] == 429) {
            [SentryLog logWithMessage:@"Rate limit reached, event will be stored and sent later" andLevel:kSentryLogLevelError];
            return YES;
        }
        // In all other cases we don't want to retry sending it and just discard the event
        return NO;
    };
}

- (void)enableAutomaticBreadcrumbTracking {
    [[SentryBreadcrumbTracker alloc] start];
}

- (void)trackMemoryPressureAsEvent {
    #if SENTRY_HAS_UIKIT
    __weak SentryClient *weakSelf = self;
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityWarning];
    event.message = @"Memory Warning";
    [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification *notification) {
                                                    [weakSelf storeEvent:event];
                                                }];
    #endif
}

#pragma mark Static Getter/Setter

+ (_Nullable instancetype)sharedClient {
    return sharedClient;
}

+ (void)setSharedClient:(SentryClient *_Nullable)client {
    sharedClient = client;
}

+ (NSString *)versionString {
    return SentryClientVersionString;
}

+ (NSString *)sdkName {
    return SentryClientSdkName;
}

+ (void)setLogLevel:(SentryLogLevel)level {
    NSParameterAssert(level);
    logLevel = level;
}

+ (SentryLogLevel)logLevel {
    return logLevel;
}

#pragma mark Event

- (void)sendEvent:(SentryEvent *)event withCompletionHandler:(_Nullable SentryRequestFinished)completionHandler {
    [self sendEvent:event useClientProperties:YES withCompletionHandler:completionHandler];
}

- (void)prepareEvent:(SentryEvent *)event
 useClientProperties:(BOOL)useClientProperties {
    NSParameterAssert(event);
    if (useClientProperties) {
        [self setSharedPropertiesOnEvent:event];
    }

    if (nil != self.beforeSerializeEvent) {
        self.beforeSerializeEvent(event);
    }
}

- (void)storeEvent:(SentryEvent *)event {
    [self prepareEvent:event useClientProperties:YES];
    [self.fileManager storeEvent:event];
}

- (void)    sendEvent:(SentryEvent *)event
  useClientProperties:(BOOL)useClientProperties
withCompletionHandler:(_Nullable SentryRequestFinished)completionHandler {
    [self prepareEvent:event useClientProperties:useClientProperties];

    if (nil != self.shouldSendEvent && !self.shouldSendEvent(event)) {
        NSString *message = @"SentryClient shouldSendEvent returned NO so we will not send the event";
        [SentryLog logWithMessage:message andLevel:kSentryLogLevelDebug];
        if (completionHandler) {
            completionHandler(NSErrorFromSentryError(kSentryErrorEventNotSent, message));
        }
        return;
    }

    NSError *requestError = nil;
    SentryNSURLRequest *request = [[SentryNSURLRequest alloc] initStoreRequestWithDsn:self.dsn
                                                                             andEvent:event
                                                                     didFailWithError:&requestError];
    if (nil != requestError) {
        [SentryLog logWithMessage:requestError.localizedDescription andLevel:kSentryLogLevelError];
        if (completionHandler) {
            completionHandler(requestError);
        }
        return;
    }

    NSString *storedEventPath = [self.fileManager storeEvent:event];
    
    if (![self.enabled boolValue]) {
        [SentryLog logWithMessage:@"SentryClient is disabled, event will be stored to send later." andLevel:kSentryLogLevelDebug];
        return;
    }
    
    __block SentryClient *_self = self;
    [self sendRequest:request withCompletionHandler:^(NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        // We check if we should leave the event locally stored and try to send it again later
        if (self.shouldQueueEvent == nil || self.shouldQueueEvent(event, response, error) == NO) {
            [_self.fileManager removeFileAtPath:storedEventPath];
        }
        if (nil == error) {
            _self.lastEvent = event;
            [NSNotificationCenter.defaultCenter postNotificationName:@"Sentry/eventSentSuccessfully"
                                                              object:nil
                                                            userInfo:[event serialize]];
            // Send all stored events in background if the queue is ready
            if ([_self.enabled boolValue] && [_self.requestManager isReady]) {
                [_self sendAllStoredEvents];
            }
        }
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)  sendRequest:(SentryNSURLRequest *)request
withCompletionHandler:(_Nullable SentryRequestOperationFinished)completionHandler {
    if (nil != self.beforeSendRequest) {
        self.beforeSendRequest(request);
    }
    [self.requestManager addRequest:request completionHandler:completionHandler];
}

- (void)sendAllStoredEvents {
    dispatch_group_t dispatchGroup = dispatch_group_create();

    for (NSDictionary<NSString *, id> *fileDictionary in [self.fileManager getAllStoredEvents]) {
        dispatch_group_enter(dispatchGroup);

        SentryNSURLRequest *request = [[SentryNSURLRequest alloc] initStoreRequestWithDsn:self.dsn
                                                                                  andData:fileDictionary[@"data"]
                                                                         didFailWithError:nil];
        [self sendRequest:request withCompletionHandler:^(NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
            if (nil == error) {
                NSDictionary *serializedEvent = [NSJSONSerialization JSONObjectWithData:fileDictionary[@"data"]
                                                                                options:0
                                                                                  error:nil];
                if (nil != serializedEvent) {
                    [NSNotificationCenter.defaultCenter postNotificationName:@"Sentry/eventSentSuccessfully"
                                                                      object:nil
                                                                    userInfo:serializedEvent];
                }
            }
            // We want to delete the event here no matter what (if we had an internet connection)
            // since it has been tried already
            if (response != nil) {
                [self.fileManager removeFileAtPath:fileDictionary[@"path"]];
            }

            dispatch_group_leave(dispatchGroup);
        }];
    }

    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:@"Sentry/allStoredEventsSent"
                                                          object:nil
                                                        userInfo:nil];
    });
}

- (void)setSharedPropertiesOnEvent:(SentryEvent *)event {
    if (nil != self.tags) {
        if (nil == event.tags) {
            event.tags = self.tags;
        } else {
            NSMutableDictionary *newTags = [NSMutableDictionary new];
            [newTags addEntriesFromDictionary:self.tags];
            [newTags addEntriesFromDictionary:event.tags];
            event.tags = newTags;
        }
    }

    if (nil != self.extra) {
        if (nil == event.extra) {
            event.extra = self.extra;
        } else {
            NSMutableDictionary *newExtra = [NSMutableDictionary new];
            [newExtra addEntriesFromDictionary:self.extra];
            [newExtra addEntriesFromDictionary:event.extra];
            event.extra = newExtra;
        }
    }

    if (nil != self.user && nil == event.user) {
        event.user = self.user;
    }

    if (nil == event.breadcrumbsSerialized) {
        event.breadcrumbsSerialized = [self.breadcrumbs serialize];
    }

    if (nil == event.infoDict) {
        event.infoDict = [[NSBundle mainBundle] infoDictionary];
    }
    
    if (nil != self.environment && nil == event.environment) {
        event.environment = self.environment;
    }
    
    if (nil != self.releaseName && nil == event.releaseName) {
        event.releaseName = self.releaseName;
    }
    
    if (nil != self.dist && nil == event.dist) {
        event.dist = self.dist;
    }
}

- (void)appendStacktraceToEvent:(SentryEvent *)event {
    if (nil != self._snapshotThreads && nil != self._debugMeta) {
        event.threads = self._snapshotThreads;
        event.debugMeta = self._debugMeta;
    }
}

#pragma mark Global properties

- (void)setTags:(NSDictionary<NSString *, NSString *> *_Nullable)tags {
    [[NSUserDefaults standardUserDefaults] setObject:tags forKey:@"sentry.io.tags"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _tags = tags;
}

- (void)setExtra:(NSDictionary<NSString *, id> *_Nullable)extra {
    [[NSUserDefaults standardUserDefaults] setObject:extra forKey:@"sentry.io.extra"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _extra = extra;
}

- (void)setUser:(SentryUser *_Nullable)user {
    [[NSUserDefaults standardUserDefaults] setObject:[user serialize] forKey:@"sentry.io.user"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _user = user;
}
    
- (void)setReleaseName:(NSString *_Nullable)releaseName {
    [[NSUserDefaults standardUserDefaults] setObject:releaseName forKey:@"sentry.io.releaseName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _releaseName = releaseName;
}
    
- (void)setDist:(NSString *_Nullable)dist {
    [[NSUserDefaults standardUserDefaults] setObject:dist forKey:@"sentry.io.dist"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _dist = dist;
}
    
- (void)setEnvironment:(NSString *_Nullable)environment {
    [[NSUserDefaults standardUserDefaults] setObject:environment forKey:@"sentry.io.environment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _environment = environment;
}

- (void)clearContext {
    [self setReleaseName:nil];
    [self setDist:nil];
    [self setEnvironment:nil];
    [self setUser:nil];
    [self setExtra:[NSDictionary new]];
    [self setTags:[NSDictionary new]];
}

- (void)restoreContextBeforeCrash {
    NSMutableDictionary *context = [[NSMutableDictionary alloc] init];
    [context setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"sentry.io.tags"] forKey:@"tags"];
    [context setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"sentry.io.extra"] forKey:@"extra"];
    [context setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"sentry.io.user"] forKey:@"user"];
    [context setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"sentry.io.releaseName"] forKey:@"releaseName"];
    [context setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"sentry.io.dist"] forKey:@"dist"];
    [context setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"sentry.io.environment"] forKey:@"environment"];
    self.lastContext = context;
}

- (void)setSampleRate:(float)sampleRate {
    if (sampleRate < 0 || sampleRate > 1) {
        [SentryLog logWithMessage:@"sampleRate must be between 0.0 and 1.0" andLevel:kSentryLogLevelError];
        return;
    }
    _sampleRate = sampleRate;
    self.shouldSendEvent = ^BOOL(SentryEvent *_Nonnull event) {
        return (sampleRate >= ((double)arc4random() / 0x100000000));
    };
}

- (void)setMaxEvents:(NSUInteger)maxEvents {
    self.fileManager.maxEvents = maxEvents;
}

- (void)setMaxBreadcrumbs:(NSUInteger)maxBreadcrumbs {
    self.fileManager.maxBreadcrumbs = maxBreadcrumbs;
}

#pragma mark SentryCrash

- (BOOL)crashedLastLaunch {
    return SentryCrash.sharedInstance.crashedLastLaunch;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
- (BOOL)startCrashHandlerWithError:(NSError *_Nullable *_Nullable)error {
    [SentryLog logWithMessage:@"SentryCrashHandler started" andLevel:kSentryLogLevelDebug];
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        installation = [[SentryInstallation alloc] init];
        [installation install];
        [installation sendAllReports];
    });
    return YES;
}
#pragma GCC diagnostic pop

- (void)crash {
    int* p = 0;
    *p = 0;
}

- (void)reportUserException:(NSString *)name
                     reason:(NSString *)reason
                   language:(NSString *)language
                 lineOfCode:(NSString *)lineOfCode
                 stackTrace:(NSArray *)stackTrace
              logAllThreads:(BOOL)logAllThreads
           terminateProgram:(BOOL)terminateProgram {
    if (nil == installation) {
        [SentryLog logWithMessage:@"SentryCrash has not been initialized, call startCrashHandlerWithError" andLevel:kSentryLogLevelError];
        return;
    }
    [SentryCrash.sharedInstance reportUserException:name
                                         reason:reason
                                       language:language
                                     lineOfCode:lineOfCode
                                     stackTrace:stackTrace
                                  logAllThreads:logAllThreads
                               terminateProgram:terminateProgram];
    [installation sendAllReports];
}

- (void)snapshotStacktrace:(void (^)(void))snapshotCompleted {
    if (nil == installation) {
        [SentryLog logWithMessage:@"SentryCrash has not been initialized, call startCrashHandlerWithError" andLevel:kSentryLogLevelError];
        return;
    }
    [SentryCrash.sharedInstance reportUserException:@"SENTRY_SNAPSHOT"
                                         reason:@"SENTRY_SNAPSHOT"
                                       language:@""
                                     lineOfCode:@""
                                     stackTrace:[[NSArray alloc] init]
                                  logAllThreads:NO
                               terminateProgram:NO];
    [installation sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        snapshotCompleted();
    }];
}

@end

NS_ASSUME_NONNULL_END
