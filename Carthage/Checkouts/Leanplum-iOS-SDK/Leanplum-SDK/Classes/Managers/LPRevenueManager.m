//
//  LPRevenueManager.m
//  Leanplum iOS SDK
//
//  Created by Atanas Dobrev on 9/9/14
//  Copyright (c) 2014 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPRevenueManager.h"
#import "LPSwizzle.h"
#import "LeanplumInternal.h"
#import "LPConstants.h"
#import "LPUtils.h"
#import "LPCountAggregator.h"

#pragma mark - SKPaymentQueue(LPSKPaymentQueueExtension) implementation

void leanplum_finishTransaction(id self, SEL _cmd, SKPaymentTransaction *transaction);
void leanplum_finishTransaction(id self, SEL _cmd, SKPaymentTransaction *transaction)
{
    ((void(*)(id, SEL, SKPaymentTransaction *))LP_GET_ORIGINAL_IMP(@selector(finishTransaction:)))(self, _cmd, transaction);
    
    LP_TRY
    if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
        [[LPRevenueManager sharedManager] addTransaction:transaction];
    }
    LP_END_TRY
}


@interface LPRevenueManager()

@property (nonatomic, strong) NSMutableDictionary *transactions;
@property (nonatomic, strong) NSMutableDictionary *requests;
@property (nonatomic, strong) LPCountAggregator *countAggregator;

@end

#pragma mark - LPRevenueManager implementation

@implementation LPRevenueManager

#pragma mark - initialization methods

- (id)init
{
    if (self = [super init]) {
        _transactions = [[NSMutableDictionary alloc] init];
        _requests = [[NSMutableDictionary alloc] init];
        _countAggregator = [LPCountAggregator sharedAggregator];
        [self loadTransactions];
        // If crash happens or the os/user terminates the app and there are pending transactions.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveTransactions)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

+ (LPRevenueManager *)sharedManager
{
    static LPRevenueManager *_sharedManager = nil;
    static dispatch_once_t revenueManagerToken;
    dispatch_once(&revenueManagerToken, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}

#pragma mark - life cycle methods

- (void)loadTransactions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *transactions = [defaults objectForKey:@"LPARTTransactions"];
    if (transactions) {
        for (NSString *key in transactions) {
            [self addTransactionDictionary:transactions[key]];
        }
    }
}

- (void)saveTransactions
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.transactions forKey:@"LPARTTransactions"];
    [defaults synchronize];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - user method

- (void)trackRevenue
{
    static dispatch_once_t swizzleRevenueMethodsToken;
    dispatch_once(&swizzleRevenueMethodsToken, ^{
        [LPSwizzle swizzleInstanceMethod:@selector(finishTransaction:)
                                forClass:[SKPaymentQueue class]
                   withReplacementMethod:(IMP) leanplum_finishTransaction];
    });
    [self.countAggregator incrementCount:@"track_revenue"];
}

#pragma mark - add transaction methods

- (void)addTransactionDictionary:(NSDictionary *)transaction
{
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:
                                  [NSSet setWithObjects:transaction[@"productIdentifier"], nil]];
    request.delegate = self;
    self.transactions[transaction[@"transactionIdentifier"]] = transaction;
    self.requests[[NSValue valueWithNonretainedObject:request]] = transaction[@"transactionIdentifier"];
    [request start];
}

- (void)addTransaction:(SKPaymentTransaction *)transaction
{
    NSData *receipt = nil;
    if ([[NSBundle mainBundle] respondsToSelector:@selector(appStoreReceiptURL)]) {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        receipt = [NSData dataWithContentsOfURL:receiptURL];
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        receipt = transaction.transactionReceipt;
#pragma GCC diagnostic pop
    }

    NSString *receiptBase64String = [LPUtils base64EncodedStringFromData:receipt];
    NSDictionary *transactionDictionary = @{
                                            @"transactionIdentifier":transaction.
                                            transactionIdentifier ?: [NSNull null],
                                            @"quantity":@(transaction.payment.quantity),
                                            @"productIdentifier":transaction.payment.
                                            productIdentifier,
                                            @"receiptData":receiptBase64String ?: [NSNull null]
                                            };
    [self addTransactionDictionary:transactionDictionary];
}

#pragma mark - SKProductRequest delegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    LP_TRY
    if ([response.products count] < 1) {
        return;
    }
    NSString *transactionIdentifier = self.requests[[NSValue valueWithNonretainedObject:request]];
    if (!transactionIdentifier) {
        return;
    }
    NSDictionary *transaction = self.transactions[transactionIdentifier];
    if (!transaction) {
        return;
    }
    SKProduct *product = nil;
    for (SKProduct *responseProduct in response.products) {
        if ([responseProduct.productIdentifier isEqualToString:[transaction objectForKey:@"productIdentifier"]]) {
            product = responseProduct;
            break;
        }
    }
    NSString *currencyCode = [product.priceLocale objectForKey:NSLocaleCurrencyCode];

    NSString *eventName = _eventName;
    if (!eventName) {
        eventName = LP_PURCHASE_EVENT;
    }

    [Leanplum track:eventName
          withValue:[product.price doubleValue] * [transaction[@"quantity"] integerValue]
            andArgs:@{
                      LP_PARAM_CURRENCY_CODE: currencyCode,
                      @"iOSTransactionIdentifier": transaction[@"transactionIdentifier"],
                      @"iOSReceiptData": transaction[@"receiptData"],
                      @"iOSSandbox": [NSNumber numberWithBool:[LPConstantsState sharedState].isDevelopmentModeEnabled]
                      }
      andParameters:@{
                      @"item": transaction[@"productIdentifier"],
                      @"quantity": transaction[@"quantity"]
                      }];

    [self.transactions removeObjectForKey:transactionIdentifier];
    [self saveTransactions];
    [self.requests removeObjectForKey:[NSValue valueWithNonretainedObject:request]];
    LP_END_TRY
}

@end
