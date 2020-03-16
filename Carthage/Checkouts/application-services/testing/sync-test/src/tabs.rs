/* Any copyright is dedicated to the Public Domain.
http://creativecommons.org/publicdomain/zero/1.0/ */

use crate::auth::TestClient;
use crate::testing::TestGroup;
use tabs::{ClientRemoteTabs, DeviceType, RemoteTab, TabsEngine};

// helpers...

pub fn verify_tabs(tabs_engine: &TabsEngine, expected: &ClientRemoteTabs) {
    let remote_tabs = tabs_engine
        .remote_tabs()
        .expect("should have synced already");
    let equivalent = remote_tabs
        .iter()
        .find(|rt| rt.client_id == expected.client_id)
        .expect("should have found the remote tabs");
    assert_remote_tabs_equiv(&equivalent, expected);
}

pub fn assert_remote_tabs_equiv(l: &ClientRemoteTabs, r: &ClientRemoteTabs) {
    assert_eq!(l.client_id, r.client_id);
    assert_eq!(l.remote_tabs.len(), r.remote_tabs.len());

    let iter = l.remote_tabs.iter().zip(r.remote_tabs.iter());
    for (l, r) in iter {
        assert_eq!(l.title, r.title);
        assert_eq!(l.icon, r.icon);
        assert_eq!(l.url_history, r.url_history);
        // last_used in stored in seconds on the server and we lose precision which
        // would make this assertion false if we compared strictly.
        assert_eq!((l.last_used / 1000) * 1000, (r.last_used / 1000) * 1000);
    }
}

pub fn sync_tabs(client: &mut TestClient) -> Result<(), failure::Error> {
    let (init, key, device_id) = client.data_for_sync()?;
    client.tabs_engine.sync(&init, &key, &device_id)?;
    Ok(())
}

// Actual tests.

fn test_tabs(c0: &mut TestClient, c1: &mut TestClient) {
    log::info!("Update tabs on c0");

    let t0 = RemoteTab {
        icon: None,
        last_used: 1_572_265_044_661,
        title: "Welcome to Bobo".to_owned(),
        url_history: vec!["https://bobo.moz".to_owned()],
    };
    c0.tabs_engine.update_local_state(vec![t0.clone()]);

    sync_tabs(c0).expect("c0 sync to work");
    sync_tabs(c1).expect("c1 sync to work");

    verify_tabs(
        &c1.tabs_engine,
        &ClientRemoteTabs {
            client_id: c0.fxa.get_current_device_id().unwrap(),
            client_name: String::new(),
            device_type: DeviceType::Mobile,
            remote_tabs: vec![t0],
        },
    );

    let t1 = RemoteTab {
        icon: None,
        last_used: 1_572_267_197_207,
        title: "Foo".to_owned(),
        url_history: vec!["https://foo.org".to_owned()],
    };
    let t2 = RemoteTab {
        icon: None,
        last_used: 1_572_267_191_104,
        title: "Bar".to_owned(),
        url_history: vec!["https://bar.org".to_owned()],
    };

    c1.tabs_engine
        .update_local_state(vec![t1.clone(), t2.clone()]);

    sync_tabs(c1).expect("c1 sync to work");
    sync_tabs(c0).expect("c0 sync to work");

    verify_tabs(
        &c0.tabs_engine,
        &ClientRemoteTabs {
            client_id: c1.fxa.get_current_device_id().unwrap(),
            client_name: String::new(),
            device_type: DeviceType::Mobile,
            remote_tabs: vec![t1, t2],
        },
    );
}

pub fn get_test_group() -> TestGroup {
    TestGroup::new("tabs", vec![("test_tabs", test_tabs)])
}
