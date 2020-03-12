/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::db::PlacesDb;
use crate::error::Result;
pub use crate::match_impl::{MatchBehavior, SearchBehavior};
use crate::msg_types::{SearchResultMessage, SearchResultReason};
use rusqlite::{types::ToSql, Row};
use serde_derive::*;
use sql_support::{maybe_log_plan, ConnExt};
use url::Url;

// A helper to log, cache and execute a query, returning a vector of flattened rows.
fn query_flat_rows_and_then_named<T, F>(
    conn: &PlacesDb,
    sql: &str,
    params: &[(&str, &dyn ToSql)],
    mapper: F,
) -> Result<Vec<T>>
where
    F: FnMut(&Row<'_>) -> Result<T>,
{
    maybe_log_plan(conn, sql, params);
    let mut stmt = conn.prepare_maybe_cached(sql, true)?;
    let iter = stmt.query_and_then_named(params, mapper)?;
    Ok(iter
        .inspect(|r| {
            if let Err(ref e) = *r {
                log::warn!("Failed to perform a search: {}", e);
                if cfg!(debug_assertions) {
                    panic!("Failed to perform a search: {}", e);
                }
            }
        })
        .flatten()
        .collect::<Vec<_>>())
}

#[derive(Debug, Clone)]
pub struct SearchParams {
    pub search_string: String,
    pub limit: u32,
}

/// Synchronously queries all providers for autocomplete matches, then filters
/// the matches. This isn't cancelable yet; once a search is started, it can't
/// be interrupted, even if the user moves on (see
/// https://github.com/mozilla/application-services/issues/265).
///
/// A provider can be anything that returns URL suggestions: Places history
/// and bookmarks, synced tabs, search engine suggestions, and search keywords.
pub fn search_frecent(conn: &PlacesDb, params: SearchParams) -> Result<Vec<SearchResult>> {
    // TODO: Tokenize the query.

    // Try to find the first heuristic result. Desktop tries extensions,
    // search engine aliases, origins, URLs, search engine domains, and
    // preloaded sites, before trying to fall back to fixing up the URL,
    // and a search if all else fails. We only try origins and URLs for
    // heuristic matches, since that's all we support.

    let mut matches = match_with_limit(
        conn,
        &[
            // Try to match on the origin, or the full URL.
            &OriginOrUrl::new(&params.search_string),
            // query adaptive matches and suggestions, matching Anywhere.
            &Adaptive::with_behavior(
                &params.search_string,
                MatchBehavior::Anywhere,
                SearchBehavior::default(),
            ),
            &Suggestions::with_behavior(
                &params.search_string,
                MatchBehavior::Anywhere,
                SearchBehavior::default(),
            ),
        ],
        params.limit,
    )?;

    matches.sort_unstable_by(|a, b| a.url.cmp(&b.url));
    matches.dedup_by(|a, b| a.url == b.url);

    Ok(matches)
}

pub fn match_url(conn: &PlacesDb, query: impl AsRef<str>) -> Result<Option<String>> {
    let scope = conn.begin_interrupt_scope();
    let matcher = OriginOrUrl::new(query.as_ref());
    // Note: The matcher ignores the limit argument (it's a trait method)
    let results = matcher.search(conn, 1)?;
    scope.err_if_interrupted()?;
    // Doing it like this lets us move the result, avoiding a copy (which almost
    // certainly doesn't matter but whatever)
    if let Some(res) = results.into_iter().next() {
        Ok(Some(res.url.into_string()))
    } else {
        Ok(None)
    }
}

fn match_with_limit(
    conn: &PlacesDb,
    matchers: &[&dyn Matcher],
    max_results: u32,
) -> Result<Vec<SearchResult>> {
    let mut results = Vec::new();
    let mut rem_results = max_results;
    let scope = conn.begin_interrupt_scope();
    for m in matchers {
        if rem_results == 0 {
            break;
        }
        scope.err_if_interrupted()?;
        let matches = m.search(conn, rem_results)?;
        results.extend(matches);
        rem_results = rem_results.saturating_sub(results.len() as u32);
    }
    Ok(results)
}

/// Records an accepted autocomplete match, recording the query string,
/// and chosen URL for subsequent matches.
pub fn accept_result(conn: &PlacesDb, search_string: &str, url: &Url) -> Result<()> {
    // See `nsNavHistory::AutoCompleteFeedback`.
    conn.execute_named(
        "INSERT OR REPLACE INTO moz_inputhistory(place_id, input, use_count)
         SELECT h.id, IFNULL(i.input, :input_text), IFNULL(i.use_count, 0) * .9 + 1
         FROM moz_places h
         LEFT JOIN moz_inputhistory i ON i.place_id = h.id AND i.input = :input_text
         WHERE url_hash = hash(:page_url) AND url = :page_url",
        &[
            (":input_text", &search_string),
            (":page_url", &url.as_str()),
        ],
    )?;

    Ok(())
}

pub fn split_after_prefix(href: &str) -> (&str, &str) {
    match memchr::memchr(b':', href.as_bytes()) {
        None => ("", href),
        Some(index) => {
            let hb = href.as_bytes();
            let mut end = index + 1;
            if hb.len() >= end + 2 && hb[end] == b'/' && hb[end + 1] == b'/' {
                end += 2;
            }
            (&href[0..end], &href[end..])
        }
    }
}

pub fn split_after_host_and_port(href: &str) -> (&str, &str) {
    let (_, remainder) = split_after_prefix(href);
    let start = memchr::memchr(b'@', remainder.as_bytes())
        .map(|i| i + 1)
        .unwrap_or(0);
    let remainder = &remainder[start..];
    let end =
        memchr::memchr3(b'/', b'?', b'#', remainder.as_bytes()).unwrap_or_else(|| remainder.len());
    remainder.split_at(end)
}

fn looks_like_origin(string: &str) -> bool {
    // Skip nonascii characters, we'll either handle them in autocomplete_match or,
    // a later part of the origins query.
    !string.is_empty()
        && !string.bytes().any(|c| {
            !c.is_ascii() || c.is_ascii_whitespace() || c == b'/' || c == b'?' || c == b'#'
        })
}

/// The match reason specifies why an autocomplete search result matched a
/// query. This can be used to filter and sort matches.
#[derive(Debug, Clone, Serialize, Eq, PartialEq)]
pub enum MatchReason {
    Keyword,
    Origin,
    Url,
    PreviousUse,
    Bookmark,
    // Hrm... This will probably make this all serialize weird...
    Tags(String),
}

#[derive(Debug, Clone, Serialize, Eq, PartialEq)]
pub struct SearchResult {
    /// The search string for this match.
    pub search_string: String,

    /// The URL to open when the user confirms a match. This is
    /// equivalent to `nsIAutoCompleteResult.getFinalCompleteValueAt`.
    pub url: Url,

    /// The title of the autocompleted value, to show in the UI. This can be the
    /// title of the bookmark or page, origin, URL, or URL fragment.
    pub title: String,

    /// The favicon URL.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub icon_url: Option<Url>,

    /// A frecency score for this match.
    pub frecency: i64,

    /// A list of reasons why this matched.
    pub reasons: Vec<MatchReason>,
}

impl SearchResult {
    /// Default search behaviors from Desktop: HISTORY, BOOKMARK, OPENPAGE, SEARCHES.
    /// Default match behavior: MATCH_BOUNDARY_ANYWHERE.
    pub fn from_adaptive_row(row: &rusqlite::Row<'_>) -> Result<Self> {
        let mut reasons = vec![MatchReason::PreviousUse];

        let search_string = row.get::<_, String>("searchString")?;
        let _place_id = row.get::<_, i64>("id")?;
        let url = row.get::<_, String>("url")?;
        let history_title = row.get::<_, Option<String>>("title")?;
        let bookmarked = row.get::<_, bool>("bookmarked")?;
        let bookmark_title = row.get::<_, Option<String>>("btitle")?;
        let frecency = row.get::<_, i64>("frecency")?;

        let title = bookmark_title.or_else(|| history_title).unwrap_or_default();

        let tags = row.get::<_, Option<String>>("tags")?;
        if let Some(tags) = tags {
            reasons.push(MatchReason::Tags(tags));
        }
        if bookmarked {
            reasons.push(MatchReason::Bookmark);
        }
        let url = Url::parse(&url)?;

        Ok(Self {
            search_string,
            url,
            title,
            icon_url: None,
            frecency,
            reasons,
        })
    }

    pub fn from_suggestion_row(row: &rusqlite::Row<'_>) -> Result<Self> {
        let mut reasons = vec![MatchReason::Bookmark];

        let search_string = row.get::<_, String>("searchString")?;
        let url = row.get::<_, String>("url")?;

        let history_title = row.get::<_, Option<String>>("title")?;
        let bookmark_title = row.get::<_, Option<String>>("btitle")?;
        let title = bookmark_title.or_else(|| history_title).unwrap_or_default();

        let tags = row.get::<_, Option<String>>("tags")?;
        if let Some(tags) = tags {
            reasons.push(MatchReason::Tags(tags));
        }
        let url = Url::parse(&url)?;

        let frecency = row.get::<_, i64>("frecency")?;

        Ok(Self {
            search_string,
            url,
            title,
            icon_url: None,
            frecency,
            reasons,
        })
    }

    pub fn from_origin_row(row: &rusqlite::Row<'_>) -> Result<Self> {
        let search_string = row.get::<_, String>("searchString")?;
        let url = row.get::<_, String>("url")?;
        let display_url = row.get::<_, String>("displayURL")?;
        let frecency = row.get::<_, i64>("frecency")?;

        let url = Url::parse(&url)?;

        Ok(Self {
            search_string,
            url,
            title: display_url,
            icon_url: None,
            frecency,
            reasons: vec![MatchReason::Origin],
        })
    }

    pub fn from_url_row(row: &rusqlite::Row<'_>) -> Result<Self> {
        let search_string = row.get::<_, String>("searchString")?;
        let href = row.get::<_, String>("url")?;
        let stripped_url = row.get::<_, String>("strippedURL")?;
        let frecency = row.get::<_, i64>("frecency")?;
        let bookmarked = row.get::<_, bool>("bookmarked")?;

        let mut reasons = vec![MatchReason::Url];
        if bookmarked {
            reasons.push(MatchReason::Bookmark);
        }

        let (url, display_url) = match href.find(&stripped_url) {
            Some(stripped_url_index) => {
                let stripped_prefix = &href[..stripped_url_index];
                let title = match &href[stripped_url_index + stripped_url.len()..].find('/') {
                    Some(next_slash_index) => {
                        &href[stripped_url_index
                            ..=stripped_url_index + stripped_url.len() + next_slash_index]
                    }
                    None => &href[stripped_url_index..],
                };
                let url = Url::parse(&[stripped_prefix, title].concat())?;
                (url, title.into())
            }
            None => {
                let url = Url::parse(&href)?;
                (url, stripped_url)
            }
        };

        Ok(Self {
            search_string,
            url,
            title: display_url,
            icon_url: None,
            frecency,
            reasons,
        })
    }
}

impl From<SearchResult> for SearchResultMessage {
    fn from(res: SearchResult) -> Self {
        Self {
            url: res.url.into_string(),
            title: res.title,
            frecency: res.frecency,
            reasons: res
                .reasons
                .into_iter()
                .map(|r| Into::<SearchResultReason>::into(r) as i32)
                .collect::<Vec<i32>>(),
        }
    }
}

impl From<MatchReason> for SearchResultReason {
    fn from(mr: MatchReason) -> Self {
        match mr {
            MatchReason::Keyword => SearchResultReason::Keyword,
            MatchReason::Origin => SearchResultReason::Origin,
            MatchReason::Url => SearchResultReason::Url,
            MatchReason::PreviousUse => SearchResultReason::PreviousUse,
            MatchReason::Bookmark => SearchResultReason::Bookmark,
            MatchReason::Tags(_) => SearchResultReason::Tag,
        }
    }
}

trait Matcher {
    fn search(&self, conn: &PlacesDb, max_results: u32) -> Result<Vec<SearchResult>>;
}

struct OriginOrUrl<'query> {
    query: &'query str,
}

