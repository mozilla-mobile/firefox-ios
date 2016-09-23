//
//  ADJUtil.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-05.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#include <math.h>
#include <stdlib.h>
#include <sys/xattr.h>

#import "ADJUtil.h"
#import "ADJLogger.h"
#import "ADJResponseData.h"
#import "ADJAdjustFactory.h"
#import "UIDevice+ADJAdditions.h"
#import "NSString+ADJAdditions.h"
#import <objc/message.h>

static const double kRequestTimeout = 60;   // 60 seconds

static NSDateFormatter *dateFormat;
static NSRegularExpression * universalLinkRegex = nil;
static NSRegularExpression * shortUniversalLinkRegex = nil;
static NSRegularExpression *optionalRedirectRegex   = nil;
static NSNumberFormatter * secondsNumberFormatter = nil;

static NSString * const kClientSdk              = @"ios4.10.1";
static NSURLSessionConfiguration * urlSessionConfiguration = nil;
static NSString * userAgent = nil;
static NSString * const kDeeplinkParam          = @"deep_link=";
static NSString * const kSchemeDelimiter        = @"://";
static NSString * const kDefaultScheme          = @"AdjustUniversalScheme";
static NSString * const kUniversalLinkPattern   = @"https://[^.]*\\.ulink\\.adjust\\.com/ulink/?(.*)";
static NSString * const kShortUniversalLinkPattern  = @"http[s]?://[a-z0-9]{4}\\.adj\\.st/?(.*)";
static NSString * const kOptionalRedirectPattern = @"adjust_redirect=[^&#]*";

static NSString * const kBaseUrl                = @"https://app.adjust.com";
static NSString * const kDateFormat             = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'Z";

@implementation ADJUtil

+ (void) initialize {
    if (self != [ADJUtil class]) {
        return;
    }
    [self initializeDateFormat];
    [self initializeUniversalLinkRegex];
    [self initializeSecondsNumberFormatter];
    [self initializeShortUniversalLinkRegex];
    [self initializeOptionalRedirectRegex];
    [self initializeUrlSessionConfiguration];
}

+ (void)initializeDateFormat {
    dateFormat = [[NSDateFormatter alloc] init];

    if ([NSCalendar instancesRespondToSelector:@selector(calendarWithIdentifier:)]) {
        // http://stackoverflow.com/a/3339787
        NSString *calendarIdentifier;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
        if (&NSCalendarIdentifierGregorian != NULL) {
#pragma clang diagnostic pop
            calendarIdentifier = NSCalendarIdentifierGregorian;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            calendarIdentifier = NSGregorianCalendar;
#pragma clang diagnostic pop
        }

        dateFormat.calendar = [NSCalendar calendarWithIdentifier:calendarIdentifier];
    }

    dateFormat.locale = [NSLocale systemLocale];
    [dateFormat setDateFormat:kDateFormat];

}

+ (void)initializeUniversalLinkRegex {
    NSError *error = NULL;

    NSRegularExpression *regex  = [NSRegularExpression
                                   regularExpressionWithPattern:kUniversalLinkPattern
                                   options:NSRegularExpressionCaseInsensitive
                                   error:&error];

    if ([ADJUtil isNotNull:error]) {
        [ADJAdjustFactory.logger error:@"Universal link regex rule error (%@)", [error description]];
        return;
    }

    universalLinkRegex = regex;
}

+ (void)initializeShortUniversalLinkRegex {
    NSError *error = NULL;

    NSRegularExpression *regex  = [NSRegularExpression
                                   regularExpressionWithPattern:kShortUniversalLinkPattern
                                   options:NSRegularExpressionCaseInsensitive
                                   error:&error];

    if ([ADJUtil isNotNull:error]) {
        [ADJAdjustFactory.logger error:@"Short Universal link regex rule error (%@)", [error description]];
        return;
    }

    shortUniversalLinkRegex = regex;
}

+ (void)initializeOptionalRedirectRegex {
    NSError *error = NULL;

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kOptionalRedirectPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];

    if ([ADJUtil isNotNull:error]) {
        [ADJAdjustFactory.logger error:@"Optional redirect regex rule error (%@)", [error description]];
        return;
    }

    optionalRedirectRegex = regex;
}

+ (void)initializeSecondsNumberFormatter {
    secondsNumberFormatter = [[NSNumberFormatter alloc] init];
    [secondsNumberFormatter setPositiveFormat:@"0.0"];
}

