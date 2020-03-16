/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

pub mod history;
pub mod matcher;
pub mod places_api;
use crate::db::PlacesDb;
use crate::error::Result;
use crate::observation::VisitObservation;
use crate::storage;

pub fn apply_observation(conn: &mut PlacesDb, visit_obs: VisitObservation) -> Result<()> {
    storage::history::apply_observation(conn, visit_obs)?;
    Ok(())
}
