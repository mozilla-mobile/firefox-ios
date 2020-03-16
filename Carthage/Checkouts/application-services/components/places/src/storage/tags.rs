/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::{fetch_page_info, TAG_LENGTH_MAX};
use crate::db::PlacesDb;
use crate::error::{InvalidPlaceInfo, Result};
use sql_support::ConnExt;
use url::Url;

/// The validity of a tag.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ValidatedTag<'a> {
    /// The tag is invalid.
    Invalid(&'a str),

    /// The tag is valid, but normalized to remove leading and trailing
    /// whitespace.
    Normalized(&'a str),

    /// The original tag is valid.
    Original(&'a str),
}

impl<'a> ValidatedTag<'a> {
    /// Returns `true` if the original tag is valid; `false` if it's invalid or
    /// normalized.
    pub fn is_original(&self) -> bool {
        match &self {
            ValidatedTag::Original(_) => true,
            _ => false,
        }
    }

    /// Returns the tag string if the tag is valid or normalized, or an error
    /// if the tag is invalid.
    pub fn ensure_valid(&self) -> Result<&'a str> {
        match self {
            ValidatedTag::Invalid(_) => Err(InvalidPlaceInfo::InvalidTag.into()),
            ValidatedTag::Normalized(t) | ValidatedTag::Original(t) => Ok(t),
        }
    }
}

/// Checks the validity of the specified tag.
pub fn validate_tag(tag: &str) -> ValidatedTag<'_> {
    // Drop empty and oversized tags.
    let t = tag.trim();
    if t.is_empty() || t.len() > TAG_LENGTH_MAX {
        ValidatedTag::Invalid(tag)
    } else if t.len() != tag.len() {
        ValidatedTag::Normalized(t)
    } else {
        ValidatedTag::Original(t)
    }
}

/// Tags the specified URL.
///
/// # Arguments
///
/// * `conn` - A database connection on which to operate.
///
/// * `url` - The URL to tag.
///
/// * `tag` - The tag to add for the URL.
///
/// # Returns
///
/// There is no success return value.
pub fn tag_url(db: &PlacesDb, url: &Url, tag: &str) -> Result<()> {
    let tag = validate_tag(&tag).ensure_valid()?;
    let tx = db.begin_transaction()?;

    // This function will not create a new place.
    // Fetch the place id, so we (a) avoid creating a new tag when we aren't
    // going to reference it and (b) to avoid a sub-query.
    let place_id = match fetch_page_info(db, url)? {
        Some(info) => info.page.row_id,
        None => return Err(InvalidPlaceInfo::NoSuchUrl.into()),
    };

    db.execute_named_cached(
        "INSERT OR IGNORE INTO moz_tags(tag, lastModified)
         VALUES(:tag, now())",
        &[(":tag", &tag)],
    )?;

    db.execute_named_cached(
        "INSERT OR IGNORE INTO moz_tags_relation(tag_id, place_id)
         VALUES((SELECT id FROM moz_tags WHERE tag = :tag), :place_id)",
        &[(":tag", &tag), (":place_id", &place_id)],
    )?;
    tx.commit()?;
    Ok(())
}

/// Remove the specified tag from the specified URL.
///
/// # Arguments
///
/// * `conn` - A database connection on which to operate.
///
/// * `url` - The URL from which the tag should be removed.
///
/// * `tag` - The tag to remove from the URL.
///
/// # Returns
///
/// There is no success return value - the operation is ignored if the URL
/// does not have the tag.
pub fn untag_url(db: &PlacesDb, url: &Url, tag: &str) -> Result<()> {
    let tag = validate_tag(&tag).ensure_valid()?;
    db.execute_named_cached(
        "DELETE FROM moz_tags_relation
         WHERE tag_id = (SELECT id FROM moz_tags
                         WHERE tag = :tag)
         AND place_id = (SELECT id FROM moz_places
                         WHERE url_hash = hash(:url)
                         AND url = :url)",
        &[(":tag", &tag), (":url", &url.as_str())],
    )?;
    Ok(())
}

