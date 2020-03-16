//
//  LPFileTransferManager.h
//  LeanplumSDK-iOS
//
//  Created by Mayank Sanganeria on 2/1/19.
//  Copyright © 2019 Leanplum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Leanplum.h"
#import "LPNetworkFactory.h"
#import "LPRequesting.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPFileTransferManager : NSObject

@property (nonatomic, strong, nullable) NSString *uploadUrl;
@property (nonatomic, readonly) int numPendingDownloads;
@property (nonatomic, strong) NSDictionary *filenameToURLs;

+ (instancetype)sharedInstance;
- (void)sendFilesNow:(NSArray *)filenames fileData:(NSArray *)fileData;

- (void)downloadFile:(NSString *)path onResponse:(LPNetworkResponseBlock)responseBlock onError:(LPNetworkErrorBlock)errorBlock;
- (void)onNoPendingDownloads:(LeanplumVariablesChangedBlock)noPendingDownloadsBlock;

@end

NS_ASSUME_NONNULL_END
