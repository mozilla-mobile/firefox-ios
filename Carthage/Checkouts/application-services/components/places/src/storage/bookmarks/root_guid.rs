/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

use lazy_static::lazy_static;
use sync_guid::Guid as SyncGuid;

pub const USER_CONTENT_ROOTS: &[BookmarkRootGuid] = &[
    BookmarkRootGuid::Menu,
    BookmarkRootGuid::Toolbar,
    BookmarkRootGuid::Unfiled,
    BookmarkRootGuid::Mobile,
];

/// Special GUIDs associated with bookmark roots.
/// It's guaranteed that the roots will always have these guids.
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Hash)]
#[repr(u8)]
pub enum BookmarkRootGuid {
    Root,
    Menu,
    Toolbar,
    Unfiled,
    Mobile,
}

lazy_static! {
    static ref GUIDS: [(BookmarkRootGuid, SyncGuid); 5] = [
        (
            BookmarkRootGuid::Root,
            SyncGuid::from(BookmarkRootGuid::Root.as_str())
        ),
        (
            BookmarkRootGuid::Menu,
            SyncGuid::from(BookmarkRootGuid::Menu.as_str())
        ),
        (
            BookmarkRootGuid::Toolbar,
            SyncGuid::from(BookmarkRootGuid::Toolbar.as_str())
        ),
        (
            BookmarkRootGuid::Unfiled,
            SyncGuid::from(BookmarkRootGuid::Unfiled.as_str())
        ),
        (
            BookmarkRootGuid::Mobile,
            SyncGuid::from(BookmarkRootGuid::Mobile.as_str())
        ),
    ];
}

impl BookmarkRootGuid {
    pub fn as_str(self) -> &'static str {
        match self {
            BookmarkRootGuid::Root => "root________",
            BookmarkRootGuid::Menu => "menu________",
            BookmarkRootGuid::Toolbar => "toolbar_____",
            BookmarkRootGuid::Unfiled => "unfiled_____",
            BookmarkRootGuid::Mobile => "mobile______",
        }
    }

    pub fn guid(self) -> &'static SyncGuid {
        &GUIDS[self as usize].1
    }

    pub fn as_guid(self) -> SyncGuid {
        self.guid().clone()
    }

    pub fn well_known(guid: &str) -> Option<Self> {
        GUIDS
            .iter()
            .find(|(_, sync_guid)| sync_guid.as_str() == guid)
            .map(|(root, _)| *root)
    }

    pub fn from_guid(guid: &SyncGuid) -> Option<Self> {
        Self::well_known(guid.as_ref())
    }
}

impl From<BookmarkRootGuid> for SyncGuid {
    fn from(item: BookmarkRootGuid) -> SyncGuid {
        item.as_guid()
    }
}

// Allow comparisons between BookmarkRootGuid and SyncGuids
impl PartialEq<BookmarkRootGuid> for SyncGuid {
    fn eq(&self, other: &BookmarkRootGuid) -> bool {
        self.as_str().as_bytes() == other.as_str().as_bytes()
    }
}

impl PartialEq<SyncGuid> for BookmarkRootGuid {
    fn eq(&self, other: &SyncGuid) -> bool {
        other.as_str().as_bytes() == self.as_str().as_bytes()
    }
}

// Even if we have a reference to &SyncGuid
impl<'a> PartialEq<BookmarkRootGuid> for &'a SyncGuid {
    fn eq(&self, other: &BookmarkRootGuid) -> bool {
        self.as_str().as_bytes() == other.as_str().as_bytes()
    }
}

impl<'a> PartialEq<&'a SyncGuid> for BookmarkRootGuid {
    fn eq(&self, other: &&'a SyncGuid) -> bool {
        other.as_str().as_bytes() == self.as_str().as_bytes()
    }
}

// And between BookmarkRootGuid and &str
impl<'a> PartialEq<BookmarkRootGuid> for &'a str {
    fn eq(&self, other: &BookmarkRootGuid) -> bool {
        *self == other.as_str()
    }
}

impl<'a> PartialEq<&'a str> for BookmarkRootGuid {
    fn eq(&self, other: &&'a str) -> bool {
        self.as_str() == *other
    }
}
