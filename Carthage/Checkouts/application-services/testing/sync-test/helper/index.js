/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// TODO: This whole thing probably should be in rust (replace Nightmare with
// fantoccini maybe?)

// DEBUGGING NOTES:
// - set `DEBUG=nightmare` in your environment for more logging
// - set `HEADLESS = false` below to display a window for nightmare.
//   Particularly useful if this script is failing on command == "oauth"

const crypto = require("crypto");
const Nightmare = require("nightmare");
require("isomorphic-fetch");

// It's cludgey to pass this like this, but simpler than parsing arguments
const HEADLESS = process.env.HELPER_SHOW_BROWSER != "1";
// Used to opt out of FxA authentication A/B tests, see
// https://github.com/mozilla/fxa-content-server/blob/e882f50/tests/tools/firefox_profile_creator.js#L5
const USERAGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.10; rv:40.0) Gecko/20100101 Firefox/40.0 FxATester/1.0";

// Log an informational message to stderr (which won't be interpreted by
// the Rust code as being part of the actual program output).
function logInfo(message, ...prettyPrintObjects) {
    process.stderr.write(`integration-test-helper: ${message}\n`);
    for (let thing of prettyPrintObjects) {
        console.error("integration-test-helper:   ", thing);
    }
}

// Called when this script gets the `oauth` argument. Goes through the oauth flow using a
// headless browser, possibly
async function oauthCommand(emailAddr, password, fxaAuthUrl, oauthFlowUrl) {
    // Delete trailing '/' if present.
    fxaAuthUrl = fxaAuthUrl.replace(/\/$/, '');

    // Clear our restmail pre-emptively in case we need to verify. This might not be
    // necessary given that we use the latest email now, but doesn't really hurt.
    await clearRestmail(emailAddr);

    const nightmare = Nightmare({
        show: !HEADLESS,
        // Number of milliseconds between simulated keypresses.
        // Default is 100 which makes this whole process much slower
        // than it needs to be.
        typeInterval: 10,
        // Wait for 25 seconds for a selector we're `wait`ing on to appear. We want
        // this to be fairly forgiving since it includes page transitions, redirects,
        // us waiting for the confirmation push message, etc.
        waitTimeout: 25000,
    });

    logInfo("Launching headless browser to perform the oauth flow (this can be slow...)");
    try {
        let needConfirmation = await nightmare
            .useragent(USERAGENT)
            .goto(oauthFlowUrl)
            .wait(".email[name='email']")
            .type(".email[name='email']", emailAddr)

            .wait("#submit-btn")
            .click("#submit-btn")

            .wait("#password")
            .type("#password", password)

            .wait("#submit-btn")
            .click("#submit-btn")

            // `body > p` indicates we're on the (quite simple) lockbox redirect page
            // `#fxa-signin-code-header` indicates that we actually got told we need to confirm the
            // sign in.
            .wait("#fxa-oauth-success-header, #fxa-signin-code-header")
            .exists("#fxa-signin-code-header");

        if (needConfirmation) {
            // Sign in confirmation. Doesn't happen on prod, happens (AFAICT) every time on dev
            logInfo("Need to do sign-in confirmation, attempting to do so through restmail...");
            let code = await restmailFindLoginCode(emailAddr);
            await nightmare
                .wait(".otp-code[type='text']")
                .type(".otp-code[type='text']", code)
                .wait("button[type='submit']")
                .click("button[type='submit']");
        } else {
            logInfo("Don't need sign-in confirmation, waiting for redirect instead.");
        }

        // We should be automatically redirected to the lockbox redirect page soon enough (if we
        // haven't already been), so wait for that and get the page's location.
        let redirectUrl = await nightmare
            .wait("#fxa-oauth-success-header")
            .evaluate(() => window.location.href);

        logInfo("Got redirect URL: " + redirectUrl);

        // Print the redirect URL to stdout. This should be the only thing we write to it,
        // since all our logging is done over stderr.
        console.log(redirectUrl);
    } catch (e) {
        logInfo(`ERROR: something threw ${e}`, e);
        throw e;
    } finally {
        // Close the browser.
        logInfo("Closing headless browser window");
        await nightmare.end();
    }
}

// Identical to fetch but rejects and logs some info if the request is a non-success code
async function request(uri, ...args) {
    let resp = await fetch(uri, ...args);
    if (!resp.ok) {
        logInfo(`Error: Got HTTP status ${resp.status} during request:`,
            "Requesting " + uri,
            resp);
        logInfo("    Response body: " + await resp.text());
        throw new Error(`HTTP status ${resp.status} (${resp.statusText})`);
    }
    return resp;
}

async function clearRestmail(emailAddr) {
    const mailboxUrl = restmailUrl(emailAddr);
    logInfo("Clearing restmail for " + emailAddr);
    await request(mailboxUrl, {
        method: "DELETE"
    });
}

