//
//  ATLConstants.h
//  AdjustTestLibrary
//
//  Created by Pedro on 20.04.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#ifndef ATLConstants_h
#define ATLConstants_h

static int const ONE_SECOND = 1000;
static int const ONE_MINUTE = 60 * ONE_SECOND;

static NSString * const TEST_LIBRARY_CLASSNAME  = @"TestLibrary";
static NSString * const ADJUST_CLASSNAME        = @"Adjust";
static NSString * const WAIT_FOR_CONTROL        = @"control";
static NSString * const WAIT_FOR_SLEEP          = @"sleep";
static NSString * const BASE_PATH_PARAM         = @"basePath";
static NSString * const TEST_NAME_PARAM         = @"basePath";
static NSString * const TEST_SESSION_ID_HEADER  = @"Test-Session-Id";

// web socket values
static NSString * const SIGNAL_INFO                = @"info";
static NSString * const SIGNAL_INIT_TEST_SESSION   = @"init-test-session";
static NSString * const SIGNAL_END_WAIT            = @"end-wait";
static NSString * const SIGNAL_CANCEL_CURRENT_TEST = @"cancel-current-test";
static NSString * const SIGNAL_UNKNOWN             = @"unknown";

#endif /* ATLConstants_h */
