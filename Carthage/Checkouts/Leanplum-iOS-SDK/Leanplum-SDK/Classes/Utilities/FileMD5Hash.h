//
//  FileMD5Hash.h
//  Leanplum
//
//  Created by Andrew First on 5/29/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
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

#ifndef Leanplum_FileMD5Hash_h
#define Leanplum_FileMD5Hash_h

// In bytes
#define FileHashDefaultChunkSizeForReadingData 4096

// Core Foundation
#include <CoreFoundation/CoreFoundation.h>

CFStringRef Leanplum_FileMD5HashCreateWithPath(CFStringRef filePath,
                                               size_t chunkSizeForReadingData);

#endif