+ (void)initializeUrlSessionConfiguration {
    urlSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
}

+ (void)updateUrlSessionConfiguration:(ADJConfig *)config {
    userAgent = config.userAgent;
}

+ (NSString *)baseUrl {
    return kBaseUrl;
}

+ (NSString *)clientSdk {
    return kClientSdk;
}

// Inspired by https://gist.github.com/kevinbarrett/2002382
+ (void)excludeFromBackup:(NSString *)path {
    NSURL *url = [NSURL fileURLWithPath:path];
    const char* filePath = [[url path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    id<ADJLogger> logger = ADJAdjustFactory.logger;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    if (&NSURLIsExcludedFromBackupKey == nil) {
        u_int8_t attrValue = 1;
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);

        if (result != 0) {
            [logger debug:@"Failed to exclude '%@' from backup", url.lastPathComponent];
        }
    } else { // iOS 5.0 and higher
        // First try and remove the extended attribute if it is present
        ssize_t result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);

        if (result != -1) {
            // The attribute exists, we need to remove it
            int removeResult = removexattr(filePath, attrName, 0);

            if (removeResult == 0) {
                [logger debug:@"Removed extended attribute on file '%@'", url];
            }
        }

        // Set the new key
        NSError *error = nil;
        BOOL success = [url setResourceValue:[NSNumber numberWithBool:YES]
                                      forKey:NSURLIsExcludedFromBackupKey
                                       error:&error];

        if (!success || error != nil) {
            [logger debug:@"Failed to exclude '%@' from backup (%@)", url.lastPathComponent, error.localizedDescription];
        }
    }
#pragma clang diagnostic pop
}

+ (NSString *)formatSeconds1970:(double)value {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:value];
    return [self formatDate:date];
}

+ (NSString *)formatDate:(NSDate *)value {
    return [dateFormat stringFromDate:value];
}

+ (void) saveJsonResponse:(NSData *)jsonData responseData:(ADJResponseData *)responseData {
    NSError *error = nil;
    NSException *exception = nil;
    NSDictionary *jsonDict = [ADJUtil buildJsonDict:jsonData exceptionPtr:&exception errorPtr:&error];

    if (exception != nil) {
        NSString *message = [NSString stringWithFormat:@"Failed to parse json response. (%@)", exception.description];

        [ADJAdjustFactory.logger error:message];
        responseData.message = message;

        return;
    }

    if (error != nil) {
        NSString *message = [NSString stringWithFormat:@"Failed to parse json response. (%@)", error.localizedDescription];

        [ADJAdjustFactory.logger error:message];
        responseData.message = message;

        return;
    }

    responseData.jsonResponse = jsonDict;
}

+ (NSDictionary *)buildJsonDict:(NSData *)jsonData
                   exceptionPtr:(NSException **)exceptionPtr
                       errorPtr:(NSError **)error {
    if (jsonData == nil) {
        return nil;
    }

    NSDictionary *jsonDict = nil;

    @try {
        jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
    } @catch (NSException *ex) {
        *exceptionPtr = ex;
        return nil;
    }

    return jsonDict;
}

+ (NSString *)getFullFilename:(NSString *)baseFilename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filename = [path stringByAppendingPathComponent:baseFilename];

    return filename;
}

+ (id)readObject:(NSString *)filename
      objectName:(NSString *)objectName
           class:(Class) classToRead {
    id<ADJLogger> logger = [ADJAdjustFactory logger];

    @try {
        NSString *fullFilename = [ADJUtil getFullFilename:filename];
        id object = [NSKeyedUnarchiver unarchiveObjectWithFile:fullFilename];

        if ([object isKindOfClass:classToRead]) {
            [logger debug:@"Read %@: %@", objectName, object];
            return object;
        } else if (object == nil) {
            [logger verbose:@"%@ file not found", objectName];
        } else {
            [logger error:@"Failed to read %@ file", objectName];
        }
    } @catch (NSException *ex ) {
        [logger error:@"Failed to read %@ file (%@)", objectName, ex];
    }

    return nil;
}

+ (void)writeObject:(id)object
           filename:(NSString *)filename
         objectName:(NSString *)objectName {
    id<ADJLogger> logger = [ADJAdjustFactory logger];
    NSString *fullFilename = [ADJUtil getFullFilename:filename];
    BOOL result = [NSKeyedArchiver archiveRootObject:object toFile:fullFilename];

    if (result == YES) {
        [ADJUtil excludeFromBackup:fullFilename];
        [logger debug:@"Wrote %@: %@", objectName, object];
    } else {
        [logger error:@"Failed to write %@ file", objectName];
    }
}

