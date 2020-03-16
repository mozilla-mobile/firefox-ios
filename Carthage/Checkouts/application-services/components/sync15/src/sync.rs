/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::changeset::CollectionUpdate;
use crate::client::Sync15StorageClient;
use crate::clients;
use crate::coll_state::LocalCollStateMachine;
use crate::error::Error;
use crate::key_bundle::KeyBundle;
use crate::state::GlobalState;
use crate::telemetry;
use interrupt::Interruptee;

pub use sync15_traits::{IncomingChangeset, Store};

pub fn synchronize(
    client: &Sync15StorageClient,
    global_state: &GlobalState,
    root_sync_key: &KeyBundle,
    store: &dyn Store,
    fully_atomic: bool,
    telem_engine: &mut telemetry::Engine,
    interruptee: &dyn Interruptee,
) -> Result<(), crate::Error> {
    synchronize_with_clients_engine(
        client,
        global_state,
        root_sync_key,
        None,
        store,
        fully_atomic,
        telem_engine,
        interruptee,
    )
}

#[allow(clippy::too_many_arguments)]
pub fn synchronize_with_clients_engine(
    client: &Sync15StorageClient,
    global_state: &GlobalState,
    root_sync_key: &KeyBundle,
    clients: Option<&clients::Engine<'_>>,
    store: &dyn Store,
    fully_atomic: bool,
    telem_engine: &mut telemetry::Engine,
    interruptee: &dyn Interruptee,
) -> Result<(), Error> {
    let collection = store.collection_name();
    log::info!("Syncing collection {}", collection);

    // our global state machine is ready - get the collection machine going.
    let mut coll_state = match LocalCollStateMachine::get_state(store, global_state, root_sync_key)?
    {
        Some(coll_state) => coll_state,
        None => {
            // XXX - this is either "error" or "declined".
            log::warn!(
                "can't setup for the {} collection - hopefully it works later",
                collection
            );
            return Ok(());
        }
    };

    if let Some(clients) = clients {
        store.prepare_for_sync(&|| clients.get_client_data())?;
    }

    let collection_requests = store.get_collection_requests(coll_state.last_modified)?;
    let incoming = if collection_requests.is_empty() {
        log::info!("skipping incoming for {} - not needed.", collection);
        vec![IncomingChangeset::new(collection, coll_state.last_modified)]
    } else {
        assert_eq!(collection_requests.last().unwrap().collection, collection);

        let count = collection_requests.len();
        collection_requests
            .into_iter()
            .enumerate()
            .map(|(idx, collection_request)| {
                interruptee.err_if_interrupted()?;
                let incoming_changes =
                    crate::changeset::fetch_incoming(client, &mut coll_state, &collection_request)?;

                log::info!(
                    "Downloaded {} remote changes (request {} of {})",
                    incoming_changes.changes.len(),
                    idx,
                    count,
                );
                Ok(incoming_changes)
            })
            .collect::<Result<Vec<_>, Error>>()?
    };

    let new_timestamp = incoming.last().expect("must have >= 1").timestamp;
    let mut outgoing = store.apply_incoming(incoming, telem_engine)?;

    interruptee.err_if_interrupted()?;
    // Bump the timestamps now just incase the upload fails.
    // xxx - duplication below smells wrong
    outgoing.timestamp = new_timestamp;
    coll_state.last_modified = new_timestamp;

    log::info!("Uploading {} outgoing changes", outgoing.changes.len());
    let upload_info =
        CollectionUpdate::new_from_changeset(client, &coll_state, outgoing, fully_atomic)?
            .upload()?;

    log::info!(
        "Upload success ({} records success, {} records failed)",
        upload_info.successful_ids.len(),
        upload_info.failed_ids.len()
    );
    // ideally we'd report this per-batch, but for now, let's just report it
    // as a total.
    let mut telem_outgoing = telemetry::EngineOutgoing::new();
    telem_outgoing.sent(upload_info.successful_ids.len() + upload_info.failed_ids.len());
    telem_outgoing.failed(upload_info.failed_ids.len());
    telem_engine.outgoing(telem_outgoing);

    store.sync_finished(upload_info.modified_timestamp, upload_info.successful_ids)?;

    log::info!("Sync finished!");
    Ok(())
}
