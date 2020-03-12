/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use std::fmt;

/// Helper type for printing repeated strings more efficiently. You should use
/// [`repeat_display`](sql_support::repeat_display), or one of the `repeat_sql_*` helpers to
/// construct it.
#[derive(Debug, Clone)]
pub struct RepeatDisplay<'a, F> {
    count: usize,
    sep: &'a str,
    fmt_one: F,
}

impl<'a, F> fmt::Display for RepeatDisplay<'a, F>
where
    F: Fn(usize, &mut fmt::Formatter<'_>) -> fmt::Result,
{
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        for i in 0..self.count {
            if i != 0 {
                f.write_str(self.sep)?;
            }
            (self.fmt_one)(i, f)?;
        }
        Ok(())
    }
}

/// Construct a RepeatDisplay that will repeatedly call `fmt_one` with a formatter `count` times,
/// separated by `sep`.
///
/// # Example
///
/// ```rust
/// # use sql_support::repeat_display;
/// assert_eq!(format!("{}", repeat_display(1, ",", |i, f| write!(f, "({},?)", i))),
///            "(0,?)");
/// assert_eq!(format!("{}", repeat_display(2, ",", |i, f| write!(f, "({},?)", i))),
///            "(0,?),(1,?)");
/// assert_eq!(format!("{}", repeat_display(3, ",", |i, f| write!(f, "({},?)", i))),
///            "(0,?),(1,?),(2,?)");
/// ```
#[inline]
pub fn repeat_display<F>(count: usize, sep: &str, fmt_one: F) -> RepeatDisplay<'_, F>
where
    F: Fn(usize, &mut fmt::Formatter<'_>) -> fmt::Result,
{
    RepeatDisplay {
        count,
        sep,
        fmt_one,
    }
}

/// Returns a value that formats as `count` instances of `?` separated by commas.
///
/// # Example
///
/// ```rust
/// # use sql_support::repeat_sql_vars;
/// assert_eq!(format!("{}", repeat_sql_vars(0)), "");
/// assert_eq!(format!("{}", repeat_sql_vars(1)), "?");
/// assert_eq!(format!("{}", repeat_sql_vars(2)), "?,?");
/// assert_eq!(format!("{}", repeat_sql_vars(3)), "?,?,?");
/// ```
pub fn repeat_sql_vars(count: usize) -> impl fmt::Display {
    repeat_display(count, ",", |_, f| write!(f, "?"))
}

/// Returns a value that formats as `count` instances of `(?)` separated by commas.
///
/// # Example
///
/// ```rust
/// # use sql_support::repeat_sql_values;
/// assert_eq!(format!("{}", repeat_sql_values(0)), "");
/// assert_eq!(format!("{}", repeat_sql_values(1)), "(?)");
/// assert_eq!(format!("{}", repeat_sql_values(2)), "(?),(?)");
/// assert_eq!(format!("{}", repeat_sql_values(3)), "(?),(?),(?)");
/// ```
///
pub fn repeat_sql_values(count: usize) -> impl fmt::Display {
    // We could also implement this as `repeat_sql_multi_values(count, 1)`,
    // but this is faster and no less clear IMO.
    repeat_display(count, ",", |_, f| write!(f, "(?)"))
}

/// Returns a value that formats as `num_values` instances of `(?,?,?,...)` (where there are
/// `vars_per_value` question marks separated by commas in between the `?`s).
///
/// Panics if `vars_per_value` is zero (however, `num_values` is allowed to be zero).
///
/// # Example
///
/// ```rust
/// # use sql_support::repeat_multi_values;
/// assert_eq!(format!("{}", repeat_multi_values(0, 2)), "");
/// assert_eq!(format!("{}", repeat_multi_values(1, 5)), "(?,?,?,?,?)");
/// assert_eq!(format!("{}", repeat_multi_values(2, 3)), "(?,?,?),(?,?,?)");
/// assert_eq!(format!("{}", repeat_multi_values(3, 1)), "(?),(?),(?)");
/// ```
pub fn repeat_multi_values(num_values: usize, vars_per_value: usize) -> impl fmt::Display {
    assert_ne!(
        vars_per_value, 0,
        "Illegal value for `vars_per_value`, must not be zero"
    );
    repeat_display(num_values, ",", move |_, f| {
        write!(f, "({})", repeat_sql_vars(vars_per_value))
    })
}
