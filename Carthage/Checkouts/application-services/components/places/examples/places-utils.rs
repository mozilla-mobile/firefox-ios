/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use cli_support::fxa_creds::{get_cli_fxa, get_default_fxa_config};
use places::bookmark_sync::store::BookmarksStore;
use places::history_sync::store::HistoryStore;
use places::storage::bookmarks::{
    fetch_tree, insert_tree, BookmarkNode, BookmarkRootGuid, BookmarkTreeNode, FetchDepth,
    FolderNode, SeparatorNode,
};
use places::types::{BookmarkType, Timestamp};
use places::{ConnectionType, PlacesApi, PlacesDb};
use sync_guid::Guid as SyncGuid;

use failure::Fail;
use serde_derive::*;
use std::fs::File;
use std::io::{BufReader, BufWriter};
use structopt::StructOpt;
use sync15::{
    sync_multiple, MemoryCachedState, SetupStorageClient, Store, StoreSyncAssociation,
    Sync15StorageClient,
};
use url::Url;

type Result<T> = std::result::Result<T, failure::Error>;

fn init_logging() {
    // Explicitly ignore some rather noisy crates. Turn on trace for everyone else.
    let spec = "trace,tokio_threadpool=warn,tokio_reactor=warn,tokio_core=warn,tokio=warn,hyper=warn,want=warn,mio=warn,reqwest=warn";
    env_logger::init_from_env(env_logger::Env::default().filter_or("RUST_LOG", spec));
}

// A struct in the format of desktop with a union of all fields.
#[derive(Debug, Default, Deserialize)]
#[serde(default, rename_all = "camelCase")]
struct DesktopItem {
    type_code: u8,
    guid: Option<SyncGuid>,
    date_added: Option<u64>,
    last_modified: Option<u64>,
    title: Option<String>,
    uri: Option<Url>,
    children: Vec<DesktopItem>,
}

fn convert_node(dm: DesktopItem) -> Option<BookmarkTreeNode> {
    let bookmark_type = BookmarkType::from_u8_with_valid_url(dm.type_code, || dm.uri.is_some());

    Some(match bookmark_type {
        BookmarkType::Bookmark => {
            let url = match dm.uri {
                Some(uri) => uri,
                None => {
                    log::warn!("ignoring bookmark node without url: {:?}", dm);
                    return None;
                }
            };
            BookmarkNode {
                guid: dm.guid,
                date_added: dm.date_added.map(|v| Timestamp(v / 1000)),
                last_modified: dm.last_modified.map(|v| Timestamp(v / 1000)),
                title: dm.title,
                url,
            }
            .into()
        }
        BookmarkType::Separator => SeparatorNode {
            guid: dm.guid,
            date_added: dm.date_added.map(|v| Timestamp(v / 1000)),
            last_modified: dm.last_modified.map(|v| Timestamp(v / 1000)),
        }
        .into(),
        BookmarkType::Folder => FolderNode {
            guid: dm.guid,
            date_added: dm.date_added.map(|v| Timestamp(v / 1000)),
            last_modified: dm.last_modified.map(|v| Timestamp(v / 1000)),
            title: dm.title,
            children: dm.children.into_iter().filter_map(convert_node).collect(),
        }
        .into(),
    })
}

fn do_import(db: &PlacesDb, root: BookmarkTreeNode) -> Result<()> {
    // We need to import each of the sub-trees individually.
    // Later we will want to get smarter around guids - currently we will
    // fail to do this twice due to guid dupes - but that's OK for now.
    let folder = match root {
        BookmarkTreeNode::Folder(folder_node) => folder_node,
        _ => {
            println!("Imported node isn't a folder structure");
            return Ok(());
        }
    };
    let is_root = match folder.guid {
        Some(ref guid) => BookmarkRootGuid::Root == *guid,
        None => false,
    };
    if !is_root {
        // later we could try and import a sub-tree.
        println!("Imported tree isn't the root node");
        return Ok(());
    }

    for sub_root_node in folder.children {
        let sub_root_folder = match sub_root_node {
            BookmarkTreeNode::Folder(folder_node) => folder_node,
            _ => {
                println!("Child of the root isn't a folder - skipping...");
                continue;
            }
        };
        println!("importing {:?}", sub_root_folder.guid);
        insert_tree(db, &sub_root_folder)?
    }
    Ok(())
}

