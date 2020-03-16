/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#![cfg(feature = "rusqlite_support")]

use crate::Guid;
use rusqlite::{
    self,
    types::{FromSql, FromSqlResult, ToSql, ToSqlOutput, ValueRef},
};

impl ToSql for Guid {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(self.as_str()))
    }
}

impl FromSql for Guid {
    fn column_result(value: ValueRef<'_>) -> FromSqlResult<Self> {
        value.as_str().map(Guid::from)
    }
}