/// Remove all tags from the specified URL.
///
/// # Arguments
///
/// * `conn` - A database connection on which to operate.
///
/// * `url` - The URL for which all tags should be removed.
///
/// # Returns
///
/// There is no success return value.
pub fn remove_all_tags_from_url(db: &PlacesDb, url: &Url) -> Result<()> {
    db.execute_named_cached(
        "DELETE FROM moz_tags_relation
         WHERE
         place_id = (SELECT id FROM moz_places
                     WHERE url_hash = hash(:url)
                     AND url = :url)",
        &[(":url", &url.as_str())],
    )?;
    Ok(())
}

/// Remove the specified tag from all URLs.
///
/// # Arguments
///
/// * `conn` - A database connection on which to operate.
///
/// * `tag` - The tag to remove.
///
/// # Returns
///
/// There is no success return value.
pub fn remove_tag(db: &PlacesDb, tag: &str) -> Result<()> {
    db.execute_named_cached(
        "DELETE FROM moz_tags
         WHERE tag = :tag",
        &[(":tag", &tag)],
    )?;
    Ok(())
}

/// Retrieves a list of URLs which have the specified tag.
///
/// # Arguments
///
/// * `conn` - A database connection on which to operate.
///
/// * `tag` - The tag to query.
///
/// # Returns
///
/// * A Vec<Url> with all URLs which have the tag, ordered by the frecency of
/// the URLs.
pub fn get_urls_with_tag(db: &PlacesDb, tag: &str) -> Result<Vec<Url>> {
    let tag = validate_tag(&tag).ensure_valid()?;

    let mut stmt = db.prepare(
        "SELECT p.url FROM moz_places p
         JOIN moz_tags_relation r ON r.place_id = p.id
         JOIN moz_tags t ON t.id = r.tag_id
         WHERE t.tag = :tag
         ORDER BY p.frecency",
    )?;

    let rows = stmt.query_and_then_named(&[(":tag", &tag)], |row| row.get::<_, String>("url"))?;
    let mut urls = Vec::new();
    for row in rows {
        urls.push(Url::parse(&row?)?);
    }
    Ok(urls)
}

