# Sync Manager

It's a bit unfortunate this component can't just be part of `sync15`.
Conceptually and functionally, it shares most in common with with the `sync15`
crate, and in some cases stretches (or arguably breaks) the abstraction barrier
that `sync15` puts up.

Unfortunately, places/logins/etc depend on sync15 directly, and so to prevent a
dependency cycle (which is disallowed by cargo), doing so would require
implementing the manager in a fully generic manner, with no specific handling of
underlying crates. This seems extremely difficult to me, so this is split out
into it's own crate, which might happen to reach into the guts of `sync15` in
some cases.