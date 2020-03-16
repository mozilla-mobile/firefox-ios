/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use crate::error::*;
use crate::types::VisitTransition;
use rusqlite::Connection;

#[derive(Debug, Clone, Copy, PartialEq)]
enum RedirectBonus {
    Unknown,
    Redirect,
    Normal,
}

#[derive(Debug, Clone, PartialEq)]
pub struct FrecencySettings {
    // TODO: These probably should not all be i32s...
    pub num_visits: i32,                     // from "places.frecency.numVisits"
    pub first_bucket_cutoff_days: i32,       // from "places.frecency.firstBucketCutoff"
    pub second_bucket_cutoff_days: i32,      // from "places.frecency.secondBucketCutoff"
    pub third_bucket_cutoff_days: i32,       // from "places.frecency.thirdBucketCutoff"
    pub fourth_bucket_cutoff_days: i32,      // from "places.frecency.fourthBucketCutoff"
    pub first_bucket_weight: i32,            // from "places.frecency.firstBucketWeight"
    pub second_bucket_weight: i32,           // from "places.frecency.secondBucketWeight"
    pub third_bucket_weight: i32,            // from "places.frecency.thirdBucketWeight"
    pub fourth_bucket_weight: i32,           // from "places.frecency.fourthBucketWeight"
    pub default_bucket_weight: i32,          // from "places.frecency.defaultBucketWeight"
    pub embed_visit_bonus: i32,              // from "places.frecency.embedVisitBonus"
    pub framed_link_visit_bonus: i32,        // from "places.frecency.framedLinkVisitBonus"
    pub link_visit_bonus: i32,               // from "places.frecency.linkVisitBonus"
    pub typed_visit_bonus: i32,              // from "places.frecency.typedVisitBonus"
    pub bookmark_visit_bonus: i32,           // from "places.frecency.bookmarkVisitBonus"
    pub download_visit_bonus: i32,           // from "places.frecency.downloadVisitBonus"
    pub permanent_redirect_visit_bonus: i32, // from "places.frecency.permRedirectVisitBonus"
    pub temporary_redirect_visit_bonus: i32, // from "places.frecency.tempRedirectVisitBonus"
    pub redirect_source_visit_bonus: i32,    // from "places.frecency.redirectSourceVisitBonus"
    pub default_visit_bonus: i32,            // from "places.frecency.defaultVisitBonus"
    pub unvisited_bookmark_bonus: i32,       // from "places.frecency.unvisitedBookmarkBonus"
    pub unvisited_typed_bonus: i32,          // from "places.frecency.unvisitedTypedBonus"
    pub reload_visit_bonus: i32,             // from "places.frecency.reloadVisitBonus"
}

pub const DEFAULT_FRECENCY_SETTINGS: FrecencySettings = FrecencySettings {
    // These are the default values of the preferences.
    num_visits: 10,
    first_bucket_cutoff_days: 4,
    second_bucket_cutoff_days: 14,
    third_bucket_cutoff_days: 31,
    fourth_bucket_cutoff_days: 90,
    first_bucket_weight: 100,
    second_bucket_weight: 70,
    third_bucket_weight: 50,
    fourth_bucket_weight: 30,
    default_bucket_weight: 10,
    embed_visit_bonus: 0,
    framed_link_visit_bonus: 0,
    link_visit_bonus: 100,
    typed_visit_bonus: 2000,
    bookmark_visit_bonus: 75,
    download_visit_bonus: 0,
    permanent_redirect_visit_bonus: 0,
    temporary_redirect_visit_bonus: 0,
    redirect_source_visit_bonus: 25,
    default_visit_bonus: 0,
    unvisited_bookmark_bonus: 140,
    unvisited_typed_bonus: 200,
    reload_visit_bonus: 0,
};

impl Default for FrecencySettings {
    #[inline]
    fn default() -> Self {
        DEFAULT_FRECENCY_SETTINGS
    }
}

