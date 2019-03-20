//
//  LPAPIConfig.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 8/25/18.
//

#import <Foundation/Foundation.h>
#import "LPRequesting.h"

@interface LPAPIConfig : NSObject

@property (nonatomic, readonly) NSString *appId;
@property (nonatomic, readonly) NSString *accessKey;

@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *token;

+ (instancetype)sharedConfig;

- (void)setAppId:(NSString *)appId withAccessKey:(NSString *)accessKey;

- (void)loadToken;
- (void)saveToken;

@end
