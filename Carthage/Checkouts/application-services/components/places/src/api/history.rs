/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::apply_observation;
use crate::db::PlacesDb;
use crate::error::*;
use crate::observation::VisitObservation;
use crate::types::*;
use url::Url;
// This module can become, roughly: PlacesUtils.history()

pub fn can_add_url(_url: &Url) -> Result<bool> {
    Ok(true)
}

// eg: PlacesUtils.history.insert({url: "http", title: ..., visits: [{date: ...}]})

// Structs representing place and visit infos for this API.
// (Not clear this makes sense - it's a copy of what desktop does just to
// get started)
// NOTE THAT THESE STRUCTS are only for demo purposes, showing how
// PlacesUtils.history.insert() could be implemented using the same shaped
// objects.
// They should really be moved into an "examples" folder.
#[derive(Debug)]
pub struct AddablePlaceInfo {
    pub url: Url,
    pub title: Option<String>,
    pub visits: Vec<AddableVisit>,
}

#[derive(Debug)]
pub struct AddableVisit {
    pub date: Timestamp,
    pub transition: VisitTransition,
    pub referrer: Option<Url>,
    pub is_local: bool,
}

// insert a visit a'la PlacesUtils.history.insert()
pub fn insert(conn: &mut PlacesDb, place: AddablePlaceInfo) -> Result<()> {
    for v in place.visits {
        let obs = VisitObservation::new(place.url.clone())
            .with_visit_type(v.transition)
            .with_at(v.date)
            .with_title(place.title.clone())
            .with_is_remote(!v.is_local);
        // .with_referrer(...) ????

        //if place.referrer
        apply_observation(conn, obs)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::places_api::test::new_mem_connection;
    use rusqlite::NO_PARAMS;

    #[test]
    fn test_insert() {
        let mut c = new_mem_connection();
        let url = Url::parse("http://example.com").expect("it's a valid url");
        let date = Timestamp::now();
        let visits = vec![AddableVisit {
            date,
            transition: VisitTransition::Link,
            referrer: None,
            is_local: true,
        }];
        let a = AddablePlaceInfo {
            url,
            title: None,
            visits,
        };

        insert(&mut c, a).expect("should insert");

        // For now, a raw read of the DB.
        let sql = "SELECT p.id, p.url, p.title,
                          p.visit_count_local, p.visit_count_remote,
                          p.hidden, p.typed, p.frecency,
                          p.last_visit_date_local, p.last_visit_date_remote,
                          p.guid, p.foreign_count, p.url_hash, p.description,
                          p.preview_image_url, p.origin_id,
                          v.is_local, v.from_visit, v.place_id,
                          v.visit_date, v.visit_type
                    FROM moz_places p, moz_historyvisits v
                    WHERE v.place_id = p.id";

        let mut stmt = c.db.prepare(sql).expect("valid sql");
        let mut rows = stmt.query(NO_PARAMS).expect("should execute");
        let result = rows.next().expect("should get a row");
        let row = result.expect("expect anything");

        assert_eq!(
            row.get::<_, String>("url").expect("should work"),
            "http://example.com/"
        ); // hrmph - note trailing slash
        assert_eq!(
            row.get::<_, Timestamp>("visit_date").expect("should work"),
            date
        );
        assert_ne!(row.get::<_, i32>("frecency").expect("should work"), 0);
        // XXX - check more.
    }
}

/////////////////////////////////////////////
// Stuff to reimplement nsHistory::VisitUri()
fn is_recently_visited(_url: &Url) -> Result<bool> {
    // History.cpp keeps an in-memory hashtable of urls visited in the last
    // 6 minutes to avoid pages which self-refresh from getting many entries.
    // ie, there's no DB query done here.
    // TODO: implement this.
    Ok(false)
}

fn add_recently_visited(_url: &Url) -> Result<()> {
    Ok(())
}

// Other "recent" flags:
// enum RecentEventFlags {
//    RECENT_TYPED      = 1 << 0,    // User typed in URL recently
//    RECENT_ACTIVATED  = 1 << 1,    // User tapped URL link recently
//    RECENT_BOOKMARKED = 1 << 2     // User bookmarked URL recently
//  };
// All of which are just a 15-second in-memory cache, and all of which appear
// to rely on explicit calls to set the flag. eg:
// nsNavHistory::MarkPageAsTyped(nsIURI *aURI) just adds to the cache.

// Is this URL the *source* is a redirect? Note that this is different than
// the redirect flags in the TransitionType, as that is the flag for the
// *target* of the redirect.
#[derive(Debug, Copy, Clone, PartialEq, PartialOrd)]
pub enum RedirectSourceType {
    Temporary,
    Permanent,
}

// nsIHistory::VisitURI - this is the main interface used by the browser
// itself to record visits.
// This differs from the desktop implementation in one major way - instead
// of using various browser-specific heuristics to compute the VisitTransition
// we assume the caller has already done this and passed the correct transition
// flags in.
pub fn visit_uri(
    conn: &mut PlacesDb,
    url: &Url,
    last_url: Option<Url>,
    // To be more honest, this would *not* take a VisitTransition,
    // but instead other "internal" nsIHistory flags, from which
    // it would deduce the VisitTransition.
    transition: VisitTransition,
    redirect_source: Option<RedirectSourceType>,
    is_error_page: bool,
) -> Result<()> {
    // Silently return if URI is something we shouldn't add to DB.
    if !can_add_url(&url)? {
        return Ok(());
    };
    // Do not save a reloaded uri if we have visited the same URI recently.
    // (Note that desktop implies `reload` based of the "is it the same as last
    // and is it recent" check below) - but here we are asking for the
    // VisitTransition to be passed in, which explicity has a value for reload.
    // Note clear if we should try and unify these.
    // (and note that if we can, we can drop the recently_visited cache)
    if let Some(ref last) = last_url {
        if url == last && is_recently_visited(url)? {
            // it's a reload we don't want to record, although we do want to
            // update it as being recent.
            add_recently_visited(url)?;
            return Ok(());
        };
    }
    // So add it.

    // XXX - translate the flags passed to this function, along with the
    // RECENT_* cache above to create the correct Transition type.
    // call get_hidden_state to see if .hidden should be set.

    // get_hidden_state...

    // EMBED visits are session-persistent and should not go through the database.
    // They exist only to keep track of isVisited status during the session.
    if transition == VisitTransition::Embed {
        log::warn!("Embed visit, but in-memory storage of these isn't done yet");
        return Ok(());
    }

    let obs = VisitObservation::new(url.clone())
        .with_is_error(is_error_page)
        .with_visit_type(transition)
        .with_is_redirect_source(redirect_source.map(|_r| true))
        .with_is_permanent_redirect_source(
            redirect_source.map(|r| r == RedirectSourceType::Permanent),
        );
    apply_observation(conn, obs)
}
