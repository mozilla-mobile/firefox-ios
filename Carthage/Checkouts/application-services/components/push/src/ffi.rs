/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This module implement the traits that make the FFI code easier to manage.

use crate::msg_types;
use ffi_support::implement_into_ffi_by_protobuf;

implement_into_ffi_by_protobuf!(msg_types::DispatchInfo);
implement_into_ffi_by_protobuf!(msg_types::KeyInfo);
implement_into_ffi_by_protobuf!(msg_types::SubscriptionInfo);
implement_into_ffi_by_protobuf!(msg_types::SubscriptionResponse);
implement_into_ffi_by_protobuf!(msg_types::PushSubscriptionChanged);
implement_into_ffi_by_protobuf!(msg_types::PushSubscriptionsChanged);