impl FrecencySettings {
    // Note: in Places, `redirect` defaults to false.
    pub fn get_transition_bonus(
        &self,
        visit_type: Option<VisitTransition>,
        visited: bool,
        redirect: bool,
    ) -> i32 {
        if redirect {
            return self.redirect_source_visit_bonus;
        }
        match (visit_type, visited) {
            (Some(VisitTransition::Link), _) => self.link_visit_bonus,
            (Some(VisitTransition::Embed), _) => self.embed_visit_bonus,
            (Some(VisitTransition::FramedLink), _) => self.framed_link_visit_bonus,
            (Some(VisitTransition::RedirectPermanent), _) => self.temporary_redirect_visit_bonus,
            (Some(VisitTransition::RedirectTemporary), _) => self.permanent_redirect_visit_bonus,
            (Some(VisitTransition::Download), _) => self.download_visit_bonus,
            (Some(VisitTransition::Reload), _) => self.reload_visit_bonus,
            (Some(VisitTransition::Typed), true) => self.typed_visit_bonus,
            (Some(VisitTransition::Typed), false) => self.unvisited_typed_bonus,
            (Some(VisitTransition::Bookmark), true) => self.bookmark_visit_bonus,
            (Some(VisitTransition::Bookmark), false) => self.unvisited_bookmark_bonus,
            // 0 == undefined (see bug 375777 in bugzilla for details)
            (None, _) => self.default_visit_bonus,
        }
    }

    fn get_frecency_aged_weight(&self, age_in_days: i32) -> i32 {
        if age_in_days <= self.first_bucket_cutoff_days {
            self.first_bucket_weight
        } else if age_in_days <= self.second_bucket_cutoff_days {
            self.second_bucket_weight
        } else if age_in_days <= self.third_bucket_cutoff_days {
            self.third_bucket_weight
        } else if age_in_days <= self.fourth_bucket_cutoff_days {
            self.fourth_bucket_weight
        } else {
            self.default_bucket_weight
        }
    }
}

struct FrecencyComputation<'db, 's> {
    conn: &'db Connection,
    settings: &'s FrecencySettings,
    page_id: i64,
    most_recent_redirect_bonus: RedirectBonus,

    typed: i32,
    visit_count: i32,
    foreign_count: i32,
    is_query: bool,
}

impl<'db, 's> FrecencyComputation<'db, 's> {
    fn new(
        conn: &'db Connection,
        settings: &'s FrecencySettings,
        page_id: i64,
        most_recent_redirect_bonus: RedirectBonus,
    ) -> Result<Self> {
        let (typed, visit_count, foreign_count, is_query) = conn.query_row_named("
            SELECT typed, (visit_count_local + visit_count_remote) as visit_count, foreign_count, (substr(url, 0, 7) = 'place:') as is_query
            FROM moz_places
            WHERE id = :page_id
        ", &[(":page_id", &page_id)], |row| {
            let typed: i32 = row.get("typed")?;
            let visit_count: i32 = row.get("visit_count")?;
            let foreign_count: i32 = row.get("foreign_count")?;
            let is_query: bool = row.get("is_query")?;
            Ok((typed, visit_count, foreign_count, is_query))
        })?;

