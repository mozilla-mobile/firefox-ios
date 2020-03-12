/* Any copyright is dedicated to the Public Domain.
http://creativecommons.org/publicdomain/zero/1.0/ */

use crate::auth::TestClient;
use crate::testing::TestGroup;
use logins::{Login, PasswordEngine, Result as LoginResult};

// helpers...

// Doesn't check metadata fields
pub fn assert_logins_equiv(a: &Login, b: &Login) {
    assert_eq!(b.guid, a.guid, "id mismatch");
    assert_eq!(b.hostname, a.hostname, "hostname mismatch");
    assert_eq!(
        b.form_submit_url, a.form_submit_url,
        "form_submit_url mismatch"
    );
    assert_eq!(b.http_realm, a.http_realm, "http_realm mismatch");
    assert_eq!(b.username, a.username, "username mismatch");
    assert_eq!(b.password, a.password, "password mismatch");
    assert_eq!(
        b.username_field, a.username_field,
        "username_field mismatch"
    );
    assert_eq!(
        b.password_field, a.password_field,
        "password_field mismatch"
    );
}

pub fn times_used_for_id(e: &PasswordEngine, id: &str) -> i64 {
    e.get(id)
        .expect("get() failed")
        .expect("Login doesn't exist")
        .times_used
}

pub fn add_login(e: &PasswordEngine, l: Login) -> LoginResult<Login> {
    let id = e.add(l)?;
    Ok(e.get(&id)?.expect("Login we just added to exist"))
}

pub fn verify_login(e: &PasswordEngine, l: &Login) {
    let equivalent = e
        .get(&l.guid)
        .expect("get() to succeed")
        .expect("Expected login to be present");
    assert_logins_equiv(&equivalent, l);
}

pub fn verify_missing_login(e: &PasswordEngine, id: &str) {
    assert!(
        e.get(id).expect("get() to succeed").is_none(),
        "Login {} should not exist",
        id
    );
}

pub fn update_login<F: FnMut(&mut Login)>(
    e: &PasswordEngine,
    id: &str,
    mut callback: F,
) -> LoginResult<Login> {
    let mut login = e.get(id)?.expect("No such login!");
    callback(&mut login);
    e.update(login)?;
    Ok(e.get(id)?.expect("Just updated this"))
}

pub fn touch_login(e: &PasswordEngine, id: &str, times: usize) -> LoginResult<Login> {
    for _ in 0..times {
        e.touch(&id)?;
    }
    Ok(e.get(&id)?.unwrap())
}

pub fn sync_logins(client: &mut TestClient) -> Result<(), failure::Error> {
    let (init, key, _device_id) = client.data_for_sync()?;
    client.logins_engine.sync(&init, &key)?;
    Ok(())
}

// Actual tests.

fn test_login_general(c0: &mut TestClient, c1: &mut TestClient) {
    log::info!("Add some logins to client0");

    let l0id = "aaaaaaaaaaaa";
    let l1id = "bbbbbbbbbbbb";

    add_login(
        &c0.logins_engine,
        Login {
            guid: l0id.into(),
            hostname: "http://www.example.com".into(),
            form_submit_url: Some("http://login.example.com".into()),
            username: "cool_username".into(),
            password: "hunter2".into(),
            username_field: "uname".into(),
            password_field: "pword".into(),
            ..Login::default()
        },
    )
    .expect("add l0");

    let login0_c0 = touch_login(&c0.logins_engine, l0id, 2).expect("touch0 c0");
    assert_eq!(login0_c0.times_used, 3);

    let login1_c0 = add_login(
        &c0.logins_engine,
        Login {
            guid: l1id.into(),
            hostname: "http://www.example.com".into(),
            http_realm: Some("Login".into()),
            username: "cool_username".into(),
            password: "sekret".into(),
            ..Login::default()
        },
    )
    .expect("add l1");

    log::info!("Syncing client0");
    sync_logins(c0).expect("c0 sync to work");

    // Should be the same after syncing.
    verify_login(&c0.logins_engine, &login0_c0);
    verify_login(&c0.logins_engine, &login1_c0);

    log::info!("Syncing client1");
    sync_logins(c1).expect("c1 sync to work");

    log::info!("Check state");

    verify_login(&c1.logins_engine, &login0_c0);
    verify_login(&c1.logins_engine, &login1_c0);

    assert_eq!(
        times_used_for_id(&c1.logins_engine, l0id),
        3,
        "Times used is wrong (first sync)"
    );

    log::info!("Update logins");

    // Change login0 on both
    update_login(&c1.logins_engine, l0id, |l| {
        l.password = "testtesttest".into();
    })
    .unwrap();

    let login0_c0 = update_login(&c0.logins_engine, l0id, |l| {
        l.username_field = "users_name".into();
    })
    .unwrap();

    // and login1 on remote.
    let login1_c1 = update_login(&c1.logins_engine, l1id, |l| {
        l.username = "less_cool_username".into();
    })
    .unwrap();

    log::info!("Sync again");

    sync_logins(c1).expect("c1 sync 2");
    sync_logins(c0).expect("c0 sync 2");

    log::info!("Check state again");

    // Ensure the remotely changed password change made it through
    verify_login(&c0.logins_engine, &login1_c1);

    // And that the conflicting one did too.
    verify_login(
        &c0.logins_engine,
        &Login {
            username_field: "users_name".into(),
            password: "testtesttest".into(),
            ..login0_c0
        },
    );

    assert_eq!(
        c0.logins_engine.get(l0id).unwrap().unwrap().times_used,
        5, // initially 1, touched twice, updated twice (on two accounts!
        // doing this right requires 3WM)
        "Times used is wrong (final)"
    );
}

