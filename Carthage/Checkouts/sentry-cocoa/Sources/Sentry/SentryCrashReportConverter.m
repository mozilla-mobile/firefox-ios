//
//  SentryCrashReportConverter.m
//  Sentry
//
//  Created by Daniel Griesser on 10/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryCrashReportConverter.h>
#import <Sentry/SentryEvent.h>
#import <Sentry/SentryDebugMeta.h>
#import <Sentry/SentryThread.h>
#import <Sentry/SentryStacktrace.h>
#import <Sentry/SentryFrame.h>
#import <Sentry/SentryException.h>
#import <Sentry/SentryContext.h>
#import <Sentry/SentryUser.h>
#import <Sentry/SentryMechanism.h>
#import <Sentry/NSDate+SentryExtras.h>

#else
#import "SentryCrashReportConverter.h"
#import "SentryEvent.h"
#import "SentryDebugMeta.h"
#import "SentryThread.h"
#import "SentryStacktrace.h"
#import "SentryFrame.h"
#import "SentryException.h"
#import "SentryContext.h"
#import "SentryUser.h"
#import "SentryMechanism.h"
#import "NSDate+SentryExtras.h"
#endif

@interface SentryCrashReportConverter ()

@property(nonatomic, strong) NSDictionary *report;
@property(nonatomic, assign) NSInteger crashedThreadIndex;
@property(nonatomic, strong) NSDictionary *exceptionContext;
@property(nonatomic, strong) NSArray *binaryImages;
@property(nonatomic, strong) NSArray *threads;
@property(nonatomic, strong) NSDictionary *systemContext;
@property(nonatomic, strong) NSString *diagnosis;

@end

@implementation SentryCrashReportConverter

static inline NSString *hexAddress(NSNumber *value) {
    return [NSString stringWithFormat:@"0x%016llx", [value unsignedLongLongValue]];
}

- (instancetype)initWithReport:(NSDictionary *)report {
    self = [super init];
    if (self) {
        self.report = report;
        self.binaryImages = report[@"binary_images"];
        self.systemContext = report[@"system"];

        NSDictionary *crashContext;
        // This is an incomplete crash report
        if (nil != report[@"recrash_report"][@"crash"]) {
            crashContext = report[@"recrash_report"][@"crash"];
        } else {
            crashContext = report[@"crash"];
        }

        self.diagnosis = crashContext[@"diagnosis"];
        self.exceptionContext = crashContext[@"error"];
        self.threads = crashContext[@"threads"];
        for (NSUInteger i = 0; i < self.threads.count; i++) {
            NSDictionary *thread = self.threads[i];
            if ([thread[@"crashed"] boolValue]) {
                self.crashedThreadIndex = (NSInteger) i;
                break;
            }
        }
    }
    return self;
}

- (SentryEvent *)convertReportToEvent {
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentrySeverityFatal];
    if ([self.report[@"report"][@"timestamp"] isKindOfClass:NSNumber.class]) {
        event.timestamp = [NSDate dateWithTimeIntervalSince1970:[self.report[@"report"][@"timestamp"] integerValue]];
    } else {
        event.timestamp = [NSDate sentry_fromIso8601String:self.report[@"report"][@"timestamp"]];
    }
    event.debugMeta = [self convertDebugMeta];
    event.threads = [self convertThreads];
    event.exceptions = [self convertExceptions];
    event.context = [self convertContext];
    
    event.releaseName = self.userContext[@"releaseName"];
    event.dist = self.userContext[@"dist"];
    event.environment = self.userContext[@"environment"];
    
    // We want to set the release and dist to the version from the crash report itself
    // otherwise it can happend that we have two different version when the app crashes
    // right before an app update #218 #219
    if (nil == event.releaseName && event.context.appContext[@"app_identifier"] && event.context.appContext[@"app_version"]) {
        event.releaseName = [NSString stringWithFormat:@"%@-%@", event.context.appContext[@"app_identifier"], event.context.appContext[@"app_version"]];
    }
    if (nil == event.dist && event.context.appContext[@"app_build"]) {
        event.dist = event.context.appContext[@"app_build"];
    }
    event.extra = [self convertExtra];
    event.tags = [self convertTags];
    event.user = [self convertUser];
    return event;
}

