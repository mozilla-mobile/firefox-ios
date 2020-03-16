#!/bin/bash

# SwiftProtobuf/Performance/generators/cpp.sh - C++ test harness generator
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
# -----------------------------------------------------------------------------
#
# Functions for generating the C++ harness.
#
# -----------------------------------------------------------------------------

function print_cpp_set_field() {
  num=$1
  type=$2

  case "$type" in
    repeated\ message)
      echo "  for (auto i = 0; i < repeated_count; i++) {"
      echo "    message.add_field$num()->set_optional_int32($((200+num)));"
      echo "  }"
      ;;
    repeated\ string)
      echo "  for (auto i = 0; i < repeated_count; i++) {"
      echo "    message.add_field$num(\"$((200+num))\");"
      echo "  }"
      ;;
    repeated\ bytes)
      echo "  for (auto i = 0; i < repeated_count; i++) {"
      echo "    message.add_field$num(std::string(20, (char)$((num))));"
      echo "  }"
      ;;
    repeated\ enum)
      echo "  for (auto i = 0; i < repeated_count; i++) {"
      echo "    message.add_field$num(PerfMessage::FOO);"
      echo "  }"
      ;;
    repeated\ float)
      echo "  for (auto i = 0; i < repeated_count; i++) {"
      echo "    message.add_field$num($((200+num)).$((200+num)));"
      echo "  }"
      ;;
    repeated\ double)
      echo "  for (auto i = 0; i < repeated_count; i++) {"
      echo "    message.add_field$num($((200+num)).$((200+num)));"
      echo "  }"
      ;;
    repeated\ *)
      echo "  for (auto i = 0; i < repeated_count; i++) {"
      echo "    message.add_field$num($((200+num)));"
      echo "  }"
      ;;
    message)
      echo "  message.mutable_field$num()->set_optional_int32($((200+num)));"
      ;;
    string)
      echo "  message.set_field$num(\"$((200+num))\");"
      ;;
    bytes)
      echo "  message.set_field$num(std::string(20, (char)$((num))));"
      ;;
    enum)
      echo "  message.set_field$num(PerfMessage::FOO);"
      ;;
    float)
      echo "  message.set_field$num($((200+num)).$((200+num)));"
      ;;
    double)
      echo "  message.set_field$num($((200+num)).$((200+num)));"
      ;;
    *)
      echo "  message.set_field$num($((200+num)));"
      ;;
  esac
}

function generate_cpp_harness() {
  cat >"$gen_harness_path" <<EOF
#include "Harness.h"
#include "message.pb.h"

#include <iostream>
#include <google/protobuf/text_format.h>
#include <google/protobuf/util/json_util.h>
#include <google/protobuf/util/message_differencer.h>
#include <google/protobuf/util/type_resolver_util.h>

using google::protobuf::Descriptor;
using google::protobuf::DescriptorPool;
using google::protobuf::TextFormat;
using google::protobuf::util::BinaryToJsonString;
using google::protobuf::util::JsonToBinaryString;
using google::protobuf::util::MessageDifferencer;
using google::protobuf::util::NewTypeResolverForDescriptorPool;
using google::protobuf::util::Status;
using google::protobuf::util::TypeResolver;
using std::cerr;
using std::endl;
using std::string;

static const char kTypeUrlPrefix[] = "type.googleapis.com";

static string GetTypeUrl(const Descriptor* message) {
  return string(kTypeUrlPrefix) + "/" + message->full_name();
}

TypeResolver* type_resolver;
string* type_url;

static void populate_fields(PerfMessage& message, int repeated_count);

void Harness::run() {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

  type_resolver = NewTypeResolverForDescriptorPool(
      kTypeUrlPrefix, DescriptorPool::generated_pool());
  type_url = new string(GetTypeUrl(PerfMessage::descriptor()));

  measure([&]() {
      measure_subtask("New message", [&]() {
        return PerfMessage();
      });

      auto message = PerfMessage();

      measure_subtask("Populate fields", [&]() {
        populate_fields(message, repeated_count);
        // Dummy return value since void won't propagate.
        return false;
      });

      // Exercise binary serialization.
      auto data = measure_subtask("Encode binary", [&]() {
        return message.SerializeAsString();
      });
      auto decoded_message = measure_subtask("Decode binary", [&]() {
        auto result = PerfMessage();
        result.ParseFromString(data);
        return result;
      });

      // Exercise JSON serialization.
      auto json = measure_subtask("Encode JSON", [&]() {
        string out_json;
        BinaryToJsonString(type_resolver, *type_url, data, &out_json);
        return out_json;
      });
      auto decoded_binary = measure_subtask("Decode JSON", [&]() {
        string out_binary;
        JsonToBinaryString(type_resolver, *type_url, json, &out_binary);
        return out_binary;
      });

      // Exercise text serialization.
      auto text = measure_subtask("Encode text", [&]() {
        string out_text;
        TextFormat::PrintToString(message, &out_text);
        return out_text;
      });
      measure_subtask("Decode text", [&]() {
        auto result = PerfMessage();
        TextFormat::ParseFromString(text, &result);
        return result;
      });

      // Exercise equality.
      measure_subtask("Equality", [&]() {
        return MessageDifferencer::Equals(message, decoded_message);
      });
  });

  google::protobuf::ShutdownProtobufLibrary();
}

void populate_fields(PerfMessage& message, int repeated_count) {
  (void)repeated_count; /* Possibly unused: Quiet the compiler */

EOF

  if [[ "$proto_type" == "homogeneous" ]]; then
    generate_cpp_homogenerous_populate_fields_body
  else
    generate_cpp_heterogenerous_populate_fields_body
  fi

  cat >> "$gen_harness_path" <<EOF
}

int Harness::run_count() const {
  return ${run_count};
}
EOF
}

