/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use cli_support::fxa_creds::{get_cli_fxa, get_default_fxa_config};
use cli_support::prompt::prompt_char;
use clipboard::{ClipboardContext, ClipboardProvider};
use tabs::{RemoteTab, TabsEngine};

type Result<T> = std::result::Result<T, failure::Error>;

fn main() -> Result<()> {
    let matches = clap::App::new("tabs_sync")
        .about("CLI for Sync tabs engine")
        .arg(
            clap::Arg::with_name("credential_file")
                .short("c")
                .long("credentials")
                .value_name("CREDENTIAL_JSON")
                .takes_value(true)
                .help(
                    "Path to store our cached fxa credentials (defaults to \"./credentials.json\"",
                ),
        )
        .get_matches();
    let cred_file = matches
        .value_of("credential_file")
        .unwrap_or("./credentials.json");

    let mut cli_fxa = get_cli_fxa(get_default_fxa_config(), &cred_file)?;
    let device_id = cli_fxa.account.get_current_device_id()?;

    let mut engine = TabsEngine::new();

    loop {
        match prompt_char("[U]pdate local state, [L]ist remote tabs, [S]ync or [Q]uit")
            .unwrap_or('?')
        {
            'U' | 'u' => {
                log::info!("Updating the local state.");
                let local_state = read_local_state();
                dbg!(&local_state);
                engine.update_local_state(local_state);
            }
            'L' | 'l' => {
                log::info!("Listing remote tabs.");
                let tabs_and_clients = match engine.remote_tabs() {
                    Some(tc) => tc,
                    None => {
                        println!("No remote tabs! Did you try syncing first?");
                        continue;
                    }
                };
                println!("--------------------------------");
                for tabs_and_client in tabs_and_clients {
                    println!("> {}", tabs_and_client.client_id);
                    for tab in tabs_and_client.remote_tabs {
                        let (first, rest) = tab.url_history.split_first().unwrap();
                        println!("  - {} ({})", tab.title, first);
                        for url in rest {
                            println!("      {}", url);
                        }
                    }
                }
                println!("--------------------------------");
            }
            'S' | 's' => {
                log::info!("Syncing!");
                match engine.sync(&cli_fxa.client_init, &cli_fxa.root_sync_key, &device_id) {
                    Err(e) => {
                        log::warn!("Sync failed! {}", e);
                    }
                    Ok(sync_ping) => {
                        log::info!("Sync was successful!");
                        log::info!(
                            "Sync telemetry: {}",
                            serde_json::to_string_pretty(&sync_ping).unwrap()
                        );
                    }
                }
            }
            'Q' | 'q' => {
                break;
            }
            '?' => {
                continue;
            }
            c => {
                println!("Unknown action '{}', exiting.", c);
                break;
            }
        }
    }
    Ok(())
}

fn read_local_state() -> Vec<RemoteTab> {
    println!("Please run the following command in the Firefox Browser Toolbox and copy it.");
    println!(
        "   JSON.stringify(await Weave.Service.engineManager.get(\"tabs\")._store.getAllTabs())"
    );
    println!("Because of platform limitations, we can't let you paste a long string here.");
    println!("So instead we'll read from your clipboard. Press ENTER when ready!");

    prompt_char("Ready?").unwrap_or_default();

    let mut ctx: ClipboardContext = ClipboardProvider::new().unwrap();
    let json = ctx.get_contents().unwrap();

    // Yeah we double parse coz the devtools console wraps the result in quotes. Sorry.
    let json: serde_json::Value = serde_json::from_str(&json).unwrap();
    let json: serde_json::Value = serde_json::from_str(json.as_str().unwrap()).unwrap();

    let tabs = json.as_array().unwrap();

    let mut local_state = vec![];
    for tab in tabs {
        let title = tab["title"].as_str().unwrap().to_owned();
        let last_used = tab["lastUsed"].as_u64().unwrap();
        let icon = tab["icon"]
            .as_str()
            .map(|s| Some(s.to_owned()))
            .unwrap_or(None);
        let url_history = tab["urlHistory"].as_array().unwrap();
        let url_history = url_history
            .iter()
            .map(|u| u.as_str().unwrap().to_owned())
            .collect();
        local_state.push(RemoteTab {
            title,
            url_history,
            icon,
            last_used,
        });
    }
    local_state
}
