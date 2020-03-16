/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use clap::value_t;
use failure::bail;
use places::{PlacesDb, VisitObservation, VisitTransition};
use rusqlite::NO_PARAMS;
use serde_derive::*;
use sql_support::ConnExt;
use std::io::prelude::*;
use std::{
    fs,
    path::{Path, PathBuf},
};
use url::Url;

type Result<T> = std::result::Result<T, failure::Error>;

#[derive(Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct SerializedObservation {
    pub url: String, // This is actually required but we check after deserializing
    pub title: Option<String>,
    pub visit_type: Option<u8>,
    pub error: bool,
    pub is_redirect_source: bool,
    pub at: Option<u64>,          // milliseconds
    pub referrer: Option<String>, // A URL
    pub remote: bool,
}

impl SerializedObservation {
    // We'd use TryFrom/TryInto but those are nightly only... :|
    pub fn into_visit(self) -> Result<VisitObservation> {
        let url = Url::parse(&self.url)?;
        let referrer = match self.referrer {
            Some(s) => Some(Url::parse(&s)?),
            _ => None,
        };
        let mut obs = VisitObservation::new(url)
            .with_title(self.title)
            .with_is_error(self.error)
            .with_is_remote(self.remote)
            .with_is_redirect_source(self.is_redirect_source)
            .with_referrer(referrer);
        if let Some(visit_type) = self.visit_type.and_then(VisitTransition::from_primitive) {
            obs = obs.with_visit_type(visit_type);
        }
        if let Some(time) = self.at {
            obs = obs.with_at(places::Timestamp(time));
        }
        Ok(obs)
    }
}

impl From<VisitObservation> for SerializedObservation {
    fn from(visit: VisitObservation) -> Self {
        Self {
            url: visit.url.to_string(),
            title: visit.title,
            visit_type: visit.visit_type.map(|vt| vt as u8),
            at: visit.at.map(Into::into),
            error: visit.is_error.unwrap_or(false),
            is_redirect_source: visit.is_redirect_source.unwrap_or(false),
            remote: visit.is_remote.unwrap_or(false),
            referrer: visit.referrer,
        }
    }
}

#[derive(Default, Clone, Debug)]
struct ImportPlacesOptions {
    pub remote_probability: f64,
}

#[derive(Default, Debug, Clone)]
struct LegacyPlaceVisit {
    id: i64,
    date: i64,
    visit_type: u8,
    from_visit: i64,
}

#[derive(Default, Debug, Clone)]
struct LegacyPlace {
    id: i64,
    guid: String,
    url: String,
    title: Option<String>,
    hidden: i64,
    typed: i64,
    last_visit_date: i64,
    visit_count: i64,
    description: Option<String>,
    preview_image_url: Option<String>,
    visits: Vec<LegacyPlaceVisit>,
}

impl LegacyPlace {
    pub fn from_row(row: &rusqlite::Row<'_>) -> Self {
        Self {
            id: row.get_unwrap("place_id"),
            guid: row.get_unwrap("place_guid"),
            title: row.get_unwrap("place_title"),
            url: row.get_unwrap("place_url"),
            description: row.get_unwrap("place_description"),
            preview_image_url: row.get_unwrap("place_preview_image_url"),
            typed: row.get_unwrap("place_typed"),
            hidden: row.get_unwrap("place_hidden"),
            visit_count: row.get_unwrap("place_visit_count"),
            last_visit_date: row.get_unwrap("place_last_visit_date"),
            visits: vec![LegacyPlaceVisit {
                id: row.get_unwrap("visit_id"),
                date: row.get_unwrap("visit_date"),
                visit_type: row.get_unwrap("visit_type"),
                from_visit: row.get_unwrap("visit_from_visit"),
            }],
        }
    }
    pub fn insert(self, db: &PlacesDb, options: &ImportPlacesOptions) -> Result<()> {
        let url = Url::parse(&self.url)?;
        for v in self.visits {
            let obs = VisitObservation::new(url.clone())
                .with_visit_type(
                    VisitTransition::from_primitive(v.visit_type).unwrap_or(VisitTransition::Link),
                )
                .with_at(places::Timestamp((v.date / 1000) as u64))
                .with_title(self.title.clone())
                .with_is_remote(rand::random::<f64>() < options.remote_probability);
            places::storage::history::apply_observation_direct(db, obs)?;
        }
        Ok(())
    }
}

