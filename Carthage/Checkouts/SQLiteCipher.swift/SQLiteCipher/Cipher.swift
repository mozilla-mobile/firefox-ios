//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
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

import SQLite3

extension Connection {
    
    public func key(key: String) throws {
        try check(sqlite3_key(handle, key, Int32(key.utf8.count)))
        try execute(
            "CREATE TABLE \"__SQLCipher.swift__\" (\"cipher key check\");\n" +
            "DROP TABLE \"__SQLCipher.swift__\";"
        )
    }
    
    public func rekey(key: String) throws {
        try check(sqlite3_rekey(handle, key, Int32(key.utf8.count)))
    }
    
    public func key(key: Blob) throws {
        try check(sqlite3_key(handle, key.bytes, Int32(key.bytes.count)))
        try execute(
            "CREATE TABLE \"__SQLCipher.swift__\" (\"cipher key check\");\n" +
            "DROP TABLE \"__SQLCipher.swift__\";"
        )
    }
    
    public func rekey(key: Blob) throws {
        try check(sqlite3_rekey(handle, key.bytes, Int32(key.bytes.count)))
    }
    
}