impl<'query> OriginOrUrl<'query> {
    pub fn new(query: &'query str) -> OriginOrUrl<'query> {
        OriginOrUrl { query }
    }
}

const URL_SQL: &str = "
    SELECT h.url as url,
            :host || :remainder AS strippedURL,
            h.frecency as frecency,
            h.foreign_count > 0 AS bookmarked,
            h.id as id,
            :searchString AS searchString
    FROM moz_places h
    JOIN moz_origins o ON o.id = h.origin_id
    WHERE o.rev_host = reverse_host(:host)
            AND MAX(h.frecency, 0) >= :frecencyThreshold
            AND h.hidden = 0
            AND strip_prefix_and_userinfo(h.url) BETWEEN strippedURL AND strippedURL || X'FFFF'
    UNION ALL
    SELECT h.url as url,
            :host || :remainder AS strippedURL,
            h.frecency as frecency,
            h.foreign_count > 0 AS bookmarked,
            h.id as id,
            :searchString AS searchString
    FROM moz_places h
    JOIN moz_origins o ON o.id = h.origin_id
    WHERE o.rev_host = reverse_host(:host) || 'www.'
            AND MAX(h.frecency, 0) >= :frecencyThreshold
            AND h.hidden = 0
            AND strip_prefix_and_userinfo(h.url) BETWEEN 'www.' || strippedURL AND 'www.' || strippedURL || X'FFFF'
    ORDER BY h.frecency DESC, h.id DESC
    LIMIT 1
";
const ORIGIN_SQL: &str = "
    SELECT IFNULL(:prefix, prefix) || moz_origins.host || '/' AS url,
            moz_origins.host || '/' AS displayURL,
            frecency,
            bookmarked,
            id,
            :searchString AS searchString
    FROM (
        SELECT host,
                TOTAL(frecency) AS host_frecency,
                (SELECT TOTAL(foreign_count) > 0 FROM moz_places
                WHERE moz_places.origin_id = moz_origins.id) AS bookmarked
        FROM moz_origins
        WHERE host BETWEEN :searchString AND :searchString || X'FFFF'
        GROUP BY host
        HAVING host_frecency >= :frecencyThreshold
        UNION ALL
        SELECT host,
                TOTAL(frecency) AS host_frecency,
                (SELECT TOTAL(foreign_count) > 0 FROM moz_places
                WHERE moz_places.origin_id = moz_origins.id) AS bookmarked
        FROM moz_origins
        WHERE host BETWEEN 'www.' || :searchString AND 'www.' || :searchString || X'FFFF'
        GROUP BY host
        HAVING host_frecency >= :frecencyThreshold
    ) AS grouped_hosts
    JOIN moz_origins ON moz_origins.host = grouped_hosts.host
    ORDER BY frecency DESC, id DESC
    LIMIT 1
";

impl<'query> Matcher for OriginOrUrl<'query> {
    fn search(&self, conn: &PlacesDb, _: u32) -> Result<Vec<SearchResult>> {
        Ok(if looks_like_origin(self.query) {
            query_flat_rows_and_then_named(
                conn,
                ORIGIN_SQL,
                &[
                    (":prefix", &rusqlite::types::Null),
                    (":searchString", &self.query),
                    (":frecencyThreshold", &-1i64),
                ],
                SearchResult::from_origin_row,
            )?
        } else if self.query.contains(|c| c == '/' || c == ':' || c == '?') {
            let (host, remainder) = split_after_host_and_port(self.query);
            // This can fail if the "host" has some characters that are not
            // currently allowed in URLs (even when punycoded). If that happens,
            // then the query we'll use here can't return any results (and
            // indeed, `reverse_host` will get mad at us since it's an invalid
            // host), so we just return an empty results set.
            let punycode_host = idna::domain_to_ascii(host);
            let host_str = if let Ok(host) = &punycode_host {
                host.as_str()
            } else {
                return Ok(vec![]);
            };
            query_flat_rows_and_then_named(
                conn,
                URL_SQL,
                &[
                    (":searchString", &self.query),
                    (":host", &host_str),
                    (":remainder", &remainder),
                    (":frecencyThreshold", &-1i64),
                ],
                SearchResult::from_url_row,
            )?
        } else {
            vec![]
        })
    }
}

struct Adaptive<'query> {
    query: &'query str,
    match_behavior: MatchBehavior,
    search_behavior: SearchBehavior,
}

