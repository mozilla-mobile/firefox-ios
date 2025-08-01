// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!

// swiftlint:disable all
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(MozillaRustComponents)
import MozillaRustComponents
#endif

fileprivate extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func empty() -> RustBuffer {
        RustBuffer(capacity: 0, len:0, data: nil)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_context_id_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_context_id_rustbuffer_free(self, $0) }
    }
}

fileprivate extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a library of its own.

fileprivate extension Data {
    init(rustBuffer: RustBuffer) {
        self.init(
            bytesNoCopy: rustBuffer.data!,
            count: Int(rustBuffer.len),
            deallocator: .none
        )
    }
}

// Define reader functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.
//
// With external types, one swift source file needs to be able to call the read
// method on another source file's FfiConverter, but then what visibility
// should Reader have?
// - If Reader is fileprivate, then this means the read() must also
//   be fileprivate, which doesn't work with external types.
// - If Reader is internal/public, we'll get compile errors since both source
//   files will try define the same type.
//
// Instead, the read() method and these helper functions input a tuple of data

fileprivate func createReader(data: Data) -> (data: Data, offset: Data.Index) {
    (data: data, offset: 0)
}

// Reads an integer at the current offset, in big-endian order, and advances
// the offset on success. Throws if reading the integer would move the
// offset past the end of the buffer.
fileprivate func readInt<T: FixedWidthInteger>(_ reader: inout (data: Data, offset: Data.Index)) throws -> T {
    let range = reader.offset..<reader.offset + MemoryLayout<T>.size
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    if T.self == UInt8.self {
        let value = reader.data[reader.offset]
        reader.offset += 1
        return value as! T
    }
    var value: T = 0
    let _ = withUnsafeMutableBytes(of: &value, { reader.data.copyBytes(to: $0, from: range)})
    reader.offset = range.upperBound
    return value.bigEndian
}

// Reads an arbitrary number of bytes, to be used to read
// raw bytes, this is useful when lifting strings
fileprivate func readBytes(_ reader: inout (data: Data, offset: Data.Index), count: Int) throws -> Array<UInt8> {
    let range = reader.offset..<(reader.offset+count)
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    var value = [UInt8](repeating: 0, count: count)
    value.withUnsafeMutableBufferPointer({ buffer in
        reader.data.copyBytes(to: buffer, from: range)
    })
    reader.offset = range.upperBound
    return value
}

// Reads a float at the current offset.
fileprivate func readFloat(_ reader: inout (data: Data, offset: Data.Index)) throws -> Float {
    return Float(bitPattern: try readInt(&reader))
}

// Reads a float at the current offset.
fileprivate func readDouble(_ reader: inout (data: Data, offset: Data.Index)) throws -> Double {
    return Double(bitPattern: try readInt(&reader))
}

// Indicates if the offset has reached the end of the buffer.
fileprivate func hasRemaining(_ reader: (data: Data, offset: Data.Index)) -> Bool {
    return reader.offset < reader.data.count
}

// Define writer functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.  See the above discussion on Readers for details.

fileprivate func createWriter() -> [UInt8] {
    return []
}

fileprivate func writeBytes<S>(_ writer: inout [UInt8], _ byteArr: S) where S: Sequence, S.Element == UInt8 {
    writer.append(contentsOf: byteArr)
}

// Writes an integer in big-endian order.
//
// Warning: make sure what you are trying to write
// is in the correct type!
fileprivate func writeInt<T: FixedWidthInteger>(_ writer: inout [UInt8], _ value: T) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { writer.append(contentsOf: $0) }
}

fileprivate func writeFloat(_ writer: inout [UInt8], _ value: Float) {
    writeInt(&writer, value.bitPattern)
}

fileprivate func writeDouble(_ writer: inout [UInt8], _ value: Double) {
    writeInt(&writer, value.bitPattern)
}

