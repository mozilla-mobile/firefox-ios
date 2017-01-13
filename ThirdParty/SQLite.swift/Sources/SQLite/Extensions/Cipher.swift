#if SQLITE_SWIFT_SQLCIPHER
import SQLCipher


/// Extension methods for [SQLCipher](https://www.zetetic.net/sqlcipher/).
/// @see [sqlcipher api](https://www.zetetic.net/sqlcipher/sqlcipher-api/)
extension Connection {

    /// Specify the key for an encrypted database.  This routine should be
    /// called right after sqlite3_open().
    ///
    /// @param key The key to use.The key itself can be a passphrase, which is converted to a key
    ///            using [PBKDF2](https://en.wikipedia.org/wiki/PBKDF2) key derivation. The result
    ///            is used as the encryption key for the database.
    ///
    ///            Alternatively, it is possible to specify an exact byte sequence using a blob literal.
    ///            With this method, it is the calling application's responsibility to ensure that the data
    ///            provided is a 64 character hex string, which will be converted directly to 32 bytes (256 bits)
    ///            of key data.
    ///            e.g. x'2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99'
    /// @param db name of the database, defaults to 'main'
    public func key(_ key: String, db: String = "main") throws {
        try _key_v2(db: db, keyPointer: key, keySize: key.utf8.count)
    }

    public func key(_ key: Blob, db: String = "main") throws {
        try _key_v2(db: db, keyPointer: key.bytes, keySize: key.bytes.count)
    }


    /// Change the key on an open database.  If the current database is not encrypted, this routine
    /// will encrypt it.
    /// To change the key on an existing encrypted database, it must first be unlocked with the
    /// current encryption key. Once the database is readable and writeable, rekey can be used
    /// to re-encrypt every page in the database with a new key.
    public func rekey(_ key: String, db: String = "main") throws {
        try _rekey_v2(db: db, keyPointer: key, keySize: key.utf8.count)
    }

    public func rekey(_ key: Blob, db: String = "main") throws {
        try _rekey_v2(db: db, keyPointer: key.bytes, keySize: key.bytes.count)
    }

    // MARK: - private
    private func _key_v2(db: String, keyPointer: UnsafePointer<UInt8>, keySize: Int) throws {
        try check(sqlite3_key_v2(handle, db, keyPointer, Int32(keySize)))
        try cipher_key_check()
    }

    private func _rekey_v2(db: String, keyPointer: UnsafePointer<UInt8>, keySize: Int) throws {
        try check(sqlite3_rekey_v2(handle, db, keyPointer, Int32(keySize)))
    }

    // When opening an existing database, sqlite3_key_v2 will not immediately throw an error if
    // the key provided is incorrect. To test that the database can be successfully opened with the
    // provided key, it is necessary to perform some operation on the database (i.e. read from it).
    private func cipher_key_check() throws {
        try scalar("SELECT count(*) FROM sqlite_master;")
    }
}
#endif
