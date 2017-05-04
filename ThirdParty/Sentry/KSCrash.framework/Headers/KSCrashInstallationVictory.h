//
//  KSCrashInstallationVictory.h
//
//  Created by Kelp on 2013-03-14.
//
//  Copyright (c) 2013 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "KSCrashInstallation.h"


/**
 Victory is an error reporting server in Python. It runs on Google App Engine.
 https://github.com/kelp404/Victory
 
 You could download this project and then deploy to GAE with free plan.
 Your app could send error information to Victory with RESTful API.
 This is a demo site: https://victory-demo.appspot.com/
 */
@interface KSCrashInstallationVictory : KSCrashInstallation

/** The URL to connect to. */
@property(nonatomic,readwrite,retain) NSURL* url;
/** The user name of crash information *required. If value is nil it will be replaced with UIDevice.currentDevice.name */
@property(nonatomic,readwrite,retain) NSString* userName;
/** The user email of crash information *optional */
@property(nonatomic,readwrite,retain) NSString* userEmail;

+ (instancetype) sharedInstance;

@end