fn test_login_deletes(c0: &mut TestClient, c1: &mut TestClient) {
    log::info!("Add some logins to client0");

    let l0id = "aaaaaaaaaaaa";
    let l1id = "bbbbbbbbbbbb";
    let l2id = "cccccccccccc";
    let l3id = "dddddddddddd";

    let login0 = add_login(
        &c0.logins_engine,
        Login {
            guid: l0id.into(),
            hostname: "http://www.example.com".into(),
            form_submit_url: Some("http://login.example.com".into()),
            username: "cool_username".into(),
            password: "hunter2".into(),
            username_field: "uname".into(),
            password_field: "pword".into(),
            ..Login::default()
        },
    )
    .expect("add l0");

    let login1 = add_login(
        &c0.logins_engine,
        Login {
            guid: l1id.into(),
            hostname: "http://www.example.com".into(),
            http_realm: Some("Login".into()),
            username: "cool_username".into(),
            password: "sekret".into(),
            ..Login::default()
        },
    )
    .expect("add l1");

    let login2 = add_login(
        &c0.logins_engine,
        Login {
            guid: l2id.into(),
            hostname: "https://www.example.org".into(),
            http_realm: Some("Test".into()),
            username: "cool_username100".into(),
            password: "123454321".into(),
            ..Login::default()
        },
    )
    .expect("add l2");

    let login3 = add_login(
        &c0.logins_engine,
        Login {
            guid: l3id.into(),
            hostname: "https://www.example.net".into(),
            http_realm: Some("Http Realm".into()),
            username: "cool_username99".into(),
            password: "aaaaa".into(),
            ..Login::default()
        },
    )
    .expect("add l3");

    log::info!("Syncing client0");

    sync_logins(c0).expect("c0 sync to work");

    // Should be the same after syncing.
    verify_login(&c0.logins_engine, &login0);
    verify_login(&c0.logins_engine, &login1);
    verify_login(&c0.logins_engine, &login2);
    verify_login(&c0.logins_engine, &login3);

    log::info!("Syncing client1");
    sync_logins(c1).expect("c1 sync to work");

    log::info!("Check state");
    verify_login(&c1.logins_engine, &login0);
    verify_login(&c1.logins_engine, &login1);
    verify_login(&c1.logins_engine, &login2);
    verify_login(&c1.logins_engine, &login3);

    // The 4 logins are for the for possible scenarios. All of them should result in the record
    // being deleted.

    // 1. Client A deletes record, client B has no changes (should delete).
    // 2. Client A deletes record, client B has also deleted record (should delete).
    // 3. Client A deletes record, client B has modified record locally (should delete).
    // 4. Same as #3 but in reverse order.

    // case 1. (c1 deletes record, c0 should have deleted on the other side)
    log::info!("Deleting {} from c1", l0id);
    assert!(c1.logins_engine.delete(l0id).expect("Delete should work"));
    verify_missing_login(&c1.logins_engine, l0id);

    // case 2. Both delete l1 separately
    log::info!("Deleting {} from both", l1id);
    assert!(c0.logins_engine.delete(l1id).expect("Delete should work"));
    assert!(c1.logins_engine.delete(l1id).expect("Delete should work"));

    // case 3a. c0 modifies record (c1 will delete it after c0 syncs so the timestamps line up)
    log::info!("Updating {} on c0", l2id);
    let login2_new = update_login(&c0.logins_engine, l2id, |l| {
        l.username = "foobar".into();
    })
    .unwrap();

    // case 4a. c1 deletes record (c0 will modify it after c1 syncs so the timestamps line up)
    assert!(c1.logins_engine.delete(l3id).expect("Delete should work"));

    // Sync c1
    log::info!("Syncing c1");
    sync_logins(c1).expect("c1 sync to work");
    log::info!("Checking c1 state after sync");

    verify_missing_login(&c1.logins_engine, l0id);
    verify_missing_login(&c1.logins_engine, l1id);
    verify_login(&c1.logins_engine, &login2);
    verify_missing_login(&c1.logins_engine, l3id);

    log::info!("Update {} on c0", l3id);
    // 4b
    update_login(&c0.logins_engine, l3id, |l| {
        l.password = "quux".into();
    })
    .unwrap();

    // Sync c0
    log::info!("Syncing c0");
    sync_logins(c0).expect("c0 sync to work");

    log::info!("Checking c0 state after sync");

    verify_missing_login(&c0.logins_engine, l0id);
    verify_missing_login(&c0.logins_engine, l1id);
    verify_login(&c0.logins_engine, &login2_new);
    verify_missing_login(&c0.logins_engine, l3id);

    log::info!("Delete {} on c1", l2id);
    // 3b
    assert!(c1.logins_engine.delete(l2id).expect("Delete should work"));

    log::info!("Syncing c1");
    sync_logins(c1).expect("c1 sync to work");

    log::info!("{} should stay dead", l2id);
    // Ensure we didn't revive it.
    verify_missing_login(&c1.logins_engine, l2id);

    log::info!("Syncing c0");
    sync_logins(c0).expect("c0 sync to work");
    log::info!("Should delete {}", l2id);
    verify_missing_login(&c0.logins_engine, l2id);
}

pub fn get_test_group() -> TestGroup {
    TestGroup::new(
        "logins",
        vec![
            ("test_login_general", test_login_general),
            ("test_login_deletes", test_login_deletes),
        ],
    )
}