function generate_cpp_homogenerous_populate_fields_body() {
  for field_number in $(seq 1 "$field_count"); do
    print_cpp_set_field "$field_number" "$field_type" >>"$gen_harness_path"
  done
}

function generate_cpp_heterogenerous_populate_fields_body() {
  cat >> "$gen_harness_path" <<EOF
  message.set_optional_int32(1);
  message.set_optional_int64(2);
  message.set_optional_uint32(3);
  message.set_optional_uint64(4);
  message.set_optional_sint32(5);
  message.set_optional_sint64(6);
  message.set_optional_fixed32(7);
  message.set_optional_fixed64(8);
  message.set_optional_sfixed32(9);
  message.set_optional_sfixed64(10);
  message.set_optional_float(11);
  message.set_optional_double(12);
  message.set_optional_bool(true);
  message.set_optional_string("14");
  message.set_optional_bytes(std::string(20, (char)15));
  message.set_optional_enum(PerfMessage::FOO);

EOF

  if [[ "$proto_syntax" == "2" ]]; then
    cat >>"$gen_harness_path" <<EOF
  message.mutable_optionalgroup()->set_optional_group_int32(101);
  message.mutable_optionalgroup()->set_optional_group_int64(102);
  message.mutable_optionalgroup()->set_optional_group_uint32(103);
  message.mutable_optionalgroup()->set_optional_group_uint64(104);
  message.mutable_optionalgroup()->set_optional_group_sint32(105);
  message.mutable_optionalgroup()->set_optional_group_sint64(106);
  message.mutable_optionalgroup()->set_optional_group_fixed32(107);
  message.mutable_optionalgroup()->set_optional_group_fixed64(108);
  message.mutable_optionalgroup()->set_optional_group_sfixed32(109);
  message.mutable_optionalgroup()->set_optional_group_sfixed64(110);
  message.mutable_optionalgroup()->set_optional_group_float(111);
  message.mutable_optionalgroup()->set_optional_group_double(112);
  message.mutable_optionalgroup()->set_optional_group_bool(true);
  message.mutable_optionalgroup()->set_optional_group_string("114");
  message.mutable_optionalgroup()->set_optional_group_bytes(std::string(20, (char)115));
  message.mutable_optionalgroup()->set_optional_group_enum(PerfMessage::FOO);

EOF
fi

  cat >>"$gen_harness_path" <<EOF
  for (auto i = 0; i < repeated_count; i++) {
    message.add_repeated_int32(201);
    message.add_repeated_int64(202);
    message.add_repeated_uint32(203);
    message.add_repeated_uint64(204);
    message.add_repeated_sint32(205);
    message.add_repeated_sint64(206);
    message.add_repeated_fixed32(207);
    message.add_repeated_fixed64(208);
    message.add_repeated_sfixed32(209);
    message.add_repeated_sfixed64(210);
    message.add_repeated_float(211);
    message.add_repeated_double(212);
    message.add_repeated_bool(true);
    message.add_repeated_string("214");
    message.add_repeated_bytes(std::string(20, (char)215));
    message.add_repeated_enum(PerfMessage::FOO);
  }

  // Instead of writing a ton of code that populates the nested messages,
  // just do some bulk assignments from a snapshot of the message we just
  // populated.
  auto snapshot = message;
  *(message.mutable_optional_message()) = snapshot;
EOF

  if [[ "$proto_syntax" == "2" ]]; then
    cat >>"$gen_harness_path" <<EOF
  *(message.mutable_optionalgroup()->mutable_optional_group_message()) = snapshot;
EOF
fi
  
  cat >>"$gen_harness_path" <<EOF
  for (auto i = 0; i < repeated_count; i++) {
    auto element = message.add_repeated_message();
    *element = snapshot;
  }
EOF
}
