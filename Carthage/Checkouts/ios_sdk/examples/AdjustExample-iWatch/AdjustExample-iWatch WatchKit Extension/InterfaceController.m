//
//  InterfaceController.m
//  AdjustExample-iWatch WatchKit Extension
//
//  Created by Uglješa Erceg on 06/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "TableRowController.h"
#import "InterfaceController.h"
#import <WatchConnectivity/WatchConnectivity.h>

@import WatchKit;

@interface InterfaceController() <WCSessionDelegate>

@property (nonatomic, weak) IBOutlet WKInterfaceTable *wkTblEventTable;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    [_wkTblEventTable setNumberOfRows:4 withRowType:@"TableRowController"];

    TableRowController *row1 = [_wkTblEventTable rowControllerAtIndex:0];
    TableRowController *row2 = [_wkTblEventTable rowControllerAtIndex:1];
    TableRowController *row3 = [_wkTblEventTable rowControllerAtIndex:2];
    TableRowController *row4 = [_wkTblEventTable rowControllerAtIndex:3];

    [row1.wkLblTitle setText:@"Simple Event"];
    [row2.wkLblTitle setText:@"Revenue Event"];
    [row3.wkLblTitle setText:@"Callback Event"];
    [row4.wkLblTitle setText:@"Partner Event"];
}

- (void)willActivate {
    [super willActivate];

    if ([WCSession isSupported]) {
        WCSession *session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    switch (rowIndex) {
        case 0: {
            NSDictionary *requst = @{@"request":@"event_simple"};

            [[WCSession defaultSession] sendMessage:requst
                                       replyHandler:^(NSDictionary *reply) {
                                           NSString *message = @"";

                                           if ([[reply objectForKey:@"response"] isEqualToString:@"ack"]) {
                                               // Event successfully tracked.
                                               message = @"Simple event tracked!";
                                           } else {
                                               // Event failed to be tracked.
                                               message = @"Simple event not tracked!";
                                           }
                                           
                                           [self pushControllerWithName:@"EventTrackedController" context:message];
                                       }
                                       errorHandler:^(NSError *error) {
                                           NSLog(@"%@", error);
                                       }
             ];

            break;
        }
        case 1: {
            NSDictionary *requst = @{@"request":@"event_revenue"};

            [[WCSession defaultSession] sendMessage:requst
                                       replyHandler:^(NSDictionary *reply) {
                                           NSString *message = @"";

                                           if ([[reply objectForKey:@"response"] isEqualToString:@"ack"]) {
                                               // Event successfully tracked.
                                               message = @"Revenue event tracked!";
                                           } else {
                                               // Event failed to be tracked.
                                               message = @"Revenue event not tracked!";
                                           }

                                           [self pushControllerWithName:@"EventTrackedController" context:message];
                                       }
                                       errorHandler:^(NSError *error) {
                                           NSLog(@"%@", error);
                                       }
             ];

            break;
        }
        case 2: {
            NSDictionary *requst = @{@"request":@"event_callback"};

            [[WCSession defaultSession] sendMessage:requst
                                       replyHandler:^(NSDictionary *reply) {
                                           NSString *message = @"";

                                           if ([[reply objectForKey:@"response"] isEqualToString:@"ack"]) {
                                               // Event successfully tracked.
                                               message = @"Callback event tracked!";
                                           } else {
                                               // Event failed to be tracked.
                                               message = @"Callback event not tracked!";
                                           }

                                           [self pushControllerWithName:@"EventTrackedController" context:message];
                                       }
                                       errorHandler:^(NSError *error) {
                                           NSLog(@"%@", error);
                                       }
             ];

            break;
        }
        case 3: {
            NSDictionary *requst = @{@"request":@"event_partner"};

            [[WCSession defaultSession] sendMessage:requst
                                       replyHandler:^(NSDictionary *reply) {
                                           NSString *message = @"";

                                           if ([[reply objectForKey:@"response"] isEqualToString:@"ack"]) {
                                               // Event successfully tracked.
                                               message = @"Partner event tracked!";
                                           } else {
                                               // Event failed to be tracked.
                                               message = @"Partner event not tracked!";
                                           }

                                           [self pushControllerWithName:@"EventTrackedController" context:message];
                                       }
                                       errorHandler:^(NSError *error) {
                                           NSLog(@"%@", error);
                                       }
             ];
            
            break;
        }
        default:
            break;
    }
}

// watchOS 1.x
/*
- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    switch (rowIndex) {
        case 0: {
            NSDictionary *requst = @{@"request":@"event_simple"};

            [InterfaceController openParentApplication:requst reply:^(NSDictionary *replyInfo, NSError *error) {

                if (error) {
                    NSLog(@"%@", error);
                } else {
                    NSString *message = @"";

                    if ([[replyInfo objectForKey:@"response"] isEqualToString:@"ack"]) {
                        // Event successfully tracked.
                        message = @"Simple event tracked!";
                    } else {
                        // Event failed to be tracked.
                        message = @"Simple event not tracked!";
                    }

                    [self pushControllerWithName:@"EventTrackedController" context:message];
                }

            }];

            break;
        }
        case 1: {
            NSDictionary *requst = @{@"request":@"event_revenue"};

            [InterfaceController openParentApplication:requst reply:^(NSDictionary *replyInfo, NSError *error) {

                if (error) {
                    NSLog(@"%@", error);
                } else {
                    NSString *message = @"";

                    if ([[replyInfo objectForKey:@"response"] isEqualToString:@"ack"]) {
                        // Event successfully tracked.
                        message = @"Revenue event tracked!";
                    } else {
                        // Event failed to be tracked.
                        message = @"Revenue event not tracked!";
                    }

                    [self pushControllerWithName:@"EventTrackedController" context:message];
                }

            }];

            break;
        }
        case 2: {
            NSDictionary *requst = @{@"request":@"event_callback"};

            [InterfaceController openParentApplication:requst reply:^(NSDictionary *replyInfo, NSError *error) {

                if (error) {
                    NSLog(@"%@", error);
                } else {
                    NSString *message = @"";

                    if ([[replyInfo objectForKey:@"response"] isEqualToString:@"ack"]) {
                        // Event successfully tracked.
                        message = @"Callback event tracked!";
                    } else {
                        // Event failed to be tracked.
                        message = @"Callback event not tracked!";
                    }

                    [self pushControllerWithName:@"EventTrackedController" context:message];
                }

            }];

            break;
        }
        case 3: {
            NSDictionary *requst = @{@"request":@"event_partner"};

            [InterfaceController openParentApplication:requst reply:^(NSDictionary *replyInfo, NSError *error) {

                if (error) {
                    NSLog(@"%@", error);
                } else {
                    NSString *message = @"";

                    if ([[replyInfo objectForKey:@"response"] isEqualToString:@"ack"]) {
                        // Event successfully tracked.
                        message = @"Partner event tracked!";
                    } else {
                        // Event failed to be tracked.
                        message = @"Partner event not tracked!";
                    }
                    
                    [self pushControllerWithName:@"EventTrackedController" context:message];
                }
                
            }];
            
            break;
        }
        default:
            break;
    }
}
*/

@end