+ (NSString *)queryString:(NSDictionary *)parameters {
    return [ADJUtil queryString:parameters queueSize:0];
}

+ (NSString *)queryString:(NSDictionary *)parameters
                queueSize:(NSUInteger)queueSize {
    NSMutableArray *pairs = [NSMutableArray array];

    for (NSString *key in parameters) {
        NSString *value = [parameters objectForKey:key];
        NSString *escapedValue = [value adjUrlEncode];
        NSString *escapedKey = [key adjUrlEncode];
        NSString *pair = [NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue];

        [pairs addObject:pair];
    }

    double now = [NSDate.date timeIntervalSince1970];
    NSString *dateString = [ADJUtil formatSeconds1970:now];
    NSString *escapedDate = [dateString adjUrlEncode];
    NSString *sentAtPair = [NSString stringWithFormat:@"%@=%@", @"sent_at", escapedDate];

    [pairs addObject:sentAtPair];

    if (queueSize > 0) {
        unsigned long queueSizeNative = (unsigned long)queueSize;
        NSString *queueSizeString = [NSString stringWithFormat:@"%lu", queueSizeNative];
        NSString *escapedQueueSize = [queueSizeString adjUrlEncode];
        NSString *queueSizePair = [NSString stringWithFormat:@"%@=%@", @"queue_size", escapedQueueSize];

        [pairs addObject:queueSizePair];
    }

    NSString *queryString = [pairs componentsJoinedByString:@"&"];

    return queryString;
}

+ (BOOL)isNull:(id)value {
    return value == nil || value == (id)[NSNull null];
}

+ (BOOL)isNotNull:(id)value {
    return value != nil && value != (id)[NSNull null];
}

+ (NSString *)formatErrorMessage:(NSString *)prefixErrorMessage
              systemErrorMessage:(NSString *)systemErrorMessage
              suffixErrorMessage:(NSString *)suffixErrorMessage {
    NSString *errorMessage = [NSString stringWithFormat:@"%@ (%@)", prefixErrorMessage, systemErrorMessage];
    if (suffixErrorMessage == nil) {
        return errorMessage;
    } else {
        return [errorMessage stringByAppendingFormat:@" %@", suffixErrorMessage];
    }
}

+ (void)sendPostRequest:(NSURL *)baseUrl
              queueSize:(NSUInteger)queueSize
     prefixErrorMessage:(NSString *)prefixErrorMessage
     suffixErrorMessage:(NSString *)suffixErrorMessage
        activityPackage:(ADJActivityPackage *)activityPackage
    responseDataHandler:(void (^)(ADJResponseData *responseData))responseDataHandler {
    NSMutableURLRequest *request = [ADJUtil requestForPackage:activityPackage baseUrl:baseUrl queueSize:queueSize];

    [ADJUtil sendRequest:request
      prefixErrorMessage:prefixErrorMessage
      suffixErrorMessage:suffixErrorMessage
         activityPackage:activityPackage
     responseDataHandler:responseDataHandler];
}

+ (NSMutableURLRequest *)requestForPackage:(ADJActivityPackage *)activityPackage
                                   baseUrl:(NSURL *)baseUrl
                                 queueSize:(NSUInteger)queueSize {
    NSURL *url = [NSURL URLWithString:activityPackage.path relativeToURL:baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRequestTimeout;
    request.HTTPMethod = @"POST";

    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:activityPackage.clientSdk forHTTPHeaderField:@"Client-Sdk"];

    NSString *bodyString = [ADJUtil queryString:activityPackage.parameters queueSize:queueSize];
    NSData *body = [NSData dataWithBytes:bodyString.UTF8String length:bodyString.length];
    [request setHTTPBody:body];

    return request;
}

+ (void)sendRequest:(NSMutableURLRequest *)request
 prefixErrorMessage:(NSString *)prefixErrorMessage
    activityPackage:(ADJActivityPackage *)activityPackage
responseDataHandler:(void (^)(ADJResponseData *responseData))responseDataHandler {
    [ADJUtil sendRequest:request
      prefixErrorMessage:prefixErrorMessage
      suffixErrorMessage:nil
         activityPackage:activityPackage
     responseDataHandler:responseDataHandler];
}

