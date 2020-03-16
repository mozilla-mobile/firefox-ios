/* Any copyright is dedicated to the Public Domain.
http://creativecommons.org/publicdomain/zero/1.0/ */

use crate::auth::TestClient;

// A (name, test_func) tuple. Eventually we should allow for more/less
// than 2 clients, and maybe this should be a trait or something.
type Test = (&'static str, fn(&mut TestClient, &mut TestClient));

pub struct TestGroup {
    pub name: &'static str,
    pub tests: Vec<Test>,
}

impl TestGroup {
    pub fn new(name: &'static str, tests: Vec<Test>) -> Self {
        Self { name, tests }
    }
}
