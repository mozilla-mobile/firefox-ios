/*
 * Copyright 2008-2014, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// original at https://github.com/tcurdt/feedbackreporter/blob/master/Sources/Main/FRSystemProfile.h

#import <Foundation/Foundation.h>

@interface ADJSystemProfile : NSObject

+ (BOOL) is64bit;
+ (NSString*) cpuFamily;
+ (NSString*) osVersion;
+ (int) cpuCount;
+ (NSString*) machineArch;
+ (NSString*) machineModel;
+ (NSString*) cpuBrand;
+ (NSString*) cpuFeatures;
+ (NSString*) cpuVendor;
+ (NSString*) appleLanguage;
+ (long long) cpuSpeed;
+ (long long) ramsize;
+ (NSString*) cpuType;
+ (NSString*) cpuSubtype;
@end