fn run_desktop_import(db: &PlacesDb, filename: String) -> Result<()> {
    println!("import from {}", filename);

    let file = File::open(filename)?;
    let reader = BufReader::new(file);
    let m: DesktopItem = serde_json::from_reader(reader)?;
    // convert mapping into our tree.
    let root = match convert_node(m) {
        Some(node) => node,
        None => {
            println!("Failed to read a tree from this file");
            return Ok(());
        }
    };
    do_import(db, root)
}

fn run_ios_import(api: &PlacesApi, filename: String) -> Result<()> {
    println!("ios import from {}", filename);
    places::import::import_ios_bookmarks(api, filename)?;
    println!("Import finished!");
    Ok(())
}

fn run_native_import(db: &PlacesDb, filename: String) -> Result<()> {
    println!("import from {}", filename);

    let file = File::open(filename)?;
    let reader = BufReader::new(file);

    let root: BookmarkTreeNode = serde_json::from_reader(reader)?;
    do_import(db, root)
}

fn run_native_export(db: &PlacesDb, filename: String) -> Result<()> {
    println!("export to {}", filename);

    let file = File::create(filename)?;
    let writer = BufWriter::new(file);

    let tree = fetch_tree(db, &BookmarkRootGuid::Root.into(), &FetchDepth::Deepest)?.unwrap();
    serde_json::to_writer_pretty(writer, &tree)?;
    Ok(())
}

#[allow(clippy::too_many_arguments)]
fn sync(
    api: &PlacesApi,
    mut engine_names: Vec<String>,
    cred_file: String,
    wipe_all: bool,
    wipe: bool,
    reset: bool,
    nsyncs: u32,
    wait: u64,
) -> Result<()> {
    let conn = api.open_sync_connection()?;

    // interrupts are per-connection, so we need to set that up here.
    let interrupt_handle = conn.new_interrupt_handle();

    ctrlc::set_handler(move || {
        println!("received Ctrl+C!");
        interrupt_handle.interrupt();
    })
    .expect("Error setting Ctrl-C handler");
    let interruptee = conn.begin_interrupt_scope();

    let cli_fxa = get_cli_fxa(get_default_fxa_config(), &cred_file)?;

    if wipe_all {
        Sync15StorageClient::new(cli_fxa.client_init.clone())?.wipe_all_remote()?;
    }
    // phew - working with traits is making markh's brain melt!
    // Note also that PlacesApi::sync() exists and ultimately we should
    // probably end up using that, but it's not yet ready to handle bookmarks.
    // And until we move to PlacesApi::sync() we simply do not persist any
    // global state at all (however, we do reuse the in-memory state).
    let mut mem_cached_state = MemoryCachedState::default();
    let mut global_state: Option<String> = None;
    let stores: Vec<Box<dyn Store>> = if engine_names.is_empty() {
        vec![
            Box::new(BookmarksStore::new(&conn, &interruptee)),
            Box::new(HistoryStore::new(&conn, &interruptee)),
        ]
    } else {
        engine_names.sort();
        engine_names.dedup();
        engine_names
            .into_iter()
            .map(|name| -> Box<dyn Store> {
                match name.as_str() {
                    "bookmarks" => Box::new(BookmarksStore::new(&conn, &interruptee)),
                    "history" => Box::new(HistoryStore::new(&conn, &interruptee)),
                    _ => unimplemented!("Can't sync unsupported engine {}", name),
                }
            })
            .collect()
    };
    for store in &stores {
        if wipe {
            store.wipe()?;
        }
        if reset {
            store.reset(&StoreSyncAssociation::Disconnected)?;
        }
    }

    // now the syncs.
    // For now we never persist the global state, which means we may lose
    // which engines are declined.
    // That's OK for the short term, and ultimately, syncing functionality
    // will be in places_api, which will give us this for free.

    // Migrate state, which we must do before we sync *any* engine.
    HistoryStore::migrate_v1_global_state(&conn)?;

    let mut error_to_report = None;
    let stores_to_sync: Vec<&dyn Store> = stores.iter().map(AsRef::as_ref).collect();

    for n in 0..nsyncs {
        let mut result = sync_multiple(
            &stores_to_sync,
            &mut global_state,
            &mut mem_cached_state,
            &cli_fxa.client_init.clone(),
            &cli_fxa.root_sync_key,
            &interruptee,
            None,
        );

        for (name, result) in result.engine_results.drain() {
            match result {
                Ok(()) => log::info!("Status for {:?}: Ok", name),
                Err(e) => {
                    log::warn!("Status for {:?}: {:?}", name, e);
                    error_to_report = Some(e);
                }
            }
        }

        match result.result {
            Err(e) => {
                log::warn!("Sync failed! {}", e);
                log::warn!("BT: {:?}", e.backtrace());
                error_to_report = Some(e);
            }
            Ok(()) => log::info!("Sync was successful!"),
        }

        println!("Sync service status: {:?}", result.service_status);
        println!(
            "Sync telemetry: {}",
            serde_json::to_string_pretty(&result.telemetry).unwrap()
        );

        if n < nsyncs - 1 {
            log::info!("Waiting {}ms before syncing again...", wait);
            std::thread::sleep(std::time::Duration::from_millis(wait));
        }
    }

    // return an error if any engine failed.
    match error_to_report {
        Some(e) => Err(e.into()),
        None => Ok(()),
    }
}