fn import_places(
    new: &mut places::PlacesDb,
    old_path: PathBuf,
    options: ImportPlacesOptions,
) -> Result<()> {
    let old = rusqlite::Connection::open_with_flags(
        &old_path,
        rusqlite::OpenFlags::SQLITE_OPEN_READ_ONLY,
    )?;

    let (place_count, visit_count) = {
        let mut stmt = old.prepare("SELECT count(*) FROM moz_places").unwrap();
        let mut rows = stmt.query(NO_PARAMS).unwrap();
        let ps: i64 = rows.next()?.unwrap().get_unwrap(0);

        let mut stmt = old
            .prepare("SELECT count(*) FROM moz_historyvisits")
            .unwrap();
        let mut rows = stmt.query(NO_PARAMS).unwrap();
        let vs: i64 = rows.next()?.unwrap().get_unwrap(0);
        (ps, vs)
    };

    log::info!(
        "Importing {} visits across {} places!",
        place_count,
        visit_count
    );
    let mut stmt = old.prepare(
        "
        SELECT
            p.id                as place_id,
            p.guid              as place_guid,
            p.url               as place_url,
            p.title             as place_title,

            p.hidden            as place_hidden,
            p.typed             as place_typed,
            p.last_visit_date   as place_last_visit_date,
            p.visit_count       as place_visit_count,

            p.description       as place_description,
            p.preview_image_url as place_preview_image_url,

            v.id                as visit_id,
            v.visit_date        as visit_date,
            v.visit_type        as visit_type,
            v.from_visit        as visit_from_visit
        FROM moz_places p
        JOIN moz_historyvisits v
            ON p.id = v.place_id
        ORDER BY p.id
    ",
    )?;

    let mut rows = stmt.query(NO_PARAMS)?;
    let mut current_place = LegacyPlace {
        id: -1,
        ..LegacyPlace::default()
    };
    let mut place_counter = 0;

    let tx = new.unchecked_transaction()?;

    print!(
        "Processing {} / {} places (approx.)",
        place_counter, place_count
    );
    let _ = std::io::stdout().flush();
    while let Some(row) = rows.next()? {
        let id: i64 = row.get("place_id")?;
        if current_place.id == id {
            current_place.visits.push(LegacyPlaceVisit {
                id: row.get("visit_id")?,
                date: row.get("visit_date")?,
                visit_type: row.get("visit_type")?,
                from_visit: row.get("visit_from_visit")?,
            });
            continue;
        }
        place_counter += 1;
        print!(
            "\rProcessing {} / {} places (approx.)",
            place_counter, place_count
        );
        let _ = std::io::stdout().flush();
        if current_place.id != -1 {
            current_place.insert(new, &options)?;
        }
        current_place = LegacyPlace::from_row(&row);
    }
    if current_place.id != -1 {
        current_place.insert(new, &options)?;
    }
    println!("Finished processing records");
    println!("Committing....");
    tx.commit()?;
    log::info!("Finished import!");
    Ok(())
}

fn read_json_file<T>(path: impl AsRef<Path>) -> Result<T>
where
    for<'a> T: serde::de::Deserialize<'a>,
{
    let file = fs::File::open(path.as_ref())?;
    Ok(serde_json::from_reader(&file)?)
}

#[cfg(not(windows))]
mod autocomplete {
    use super::*;
    use places::api::matcher::{search_frecent, SearchParams, SearchResult};
    use places::ErrorKind;
    use rusqlite::{Error as RusqlError, ErrorCode};
    use sql_support::SqlInterruptHandle;
    use std::sync::{
        atomic::{AtomicUsize, Ordering},
        mpsc, Arc,
    };
    use std::thread;
    use std::time::{Duration, Instant};

