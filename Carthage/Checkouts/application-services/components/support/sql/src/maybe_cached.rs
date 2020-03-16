/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use rusqlite::{self, CachedStatement, Connection, Statement};

use std::ops::{Deref, DerefMut};

/// MaybeCached is a type that can be used to help abstract
/// over cached and uncached rusqlite statements in a transparent manner.
pub enum MaybeCached<'conn> {
    Uncached(Statement<'conn>),
    Cached(CachedStatement<'conn>),
}

impl<'conn> Deref for MaybeCached<'conn> {
    type Target = Statement<'conn>;
    #[inline]
    fn deref(&self) -> &Statement<'conn> {
        match self {
            MaybeCached::Cached(cached) => Deref::deref(cached),
            MaybeCached::Uncached(uncached) => uncached,
        }
    }
}

impl<'conn> DerefMut for MaybeCached<'conn> {
    #[inline]
    fn deref_mut(&mut self) -> &mut Statement<'conn> {
        match self {
            MaybeCached::Cached(cached) => DerefMut::deref_mut(cached),
            MaybeCached::Uncached(uncached) => uncached,
        }
    }
}

impl<'conn> From<Statement<'conn>> for MaybeCached<'conn> {
    #[inline]
    fn from(stmt: Statement<'conn>) -> Self {
        MaybeCached::Uncached(stmt)
    }
}

impl<'conn> From<CachedStatement<'conn>> for MaybeCached<'conn> {
    #[inline]
    fn from(stmt: CachedStatement<'conn>) -> Self {
        MaybeCached::Cached(stmt)
    }
}

impl<'conn> MaybeCached<'conn> {
    #[inline]
    pub fn prepare(
        conn: &'conn Connection,
        sql: &str,
        cached: bool,
    ) -> rusqlite::Result<MaybeCached<'conn>> {
        if cached {
            Ok(MaybeCached::Cached(conn.prepare_cached(sql)?))
        } else {
            Ok(MaybeCached::Uncached(conn.prepare(sql)?))
        }
    }
}