// Protocol for types that transfer other types across the FFI. This is
// analogous to the Rust trait of the same name.
fileprivate protocol FfiConverter {
    associatedtype FfiType
    associatedtype SwiftType

    static func lift(_ value: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType
    static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType
    static func write(_ value: SwiftType, into buf: inout [UInt8])
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
fileprivate protocol FfiConverterPrimitive: FfiConverter where FfiType == SwiftType { }

extension FfiConverterPrimitive {
#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func lift(_ value: FfiType) throws -> SwiftType {
        return value
    }

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func lower(_ value: SwiftType) -> FfiType {
        return value
    }
}

// Types conforming to `FfiConverterRustBuffer` lift and lower into a `RustBuffer`.
// Used for complex types where it's hard to write a custom lift/lower.
fileprivate protocol FfiConverterRustBuffer: FfiConverter where FfiType == RustBuffer {}

extension FfiConverterRustBuffer {
#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func lift(_ buf: RustBuffer) throws -> SwiftType {
        var reader = createReader(data: Data(rustBuffer: buf))
        let value = try read(from: &reader)
        if hasRemaining(reader) {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func lower(_ value: SwiftType) -> RustBuffer {
          var writer = createWriter()
          write(value, into: &writer)
          return RustBuffer(bytes: writer)
    }
}
// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
fileprivate enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case unexpectedStaleHandle
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
        case let .rustPanic(message): return message
        }
    }
}

fileprivate extension NSLock {
    func withLock<T>(f: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try f()
    }
}

fileprivate let CALL_SUCCESS: Int8 = 0
fileprivate let CALL_ERROR: Int8 = 1
fileprivate let CALL_UNEXPECTED_ERROR: Int8 = 2
fileprivate let CALL_CANCELLED: Int8 = 3

fileprivate extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer.init(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    let neverThrow: ((RustBuffer) throws -> Never)? = nil
    return try makeRustCall(callback, errorHandler: neverThrow)
}

private func rustCallWithError<T, E: Swift.Error>(
    _ errorHandler: @escaping (RustBuffer) throws -> E,
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: errorHandler)
}

private func makeRustCall<T, E: Swift.Error>(
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T,
    errorHandler: ((RustBuffer) throws -> E)?
) throws -> T {
    uniffiEnsureContextIdInitialized()
    var callStatus = RustCallStatus.init()
    let returnedVal = callback(&callStatus)
    try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: errorHandler)
    return returnedVal
}

