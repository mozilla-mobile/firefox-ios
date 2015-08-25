//
//  KIF.h
//  KIF
//
//  Created by Jim Puls on 12/21/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "KIFTestActor.h"
#import "KIFTestCase.h"
#import "KIFSystemTestActor.h"
#import "KIFUITestActor.h"
#import "KIFUITestActor-ConditionalTests.h"

#ifndef KIF_SENTEST
#import "XCTestCase-KIFAdditions.h"
#else
#import "SenTestCase-KIFAdditions.h"
#endif
