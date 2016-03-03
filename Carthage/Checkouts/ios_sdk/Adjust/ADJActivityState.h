//
//  ADJActivityState.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-02.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface ADJActivityState : NSObject <NSCoding, NSCopying>

// persistent data
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL askingAttribution;

// global counters
@property (nonatomic, assign) int eventCount;
@property (nonatomic, assign) int sessionCount;

// session attributes
@property (nonatomic, assign) int subsessionCount;
@property (nonatomic, assign) double sessionLength; // all durations in seconds
@property (nonatomic, assign) double timeSpent;
@property (nonatomic, assign) double lastActivity;  // all times in seconds since 1970

// last ten transaction identifiers
@property (nonatomic, retain) NSMutableArray *transactionIds;

// not persisted, only injected
@property (nonatomic, assign) double lastInterval;

- (void)resetSessionAttributes:(double)now;

// transaction ID management
- (void)addTransactionId:(NSString *)transactionId;
- (BOOL)findTransactionId:(NSString *)transactionId;

@end
