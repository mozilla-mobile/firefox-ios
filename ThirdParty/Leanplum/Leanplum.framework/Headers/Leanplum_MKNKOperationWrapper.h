//
//  Leanplum_MKNKOperationWrapper.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

#import "LPNetworkProtocol.h"
#import "MKNetworkKit.h"

/**
 * Wrapper for Leanplum_MKNetworkOperation to use with the factory.
 */
@interface Leanplum_MKNKOperationWrapper : NSObject<LPNetworkOperationProtocol>

@property (nonatomic, strong) Leanplum_MKNetworkOperation *operation;

@end

#endif