impl<'query> Adaptive<'query> {
    pub fn with_behavior(
        query: &'query str,
        match_behavior: MatchBehavior,
        search_behavior: SearchBehavior,
    ) -> Adaptive<'query> {
        Adaptive {
            query,
            match_behavior,
            search_behavior,
        }
    }
}

impl<'query> Matcher for Adaptive<'query> {
    fn search(&self, conn: &PlacesDb, max_results: u32) -> Result<Vec<SearchResult>> {
        Ok(query_flat_rows_and_then_named(
            conn,
            "
            SELECT h.url as url,
                   h.title as title,
                   EXISTS(SELECT 1 FROM moz_bookmarks
                          WHERE fk = h.id) AS bookmarked,
                   (SELECT title FROM moz_bookmarks
                    WHERE fk = h.id AND
                          title NOT NULL
                    ORDER BY lastModified DESC
                    LIMIT 1) AS btitle,
                   NULL AS tags,
                   h.visit_count_local + h.visit_count_remote AS visit_count,
                   h.typed as typed,
                   h.id as id,
                   NULL AS open_count,
                   h.frecency as frecency,
                   :searchString AS searchString
            FROM (
              SELECT ROUND(MAX(use_count) * (1 + (input = :searchString)), 1) AS rank,
                     place_id
              FROM moz_inputhistory
              WHERE input BETWEEN :searchString AND :searchString || X'FFFF'
              GROUP BY place_id
            ) AS i
            JOIN moz_places h ON h.id = i.place_id
            WHERE AUTOCOMPLETE_MATCH(:searchString, h.url,
                                     IFNULL(btitle, h.title), tags,
                                     visit_count, h.typed, bookmarked,
                                     NULL, :matchBehavior, :searchBehavior)
            ORDER BY rank DESC, h.frecency DESC
            LIMIT :maxResults",
            &[
                (":searchString", &self.query),
                (":matchBehavior", &self.match_behavior),
                (":searchBehavior", &self.search_behavior),
                (":maxResults", &max_results),
            ],
            SearchResult::from_adaptive_row,
        )?)
    }
}

