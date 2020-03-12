# The `native_support` kotlin library.

This essentially is where we put shared android code which meets both of the following requirements:

- We'd like to reuse it in multiple projects.
- It only is sensible for inclusion in packages that already have a transitive dependency on JNA.

This is a bit subtle, but is mostly done to avoid additional special cases we'd need in the publish pipeline to handle this case sanely. (It also avoids adding that dependency if it's not needed).

In particular, this means pure-kotlin modules (sync15, for example), should not depend on this.
