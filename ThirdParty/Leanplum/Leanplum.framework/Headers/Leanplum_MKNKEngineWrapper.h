//
//  Leanplum_MKNKEngineWrapper.h
//  Leanplum
//
//  Created by Alexis Oyama on 11/14/16.
//  Copyright (c) 2016 Leanplum, Inc. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000

#import "LPNetworkProtocol.h"
#import "MKNetworkKit.h"

/**
 * Wrapper for Leanplum_MKNetworkEngine to use with the factory.
 */
@interface Leanplum_MKNKEngineWrapper : NSObject<LPNetworkEngineProtocol>

@property (nonatomic, strong) Leanplum_MKNetworkEngine *engine;

@end

#endif
