use cli_support::prompt::prompt_string;
use fxa_client::FirefoxAccount;
use std::collections::HashMap;
use url::Url;

const CONTENT_SERVER: &str = "http://127.0.0.1:3030";
const CLIENT_ID: &str = "7f368c6886429f19";
const REDIRECT_URI: &str = "https://mozilla.github.io/notes/fxa/android-redirect.html";
const SCOPES: &[&str] = &["https://identity.mozilla.com/apps/oldsync"];

fn main() {
    let mut fxa = FirefoxAccount::new(CONTENT_SERVER, CLIENT_ID, REDIRECT_URI);
    let url = fxa.begin_oauth_flow(&SCOPES).unwrap();
    println!("Open the following URL:");
    println!("{}", url);
    let redirect_uri: String = prompt_string("Obtained redirect URI").unwrap();
    let redirect_uri = Url::parse(&redirect_uri).unwrap();
    let query_params: HashMap<_, _> = redirect_uri.query_pairs().into_owned().collect();
    let code = &query_params["code"];
    let state = &query_params["state"];
    fxa.complete_oauth_flow(&code, &state).unwrap();
    let oauth_info = fxa.get_access_token(SCOPES[0]);
    println!("access_token: {:?}", oauth_info);
}
