//
//  SentryCrashJSONCodec_Tests.m
//
//  Created by Karl Stenerud on 2012-01-08.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
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


#import <XCTest/XCTest.h>

#import "FileBasedTestCase.h"
#import "SentryCrashJSONCodecObjC.h"
#import "SentryCrashJSONCodec.h"


@interface SentryCrashJSONCodec_Tests : FileBasedTestCase @end


@implementation SentryCrashJSONCodec_Tests

static NSData* toData(NSString* string)
{
    if(string == nil)
    {
        return nil;
    }
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

static NSString* toString(NSData* data)
{
    if(data == nil)
    {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)testSerializeDeserializeArrayEmpty
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[]";
    id original = [NSArray array];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayNull
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[null]";
    id original = [NSArray arrayWithObjects:
                   [NSNull null],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayBoolTrue
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[true]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithBool:YES],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayBoolFalse
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[false]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithBool:NO],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayInteger
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[1]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithInt:1],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayFloat
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[-0.2]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithFloat:-0.2f],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([[result objectAtIndex:0] floatValue], -0.2f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeArrayFloat2
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[-2e-15]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithFloat:-2e-15f],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([[result objectAtIndex:0] floatValue], -2e-15f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayString
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[\"One\"]";
    id original = [NSArray arrayWithObjects:
                   @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayStringIntl
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[\"テスト\"]";
    id original = [NSArray arrayWithObjects:
                   @"テスト",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayMultipleEntries
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[\"One\",1000,true]";
    id original = [NSArray arrayWithObjects:
                   @"One",
                   [NSNumber numberWithInt:1000],
                   [NSNumber numberWithBool:YES],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithArray
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[[]]";
    id original = [NSArray arrayWithObjects:
                   [NSArray array],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithArray2
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[[\"Blah\"]]";
    id original = [NSArray arrayWithObjects:
                   [NSArray arrayWithObjects:@"Blah", nil],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithDictionary
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[{}]";
    id original = [NSArray arrayWithObjects:
                   [NSDictionary dictionary],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeArrayWithDictionary2
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[{\"Blah\":true}]";
    id original = [NSArray arrayWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithBool:YES], @"Blah",
                    nil],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}


- (void)testSerializeDeserializeDictionaryEmpty
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{}";
    id original = [NSDictionary dictionary];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryNull
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":null}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNull null], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryBoolTrue
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":true}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithBool:YES], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryBoolFalse
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":false}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithBool:NO], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryInteger
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":1}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithInt:1], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryFloat
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":54.918}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithFloat:54.918f], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([[(NSDictionary*)result objectForKey:@"One"] floatValue], 54.918f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeDictionaryFloat2
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":5e+20}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSNumber numberWithFloat:5e20f], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual([[(NSDictionary*)result objectForKey:@"One"] floatValue], 5e20f, @"");
    // This always fails on NSNumber filled with float.
    //XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryString
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":\"Value\"}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"Value", @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryMultipleEntries
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":\"Value\",\"Three\":true,\"Two\":1000}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"Value", @"One",
                   [NSNumber numberWithInt:1000], @"Two",
                   [NSNumber numberWithBool:YES], @"Three",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithDictionary
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":{}}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSDictionary dictionary], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithDictionary2
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"One\":{\"Blah\":1}}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:1], @"Blah",
                    nil], @"One",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithArray
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"Key\":[]}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSArray array], @"Key",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDictionaryWithArray2
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"Blah\":[true]}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSArray arrayWithObject:[NSNumber numberWithBool:YES]], @"Blah",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeBigDictionary
{
    NSError* error = (NSError*)self;
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"0", @"0",
                   @"1", @"1",
                   @"2", @"2",
                   @"3", @"3",
                   @"4", @"4",
                   @"5", @"5",
                   @"6", @"6",
                   @"7", @"7",
                   @"8", @"8",
                   @"9", @"9",
                   @"10", @"10",
                   @"11", @"11",
                   @"12", @"12",
                   @"13", @"13",
                   @"14", @"14",
                   @"15", @"15",
                   @"16", @"16",
                   @"17", @"17",
                   @"18", @"18",
                   @"19", @"19",
                   @"20", @"20",
                   @"21", @"21",
                   @"22", @"22",
                   @"23", @"23",
                   @"24", @"24",
                   @"25", @"25",
                   @"26", @"26",
                   @"27", @"27",
                   @"28", @"28",
                   @"29", @"29",
                   @"30", @"30",
                   @"31", @"31",
                   @"32", @"32",
                   @"33", @"33",
                   @"34", @"34",
                   @"35", @"35",
                   @"36", @"36",
                   @"37", @"37",
                   @"38", @"38",
                   @"39", @"39",
                   @"40", @"40",
                   @"41", @"41",
                   @"42", @"42",
                   @"43", @"43",
                   @"44", @"44",
                   @"45", @"45",
                   @"46", @"46",
                   @"47", @"47",
                   @"48", @"48",
                   @"49", @"49",
                   @"50", @"50",
                   @"51", @"51",
                   @"52", @"52",
                   @"53", @"53",
                   @"54", @"54",
                   @"55", @"55",
                   @"56", @"56",
                   @"57", @"57",
                   @"58", @"58",
                   @"59", @"59",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void)testSerializeDeserializeDeep
{
    NSError* error = (NSError*)self;
    NSString* expected = @"{\"a0\":\"A0\",\"a1\":{\"b0\":{\"c0\":\"C0\",\"c1\":{\"d0\":[[],[],[]],\"d1\":\"D1\"}},\"b1\":\"B1\"},\"a2\":\"A2\"}";
    id original = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"A0", @"a0",
                   [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSDictionary dictionaryWithObjectsAndKeys:
                     @"C0", @"c0",
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSArray arrayWithObjects:[NSArray array], [NSArray array], [NSArray array], nil], @"d0",
                      @"D1", @"d1",
                      nil], @"c1",
                     nil], @"b0",
                    @"B1", @"b1",
                    nil], @"a1",
                   @"A2", @"a2",
                   nil];

    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testDeserializeUnicode
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"\\u00dcOne\"]";
    NSString* expected = @"\u00dcOne";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result objectAtIndex:0];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testDeserializeUnicode2
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"\\u827e\\u5c0f\\u8587\"]";
    NSString* expected = @"\u827e\u5c0f\u8587";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result objectAtIndex:0];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testDeserializeUnicodeExtended
{
    // 𐌣 = 0x10323 = 0x40,0x323 = 0xd840,0xdf23
    NSError* error = (NSError*)self;
    NSString* json = @"[\"ABC\\ud840\\udf23DEFGHIJ\"]";
    NSString* expected = @"ABC𐌣DEFGHIJ";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result objectAtIndex:0];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testDeserializeUnicodeExtendedLoneTrailSurrogate
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"ABC\\ud840DEFGHIJ\"]";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testDeserializeUnicodeExtendedMissingTrailSurrogate
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"ABC\\udf23DEFGHIJ\"]";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testDeserializeUnicodeExtendedMissingTrailSurrogate2
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"ABC\\udf23\\u1234DEFGHIJ\"]";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testDeserializeUnicodeExtendedCutOff
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"ABC\\udf23\"]";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testDeserializeControlChars
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"\\b\\f\\n\\r\\t\"]";
    NSString* expected = @"\b\f\n\r\t";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result objectAtIndex:0];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testSerializeDeserializeControlChars2
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[\"\\b\\f\\n\\r\\t\"]";
    id original = [NSArray arrayWithObjects:
                   @"\b\f\n\r\t",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeControlChars3
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[\"Testing\\b escape \\f chars\\n\"]";
    id original = [NSArray arrayWithObjects:
                   @"Testing\b escape \f chars\n",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeEscapedChars
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[\"\\\"\\\\\"]";
    id original = [NSArray arrayWithObjects:
                   @"\"\\",
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeFloat
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[1.2]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithFloat:1.2f],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([[result objectAtIndex:0] floatValue] ==  [[original objectAtIndex:0] floatValue], @"");
}

- (void) testSerializeDeserializeDouble
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[0.1]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithDouble:0.1],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([[result objectAtIndex:0] floatValue] ==  [[original objectAtIndex:0] floatValue], @"");
}

- (void) testSerializeDeserializeChar
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[20]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithChar:20],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeShort
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[2000]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithShort:2000],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeLong
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[2000000000]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithLong:2000000000],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeLongLong
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[200000000000]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithLongLong:200000000000],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeNegative
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[-2000]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithInt:-2000],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserialize0
{
    NSError* error = (NSError*)self;
    NSString* expected = @"[0]";
    id original = [NSArray arrayWithObjects:
                   [NSNumber numberWithInt:0],
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeEmptyString
{
    NSError* error = (NSError*)self;
    NSString* string = @"";
    NSString* expected = @"[\"\"]";
    id original = [NSArray arrayWithObjects:
                   string,
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeBigString
{
    NSError* error = (NSError*)self;

    int length = 500;
    NSMutableString* string = [NSMutableString stringWithCapacity:(NSUInteger)length];
    for(int i = 0; i < length; i++)
    {
        [string appendFormat:@"%d", i%10];
    }

    NSString* expected = [NSString stringWithFormat:@"[\"%@\"]", string];
    id original = [NSArray arrayWithObjects:
                   string,
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(jsonString, expected, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeHugeString
{
    NSError* error = (NSError*)self;
    char buff[5000];
    memset(buff, '2', sizeof(buff));
    buff[sizeof(buff)-1] = 0;
    NSString* string = [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];

    id original = [NSArray arrayWithObjects:
                   string,
                   nil];
    NSString* jsonString = toString([SentryCrashJSONCodec encode:original
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(jsonString, @"");
    XCTAssertNil(error, @"");
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, original, @"");
}

- (void) testSerializeDeserializeLargeArray
{
    NSError* error = (NSError*)self;
    unsigned int numEntries = 2000;

    NSMutableString* jsonString = [NSMutableString string];
    [jsonString appendString:@"["];
    for(unsigned int i = 0; i < numEntries; i++)
    {
        [jsonString appendFormat:@"%d,", i%10];
    }
    [jsonString deleteCharactersInRange:NSMakeRange([jsonString length]-1, 1)];
    [jsonString appendString:@"]"];

    NSArray* deserialized = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    unsigned int deserializedCount = (unsigned int)[deserialized count];
    XCTAssertNotNil(deserialized, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual(deserializedCount, numEntries, @"");
    NSString* serialized = toString([SentryCrashJSONCodec encode:deserialized
                                                options:0
                                                  error:&error]);
    XCTAssertNotNil(serialized, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(serialized, jsonString, @"");
    int value = [[deserialized objectAtIndex:1] intValue];
    XCTAssertEqual(value, 1, @"");
    value = [[deserialized objectAtIndex:9] intValue];
    XCTAssertEqual(value, 9, @"");
}

- (void) testSerializeDeserializeLargeDictionary
{
    NSError* error = (NSError*)self;
    unsigned int numEntries = 2000;

    NSMutableString* jsonString = [NSMutableString string];
    [jsonString appendString:@"{"];
    for(unsigned int i = 0; i < numEntries; i++)
    {
        [jsonString appendFormat:@"\"%d\":%d,", i, i];
    }
    [jsonString deleteCharactersInRange:NSMakeRange([jsonString length]-1, 1)];
    [jsonString appendString:@"}"];

    NSDictionary* deserialized = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    unsigned int deserializedCount = (unsigned int)[deserialized count];
    XCTAssertNotNil(deserialized, @"");
    XCTAssertNil(error, @"");
    XCTAssertEqual(deserializedCount, numEntries, @"");
    int value = [[(NSDictionary*)deserialized objectForKey:@"1"] intValue];
    XCTAssertEqual(value, 1, @"");
    NSString* serialized = toString([SentryCrashJSONCodec encode:deserialized
                                                options:SentryCrashJSONEncodeOptionSorted
                                                  error:&error]);
    XCTAssertNotNil(serialized, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([serialized length] == [jsonString length], @"");
}

- (void) testDeserializeArrayMissingTerminator
{
    NSError* error = (NSError*)self;
    NSString* json = @"[\"blah\"";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

//- (void) testSerializeBadTopLevelType
//{
//    NSError* error = (NSError*)self;
//    id source = @"Blah";
//    NSString* result = toString([SentryCrashJSONCodec encode:source error:&error]);
//    XCTAssertNil(result, @"");
//    XCTAssertNotNil(error, @"");
//}

- (void) testSerializeArrayBadType
{
    NSError* error = (NSError*)self;
    id source = [NSArray arrayWithObject:[NSValue valueWithPointer:NULL]];
    NSString* result = toString([SentryCrashJSONCodec encode:source
                                            options:SentryCrashJSONEncodeOptionSorted
                                              error:&error]);
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testSerializeDictionaryBadType
{
    NSError* error = (NSError*)self;
    id source = [NSDictionary dictionaryWithObject:[NSValue valueWithPointer:NULL] forKey:@"blah"];
    NSString* result = toString([SentryCrashJSONCodec encode:source
                                            options:SentryCrashJSONEncodeOptionSorted
                                              error:&error]);
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testSerializeDictionaryBadCharacter
{
    NSError* error = (NSError*)self;
    id source = [NSDictionary dictionaryWithObject:@"blah" forKey:@"blah\x01blah"];
    NSString* result = toString([SentryCrashJSONCodec encode:source
                                            options:SentryCrashJSONEncodeOptionSorted
                                              error:&error]);
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testSerializeArrayBadCharacter
{
    NSError* error = (NSError*)self;
    id source = [NSArray arrayWithObject:@"test\x01ing"];
    NSString* result = toString([SentryCrashJSONCodec encode:source
                                            options:SentryCrashJSONEncodeOptionSorted
                                              error:&error]);
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayInvalidUnicodeSequence
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"One\\ubarfTwo\"]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayInvalidUnicodeSequence2
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"One\\u123gTwo\"]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayUnterminatedEscape
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"One\\u123\"]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayUnterminatedEscape2
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"One\\\"]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayUnterminatedEscape3
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"One\\u\"]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayInvalidEscape
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"One\\qTwo\"]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayUnterminatedString
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"One]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayTruncatedFalse
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[f]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayInvalidFalse
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[falst]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayTruncatedTrue
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[t]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayInvalidTrue
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[ture]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayTruncatedNull
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[n]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayInvalidNull
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[nlll]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayInvalidElement
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[-blah]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayUnterminated
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[\"blah\"";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeArrayNumberOverflow
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"[123456789012345678901234567890]";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
}

- (void)testDeserializeDictionaryInvalidKey
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"{blah:\"blah\"}";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeDictionaryMissingSeparator
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"{\"blah\"\"blah\"}";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeDictionaryBadElement
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"{\"blah\":blah\"}";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeDictionaryUnterminated
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"{\"blah\":\"blah\"";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void)testDeserializeInvalidData
{
    NSError* error = (NSError*)self;
    NSString* jsonString = @"X{\"blah\":\"blah\"}";
    id result = [SentryCrashJSONCodec decode:toData(jsonString) options:0 error:&error];
    XCTAssertNil(result, @"");
    XCTAssertNotNil(error, @"");
}

- (void) testDeserializeArrayWithNull
{
    NSError* error = (NSError*)self;
    NSString* json = @"[null]";
    id expected = [NSNull null];
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:0
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result objectAtIndex:0];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testDeserializeArrayWithNullIgnoreNullInArray
{
    NSError* error = (NSError*)self;
    NSString* json = @"[null]";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:SentryCrashJSONDecodeOptionIgnoreNullInArray
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([result count] == 0, @"");
}

- (void) testDeserializeArrayWithNullIgnoreNullInObject
{
    NSError* error = (NSError*)self;
    NSString* json = @"[null]";
    id expected = [NSNull null];
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:SentryCrashJSONDecodeOptionIgnoreNullInObject
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result objectAtIndex:0];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testDeserializeArrayWithNullIgnoreAllNulls
{
    NSError* error = (NSError*)self;
    NSString* json = @"[null]";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:SentryCrashJSONDecodeOptionIgnoreAllNulls
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([result count] == 0, @"");
}

- (void) testDeserializeObjectWithNull
{
    NSError* error = (NSError*)self;
    NSString* json = @"{\"blah\":null}";
    id expected = [NSNull null];
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:0
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result valueForKey:@"blah"];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testDeserializeObjectWithNullIgnoreNullInArray
{
    NSError* error = (NSError*)self;
    NSString* json = @"{\"blah\":null}";
    id expected = [NSNull null];
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:SentryCrashJSONDecodeOptionIgnoreNullInArray
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    NSString* value = [result valueForKey:@"blah"];
    XCTAssertEqualObjects(value, expected, @"");
}

- (void) testDeserializeObjectWithNullIgnoreNullInObject
{
    NSError* error = (NSError*)self;
    NSString* json = @"{\"blah\":null}";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:SentryCrashJSONDecodeOptionIgnoreNullInObject
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([result count] == 0, @"");
}

- (void) testDeserializeObjectWithNullIgnoreAllNulls
{
    NSError* error = (NSError*)self;
    NSString* json = @"{\"blah\":null}";
    NSArray* result = [SentryCrashJSONCodec decode:toData(json)
                                  options:SentryCrashJSONDecodeOptionIgnoreAllNulls
                                    error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([result count] == 0, @"");
}

- (void) testFloatParsingDoesntOverflow
{
    NSError *error = (NSError*)self;

    char * buffer = malloc(0x1000000);
    for (int i = 0; i < 0x1000000; i++) {
        buffer[i] = ';';
    }

    memcpy(buffer, "{\"test\":1.1}", 12);

    NSData *data = [NSData dataWithBytesNoCopy:buffer length:0x1000000 freeWhenDone:YES];

    NSDictionary *result = [SentryCrashJSONCodec decode: data
                                    options:0
                                         error:&error];
    XCTAssertNotNil(result, @"");
    XCTAssertNil(error, @"");
    XCTAssertTrue([result count] == 1, @"");

}

static int addJSONData(const char* data, int length, void* userData)
{
    NSMutableData* nsdata = (__bridge NSMutableData*)userData;
    [nsdata appendBytes:data length:(unsigned)length];
    return SentryCrashJSON_OK;
}

- (void) serializeObject:(id) object toFile:(NSString*) filename
{
    NSError* error = nil;
    NSData* savedData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    XCTAssertNotNil(savedData);
    XCTAssertNil(error);
    XCTAssertTrue([savedData writeToFile:filename atomically:YES]);
}

- (void) expectData:(NSData*) data encodesObject:(id) expectedObject
{
    NSError* error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssertNotNil(object);
    XCTAssertNil(error);
    XCTAssertEqualObjects(object, expectedObject);
}

- (id) decodeJSON:(const char*) jsonBytes
{
    NSError* error = nil;
    NSData* jsonData = [NSData dataWithBytes:jsonBytes length:strlen(jsonBytes)];
    id object = [SentryCrashJSONCodec decode:jsonData options:SentryCrashJSONDecodeOptionKeepPartialObject error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(object);
    return object;
}

- (void) expectEquivalentJSON:(const char*) jsonCompareBytes toJSON:(const char*) jsonExpectedBytes
{
    id objectCompare = [self decodeJSON:jsonCompareBytes];
    id objectExpect = [self decodeJSON:jsonExpectedBytes];
    XCTAssertEqualObjects(objectCompare, objectExpect);
}

- (void) testAddJSONFromFile
{
    NSString* savedFilename = [self.tempPath stringByAppendingPathComponent:@"saved.json"];
    id savedObject = @{@"loaded": @"yes"};
    [self serializeObject:savedObject toFile:savedFilename];
    id expectedObject = @{@"1": @"one", @"from_file": savedObject};

    NSMutableData* encodedData = [NSMutableData data];
    SentryCrashJSONEncodeContext context = {0};
    sentrycrashjson_beginEncode(&context, false, addJSONData, (__bridge void *)(encodedData));
    sentrycrashjson_beginObject(&context, NULL);
    sentrycrashjson_addStringElement(&context, "1", "one", SentryCrashJSON_SIZE_AUTOMATIC);
    sentrycrashjson_addJSONFromFile(&context, "from_file", savedFilename.UTF8String, true);
    sentrycrashjson_endContainer(&context);
    sentrycrashjson_endEncode(&context);

    [self expectData:encodedData encodesObject:expectedObject];
}

- (void) testAddJSONFromBigFile
{
    NSString* savedFilename = [self.tempPath stringByAppendingPathComponent:@"big.json"];
    id savedObject = @{
                       @"an_array": @[@1, @2, @3, @4],
                       @"lines": @[
                               @"I cannot describe to you my sensations on the near prospect of my undertaking.",
                               @"It is impossible to communicate to you a conception of the trembling sensation, half pleasurable and half fearful, with which I am preparing to depart.",
                               @"I am going to unexplored regions, to \"the land of mist and snow,\" but I shall kill no albatross; therefore do not be alarmed for my safety or if I should come back to you as worn and woeful as the \"Ancient Mariner.\"",
                               @"You will smile at my allusion, but I will disclose a secret.",
                               @"I have often attributed my attachment to, my passionate enthusiasm for, the dangerous mysteries of ocean to that production of the most imaginative of modern poets.",
                               @"There is something at work in my soul which I do not understand.",
                               @"I am practically industrious—painstaking, a workman to execute with perseverance and labour—but besides this there is a love for the marvellous, a belief in the marvellous, intertwined in all my projects, which hurries me out of the common pathways of men, even to the wild sea and unvisited regions I am about to explore.",
                               @"But to return to dearer considerations.",
                               @"Shall I meet you again, after having traversed immense seas, and returned by the most southern cape of Africa or America? I dare not expect such success, yet I cannot bear to look on the reverse of the picture.",
                               @"Continue for the present to write to me by every opportunity: I may receive your letters on some occasions when I need them most to support my spirits.",
                               @"I love you very tenderly.",
                               @"Remember me with affection, should you never hear from me again.",
                               ],
                       };
    [self serializeObject:savedObject toFile:savedFilename];
    id expectedObject = @{@"testing": @"this", @"from_file": savedObject};

    NSMutableData* encodedData = [NSMutableData data];
    SentryCrashJSONEncodeContext context = {0};
    sentrycrashjson_beginEncode(&context, false, addJSONData, (__bridge void *)(encodedData));
    sentrycrashjson_beginObject(&context, NULL);
    sentrycrashjson_addStringElement(&context, "testing", "this", SentryCrashJSON_SIZE_AUTOMATIC);
    sentrycrashjson_addJSONFromFile(&context, "from_file", savedFilename.UTF8String, true);
    sentrycrashjson_endContainer(&context);
    sentrycrashjson_endEncode(&context);

    [self expectData:encodedData encodesObject:expectedObject];
}

- (void) testAddJSONFromBrokenFile
{
    NSString* savedFilename = [self.tempPath stringByAppendingPathComponent:@"broken.json"];
    char* savedJSON = "{"
                            "\"an_object\": {";
    char* expectedJSON = "{"
                            "\"1\": \"one\","
                            "\"from_file\": {"
                                "\"an_object\": {"
                                "}"
                            "}"
                        "}";

    NSData* data = [NSData dataWithBytes:savedJSON length:strlen(savedJSON)];
    XCTAssertTrue([data writeToFile:savedFilename atomically:YES]);

    NSError* error = nil;
    NSData* expectedObject = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:expectedJSON length:strlen(expectedJSON)] options:0 error:&error];
    XCTAssertNotNil(expectedObject);
    XCTAssertNil(error);

    NSMutableData* encodedData = [NSMutableData data];
    SentryCrashJSONEncodeContext context = {0};
    sentrycrashjson_beginEncode(&context, false, addJSONData, (__bridge void *)(encodedData));
    sentrycrashjson_beginObject(&context, NULL);
    sentrycrashjson_addStringElement(&context, "1", "one", SentryCrashJSON_SIZE_AUTOMATIC);
    sentrycrashjson_addJSONFromFile(&context, "from_file", savedFilename.UTF8String, true);
    sentrycrashjson_endContainer(&context);
    sentrycrashjson_endEncode(&context);

    [self expectData:encodedData encodesObject:expectedObject];
}

- (void) testDontCloseLastContainer
{
    char* jsonData = "{\"a\":\"1\"}";
    char* expectedJson = "{\"a_container\": {\"a\":\"1\", \"testing\":\"this\"}}";

    NSMutableData* encodedData = [NSMutableData data];
    SentryCrashJSONEncodeContext context = {0};
    sentrycrashjson_beginEncode(&context, false, addJSONData, (__bridge void *)(encodedData));
    sentrycrashjson_beginObject(&context, NULL);
    sentrycrashjson_addJSONElement(&context, "a_container", jsonData, (int)strlen(jsonData), false);
    sentrycrashjson_addStringElement(&context, "testing", "this", SentryCrashJSON_SIZE_AUTOMATIC);
    sentrycrashjson_endContainer(&context);
    sentrycrashjson_endEncode(&context);
    [encodedData appendBytes:"\0" length:1];

    [self expectEquivalentJSON:encodedData.bytes toJSON:expectedJson];
}

@end
