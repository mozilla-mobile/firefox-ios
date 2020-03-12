//
//  SentryCrashFileUtils_Tests.m
//
//  Created by Karl Stenerud on 2012-01-28.
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


#import "FileBasedTestCase.h"
#include <stdio.h>
#include <fcntl.h>

#import "SentryCrashFileUtils.h"


@interface SentryCrashFileUtils_Tests : FileBasedTestCase @end


@implementation SentryCrashFileUtils_Tests

- (void) testReadBuffered_EmptyFile
{
    int readBufferSize = 10;
    int dstBufferSize = 5;
    int readSize = 5;
    int expectedBytesRead = 0;
    NSString* fileContents = @"";
    NSString* expectedDataRead = @"";
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    int bytesRead = sentrycrashfu_readBufferedReader(&reader, dstBuffer, readSize);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBuffered_SameSize
{
    int readBufferSize = 10;
    int dstBufferSize = 5;
    int readSize = 5;
    int expectedBytesRead = 5;
    NSString* fileContents = @"12345";
    NSString* expectedDataRead = @"12345";
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    int bytesRead = sentrycrashfu_readBufferedReader(&reader, dstBuffer, readSize);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBuffered_FileIsBigger
{
    int readBufferSize = 10;
    int dstBufferSize = 5;
    int readSize = 5;
    int expectedBytesRead = 5;
    NSString* fileContents = @"123456789";
    NSString* expectedDataRead = @"12345";
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    int bytesRead = sentrycrashfu_readBufferedReader(&reader, dstBuffer, readSize);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBuffered_ReadBufferIsSmaller
{
    int readBufferSize = 3;
    int dstBufferSize = 5;
    int readSize = 5;
    int expectedBytesRead = 5;
    NSString* fileContents = @"12345";
    NSString* expectedDataRead = @"12345";
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    int bytesRead = sentrycrashfu_readBufferedReader(&reader, dstBuffer, readSize);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBuffered_ReadBufferIsMuchSmaller
{
    int readBufferSize = 3;
    int dstBufferSize = 16;
    int readSize = 16;
    int expectedBytesRead = 16;
    NSString* fileContents = @"1234567890abcdef";
    NSString* expectedDataRead = @"1234567890abcdef";
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    int bytesRead = sentrycrashfu_readBufferedReader(&reader, dstBuffer, readSize);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBufferedUntilChar_Halfway
{
    int readBufferSize = 10;
    int dstBufferSize = 5;
    NSString* fileContents = @"12345";
    int ch = '3';
    NSString* expectedDataRead = @"123";
    int expectedBytesRead = (int)expectedDataRead.length;
    int bytesRead = dstBufferSize;
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    bool result = sentrycrashfu_readBufferedReaderUntilChar(&reader, ch, dstBuffer, &bytesRead);
    XCTAssertTrue(result);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBufferedUntilChar_Beginning
{
    int readBufferSize = 10;
    int dstBufferSize = 5;
    NSString* fileContents = @"12345";
    int ch = '1';
    NSString* expectedDataRead = @"1";
    int expectedBytesRead = (int)expectedDataRead.length;
    int bytesRead = dstBufferSize;
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    bool result = sentrycrashfu_readBufferedReaderUntilChar(&reader, ch, dstBuffer, &bytesRead);
    XCTAssertTrue(result);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBufferedUntilChar_End
{
    int readBufferSize = 10;
    int dstBufferSize = 5;
    NSString* fileContents = @"12345";
    int ch = '5';
    NSString* expectedDataRead = @"12345";
    int expectedBytesRead = (int)expectedDataRead.length;
    int bytesRead = dstBufferSize;
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    bool result = sentrycrashfu_readBufferedReaderUntilChar(&reader, ch, dstBuffer, &bytesRead);
    XCTAssertTrue(result);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBufferedUntilChar_SmallDstBuffer
{
    int readBufferSize = 10;
    int dstBufferSize = 3;
    NSString* fileContents = @"12345";
    int ch = '5';
    NSString* expectedDataRead = @"123";
    int expectedBytesRead = (int)expectedDataRead.length;
    int bytesRead = dstBufferSize;
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    bool result = sentrycrashfu_readBufferedReaderUntilChar(&reader, ch, dstBuffer, &bytesRead);
    XCTAssertTrue(result);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBufferedUntilChar_SmallReadBuffer
{
    int readBufferSize = 4;
    int dstBufferSize = 10;
    NSString* fileContents = @"1234567890";
    int ch = '9';
    NSString* expectedDataRead = @"123456789";
    int expectedBytesRead = (int)expectedDataRead.length;
    int bytesRead = dstBufferSize;
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    bool result = sentrycrashfu_readBufferedReaderUntilChar(&reader, ch, dstBuffer, &bytesRead);
    XCTAssertTrue(result);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBufferedUntilChar_NotFound
{
    int readBufferSize = 3;
    int dstBufferSize = 8;
    NSString* fileContents = @"12345";
    int ch = '9';
    NSString* expectedDataRead = @"12345";
    int expectedBytesRead = (int)expectedDataRead.length;
    int bytesRead = dstBufferSize;
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    bool result = sentrycrashfu_readBufferedReaderUntilChar(&reader, ch, dstBuffer, &bytesRead);
    XCTAssertFalse(result);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testReadBufferedUntilChar_NotFound_LargeFile
{
    int readBufferSize = 4;
    int dstBufferSize = 8;
    NSString* fileContents = @"1234567890";
    int ch = 'a';
    NSString* expectedDataRead = @"12345678";
    int expectedBytesRead = (int)expectedDataRead.length;
    int bytesRead = dstBufferSize;
    char readBuffer[readBufferSize];
    SentryCrashBufferedReader reader;
    NSString* path = [self generateFileWithString:fileContents];
    XCTAssertTrue(sentrycrashfu_openBufferedReader(&reader, path.UTF8String, readBuffer, readBufferSize));
    char dstBuffer[dstBufferSize + 1];
    bool result = sentrycrashfu_readBufferedReaderUntilChar(&reader, ch, dstBuffer, &bytesRead);
    XCTAssertFalse(result);
    XCTAssertEqual(bytesRead, expectedBytesRead);
    dstBuffer[bytesRead] = '\0';
    XCTAssertEqualObjects([NSString stringWithUTF8String:dstBuffer], expectedDataRead);
    sentrycrashfu_closeBufferedReader(&reader);
}

- (void) testWriteBuffered
{
    int writeBufferSize = 5;
    int writeSize = 5;
    NSString* fileContents = @"12345";
    char writeBuffer[writeBufferSize];
    SentryCrashBufferedWriter writer;
    NSString* path = [self generateTempFilePath];
    XCTAssertTrue(sentrycrashfu_openBufferedWriter(&writer, path.UTF8String, writeBuffer, writeBufferSize));
    XCTAssertTrue(sentrycrashfu_writeBufferedWriter(&writer, fileContents.UTF8String, writeSize));
    sentrycrashfu_closeBufferedWriter(&writer);
    NSError* error = nil;
    NSString* actualFileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(actualFileContents, fileContents);
}

- (void) testWriteBuffered_Flush
{
    int writeBufferSize = 5;
    int writeSize = 5;
    NSString* fileContents = @"12345";
    char writeBuffer[writeBufferSize];
    SentryCrashBufferedWriter writer;
    NSString* path = [self generateTempFilePath];
    XCTAssertTrue(sentrycrashfu_openBufferedWriter(&writer, path.UTF8String, writeBuffer, writeBufferSize));
    XCTAssertTrue(sentrycrashfu_writeBufferedWriter(&writer, fileContents.UTF8String, writeSize));
    sentrycrashfu_flushBufferedWriter(&writer);
    NSError* error = nil;
    NSString* actualFileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(actualFileContents, fileContents);
    sentrycrashfu_closeBufferedWriter(&writer);
}

- (void) testWriteBuffered_BufferIsSmaller
{
    int writeBufferSize = 4;
    int writeSize = 10;
    NSString* fileContents = @"1234567890";
    char writeBuffer[writeBufferSize];
    SentryCrashBufferedWriter writer;
    NSString* path = [self generateTempFilePath];
    XCTAssertTrue(sentrycrashfu_openBufferedWriter(&writer, path.UTF8String, writeBuffer, writeBufferSize));
    XCTAssertTrue(sentrycrashfu_writeBufferedWriter(&writer, fileContents.UTF8String, writeSize));
    sentrycrashfu_closeBufferedWriter(&writer);
    NSError* error = nil;
    NSString* actualFileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(actualFileContents, fileContents);
}

- (void) testWriteBuffered_DataIsSmaller
{
    int writeBufferSize = 10;
    int writeSize = 3;
    NSString* fileContents = @"123";
    char writeBuffer[writeBufferSize];
    SentryCrashBufferedWriter writer;
    NSString* path = [self generateTempFilePath];
    XCTAssertTrue(sentrycrashfu_openBufferedWriter(&writer, path.UTF8String, writeBuffer, writeBufferSize));
    XCTAssertTrue(sentrycrashfu_writeBufferedWriter(&writer, fileContents.UTF8String, writeSize));
    sentrycrashfu_closeBufferedWriter(&writer);
    NSError* error = nil;
    NSString* actualFileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(actualFileContents, fileContents);
}

- (void) testLastPathEntry
{
    NSString* path = @"some/kind/of/path";
    NSString* expected = @"path";
    NSString* actual = [NSString stringWithCString:sentrycrashfu_lastPathEntry([path cStringUsingEncoding:NSUTF8StringEncoding])
                                          encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testWriteBytesToFD
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* expected = @"testing a bunch of stuff.\nOh look, a newline!";
    int stringLength = (int)[expected length];

    int fd = open([path UTF8String], O_RDWR | O_CREAT | O_EXCL, 0644);
    XCTAssertTrue(fd >= 0, @"");
    bool result = sentrycrashfu_writeBytesToFD(fd, [expected cStringUsingEncoding:NSUTF8StringEncoding], stringLength);
    XCTAssertTrue(result, @"");
    NSString* actual = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testWriteBytesToFDBig
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    int length = 1000000;
    NSMutableData* expected = [NSMutableData dataWithCapacity:(NSUInteger)length];
    for(int i = 0; i < length; i++)
    {
        unsigned char byte = (unsigned char)i;
        [expected appendBytes:&byte length:1];
    }

    int fd = open([path UTF8String], O_RDWR | O_CREAT | O_EXCL, 0644);
    XCTAssertTrue(fd >= 0, @"");
    bool result = sentrycrashfu_writeBytesToFD(fd, [expected bytes], length);
    XCTAssertTrue(result, @"");
    NSMutableData* actual = [NSMutableData dataWithContentsOfFile:path options:0 error:&error];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testReadBytesFromFD
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* expected = @"testing a bunch of stuff.\nOh look, a newline!";
    int stringLength = (int)[expected length];
    [expected writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");

    int fd = open([path UTF8String], O_RDONLY);
    XCTAssertTrue(fd >= 0, @"");
    NSMutableData* data = [NSMutableData dataWithLength:(NSUInteger)stringLength];
    bool result = sentrycrashfu_readBytesFromFD(fd, [data mutableBytes], stringLength);
    XCTAssertTrue(result, @"");
    NSString* actual = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testReadBytesFromFDBig
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    int length = 1000000;
    NSMutableData* expected = [NSMutableData dataWithCapacity:(NSUInteger)length];
    for(int i = 0; i < length; i++)
    {
        unsigned char byte = (unsigned char)i;
        [expected appendBytes:&byte length:1];
    }
    [expected writeToFile:path options:0 error:&error];
    XCTAssertNil(error, @"");

    int fd = open([path UTF8String], O_RDONLY);
    XCTAssertTrue(fd >= 0, @"");
    NSMutableData* actual = [NSMutableData dataWithLength:(NSUInteger)length];
    bool result = sentrycrashfu_readBytesFromFD(fd, [actual mutableBytes], length);
    XCTAssertTrue(result, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testReadEntireFile
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* expected = @"testing a bunch of stuff.\nOh look, a newline!";
    [expected writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");

    int fd = open([path UTF8String], O_RDONLY);
    XCTAssertTrue(fd >= 0, @"");
    char* bytes;
    int readLength;
    bool result = sentrycrashfu_readEntireFile([path UTF8String], &bytes, &readLength, 0);
    XCTAssertTrue(result, @"");
    NSMutableData* data = [NSMutableData dataWithBytesNoCopy:bytes length:(unsigned)readLength freeWhenDone:YES];
    NSString* actual = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testReadEntireFileBig
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    int length = 1000000;
    NSMutableData* expected = [NSMutableData dataWithCapacity:(NSUInteger)length];
    for(int i = 0; i < length; i++)
    {
        unsigned char byte = (unsigned char)i;
        [expected appendBytes:&byte length:1];
    }
    [expected writeToFile:path options:0 error:&error];
    XCTAssertNil(error, @"");

    int fd = open([path UTF8String], O_RDONLY);
    XCTAssertTrue(fd >= 0, @"");
    char* bytes;
    int readLength;
    bool result = sentrycrashfu_readEntireFile([path UTF8String], &bytes, &readLength, 0);
    XCTAssertTrue(result, @"");
    NSMutableData* actual = [NSMutableData dataWithBytesNoCopy:bytes length:(unsigned)readLength freeWhenDone:YES];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testWriteStringToFD
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* expected = @"testing a bunch of stuff.\nOh look, a newline!";

    int fd = open([path UTF8String], O_RDWR | O_CREAT | O_EXCL, 0644);
    XCTAssertTrue(fd >= 0, @"");
    bool result = sentrycrashfu_writeStringToFD(fd, [expected cStringUsingEncoding:NSUTF8StringEncoding]);
    XCTAssertTrue(result, @"");
    NSString* actual = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testWriteFmtToFD
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* expected = @"test test testing 1 2.0 3";

    int fd = open([path UTF8String], O_RDWR | O_CREAT | O_EXCL, 0644);
    XCTAssertTrue(fd >= 0, @"");
    bool result = sentrycrashfu_writeFmtToFD(fd, "test test testing %d %.1f %s", 1, 2.0f, "3");
    XCTAssertTrue(result, @"");
    NSString* actual = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (bool) writeToFD:(int) fd fmt:(char*) fmt, ...
{
    va_list args;
    va_start(args, fmt);
    bool result = sentrycrashfu_writeFmtArgsToFD(fd, fmt, args);
    va_end(args);
    return result;
}

- (void) testWriteFmtArgsToFD
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* expected = @"test test testing 1 2.0 3";

    int fd = open([path UTF8String], O_RDWR | O_CREAT | O_EXCL, 0644);
    XCTAssertTrue(fd >= 0, @"");
    bool result = [self writeToFD:fd fmt: "test test testing %d %.1f %s", 1, 2.0f, "3"];
    XCTAssertTrue(result, @"");
    NSString* actual = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testReadLineFromFD
{
    NSError* error = nil;
    NSString* path = [self.tempPath stringByAppendingPathComponent:@"test.txt"];
    NSString* source = @"line 1\nline 2\nline 3";
    NSString* expected1 = @"line 1";
    NSString* expected2 = @"line 2";
    NSString* expected3 = @"line 3";
    [source writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");

    int fd = open([path UTF8String], O_RDONLY);
    XCTAssertTrue(fd >= 0, @"");
    NSMutableData* data = [NSMutableData dataWithLength:100];
    int bytesRead;
    NSString* actual;

    bytesRead = sentrycrashfu_readLineFromFD(fd, [data mutableBytes], 100);
    XCTAssertTrue(bytesRead > 0, @"");
    actual = [[NSString alloc] initWithBytes:[data bytes]
                                      length:(NSUInteger)bytesRead
                                    encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected1, @"");

    bytesRead = sentrycrashfu_readLineFromFD(fd, [data mutableBytes], 100);
    XCTAssertTrue(bytesRead > 0, @"");
    actual = [[NSString alloc] initWithBytes:[data bytes]
                                      length:(NSUInteger)bytesRead
                                    encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected2, @"");

    bytesRead = sentrycrashfu_readLineFromFD(fd, [data mutableBytes], 100);
    XCTAssertTrue(bytesRead > 0, @"");
    actual = [[NSString alloc] initWithBytes:[data bytes]
                                      length:(NSUInteger)bytesRead
                                    encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected3, @"");

    bytesRead = sentrycrashfu_readLineFromFD(fd, [data mutableBytes], 100);
    XCTAssertTrue(bytesRead == 0, @"");
}

@end
