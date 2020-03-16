
# Using protobuf-encoded data over Rust FFI.

This assumes you already have your FFI mostly set up. If you don't that part
should be covered by another document, which may or may not exist yet (at the time of this writing, it does not).

Most of this is concerned with how to do it the first time as well. If your rust
component already is returning protobuf-encoded data, you probably just need to
follow the examples of the other steps it takes.

## Rust Changes

1. To your main rust crate, add dependencies on the `prost`, `prost-derive`, and
   `bytes` crates.
2. Add `features = ["prost_support"]` to the `ffi_support` dependency.
3. Add `prost-build` to your build dependencies (e.g. you probably have to add
   both of these):
    ```toml
    [build-dependencies]
    prost-build = "check what version our other crates are using"
    ```
4. Create a new file named `mylib_msg_types.proto` (well, prefix it with the
   actual name of your lib) in your main crate's src folder. This is what is
   referenced in that bit you pasted above, so if you want or need to change its
   name, you must do so consistently.

   Due to annoying details of how the iOS megazord works, the name of the .proto
   file must be unique.

    1. This file should start with
    ```
    syntax = "proto2";
    package msg_types;
    ```

    The package name is going to determine where the .rs file is output, which
    will be relevant shortly.

    2. Fill in your definitions in the rest of the file. See
       https://developers.google.com/protocol-buffers/docs/proto for examples.

5. In the same directory as your main crate's Cargo.toml, add a `build.rs` file.
   Paste the following into it:
    ```rust
    /* This Source Code Form is subject to the terms of the Mozilla Public
     * License, v. 2.0. If a copy of the MPL was not distributed with this
     * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

    fn main() {
        println!("cargo:rerun-if-changed=src/mylib_msg_types.proto");
        prost_build::compile_protos(&["src/mylib_msg_types.proto"], &["src/"]).unwrap();
    }
    ```

6. Into your main crate's lib.rs file, add something equivalent to the following:
    ```rust
    pub mod msg_types {
        include!(concat!(env!("OUT_DIR"), "/msg_types.rs"));
    }
    ```

    This exposes the file your `build.rs` generates (from the .proto file) as a
    rust module.

7. Open your main crates's src/ffi.rs (note: *not* ffi/src/lib.rs! We'll get
   there shortly!)

   For each type you declare in your .proto file, first decide if you want to
   use this as the primary type to represent this data, or if you want to convert
   it from a more idiomatic Rust type into the message type when returning.

   If it's something that exists solely to return over the FFI, or you may have
   a large number of them (or if you need to return them in an array, see the
   FAQ question on this) it *may* be best to just use the type from msg_types in your rust code.

   We'll what you do in both cases. The parts only relevant if you are converting
   between a rust type and the protobuf start with "*(optional unless converting types)*".

   Note that if your canonical rust type is defined in another crate, or if it's
   something like `Vec<T>`, you will need to use a wrapper. See the FAQ question
   on `Vec<T>` about this.

    1. *(optional unless converting types)* Define the conversion between the
       idiomatic Rust type and the type produced from `msg_types`. This will
       likely look something like this:
       ```rust
        impl From<HistoryVisitInfo> for msg_types::HistoryVisitInfo {
            fn from(hvi: HistoryVisitInfo) -> Self {
                Self {
                    // convert url::Url to String
                    url: hvi.url.into_string(),
                    // Title is already an Option<String>
                    title: hvi.title,
                    // Convert Timestamp to i64
                    timestamp: hvi.title.0 as i64,
                    // Convert rust enum to i32
                    visit_type: hvi.visit_type as i32,
                }
            }
        }
        ```
    2. Add a call to:
        ```rust
        ffi_support::implement_into_ffi_by_protobuf!(msg_types::MyType);
        ```

    3. *(optional unless converting types)* Add a call to
        ```rust
        ffi_support::implement_into_ffi_by_delegation!(MyType, msg_types::MyType);
        ```

      If `MyType` is something that you were previously returning via JSON, you need
      to remove the call to `implement_into_ffi_by_json!`, and you may also want to
      delete `Serialize` from it's `#[derive(...)]` while you're at it, unless you
      still need it.

