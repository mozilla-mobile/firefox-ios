//
//  ATLUtilNetworking.m
//  AdjustTestLibrary
//
//  Created by Pedro on 18.04.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import "ATLUtilNetworking.h"
#import "ATLUtil.h"
#import "ATLTestLibrary.h"

static const double kRequestTimeout = 60;   // 60 seconds
static NSURLSessionConfiguration *urlSessionConfiguration = nil;

@implementation ATLHttpResponse
@end

@implementation ATLHttpRequest
@end

@implementation ATLUtilNetworking

+ (void)initialize {
    if (self != [ATLUtilNetworking class]) {
        return;
    }
    
    [self initializeUrlSessionConfiguration];
}

+ (void)initializeUrlSessionConfiguration {
    urlSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
}

+ (NSString *)appendBasePath:(NSString *)basePath
                        path:(NSString *)path {
    if (basePath == nil) {
        return path;
    }
    return [NSString stringWithFormat:@"%@%@", basePath, path];
}

+ (void)sendPostRequest:(ATLHttpRequest *)requestData
        responseHandler:(httpResponseHandler)responseHandler
{
    NSMutableURLRequest *request = [ATLUtilNetworking requestForPackage:requestData];
    
    [ATLUtilNetworking sendRequest:request
                   responseHandler:responseHandler];
}

+ (NSMutableURLRequest *)requestForPackage:(ATLHttpRequest *)requestData
{
    NSURL *url = [NSURL URLWithString:requestData.path relativeToURL:[ATLTestLibrary baseUrl]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = kRequestTimeout;
    request.HTTPMethod = @"POST";
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    if (requestData.headerFields != nil) {
        for (NSString *key in requestData.headerFields) {
            [request setValue:requestData.headerFields[key] forHTTPHeaderField:key];
        }
    }
    
    if (requestData.bodyString != nil) {
        NSData *body = [NSData dataWithBytes:requestData.bodyString.UTF8String length:requestData.bodyString.length];
        [request setHTTPBody:body];
    }
    
    return request;
}

+ (void)sendRequest:(NSMutableURLRequest *)request
    responseHandler:(httpResponseHandler)responseHandler
{
    Class NSURLSessionClass = NSClassFromString(@"NSURLSession");
   
    if (NSURLSessionClass != nil) {
        [ATLUtilNetworking sendNSURLSessionRequest:request
                     responseHandler:responseHandler];
    } else {
        [ATLUtilNetworking sendNSURLConnectionRequest:request
                        responseHandler:responseHandler];
    }
}

+ (void)sendNSURLSessionRequest:(NSMutableURLRequest *)request
            responseHandler:(httpResponseHandler)responseHandler
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:urlSessionConfiguration
                                                delegate:nil
                                           delegateQueue:nil];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      ATLHttpResponse *httpResponseData =
                                      [ATLUtilNetworking completionHandler:data
                                                                   response:(NSHTTPURLResponse *)response
                                                                      error:error];
                                      responseHandler(httpResponseData);
                                  }];
    
    [task resume];
    [session finishTasksAndInvalidate];
}

+ (void)sendNSURLConnectionRequest:(NSMutableURLRequest *)request
                   responseHandler:(httpResponseHandler)responseHandler
{
    NSError *responseError = nil;
    NSHTTPURLResponse *urlResponse = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&urlResponse
                                                     error:&responseError];
#pragma clang diagnostic pop
    
    ATLHttpResponse *httpResponseData = [ATLUtilNetworking completionHandler:data
                                                                     response:(NSHTTPURLResponse *)urlResponse
                                                                        error:responseError];
    
    responseHandler(httpResponseData);
}

+ (ATLHttpResponse *)completionHandler:(NSData *)data
                              response:(NSHTTPURLResponse *)urlResponse
                                 error:(NSError *)responseError
{
    ATLHttpResponse *httpResponseData = [[ATLHttpResponse alloc] init];
    
    // Connection error
    if (responseError != nil) {
        [ATLUtil debug:@"responseError %@", responseError.localizedDescription];
        
        return httpResponseData;
    }
    
    if ([ATLUtil isNull:data]) {
        [ATLUtil debug:@"data is null %@"];

        return httpResponseData;
    }
    
    httpResponseData.responseString = [ATLUtil adjTrim:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    [ATLUtil debug:@"Response: %@", httpResponseData.responseString];

    httpResponseData.statusCode = urlResponse.statusCode;

    httpResponseData.headerFields = urlResponse.allHeaderFields;
    [ATLUtil debug:@"header fields: %@", httpResponseData.headerFields];

    httpResponseData.jsonFoundation = [ATLUtilNetworking saveJsonResponse:data];
    [ATLUtil debug:@"json response: %@", httpResponseData.jsonFoundation];

    [ATLUtil debug:@"json response class: %@", NSStringFromClass([httpResponseData.jsonFoundation class])];
    //2const char * cStringClassName = object_getClassName(httpResponseData.jsonFoundation);
    
    return httpResponseData;
}

+ (id)saveJsonResponse:(NSData *)jsonData {
    NSError *error = nil;
    NSException *exception = nil;
    id jsonFoundation = [ATLUtilNetworking buildJsonFoundation:jsonData exceptionPtr:&exception errorPtr:&error];
    
    if (exception != nil) {
        [ATLUtil debug:@"Failed to parse json response. (%@)", exception.description];
        
        return nil;
    }
    
    if (error != nil) {
        [ATLUtil debug:@"Failed to parse json response. (%@)", error.description];

        return nil;
    }
    
    return jsonFoundation;
}

+ (id)buildJsonFoundation:(NSData *)jsonData
               exceptionPtr:(NSException **)exceptionPtr
                   errorPtr:(NSError **)error {
    if (jsonData == nil) {
        return nil;
    }
    
    id jsonFoundation = nil;
    
    @try {
        jsonFoundation = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
    } @catch (NSException *ex) {
        *exceptionPtr = ex;
        return nil;
    }
    
    return jsonFoundation;
}

@end