    #[derive(Debug, Clone)]
    struct ConnectionArgs {
        path: PathBuf,
    }

    impl ConnectionArgs {
        pub fn connect(&self) -> Result<places::PlacesDb> {
            let api = places::PlacesApi::new(&self.path)?;
            Ok(api.open_connection(places::ConnectionType::ReadOnly)?)
        }
    }

    #[derive(Debug, Clone)]
    struct AutocompleteRequest {
        id: usize,
        search: SearchParams,
    }

    #[derive(Debug, Clone)]
    struct AutocompleteResponse {
        id: usize,
        search: SearchParams,
        results: Vec<SearchResult>,
        took: Duration,
    }

    struct BackgroundAutocomplete {
        // Only written from the main thread, and read from the background thread.
        // We use this to signal to the background thread that it shouldn't start on a query that has
        // an ID below this value, since we already have added a newer one into the queue. Note that
        // an ID higher than this value is allowed (it indicates that the BG thread is reading in the
        // window between when we added the search to the queue and when we )
        last_id: Arc<AtomicUsize>,
        // Write-only interface to the queue that the BG thread reads from.
        send_query: mpsc::Sender<AutocompleteRequest>,
        // Read-only interface to the queue the BG thread returns results from.
        recv_results: mpsc::Receiver<AutocompleteResponse>,
        // Currently not used but if we wanted to restart the thread or start additional threads
        // we could use this.
        // conn_args: ConnectionArgs,
        // Thread handle for the BG thread. We can't drop this without problems so we
        // prefix with _ to shut rust up about it being unused.
        _handle: thread::JoinHandle<Result<()>>,
        interrupt_handle: SqlInterruptHandle,
    }

    impl BackgroundAutocomplete {
        pub fn start(conn_args: ConnectionArgs) -> Result<Self> {
            let (send_query, recv_query) = mpsc::channel::<AutocompleteRequest>();

            // Should this channel have a buffer?
            let (send_results, recv_results) = mpsc::channel::<AutocompleteResponse>();

            let last_id = Arc::new(AtomicUsize::new(0usize));

            let conn = conn_args.connect()?;
            let interrupt_handle = conn.new_interrupt_handle();
            let handle = {
                let last_id = last_id.clone();
                thread::spawn(move || {
                    // Note: unwraps/panics here won't bring down the main thread.
                    for AutocompleteRequest { id, search } in recv_query.iter() {
                        // Check if this query is worth processing. Note that we check that the id
                        // isn't known to be stale. The id can be ahead of `last_id`, since
                        // we push the item on before incrementing `last_id`.
                        if id < last_id.load(Ordering::SeqCst) {
                            continue;
                        }
                        let start = Instant::now();
                        match search_frecent(&conn, search.clone()) {
                            Ok(results) => {
                                // Should we skip sending results if `last_id` indicates we
                                // don't care anymore?
                                send_results
                                    .send(AutocompleteResponse {
                                        id,
                                        search,
                                        results,
                                        took: Instant::now().duration_since(start),
                                    })
                                    .unwrap(); // This failing means the main thread has died (most likely)
                            }
                            Err(e) => {
                                match e.kind() {
                                    ErrorKind::InterruptedError(_) => {
                                        // Ignore.
                                    }
                                    ErrorKind::SqlError(RusqlError::SqliteFailure(err, _))
                                        if err.code == ErrorCode::OperationInterrupted =>
                                    {
                                        // Ignore.
                                    }
                                    _ => {
                                        // TODO: this is likely not to go very well since we're in raw mode...
                                        log::error!("Got error doing autocomplete: {:?}", e);
                                        panic!("Got error doing autocomplete: {:?}", e);
                                    }
                                }
                            }
                        }
                    }
                    Ok(())
                })
            };

            Ok(BackgroundAutocomplete {
                last_id,
                send_query,
                recv_results,
                interrupt_handle,
                // conn_args,
                _handle: handle,
            })
        }

