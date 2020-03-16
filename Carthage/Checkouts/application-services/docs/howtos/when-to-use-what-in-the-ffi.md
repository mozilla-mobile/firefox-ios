
# When to use what method of passing data between Rust and Java/Swift

There are a bunch of options here. For the purposes of our discussion,
there are two kinds of values you may want to pass over the FFI.

1. Types with identity (includes stateful types, resource types, or anything that
   isn't really serializable).
2. Plain ol' data.

## Types with identity

Examples of this are things like database connections, the FirefoxAccounts
struct, etc. These types are complex, implemented in rust, and it's not
unreasonable for them to come to Java/Kotlin as a type representing a
resource (e.g. implementing `Closable`/`AutoClosable`).

You have two choices here:

1. Use a `ConcurrentHandleMap` to store all instances of your object, and
   pass the handle back and forth as a u64 from Rust / Long from Kotlin.

   This is recommended for most cases, as it's the hardest to mess up.
   Additionally, for types T such that `&T: Sync + Send`, or that you
   need to call `&mut self` method, this is the safest choice.

   Additionally, this will ensure panic-safety, as you'll poison your Mutex.

   The [`ffi_support::handle_map` docs](https://docs.rs/ffi-support/*/ffi_support/handle_map/index.html)
   are good, and under `ConcurrentHandleMap` include an example of how to set
   this up. You can also look at most of the FFI crates, as they do this (with
   the exception of `rc_log`, which has unique requirements).

2. Using an opaque pointer. This is generally only recommended for rare cases
   like the `PlacesInterruptHandle` (or the `LogAdapterState` from `rc_log`,
   although it will probably eventually use a handle).

   It's good if your synchronization or threading requirements are somewhat
   complex and handled separately, such that the additional overhead of
   the `ConcurrentHandleMap` is undesirable. You should probably talk to us
   before adding another type that works this way, to make sure it's sound.

   The [`ffi_support` docs](https://docs.rs/ffi-support/*/ffi_support/macro.implement_into_ffi_by_pointer.html)
   discuss how to do this, or take a look at how it's done for
   `PlacesInterruptHandle`).

## Plain Old Data

This includes both primitive values, strings, arrays, or arbitrarially nested
structures containing them.

### Primitives

Specifically numeric primitives. These we'll tackle first since they're the
easiest.

In general, you can just pass them as you wish. There are a couple of
exceptions/caveats. All of them are caused by JNA/Android issues (Swift has very
good support for calling over the FFI), but it's our lowest common denominator.

1. `bool`: Don't use it. JNA doesn't handle it well. Instead, use a numeric type
    (like `u8`) and represent 0 for false and 1 for true for interchange over the
    FFI, converting back to a Kotlin `Boolean` or swift `Bool` after (as to
    not expose this somewhat annoying limitation in our public API).

2. `usize`/`isize`: These cause the structure size to be different based on the
   platform. JNA does handle this if you use `NativeSize`, but it's awkward,
   incompatible with it's Direct Mapping optimization (which we don't use but
   want to in the future), and has more overhead than just using `i64`/`i32` for
   `Long`/`Int`. (You can also use `u64`/`u32` for `Long`/`Int`, if you're certain the
   value is not negative)

3. `char`: I really don't see a reason you need to pass a single codepoint over the
   FFI, but if someone needs to do this, they instead should just pass it as a `u32`.

    If you do this, you should probably be aware of the fact that Java chars are 16
    bit, and Swift `Character`s are actually strings (they represent Extended
    Grapheme Clusters, not codepoints).

### Strings

These we pass as nul-terminated UTF-8 C-strings.

For return values, used `*mut c_char`, and for input, use
[`ffi_support::FfiStr`](https://docs.rs/ffi-support/*/ffi_support/struct.FfiStr.html)

1. If the string is returned from Rust to Kotlin/Swift, you need to expose a
   string destructor from your ffi crate. See
   [`ffi_support::define_string_destructor!`](https://docs.rs/ffi-support/*/ffi_support/macro.define_string_destructor.html)).

    For converting to a `*mut c_char`, use either
   [`rust_string_to_c`](https://docs.rs/ffi-support/*/ffi_support/fn.rust_string_to_c.html)
    if you have a `String`, or
   [`opt_rust_string_to_c`](https://docs.rs/ffi-support/*/ffi_support/fn.opt_rust_string_to_c.html)
    for `Option<String>` (None becomes `std::ptr::null_mut()`).

    **Important**: In Kotlin, the type returned by a function that produces this
    must be `Pointer`, and not `String`, and the parameter that the destructor takes
    as input must also be `Pointer`.

    Using `String` will *almost* work. JNA will convert the return value to
    `String` automatically, leaking the value rust provides. Then, when passing
    to the destructor, it will allocate a temporary buffer, pass it to Rust, which
    we'll free, corrupting both heaps 💥. Oops!

2. If the string is passed into Rust from Kotlin/Swift, the rust code should
   declare the parameter as a [`FfiStr<'_>`](https://docs.rs/ffi-support/*/ffi_support/struct.FfiStr.html).
   and things should then work more or less automatically. The `FfiStr` has methods
   for extracting it's data as `&str`, `Option<&str>`, `String`, and `Option<String>`.

It's also completely fine to use Protobufs or JSON for this case!

### Aggregates

This is any type that's more complex than a primitive or a string (arrays,
structures, and combinations there-in). There are two options we recommend for
these cases:

1. Passing data using protobufs. See the
   "[Using protobuf-encoded data over Rust FFI](passing-protobuf-data-over-ffi.md)"
   document for details on how to do this. We recommend this for all new use cases, unless
   you have a specific reason that JSON is better (e.g. semi-opaque JSON encoded data is
   desired on the other side).

2. Passing data as JSON. This is very easy, and useful for prototyping, however
   much slower, requires a great deal of copying and redundant encode/decode
   steps (in general, the data will be copied at least 4 times to make this
   work, and almost certainly more in practice), and can be done relatively
   easily by `derive(Serialize, Deserialize)`, and adding
   [`ffi_support::implement_into_ffi_by_json`](https://docs.rs/ffi-support/*/ffi_support/macro.implement_into_ffi_by_json.html)
   into the crate that defines the type.

   Again, for new code, this is not a recommended approach for new code, unless
   there's some reason it's preferrable for you.
