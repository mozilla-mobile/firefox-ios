/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This example demonstrates how our "cooperative transactions" work.
// Execute with a cmdline something like:
// % RUST_LOG=places::db::tx=debug cargo run --example check-coop-tx

use places::api::places_api::ConnectionType;
use places::PlacesDb;
use rusqlite::NO_PARAMS;
use std::fs::remove_file;
use std::sync::mpsc::sync_channel;
use std::sync::{Arc, Mutex};
use std::thread;

type Result<T> = std::result::Result<T, failure::Error>;

fn update(t: &PlacesDb, n: u32) -> Result<()> {
    t.execute(
        &format!(
            "INSERT INTO moz_places (guid, url, url_hash)
                VALUES ('fake_{n:07}', 'http://example.com/{n}', hash('http://example.com/{n}'))",
            n = n
        ),
        NO_PARAMS,
    )?;
    Ok(())
}

fn main() -> Result<()> {
    let path = "./test.db";

    let _ = remove_file(path); // ignore error
    let _ = env_logger::try_init();

    let coop_tx_lock = Arc::new(Mutex::new(()));

    let dbmain = PlacesDb::open(path, ConnectionType::ReadWrite, 0, coop_tx_lock.clone()).unwrap();
    let (tx, rx) = sync_channel(0);

    let child = thread::spawn(move || {
        let db1 = PlacesDb::open(path, ConnectionType::Sync, 0, coop_tx_lock.clone()).unwrap();
        // assert_eq!(rx.recv().unwrap(), 0);
        let mut t = db1
            .begin_transaction()
            .expect("should get the thread transaction");
        println!("inner has tx");
        tx.send(0).unwrap();
        for i in 0..100_000 {
            update(&db1, i).unwrap();
            t.maybe_commit().unwrap();
        }
        t.commit().unwrap();

        println!("finished inner thread");
    });

    let _ = rx.recv().unwrap();
    println!("inner thread has tx lock, so charging ahead...");
    for i in 100_000..100_020 {
        let tx = dbmain
            .begin_transaction()
            .expect("should get the main transaction");
        update(&dbmain, i).unwrap();
        tx.commit().expect("main thread should commit");
        println!("main thread commited");
    }
    println!("completed outer, waiting for thread to complete.");

    child.join().unwrap();

    Ok(())
}
