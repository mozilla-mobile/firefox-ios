/* Any copyright is dedicated to the Public Domain.
http://creativecommons.org/publicdomain/zero/1.0/ */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use structopt::StructOpt;

mod auth;
mod logins;
mod tabs;
mod testing;

use crate::auth::{FxaConfigUrl, TestUser};
use crate::testing::TestGroup;

macro_rules! cleanup_clients {
    ($($client:expr),+) => {
        crate::auth::cleanup_server(vec![$($client),+]).expect("Remote cleanup failed");
        $($client.fully_reset_local_db().expect("Failed to reset client");)+
    };
}

pub fn init_testing() {
    // Enable backtraces.
    std::env::set_var("RUST_BACKTRACE", "1");
    // Turn on trace logging for everything except for a few crates (mostly from
    // our network stack) that happen to be particularly noisy (even on `info`
    // level), which get turned on at the warn level. This can still be
    // overridden with RUST_LOG, however.
    let log_filter = "trace,tokio_threadpool=warn,tokio_reactor=warn,tokio_core=warn,tokio=warn,\
         hyper=warn,want=warn,mio=warn,reqwest=warn,trust_dns_proto=warn,trust_dns_resolver=warn";
    env_logger::init_from_env(env_logger::Env::default().filter_or("RUST_LOG", log_filter));
}

pub fn run_test_groups(opts: &Opts, groups: Vec<TestGroup>) {
    let mut user = TestUser::new(opts, 2).expect("Failed to get test user.");
    let (c0, c1) = {
        let (c0s, c1s) = user.clients.split_at_mut(1);
        (&mut c0s[0], &mut c1s[0])
    };
    log::info!("+ Testing {} groups", groups.len());
    for group in groups {
        log::info!("++ TestGroup begin {}", group.name);
        for (name, test) in group.tests {
            log::info!("+++ Test begin {}::{}", group.name, name);
            test(c0, c1);
            log::info!("+++ Test cleanup {}::{}", group.name, name);
            cleanup_clients!(c0, c1);
            log::info!("+++ Test finish {}::{}", group.name, name);
        }
        log::info!("++ TestGroup end {}", group.name);
    }
    log::info!("+ Test groups finished");
}

// Note: this uses doc comments to generate the help text.
#[derive(Clone, Debug, StructOpt)]
#[structopt(name = "sync-test", about = "Sync integration tests")]
pub struct Opts {
    #[structopt(name = "oauth-retries", long, short = "r", default_value = "0")]
    /// Number of times to retry authentication with FxA if automatically
    /// logging in with OAuth fails (Sadly, it seems inherently finnicky).
    pub oauth_retries: u64,

    #[structopt(name = "oauth-retry-delay", long, default_value = "5000")]
    /// Number of milliseconds to wait between retries. Does nothing if
    /// `oauth-retries` is 0.
    pub oauth_delay_time: u64,

    #[structopt(name = "oauth-retry-delay-backoff", long, default_value = "2000")]
    /// Number of milliseconds to increase `oauth-retry-delay` with after each
    /// failure. Does nothing if `oauth-retries` is 0.
    pub oauth_retry_backoff: u64,

    #[structopt(name = "fxa-stack", short = "s", long, default_value = "stable-dev")]
    /// Either 'release', 'stage', 'stable-dev', or a URL.
    pub fxa_stack: FxaConfigUrl,

    #[structopt(name = "force-username", long)]
    /// Force the username portion of the restmail email. Must be a valid username,
    /// note that the username is also used for the password. See also
    /// `--no-delete-account`, which is useful in combination with this.
    pub force_username: Option<String>,

    #[structopt(name = "no-delete-account", long)]
    /// Disable deleting the fx account after use. Incompatible with oauth-retries.
    pub no_delete_account: bool,

    #[structopt(name = "helper-debug", long)]
    /// Run the helper browser as non-headless, and enable extra logging
    pub helper_debug: bool,
    // TODO: allow specifying which test groups to use.
}

pub fn main() {
    let opts = Opts::from_args();
    println!("### Running sync integration tests ###");
    init_testing();
    run_test_groups(&opts, vec![crate::logins::get_test_group()]);
    run_test_groups(&opts, vec![crate::tabs::get_test_group()]);
    println!("### Sync integration tests passed!");
}