        pub fn query(&mut self, search: SearchParams) -> Result<()> {
            self.interrupt_handle.interrupt();
            // Cludgey but whatever.
            let id = self.last_id.load(Ordering::SeqCst) + 1;
            let request = AutocompleteRequest { id, search };
            let res = self.send_query.send(request);
            self.last_id.store(id, Ordering::SeqCst);
            res?;
            Ok(())
        }

        pub fn poll_results(&mut self) -> Result<Option<AutocompleteResponse>> {
            match self.recv_results.try_recv() {
                Ok(results) => Ok(Some(results)),
                Err(mpsc::TryRecvError::Empty) => Ok(None),
                Err(e) => Err(e.into()),
            }
        }
    }

    // TODO: we should normalize and casefold both of these.
    fn find_highlighted_sections<'a>(
        source: &'a str,
        search_tokens: &[&str],
    ) -> Vec<(&'a str, bool)> {
        if search_tokens.is_empty() {
            return vec![(source, false)];
        }
        // (start, end) indices in `source` where an item in
        // `search_tokens` appears.
        let mut ranges = vec![];
        for token in search_tokens {
            let mut offset = 0;
            while let Some(index) = source[offset..].find(token) {
                ranges.push((offset + index, offset + index + token.len()));
                offset += index + 1;
            }
        }
        if ranges.is_empty() {
            return vec![(source, false)];
        }
        // Sort ranges in ascending order based on where they appear in `source`.
        ranges.sort_by(|a, b| a.0.cmp(&b.0));

        // Combine ranges that overlap.
        let mut coalesced = vec![ranges[0]];
        for curr in ranges.iter().skip(1) {
            // we know `coalesced` is never empty
            let prev = *coalesced.last().unwrap();
            if curr.0 < prev.1 {
                // Found an overlap. Update prev, but don't add cur.
                if curr.1 > prev.0 {
                    *coalesced.last_mut().unwrap() = (prev.0, curr.1);
                }
            // else `prev` already encompasses `curr` entirely... (IIRC
            // this is possible in weird cases).
            } else {
                coalesced.push(*curr);
            }
        }

        let mut result = Vec::with_capacity(coalesced.len() + 1);
        let mut pos = 0;
        for (start, end) in coalesced {
            if pos < start {
                result.push((&source[pos..start], false));
            }
            result.push((&source[start..end], true));
            pos = end;
        }
        if pos < source.len() {
            result.push((&source[pos..], false))
        }

        result
    }

    fn highlight_sections<W: Write>(
        out: &mut W,
        source: &str,
        search_tokens: &[&str],
        pad: usize,
    ) -> Result<()> {
        use termion::style::{Bold, NoFaint};
        let (term_width, _) = termion::terminal_size()?;
        let mut source_shortened = source
            .chars()
            .take(term_width as usize - 10 - pad)
            .collect::<String>();
        if source_shortened.len() != source.len() {
            source_shortened.push_str("...");
        }
        let sections = find_highlighted_sections(&source_shortened, search_tokens);
        let mut highlight_on = false; // Not necessary beyond an optimization
        for (text, need_highlight) in sections {
            if need_highlight == highlight_on {
                write!(out, "{}", text)?;
            } else if need_highlight {
                // Annoyingly Bold and NoBold are different types,
                // so we can't unify these branches.
                write!(out, "{}{}", Bold, text)?;
            } else {
                // The code termion uses for NoBold isn't widely supported...
                // And they don't have an issue tracker (PRs only). NoFaint
                // uses a code that should reset to normal though.
                write!(out, "{}{}", NoFaint, text)?;
            }
            highlight_on = need_highlight;
        }
        if highlight_on {
            // This probably shouldn't be possible
            write!(out, "{}", NoFaint)?;
        }
        Ok(())
    }

    pub fn start_autocomplete(db_path: PathBuf) -> Result<()> {
        use termion::{
            clear, color,
            cursor::{self, Goto},
            event::Key,
            input::TermRead,
            raw::IntoRawMode,
            style::{Invert, NoInvert},
        };

        let mut autocompleter = BackgroundAutocomplete::start(ConnectionArgs { path: db_path })?;

        let mut stdin = termion::async_stdin();
        let stdout = std::io::stdout().into_raw_mode()?;
        let mut stdout = termion::screen::AlternateScreen::from(stdout);
        write!(
            stdout,
            "{}{}Autocomplete demo (press escape to exit){}> ",
            clear::All,
            Goto(1, 1),
            Goto(1, 2)
        )?;
        stdout.flush()?;

        let no_title = format!(
            "{}(no title){}",
            termion::style::Faint,
            termion::style::NoFaint
        );
        let throttle_dur = Duration::from_millis(100);
        // TODO: refactor these to be part of a struct or something.
        let mut query_str = String::new();
        let mut last_query = Instant::now();
        let mut last_keypress = Instant::now();
        let mut results: Option<AutocompleteResponse> = None;
        // The index of the highlighted item in the results.
        let mut pos = 0;
        // The index in `query_str` the cursor is at
        let mut cursor_idx = 0;
        // Whether or not we need to repain the re
        let mut repaint_results = true;
        // Whether or not the input changed and needs repainting / possible requerying
        let mut input_changed = true;
        // true if the input changed, we rendered the change, but we didn't execute the query because
        // it was within throttle_dur.
        let mut pending_change = false;
        loop {
            for res in (&mut stdin).keys() {
                //.events_and_raw() {
                let key = res?;
                last_keypress = Instant::now();
                match key {
                    Key::Esc => return Ok(()),
                    Key::Char('\n') | Key::Char('\r') => {
                        if !query_str.is_empty() {
                            last_query = Instant::now();
                            pending_change = false;
                            autocompleter.query(SearchParams {
                                search_string: query_str.clone(),
                                limit: 10,
                            })?;
                        }
                    }
                    Key::Char(ch) => {
                        query_str.insert(cursor_idx, ch);
                        cursor_idx += 1;
                        input_changed = true;
                    }
                    Key::Ctrl('n') | Key::Down => {
                        if let Some(res) = &results {
                            if pos + 1 < res.results.len() {
                                pos += 1;
                                repaint_results = true;
                            }
                        }
                    }
                    Key::Ctrl('p') | Key::Up => {
                        if results.is_some() && pos > 0 {
                            pos -= 1;
                            repaint_results = true;
                        }
                    }
                    Key::Ctrl('k') => {
                        query_str.truncate(cursor_idx);
                        input_changed = true;
                    }
                    Key::Right | Key::Ctrl('f') => {
                        if cursor_idx < query_str.len() {
                            write!(stdout, "{}", termion::cursor::Right(1))?;
                            cursor_idx += 1;
                        }
                    }
                    Key::Left | Key::Ctrl('b') => {
                        if cursor_idx > 0 {
                            write!(stdout, "{}", termion::cursor::Left(1))?;
                            cursor_idx -= 1;
                        }
                    }
                    Key::Backspace => {
                        if cursor_idx > 0 {
                            query_str.remove(cursor_idx - 1);
                            cursor_idx -= 1;
                            input_changed = true;
                        }
                    }
                    Key::Delete | Key::Ctrl('d') => {
                        if cursor_idx + 1 != query_str.len() {
                            query_str.remove(cursor_idx + 1);
                            input_changed = true;
                        }
                    }
                    Key::Ctrl('a') | Key::Home => {
                        write!(stdout, "{}", Goto(3, 2))?;
                        cursor_idx = 0;
                    }
                    Key::Ctrl('e') | Key::End => {
                        write!(stdout, "{}", Goto(3 + query_str.len() as u16, 2))?;
                        cursor_idx = query_str.len();
                    }
                    Key::Ctrl('u') => {
                        cursor_idx = 0;
                        query_str.clear();
                        input_changed = true;
                    }
                    _ => {}
                }
            }
            if let Some(new_res) = autocompleter.poll_results()? {
                results = Some(new_res);
                pos = 0;
                repaint_results = true;
            }
            if input_changed {
                let now = Instant::now();
                let last = last_query;
                last_query = now;
                if !query_str.is_empty() {
                    if now.duration_since(last) > throttle_dur {
                        pending_change = false;
                        autocompleter.query(SearchParams {
                            search_string: query_str.clone(),
                            limit: 10,
                        })?;
                    } else {
                        pending_change = true;
                    }
                } else {
                    pending_change = false;
                }
                write!(
                    stdout,
                    "{}{}> {}{}",
                    Goto(1, 2),
                    clear::CurrentLine,
                    query_str,
                    Goto(3 + cursor_idx as u16, 2)
                )?;

                if query_str.is_empty() {
                    results = None;
                    pos = 0;
                    repaint_results = true;
                }
                input_changed = false;
            } else if pending_change && last_keypress.elapsed() > throttle_dur {
                pending_change = false;
                if !query_str.is_empty() {
                    autocompleter.query(SearchParams {
                        search_string: query_str.clone(),
                        limit: 10,
                    })?;
                }
            }

            if repaint_results {
                match &results {
                    Some(results) => {
                        // let search_query = results.search.search_string;
                        write!(
                            stdout,
                            "{}{}{}Query id={} gave {} results (max {}) for \"{}\" after {}us",
                            cursor::Save,
                            Goto(1, 3),
                            clear::AfterCursor,
                            results.id,
                            results.results.len(),
                            results.search.limit,
                            results.search.search_string,
                            results.took.as_secs() * 1_000_000
                                + (u64::from(results.took.subsec_nanos()) / 1000)
                        )?;
                        let (_, term_h) = termion::terminal_size()?;
                        write!(stdout, "{}", Goto(1, 4))?;
                        let search_tokens = results
                            .search
                            .search_string
                            .split_whitespace()
                            .collect::<Vec<&str>>();
                        for (i, item) in results.results.iter().enumerate() {
                            if 4 + (1 + i as u16) * 2 >= term_h {
                                break;
                            }
                            write!(stdout, "{}", Goto(1, 4 + (i as u16) * 2))?;
                            let prefix = format!("{}. ({}) ", i + 1, item.frecency);
                            if i == pos {
                                write!(stdout, "{}", Invert)?;
                                write!(
                                    stdout,
                                    "{}{}{}. ({}{}{}) ",
                                    color::Bg(color::Blue),
                                    i + 1,
                                    color::Bg(color::Reset),
                                    color::Bg(color::Red),
                                    item.frecency,
                                    color::Bg(color::Reset)
                                )?;
                            } else {
                                write!(
                                    stdout,
                                    "{}{}{}. ({}{}{}) ",
                                    color::Fg(color::Blue),
                                    i + 1,
                                    color::Fg(color::Reset),
                                    color::Fg(color::Red),
                                    item.frecency,
                                    color::Fg(color::Reset)
                                )?;
                            }

                            if !item.title.is_empty() {
                                highlight_sections(
                                    &mut stdout,
                                    &item.title,
                                    &search_tokens,
                                    prefix.len(),
                                )?;
                            } else {
                                write!(stdout, "{}", no_title)?;
                            }
                            write!(stdout, "{}    ", Goto(1, 5 + (i as u16) * 2))?;
                            let url_str = item.url.to_string();
                            if i == pos {
                                write!(stdout, "{}", color::Bg(color::Green))?;
                            } else {
                                write!(stdout, "{}", color::Fg(color::Green))?;
                            }

                            highlight_sections(&mut stdout, &url_str, &search_tokens, 4)?;
                            if i == pos {
                                write!(stdout, "{}{}", color::Bg(color::Reset), NoInvert)?;
                            } else {
                                write!(stdout, "{}", color::Fg(color::Reset))?;
                            }
                        }
                        write!(stdout, "{}", cursor::Restore)?;
                    }
                    None => {
                        write!(
                            stdout,
                            "{}{}{}{}",
                            cursor::Save,
                            Goto(1, 3),
                            clear::AfterCursor,
                            cursor::Restore
                        )?;
                    }
                }
                repaint_results = false;
            }
            stdout.flush()?;
            thread::sleep(Duration::from_millis(16));
        }
    }
}

