//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Common/GREYLogger.h"

#import "Additions/NSError+GREYAdditions.h"
#import "Additions/XCTestCase+GREYAdditions.h"
#import "Common/GREYError+Internal.h"
#import "Common/GREYError.h"
#import "Common/GREYFailureFormatter.h"
#import "Common/GREYFailureScreenshotter.h"
#import "Common/GREYObjectFormatter.h"
#import "Common/GREYThrowDefines.h"

void I_GREYLogError(NSError *error,
                    NSString *filePath,
                    NSUInteger lineNumber,
                    NSString *functionName,
                    NSArray *stackTrace) {
  if (!error) {
    NSLog(@"No error specified");
    return;
  }

  GREYError *errorObject;
  if ([error isKindOfClass:[GREYError class]]) {
    errorObject = (GREYError *)error;
  } else {
    errorObject = I_GREYErrorMake(error.domain,
                                  error.code,
                                  error.userInfo,
                                  filePath,
                                  lineNumber,
                                  functionName,
                                  nil,
                                  stackTrace);

    errorObject.appScreenshots =
        [GREYFailureScreenshotter generateAppScreenshotsWithPrefix:nil
                                                           failure:@"Error"];
  }

  NSString *errorDetail = [GREYError grey_nestedDescriptionForError:error];
  NSString *errorContent = [GREYFailureFormatter formatFailureForError:errorObject
                                                             excluding:nil
                                                          failureLabel:@"Error"
                                                           failureName:@"Error To Log"
                                                                format:@"%@", errorDetail];
  NSLog(@"%@", errorContent);
}