8. In your ffi crate's lib.rs, make the following changes:

    1. Any function that conceptually returns a protobuf type must now return
      `ffi_support::ByteBuffer` (if it returned via JSON before, this should be
      a change of `-> *mut c_char` to `-> ByteBuffer`).

       Sometimes you may want to return an *optional* protobuf. Since we are returning the `RustBuffer` struct **by value** in our FFI code, it cannot be "nulled". However this structure has a `data` pointer, which will can get nulled: instead of returning a `Result<T>`, simply return `Result<Option<T>>`. In practice this means [very little changes](https://github.com/mozilla/application-services/blob/2df37a4c8c9d3b9c9159b0f80542303088027618/components/tabs/ffi/src/lib.rs#L85-L95) in Rust code.
       We have also outlined in the specific Kotlin/Swift implementations below the small changes to make to your code.


    2. You must add a call to
    `ffi_support::define_bytebuffer_destructor!(mylib_destroy_bytebuffer)`.

      The name you chose for `mylib_destroy_bytebuffer` **must not** collide with the name anybody else uses for this.

## Kotlin Changes

1. Inside your component's build.gradle (e.g.
   `components/mything/android/build.gradle`, not the top level one):

    1. Add `apply plugin: 'com.google.protobuf'` to the top of the file.

    2. Into the `android { ... }` block, add:
        ```groovy
        sourceSets {
            main {
                proto {
                    srcDir '../src'
                }
            }
        }
        ```
    3. Add a new top level block:
        ```groovy
        protobuf {
            protoc {
                artifact = 'com.google.protobuf:protoc:3.0.0'
            }
            plugins {
                javalite {
                    artifact = 'com.google.protobuf:protoc-gen-javalite:3.0.0'
                }
            }
            generateProtoTasks {
                all().each { task ->
                    task.builtins {
                        remove java
                    }
                    task.plugins {
                        javalite { }
                    }
                }
            }
        }
        ```
    4. Add the following to your dependencies:
        ```groovy
        implementation 'com.google.protobuf:protobuf-lite:3.0.0'
        implementation project(':native-support')
        ```
2. In the file where the foreign functions are defined, make sure that the
   function returning this type returns a `RustBuffer.ByValue` (`RustBuffer` is
   in `mozilla.appservices.support.native`).

   Additionally, add a declaration for `mylib_destroy_bytebuffer` (the name must match what was used in the `ffi/src/lib.rs` above). This should look like:

   ```kotlin
   fun mylib_destroy_bytebuffer(v: RustBuffer.ByValue)
   ```

3. Usage code then looks as follows:
    ```kotlin
        val rustBuffer = rustCall { error ->
            MyLibFFI.INSTANCE.call_thing_returning_rustbuffer(...)
        }
        try {
            // Note: if conceptually your function returns Option<ByteBuffer>
            // from rust, you should do the following here instead:
            //
            // val message = rustBuffer.asCodedInputStream()?.let { stream ->
            //   MsgTypes.SomeMessageData.parseFrom(stream)
            // }
            val message = MsgTypes.SomeMessageData.parseFrom(
                    infoBuffer.asCodedInputStream()!!)
            // use `message` to produce the higher level type you want to return.

        } finally {
            LibPlacesFFI.INSTANCE.mylib_destroy_bytebuffer(infoBuffer)
        }
    ```

## Swift