+ (void)sendRequest:(NSMutableURLRequest *)request
 prefixErrorMessage:(NSString *)prefixErrorMessage
 suffixErrorMessage:(NSString *)suffixErrorMessage
    activityPackage:(ADJActivityPackage *)activityPackage
responseDataHandler:(void (^)(ADJResponseData *responseData))responseDataHandler {
    Class NSURLSessionClass = NSClassFromString(@"NSURLSession");

    if (userAgent != nil) {
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    if (NSURLSessionClass != nil) {
        [ADJUtil sendNSURLSessionRequest:request
                      prefixErrorMessage:prefixErrorMessage
                      suffixErrorMessage:suffixErrorMessage
                         activityPackage:activityPackage
                     responseDataHandler:responseDataHandler];
    } else {
        [ADJUtil sendNSURLConnectionRequest:request
                         prefixErrorMessage:prefixErrorMessage
                         suffixErrorMessage:suffixErrorMessage
                            activityPackage:activityPackage
                        responseDataHandler:responseDataHandler];
    }
}

+ (void)sendNSURLSessionRequest:(NSMutableURLRequest *)request
             prefixErrorMessage:(NSString *)prefixErrorMessage
             suffixErrorMessage:(NSString *)suffixErrorMessage
                activityPackage:(ADJActivityPackage *)activityPackage
            responseDataHandler:(void (^)(ADJResponseData *responseData))responseDataHandler
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:urlSessionConfiguration];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      ADJResponseData *responseData = [ADJUtil completionHandler:data
                                                                                        response:(NSHTTPURLResponse *)response
                                                                                           error:error
                                                                              prefixErrorMessage:prefixErrorMessage
                                                                              suffixErrorMessage:suffixErrorMessage
                                                                                 activityPackage:activityPackage];
                                      responseDataHandler(responseData);
                                  }];
    [task resume];
}

+ (void)sendNSURLConnectionRequest:(NSMutableURLRequest *)request
                prefixErrorMessage:(NSString *)prefixErrorMessage
                suffixErrorMessage:(NSString *)suffixErrorMessage
                   activityPackage:(ADJActivityPackage *)activityPackage
               responseDataHandler:(void (^)(ADJResponseData *responseData))responseDataHandler {
    NSError *responseError = nil;
    NSHTTPURLResponse *urlResponse = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&urlResponse
                                                     error:&responseError];
#pragma clang diagnostic pop

    ADJResponseData *responseData = [ADJUtil completionHandler:data
                                                      response:(NSHTTPURLResponse *)urlResponse
                                                         error:responseError
                                            prefixErrorMessage:prefixErrorMessage
                                            suffixErrorMessage:suffixErrorMessage
                                               activityPackage:activityPackage];

    responseDataHandler(responseData);
}

+ (ADJResponseData *)completionHandler:(NSData *)data
                              response:(NSHTTPURLResponse *)urlResponse
                                 error:(NSError *)responseError
                    prefixErrorMessage:(NSString *)prefixErrorMessage
                    suffixErrorMessage:(NSString *)suffixErrorMessage
                       activityPackage:(ADJActivityPackage *)activityPackage {
    ADJResponseData *responseData = [ADJResponseData buildResponseData:activityPackage];

    // Connection error
    if (responseError != nil) {
        NSString *errorMessage = [ADJUtil formatErrorMessage:prefixErrorMessage
                                          systemErrorMessage:responseError.localizedDescription
                                          suffixErrorMessage:suffixErrorMessage];

        [ADJAdjustFactory.logger error:errorMessage];
        responseData.message = errorMessage;

        return responseData;
    }

    if ([ADJUtil isNull:data]) {
        NSString *errorMessage = [ADJUtil formatErrorMessage:prefixErrorMessage
                                          systemErrorMessage:@"empty error"
                                          suffixErrorMessage:suffixErrorMessage];

        [ADJAdjustFactory.logger error:errorMessage];
        responseData.message = errorMessage;

        return responseData;
    }

    NSString *responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] adjTrim];
    NSInteger statusCode = urlResponse.statusCode;

    [ADJAdjustFactory.logger verbose:@"Response: %@", responseString];
    [ADJUtil saveJsonResponse:data responseData:responseData];

    if ([ADJUtil isNull:responseData.jsonResponse]) {
        return responseData;
    }

    NSString *messageResponse = [responseData.jsonResponse objectForKey:@"message"];

    responseData.message    = messageResponse;
    responseData.timeStamp  = [responseData.jsonResponse objectForKey:@"timestamp"];
    responseData.adid       = [responseData.jsonResponse objectForKey:@"adid"];

    if (messageResponse == nil) {
        messageResponse = @"No message found";
    }

    if (statusCode == 200) {
        [ADJAdjustFactory.logger info:@"%@", messageResponse];
        responseData.success = YES;
    } else {
        [ADJAdjustFactory.logger error:@"%@", messageResponse];
    }

    return responseData;
}

