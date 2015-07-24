//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright (c) 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

@import Foundation;

typedef struct SQLiteHandle SQLiteHandle;
typedef struct SQLiteContext SQLiteContext;
typedef struct SQLiteValue SQLiteValue;

typedef int (^_SQLiteBusyHandlerCallback)(int times);
int _SQLiteBusyHandler(SQLiteHandle * handle, _SQLiteBusyHandlerCallback callback);

typedef void (^_SQLiteTraceCallback)(const char * SQL);
void _SQLiteTrace(SQLiteHandle * handle, _SQLiteTraceCallback callback);

typedef void (^_SQLiteUpdateHookCallback)(int operation, const char * db, const char * table, long long rowid);
void _SQLiteUpdateHook(SQLiteHandle * handle, _SQLiteUpdateHookCallback callback);

typedef int (^_SQLiteCommitHookCallback)();
void _SQLiteCommitHook(SQLiteHandle * handle, _SQLiteCommitHookCallback callback);

typedef void (^_SQLiteRollbackHookCallback)();
void _SQLiteRollbackHook(SQLiteHandle * handle, _SQLiteRollbackHookCallback callback);

typedef void (^_SQLiteCreateFunctionCallback)(SQLiteContext * context, int argc, SQLiteValue ** argv);
int _SQLiteCreateFunction(SQLiteHandle * handle, const char * name, int argc, int deterministic, _SQLiteCreateFunctionCallback callback);

typedef int (^_SQLiteCreateCollationCallback)(const char * lhs, const char * rhs);
int _SQLiteCreateCollation(SQLiteHandle * handle, const char * name, _SQLiteCreateCollationCallback callback);

typedef NSString * (^_SQLiteTokenizerNextCallback)(const char * input, int * inputOffset, int * inputLength);
int _SQLiteRegisterTokenizer(SQLiteHandle * db, const char * module, const char * tokenizer, _SQLiteTokenizerNextCallback callback);
