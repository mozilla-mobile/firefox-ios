/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use hex;

use push::communications::Connection;
use push::config::PushConfiguration;
use push::crypto::get_bytes;
use push::error::Result;
use push::subscriber::PushManager;

/** Perform a "Live" test against a locally configured push server
 *
 * See https://autopush.readthedocs.io/en/latest/testing.html on
 * setting up a local push server. This will also create a local
 * test database under "/tmp". This database should be deleted before
 * you re-run this test.
 *
 * NOTE: if you wish to do a "live" test inside of the kotlin layer,
 * See `PushTest.kt` and look for "LIVETEST".
 */

fn dummy_uuid() -> Result<String> {
    // Use easily findable "test" UUIDs
    Ok(format!(
        "deadbeef-{}-{}-{}-{}",
        hex::encode(&get_bytes(2)?),
        hex::encode(&get_bytes(2)?),
        hex::encode(&get_bytes(2)?),
        hex::encode(&get_bytes(6)?),
    ))
}

fn test_live_server() -> Result<()> {
    let config = PushConfiguration {
        http_protocol: Some("http".to_owned()),
        server_host: "localhost:8082".to_owned(),
        sender_id: "fir-bridgetest".to_owned(),
        bridge_type: Some("fcm".to_owned()),
        registration_id: Some("SomeRegistrationValue".to_owned()),
        ..Default::default()
    };
    let mut pm = PushManager::new(config)?;
    let channel1 = dummy_uuid()?;
    let channel2 = dummy_uuid()?;

    println!("Channels: [{}, {}]", channel1, channel2);

    println!("\n == Subscribing channels");
    let sub1 = pm.subscribe(&channel1, "", None).expect("subscribe failed");
    // These are normally opaque values, displayed here for debug.
    println!("Connection info: {:?}", (&pm.conn.uaid, &pm.conn.auth));
    println!("## Subscription 1: {:?}", sub1);
    println!("## Info: {:?}", pm.get_record_by_chid(&channel1));
    let sub2 = pm.subscribe(&channel2, "", None)?;
    println!("## Subscription 2: {:?}", sub2);

    // You don't need to do this, normally. This is just for
    // debugging and analysis.
    println!("\n == Fetching channel list 1");
    let ll = pm.conn.channel_list().expect("channel list failed");
    println!("Server Known channels: {:?}", ll);

    println!("\n == Unsubscribing single channel");
    pm.unsubscribe(Some(&channel1)).expect("chid unsub failed");
    println!("\n == Fetching channel list 2");
    let ll = pm.conn.channel_list().expect("channel list failed");
    println!("Server Known channels: {:?}", ll);

    // the list of known channels should come from whatever is
    // holding the index of channels to recipient applications.
    println!("Verify: {:?}", pm.verify_connection());

    println!("\n == Fetching channel list 3");
    let ll = pm.conn.channel_list().expect("channel list failed");
    println!("Server Known channels: {:?}", ll);

    println!("\n == Unsubscribing all.");
    // Unsubscribe all channels.
    pm.unsubscribe(None)?;

    println!("Done");
    Ok(())
}

fn main() -> Result<()> {
    test_live_server()
}