// Convert all values to strings, if value is dictionary -> recursive call
+ (NSDictionary *)convertDictionaryValues:(NSDictionary *)dictionary {
    NSMutableDictionary *convertedDictionary = [[NSMutableDictionary alloc] initWithCapacity:dictionary.count];

    for (NSString *key in dictionary) {
        id value = [dictionary objectForKey:key];

        if ([value isKindOfClass:[NSDictionary class]]) {
            // Dictionary value, recursive call
            NSDictionary *dictionaryValue = [ADJUtil convertDictionaryValues:(NSDictionary *)value];
            [convertedDictionary setObject:dictionaryValue forKey:key];
        } else if ([value isKindOfClass:[NSDate class]]) {
            // Format date to our custom format
            NSString *dateStingValue = [ADJUtil formatDate:value];
            [convertedDictionary setObject:dateStingValue forKey:key];
        } else {
            // Convert all other objects directly to string
            NSString *stringValue = [NSString stringWithFormat:@"%@", value];
            [convertedDictionary setObject:stringValue forKey:key];
        }
    }

    return convertedDictionary;
}

+ (NSString *)idfa {
    return [[UIDevice currentDevice] adjIdForAdvertisers];
}

+ (NSURL *)convertUniversalLink:(NSURL *)url scheme:(NSString *)scheme {
    id<ADJLogger> logger = ADJAdjustFactory.logger;

    if ([ADJUtil isNull:url]) {
        [logger error:@"Received universal link is nil"];
        return nil;
    }

    if ([ADJUtil isNull:scheme] || [scheme length] == 0) {
        [logger warn:@"Non-empty scheme required, using the scheme \"AdjustUniversalScheme\""];
        scheme = kDefaultScheme;
    }

    NSString *urlString = [url absoluteString];

    if ([ADJUtil isNull:urlString]) {
        [logger error:@"Parsed universal link is nil"];
        return nil;
    }

    if (universalLinkRegex == nil) {
        [logger error:@"Universal link regex not correctly configured"];
        return nil;
    }

    if (shortUniversalLinkRegex == nil) {
        [logger error:@"Short Universal link regex not correctly configured"];
        return nil;
    }

    NSArray<NSTextCheckingResult *> *matches = [universalLinkRegex matchesInString:urlString options:0 range:NSMakeRange(0, [urlString length])];

    if ([matches count] == 0) {
        matches = [shortUniversalLinkRegex matchesInString:urlString options:0 range:NSMakeRange(0, [urlString length])];
        if ([matches count] == 0) {
            [logger error:@"Url doesn't match as universal link or short version"];
            return nil;
        }
    }

    if ([matches count] > 1) {
        [logger error:@"Url match as universal link multiple times"];
        return nil;
    }

    NSTextCheckingResult *match = matches[0];

    if ([match numberOfRanges] != 2) {
        [logger error:@"Wrong number of ranges matched"];
        return nil;
    }

    NSString *tailSubString = [urlString substringWithRange:[match rangeAtIndex:1]];

    NSString *finalTailSubString = [ADJUtil removeOptionalRedirect:tailSubString];

    NSString *extractedUrlString = [NSString stringWithFormat:@"%@://%@", scheme, finalTailSubString];

    [logger info:@"Converted deeplink from universal link %@", extractedUrlString];

    NSURL *extractedUrl = [NSURL URLWithString:extractedUrlString];

    if ([ADJUtil isNull:extractedUrl]) {
        [logger error:@"Unable to parse converted deeplink from universal link %@", extractedUrlString];
        return nil;
    }

    return extractedUrl;
}

