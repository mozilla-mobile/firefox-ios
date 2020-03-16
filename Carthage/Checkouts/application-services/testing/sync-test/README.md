# End-to-End Tests for Sync

This package implements "end-to-end" integration tests for syncing various data types -
two clients using a real live account and a real live sync server, exchanging
data and asserting that the exchange works as intended.

## Running the tests

Run the tests using `cargo run`.

Use `cargo run -- --help` to see the available options.

Running the tests currently requires nodejs, in order to drive a headless browser.
There is an [open issue](https://github.com/mozilla/application-services/issues/2403)
to investigate how to remove this dependency.

## Adding tests

For each datatype managed by sync, there should be a suite of corresponding tests.
To add some:

0. In `auth.rs`, add support your sync engine to the `TestClient` struct.
0. Create a file `./src/<datatype>.rs` to hold the tests; `logins.rs` may provide a useful example.
  0. Create a `test_<name>` function for each scenario you want to exercise. The function should take
     two `TestClient` instances as arguments, and use them to drive a simulated sync between two clients.
  0. Define a `get_test_group()` function that returns your test scenarios in a `TestGroup` struct.
0. Add your test group to the `main` function defined in `main.rs` for execution.
