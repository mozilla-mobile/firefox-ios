/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use cli_support::prompt::prompt_string;
use dialoguer::Select;
use fxa_client::{device, Config, FirefoxAccount, IncomingDeviceCommand};
use std::{
    collections::HashMap,
    fs,
    io::{Read, Write},
    sync::{Arc, Mutex},
    thread, time,
};
use url::Url;

static CREDENTIALS_PATH: &str = "credentials.json";
static CONTENT_SERVER: &str = "https://accounts.firefox.com";
static CLIENT_ID: &str = "a2270f727f45f648";
static REDIRECT_URI: &str = "https://accounts.firefox.com/oauth/success/a2270f727f45f648";
static SCOPES: &[&str] = &["profile", "https://identity.mozilla.com/apps/oldsync"];
static DEFAULT_DEVICE_NAME: &str = "Bobo device";

fn load_fxa_creds() -> Result<FirefoxAccount, failure::Error> {
    let mut file = fs::File::open(CREDENTIALS_PATH)?;
    let mut s = String::new();
    file.read_to_string(&mut s)?;
    Ok(FirefoxAccount::from_json(&s)?)
}

fn load_or_create_fxa_creds(cfg: Config) -> Result<FirefoxAccount, failure::Error> {
    let acct = load_fxa_creds().or_else(|_e| create_fxa_creds(cfg))?;
    persist_fxa_state(&acct);
    Ok(acct)
}

fn persist_fxa_state(acct: &FirefoxAccount) {
    let json = acct.to_json().unwrap();
    let mut file = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .truncate(true)
        .create(true)
        .open(CREDENTIALS_PATH)
        .unwrap();
    write!(file, "{}", json).unwrap();
    file.flush().unwrap();
}

fn create_fxa_creds(cfg: Config) -> Result<FirefoxAccount, failure::Error> {
    let mut acct = FirefoxAccount::with_config(cfg);
    let oauth_uri = acct.begin_oauth_flow(&SCOPES)?;

    if webbrowser::open(&oauth_uri.as_ref()).is_err() {
        println!("Please visit this URL, sign in, and then copy-paste the final URL below.");
        println!("\n    {}\n", oauth_uri);
    } else {
        println!("Please paste the final URL below:\n");
    }

    let redirect_uri: String = prompt_string("Final URL").unwrap();
    let redirect_uri = Url::parse(&redirect_uri).unwrap();
    let query_params: HashMap<_, _> = redirect_uri.query_pairs().into_owned().collect();
    let code = &query_params["code"];
    let state = &query_params["state"];
    acct.complete_oauth_flow(&code, &state).unwrap();
    persist_fxa_state(&acct);
    Ok(acct)
}

fn main() -> Result<(), failure::Error> {
    let cfg = Config::new(CONTENT_SERVER, CLIENT_ID, REDIRECT_URI);
    let mut acct = load_or_create_fxa_creds(cfg)?;

    // Make sure the device and the send-tab command are registered.
    acct.initialize_device(
        DEFAULT_DEVICE_NAME,
        device::Type::Desktop,
        &[device::Capability::SendTab],
    )
    .unwrap();
    persist_fxa_state(&acct);

    let acct: Arc<Mutex<FirefoxAccount>> = Arc::new(Mutex::new(acct));
    {
        let acct = acct.clone();
        thread::spawn(move || {
            loop {
                let evts = acct
                    .lock()
                    .unwrap()
                    .poll_device_commands()
                    .unwrap_or_else(|_| vec![]); // Ignore 404 errors for now.
                persist_fxa_state(&acct.lock().unwrap());
                for e in evts {
                    match e {
                        IncomingDeviceCommand::TabReceived { sender, payload } => {
                            let tab = &payload.entries[0];
                            match sender {
                                Some(ref d) => {
                                    println!("Tab received from {}: {}", d.display_name, tab.url)
                                }
                                None => println!("Tab received: {}", tab.url),
                            };
                            webbrowser::open(&tab.url).unwrap();
                        }
                    }
                }
                thread::sleep(time::Duration::from_secs(1));
            }
        });
    }

    // Menu:
    loop {
        println!("Main menu:");
        let mut main_menu = Select::new();
        main_menu.items(&["Set Display Name", "Send a Tab", "Quit"]);
        main_menu.default(0);
        let main_menu_selection = main_menu.interact().unwrap();

        match main_menu_selection {
            0 => {
                let new_name: String = prompt_string("New display name").unwrap();
                // Set device display name
                acct.lock().unwrap().set_device_name(&new_name).unwrap();
                println!("Display name set to: {}", new_name);
            }
            1 => {
                let devices = acct.lock().unwrap().get_devices().unwrap();
                let devices_names: Vec<String> =
                    devices.iter().map(|i| i.display_name.clone()).collect();
                let mut targets_menu = Select::new();
                targets_menu.default(0);
                let devices_names_refs: Vec<&str> =
                    devices_names.iter().map(AsRef::as_ref).collect();
                targets_menu.items(&devices_names_refs);
                println!("Choose a send-tab target:");
                let selection = targets_menu.interact().unwrap();
                let target = &devices[selection];

                // Payload
                let title: String = prompt_string("Title").unwrap();
                let url: String = prompt_string("URL").unwrap();
                acct.lock()
                    .unwrap()
                    .send_tab(&target.id, &title, &url)
                    .unwrap();
                println!("Tab sent!");
            }
            2 => ::std::process::exit(0),
            _ => panic!("Invalid choice!"),
        }
    }
}