- (NSDictionary<NSString *, id <NSSecureCoding>> *_Nullable)convertExtra {
    return self.userContext[@"extra"];
}

- (NSDictionary<NSString *, NSString *> *_Nullable)convertTags {
    return self.userContext[@"tags"];
}

- (SentryUser *_Nullable)convertUser {
    SentryUser *user = nil;
    if (nil != self.userContext[@"user"]) {
        user = [[SentryUser alloc] init];
        user.userId = self.userContext[@"user"][@"id"];
        user.email = self.userContext[@"user"][@"email"];
        user.username = self.userContext[@"user"][@"username"];
        user.extra = self.userContext[@"user"][@"extra"];
    }
    return user;
}

- (SentryContext *)convertContext {
    SentryContext *context = [[SentryContext alloc] init];

    [self addOsContext:context];
    [self addDeviceContext:context];
    [self addAppContext:context];

    return context;
}

- (void)addAppContext:(SentryContext *)context {
    NSMutableDictionary *appContext = [NSMutableDictionary new];
    [appContext setValue:self.systemContext[@"app_start_time"] forKey:@"app_start_time"];
    [appContext setValue:self.systemContext[@"device_app_hash"] forKey:@"device_app_hash"];
    [appContext setValue:self.systemContext[@"CFBundleIdentifier"] forKey:@"app_identifier"];
    [appContext setValue:self.systemContext[@"CFBundleName"] forKey:@"app_name"];
    [appContext setValue:self.systemContext[@"CFBundleVersion"] forKey:@"app_build"];
    [appContext setValue:self.systemContext[@"CFBundleShortVersionString"] forKey:@"app_version"];
    [appContext setValue:self.systemContext[@"CFBundleExecutablePath"] forKey:@"executable_path"];
    [appContext setValue:self.systemContext[@"build_type"] forKey:@"build_type"];
    context.appContext = appContext;
}

- (void)addDeviceContext:(SentryContext *)context {
    NSMutableDictionary *deviceContext = [NSMutableDictionary new];
    [deviceContext setValue:self.family forKey:@"family"];
    [deviceContext setValue:self.systemContext[@"cpu_arch"] forKey:@"arch"];
    [deviceContext setValue:self.systemContext[@"boot_time"] forKey:@"boot_time"];
    [deviceContext setValue:self.systemContext[@"timezone"] forKey:@"time_zone"];
    [deviceContext setValue:self.systemContext[@"memory"][@"size"] forKey:@"memory_size"];
    [deviceContext setValue:self.systemContext[@"memory"][@"usable"] forKey:@"usable_memory"];
    [deviceContext setValue:self.systemContext[@"memory"][@"free"] forKey:@"free_memory"];
    [deviceContext setValue:self.systemContext[@"storage"] forKey:@"storage_size"];
    [deviceContext setValue:self.systemContext[@"machine"] forKey:@"model"];
    [deviceContext setValue:self.systemContext[@"model"] forKey:@"model_id"];
    context.deviceContext = deviceContext;
}

- (void)addOsContext:(SentryContext *)context {
    NSMutableDictionary *osContext = [NSMutableDictionary new];
    [osContext setValue:self.systemContext[@"system_name"] forKey:@"name"];
    [osContext setValue:self.systemContext[@"system_version"] forKey:@"version"];
    [osContext setValue:self.systemContext[@"os_version"] forKey:@"build"];
    [osContext setValue:self.systemContext[@"kernel_version"] forKey:@"kernel_version"];
    [osContext setValue:self.systemContext[@"jailbroken"] forKey:@"rooted"];
    context.osContext = osContext;
}

