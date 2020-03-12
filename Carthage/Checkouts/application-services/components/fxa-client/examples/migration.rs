use cli_support::prompt::prompt_string;
use fxa_client::FirefoxAccount;
use std::{thread, time};

static CLIENT_ID: &str = "3c49430b43dfba77";
static CONTENT_SERVER: &str = "https://accounts.firefox.com";
static REDIRECT_URI: &str = "https://accounts.firefox.com/oauth/success/3c49430b43dfba77";

fn main() {
    let mut fxa = FirefoxAccount::new(CONTENT_SERVER, CLIENT_ID, REDIRECT_URI);
    println!("Enter Session token (hex-string):");
    let session_token: String = prompt_string("session token").unwrap();
    println!("Enter kSync (hex-string):");
    let k_sync: String = prompt_string("k_sync").unwrap();
    println!("Enter kXCS (hex-string):");
    let k_xcs: String = prompt_string("k_xcs").unwrap();
    let migration_result =
        match fxa.migrate_from_session_token(&session_token, &k_sync, &k_xcs, true) {
            Ok(migration_result) => migration_result,
            Err(err) => {
                println!("Error: {}", err);
                // example for offline behaviour
                loop {
                    thread::sleep(time::Duration::from_millis(5000));
                    let retry = fxa.try_migration();
                    match retry {
                        Ok(result) => break result,
                        Err(_) => println!("Retrying... Are you connected to the internet?"),
                    }
                }
            }
        };
    println!("WOW! You've been migrated in {:?}.", migration_result);
    println!("JSON: {}", fxa.to_json().unwrap());
}
