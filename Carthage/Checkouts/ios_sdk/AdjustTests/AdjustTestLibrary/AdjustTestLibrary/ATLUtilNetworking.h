//
//  ATLUtilNetworking.h
//  AdjustTestLibrary
//
//  Created by Pedro on 18.04.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATLHttpResponse : NSObject

@property (nonatomic, copy) NSString *responseString;
@property (nonatomic, strong) id jsonFoundation;
@property (nonatomic, strong) NSDictionary *headerFields;
@property (nonatomic, assign) NSInteger statusCode;

@end

@interface ATLHttpRequest : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *bodyString;
@property (nonatomic, strong) NSDictionary *headerFields;

@end

typedef void (^httpResponseHandler)(ATLHttpResponse* httpResponse);

@interface ATLUtilNetworking : NSObject

+ (void)sendPostRequest:(ATLHttpRequest *)requestData
        responseHandler:(httpResponseHandler) responseHandler;

+ (NSString *)appendBasePath:(NSString *)basePath
                        path:(NSString *)path;
@end
