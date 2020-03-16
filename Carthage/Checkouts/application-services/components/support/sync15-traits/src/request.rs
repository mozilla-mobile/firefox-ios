/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
use crate::{Guid, ServerTimestamp};
use std::borrow::Cow;
use url::{form_urlencoded as form, Url, UrlQuery};
#[derive(Debug, Clone, PartialEq)]
pub struct CollectionRequest {
    pub collection: Cow<'static, str>,
    pub full: bool,
    pub ids: Option<Vec<Guid>>,
    pub limit: usize,
    pub older: Option<ServerTimestamp>,
    pub newer: Option<ServerTimestamp>,
    pub order: Option<RequestOrder>,
    pub commit: bool,
    pub batch: Option<String>,
}

impl CollectionRequest {
    #[inline]
    pub fn new<S>(collection: S) -> CollectionRequest
    where
        S: Into<Cow<'static, str>>,
    {
        CollectionRequest {
            collection: collection.into(),
            full: false,
            ids: None,
            limit: 0,
            older: None,
            newer: None,
            order: None,
            commit: false,
            batch: None,
        }
    }

    #[inline]
    pub fn ids<V>(mut self, v: V) -> CollectionRequest
    where
        V: IntoIterator,
        V::Item: Into<Guid>,
    {
        self.ids = Some(v.into_iter().map(|id| id.into()).collect());
        self
    }

    #[inline]
    pub fn full(mut self) -> CollectionRequest {
        self.full = true;
        self
    }

    #[inline]
    pub fn older_than(mut self, ts: ServerTimestamp) -> CollectionRequest {
        self.older = Some(ts);
        self
    }

    #[inline]
    pub fn newer_than(mut self, ts: ServerTimestamp) -> CollectionRequest {
        self.newer = Some(ts);
        self
    }

    #[inline]
    pub fn sort_by(mut self, order: RequestOrder) -> CollectionRequest {
        self.order = Some(order);
        self
    }

    #[inline]
    pub fn limit(mut self, num: usize) -> CollectionRequest {
        self.limit = num;
        self
    }

    #[inline]
    pub fn batch(mut self, batch: Option<String>) -> CollectionRequest {
        self.batch = batch;
        self
    }

    #[inline]
    pub fn commit(mut self, v: bool) -> CollectionRequest {
        self.commit = v;
        self
    }

    fn build_query(&self, pairs: &mut form::Serializer<'_, UrlQuery<'_>>) {
        if self.full {
            pairs.append_pair("full", "1");
        }
        if self.limit > 0 {
            pairs.append_pair("limit", &self.limit.to_string());
        }
        if let Some(ids) = &self.ids {
            // Most ids are 12 characters, and we comma separate them, so 13.
            let mut buf = String::with_capacity(ids.len() * 13);
            for (i, id) in ids.iter().enumerate() {
                if i > 0 {
                    buf.push(',');
                }
                buf.push_str(id.as_str());
            }
            pairs.append_pair("ids", &buf);
        }
        if let Some(batch) = &self.batch {
            pairs.append_pair("batch", &batch);
        }
        if self.commit {
            pairs.append_pair("commit", "true");
        }
        if let Some(ts) = self.older {
            pairs.append_pair("older", &ts.to_string());
        }
        if let Some(ts) = self.newer {
            pairs.append_pair("newer", &ts.to_string());
        }
        if let Some(o) = self.order {
            pairs.append_pair("sort", o.as_str());
        }
        pairs.finish();
    }

    pub fn build_url(&self, mut base_url: Url) -> Result<Url, UnacceptableBaseUrl> {
        base_url
            .path_segments_mut()
            .map_err(|_| UnacceptableBaseUrl(()))?
            .extend(&["storage", &self.collection]);
        self.build_query(&mut base_url.query_pairs_mut());
        // This is strange but just accessing query_pairs_mut makes you have
        // a trailing question mark on your url. I don't think anything bad
        // would happen here, but I don't know, and also, it looks dumb so
        // I'd rather not have it.
        if base_url.query() == Some("") {
            base_url.set_query(None);
        }
        Ok(base_url)
    }
}
#[derive(Debug)]
pub struct UnacceptableBaseUrl(());

impl std::fmt::Display for UnacceptableBaseUrl {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("Storage server URL is not a base")
    }
}
impl std::error::Error for UnacceptableBaseUrl {}

#[derive(Debug, Clone, Copy, Eq, PartialEq, Ord, PartialOrd, Hash)]
pub enum RequestOrder {
    Oldest,
    Newest,
    Index,
}

impl RequestOrder {
    #[inline]
    pub fn as_str(self) -> &'static str {
        match self {
            RequestOrder::Oldest => "oldest",
            RequestOrder::Newest => "newest",
            RequestOrder::Index => "index",
        }
    }
}

impl std::fmt::Display for RequestOrder {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}