        Ok(Self {
            conn,
            settings,
            page_id,
            most_recent_redirect_bonus,
            typed,
            visit_count,
            foreign_count,
            is_query,
        })
    }

    fn has_bookmark(&self) -> bool {
        self.foreign_count > 0
    }

    fn score_recent_visits(&self) -> Result<(usize, f32)> {
        // Get a sample of the last visits to the page, to calculate its weight.
        // In case the visit is a redirect target, calculate the frecency
        // as if the original page was visited.
        // If it's a redirect source, we may want to use a lower bonus.
        let get_recent_visits = format!(
            "SELECT
                 IFNULL(origin.visit_type, v.visit_type) AS visit_type,
                 target.visit_type AS target_visit_type,
                 ROUND((now() - v.visit_date)/86400000) AS age_in_days
             FROM moz_historyvisits v
             LEFT JOIN moz_historyvisits origin ON origin.id = v.from_visit
                 AND v.visit_type BETWEEN {redirect_permanent} AND {redirect_temporary}
             LEFT JOIN moz_historyvisits target ON v.id = target.from_visit
                 AND target.visit_type BETWEEN {redirect_permanent} AND {redirect_temporary}
             WHERE v.place_id = :page_id
             ORDER BY v.visit_date DESC
             LIMIT {max_visits}",
            redirect_permanent = VisitTransition::RedirectPermanent as u8,
            redirect_temporary = VisitTransition::RedirectTemporary as u8,
            max_visits = self.settings.num_visits,
        );

        let mut stmt = self.conn.prepare(&get_recent_visits)?;

        let row_iter = stmt.query_and_then_named(
            &[(":page_id", &self.page_id)],
            |row| -> rusqlite::Result<_> {
                let visit_type = row.get::<_, Option<u8>>("visit_type")?.unwrap_or(0);
                let target_visit_type = row.get::<_, Option<u8>>("target_visit_type")?.unwrap_or(0);
                let age_in_days: f64 = row.get("age_in_days")?;
                Ok((
                    VisitTransition::from_primitive(visit_type),
                    VisitTransition::from_primitive(target_visit_type),
                    age_in_days as i32,
                ))
            },
        )?;

        let mut num_sampled_visits = 0;
        let mut points_for_sampled_visits = 0.0f32;

        for row_result in row_iter {
            let (visit_type, target_visit_type, age_in_days) = row_result?;
            // When adding a new visit, we should haved passed-in whether we should
            // use the redirect bonus. We can't fetch this information from the
            // database, because we only store redirect targets.
            // For older visits we extract the value from the database.
            let use_redirect_bonus = if self.most_recent_redirect_bonus == RedirectBonus::Unknown
                || num_sampled_visits > 0
            {
                target_visit_type == Some(VisitTransition::RedirectPermanent)
                    || (target_visit_type == Some(VisitTransition::RedirectTemporary)
                        && visit_type != Some(VisitTransition::Typed))
            } else {
                self.most_recent_redirect_bonus == RedirectBonus::Redirect
            };

            let mut bonus =
                self.settings
                    .get_transition_bonus(visit_type, true, use_redirect_bonus);

            if self.has_bookmark() {
                bonus += self.settings.get_transition_bonus(
                    Some(VisitTransition::Bookmark),
                    true,
                    false,
                );
            }
            if bonus != 0 {
                let weight = self.settings.get_frecency_aged_weight(age_in_days) as f32;
                points_for_sampled_visits += weight * (bonus as f32 / 100.0)
            }
            num_sampled_visits += 1;
        }

        Ok((num_sampled_visits, points_for_sampled_visits))
    }

    fn get_frecency_for_sample(&self, num_sampled: usize, score: f32) -> i32 {
        if score == 0.0f32 {
            // We were unable to calculate points, maybe cause all the visits in the
            // sample had a zero bonus. Though, we know the page has some past valid
            // visit, or visit_count would be zero. Thus we set the frecency to
            // -1, so they are still shown in autocomplete.
            -1
        } else {
            // Estimate frecency using the sampled visits.
            // Use ceil() so that we don't round down to 0, which
            // would cause us to completely ignore the place during autocomplete.
            ((self.visit_count as f32) * score.ceil() / (num_sampled as f32)).ceil() as i32
        }
    }

    fn compute_unvisited_bookmark_frecency(&self) -> i32 {
        // Make it so something bookmarked and typed will have a higher frecency
        // than something just typed or just bookmarked.
        let mut bonus =
            self.settings
                .get_transition_bonus(Some(VisitTransition::Bookmark), false, false);
        if self.typed != 0 {
            bonus += self
                .settings
                .get_transition_bonus(Some(VisitTransition::Typed), false, false);
        }

        // Assume "now" as our age_in_days, so use the first bucket.
        let score = (self.settings.first_bucket_weight as f32) * (bonus as f32 / 100.0f32);

        // use ceil() so that we don't round down to 0, which
        // would cause us to completely ignore the place during autocomplete
        score.ceil() as i32
    }
}

pub fn calculate_frecency(
    db: &Connection,
    settings: &FrecencySettings,
    page_id: i64,
    is_redirect: Option<bool>,
) -> Result<i32> {
    assert!(page_id > 0, "calculate_frecency given invalid page_id");

    let most_recent_redirect_bonus = match is_redirect {
        None => RedirectBonus::Unknown,
        Some(true) => RedirectBonus::Redirect,
        Some(false) => RedirectBonus::Normal,
    };

    let fc = FrecencyComputation::new(db, settings, page_id, most_recent_redirect_bonus)?;

    let (num_sampled_visits, sample_score) = if fc.visit_count > 0 {
        fc.score_recent_visits()?
    } else {
        (0, 0.0f32)
    };

    Ok(if num_sampled_visits > 0 {
        // If we sampled some visits for this page, use the calculated weight.
        fc.get_frecency_for_sample(num_sampled_visits, sample_score)
    } else if !fc.has_bookmark() || fc.is_query {
        // Otherwise, this page has no visits, it may be bookmarked.
        0
    } else {
        // For unvisited bookmarks, produce a non-zero frecency, so that they show
        // up in URL bar autocomplete.
        fc.compute_unvisited_bookmark_frecency()
    })
}