+ (NSString *)removeOptionalRedirect:(NSString *)tailSubString {
    id<ADJLogger> logger = ADJAdjustFactory.logger;

    if (optionalRedirectRegex == nil) {
        [ADJAdjustFactory.logger error:@"Remove Optional Redirect regex not correctly configured"];
        return tailSubString;
    }

    NSArray<NSTextCheckingResult *> *optionalRedirectmatches = [optionalRedirectRegex matchesInString:tailSubString
                                                                                              options:0
                                                                                                range:NSMakeRange(0, [tailSubString length])];

    if ([optionalRedirectmatches count] == 0) {
        [logger debug:@"Universal link does not contain option adjust_redirect parameter"];
        return tailSubString;
    }

    if ([optionalRedirectmatches count] > 1) {
        [logger error:@"Universal link contains multiple option adjust_redirect parameters"];
        return tailSubString;
    }

    NSTextCheckingResult *redirectMatch = optionalRedirectmatches[0];

    NSRange redirectRange = [redirectMatch rangeAtIndex:0];

    NSString *beforeRedirect = [tailSubString substringToIndex:redirectRange.location];
    NSString *afterRedirect = [tailSubString substringFromIndex:(redirectRange.location + redirectRange.length)];

    if (beforeRedirect.length > 0 &&
        afterRedirect.length > 0)
    {
        NSString *lastCharacterBeforeRedirect = [beforeRedirect substringFromIndex:beforeRedirect.length - 1];
        NSString *firstCharacterAfterRedirect = [afterRedirect substringToIndex:1];

        if ([@"&" isEqualToString:lastCharacterBeforeRedirect] &&
            [@"&" isEqualToString:firstCharacterAfterRedirect])
        {
            beforeRedirect = [beforeRedirect
                              substringToIndex:beforeRedirect.length - 1];
        }

        if ([@"&" isEqualToString:lastCharacterBeforeRedirect] &&
            [@"#" isEqualToString:firstCharacterAfterRedirect])
        {
            beforeRedirect = [beforeRedirect
                              substringToIndex:beforeRedirect.length - 1];
        }

        if ([@"?" isEqualToString:lastCharacterBeforeRedirect] &&
            [@"#" isEqualToString:firstCharacterAfterRedirect])
        {
            beforeRedirect = [beforeRedirect
                              substringToIndex:beforeRedirect.length - 1];
        }

        if ([@"?" isEqualToString:lastCharacterBeforeRedirect] &&
            [@"&" isEqualToString:firstCharacterAfterRedirect])
        {
            afterRedirect = [afterRedirect substringFromIndex:1];
        }

    }
    NSString * removedRedirect = [NSString stringWithFormat:@"%@%@", beforeRedirect, afterRedirect];

    return removedRedirect;
}

+ (NSString *)secondsNumberFormat:(double)seconds {
    // Normalize negative zero
    if (seconds < 0) {
        seconds = seconds * -1;
    }

    return [secondsNumberFormatter stringFromNumber:[NSNumber numberWithDouble:seconds]];
}

+ (double)randomInRange:(double)minRange maxRange:(double)maxRange {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        srand48(arc4random());
    });

    double random = drand48();
    double range = maxRange - minRange;
    double scaled = random  * range;
    double shifted = scaled + minRange;

    return shifted;
}

+ (NSTimeInterval)waitingTime:(NSInteger)retries
              backoffStrategy:(ADJBackoffStrategy *)backoffStrategy {
    if (retries < backoffStrategy.minRetries) {
        return 0;
    }

    // Start with base 0
    NSInteger base = retries - backoffStrategy.minRetries;

    // Get the exponential Time from the base: 1, 2, 4, 8, 16, ... * times the multiplier
    NSTimeInterval exponentialTime = pow(2.0, base) * backoffStrategy.secondMultiplier;

    // Limit the maximum allowed time to wait
    NSTimeInterval ceilingTime = MIN(exponentialTime, backoffStrategy.maxWait);

    // Add 1 to allow maximum value
    double randomRange = [ADJUtil randomInRange:backoffStrategy.minRange maxRange:backoffStrategy.maxRange];

    // Apply jitter factor
    NSTimeInterval waitingTime =  ceilingTime * randomRange;

    return waitingTime;
}

+ (void)launchInMainThread:(NSObject *)receiver
                  selector:(SEL)selector
                withObject:(id)object {
    if (ADJAdjustFactory.testing) {
        [ADJAdjustFactory.logger debug:@"Launching in the background for testing"];
        [receiver performSelectorInBackground:selector withObject:object];
    } else {
        [receiver performSelectorOnMainThread:selector
                                   withObject:object
                                waitUntilDone:NO];  // non-blocking
    }
}

