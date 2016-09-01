//
//  URLRequest.m
//  AdjustExample-iOS
//
//  Created by Uglješa Erceg on 02/12/15.
//  Copyright © 2015 adjust. All rights reserved.
//

#import "Constants.h"
#import "URLRequest.h"

@implementation URLRequest

+ (void)forgetDeviceWithAppToken:(NSString *)appToken
                            idfv:(NSString *)idfv
                 responseHandler:(void (^)(NSString *response))responseHandler {
    NSDictionary *parameters = @{ kParamAppToken : appToken,
                                  kParamIdfv : idfv };
    NSURL *url = [NSURL URLWithString:kBaseForgetUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.timeoutInterval = 5.0;
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[self bodyForParameters:parameters]];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      responseHandler([NSString stringWithUTF8String:[data bytes]]);
                                  }];
    [task resume];
}

+ (NSData *)bodyForParameters:(NSDictionary *)parameters {
    NSString *bodyString = [self queryString:parameters];
    NSData *body = [NSData dataWithBytes:bodyString.UTF8String length:bodyString.length];

    return body;
}

+ (NSString *)queryString:(NSDictionary *)parameters {
    NSMutableArray *pairs = [NSMutableArray array];

    for (NSString *key in parameters) {
        NSString *value         = [parameters objectForKey:key];
        NSString *escapedKey    = [self urlEncode:key];
        NSString *escapedValue  = [self urlEncode:value];
        NSString *pair          = [NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue];

        [pairs addObject:pair];
    }

    NSString *queryString = [pairs componentsJoinedByString:@"&"];

    return queryString;
}

+ (NSString *)urlEncode:(NSString *)stringToEncode {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)stringToEncode,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
#pragma clang diagnostic pop
}

@end