function genAuthPW(email, password) {
    // This is based on a utility script I wrote a while back, which in turn was derived from
    // https://github.com/mozilla/fxa-auth-server/wiki/onepw-protocol#creating-the-account and
    // https://searchfox.org/mozilla-central/source/services/fxaccounts/Credentials.jsm.
    let qs = crypto.pbkdf2Sync(
        password,
        "identity.mozilla.com/picl/v1/quickStretch:" + email,
        1000, 32, "sha256");

    let digest = crypto.createHmac("sha256", Buffer.alloc(8 * 4))
        .update(qs).digest();

    digest = crypto.createHmac("sha256", digest)
        .update("identity.mozilla.com/picl/v1/authPW\x01").digest();

    return digest.toString("hex");
}

function restmailUsername(email) {
    const restmailUser = email.replace(/@restmail\.net$/, "");

    if (restmailUser.length == email.length) {
        logInfo("Error: Not a restmail account (doesn't end with @restmail.net): " + email);
        throw new Error("Invalid restmail account");
    }

    return restmailUser;
}

function restmailUrl(email) {
    const restmailUser = restmailUsername(email);
    return `https://restmail.net/mail/${encodeURIComponent(restmailUser)}`;
}

async function delay(millis) {
    await new Promise(resolve => {
        setTimeout(() => resolve(), millis);
    });
}

async function findInRestmail(emailAddr, filterFn) {
    const maxTries = 10;
    const mailUrl = restmailUrl(emailAddr);
    logInfo(`Checking ${mailUrl} up to ${maxTries} times.`);

    for (let i = 0; i < maxTries; ++i) {
        let mailbox = await request(mailUrl).then(resp => resp.json());
        let matchingEmails = mailbox.filter(filterFn);

        if (matchingEmails.length == 0) {
            logInfo(`Failed to find matching email. Waiting ${i + 1} seconds and retrying.`);
            await delay((i + 1) * 1000);
            continue;
        }

        if (matchingEmails.length > 1) {
            logInfo(`Found ${matchingEmails.length} emails that applies (taking latest)`);
            matchingEmails.sort((a, b) => {
                let aTime = new Date(a.receivedAt);
                let bTime = new Date(b.receivedAt);
                return bTime - aTime;
            });
        }

        return matchingEmails[0];
    }

    logInfo(`Error: Failed to find email after ${maxTries} tries!`);
    throw new Error("Hit retry max!");
}

async function restmailVerifyAccount(authUrl, uid, emailAddr) {
    let verificationEmail = await findInRestmail(emailAddr, mail =>
        mail.headers["x-uid"] === uid &&
        mail.headers["x-template-name"] === "verify");
    await postJSON(`${authUrl}/v1/recovery_email/verify_code`, {
        uid: verificationEmail.headers["x-uid"],
        code: verificationEmail.headers["x-verify-code"],
    });
}

async function restmailFindLoginCode(emailAddr) {
    let verificationEmail = await findInRestmail(emailAddr, mail =>
        mail.headers["x-template-name"] == "verifyLoginCode");
    return verificationEmail.headers["x-signin-verify-code"];
}

async function postJSON(url, jsonBody) {
    const response = await request(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(jsonBody),
    });
    return response.json();
}

async function destroyCommand(emailAddr, password, authUrl) {
    // Delete trailing '/'
    authUrl = authUrl.replace(/\/$/, "");

    await postJSON(`${authUrl}/v1/account/destroy`, {
        email: emailAddr,
        authPW: genAuthPW(emailAddr, password),
    });

    logInfo("Account destroyed successfully!");
}

async function createCommand(emailAddr, password, authUrl) {
    // Delete trailing '/'
    authUrl = authUrl.replace(/\/$/, "");

    await clearRestmail(emailAddr);

    let {
        uid
    } = await postJSON(`${authUrl}/v1/account/create`, {
        email: emailAddr,
        authPW: genAuthPW(emailAddr, password),
    });

    logInfo(`POST /v1/account/create succeeded`);
    logInfo("Autoverifying account on restmail... uid = " + uid);

    await restmailVerifyAccount(authUrl, uid, emailAddr);

    logInfo("Account created and verified!");
}

const USAGE_HELP = `
Usage: <command> <username@restmail.net> <password> <auth_url> [<oauth_url>]

    <command>: either "create", "destroy", or "oauth".

    <auth_url>: The fxa "auth_server_base_url" as reported by a request to
                /.well-known/fxa-client-configuration.

    <oauth_url>: The URL we should use to perform the Oauth flow. This is
                 required if the command was "oauth" and forbidden otherwise.
`;

function usage(...args) {
    if (args.length) {
        logInfo(...args);
    }
    logInfo(USAGE_HELP);
    process.exit(2);
}

async function main(commandName, ...commandArgs) {
    const COMMANDS = {
        oauth: oauthCommand,
        create: createCommand,
        destroy: destroyCommand,
    };

    if (!COMMANDS.hasOwnProperty(commandName)) {
        usage("Error: Unknown command: " + commandName);
    }

    let commandFunc = COMMANDS[commandName];
    if (commandArgs.length != commandFunc.length) {
        usage(`Error: Wrong number of args, expected ${commandFunc.length}, got`, commandArgs);
    }

    logInfo(`Running command ${commandName} with args`, ...commandArgs);

    await commandFunc(...commandArgs);
}

// process.argv[0] is `node` and process.argv[1] is the path to our script.
main(...process.argv.slice(2)).catch(e => {
    logInfo("Error: ", e);
    process.exit(1);
});