1. You need to install `carthage` and `swift-protobuf`, as well as `protobuf`
   (if you don't have it already). The following should do the trick if you
   use homebrew:
   ```
   brew install carthage swift-protobuf protobuf
   ```

2. Run `carthage bootstrap` from the root of this repository. This will produce a
  (gitignored) Carthage directory in this repository.

3. In Xcode, you need to add `Carthage/Build/iOS/SwiftProtobuf.framework`
  to your target's "Linked frameworks and libraries" list.
    - You'll need to click "Add Other" for choosing a path to be available.
    - This was hard for me to find, so see [this screenshot](./img/swift-protobuf-framework.png)
      if you are having trouble locating it.

4. Add `FRAMEWORK_SEARCH_PATHS = "../../../Carthage/Build/iOS"` (Note: you may need a different number of `..`s) to the `base.xcconfig`

5. Add your msg_types.proto file to the xcode project.
    - Do not check "copy items as needed".

6. Under "Build Rules", add a new build rule:

    - Choose "Source files with names matching:" and enter `*.proto`

    - Choose "Using custom script" and paste the following into the textarea.
        ```
        protoc --proto_path=$INPUT_FILE_DIR --swift_out=$DERIVED_FILE_DIR $INPUT_FILE_PATH
        ```
    - Under "Output Files", add `$(DERIVED_FILE_DIR)/$(INPUT_FILE_BASE).pb.swift`
      (with no compiler flags).

    This should look like [this screenshot](./img/swift-protobuf-build-rule.png)
    (which should also help indicate where to find the build rules page) after
    you finish.

7. If you have a test target for your framework (and you should, but not all of
   our iOS code does), you need to do the following as well:

    1. In the test target's Build phases, add SwiftProtobuf.framework to the
       "Link Binary with Libraries" phase (As in step 3, you need to "Add
       Other", and choose
       `<repo-root>/Carthage/Build/iOS/SwiftProtobuf.framework`).
    2. Add a new "Copy Files" build phase to the test target. Select the
       SwiftProtobuf.framework, and set the destination to Frameworks.

    See [this screenshot](./img/swift-protobuf-test-setup.png) for what it should look
    like when done.

8. Add a declaration for the rust buffer type to your .h file:

    Note that the name must be unique, hence the `MyLib` prefix (use your actual
    lib name, and not MyLib, of course).

    ```c
    typedef struct MyLibRustBuffer {
        int64_t len;
        uint8_t *_Nullable data;
    } MyLibRustBuffer;

    // Note: this must be the same name you called
    // `ffi_support::define_bytebuffer_destructor!` with in
    // Rust setup step 8.
    void mylib_destroy_bytebuffer(MyLibRustBuffer bb);
    ```

    Then, your functions that return `ffi_support::ByteBuffers` in rust should
    return `MyLibRustBuffer` in the version exposed by the header, for example (from places)

    ```c
    PlacesRustBuffer bookmarks_get_by_guid(PlacesConnectionHandle handle,
                                           char const *_Nonnull guid,
                                           PlacesRustError *_Nonnull out_err);
    ```

9. Add the following somewhere in your swift code: (TODO: Eventually we should
   figure out a way to share this)

    ```swift
    extension Data {
        init(mylibRustBuffer: MyLibRustBuffer) {
            self.init(bytes: mylibRustBuffer.data!, count: Int(mylibRustBuffer.len))
        }
    }
    ```

10. Usage code then looks something like:

    ```swift
    let buffer = try MylibError.unwrap { error in
        mylib_function_returning_buffer(self.handle, error)
    }
    // Note: if conceptually your function returns Option<ByteBuffer>
    // from rust, you should do the following here:
    //
    // if buffer.data == nil {
    //    return nil
    // }

    defer { mylib_destroy_bytebuffer(buffer) }
    let msg = try! MsgTypes_MyMessageType(serializedData: Data(mylibRustBuffer: buffer))
    // use msg...
    ```

Note: If Xcode has trouble locating the types generated from the .proto file,
even though the build works, restarting Xcode may fix the issue.

# Using protobuf to pass data *into* Rust code

Don't pass `ffi_support::ByteBuffer`/`RustBuffer` into rust.
It is a type for going in the other direction.

Instead, you should pass the data and length separately.

The Rust side of this looks something like this:

```rust
#[no_mangle]
pub unsafe extern "C" fn rust_fun_taking_protobuf(
    data *const u8,
    len: i32,
    error: &mut ExternError,
) {
    // Or another call_with_blah function as needed
    ffi_support::call_with_result(error, || {
        // TODO: We should find a way to share some of this boilerplate
        assert!(len >= 0, "Bad buffer len: {}", len);
        let bytes = if len == 0 {
            // This will still fail, but as a bad protobuf format.
            &[]
        } else {
            assert!(!data.is_null(), "Unexpected null data pointer");
            std::slice::from_raw_parts(data, len as usize)
        };
        let my_thing: MyMsgType = prost::Message::decode(bytes)?;
        // Do stuff with my_thing...

        Ok(())
    })
}
```

## Kotlin/Android

There are two ways of passing the data/length pairs on android. You can use
either a `Array<Byte>` or a `Pointer`, which you can get from a "direct"
`java.nio.ByteBuffer`. We recommend the latter, as it avoids an additional copy,
which can be done as follows (using the `toNioDirectBuffer` our kotlin support
library provides):

In Kotlin:

```kotlin
// In the com.sun.jna.Library
fun rust_fun_taking_protobuf(data: Pointer, len: Int, out: RustError.ByReference)

// In some your wrapper (note: `toNioDirectBuffer` is defined by our
// support library)
val (len, nioBuf) = theProtobufType.toNioDirectBuffer()
rustCall { err ->
    val ptr = Native.getDirectBufferPointer(nioBuf)
    MyLib.INSTANCE.rust_fun_taking_protobuf(ptr, len, err)
}
```

Note that the `toNioDirectBuffer` helper can't return the Pointer directly, as
it is only valid until the NIO buffer is garbage collected, and if the pointer
were returned it would not be reachable.

## Swift

1. Make sure you've done the first 7 steps (up until you need to modify .h
   files) of the swift setup for returning protobuf data.

2. The function taking the protobuf should look like this in the header file:

    ```c
    void rust_fun_taking_protobuf(uint8_t const *_Nonnull data,
                                  int32_t len,
                                  MylibRustError *_Nonnull out_err);
    ```

3. Then, the usage code from Swift would look like:

    ```swift
    var msg = MsgTypes_MyThing()
    // populate `msg` with whatever you need to send...

    // Note: the `try!` here only fails if you failed to
    // populate a required field.

    let data = try! msg.serializedData()
    let size = Int32(data.count)

    try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
        try MyLibError.unwrap { error in
            rust_fun_taking_protobuf(bytes, size, error)
        }
    }
    ```

# FAQ

### What are the downsides of using types from `msg_types.proto` heavily?