private func uniffiCheckCallStatus<E: Swift.Error>(
    callStatus: RustCallStatus,
    errorHandler: ((RustBuffer) throws -> E)?
) throws {
    switch callStatus.code {
        case CALL_SUCCESS:
            return

        case CALL_ERROR:
            if let errorHandler = errorHandler {
                throw try errorHandler(callStatus.errorBuf)
            } else {
                callStatus.errorBuf.deallocate()
                throw UniffiInternalError.unexpectedRustCallError
            }

        case CALL_UNEXPECTED_ERROR:
            // When the rust code sees a panic, it tries to construct a RustBuffer
            // with the message.  But if that code panics, then it just sends back
            // an empty buffer.
            if callStatus.errorBuf.len > 0 {
                throw UniffiInternalError.rustPanic(try FfiConverterString.lift(callStatus.errorBuf))
            } else {
                callStatus.errorBuf.deallocate()
                throw UniffiInternalError.rustPanic("Rust panic")
            }

        case CALL_CANCELLED:
            fatalError("Cancellation not supported yet")

        default:
            throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

private func uniffiTraitInterfaceCall<T>(
    callStatus: UnsafeMutablePointer<RustCallStatus>,
    makeCall: () throws -> T,
    writeReturn: (T) -> ()
) {
    do {
        try writeReturn(makeCall())
    } catch let error {
        callStatus.pointee.code = CALL_UNEXPECTED_ERROR
        callStatus.pointee.errorBuf = FfiConverterString.lower(String(describing: error))
    }
}

private func uniffiTraitInterfaceCallWithError<T, E>(
    callStatus: UnsafeMutablePointer<RustCallStatus>,
    makeCall: () throws -> T,
    writeReturn: (T) -> (),
    lowerError: (E) -> RustBuffer
) {
    do {
        try writeReturn(makeCall())
    } catch let error as E {
        callStatus.pointee.code = CALL_ERROR
        callStatus.pointee.errorBuf = lowerError(error)
    } catch {
        callStatus.pointee.code = CALL_UNEXPECTED_ERROR
        callStatus.pointee.errorBuf = FfiConverterString.lower(String(describing: error))
    }
}
fileprivate final class UniffiHandleMap<T>: @unchecked Sendable {
    // All mutation happens with this lock held, which is why we implement @unchecked Sendable.
    private let lock = NSLock()
    private var map: [UInt64: T] = [:]
    private var currentHandle: UInt64 = 1

    func insert(obj: T) -> UInt64 {
        lock.withLock {
            let handle = currentHandle
            currentHandle += 1
            map[handle] = obj
            return handle
        }
    }

     func get(handle: UInt64) throws -> T {
        try lock.withLock {
            guard let obj = map[handle] else {
                throw UniffiInternalError.unexpectedStaleHandle
            }
            return obj
        }
    }

    @discardableResult
    func remove(handle: UInt64) throws -> T {
        try lock.withLock {
            guard let obj = map.removeValue(forKey: handle) else {
                throw UniffiInternalError.unexpectedStaleHandle
            }
            return obj
        }
    }

    var count: Int {
        get {
            map.count
        }
    }
}


// Public interface members begin here.


#if swift(>=5.8)
@_documentation(visibility: private)
#endif
fileprivate struct FfiConverterUInt8: FfiConverterPrimitive {
    typealias FfiType = UInt8
    typealias SwiftType = UInt8

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt8 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: UInt8, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
fileprivate struct FfiConverterInt64: FfiConverterPrimitive {
    typealias FfiType = Int64
    typealias SwiftType = Int64

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Int64 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: Int64, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
fileprivate struct FfiConverterBool : FfiConverter {
    typealias FfiType = Int8
    typealias SwiftType = Bool

    public static func lift(_ value: Int8) throws -> Bool {
        return value != 0
    }

    public static func lower(_ value: Bool) -> Int8 {
        return value ? 1 : 0
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Bool {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: Bool, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
fileprivate struct FfiConverterString: FfiConverter {
    typealias SwiftType = String
    typealias FfiType = RustBuffer

    public static func lift(_ value: RustBuffer) throws -> String {
        defer {
            value.deallocate()
        }
        if value.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: value.data!, count: Int(value.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    public static func lower(_ value: String) -> RustBuffer {
        return value.utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> String {
        let len: Int32 = try readInt(&buf)
        return String(bytes: try readBytes(&buf, count: Int(len)), encoding: String.Encoding.utf8)!
    }

    public static func write(_ value: String, into buf: inout [UInt8]) {
        let len = Int32(value.utf8.count)
        writeInt(&buf, len)
        writeBytes(&buf, value.utf8)
    }
}




/**
 * Top-level API for the context_id component
 */
public protocol ContextIdComponentProtocol: AnyObject {
    
    /**
     * Regenerate the context ID.
     */
    func forceRotation() throws 
    
    /**
     * Return the current context ID string.
     */
    func request(rotationDaysInS: UInt8) throws  -> String
    
    /**
     * Unset the callbacks set during construction, and use a default
     * no-op ContextIdCallback instead.
     */
    func unsetCallback() throws 
    
}
/**
 * Top-level API for the context_id component
 */
open class ContextIdComponent: ContextIdComponentProtocol, @unchecked Sendable {
    fileprivate let pointer: UnsafeMutableRawPointer!

    /// Used to instantiate a [FFIObject] without an actual pointer, for fakes in tests, mostly.
#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public struct NoPointer {
        public init() {}
    }

    // TODO: We'd like this to be `private` but for Swifty reasons,
    // we can't implement `FfiConverter` without making this `required` and we can't
    // make it `required` without making it `public`.
    required public init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    // This constructor can be used to instantiate a fake object.
    // - Parameter noPointer: Placeholder value so we can have a constructor separate from the default empty one that may be implemented for classes extending [FFIObject].
    //
    // - Warning:
    //     Any object instantiated with this constructor cannot be passed to an actual Rust-backed object. Since there isn't a backing [Pointer] the FFI lower functions will crash.
#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public init(noPointer: NoPointer) {
        self.pointer = nil
    }

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public func uniffiClonePointer() -> UnsafeMutableRawPointer {
        return try! rustCall { uniffi_context_id_fn_clone_contextidcomponent(self.pointer, $0) }
    }
    /**
     * Construct a new [ContextIDComponent].
     *
     * If no creation timestamp is provided, the current time will be used.
     */
public convenience init(initContextId: String, creationTimestampS: Int64, runningInTestAutomation: Bool, callback: ContextIdCallback) {
    let pointer =
        try! rustCall() {
    uniffi_context_id_fn_constructor_contextidcomponent_new(
        FfiConverterString.lower(initContextId),
        FfiConverterInt64.lower(creationTimestampS),
        FfiConverterBool.lower(runningInTestAutomation),
        FfiConverterCallbackInterfaceContextIdCallback_lower(callback),$0
    )
}
    self.init(unsafeFromRawPointer: pointer)
}

    deinit {
        guard let pointer = pointer else {
            return
        }

        try! rustCall { uniffi_context_id_fn_free_contextidcomponent(pointer, $0) }
    }

    

    
    /**
     * Regenerate the context ID.
     */
open func forceRotation()throws   {try rustCallWithError(FfiConverterTypeApiError_lift) {
    uniffi_context_id_fn_method_contextidcomponent_force_rotation(self.uniffiClonePointer(),$0
    )
}
}
    
    /**
     * Return the current context ID string.
     */
open func request(rotationDaysInS: UInt8)throws  -> String  {
    return try  FfiConverterString.lift(try rustCallWithError(FfiConverterTypeApiError_lift) {
    uniffi_context_id_fn_method_contextidcomponent_request(self.uniffiClonePointer(),
        FfiConverterUInt8.lower(rotationDaysInS),$0
    )
})
}
    
    /**
     * Unset the callbacks set during construction, and use a default
     * no-op ContextIdCallback instead.
     */
open func unsetCallback()throws   {try rustCallWithError(FfiConverterTypeApiError_lift) {
    uniffi_context_id_fn_method_contextidcomponent_unset_callback(self.uniffiClonePointer(),$0
    )
}
}
    

}


#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public struct FfiConverterTypeContextIDComponent: FfiConverter {

    typealias FfiType = UnsafeMutableRawPointer
    typealias SwiftType = ContextIdComponent

    public static func lift(_ pointer: UnsafeMutableRawPointer) throws -> ContextIdComponent {
        return ContextIdComponent(unsafeFromRawPointer: pointer)
    }

    public static func lower(_ value: ContextIdComponent) -> UnsafeMutableRawPointer {
        return value.uniffiClonePointer()
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> ContextIdComponent {
        let v: UInt64 = try readInt(&buf)
        // The Rust code won't compile if a pointer won't fit in a UInt64.
        // We have to go via `UInt` because that's the thing that's the size of a pointer.
        let ptr = UnsafeMutableRawPointer(bitPattern: UInt(truncatingIfNeeded: v))
        if (ptr == nil) {
            throw UniffiInternalError.unexpectedNullPointer
        }
        return try lift(ptr!)
    }

    public static func write(_ value: ContextIdComponent, into buf: inout [UInt8]) {
        // This fiddling is because `Int` is the thing that's the same size as a pointer.
        // The Rust code won't compile if a pointer won't fit in a `UInt64`.
        writeInt(&buf, UInt64(bitPattern: Int64(Int(bitPattern: lower(value)))))
    }
}


#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public func FfiConverterTypeContextIDComponent_lift(_ pointer: UnsafeMutableRawPointer) throws -> ContextIdComponent {
    return try FfiConverterTypeContextIDComponent.lift(pointer)
}

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public func FfiConverterTypeContextIDComponent_lower(_ value: ContextIdComponent) -> UnsafeMutableRawPointer {
    return FfiConverterTypeContextIDComponent.lower(value)
}




public enum ApiError {

    
    
    case Other(reason: String
    )
}


#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public struct FfiConverterTypeApiError: FfiConverterRustBuffer {
    typealias SwiftType = ApiError

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> ApiError {
        let variant: Int32 = try readInt(&buf)
        switch variant {

        

        
        case 1: return .Other(
            reason: try FfiConverterString.read(from: &buf)
            )

         default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: ApiError, into buf: inout [UInt8]) {
        switch value {

        

        
        
        case let .Other(reason):
            writeInt(&buf, Int32(1))
            FfiConverterString.write(reason, into: &buf)
            
        }
    }
}


#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public func FfiConverterTypeApiError_lift(_ buf: RustBuffer) throws -> ApiError {
    return try FfiConverterTypeApiError.lift(buf)
}

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public func FfiConverterTypeApiError_lower(_ value: ApiError) -> RustBuffer {
    return FfiConverterTypeApiError.lower(value)
}


extension ApiError: Equatable, Hashable {}



extension ApiError: Foundation.LocalizedError {
    public var errorDescription: String? {
        String(reflecting: self)
    }
}





public protocol ContextIdCallback: AnyObject {
    
    func persist(contextId: String, creationDate: Int64) 
    
    func rotated(oldContextId: String) 
    
}
// Magic number for the Rust proxy to call using the same mechanism as every other method,
// to free the callback once it's dropped by Rust.
private let IDX_CALLBACK_FREE: Int32 = 0
// Callback return codes
private let UNIFFI_CALLBACK_SUCCESS: Int32 = 0
private let UNIFFI_CALLBACK_ERROR: Int32 = 1
private let UNIFFI_CALLBACK_UNEXPECTED_ERROR: Int32 = 2

// Put the implementation in a struct so we don't pollute the top-level namespace
fileprivate struct UniffiCallbackInterfaceContextIdCallback {

    // Create the VTable using a series of closures.
    // Swift automatically converts these into C callback functions.
    //
    // This creates 1-element array, since this seems to be the only way to construct a const
    // pointer that we can pass to the Rust code.
    static let vtable: [UniffiVTableCallbackInterfaceContextIdCallback] = [UniffiVTableCallbackInterfaceContextIdCallback(
        persist: { (
            uniffiHandle: UInt64,
            contextId: RustBuffer,
            creationDate: Int64,
            uniffiOutReturn: UnsafeMutableRawPointer,
            uniffiCallStatus: UnsafeMutablePointer<RustCallStatus>
        ) in
            let makeCall = {
                () throws -> () in
                guard let uniffiObj = try? FfiConverterCallbackInterfaceContextIdCallback.handleMap.get(handle: uniffiHandle) else {
                    throw UniffiInternalError.unexpectedStaleHandle
                }
                return uniffiObj.persist(
                     contextId: try FfiConverterString.lift(contextId),
                     creationDate: try FfiConverterInt64.lift(creationDate)
                )
            }

            
            let writeReturn = { () }
            uniffiTraitInterfaceCall(
                callStatus: uniffiCallStatus,
                makeCall: makeCall,
                writeReturn: writeReturn
            )
        },
        rotated: { (
            uniffiHandle: UInt64,
            oldContextId: RustBuffer,
            uniffiOutReturn: UnsafeMutableRawPointer,
            uniffiCallStatus: UnsafeMutablePointer<RustCallStatus>
        ) in
            let makeCall = {
                () throws -> () in
                guard let uniffiObj = try? FfiConverterCallbackInterfaceContextIdCallback.handleMap.get(handle: uniffiHandle) else {
                    throw UniffiInternalError.unexpectedStaleHandle
                }
                return uniffiObj.rotated(
                     oldContextId: try FfiConverterString.lift(oldContextId)
                )
            }

            
            let writeReturn = { () }
            uniffiTraitInterfaceCall(
                callStatus: uniffiCallStatus,
                makeCall: makeCall,
                writeReturn: writeReturn
            )
        },
        uniffiFree: { (uniffiHandle: UInt64) -> () in
            let result = try? FfiConverterCallbackInterfaceContextIdCallback.handleMap.remove(handle: uniffiHandle)
            if result == nil {
                print("Uniffi callback interface ContextIdCallback: handle missing in uniffiFree")
            }
        }
    )]
}

private func uniffiCallbackInitContextIdCallback() {
    uniffi_context_id_fn_init_callback_vtable_contextidcallback(UniffiCallbackInterfaceContextIdCallback.vtable)
}

// FfiConverter protocol for callback interfaces
#if swift(>=5.8)
@_documentation(visibility: private)
#endif
fileprivate struct FfiConverterCallbackInterfaceContextIdCallback {
    fileprivate static let handleMap = UniffiHandleMap<ContextIdCallback>()
}

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
extension FfiConverterCallbackInterfaceContextIdCallback : FfiConverter {
    typealias SwiftType = ContextIdCallback
    typealias FfiType = UInt64

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func lift(_ handle: UInt64) throws -> SwiftType {
        try handleMap.get(handle: handle)
    }

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType {
        let handle: UInt64 = try readInt(&buf)
        return try lift(handle)
    }

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func lower(_ v: SwiftType) -> UInt64 {
        return handleMap.insert(obj: v)
    }

#if swift(>=5.8)
    @_documentation(visibility: private)
#endif
    public static func write(_ v: SwiftType, into buf: inout [UInt8]) {
        writeInt(&buf, lower(v))
    }
}


#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public func FfiConverterCallbackInterfaceContextIdCallback_lift(_ handle: UInt64) throws -> ContextIdCallback {
    return try FfiConverterCallbackInterfaceContextIdCallback.lift(handle)
}

#if swift(>=5.8)
@_documentation(visibility: private)
#endif
public func FfiConverterCallbackInterfaceContextIdCallback_lower(_ v: ContextIdCallback) -> UInt64 {
    return FfiConverterCallbackInterfaceContextIdCallback.lower(v)
}

private enum InitializationResult {
    case ok
    case contractVersionMismatch
    case apiChecksumMismatch
}
// Use a global variable to perform the versioning checks. Swift ensures that
// the code inside is only computed once.
private let initializationResult: InitializationResult = {
    // Get the bindings contract version from our ComponentInterface
    let bindings_contract_version = 29
    // Get the scaffolding contract version by calling the into the dylib
    let scaffolding_contract_version = ffi_context_id_uniffi_contract_version()
    if bindings_contract_version != scaffolding_contract_version {
        return InitializationResult.contractVersionMismatch
    }
    if (uniffi_context_id_checksum_method_contextidcomponent_force_rotation() != 57248) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_context_id_checksum_method_contextidcomponent_request() != 62689) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_context_id_checksum_method_contextidcomponent_unset_callback() != 21655) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_context_id_checksum_constructor_contextidcomponent_new() != 28490) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_context_id_checksum_method_contextidcallback_persist() != 51609) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_context_id_checksum_method_contextidcallback_rotated() != 3858) {
        return InitializationResult.apiChecksumMismatch
    }

    uniffiCallbackInitContextIdCallback()
    return InitializationResult.ok
}()

// Make the ensure init function public so that other modules which have external type references to
// our types can call it.
public func uniffiEnsureContextIdInitialized() {
    switch initializationResult {
    case .ok:
        break
    case .contractVersionMismatch:
        fatalError("UniFFI contract version mismatch: try cleaning and rebuilding your project")
    case .apiChecksumMismatch:
        fatalError("UniFFI API checksum mismatch: try cleaning and rebuilding your project")
    }
}

// swiftlint:enable all