#![allow(unknown_lints)]
#![warn(rust_2018_idioms)]

use criterion::{criterion_group, criterion_main, Criterion};
use places::match_impl::{AutocompleteMatch, MatchBehavior, SearchBehavior};

fn bench_match_anywhere(c: &mut Criterion) {
    c.bench_function("match anywhere url", |b| {
        let matcher = AutocompleteMatch {
            search_str: "lication-servic",
            url_str: "https://github.com/mozilla/application-services/",
            title_str: "mozilla/application-services: Firefox Application Services",
            tags: "",
            visit_count: 100,
            typed: false,
            bookmarked: false,
            open_page_count: 0,
            match_behavior: MatchBehavior::Anywhere,
            search_behavior: SearchBehavior::default(),
        };
        b.iter(|| matcher.invoke())
    });
    c.bench_function("match anywhere title casecmp", |b| {
        let matcher = AutocompleteMatch {
            search_str: "notpresent services",
            url_str: "https://github.com/mozilla/application-services/",
            title_str: "mozilla/application-services: Firefox Application Services",
            tags: "",
            match_behavior: MatchBehavior::Anywhere,
            visit_count: 100,
            typed: false,
            bookmarked: false,
            open_page_count: 0,
            search_behavior: SearchBehavior::default(),
        };
        b.iter(|| matcher.invoke())
    });
}

criterion_group!(benches, bench_match_anywhere);
criterion_main!(benches);