// Note: this uses doc comments to generate the help text.
#[derive(Clone, Debug, StructOpt)]
#[structopt(name = "places-utils", about = "Command-line utilities for places")]
pub struct Opts {
    #[structopt(
        name = "database_path",
        long,
        short = "d",
        default_value = "./places.db"
    )]
    /// Path to the database, which will be created if it doesn't exist.
    pub database_path: String,

    /// Leaves all logging disabled, which may be useful when evaluating perf
    #[structopt(name = "no-logging", long)]
    pub no_logging: bool,

    #[structopt(subcommand)]
    cmd: Command,
}

#[derive(Clone, Debug, StructOpt)]
enum Command {
    #[structopt(name = "sync")]
    /// Syncs all or some engines.
    Sync {
        #[structopt(name = "engines", long)]
        /// The names of the engines to sync. If not specified, all engines
        /// will be synced.
        engines: Vec<String>,

        /// Path to store our cached fxa credentials.
        #[structopt(name = "credentials", long, default_value = "./credentials.json")]
        credential_file: String,

        /// Wipe ALL storage from the server before syncing.
        #[structopt(name = "wipe-all-remote", long)]
        wipe_all: bool,

        /// Wipe the engine data from the server before syncing.
        #[structopt(name = "wipe-remote", long)]
        wipe: bool,

        /// Reset the store before syncing
        #[structopt(name = "reset", long)]
        reset: bool,

        /// Number of syncs to perform
        #[structopt(name = "nsyncs", long, default_value = "1")]
        nsyncs: u32,

        /// Number of milliseconds to wait between syncs
        #[structopt(name = "wait", long, default_value = "0")]
        wait: u64,
    },

    #[structopt(name = "export-bookmarks")]
    /// Exports bookmarks (but not in a way Desktop can import it!)
    ExportBookmarks {
        #[structopt(name = "output-file", long, short = "o")]
        /// The name of the output file where the json will be written.
        output_file: String,
    },

    #[structopt(name = "import-bookmarks")]
    /// Import bookmarks from a 'native' export (ie, as exported by this utility)
    ImportBookmarks {
        #[structopt(name = "input-file", long, short = "i")]
        /// The name of the file to read.
        input_file: String,
    },

    #[structopt(name = "import-ios-bookmarks")]
    /// Import bookmarks from an iOS browser.db
    ImportIosBookmarks {
        #[structopt(name = "input-file", long, short = "i")]
        /// The name of the file to read.
        input_file: String,
    },

    #[structopt(name = "import-desktop-bookmarks")]
    /// Import bookmarks from JSON file exported by desktop Firefox
    ImportDesktopBookmarks {
        #[structopt(name = "input-file", long, short = "i")]
        /// Imports bookmarks from a desktop export
        input_file: String,
    },
}

fn main() -> Result<()> {
    let opts = Opts::from_args();
    if !opts.no_logging {
        init_logging();
    }

    let db_path = opts.database_path;
    let api = PlacesApi::new(&db_path)?;
    let db = api.open_connection(ConnectionType::ReadWrite)?;

    match opts.cmd {
        Command::Sync {
            engines,
            credential_file,
            wipe_all,
            wipe,
            reset,
            nsyncs,
            wait,
        } => sync(
            &api,
            engines,
            credential_file,
            wipe_all,
            wipe,
            reset,
            nsyncs,
            wait,
        ),
        Command::ExportBookmarks { output_file } => run_native_export(&db, output_file),
        Command::ImportBookmarks { input_file } => run_native_import(&db, input_file),
        Command::ImportIosBookmarks { input_file } => run_ios_import(&api, input_file),
        Command::ImportDesktopBookmarks { input_file } => run_desktop_import(&db, input_file),
    }
}