1. It doesn't lead to particularly idiomatic Rust code.
2. We loose the ability to enforce many type invariants that we'd like. For
   example, we cannot declare that a field holds a `Url`, and must use a
   `String` instead.

### I'd like to expose a function returning a `Vec<T>`.

If T is a type from your mylib_msg_types.proto, then this is fairly easy:

Don't, instead add a new msg_type that contains a repeated T field, and make
that rust function return that.

Then, make so long as the new msg_type has `implement_into_ffi_by_protobuf!` and the ffi function returns a ByteBuffer, things should "Just Work".

---

Unfortunately, if T is merely *convertable* to something from mylib_msg_types.proto,
this adds a bunch of boilerplate.

Say we have the following mylib_msg_types.proto:

```proto
message HistoryVisitInfo {
    required string url = 1;
    optional string title = 2;
    required int64 timestamp = 3;
    required int32 visit_type = 4;
}
message HistoryVisitInfos {
    repeated HistoryVisitInfo infos = 1;
}
```

in src/ffi.rs, we then need

```rust
// Convert from idiomatic rust HistoryVisitInfo to msg_type HistoryVisitInfo
impl From<HistoryVisitInfo> for msg_types::HistoryVisitInfo {
    fn from(hvi: HistoryVisitInfo) -> Self {
        Self {
            url: hvi.url,
            title: hvi.title,
            timestamp: hvi.title.0 as i64,
            visit_type: hvi.visit_type as i32,
        }
    }
}

// Declare a type that exists to wrap the vec (see the next question about
// why this is needed)
pub struct HistoryVisitInfos(pub Vec<HistoryVisitInfo>);

// Define the conversion between said wrapper and the protobuf
// HistoryVisitInfos
impl From<HistoryVisitInfos> for msg_types::HistoryVisitInfos {
    fn from(hvis: HistoryVisitInfos) -> Self {
        Self {
            infos: hvis.0
                .into_iter()
                .map(msg_types::HistoryVisitInfo::from)
                .collect()
        }
    }
}

// generate the IntoFfi for msg_types::HistoryVisitInfos
implement_into_ffi_by_protobuf!(msg_types::HistoryVisitInfos);
// Use it to implement it for HistoryVisitInfos
implement_into_ffi_by_delegation!(HistoryVisitInfos, msg_types::HistoryVisitInfos);
```

Then, in `ffi/src/lib.rs`, where you currently return the Vec, you need to
change it to return wrap that in main_crate::ffi::HistoryVisitInfos, something like

```rust
CONNECTIONS.call_with_result(error, handle, |conn| -> places::Result<_> {
    Ok(HistoryVisitInfos(storage::history::get_visit_infos(
        conn,
        places::Timestamp(start_date.max(0) as u64),
        places::Timestamp(end_date.max(0) as u64),
    )?))
})
```

### Why is that so painful?

Yep. There are a few reasons for this.

`ffi_support` is the only one who is in a position to decide how a `Vec<T>` is
returned over the FFI. Rust has a rule that either the trait (in this case
`IntoFfi`) or the type (in this case `Vec`) must be implemented in the crate
where the `impl` block happens. This is known as the orphan rule.

Additionally, until rust gains support for
[specialization](https://github.com/rust-lang/rust/issues/31844), we have very
little flexibility with how this works. We can't implement it one way for some
kinds of T's, and another way for others (however, we can, and do, make it
opt-in, but that's unrelated).

This means ffi_support is in the position of deciding how `Vec<T>` goes over the
FFI for all T. At one point, the reasonable choice seemed to be JSON. This is
still used fairly heavily for returning arrays of things, and so until we move
*everything* to use protobufs, we don't really want to take that out.

Unfortunately even we no longer use JSON for this, the conversion between
`Vec<T>` and the ByteBuffer has to happen through an intermediate type, due to
the way protobuf messages work (you can't have a message that's an array, but
you *can* have one that is a single item type which contains a repeated array),
and it isn't clear how to make this work (it can't be an argument to a macro, as
that would violate the orphan rule).

The only thing that would work is if we use the types generated by prost for more
than just returning things over the FFI. e.g. the rust `get_visit_infos()` call would return `HistoryVisitInfos` struct that is generated from a `.proto` file.

#### Could this be worked around by using length-delimited protobuf messages?

Yes, possibly. Looking into this is something we may do in the future.

### Why is the module produced from .proto `msg_types` and not `ffi_types`?

We use `msg_types` and not e.g. `ffi_types`, since in some cases (see the next
FAQ about returning arrays, for example) it can reduce boilerplate a lot to use
these for returning the data to rust code directly (particularly when the rust
API exists almost exclusively to be called from the FFI).

Using a name like `ffi_types`, while possibly intuitive, gives the impression
that these types should not be used outside the FFI, and that it may even be
unsafe to do so.