fn main() -> Result<()> {
    let matches = clap::App::new("autocomplete-example")
        .arg(clap::Arg::with_name("database_path")
            .long("database")
            .short("d")
            .takes_value(true)
            .help("Path to the database (with the *new* schema). Defaults to './new-places.db'"))
        .arg(clap::Arg::with_name("import_places")
            .long("import-places")
            .short("p")
            .takes_value(true)
            .value_name("'auto'|'path/to/places.sqlite'")
            .help("Source places db to import from, or 'auto' to import from the largest places.sqlite"))
        .arg(clap::Arg::with_name("import_places_remote_weight")
            .long("import-places-remote-weight")
            .takes_value(true)
            .value_name("WEIGHT")
            .help("Probability (between 0.0 and 1.0, default = 0.1) that a given visit from `places` should \
                   be considered `remote`. Ignored when --import-places is not passed"))
        .arg(clap::Arg::with_name("import_observations")
            .long("import-observations")
            .short("o")
            .takes_value(true)
            .value_name("path/to/observations.json")
            .help("Path to a JSON file containing a list of 'observations'"))
        .arg(clap::Arg::with_name("no_interactive")
            .long("no-interactive")
            .short("x")
            .help("Don't run the interactive demo after completion (if you just want to run an \
                   import and exit, for example)"))
        .get_matches();

    let db_path = matches
        .value_of("database_path")
        .unwrap_or("./new-places.db");

    let api = places::PlacesApi::new(&db_path)?;
    let mut conn = api.open_connection(places::ConnectionType::ReadWrite)?;

    if let Some(import_places_arg) = matches.value_of("import_places") {
        let options = ImportPlacesOptions {
            remote_probability: value_t!(matches, "import_places_remote_weight", f64)
                .unwrap_or(0.1),
        };
        let import_source = if import_places_arg == "auto" {
            log::info!("Automatically locating largest places DB in your profile(s)");
            let profile_info = if let Some(info) = find_places_db::get_largest_places_db()? {
                info
            } else {
                log::error!("Failed to locate your firefox profile!");
                bail!("--import-places=auto specified, but couldn't find a `places.sqlite`");
            };
            log::info!(
                "Using a {} places.sqlite from profile '{}' (places path = {:?})",
                profile_info.friendly_db_size(),
                profile_info.profile_name,
                profile_info.path
            );
            assert!(
                profile_info.path.exists(),
                "Bug in find_places_db, provided path doesn't exist!"
            );
            profile_info.path
        } else {
            let path = Path::new(import_places_arg);
            if !path.exists() {
                bail!(
                    "Provided path to --import-places doesn't exist and isn't 'auto': {:?}",
                    import_places_arg
                );
            }
            path.to_owned()
        };

        // Copy `import_source` to a temporary location, because we aren't allowed to open
        // places.sqlite while Firefox is open.

        let dir = tempfile::tempdir()?;
        let temp_places = dir.path().join("places-tmp.sqlite");

        fs::copy(&import_source, &temp_places)?;
        import_places(&mut conn, temp_places, options)?;
    }

    if let Some(observations_json) = matches.value_of("import_observations") {
        log::info!("Importing observations from {}", observations_json);
        let observations: Vec<SerializedObservation> = read_json_file(observations_json)?;
        let num_observations = observations.len();
        log::info!("Found {} observations", num_observations);
        for (counter, obs) in observations.into_iter().enumerate() {
            let visit = obs.into_visit()?;
            places::apply_observation(&mut conn, visit)?;
            if (counter % 1000) == 0 {
                log::trace!("Importing observations {} / {}", counter, num_observations);
            }
        }
    }
    // Close our connection before starting autocomplete.
    drop(conn);
    if !matches.is_present("no_interactive") {
        #[cfg(not(windows))]
        {
            // Can't use cfg! macro, this module doesn't exist at all on windows
            autocomplete::start_autocomplete(Path::new(db_path).to_owned())?;
        }
        #[cfg(windows)]
        {
            println!("The interactive autocomplete demo isn't available on windows currently :(");
        }
    }

    Ok(())
}
