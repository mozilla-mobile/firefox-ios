#!/bin/bash

# SwiftProtobuf/Performance/generators/proto.sh - Test proto generator
#
# This source file is part of the Swift.org open source project
#
# Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See http://swift.org/LICENSE.txt for license information
# See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
#
# -----------------------------------------------------------------------------
#
# Functions for generating the test proto.
#
# -----------------------------------------------------------------------------

function print_proto_field() {
  num="$1"
  _type=`echo $2 | sed -e 's/enum/PerfEnum/'`

  if [[ "$proto_syntax" == "2" ]] && [[ "$field_type" != repeated* ]]; then
    type="optional $_type"
  else
    type="$_type"
  fi

  if [[ -n "$packed" ]]; then
    echo "  $type field$num = $num [packed=$packed];"
  else
    echo "  $type field$num = $num;"
  fi
}

# Generates a test proto with multiple fields of a single type.
function generate_homogeneous_test_proto() {
  cat >"$gen_message_path" <<EOF
syntax = "proto$proto_syntax";
EOF

  case "$field_type" in
      *message)
	  case "$field_type" in
	      repeated\ message)
		  out_field_type="repeated SubMessage"
		  ;;
	      message)
		  out_field_type="SubMessage"
		  ;;
	      *)
		  echo "XXX Invalid field type ``$field_type''"
		  ;;
	  esac
	  echo "message SubMessage {" >>"$gen_message_path"
	  echo "  int32 optional_int32 = 1;" >>"$gen_message_path"
	  echo "}" >>"$gen_message_path"
	  ;;
      *)
	  out_field_type="$field_type"
	  ;;
  esac

  cat >>"$gen_message_path" <<EOF
message PerfMessage {
  enum PerfEnum {
    ZERO = 0;
    FOO = 1;
    BAR = 2;
    BAZ = 3;
    NEG = -1;
  }
EOF

  for field_number in $(seq 1 "$field_count"); do
    print_proto_field "$field_number" "$out_field_type" >>"$gen_message_path"
  done

  cat >>"$gen_message_path" <<EOF
}
EOF
}

# Generates a test proto with multiple field types.
function generate_heterogeneous_test_proto() {
  if [[ "$proto_syntax" == "2" ]]; then
    optional="optional "
  else
    optional=""
  fi

  cat >"$gen_message_path" <<EOF
syntax = "proto$proto_syntax";

message PerfMessage {
  enum PerfEnum {
    ZERO = 0;
    FOO = 1;
    BAR = 2;
    BAZ = 3;
    NEG = -1;
  }

  // Singular
  $optional    int32 optional_int32    =  1;
  $optional    int64 optional_int64    =  2;
  $optional   uint32 optional_uint32   =  3;
  $optional   uint64 optional_uint64   =  4;
  $optional   sint32 optional_sint32   =  5;
  $optional   sint64 optional_sint64   =  6;
  $optional  fixed32 optional_fixed32  =  7;
  $optional  fixed64 optional_fixed64  =  8;
  $optional sfixed32 optional_sfixed32 =  9;
  $optional sfixed64 optional_sfixed64 = 10;
  $optional    float optional_float    = 11;
  $optional   double optional_double   = 12;
  $optional     bool optional_bool     = 13;
  $optional   string optional_string   = 14;
  $optional    bytes optional_bytes    = 15;
  $optional    PerfEnum optional_enum  = 16;
  $optional PerfMessage optional_message = 17;
EOF

  if [[ "$proto_syntax" == "2" ]]; then
    cat >>"$gen_message_path" <<EOF
  $optional group OptionalGroup = 100 {
    $optional    int32 optional_group_int32    = 101;
    $optional    int64 optional_group_int64    = 102;
    $optional   uint32 optional_group_uint32   = 103;
    $optional   uint64 optional_group_uint64   = 104;
    $optional   sint32 optional_group_sint32   = 105;
    $optional   sint64 optional_group_sint64   = 106;
    $optional  fixed32 optional_group_fixed32  = 107;
    $optional  fixed64 optional_group_fixed64  = 108;
    $optional sfixed32 optional_group_sfixed32 = 109;
    $optional sfixed64 optional_group_sfixed64 = 110;
    $optional    float optional_group_float    = 111;
    $optional   double optional_group_double   = 112;
    $optional     bool optional_group_bool     = 113;
    $optional   string optional_group_string   = 114;
    $optional    bytes optional_group_bytes    = 115;
    $optional PerfEnum optional_group_enum     = 116;
    $optional PerfMessage optional_group_message = 117;
  }
EOF
fi

  cat >>"$gen_message_path" <<EOF
  // Repeated
  repeated    int32 repeated_int32    = 201 [packed=${packed:-false}];
  repeated    int64 repeated_int64    = 202 [packed=${packed:-false}];
  repeated   uint32 repeated_uint32   = 203 [packed=${packed:-false}];
  repeated   uint64 repeated_uint64   = 204 [packed=${packed:-false}];
  repeated   sint32 repeated_sint32   = 205 [packed=${packed:-false}];
  repeated   sint64 repeated_sint64   = 206 [packed=${packed:-false}];
  repeated  fixed32 repeated_fixed32  = 207 [packed=${packed:-false}];
  repeated  fixed64 repeated_fixed64  = 208 [packed=${packed:-false}];
  repeated sfixed32 repeated_sfixed32 = 209 [packed=${packed:-false}];
  repeated sfixed64 repeated_sfixed64 = 210 [packed=${packed:-false}];
  repeated    float repeated_float    = 211 [packed=${packed:-false}];
  repeated   double repeated_double   = 212 [packed=${packed:-false}];
  repeated     bool repeated_bool     = 213 [packed=${packed:-false}];
  repeated   string repeated_string   = 214 [packed=${packed:-false}];
  repeated    bytes repeated_bytes    = 215 [packed=${packed:-false}];
  repeated PerfMessage repeated_message = 216 [packed=${packed:-false}];
  repeated    PerfEnum repeated_enum    = 217 [packed=${packed:-false}];

  oneof oneof_field {
    uint32 oneof_uint32 = 401;
    PerfMessage oneof_message = 402;
    string oneof_string = 403;
    bytes oneof_bytes = 404;
  }
}
EOF
}