/// Retrieves a list of tags for the specified URL.
///
/// # Arguments
///
/// * `conn` - A database connection on which to operate.
///
/// * `url` - The URL to query.
///
/// # Returns
///
/// * A Vec<String> with all tags for the URL, sorted by the last modified
///   date of the tag (latest to oldest)
pub fn get_tags_for_url(db: &PlacesDb, url: &Url) -> Result<Vec<String>> {
    let mut stmt = db.prepare(
        "SELECT t.tag
         FROM moz_tags t
         JOIN moz_tags_relation r ON r.tag_id = t.id
         JOIN moz_places h ON h.id = r.place_id
         WHERE url_hash = hash(:url) AND url = :url
         ORDER BY t.lastModified DESC",
    )?;
    let rows = stmt.query_and_then_named(&[(":url", &url.as_str())], |row| {
        row.get::<_, String>("tag")
    })?;
    let mut tags = Vec::new();
    for row in rows {
        tags.push(row?);
    }
    Ok(tags)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::places_api::test::new_mem_connection;
    use crate::storage::new_page_info;

    fn check_tags_for_url(db: &PlacesDb, url: &Url, mut expected: Vec<String>) {
        let mut tags = get_tags_for_url(&db, &url).expect("should work");
        tags.sort();
        expected.sort();
        assert_eq!(tags, expected);
    }

    fn check_urls_with_tag(db: &PlacesDb, tag: &str, mut expected: Vec<Url>) {
        let mut with_tag = get_urls_with_tag(db, tag).expect("should work");
        with_tag.sort();
        expected.sort();
        assert_eq!(with_tag, expected);
    }

    fn get_foreign_count(db: &PlacesDb, url: &Url) -> i32 {
        let count: Result<Option<i32>> = db.try_query_row(
            "SELECT foreign_count
             FROM moz_places
             WHERE url = :url",
            &[(":url", &url.as_str())],
            |row| Ok(row.get::<_, i32>(0)?),
            false,
        );
        count.expect("should work").expect("should get a value")
    }

    #[test]
    fn test_validate_tag() {
        let v = validate_tag("foo");
        assert_eq!(v, ValidatedTag::Original("foo"));
        assert!(v.is_original());
        assert_eq!(v.ensure_valid().expect("should work"), "foo");

        let v = validate_tag(" foo ");
        assert_eq!(v, ValidatedTag::Normalized("foo"));
        assert!(!v.is_original());
        assert_eq!(v.ensure_valid().expect("should work"), "foo");

        let v = validate_tag("");
        assert_eq!(v, ValidatedTag::Invalid(""));
        assert!(!v.is_original());
        assert!(v.ensure_valid().is_err());

        assert_eq!(validate_tag("foo bar"), ValidatedTag::Original("foo bar"));
        assert_eq!(
            validate_tag(" foo bar "),
            ValidatedTag::Normalized("foo bar")
        );

        assert!(validate_tag(&"f".repeat(101)).ensure_valid().is_err());
    }

    #[test]
    fn test_tags() {
        let conn = new_mem_connection();
        let url1 = Url::parse("http://example.com").expect("valid url");
        let url2 = Url::parse("http://example2.com").expect("valid url");

        new_page_info(&conn, &url1, None).expect("should create the page");
        new_page_info(&conn, &url2, None).expect("should create the page");
        check_tags_for_url(&conn, &url1, vec![]);
        check_tags_for_url(&conn, &url2, vec![]);
        assert_eq!(get_foreign_count(&conn, &url1), 0);
        assert_eq!(get_foreign_count(&conn, &url2), 0);

        tag_url(&conn, &url1, "common").expect("should work");
        assert_eq!(get_foreign_count(&conn, &url1), 1);
        tag_url(&conn, &url1, "tag-1").expect("should work");
        assert_eq!(get_foreign_count(&conn, &url1), 2);
        tag_url(&conn, &url2, "common").expect("should work");
        assert_eq!(get_foreign_count(&conn, &url2), 1);
        tag_url(&conn, &url2, "tag-2").expect("should work");
        assert_eq!(get_foreign_count(&conn, &url2), 2);

        check_tags_for_url(
            &conn,
            &url1,
            vec!["common".to_string(), "tag-1".to_string()],
        );
        check_tags_for_url(
            &conn,
            &url2,
            vec!["common".to_string(), "tag-2".to_string()],
        );

        check_urls_with_tag(&conn, "common", vec![url1.clone(), url2.clone()]);
        check_urls_with_tag(&conn, "tag-1", vec![url1.clone()]);
        check_urls_with_tag(&conn, "tag-2", vec![url2.clone()]);

        untag_url(&conn, &url1, "common").expect("should work");
        assert_eq!(get_foreign_count(&conn, &url1), 1);

        check_urls_with_tag(&conn, "common", vec![url2.clone()]);

        remove_tag(&conn, "common").expect("should work");
        check_urls_with_tag(&conn, "common", vec![]);
        assert_eq!(get_foreign_count(&conn, &url2), 1);

        remove_tag(&conn, "tag-1").expect("should work");
        check_urls_with_tag(&conn, "tag-1", vec![]);
        assert_eq!(get_foreign_count(&conn, &url1), 0);

        remove_tag(&conn, "tag-2").expect("should work");
        check_urls_with_tag(&conn, "tag-2", vec![]);
        assert_eq!(get_foreign_count(&conn, &url2), 0);

        // should be no tags rows left.
        let count: Result<Option<u32>> = conn.try_query_row(
            "SELECT COUNT(*) from moz_tags",
            &[],
            |row| Ok(row.get::<_, u32>(0)?),
            true,
        );
        assert_eq!(count.unwrap().unwrap(), 0);
        let count: Result<Option<u32>> = conn.try_query_row(
            "SELECT COUNT(*) from moz_tags_relation",
            &[],
            |row| Ok(row.get::<_, u32>(0)?),
            true,
        );
        assert_eq!(count.unwrap().unwrap(), 0);

        // places should still exist.
        fetch_page_info(&conn, &url1)
            .expect("should work")
            .expect("should exist");
        fetch_page_info(&conn, &url2)
            .expect("should work")
            .expect("should exist");
    }
}
