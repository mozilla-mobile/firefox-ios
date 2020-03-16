# Welcome!

The Application Services libraries provide cross-platform components for storing and syncing user data within the Firefox ecosystem. Firefox manages _lots_ of data: a typical user profile houses over forty different stores, including your history, bookmarks, and saved logins.

As we make Firefox available on more platforms—and ship products that aren't web browsers—it's become clear that each project wants to access existing Firefox data, and make its own data available to others. The goal of the sync and storage components is to expose a uniform, flexible, and high-level way to do this.

## What?

**High-level** means your application thinks in terms of _what_ it wants to do, not _how_. Adding a bookmark, storing a page visit, updating a saved password, and syncing history are all examples of the former. Meanwhile, the component takes care of the details: defining the database schema, handling migrations, optimizing queries, downloading and uploading Sync records, and resolving merge conflicts.

**Uniform** means one way to access data everywhere. The same building blocks are used for each component; once you know how one works, you can understand the others. They are also consistent across products and platforms, so you don't need to change three different codebases.

**Flexible** means it's easy for your application to add new fields and data types, and experiment with new ways to represent data.

## Why?

Historically, each product had to build its own storage and sync system. They often started with similar data models, but then evolved based on immediate product needs. Changes had to be backported to each platform, often across languages: Firefox Desktop was written in a mix of JavaScript and C++, Firefox for Android in Java, and Firefox for iOS in Swift.

Beyond the language barrier, there was little commonality between the implementations. All platforms used [SQLite](https://sqlite.org/) for storage, with a similarly-shaped schema, but the similarities ended there. Some concepts didn't translate well, if at all, and coordinating changes across platforms was hard. Syncing was often bolted on, and required lots of low-level integration work. This made for an inconsistent, brittle experience for developers and users.

The new components build on our experience shipping sync and storage on three platforms. The cross-platform parts are written in [Rust](https://www.rust-lang.org/), with bindings for [Kotlin](https://kotlinlang.org/) and [Swift](https://swift.org/).

In the next section, we'll look at how a component works.
