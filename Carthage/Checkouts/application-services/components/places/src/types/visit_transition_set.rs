/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use super::{InvalidVisitType, VisitTransition};
use rusqlite::types::ToSqlOutput;
use std::convert::{TryFrom, TryInto};

#[derive(Copy, Clone, Debug, Default, PartialEq, Eq, Hash)]
pub struct VisitTransitionSet {
    bits: u16,
}

const ALL_BITS_SET: u16 = (1u16 << (VisitTransition::Link as u8))
    | (1u16 << (VisitTransition::Typed as u8))
    | (1u16 << (VisitTransition::Bookmark as u8))
    | (1u16 << (VisitTransition::Embed as u8))
    | (1u16 << (VisitTransition::RedirectPermanent as u8))
    | (1u16 << (VisitTransition::RedirectTemporary as u8))
    | (1u16 << (VisitTransition::Download as u8))
    | (1u16 << (VisitTransition::FramedLink as u8))
    | (1u16 << (VisitTransition::Reload as u8));

impl VisitTransitionSet {
    pub const fn new() -> Self {
        Self { bits: 0 }
    }

    pub const fn empty() -> Self {
        Self::new()
    }

    pub const fn all() -> Self {
        Self { bits: ALL_BITS_SET }
    }

    pub const fn single(ty: VisitTransition) -> Self {
        Self {
            bits: (1u16 << (ty as u8)),
        }
    }

    pub fn for_specific(tys: &[VisitTransition]) -> Self {
        tys.iter().cloned().collect()
    }

    pub fn into_u16(self) -> u16 {
        self.bits
    }

    pub fn from_u16(v: u16) -> Result<VisitTransitionSet, InvalidVisitType> {
        v.try_into()
    }

    pub fn contains(self, t: VisitTransition) -> bool {
        (self.bits & (1 << (t as u32))) != 0
    }

    pub fn insert(&mut self, t: VisitTransition) {
        self.bits |= 1 << (t as u8);
    }

    pub fn remove(&mut self, t: VisitTransition) {
        self.bits &= !(1 << (t as u8));
    }

    pub fn complement(self) -> VisitTransitionSet {
        Self {
            bits: (!self.bits) & ALL_BITS_SET,
        }
    }

    pub fn len(self) -> usize {
        self.bits.count_ones() as usize
    }

    pub fn is_empty(self) -> bool {
        self.bits == 0
    }
}

impl TryFrom<u16> for VisitTransitionSet {
    type Error = InvalidVisitType;
    fn try_from(bits: u16) -> Result<Self, InvalidVisitType> {
        if bits != (bits & ALL_BITS_SET) {
            Err(InvalidVisitType)
        } else {
            Ok(Self { bits })
        }
    }
}

impl IntoIterator for VisitTransitionSet {
    type Item = VisitTransition;
    type IntoIter = VisitTransitionSetIter;
    fn into_iter(self) -> VisitTransitionSetIter {
        VisitTransitionSetIter {
            bits: self.bits,
            pos: 0,
        }
    }
}

pub struct VisitTransitionSetIter {
    bits: u16,
    pos: u8,
}

impl Iterator for VisitTransitionSetIter {
    type Item = VisitTransition;
    fn next(&mut self) -> Option<Self::Item> {
        if self.bits == 0 {
            return None;
        }
        while (self.bits & 1) == 0 {
            self.pos += 1;
            self.bits >>= 1;
        }
        // Should always be fine unless VisitTransitionSet has a bug.
        let result: VisitTransition = self.pos.try_into().expect("Bug in VisitTransitionSet");
        self.pos += 1;
        self.bits >>= 1;
        Some(result)
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        let value = self.bits.count_ones() as usize;
        (value, Some(value))
    }
}

impl From<VisitTransitionSet> for u16 {
    fn from(vts: VisitTransitionSet) -> Self {
        vts.bits
    }
}

impl Extend<VisitTransition> for VisitTransitionSet {
    fn extend<I>(&mut self, iter: I)
    where
        I: IntoIterator<Item = VisitTransition>,
    {
        for element in iter {
            self.insert(element);
        }
    }
}

impl std::iter::FromIterator<VisitTransition> for VisitTransitionSet {
    fn from_iter<I>(iterator: I) -> Self
    where
        I: IntoIterator<Item = VisitTransition>,
    {
        let mut ret = Self::new();
        ret.extend(iterator);
        ret
    }
}

impl rusqlite::ToSql for VisitTransitionSet {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput<'_>> {
        Ok(ToSqlOutput::from(u16::from(*self)))
    }
}

#[cfg(test)]
mod test {
    use super::*;

    const ALL_TRANSITIONS: &[VisitTransition] = &[
        VisitTransition::Link,
        VisitTransition::Typed,
        VisitTransition::Bookmark,
        VisitTransition::Embed,
        VisitTransition::RedirectPermanent,
        VisitTransition::RedirectTemporary,
        VisitTransition::Download,
        VisitTransition::FramedLink,
        VisitTransition::Reload,
    ];
    #[test]
    fn test_vtset() {
        let mut vts = VisitTransitionSet::empty();
        let vts_all = VisitTransitionSet::all();
        assert_eq!(vts_all.len(), ALL_TRANSITIONS.len());
        assert_eq!(vts.len(), 0);
        for &ty in ALL_TRANSITIONS {
            assert!(vts_all.contains(ty));
            vts.insert(ty);
            assert_eq!(vts.into_u16().try_into(), Ok(vts));
        }
        assert_eq!(vts_all, vts);

        let to_remove = &[
            VisitTransition::Typed,
            VisitTransition::RedirectPermanent,
            VisitTransition::RedirectTemporary,
        ];
        for &r in to_remove {
            assert!(vts.contains(r));
            vts.remove(r);
            assert!(!vts.contains(r));
        }
        for &ty in ALL_TRANSITIONS {
            if to_remove.contains(&ty) {
                assert!(!vts.contains(ty));
                assert!(vts.complement().contains(ty));
            } else {
                assert!(vts.contains(ty));
                assert!(!vts.complement().contains(ty));
            }
        }
    }

    #[test]
    fn test_vtset_iter() {
        let mut vts = VisitTransitionSet::all();
        assert_eq!(&vts.into_iter().collect::<Vec<_>>()[..], ALL_TRANSITIONS);

        let to_remove = &[
            VisitTransition::Typed,
            VisitTransition::RedirectPermanent,
            VisitTransition::RedirectTemporary,
        ];

        for &r in to_remove {
            vts.remove(r);
        }

        let want = &[
            VisitTransition::Link,
            VisitTransition::Bookmark,
            VisitTransition::Embed,
            VisitTransition::Download,
            VisitTransition::FramedLink,
            VisitTransition::Reload,
        ];
        assert_eq!(&vts.into_iter().collect::<Vec<_>>()[..], want);

        assert_eq!(
            &vts.complement().into_iter().collect::<Vec<_>>()[..],
            to_remove
        );
    }

    #[test]
    fn test_vtset_try_from() {
        assert!(VisitTransitionSet::try_from(1).is_err());

        assert_eq!(
            VisitTransitionSet::try_from(2),
            Ok(VisitTransitionSet::single(VisitTransition::Link)),
        );

        assert!(VisitTransitionSet::try_from(ALL_BITS_SET + 1).is_err(),);

        assert!(VisitTransitionSet::try_from(ALL_BITS_SET + 2).is_err(),);

        assert_eq!(
            VisitTransitionSet::try_from(ALL_BITS_SET),
            Ok(VisitTransitionSet::all()),
        );
    }
}