struct Suggestions<'query> {
    query: &'query str,
    match_behavior: MatchBehavior,
    search_behavior: SearchBehavior,
}

impl<'query> Suggestions<'query> {
    pub fn with_behavior(
        query: &'query str,
        match_behavior: MatchBehavior,
        search_behavior: SearchBehavior,
    ) -> Suggestions<'query> {
        Suggestions {
            query,
            match_behavior,
            search_behavior,
        }
    }
}

impl<'query> Matcher for Suggestions<'query> {
    fn search(&self, conn: &PlacesDb, max_results: u32) -> Result<Vec<SearchResult>> {
        Ok(query_flat_rows_and_then_named(
            conn,
            "
            SELECT h.url, h.title,
                   EXISTS(SELECT 1 FROM moz_bookmarks
                          WHERE fk = h.id) AS bookmarked,
                   (SELECT title FROM moz_bookmarks
                    WHERE fk = h.id AND
                          title NOT NULL
                    ORDER BY lastModified DESC
                    LIMIT 1) AS btitle,
                   NULL AS tags,
                   h.visit_count_local + h.visit_count_remote AS visit_count,
                   h.typed as typed,
                   h.id as id,
                   NULL AS open_count, h.frecency, :searchString AS searchString
            FROM moz_places h
            WHERE h.frecency > 0
              AND AUTOCOMPLETE_MATCH(:searchString, h.url,
                                     IFNULL(btitle, h.title), tags,
                                     visit_count, h.typed,
                                     bookmarked, NULL,
                                     :matchBehavior, :searchBehavior)
              AND (+h.visit_count_local > 0 OR +h.visit_count_remote > 0)
            ORDER BY h.frecency DESC, h.id DESC
            LIMIT :maxResults",
            &[
                (":searchString", &self.query),
                (":matchBehavior", &self.match_behavior),
                (":searchBehavior", &self.search_behavior),
                (":maxResults", &max_results),
            ],
            SearchResult::from_suggestion_row,
        )?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::places_api::test::new_mem_connection;
    use crate::observation::VisitObservation;
    use crate::storage::history::apply_observation;
    use crate::types::{Timestamp, VisitTransition};

    #[test]
    fn split() {
        assert_eq!(
            split_after_prefix("http://example.com"),
            ("http://", "example.com")
        );
        assert_eq!(split_after_prefix("foo:example"), ("foo:", "example"));
        assert_eq!(split_after_prefix("foo:"), ("foo:", ""));
        assert_eq!(split_after_prefix("notaspec"), ("", "notaspec"));
        assert_eq!(split_after_prefix("http:/"), ("http:", "/"));
        assert_eq!(split_after_prefix("http://"), ("http://", ""));

        assert_eq!(
            split_after_host_and_port("http://example.com/"),
            ("example.com", "/")
        );
        assert_eq!(
            split_after_host_and_port("http://example.com:8888/"),
            ("example.com:8888", "/")
        );
        assert_eq!(
            split_after_host_and_port("http://user:pass@example.com/"),
            ("example.com", "/")
        );
        assert_eq!(split_after_host_and_port("foo:example"), ("example", ""));
    }

    #[test]
    fn search() {
        let conn = new_mem_connection();

        let url = Url::parse("http://example.com/123").unwrap();
        let visit = VisitObservation::new(url.clone())
            .with_title("Example page 123".to_string())
            .with_visit_type(VisitTransition::Typed)
            .with_at(Timestamp::now());

        apply_observation(&conn, visit).expect("Should apply visit");

        let by_origin = search_frecent(
            &conn,
            SearchParams {
                search_string: "example.com".into(),
                limit: 10,
            },
        )
        .expect("Should search by origin");
        assert!(by_origin
            .iter()
            .any(|result| result.search_string == "example.com"
                && result.title == "example.com/"
                && result.url.as_str() == "http://example.com/"
                && result.reasons == [MatchReason::Origin]));

        let by_url_without_path = search_frecent(
            &conn,
            SearchParams {
                search_string: "http://example.com".into(),
                limit: 10,
            },
        )
        .expect("Should search by URL without path");
        assert!(by_url_without_path
            .iter()
            .any(|result| result.title == "example.com/"
                && result.url.as_str() == "http://example.com/"
                && result.reasons == [MatchReason::Url]));

        let by_url_with_path = search_frecent(
            &conn,
            SearchParams {
                search_string: "http://example.com/1".into(),
                limit: 10,
            },
        )
        .expect("Should search by URL with path");
        assert!(by_url_with_path
            .iter()
            .any(|result| result.title == "example.com/123"
                && result.url.as_str() == "http://example.com/123"
                && result.reasons == [MatchReason::Url]));

        accept_result(&conn, "ample", &url).expect("Should accept input history match");

        let by_adaptive = search_frecent(
            &conn,
            SearchParams {
                search_string: "ample".into(),
                limit: 10,
            },
        )
        .expect("Should search by adaptive input history");
        assert!(by_adaptive
            .iter()
            .any(|result| result.search_string == "ample"
                && result.url == url
                && result.reasons == [MatchReason::PreviousUse]));

        let with_limit = search_frecent(
            &conn,
            SearchParams {
                search_string: "example".into(),
                limit: 1,
            },
        )
        .expect("Should search until reaching limit");
        assert_eq!(
            with_limit,
            vec![SearchResult {
                search_string: "example".into(),
                url: Url::parse("http://example.com/").unwrap(),
                title: "example.com/".into(),
                icon_url: None,
                frecency: 1999,
                reasons: vec![MatchReason::Origin],
            }]
        );
    }
    #[test]
    fn search_unicode() {
        let conn = new_mem_connection();

        let url = Url::parse("http://exämple.com/123").unwrap();
        let visit = VisitObservation::new(url)
            .with_title("Example page 123".to_string())
            .with_visit_type(VisitTransition::Typed)
            .with_at(Timestamp::now());

        apply_observation(&conn, visit).expect("Should apply visit");

        let by_url_without_path = search_frecent(
            &conn,
            SearchParams {
                search_string: "http://exämple.com".into(),
                limit: 10,
            },
        )
        .expect("Should search by URL without path");
        assert!(by_url_without_path
            .iter()
            // Should we consider un-punycoding the title? (firefox desktop doesn't...)
            .any(|result| result.title == "xn--exmple-cua.com/"
                && result.url.as_str() == "http://xn--exmple-cua.com/"
                && result.reasons == [MatchReason::Url]));

        let by_url_with_path = search_frecent(
            &conn,
            SearchParams {
                search_string: "http://exämple.com/1".into(),
                limit: 10,
            },
        )
        .expect("Should search by URL with path");
        assert!(
            by_url_with_path
                .iter()
                .any(|result| result.title == "xn--exmple-cua.com/123"
                    && result.url.as_str() == "http://xn--exmple-cua.com/123"
                    && result.reasons == [MatchReason::Url]),
            "{:?}",
            by_url_with_path
        );

        // The "ball of yarn" emoji is not currently accepted as valid
        // in URLs, but we should just return an empty result set.
        let ball_of_yarn_about_blank = "about:blank🧶";
        let empty = match_url(&conn, ball_of_yarn_about_blank).unwrap();
        assert!(empty.is_none());
        // Just run this to make sure the unwrap doesn't panic us
        search_frecent(
            &conn,
            SearchParams {
                search_string: ball_of_yarn_about_blank.into(),
                limit: 10,
            },
        )
        .unwrap();
    }
    // This panics in tests but not for "real" consumers. In an effort to ensure
    // we are panicing where we think we are, note the 'expected' string.
    // (Not really clear this test offers much value, but seems worth having...)
    #[test]
    #[cfg_attr(
        debug_assertions,
        should_panic(expected = "Failed to perform a search:")
    )]
    fn search_invalid_url() {
        use rusqlite::NO_PARAMS;
        let conn = new_mem_connection();

        conn.execute(
            "INSERT INTO moz_places (guid, url, url_hash, frecency)
             VALUES ('fake_guid___', 'not-a-url', hash('not-a-url'), 10)",
            NO_PARAMS,
        )
        .expect("should insert");

        let _ = search_frecent(
            &conn,
            SearchParams {
                search_string: "not-a-url".into(),
                limit: 10,
            },
        );
    }
}
