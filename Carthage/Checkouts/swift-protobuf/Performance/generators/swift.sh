#!/bin/bash

# SwiftProtobuf/Performance/generators/swift.sh - Swift test harness generator
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
# Functions for generating the Swift harness.
#
# -----------------------------------------------------------------------------

function print_swift_set_field() {
  num=$1
  type=$2

  case "$type" in
    repeated\ message)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append(SubMessage.with { \$0.optionalInt32 = $((200+num)) })"
      echo "    }"
      ;;
    repeated\ bytes)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append(Data(repeating:$((num)), count: 20))"
      echo "    }"
      ;;
    repeated\ bool)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append(true)"
      echo "    }"
      ;;
    repeated\ string)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append(\"$((200+num))\")"
      echo "    }"
      ;;
    repeated\ enum)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append(.foo)"
      echo "    }"
      ;;
    repeated\ float)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append($((200+num)).$((200+num)))"
      echo "    }"
      ;;
    repeated\ double)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append($((200+num)).$((200+num)))"
      echo "    }"
      ;;
    repeated\ *)
      echo "    for _ in 0..<repeatedCount {"
      echo "      message.field$num.append($((200+num)))"
      echo "    }"
      ;;
    message)
      echo "    message.field$num = SubMessage.with { \$0.optionalInt32 = $((200+num)) }"
      ;;
    bytes)
      echo "    message.field$num = Data(repeating:$((num)), count: 20)"
      ;;
    bool)
      echo "    message.field$num = true"
      ;;
    string)
      echo "    message.field$num = \"$((200+num))\""
      ;;
    enum)
      echo "    message.field$num = .foo"
      ;;
    float)
      echo "    message.field$num = $((200+num)).$((200+num))"
      ;;
    double)
      echo "    message.field$num = $((200+num)).$((200+num))"
      ;;
    *)
      echo "    message.field$num = $((200+num))"
      ;;
  esac
}

function generate_swift_harness() {
  cat >"$gen_harness_path" <<EOF
import Foundation

extension Harness {
  var runCount: Int { return $run_count }

  func run() {
    measure {
      _ = measureSubtask("New message") {
        return PerfMessage()
      }

      var message = PerfMessage()
      measureSubtask("Populate fields") {
        populateFields(of: &message)
      }

      message = measureSubtask("Populate fields with with") {
        return populateFieldsWithWith()
      }

      // Exercise binary serialization.
      let data = try measureSubtask("Encode binary") {
        return try message.serializedData()
      }
      let message2 = try measureSubtask("Decode binary") {
        return try PerfMessage(serializedData: data)
      }

      // Exercise JSON serialization.
      let json = try measureSubtask("Encode JSON") {
        return try message.jsonUTF8Data()
      }
      _ = try measureSubtask("Decode JSON") {
        return try PerfMessage(jsonUTF8Data: json)
      }

      // Exercise text serialization.
      let text = measureSubtask("Encode text") {
        return message.textFormatString()
      }
      _ = try measureSubtask("Decode text") {
        return try PerfMessage(textFormatString: text)
      }

      // Exercise equality.
      _ = measureSubtask("Equality") {
        return message == message2
      }
    }
  }

  private func populateFields(of message: inout PerfMessage) {
EOF

  if [[ "$proto_type" == "homogeneous" ]]; then
    generate_swift_homogenerous_populate_fields_body
  else
    generate_swift_heterogenerous_populate_fields_body
  fi

  cat >> "$gen_harness_path" <<EOF
  }

  private func populateFieldsWithWith() -> PerfMessage {
    return PerfMessage.with { message in
EOF

  if [[ "$proto_type" == "homogeneous" ]]; then
    generate_swift_homogenerous_populate_fields_body
  else
    generate_swift_heterogenerous_populate_fields_body
  fi

  cat >> "$gen_harness_path" <<EOF
    }
  }
}
EOF
}

function generate_swift_homogenerous_populate_fields_body() {
  for field_number in $(seq 1 "$field_count"); do
    print_swift_set_field "$field_number" "$field_type" >>"$gen_harness_path"
  done
}

function generate_swift_heterogenerous_populate_fields_body() {
  cat >> "$gen_harness_path" <<EOF
    message.optionalInt32 = 1
    message.optionalInt64 = 2
    message.optionalUint32 = 3
    message.optionalUint64 = 4
    message.optionalSint32 = 5
    message.optionalSint64 = 6
    message.optionalFixed32 = 7
    message.optionalFixed64 = 8
    message.optionalSfixed32 = 9
    message.optionalSfixed64 = 10
    message.optionalFloat = 11
    message.optionalDouble = 12
    message.optionalBool = true
    message.optionalString = "14"
    message.optionalBytes = Data(repeating: 15, count: 20)
    message.optionalEnum = .foo

EOF

  if [[ "$proto_syntax" == "2" ]]; then
    cat >>"$gen_harness_path" <<EOF
    message.optionalGroup.optionalGroupInt32 = 101
    message.optionalGroup.optionalGroupInt64 = 102
    message.optionalGroup.optionalGroupUint32 = 103
    message.optionalGroup.optionalGroupUint64 = 104
    message.optionalGroup.optionalGroupSint32 = 105
    message.optionalGroup.optionalGroupSint64 = 106
    message.optionalGroup.optionalGroupFixed32 = 107
    message.optionalGroup.optionalGroupFixed64 = 108
    message.optionalGroup.optionalGroupSfixed32 = 109
    message.optionalGroup.optionalGroupSfixed64 = 110
    message.optionalGroup.optionalGroupFloat = 111
    message.optionalGroup.optionalGroupDouble = 112
    message.optionalGroup.optionalGroupBool = true
    message.optionalGroup.optionalGroupString = "114"
    message.optionalGroup.optionalGroupBytes = Data(repeating: 115, count: 20)
    message.optionalGroup.optionalGroupEnum = .foo
EOF
fi

  cat >>"$gen_harness_path" <<EOF
    for _ in 0..<repeatedCount {
      message.repeatedInt32.append(201)
      message.repeatedInt64.append(202)
      message.repeatedUint32.append(203)
      message.repeatedUint64.append(204)
      message.repeatedSint32.append(205)
      message.repeatedSint64.append(206)
      message.repeatedFixed32.append(207)
      message.repeatedFixed64.append(208)
      message.repeatedSfixed32.append(209)
      message.repeatedSfixed64.append(210)
      message.repeatedFloat.append(211)
      message.repeatedDouble.append(212)
      message.repeatedBool.append(true)
      message.repeatedString.append("214")
      message.repeatedBytes.append(Data(repeating: 215, count: 20))
      message.repeatedEnum.append(.foo)
    }

    // Instead of writing a ton of code that populates the nested messages,
    // just do some bulk assignments from a snapshot of the message we just
    // populated.
    let snapshot = message
    message.optionalMessage = snapshot
EOF

  if [[ "$proto_syntax" == "2" ]]; then
    cat >>"$gen_harness_path" <<EOF
    message.optionalGroup.optionalGroupMessage = snapshot
EOF
fi

  cat >>"$gen_harness_path" <<EOF
    for _ in 0..<repeatedCount {
      message.repeatedMessage.append(snapshot)
    }
EOF
}