- (NSString *)family {
    NSString *systemName = self.systemContext[@"system_name"];
    NSArray *components = [systemName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return components[0];
}

- (NSArray *)rawStackTraceForThreadIndex:(NSInteger)threadIndex {
    NSDictionary *thread = [self.threads objectAtIndex:threadIndex];
    return thread[@"backtrace"][@"contents"];
}

- (NSDictionary *)registersForThreadIndex:(NSInteger)threadIndex {
    NSDictionary *thread = [self.threads objectAtIndex:threadIndex];
    NSMutableDictionary *registers = [NSMutableDictionary new];
    for (NSString *key in [thread[@"registers"][@"basic"] allKeys]) {
        [registers setValue:hexAddress(thread[@"registers"][@"basic"][key]) forKey:key];
    }
    return registers;
}

- (NSDictionary *)binaryImageForAddress:(uintptr_t)address {
    NSDictionary *result = nil;
    for (NSDictionary *binaryImage in self.binaryImages) {
        uintptr_t imageStart = (uintptr_t) [binaryImage[@"image_addr"] unsignedLongLongValue];
        uintptr_t imageEnd = imageStart + (uintptr_t) [binaryImage[@"image_size"] unsignedLongLongValue];
        if (address >= imageStart && address < imageEnd) {
            result = binaryImage;
            break;
        }
    }
    return result;
}

- (SentryThread *_Nullable)threadAtIndex:(NSInteger)threadIndex stripCrashedStacktrace:(BOOL)stripCrashedStacktrace {
    if (threadIndex >= [self.threads count]) {
        return nil;
    }
    NSDictionary *threadDictionary = [self.threads objectAtIndex:threadIndex];

    SentryThread *thread = [[SentryThread alloc] initWithThreadId:threadDictionary[@"index"]];
    // We only want to add the stacktrace if this thread hasn't crashed
    thread.stacktrace = [self stackTraceForThreadIndex:threadIndex];
    if (stripCrashedStacktrace && [threadDictionary[@"crashed"] boolValue]) {
        thread.stacktrace = nil;
    }
    thread.crashed = threadDictionary[@"crashed"];
    thread.current = threadDictionary[@"current_thread"];
    thread.name = threadDictionary[@"name"];
    if (nil == thread.name) {
        thread.name = threadDictionary[@"dispatch_queue"];
    }
    return thread;
}

- (SentryFrame *)stackFrameAtIndex:(NSInteger)frameIndex inThreadIndex:(NSInteger)threadIndex {
    NSDictionary *frameDictionary = [self rawStackTraceForThreadIndex:threadIndex][frameIndex];
    uintptr_t instructionAddress = (uintptr_t) [frameDictionary[@"instruction_addr"] unsignedLongLongValue];
    NSDictionary *binaryImage = [self binaryImageForAddress:instructionAddress];
//    BOOL isAppImage = [binaryImage[@"name"] containsString:@"/Bundle/Application/"];
    SentryFrame *frame = [[SentryFrame alloc] init];
    frame.symbolAddress = hexAddress(frameDictionary[@"symbol_addr"]);
    frame.instructionAddress = hexAddress(frameDictionary[@"instruction_addr"]);
    frame.imageAddress = hexAddress(binaryImage[@"image_addr"]);
    frame.package = binaryImage[@"name"];
    if (frameDictionary[@"symbol_name"]) {
        frame.function = frameDictionary[@"symbol_name"];
    }
    return frame;
}

// We already get all the frames in the right order
- (NSArray<SentryFrame *> *)stackFramesForThreadIndex:(NSInteger)threadIndex {
    NSUInteger frameCount = [self rawStackTraceForThreadIndex:threadIndex].count;
    if (frameCount <= 0) {
        return [NSArray new];
    }

    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:frameCount];
    for (NSInteger i = frameCount - 1; i >= 0; i--) {
        [frames addObject:[self stackFrameAtIndex:i inThreadIndex:threadIndex]];
    }
    return frames;
}

- (SentryStacktrace *)stackTraceForThreadIndex:(NSInteger)threadIndex {
    NSArray<SentryFrame *> *frames = [self stackFramesForThreadIndex:threadIndex];
    SentryStacktrace *stacktrace = [[SentryStacktrace alloc] initWithFrames:frames
                                                                  registers:[self registersForThreadIndex:threadIndex]];
    [stacktrace fixDuplicateFrames];
    return stacktrace;
}

- (SentryThread *_Nullable)crashedThread {
    return [self threadAtIndex:self.crashedThreadIndex stripCrashedStacktrace:NO];
}

