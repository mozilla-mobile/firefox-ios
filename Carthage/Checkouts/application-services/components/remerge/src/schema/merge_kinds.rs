/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum UntypedMerge {
    TakeNewest,
    PreferRemote,
    Duplicate,
    CompositeMember,
}

impl std::fmt::Display for UntypedMerge {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UntypedMerge::TakeNewest => f.write_str("take_newest"),
            UntypedMerge::PreferRemote => f.write_str("prefer_remote"),
            UntypedMerge::Duplicate => f.write_str("duplicate"),
            UntypedMerge::CompositeMember => f.write_str("<composite member>"),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum TextMerge {
    Untyped(UntypedMerge),
}

impl std::fmt::Display for TextMerge {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TextMerge::Untyped(u) => write!(f, "{}", u),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum TimestampMerge {
    Untyped(UntypedMerge),
    TakeMin,
    TakeMax,
}

impl std::fmt::Display for TimestampMerge {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TimestampMerge::Untyped(u) => write!(f, "{}", u),
            TimestampMerge::TakeMin => f.write_str("take_min"),
            TimestampMerge::TakeMax => f.write_str("take_max"),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum NumberMerge {
    Untyped(UntypedMerge),
    TakeMin,
    TakeMax,
    TakeSum,
}

impl std::fmt::Display for NumberMerge {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            NumberMerge::Untyped(u) => write!(f, "{}", u),
            NumberMerge::TakeMin => f.write_str("take_min"),
            NumberMerge::TakeMax => f.write_str("take_max"),
            NumberMerge::TakeSum => f.write_str("take_sum"),
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub enum BooleanMerge {
    Untyped(UntypedMerge),
    PreferFalse,
    PreferTrue,
}

impl std::fmt::Display for BooleanMerge {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BooleanMerge::Untyped(u) => write!(f, "{}", u),
            BooleanMerge::PreferFalse => f.write_str("prefer_false"),
            BooleanMerge::PreferTrue => f.write_str("prefer_true"),
        }
    }
}

// macro to remove boilerplate
macro_rules! merge_boilerplate {
    // base case.
    (@type [$MergeT:ident]) => {
    };

    // @common_methods: implement an common_methods method returning Option<UntypedMerge>
    (@type [$MergeT:ident] @common_methods $($tt:tt)*) => {
        impl $MergeT {
            pub fn as_untyped(&self) -> Option<UntypedMerge> {
                #[allow(unreachable_patterns)]
                match self {
                    $MergeT::Untyped(u) => Some(*u),
                    _ => None
                }
            }
            pub fn is_composite_member(&self) -> bool {
                self.as_untyped() == Some(UntypedMerge::CompositeMember)
            }
        }
        merge_boilerplate!(@type [$MergeT] $($tt)*);
    };

    // @from_untyped: impl From<Untyped> for $MergeT
    (@type [$MergeT:ident] @from_untyped $($tt:tt)+) => {
        impl From<UntypedMerge> for $MergeT {
            #[inline]
            fn from(u: UntypedMerge) -> Self {
                $MergeT::Untyped(u)
            }
        }
        merge_boilerplate!(@type [$MergeT] $($tt)+);
    };

    // @compare_untyped : implement PartialEq<UntypedMerge> automatically.
    (@type [$MergeT:ident] @compare_untyped $($tt:tt)*) => {
        impl PartialEq<UntypedMerge> for $MergeT {
            #[inline]
            fn eq(&self, o: &UntypedMerge) -> bool {
                #[allow(unreachable_patterns)]
                match self {
                    $MergeT::Untyped(u) => u == o,
                    _ => false,
                }
            }
        }
        impl PartialEq<$MergeT> for UntypedMerge {
            #[inline]
            fn eq(&self, o: &$MergeT) -> bool {
                o == self
            }
        }
        merge_boilerplate!(@type [$MergeT] $($tt)*);
    };

    // @compare_via_untyped [$T0, ...], implement PartialEq<$T0> for $MergeT, assuming
    // that $T0 and $MergeT only overlap in UntypedMerge impls.
    (@type [$MergeT:ident] @compare_via_untyped [$($T0:ident),* $(,)?] $($tt:tt)*) => {
        $(
            impl PartialEq<$T0> for $MergeT {
                fn eq(&self, o: &$T0) -> bool {
                    #[allow(unreachable_patterns)]
                    match (self, o) {
                        ($MergeT::Untyped(self_u), $T0::Untyped(t0_u)) => self_u == t0_u,
                        _ => false
                    }
                }
            }
            impl PartialEq<$MergeT> for $T0 {
                fn eq(&self, o: &$MergeT) -> bool {
                    PartialEq::eq(o, self)
                }
            }
        )*

        merge_boilerplate!(
            @type [$MergeT]
            $($tt)*
        );
    };

    // @compare_with [SomeTy { Enums, Vals, That, Are, The, Same }]
    (@type [$MergeT:ident] @compare_with [$T0:ident { $($Variant:ident),+ $(,)? }] $($tt:tt)*) => {
        impl PartialEq<$T0> for $MergeT {
            #[inline]
            fn eq(&self, o: &$T0) -> bool {
                #[allow(unreachable_patterns)]
                match (self, o) {
                    ($MergeT::Untyped(self_u), $T0::Untyped(t0_u)) => self_u == t0_u,
                    $(($MergeT::$Variant, $T0::$Variant) => true,)+
                    _ => false
                }
            }
        }

        impl PartialEq<$MergeT> for $T0 {
            #[inline]
            fn eq(&self, o: &$MergeT) -> bool {
                o == self
            }
        }

        merge_boilerplate!(@type [$MergeT] $($tt)*);
    };

    // @from [SomeEnum { Variants, That, Are, The, Same }]
    (@type [$MergeT:ident] @from [$T0:ident { $($Variant:ident),+ $(,)? }] $($tt:tt)*) => {
        impl From<$T0> for $MergeT {
            fn from(t: TimestampMerge) -> Self {
                match t {
                    $T0::Untyped(u) => $MergeT::Untyped(u),
                    $($T0::$Variant => $MergeT::$Variant,)+
                }
            }
        }
        merge_boilerplate!(@type [$MergeT] $($tt)*);
    }
}

merge_boilerplate!(
    @type [BooleanMerge]
    @from_untyped
    @common_methods
    @compare_untyped
    @compare_via_untyped [NumberMerge, TextMerge, TimestampMerge]
);

merge_boilerplate!(
    @type [TextMerge]
    @from_untyped
    @common_methods
    @compare_untyped
    @compare_via_untyped [NumberMerge, TimestampMerge]
);

merge_boilerplate!(
    @type [NumberMerge]
    @from_untyped
    @common_methods
    @compare_untyped
    @compare_via_untyped []
    @compare_with [TimestampMerge { TakeMax, TakeMin }]
    @from [TimestampMerge { TakeMax, TakeMin }]
);

merge_boilerplate!(
    @type [TimestampMerge]
    @from_untyped
    @common_methods
    @compare_untyped
);