+ (void)launchInMainThread:(dispatch_block_t)block {
    if (ADJAdjustFactory.testing) {
        [ADJAdjustFactory.logger debug:@"Launching in the background for testing"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

+ (BOOL)isValidParameter:(NSString *)attribute
           attributeType:(NSString *)attributeType
           parameterName:(NSString *)parameterName {
    if ([ADJUtil isNull:attribute]) {
        [ADJAdjustFactory.logger error:@"%@ parameter %@ is missing", parameterName, attributeType];
        return NO;
    }

    if ([attribute isEqualToString:@""]) {
        [ADJAdjustFactory.logger error:@"%@ parameter %@ is empty", parameterName, attributeType];
        return NO;
    }

    return YES;
}

+ (NSDictionary *)mergeParameters:(NSDictionary *)target
                           source:(NSDictionary *)source
                    parameterName:(NSString *)parameterName {
    if (target == nil) {
        return source;
    }

    if (source == nil) {
        return target;
    }

    NSMutableDictionary *mergedParameters = [NSMutableDictionary dictionaryWithDictionary:target];
    [source enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *oldValue = [mergedParameters objectForKey:key];

        if (oldValue != nil) {
            [ADJAdjustFactory.logger warn:@"Key %@ with value %@ from %@ parameter was replaced by value %@",
             key, oldValue, parameterName, obj];
        }

        [mergedParameters setObject:obj forKey:key];
    }];

    return (NSDictionary *)mergedParameters;
}

+ (void)launchInQueue:(dispatch_queue_t)queue
           selfInject:(id)selfInject
                block:(selfInjectedBlock)block {
    __weak __typeof__(selfInject) weakSelf = selfInject;

    dispatch_async(queue, ^{
        __typeof__(selfInject) strongSelf = weakSelf;

        if (strongSelf == nil) {
            return;
        }

        block(strongSelf);
    });
}

+ (NSString *)getFilename:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filepath = [path stringByAppendingPathComponent:filename];

    return filepath;
}

+ (BOOL)deleteFile:(NSString *)filename {
    NSString *filepath = [ADJUtil getFilename:filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL exists = [fileManager fileExistsAtPath:filepath];

    if (!exists) {
        [ADJAdjustFactory.logger verbose:@"File %@ does not exist at path %@", filename, filepath];
        return YES;
    }

    BOOL deleted = [fileManager removeItemAtPath:filepath error:&error];

    if (!deleted) {
        [ADJAdjustFactory.logger verbose:@"Unable to delete file %@ at path %@", filename, filepath];
    }

    if (error) {
        [ADJAdjustFactory.logger error:@"Error (%@) deleting file %@", [error localizedDescription], filename];
    }

    return deleted;
}

+ (void)launchDeepLinkMain:(NSURL *)deepLinkUrl {
    UIApplication * sharedUIApplication = [UIApplication sharedApplication];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL openUrlSelector = @selector(openURL:options:completionHandler:);
#pragma clang diagnostic pop

    if ([sharedUIApplication respondsToSelector:openUrlSelector]) {
        /*
         [sharedUIApplication openURL:deepLinkUrl options:@{} completionHandler:^(BOOL success) {
         if (!success) {
         [ADJAdjustFactory.logger error:@"Unable to open deep link (%@)", deepLinkUrl];
         }
         }];
         */

        NSMethodSignature * methSig = [sharedUIApplication methodSignatureForSelector: openUrlSelector];
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature: methSig];

        [invocation setSelector: openUrlSelector];
        [invocation setTarget: sharedUIApplication];

        NSDictionary * emptyDictionary = @{};
        void (^completion)(BOOL) = ^(BOOL success) {
            if (!success) {
                [ADJAdjustFactory.logger error:@"Unable to open deep link (%@)", deepLinkUrl];
            }
        };

        [invocation setArgument: &deepLinkUrl  atIndex: 2];
        [invocation setArgument: &emptyDictionary atIndex: 3];
        [invocation setArgument: &completion  atIndex: 4];

        [invocation invoke];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        BOOL success = [sharedUIApplication openURL:deepLinkUrl];
#pragma clang diagnostic pop

        if (!success) {
            [ADJAdjustFactory.logger error:@"Unable to open deep link (%@)", deepLinkUrl];
        }
    }
}

@end