- (NSArray<SentryDebugMeta *> *)convertDebugMeta {
    NSMutableArray<SentryDebugMeta *> *result = [NSMutableArray new];
    for (NSDictionary *sourceImage in self.report[@"binary_images"]) {
        SentryDebugMeta *debugMeta = [[SentryDebugMeta alloc] init];
        debugMeta.uuid = sourceImage[@"uuid"];
        debugMeta.type = @"apple";
        debugMeta.cpuType = sourceImage[@"cpu_type"];
        debugMeta.cpuSubType = sourceImage[@"cpu_subtype"];
        debugMeta.imageAddress = hexAddress(sourceImage[@"image_addr"]);
        debugMeta.imageSize = sourceImage[@"image_size"];
        debugMeta.imageVmAddress = hexAddress(sourceImage[@"image_vmaddr"]);
        debugMeta.name = sourceImage[@"name"];
        debugMeta.majorVersion = sourceImage[@"major_version"];
        debugMeta.minorVersion = sourceImage[@"minor_version"];
        debugMeta.revisionVersion = sourceImage[@"revision_version"];
        [result addObject:debugMeta];
    }
    return result;
}

- (NSArray<SentryException *> *_Nullable)convertExceptions {
    if (nil == self.exceptionContext) {
        return nil;
    }
    NSString *exceptionType = self.exceptionContext[@"type"];
    SentryException *exception = [[SentryException alloc] initWithValue:@"Unknown Exception" type:@"Unknown Exception"];
    if ([exceptionType isEqualToString:@"nsexception"]) {
        exception = [self parseNSException];
    } else if ([exceptionType isEqualToString:@"cpp_exception"]) {
        exception = [[SentryException alloc] initWithValue:self.exceptionContext[@"cpp_exception"][@"name"]
                                                      type:@"C++ Exception"];
    } else if ([exceptionType isEqualToString:@"mach"]) {
        exception = [[SentryException alloc] initWithValue:[NSString stringWithFormat:@"Exception %@, Code %@, Subcode %@",
                                                                                      self.exceptionContext[@"mach"][@"exception"],
                                                                                      self.exceptionContext[@"mach"][@"code"],
                                                                                      self.exceptionContext[@"mach"][@"subcode"]]
                                                      type:self.exceptionContext[@"mach"][@"exception_name"]];
    } else if ([exceptionType isEqualToString:@"signal"]) {
        exception = [[SentryException alloc] initWithValue:[NSString stringWithFormat:@"Signal %@, Code %@",
                                                                                      self.exceptionContext[@"signal"][@"signal"],
                                                                                      self.exceptionContext[@"signal"][@"code"]]
                                                      type:self.exceptionContext[@"signal"][@"name"]];
    } else if ([exceptionType isEqualToString:@"user"]) {
        NSString *exceptionReason = [NSString stringWithFormat:@"%@", self.exceptionContext[@"reason"]];
        exception = [[SentryException alloc] initWithValue:exceptionReason
                                                      type:self.exceptionContext[@"user_reported"][@"name"]];

        NSRange match = [exceptionReason rangeOfString:@":"];
        if (match.location != NSNotFound) {
            exception = [[SentryException alloc] initWithValue:[[exceptionReason substringWithRange:NSMakeRange(match.location + match.length, (exceptionReason.length - match.location) - match.length)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                                          type:[exceptionReason substringWithRange:NSMakeRange(0, match.location)]];
        }
    }

    [self enhanceValueFromNotableAddresses:exception];
    exception.mechanism = [self extractMechanism];
    exception.thread = [self crashedThread];
    if (nil != self.diagnosis && self.diagnosis.length > 0 && ![self.diagnosis containsString:exception.value]) {
        exception.value = [exception.value stringByAppendingString:[NSString stringWithFormat:@" >\n%@", self.diagnosis]];
    }
    return @[exception];
}

- (SentryException *)parseNSException {
//    if ([self.exceptionContext[@"nsexception"][@"name"] containsString:@"NativeScript encountered a fatal error:"]) {
//        // TODO parsing here
//        SentryException *exception = [[SentryException alloc] initWithValue:self.exceptionContext[@"nsexception"][@"reason"]
//                                                                       type:self.exceptionContext[@"nsexception"][@"name"]];
//        // exception.thread set here with parsed js stacktrace
//
//        return exception;
//    }
    NSString *reason = @"";
    if (nil != self.exceptionContext[@"nsexception"][@"reason"]) {
        reason = self.exceptionContext[@"nsexception"][@"reason"];
    } else if (nil != self.exceptionContext[@"reason"]) {
        reason = self.exceptionContext[@"reason"];
    }
    
    return [[SentryException alloc] initWithValue:[NSString stringWithFormat:@"%@", reason]
                                             type:self.exceptionContext[@"nsexception"][@"name"]];
}

- (void)enhanceValueFromNotableAddresses:(SentryException *)exception {
    // Gatekeeper fixes https://github.com/getsentry/sentry-cocoa/issues/231
    if ([self.threads count] == 0 || self.crashedThreadIndex >= [self.threads count]) {
        return;
    }
    NSDictionary *crashedThread = [self.threads objectAtIndex:self.crashedThreadIndex];
    NSDictionary *notableAddresses = [crashedThread objectForKey:@"notable_addresses"];
    NSMutableOrderedSet *reasons = [[NSMutableOrderedSet alloc] init];
    if (nil != notableAddresses) {
        for(id key in notableAddresses) {
            NSDictionary *content = [notableAddresses objectForKey:key];
            if ([[content objectForKey:@"type"] isEqualToString:@"string"] && nil != [content objectForKey:@"value"]) {
                // if there are less than 3 slashes it shouldn't be a filepath
                if ([[[content objectForKey:@"value"] componentsSeparatedByString:@"/"] count] < 3) {
                    [reasons addObject:[content objectForKey:@"value"]];
                }
            }
        }
    }
    if (reasons.count > 0) {
        exception.value = [[[reasons array] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] componentsJoinedByString:@" > "];
    }
}

- (SentryMechanism *_Nullable)extractMechanism {
    SentryMechanism *mechanism = [[SentryMechanism alloc] initWithType:[self.exceptionContext objectForKey:@"type"]];
    if (nil != [self.exceptionContext objectForKey:@"mach"]) {
        mechanism.handled = @(NO);

        NSMutableDictionary *meta = [NSMutableDictionary new];

        NSMutableDictionary *machException = [NSMutableDictionary new];
        [machException setValue:self.exceptionContext[@"mach"][@"exception_name"] forKey:@"name"];
        [machException setValue:self.exceptionContext[@"mach"][@"exception"] forKey:@"exception"];
        [machException setValue:self.exceptionContext[@"mach"][@"subcode"] forKey:@"subcode"];
        [machException setValue:self.exceptionContext[@"mach"][@"code"] forKey:@"code"];
        [meta setValue:machException forKey:@"mach_exception"];

        if (nil != [self.exceptionContext objectForKey:@"signal"]) {
            NSMutableDictionary *signal = [NSMutableDictionary new];
            [signal setValue:self.exceptionContext[@"signal"][@"signal"] forKey:@"number"];
            [signal setValue:self.exceptionContext[@"signal"][@"code"] forKey:@"code"];
            [signal setValue:self.exceptionContext[@"signal"][@"code_name"] forKey:@"code_name"];
            [signal setValue:self.exceptionContext[@"signal"][@"name"] forKey:@"name"];
            [meta setValue:signal forKey:@"signal"];
        }

        mechanism.meta = meta;

        if (nil != self.exceptionContext[@"address"] && [self.exceptionContext[@"address"] integerValue] > 0) {
            mechanism.data = @{ @"relevant_address": hexAddress(self.exceptionContext[@"address"]) };
        }
    }
    return mechanism;
}

- (NSArray *)convertThreads {
    NSMutableArray *result = [NSMutableArray new];
    for (NSInteger threadIndex = 0; threadIndex < (NSInteger) self.threads.count; threadIndex++) {
        SentryThread *thread = [self threadAtIndex:threadIndex stripCrashedStacktrace:YES];
        if (thread) {
            [result addObject:thread];
        }
    }
    return result;
}

@end
