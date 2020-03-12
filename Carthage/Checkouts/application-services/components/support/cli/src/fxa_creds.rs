/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Utilities for command-line utilities which want to use fxa credentials.

use crate::prompt::prompt_string;
use fxa_client::{error, AccessTokenInfo, Config, FirefoxAccount};
use std::collections::HashMap;
use std::{
    fs,
    io::{Read, Write},
};
use sync15::{KeyBundle, Sync15StorageClientInit};
use url::Url;
use webbrowser;

type Result<T> = std::result::Result<T, failure::Error>;

// Defaults - not clear they are the best option, but they are a currently
// working option.
const CLIENT_ID: &str = "e7ce535d93522896";
const REDIRECT_URI: &str = "https://lockbox.firefox.com/fxa/android-redirect.html";
const SYNC_SCOPE: &str = "https://identity.mozilla.com/apps/oldsync";

fn load_fxa_creds(path: &str) -> Result<FirefoxAccount> {
    let mut file = fs::File::open(path)?;
    let mut s = String::new();
    file.read_to_string(&mut s)?;
    Ok(FirefoxAccount::from_json(&s)?)
}

fn load_or_create_fxa_creds(path: &str, cfg: Config) -> Result<FirefoxAccount> {
    load_fxa_creds(path).or_else(|e| {
        log::info!(
            "Failed to load existing FxA credentials from {:?} (error: {}), launching OAuth flow",
            path,
            e
        );
        create_fxa_creds(path, cfg)
    })
}

fn create_fxa_creds(path: &str, cfg: Config) -> Result<FirefoxAccount> {
    let mut acct = FirefoxAccount::with_config(cfg);
    let oauth_uri = acct.begin_oauth_flow(&[SYNC_SCOPE])?;

    if webbrowser::open(&oauth_uri.as_ref()).is_err() {
        log::warn!("Failed to open a web browser D:");
        println!("Please visit this URL, sign in, and then copy-paste the final URL below.");
        println!("\n    {}\n", oauth_uri);
    } else {
        println!("Please paste the final URL below:\n");
    }

    let final_url = url::Url::parse(&prompt_string("Final URL").unwrap_or_default())?;
    let query_params = final_url
        .query_pairs()
        .into_owned()
        .collect::<HashMap<String, String>>();

    acct.complete_oauth_flow(&query_params["code"], &query_params["state"])?;
    // Device registration.
    acct.initialize_device("CLI Device", fxa_client::device::Type::Desktop, &[])?;
    let mut file = fs::File::create(path)?;
    write!(file, "{}", acct.to_json()?)?;
    file.flush()?;
    Ok(acct)
}

// Our public functions. It would be awesome if we could somehow integrate
// better with clap, so we could automagically support various args (such as
// the config to use or filenames to read), but this will do for now.
pub fn get_default_fxa_config() -> Config {
    Config::release(CLIENT_ID, REDIRECT_URI)
}

fn get_account_and_token(
    config: Config,
    cred_file: &str,
) -> Result<(FirefoxAccount, AccessTokenInfo)> {
    // TODO: we should probably set a persist callback on acct?
    let mut acct = load_or_create_fxa_creds(cred_file, config.clone())?;
    // `scope` could be a param, but I can't see it changing.
    match acct.get_access_token(SYNC_SCOPE) {
        Ok(t) => Ok((acct, t)),
        Err(e) => {
            match e.kind() {
                // We can retry an auth error.
                error::ErrorKind::RemoteError { code: 401, .. } => {
                    println!("Saw an auth error using stored credentials - recreating them...");
                    acct = create_fxa_creds(cred_file, config)?;
                    let token = acct.get_access_token(SYNC_SCOPE)?;
                    Ok((acct, token))
                }
                _ => Err(e.into()),
            }
        }
    }
}

pub fn get_cli_fxa(config: Config, cred_file: &str) -> Result<CliFxa> {
    let tokenserver_url = config.token_server_endpoint_url()?;
    let (acct, token_info) = match get_account_and_token(config, cred_file) {
        Ok(v) => v,
        Err(e) => failure::bail!("Failed to use saved credentials. {}", e),
    };
    let key = token_info.key.unwrap();

    let client_init = Sync15StorageClientInit {
        key_id: key.kid.clone(),
        access_token: token_info.token.clone(),
        tokenserver_url: tokenserver_url.clone(),
    };
    let root_sync_key = KeyBundle::from_ksync_bytes(&key.key_bytes()?)?;

    Ok(CliFxa {
        account: acct,
        client_init,
        tokenserver_url,
        root_sync_key,
    })
}

pub struct CliFxa {
    pub account: FirefoxAccount,
    pub client_init: Sync15StorageClientInit,
    pub tokenserver_url: Url,
    pub root_sync_key: KeyBundle,
}
