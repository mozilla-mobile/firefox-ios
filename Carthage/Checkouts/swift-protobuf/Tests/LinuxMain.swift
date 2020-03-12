//
// GENERATED FILE
// DO NOT EDIT
//

import XCTest
@testable import SwiftProtobufTests
@testable import SwiftProtobufPluginLibraryTests


extension Test_Descriptor {
    static var allTests = [
        ("testParsing", testParsing),
        ("testLookup", testLookup),
        ("testParents", testParents),
        ("testFields", testFields),
        ("testExtensions", testExtensions)
    ]
}

extension Test_NamingUtils {
    static var allTests = [
        ("testTypePrefix", testTypePrefix),
        ("testPrefixStripper_strip", testPrefixStripper_strip),
        ("testSanitize_messageName", testSanitize_messageName),
        ("testSanitize_enumName", testSanitize_enumName),
        ("testSanitize_oneofName", testSanitize_oneofName),
        ("testSanitize_fieldName", testSanitize_fieldName),
        ("testSanitize_enumCaseName", testSanitize_enumCaseName),
        ("testSanitize_messageScopedExtensionName", testSanitize_messageScopedExtensionName),
        ("testToCamelCase", testToCamelCase)
    ]
}

extension Test_ProtoFileToModuleMappings {
    static var allTests = [
        ("test_Initialization", test_Initialization),
        ("test_Initialization_InvalidConfigs", test_Initialization_InvalidConfigs),
        ("test_moduleName_forFile", test_moduleName_forFile),
        ("test_neededModules_forFile", test_neededModules_forFile),
        ("test_neededModules_forFile_PublicImports", test_neededModules_forFile_PublicImports)
    ]
}

extension Test_SwiftLanguage {
    static var allTests = [
        ("testIsValidSwiftIdentifier", testIsValidSwiftIdentifier),
        ("testIsNotValidSwiftIdentifier", testIsNotValidSwiftIdentifier)
    ]
}

extension Test_SwiftProtobufNamer {
    static var allTests = [
        ("testEnumValueHandling_AliasNameMatches", testEnumValueHandling_AliasNameMatches),
        ("testEnumValueHandling_NameCollisions", testEnumValueHandling_NameCollisions),
        ("testEnumValueHandling_NameCollisionsAndAliasMatches", testEnumValueHandling_NameCollisionsAndAliasMatches),
        ("testEnumValueHandling_UniqueAliasNameCollisions", testEnumValueHandling_UniqueAliasNameCollisions)
    ]
}

extension Test_AllTypes {
    static var allTests = [
        ("testEncoding_unknown", testEncoding_unknown),
        ("testEncoding_optionalInt32", testEncoding_optionalInt32),
        ("testEncoding_optionalInt64", testEncoding_optionalInt64),
        ("testEncoding_optionalUint32", testEncoding_optionalUint32),
        ("testEncoding_optionalUint64", testEncoding_optionalUint64),
        ("testEncoding_optionalSint32", testEncoding_optionalSint32),
        ("testEncoding_optionalSint64", testEncoding_optionalSint64),
        ("testEncoding_optionalFixed32", testEncoding_optionalFixed32),
        ("testEncoding_optionalFixed64", testEncoding_optionalFixed64),
        ("testEncoding_optionalSfixed32", testEncoding_optionalSfixed32),
        ("testEncoding_optionalSfixed64", testEncoding_optionalSfixed64),
        ("testEncoding_optionalFloat", testEncoding_optionalFloat),
        ("testEncoding_optionalDouble", testEncoding_optionalDouble),
        ("testEncoding_optionalBool", testEncoding_optionalBool),
        ("testEncoding_optionalString", testEncoding_optionalString),
        ("testEncoding_optionalGroup", testEncoding_optionalGroup),
        ("testEncoding_optionalBytes", testEncoding_optionalBytes),
        ("testEncoding_optionalNestedMessage", testEncoding_optionalNestedMessage),
        ("testEncoding_optionalNestedMessage_unknown1", testEncoding_optionalNestedMessage_unknown1),
        ("testEncoding_optionalNestedMessage_unknown2", testEncoding_optionalNestedMessage_unknown2),
        ("testEncoding_optionalNestedMessage_unknown3", testEncoding_optionalNestedMessage_unknown3),
        ("testEncoding_optionalNestedMessage_unknown4", testEncoding_optionalNestedMessage_unknown4),
        ("testEncoding_optionalForeignMessage", testEncoding_optionalForeignMessage),
        ("testEncoding_optionalImportMessage", testEncoding_optionalImportMessage),
        ("testEncoding_optionalNestedEnum", testEncoding_optionalNestedEnum),
        ("testEncoding_optionalForeignEnum", testEncoding_optionalForeignEnum),
        ("testEncoding_optionalImportEnum", testEncoding_optionalImportEnum),
        ("testEncoding_optionalStringPiece", testEncoding_optionalStringPiece),
        ("testEncoding_optionalCord", testEncoding_optionalCord),
        ("testEncoding_optionalPublicImportMessage", testEncoding_optionalPublicImportMessage),
        ("testEncoding_optionalLazyMessage", testEncoding_optionalLazyMessage),
        ("testEncoding_repeatedInt32", testEncoding_repeatedInt32),
        ("testEncoding_repeatedInt64", testEncoding_repeatedInt64),
        ("testEncoding_repeatedUint32", testEncoding_repeatedUint32),
        ("testEncoding_repeatedUint64", testEncoding_repeatedUint64),
        ("testEncoding_repeatedSint32", testEncoding_repeatedSint32),
        ("testEncoding_repeatedSint64", testEncoding_repeatedSint64),
        ("testEncoding_repeatedFixed32", testEncoding_repeatedFixed32),
        ("testEncoding_repeatedFixed64", testEncoding_repeatedFixed64),
        ("testEncoding_repeatedSfixed32", testEncoding_repeatedSfixed32),
        ("testEncoding_repeatedSfixed64", testEncoding_repeatedSfixed64),
        ("testEncoding_repeatedFloat", testEncoding_repeatedFloat),
        ("testEncoding_repeatedDouble", testEncoding_repeatedDouble),
        ("testEncoding_repeatedBool", testEncoding_repeatedBool),
        ("testEncoding_repeatedString", testEncoding_repeatedString),
        ("testEncoding_repeatedBytes", testEncoding_repeatedBytes),
        ("testEncoding_repeatedGroup", testEncoding_repeatedGroup),
        ("testEncoding_repeatedNestedMessage", testEncoding_repeatedNestedMessage),
        ("testEncoding_repeatedNestedMessage_unknown", testEncoding_repeatedNestedMessage_unknown),
        ("testEncoding_repeatedNestedEnum", testEncoding_repeatedNestedEnum),
        ("testEncoding_defaultInt32", testEncoding_defaultInt32),
        ("testEncoding_defaultInt64", testEncoding_defaultInt64),
        ("testEncoding_defaultUint32", testEncoding_defaultUint32),
        ("testEncoding_defaultUint64", testEncoding_defaultUint64),
        ("testEncoding_defaultSint32", testEncoding_defaultSint32),
        ("testEncoding_defaultSint64", testEncoding_defaultSint64),
        ("testEncoding_defaultFixed32", testEncoding_defaultFixed32),
        ("testEncoding_defaultFixed64", testEncoding_defaultFixed64),
        ("testEncoding_defaultSfixed32", testEncoding_defaultSfixed32),
        ("testEncoding_defaultSfixed64", testEncoding_defaultSfixed64),
        ("testEncoding_defaultFloat", testEncoding_defaultFloat),
        ("testEncoding_defaultDouble", testEncoding_defaultDouble),
        ("testEncoding_defaultBool", testEncoding_defaultBool),
        ("testEncoding_defaultString", testEncoding_defaultString),
        ("testEncoding_defaultBytes", testEncoding_defaultBytes),
        ("testEncoding_defaultNestedEnum", testEncoding_defaultNestedEnum),
        ("testEncoding_defaultForeignEnum", testEncoding_defaultForeignEnum),
        ("testEncoding_defaultImportEnum", testEncoding_defaultImportEnum),
        ("testEncoding_defaultStringPiece", testEncoding_defaultStringPiece),
        ("testEncoding_defaultCord", testEncoding_defaultCord),
        ("testEncoding_oneofUint32", testEncoding_oneofUint32),
        ("testEncoding_oneofNestedMessage", testEncoding_oneofNestedMessage),
        ("testEncoding_oneofNestedMessage1", testEncoding_oneofNestedMessage1),
        ("testEncoding_oneofNestedMessage2", testEncoding_oneofNestedMessage2),
        ("testEncoding_oneofNestedMessage9", testEncoding_oneofNestedMessage9),
        ("testEncoding_oneofString", testEncoding_oneofString),
        ("testEncoding_oneofBytes", testEncoding_oneofBytes),
        ("testEncoding_oneofBytes2", testEncoding_oneofBytes2),
        ("testEncoding_oneofBytes3", testEncoding_oneofBytes3),
        ("testEncoding_oneofBytes4", testEncoding_oneofBytes4),
        ("testEncoding_oneofBytes5", testEncoding_oneofBytes5),
        ("testEncoding_oneofBytes_failures", testEncoding_oneofBytes_failures),
        ("testEncoding_oneofBytes_debugDescription", testEncoding_oneofBytes_debugDescription),
        ("testDebugDescription", testDebugDescription),
        ("testDebugDescription2", testDebugDescription2),
        ("testDebugDescription3", testDebugDescription3),
        ("testDebugDescription4", testDebugDescription4),
        ("testWithFactoryHelper", testWithFactoryHelper),
        ("testWithFactoryHelperRethrows", testWithFactoryHelperRethrows),
        ("testUnknownFields_Success", testUnknownFields_Success),
        ("testUnknownFields_Failures", testUnknownFields_Failures)
    ]
}

extension Test_AllTypes_Proto3 {
    static var allTests = [
        ("testEncoding_optionalInt32", testEncoding_optionalInt32),
        ("testEncoding_optionalInt64", testEncoding_optionalInt64),
        ("testEncoding_optionalUint32", testEncoding_optionalUint32),
        ("testEncoding_optionalUint64", testEncoding_optionalUint64),
        ("testEncoding_optionalSint32", testEncoding_optionalSint32),
        ("testEncoding_optionalSint64", testEncoding_optionalSint64),
        ("testEncoding_optionalFixed32", testEncoding_optionalFixed32),
        ("testEncoding_optionalFixed64", testEncoding_optionalFixed64),
        ("testEncoding_optionalSfixed32", testEncoding_optionalSfixed32),
        ("testEncoding_optionalSfixed64", testEncoding_optionalSfixed64),
        ("testEncoding_optionalFloat", testEncoding_optionalFloat),
        ("testEncoding_optionalDouble", testEncoding_optionalDouble),
        ("testEncoding_optionalBool", testEncoding_optionalBool),
        ("testEncoding_optionalString", testEncoding_optionalString),
        ("testEncoding_optionalBytes", testEncoding_optionalBytes),
        ("testEncoding_optionalNestedMessage", testEncoding_optionalNestedMessage),
        ("testEncoding_optionalForeignMessage", testEncoding_optionalForeignMessage),
        ("testEncoding_optionalImportMessage", testEncoding_optionalImportMessage),
        ("testEncoding_optionalNestedEnum", testEncoding_optionalNestedEnum),
        ("testEncoding_optionalForeignEnum", testEncoding_optionalForeignEnum),
        ("testEncoding_repeatedInt32", testEncoding_repeatedInt32),
        ("testEncoding_repeatedInt64", testEncoding_repeatedInt64),
        ("testEncoding_repeatedUint32", testEncoding_repeatedUint32),
        ("testEncoding_repeatedUint64", testEncoding_repeatedUint64),
        ("testEncoding_repeatedSint32", testEncoding_repeatedSint32),
        ("testEncoding_repeatedSint64", testEncoding_repeatedSint64),
        ("testEncoding_repeatedFixed32", testEncoding_repeatedFixed32),
        ("testEncoding_repeatedFixed64", testEncoding_repeatedFixed64),
        ("testEncoding_repeatedSfixed32", testEncoding_repeatedSfixed32),
        ("testEncoding_repeatedSfixed64", testEncoding_repeatedSfixed64),
        ("testEncoding_repeatedFloat", testEncoding_repeatedFloat),
        ("testEncoding_repeatedDouble", testEncoding_repeatedDouble),
        ("testEncoding_repeatedBool", testEncoding_repeatedBool),
        ("testEncoding_repeatedString", testEncoding_repeatedString),
        ("testEncoding_repeatedBytes", testEncoding_repeatedBytes),
        ("testEncoding_repeatedNestedMessage", testEncoding_repeatedNestedMessage),
        ("testEncoding_repeatedNestedEnum", testEncoding_repeatedNestedEnum),
        ("testEncoding_oneofUint32", testEncoding_oneofUint32),
        ("testEncoding_oneofNestedMessage", testEncoding_oneofNestedMessage),
        ("testEncoding_oneofNestedMessage1", testEncoding_oneofNestedMessage1),
        ("testEncoding_oneofNestedMessage2", testEncoding_oneofNestedMessage2),
        ("testEncoding_oneofNestedMessage9", testEncoding_oneofNestedMessage9),
        ("testEncoding_oneofString", testEncoding_oneofString),
        ("testEncoding_oneofBytes", testEncoding_oneofBytes),
        ("testEncoding_oneofBytes2", testEncoding_oneofBytes2),
        ("testEncoding_oneofBytes3", testEncoding_oneofBytes3),
        ("testEncoding_oneofBytes4", testEncoding_oneofBytes4),
        ("testEncoding_oneofBytes5", testEncoding_oneofBytes5),
        ("testEncoding_oneofBytes_failures", testEncoding_oneofBytes_failures),
        ("testEncoding_oneofBytes_debugDescription", testEncoding_oneofBytes_debugDescription),
        ("testDebugDescription", testDebugDescription),
        ("testDebugDescription2", testDebugDescription2),
        ("testDebugDescription3", testDebugDescription3)
    ]
}

extension Test_Any {
    static var allTests = [
        ("test_Any", test_Any),
        ("test_Any_different_prefix", test_Any_different_prefix),
        ("test_Any_noprefix", test_Any_noprefix),
        ("test_Any_shortesttype", test_Any_shortesttype),
        ("test_Any_UserMessage", test_Any_UserMessage),
        ("test_Any_UnknownUserMessage_JSON", test_Any_UnknownUserMessage_JSON),
        ("test_Any_UnknownUserMessage_protobuf", test_Any_UnknownUserMessage_protobuf),
        ("test_Any_Any", test_Any_Any),
        ("test_Any_Duration_JSON_roundtrip", test_Any_Duration_JSON_roundtrip),
        ("test_Any_Duration_transcode", test_Any_Duration_transcode),
        ("test_Any_FieldMask_JSON_roundtrip", test_Any_FieldMask_JSON_roundtrip),
        ("test_Any_FieldMask_transcode", test_Any_FieldMask_transcode),
        ("test_Any_Int32Value_JSON_roundtrip", test_Any_Int32Value_JSON_roundtrip),
        ("test_Any_Int32Value_transcode", test_Any_Int32Value_transcode),
        ("test_Any_Struct_JSON_roundtrip", test_Any_Struct_JSON_roundtrip),
        ("test_Any_Struct_transcode", test_Any_Struct_transcode),
        ("test_Any_Timestamp_JSON_roundtrip", test_Any_Timestamp_JSON_roundtrip),
        ("test_Any_Timestamp_transcode", test_Any_Timestamp_transcode),
        ("test_Any_ListValue_JSON_roundtrip", test_Any_ListValue_JSON_roundtrip),
        ("test_Any_ListValue_transcode", test_Any_ListValue_transcode),
        ("test_Any_Value_struct_JSON_roundtrip", test_Any_Value_struct_JSON_roundtrip),
        ("test_Any_Value_struct_transcode", test_Any_Value_struct_transcode),
        ("test_Any_Value_int_JSON_roundtrip", test_Any_Value_int_JSON_roundtrip),
        ("test_Any_Value_int_transcode", test_Any_Value_int_transcode),
        ("test_Any_Value_string_JSON_roundtrip", test_Any_Value_string_JSON_roundtrip),
        ("test_Any_Value_string_transcode", test_Any_Value_string_transcode),
        ("test_Any_OddTypeURL_FromValue", test_Any_OddTypeURL_FromValue),
        ("test_Any_OddTypeURL_FromMessage", test_Any_OddTypeURL_FromMessage),
        ("test_IsA", test_IsA),
        ("test_Any_Registery", test_Any_Registery)
    ]
}

extension Test_Api {
    static var allTests = [
        ("testExists", testExists),
        ("testInitializer", testInitializer)
    ]
}

extension Test_BasicFields_Access_Proto2 {
    static var allTests = [
        ("testOptionalInt32", testOptionalInt32),
        ("testOptionalInt64", testOptionalInt64),
        ("testOptionalUint32", testOptionalUint32),
        ("testOptionalUint64", testOptionalUint64),
        ("testOptionalSint32", testOptionalSint32),
        ("testOptionalSint64", testOptionalSint64),
        ("testOptionalFixed32", testOptionalFixed32),
        ("testOptionalFixed64", testOptionalFixed64),
        ("testOptionalSfixed32", testOptionalSfixed32),
        ("testOptionalSfixed64", testOptionalSfixed64),
        ("testOptionalFloat", testOptionalFloat),
        ("testOptionalDouble", testOptionalDouble),
        ("testOptionalBool", testOptionalBool),
        ("testOptionalString", testOptionalString),
        ("testOptionalBytes", testOptionalBytes),
        ("testOptionalGroup", testOptionalGroup),
        ("testOptionalNestedMessage", testOptionalNestedMessage),
        ("testOptionalForeignMessage", testOptionalForeignMessage),
        ("testOptionalImportMessage", testOptionalImportMessage),
        ("testOptionalNestedEnum", testOptionalNestedEnum),
        ("testOptionalForeignEnum", testOptionalForeignEnum),
        ("testOptionalImportEnum", testOptionalImportEnum),
        ("testOptionalStringPiece", testOptionalStringPiece),
        ("testOptionalCord", testOptionalCord),
        ("testOptionalPublicImportMessage", testOptionalPublicImportMessage),
        ("testOptionalLazyMessage", testOptionalLazyMessage),
        ("testDefaultInt32", testDefaultInt32),
        ("testDefaultInt64", testDefaultInt64),
        ("testDefaultUint32", testDefaultUint32),
        ("testDefaultUint64", testDefaultUint64),
        ("testDefaultSint32", testDefaultSint32),
        ("testDefaultSint64", testDefaultSint64),
        ("testDefaultFixed32", testDefaultFixed32),
        ("testDefaultFixed64", testDefaultFixed64),
        ("testDefaultSfixed32", testDefaultSfixed32),
        ("testDefaultSfixed64", testDefaultSfixed64),
        ("testDefaultFloat", testDefaultFloat),
        ("testDefaultDouble", testDefaultDouble),
        ("testDefaultBool", testDefaultBool),
        ("testDefaultString", testDefaultString),
        ("testDefaultBytes", testDefaultBytes),
        ("testDefaultNestedEnum", testDefaultNestedEnum),
        ("testDefaultForeignEnum", testDefaultForeignEnum),
        ("testDefaultImportEnum", testDefaultImportEnum),
        ("testDefaultStringPiece", testDefaultStringPiece),
        ("testDefaultCord", testDefaultCord),
        ("testRepeatedInt32", testRepeatedInt32),
        ("testRepeatedInt64", testRepeatedInt64),
        ("testRepeatedUint32", testRepeatedUint32),
        ("testRepeatedUint64", testRepeatedUint64),
        ("testRepeatedSint32", testRepeatedSint32),
        ("testRepeatedSint64", testRepeatedSint64),
        ("testRepeatedFixed32", testRepeatedFixed32),
        ("testRepeatedFixed64", testRepeatedFixed64),
        ("testRepeatedSfixed32", testRepeatedSfixed32),
        ("testRepeatedSfixed64", testRepeatedSfixed64),
        ("testRepeatedFloat", testRepeatedFloat),
        ("testRepeatedDouble", testRepeatedDouble),
        ("testRepeatedBool", testRepeatedBool),
        ("testRepeatedString", testRepeatedString),
        ("testRepeatedBytes", testRepeatedBytes),
        ("testRepeatedGroup", testRepeatedGroup),
        ("testRepeatedNestedMessage", testRepeatedNestedMessage),
        ("testRepeatedForeignMessage", testRepeatedForeignMessage),
        ("testRepeatedImportMessage", testRepeatedImportMessage),
        ("testRepeatedNestedEnum", testRepeatedNestedEnum),
        ("testRepeatedForeignEnum", testRepeatedForeignEnum),
        ("testRepeatedImportEnum", testRepeatedImportEnum),
        ("testRepeatedStringPiece", testRepeatedStringPiece),
        ("testRepeatedCord", testRepeatedCord),
        ("testRepeatedLazyMessage", testRepeatedLazyMessage)
    ]
}

extension Test_BasicFields_Access_Proto3 {
    static var allTests = [
        ("testOptionalInt32", testOptionalInt32),
        ("testOptionalInt64", testOptionalInt64),
        ("testOptionalUint32", testOptionalUint32),
        ("testOptionalUint64", testOptionalUint64),
        ("testOptionalSint32", testOptionalSint32),
        ("testOptionalSint64", testOptionalSint64),
        ("testOptionalFixed32", testOptionalFixed32),
        ("testOptionalFixed64", testOptionalFixed64),
        ("testOptionalSfixed32", testOptionalSfixed32),
        ("testOptionalSfixed64", testOptionalSfixed64),
        ("testOptionalFloat", testOptionalFloat),
        ("testOptionalDouble", testOptionalDouble),
        ("testOptionalBool", testOptionalBool),
        ("testOptionalString", testOptionalString),
        ("testOptionalBytes", testOptionalBytes),
        ("testOptionalNestedMessage", testOptionalNestedMessage),
        ("testOptionalForeignMessage", testOptionalForeignMessage),
        ("testOptionalImportMessage", testOptionalImportMessage),
        ("testOptionalNestedEnum", testOptionalNestedEnum),
        ("testOptionalForeignEnum", testOptionalForeignEnum),
        ("testOptionalPublicImportMessage", testOptionalPublicImportMessage),
        ("testRepeatedInt32", testRepeatedInt32),
        ("testRepeatedInt64", testRepeatedInt64),
        ("testRepeatedUint32", testRepeatedUint32),
        ("testRepeatedUint64", testRepeatedUint64),
        ("testRepeatedSint32", testRepeatedSint32),
        ("testRepeatedSint64", testRepeatedSint64),
        ("testRepeatedFixed32", testRepeatedFixed32),
        ("testRepeatedFixed64", testRepeatedFixed64),
        ("testRepeatedSfixed32", testRepeatedSfixed32),
        ("testRepeatedSfixed64", testRepeatedSfixed64),
        ("testRepeatedFloat", testRepeatedFloat),
        ("testRepeatedDouble", testRepeatedDouble),
        ("testRepeatedBool", testRepeatedBool),
        ("testRepeatedString", testRepeatedString),
        ("testRepeatedBytes", testRepeatedBytes),
        ("testRepeatedNestedMessage", testRepeatedNestedMessage),
        ("testRepeatedForeignMessage", testRepeatedForeignMessage),
        ("testRepeatedImportMessage", testRepeatedImportMessage),
        ("testRepeatedNestedEnum", testRepeatedNestedEnum),
        ("testRepeatedForeignEnum", testRepeatedForeignEnum)
    ]
}

extension Test_BinaryDecodingOptions {
    static var allTests = [
        ("testMessageDepthLimit", testMessageDepthLimit),
        ("testDiscaringUnknownFields", testDiscaringUnknownFields)
    ]
}

extension Test_BinaryDelimited {
    static var allTests = [
        ("testEverything", testEverything)
    ]
}

extension Test_Conformance {
    static var allTests = [
        ("testFieldNaming", testFieldNaming),
        ("testFieldNaming_protoNames", testFieldNaming_protoNames),
        ("testFieldNaming_escapeInName", testFieldNaming_escapeInName),
        ("testInt32_min_roundtrip", testInt32_min_roundtrip),
        ("testInt32_toosmall", testInt32_toosmall),
        ("testRepeatedBoolWrapper", testRepeatedBoolWrapper),
        ("testString_badUnicodeEscape", testString_badUnicodeEscape),
        ("testString_surrogates", testString_surrogates)
    ]
}

extension Test_Duration {
    static var allTests = [
        ("testJSON_encode", testJSON_encode),
        ("testJSON_decode", testJSON_decode),
        ("testSerializationFailure", testSerializationFailure),
        ("testJSON_durationField", testJSON_durationField),
        ("testFieldMember", testFieldMember),
        ("testTranscode", testTranscode),
        ("testConformance", testConformance),
        ("testBasicArithmetic", testBasicArithmetic),
        ("testArithmeticNormalizes", testArithmeticNormalizes),
        ("testFloatLiteralConvertible", testFloatLiteralConvertible),
        ("testInitializationByTimeIntervals", testInitializationByTimeIntervals),
        ("testGetters", testGetters)
    ]
}

extension Test_Empty {
    static var allTests = [
        ("testExists", testExists)
    ]
}

extension Test_Enum {
    static var allTests = [
        ("testEqual", testEqual),
        ("testJSONsingular", testJSONsingular),
        ("testJSONrepeated", testJSONrepeated),
        ("testUnknownValues", testUnknownValues),
        ("testEnumPrefixStripping", testEnumPrefixStripping),
        ("testEnumPrefixStripping_TextFormat", testEnumPrefixStripping_TextFormat),
        ("testEnumPrefixStripping_JSON", testEnumPrefixStripping_JSON),
        ("testCaseIterable", testCaseIterable)
    ]
}

extension Test_EnumWithAliases {
    static var allTests = [
        ("testJSONEncodeUsesOriginalNames", testJSONEncodeUsesOriginalNames),
        ("testJSONDecodeAcceptsAllNames", testJSONDecodeAcceptsAllNames),
        ("testTextFormatEncodeUsesOriginalNames", testTextFormatEncodeUsesOriginalNames),
        ("testTextFormatDecodeAcceptsAllNames", testTextFormatDecodeAcceptsAllNames)
    ]
}

extension Test_Enum_Proto2 {
    static var allTests = [
        ("testEqual", testEqual),
        ("testUnknownIgnored", testUnknownIgnored),
        ("testJSONsingular", testJSONsingular),
        ("testJSONrepeated", testJSONrepeated),
        ("testUnknownValues", testUnknownValues),
        ("testEnumPrefixStripping", testEnumPrefixStripping),
        ("testEnumPrefixStripping_TextFormat", testEnumPrefixStripping_TextFormat),
        ("testEnumPrefixStripping_JSON", testEnumPrefixStripping_JSON),
        ("testCaseIterable", testCaseIterable)
    ]
}

extension Test_Extensions {
    static var allTests = [
        ("test_optionalInt32Extension", test_optionalInt32Extension),
        ("test_extensionMessageSpecificity", test_extensionMessageSpecificity),
        ("test_optionalStringExtension", test_optionalStringExtension),
        ("test_repeatedInt32Extension", test_repeatedInt32Extension),
        ("test_defaultInt32Extension", test_defaultInt32Extension),
        ("test_groupExtension", test_groupExtension),
        ("test_repeatedGroupExtension", test_repeatedGroupExtension),
        ("test_MessageNoStorageClass", test_MessageNoStorageClass),
        ("test_MessageUsingStorageClass", test_MessageUsingStorageClass)
    ]
}

extension Test_ExtremeDefaultValues {
    static var allTests = [
        ("test_escapedBytes", test_escapedBytes),
        ("test_largeUint32", test_largeUint32),
        ("test_largeUint64", test_largeUint64),
        ("test_smallInt32", test_smallInt32),
        ("test_smallInt64", test_smallInt64),
        ("test_reallySmallInt32", test_reallySmallInt32),
        ("test_reallySmallInt64", test_reallySmallInt64),
        ("test_utf8String", test_utf8String),
        ("test_zeroFloat", test_zeroFloat),
        ("test_oneFloat", test_oneFloat),
        ("test_smallFloat", test_smallFloat),
        ("test_negativeOneFloat", test_negativeOneFloat),
        ("test_negativeFloat", test_negativeFloat),
        ("test_largeFloat", test_largeFloat),
        ("test_smallNegativeFloat", test_smallNegativeFloat),
        ("test_infDouble", test_infDouble),
        ("test_negInfDouble", test_negInfDouble),
        ("test_nanDouble", test_nanDouble),
        ("test_infFloat", test_infFloat),
        ("test_negInfFloat", test_negInfFloat),
        ("test_nanFloat", test_nanFloat),
        ("test_cppTrigraph", test_cppTrigraph),
        ("test_stringWithZero", test_stringWithZero),
        ("test_bytesWithZero", test_bytesWithZero),
        ("test_stringPieceWithZero", test_stringPieceWithZero),
        ("test_cordWithZero", test_cordWithZero),
        ("test_replacementString", test_replacementString)
    ]
}

extension Test_FieldMask {
    static var allTests = [
        ("testJSON", testJSON),
        ("testProtobuf", testProtobuf),
        ("testDebugDescription", testDebugDescription),
        ("testConvenienceInits", testConvenienceInits),
        ("testJSON_field", testJSON_field),
        ("testSerializationFailure", testSerializationFailure)
    ]
}

extension Test_FieldOrdering {
    static var allTests = [
        ("test_FieldOrdering", test_FieldOrdering)
    ]
}

extension Test_GroupWithinGroup {
    static var allTests = [
        ("testGroupWithGroup_Single", testGroupWithGroup_Single),
        ("testGroupWithGroup_Repeated", testGroupWithGroup_Repeated)
    ]
}

extension Test_JSON {
    static var allTests = [
        ("testMultipleFields", testMultipleFields),
        ("testTruncation", testTruncation),
        ("testOptionalInt32", testOptionalInt32),
        ("testOptionalUInt32", testOptionalUInt32),
        ("testOptionalInt64", testOptionalInt64),
        ("testOptionalUInt64", testOptionalUInt64),
        ("testOptionalDouble", testOptionalDouble),
        ("testOptionalFloat", testOptionalFloat),
        ("testOptionalDouble_NaN", testOptionalDouble_NaN),
        ("testOptionalFloat_NaN", testOptionalFloat_NaN),
        ("testOptionalDouble_roundtrip", testOptionalDouble_roundtrip),
        ("testOptionalFloat_roundtrip", testOptionalFloat_roundtrip),
        ("testOptionalBool", testOptionalBool),
        ("testOptionalString", testOptionalString),
        ("testOptionalString_controlCharacters", testOptionalString_controlCharacters),
        ("testOptionalBytes", testOptionalBytes),
        ("testOptionalBytes_escapes", testOptionalBytes_escapes),
        ("testOptionalBytes_roundtrip", testOptionalBytes_roundtrip),
        ("testOptionalNestedMessage", testOptionalNestedMessage),
        ("testOptionalNestedEnum", testOptionalNestedEnum),
        ("testRepeatedInt32", testRepeatedInt32),
        ("testRepeatedString", testRepeatedString),
        ("testRepeatedNestedMessage", testRepeatedNestedMessage),
        ("testOneof", testOneof),
        ("testEmptyMessage", testEmptyMessage)
    ]
}

extension Test_JSONPacked {
    static var allTests = [
        ("testPackedFloat", testPackedFloat),
        ("testPackedDouble", testPackedDouble),
        ("testPackedInt32", testPackedInt32),
        ("testPackedInt64", testPackedInt64),
        ("testPackedUInt32", testPackedUInt32),
        ("testPackedUInt64", testPackedUInt64),
        ("testPackedSInt32", testPackedSInt32),
        ("testPackedSInt64", testPackedSInt64),
        ("testPackedFixed32", testPackedFixed32),
        ("testPackedFixed64", testPackedFixed64),
        ("testPackedSFixed32", testPackedSFixed32),
        ("testPackedSFixed64", testPackedSFixed64),
        ("testPackedBool", testPackedBool)
    ]
}

extension Test_JSONrepeated {
    static var allTests = [
        ("testPackedInt32", testPackedInt32)
    ]
}

extension Test_JSONDecodingOptions {
    static var allTests = [
        ("testMessageDepthLimit", testMessageDepthLimit),
        ("testIgnoreUnknownFields", testIgnoreUnknownFields)
    ]
}

extension Test_JSONEncodingOptions {
    static var allTests = [
        ("testAlwaysPrintEnumsAsInts", testAlwaysPrintEnumsAsInts),
        ("testPreserveProtoFieldNames", testPreserveProtoFieldNames)
    ]
}

extension Test_JSON_Array {
    static var allTests = [
        ("testTwoObjectsWithMultipleFields", testTwoObjectsWithMultipleFields),
        ("testRepeatedNestedMessage", testRepeatedNestedMessage)
    ]
}

extension Test_JSON_Conformance {
    static var allTests = [
        ("testNullSupport_regularTypes", testNullSupport_regularTypes),
        ("testNullSupport_wellKnownTypes", testNullSupport_wellKnownTypes),
        ("testNullSupport_Value", testNullSupport_Value),
        ("testNullSupport_Repeated", testNullSupport_Repeated),
        ("testNullSupport_RepeatedValue", testNullSupport_RepeatedValue),
        ("testNullConformance", testNullConformance),
        ("testValueList", testValueList),
        ("testNestedAny", testNestedAny)
    ]
}

extension Test_JSON_Group {
    static var allTests = [
        ("testOptionalGroup", testOptionalGroup),
        ("testRepeatedGroup", testRepeatedGroup)
    ]
}

extension Test_Map {
    static var allTests = [
        ("test_mapInt32Int32", test_mapInt32Int32),
        ("test_mapInt64Int64", test_mapInt64Int64),
        ("test_mapUint32Uint32", test_mapUint32Uint32),
        ("test_mapUint64Uint64", test_mapUint64Uint64),
        ("test_mapSint32Sint32", test_mapSint32Sint32),
        ("test_mapSint64Sint64", test_mapSint64Sint64),
        ("test_mapFixed32Fixed32", test_mapFixed32Fixed32),
        ("test_mapFixed64Fixed64", test_mapFixed64Fixed64),
        ("test_mapSfixed32Sfixed32", test_mapSfixed32Sfixed32),
        ("test_mapSfixed64Sfixed64", test_mapSfixed64Sfixed64),
        ("test_mapInt32Float", test_mapInt32Float),
        ("test_mapInt32Double", test_mapInt32Double),
        ("test_mapBoolBool", test_mapBoolBool),
        ("test_mapStringString", test_mapStringString),
        ("test_mapInt32Bytes", test_mapInt32Bytes),
        ("test_mapInt32Enum", test_mapInt32Enum),
        ("test_mapInt32ForeignMessage", test_mapInt32ForeignMessage),
        ("test_mapStringForeignMessage", test_mapStringForeignMessage),
        ("test_mapEnumUnknowns_Proto2", test_mapEnumUnknowns_Proto2),
        ("test_mapEnumUnknowns_Proto3", test_mapEnumUnknowns_Proto3)
    ]
}

extension Test_MapFields_Access_Proto2 {
    static var allTests = [
        ("testMapInt32Int32", testMapInt32Int32),
        ("testMapInt64Int64", testMapInt64Int64),
        ("testMapUint32Uint32", testMapUint32Uint32),
        ("testMapUint64Uint64", testMapUint64Uint64),
        ("testMapSint32Sint32", testMapSint32Sint32),
        ("testMapSint64Sint64", testMapSint64Sint64),
        ("testMapFixed32Fixed32", testMapFixed32Fixed32),
        ("testMapFixed64Fixed64", testMapFixed64Fixed64),
        ("testMapSfixed32Sfixed32", testMapSfixed32Sfixed32),
        ("testMapSfixed64Sfixed64", testMapSfixed64Sfixed64),
        ("testMapInt32Float", testMapInt32Float),
        ("testMapInt32Double", testMapInt32Double),
        ("testMapBoolBool", testMapBoolBool),
        ("testMapStringString", testMapStringString),
        ("testMapStringBytes", testMapStringBytes),
        ("testMapStringMessage", testMapStringMessage),
        ("testMapInt32Bytes", testMapInt32Bytes),
        ("testMapInt32Enum", testMapInt32Enum),
        ("testMapInt32Message", testMapInt32Message)
    ]
}

extension Test_MapFields_Access_Proto3 {
    static var allTests = [
        ("testMapInt32Int32", testMapInt32Int32),
        ("testMapInt64Int64", testMapInt64Int64),
        ("testMapUint32Uint32", testMapUint32Uint32),
        ("testMapUint64Uint64", testMapUint64Uint64),
        ("testMapSint32Sint32", testMapSint32Sint32),
        ("testMapSint64Sint64", testMapSint64Sint64),
        ("testMapFixed32Fixed32", testMapFixed32Fixed32),
        ("testMapFixed64Fixed64", testMapFixed64Fixed64),
        ("testMapSfixed32Sfixed32", testMapSfixed32Sfixed32),
        ("testMapSfixed64Sfixed64", testMapSfixed64Sfixed64),
        ("testMapInt32Float", testMapInt32Float),
        ("testMapInt32Double", testMapInt32Double),
        ("testMapBoolBool", testMapBoolBool),
        ("testMapStringString", testMapStringString),
        ("testMapStringBytes", testMapStringBytes),
        ("testMapStringMessage", testMapStringMessage),
        ("testMapInt32Bytes", testMapInt32Bytes),
        ("testMapInt32Enum", testMapInt32Enum),
        ("testMapInt32Message", testMapInt32Message)
    ]
}

extension Test_Map_JSON {
    static var allTests = [
        ("testMapInt32Int32", testMapInt32Int32),
        ("testMapInt64Int64", testMapInt64Int64),
        ("testMapUInt32UInt32", testMapUInt32UInt32),
        ("testMapUInt64UInt64", testMapUInt64UInt64),
        ("testMapSInt32SInt32", testMapSInt32SInt32),
        ("testMapSInt64SInt64", testMapSInt64SInt64),
        ("testFixed32Fixed32", testFixed32Fixed32),
        ("testFixed64Fixed64", testFixed64Fixed64),
        ("testSFixed32SFixed32", testSFixed32SFixed32),
        ("testSFixed64SFixed64", testSFixed64SFixed64),
        ("test_mapInt32Float", test_mapInt32Float),
        ("test_mapInt32Double", test_mapInt32Double),
        ("test_mapBoolBool", test_mapBoolBool),
        ("testMapStringString", testMapStringString),
        ("testMapInt32Bytes", testMapInt32Bytes),
        ("testMapInt32Enum", testMapInt32Enum),
        ("testMapInt32Message", testMapInt32Message)
    ]
}

extension Test_Merge {
    static var allTests = [
        ("testMergeSimple", testMergeSimple),
        ("testMergePreservesValueSemantics", testMergePreservesValueSemantics)
    ]
}

extension Test_MessageSet {
    static var allTests = [
        ("testSerialize", testSerialize),
        ("testParse", testParse),
        ("testTextFormat_Serialize", testTextFormat_Serialize),
        ("testTextFormat_Parse", testTextFormat_Parse)
    ]
}

extension Test_FieldNamingInitials {
    static var allTests = [
        ("testHidingFunctions", testHidingFunctions),
        ("testLowers", testLowers),
        ("testUppers", testUppers),
        ("testWordCase", testWordCase)
    ]
}

extension Test_ExtensionNamingInitials_MessageScoped {
    static var allTests = [
        ("testLowers", testLowers),
        ("testUppers", testUppers),
        ("testWordCase", testWordCase)
    ]
}

extension Test_ExtensionNamingInitials_GlobalScoped {
    static var allTests = [
        ("testLowers", testLowers),
        ("testUppers", testUppers),
        ("testWordCase", testWordCase)
    ]
}

extension Test_ExtensionNamingInitials_GlobalScoped_NoPrefix {
    static var allTests = [
        ("testLowers", testLowers),
        ("testUppers", testUppers),
        ("testWordCase", testWordCase)
    ]
}

extension Test_OneofFields_Access_Proto2 {
    static var allTests = [
        ("testOneofInt32", testOneofInt32),
        ("testOneofInt64", testOneofInt64),
        ("testOneofUint32", testOneofUint32),
        ("testOneofUint64", testOneofUint64),
        ("testOneofSint32", testOneofSint32),
        ("testOneofSint64", testOneofSint64),
        ("testOneofFixed32", testOneofFixed32),
        ("testOneofFixed64", testOneofFixed64),
        ("testOneofSfixed32", testOneofSfixed32),
        ("testOneofSfixed64", testOneofSfixed64),
        ("testOneofFloat", testOneofFloat),
        ("testOneofDouble", testOneofDouble),
        ("testOneofBool", testOneofBool),
        ("testOneofString", testOneofString),
        ("testOneofBytes", testOneofBytes),
        ("testOneofGroup", testOneofGroup),
        ("testOneofMessage", testOneofMessage),
        ("testOneofEnum", testOneofEnum),
        ("testOneofOnlyOneSet", testOneofOnlyOneSet)
    ]
}

extension Test_OneofFields_Access_Proto3 {
    static var allTests = [
        ("testOneofInt32", testOneofInt32),
        ("testOneofInt64", testOneofInt64),
        ("testOneofUint32", testOneofUint32),
        ("testOneofUint64", testOneofUint64),
        ("testOneofSint32", testOneofSint32),
        ("testOneofSint64", testOneofSint64),
        ("testOneofFixed32", testOneofFixed32),
        ("testOneofFixed64", testOneofFixed64),
        ("testOneofSfixed32", testOneofSfixed32),
        ("testOneofSfixed64", testOneofSfixed64),
        ("testOneofFloat", testOneofFloat),
        ("testOneofDouble", testOneofDouble),
        ("testOneofBool", testOneofBool),
        ("testOneofString", testOneofString),
        ("testOneofBytes", testOneofBytes),
        ("testOneofMessage", testOneofMessage),
        ("testOneofEnum", testOneofEnum),
        ("testOneofOnlyOneSet", testOneofOnlyOneSet)
    ]
}

extension Test_Packed {
    static var allTests = [
        ("testEncoding_packedInt32", testEncoding_packedInt32),
        ("testEncoding_packedInt64", testEncoding_packedInt64),
        ("testEncoding_packedUint32", testEncoding_packedUint32),
        ("testEncoding_packedUint64", testEncoding_packedUint64),
        ("testEncoding_packedSint32", testEncoding_packedSint32),
        ("testEncoding_packedSint64", testEncoding_packedSint64),
        ("testEncoding_packedFixed32", testEncoding_packedFixed32),
        ("testEncoding_packedFixed64", testEncoding_packedFixed64),
        ("testEncoding_packedSfixed32", testEncoding_packedSfixed32),
        ("testEncoding_packedSfixed64", testEncoding_packedSfixed64),
        ("testEncoding_packedFloat", testEncoding_packedFloat),
        ("testEncoding_packedDouble", testEncoding_packedDouble),
        ("testEncoding_packedBool", testEncoding_packedBool),
        ("testEncoding_packedEnum", testEncoding_packedEnum)
    ]
}

extension Test_ParsingMerge {
    static var allTests = [
        ("test_Merge", test_Merge),
        ("test_Merge_Oneof", test_Merge_Oneof)
    ]
}

extension Test_ReallyLargeTagNumber {
    static var allTests = [
        ("test_ReallyLargeTagNumber", test_ReallyLargeTagNumber)
    ]
}

extension Test_RecursiveMap {
    static var allTests = [
        ("test_RecursiveMap", test_RecursiveMap)
    ]
}

extension Test_Required {
    static var allTests = [
        ("test_IsInitialized", test_IsInitialized),
        ("test_OneOf_IsInitialized", test_OneOf_IsInitialized),
        ("test_NestedInProto2_IsInitialized", test_NestedInProto2_IsInitialized),
        ("test_NestedInProto3_IsInitialized", test_NestedInProto3_IsInitialized),
        ("test_map_isInitialized", test_map_isInitialized),
        ("test_Extensions_isInitialized", test_Extensions_isInitialized),
        ("test_decodeRequired", test_decodeRequired),
        ("test_encodeRequired", test_encodeRequired)
    ]
}

extension Test_SmallRequired {
    static var allTests = [
        ("test_decodeRequired", test_decodeRequired),
        ("test_encodeRequired", test_encodeRequired)
    ]
}

extension Test_Reserved {
    static var allTests = [
        ("testEnumNaming", testEnumNaming),
        ("testMessageNames", testMessageNames),
        ("testFieldNamesMatchingMetadata", testFieldNamesMatchingMetadata),
        ("testExtensionNamesMatching", testExtensionNamesMatching)
    ]
}

extension Test_SimpleExtensionMap {
    static var allTests = [
        ("testInsert", testInsert),
        ("testInsert_contentsOf", testInsert_contentsOf),
        ("testInitialize_list", testInitialize_list),
        ("testFormUnion", testFormUnion),
        ("testUnion", testUnion),
        ("testInitialize_union", testInitialize_union),
        ("testSubscript", testSubscript),
        ("testFieldNumberForProto", testFieldNumberForProto)
    ]
}

extension Test_Struct {
    static var allTests = [
        ("testStruct_pbencode", testStruct_pbencode),
        ("testStruct_pbdecode", testStruct_pbdecode),
        ("test_JSON", test_JSON),
        ("test_JSON_field", test_JSON_field),
        ("test_equality", test_equality)
    ]
}

extension Test_JSON_ListValue {
    static var allTests = [
        ("testProtobuf", testProtobuf),
        ("testJSON", testJSON),
        ("test_equality", test_equality)
    ]
}

extension Test_Value {
    static var allTests = [
        ("testValue_empty", testValue_empty)
    ]
}

extension Test_JSON_Value {
    static var allTests = [
        ("testValue_emptyShouldThrow", testValue_emptyShouldThrow),
        ("testValue_null", testValue_null),
        ("testValue_number", testValue_number),
        ("testValue_string", testValue_string),
        ("testValue_bool", testValue_bool),
        ("testValue_struct", testValue_struct),
        ("testValue_list", testValue_list),
        ("testValue_complex", testValue_complex),
        ("testStruct_conformance", testStruct_conformance),
        ("testStruct_null", testStruct_null)
    ]
}

extension Test_TextFormat_Map_proto3 {
    static var allTests = [
        ("test_Int32Int32", test_Int32Int32),
        ("test_Int32Int32_numbers", test_Int32Int32_numbers),
        ("test_StringMessage", test_StringMessage),
        ("test_StringMessage_numbers", test_StringMessage_numbers)
    ]
}

extension Test_TextFormat_Unknown {
    static var allTests = [
        ("test_unknown_varint", test_unknown_varint),
        ("test_unknown_fixed64", test_unknown_fixed64),
        ("test_unknown_lengthDelimited_string", test_unknown_lengthDelimited_string),
        ("test_unknown_lengthDelimited_message", test_unknown_lengthDelimited_message),
        ("test_unknown_lengthDelimited_notmessage", test_unknown_lengthDelimited_notmessage),
        ("test_unknown_lengthDelimited_nested_message", test_unknown_lengthDelimited_nested_message),
        ("test_unknown_lengthDelimited_nested_message_recursion_limits", test_unknown_lengthDelimited_nested_message_recursion_limits),
        ("test_unknown_group", test_unknown_group),
        ("test_unknown_nested_group", test_unknown_nested_group),
        ("test_unknown_nested_group_no_recursion_limits", test_unknown_nested_group_no_recursion_limits),
        ("test_unknown_fixed32", test_unknown_fixed32)
    ]
}

extension Test_TextFormat_WKT_proto3 {
    static var allTests = [
        ("testAny", testAny),
        ("testAny_verbose", testAny_verbose),
        ("testApi", testApi),
        ("testDuration", testDuration),
        ("testEmpty", testEmpty),
        ("testFieldMask", testFieldMask),
        ("testStruct", testStruct),
        ("testTimestamp", testTimestamp),
        ("testType", testType),
        ("testDoubleValue", testDoubleValue),
        ("testFloatValue", testFloatValue),
        ("testInt64Value", testInt64Value),
        ("testUInt64Value", testUInt64Value),
        ("testInt32Value", testInt32Value),
        ("testUInt32Value", testUInt32Value),
        ("testBoolValue", testBoolValue),
        ("testStringValue", testStringValue),
        ("testBytesValue", testBytesValue),
        ("testValue", testValue)
    ]
}

extension Test_TextFormat_proto2 {
    static var allTests = [
        ("test_group", test_group),
        ("test_group_numbers", test_group_numbers),
        ("test_repeatedGroup", test_repeatedGroup),
        ("test_repeatedGroup_numbers", test_repeatedGroup_numbers)
    ]
}

extension Test_TextFormat_proto2_extensions {
    static var allTests = [
        ("test_file_level_extension", test_file_level_extension),
        ("test_nested_extension", test_nested_extension)
    ]
}

extension Test_TextFormat_proto3 {
    static var allTests = [
        ("testDecoding_comments", testDecoding_comments),
        ("testDecoding_comments_numbers", testDecoding_comments_numbers),
        ("testEncoding_optionalInt32", testEncoding_optionalInt32),
        ("testEncoding_optionalInt64", testEncoding_optionalInt64),
        ("testEncoding_optionalUint32", testEncoding_optionalUint32),
        ("testEncoding_optionalUint64", testEncoding_optionalUint64),
        ("testEncoding_optionalSint32", testEncoding_optionalSint32),
        ("testEncoding_optionalSint64", testEncoding_optionalSint64),
        ("testEncoding_optionalFixed32", testEncoding_optionalFixed32),
        ("testEncoding_optionalFixed64", testEncoding_optionalFixed64),
        ("testEncoding_optionalSfixed32", testEncoding_optionalSfixed32),
        ("testEncoding_optionalSfixed64", testEncoding_optionalSfixed64),
        ("testEncoding_optionalFloat", testEncoding_optionalFloat),
        ("testEncoding_optionalDouble", testEncoding_optionalDouble),
        ("testEncoding_optionalBool", testEncoding_optionalBool),
        ("testEncoding_optionalString", testEncoding_optionalString),
        ("testEncoding_optionalString_controlCharacters", testEncoding_optionalString_controlCharacters),
        ("testEncoding_optionalString_UTF8", testEncoding_optionalString_UTF8),
        ("testEncoding_optionalBytes", testEncoding_optionalBytes),
        ("testEncoding_optionalBytes_roundtrip", testEncoding_optionalBytes_roundtrip),
        ("testEncoding_optionalNestedMessage", testEncoding_optionalNestedMessage),
        ("testEncoding_optionalForeignMessage", testEncoding_optionalForeignMessage),
        ("testEncoding_optionalImportMessage", testEncoding_optionalImportMessage),
        ("testEncoding_optionalNestedEnum", testEncoding_optionalNestedEnum),
        ("testEncoding_optionalForeignEnum", testEncoding_optionalForeignEnum),
        ("testEncoding_optionalPublicImportMessage", testEncoding_optionalPublicImportMessage),
        ("testEncoding_repeatedInt32", testEncoding_repeatedInt32),
        ("testEncoding_repeatedInt64", testEncoding_repeatedInt64),
        ("testEncoding_repeatedUint32", testEncoding_repeatedUint32),
        ("testEncoding_repeatedUint64", testEncoding_repeatedUint64),
        ("testEncoding_repeatedSint32", testEncoding_repeatedSint32),
        ("testEncoding_repeatedSint64", testEncoding_repeatedSint64),
        ("testEncoding_repeatedFixed32", testEncoding_repeatedFixed32),
        ("testEncoding_repeatedFixed64", testEncoding_repeatedFixed64),
        ("testEncoding_repeatedSfixed32", testEncoding_repeatedSfixed32),
        ("testEncoding_repeatedSfixed64", testEncoding_repeatedSfixed64),
        ("testEncoding_repeatedFloat", testEncoding_repeatedFloat),
        ("testEncoding_repeatedDouble", testEncoding_repeatedDouble),
        ("testEncoding_repeatedBool", testEncoding_repeatedBool),
        ("testEncoding_repeatedString", testEncoding_repeatedString),
        ("testEncoding_repeatedBytes", testEncoding_repeatedBytes),
        ("testEncoding_repeatedNestedMessage", testEncoding_repeatedNestedMessage),
        ("testEncoding_repeatedForeignMessage", testEncoding_repeatedForeignMessage),
        ("testEncoding_repeatedImportMessage", testEncoding_repeatedImportMessage),
        ("testEncoding_repeatedNestedEnum", testEncoding_repeatedNestedEnum),
        ("testEncoding_repeatedForeignEnum", testEncoding_repeatedForeignEnum),
        ("testEncoding_oneofUint32", testEncoding_oneofUint32),
        ("testInvalidToken", testInvalidToken),
        ("testInvalidFieldName", testInvalidFieldName),
        ("testInvalidCapitalization", testInvalidCapitalization),
        ("testExplicitDelimiters", testExplicitDelimiters),
        ("testMultipleFields", testMultipleFields),
        ("testMultipleFields_numbers", testMultipleFields_numbers)
    ]
}

extension Test_Timestamp {
    static var allTests = [
        ("testJSON", testJSON),
        ("testJSON_range", testJSON_range),
        ("testJSON_timezones", testJSON_timezones),
        ("testJSON_timestampField", testJSON_timestampField),
        ("testJSON_conformance", testJSON_conformance),
        ("testSerializationFailure", testSerializationFailure),
        ("testBasicArithmetic", testBasicArithmetic),
        ("testArithmeticNormalizes", testArithmeticNormalizes),
        ("testInitializationByTimestamps", testInitializationByTimestamps),
        ("testInitializationByReferenceTimestamp", testInitializationByReferenceTimestamp),
        ("testInitializationByDates", testInitializationByDates),
        ("testTimestampGetters", testTimestampGetters)
    ]
}

extension Test_Type {
    static var allTests = [
        ("testExists", testExists)
    ]
}

extension Test_Unknown_proto2 {
    static var allTests = [
        ("testBinaryPB", testBinaryPB),
        ("testJSON", testJSON),
        ("test_MessageNoStorageClass", test_MessageNoStorageClass),
        ("test_MessageUsingStorageClass", test_MessageUsingStorageClass)
    ]
}

extension Test_Unknown_proto3 {
    static var allTests = [
        ("testBinaryPB", testBinaryPB),
        ("testJSON", testJSON),
        ("test_MessageNoStorageClass", test_MessageNoStorageClass),
        ("test_MessageUsingStorageClass", test_MessageUsingStorageClass)
    ]
}

extension Test_Wrappers {
    static var allTests = [
        ("testDoubleValue", testDoubleValue),
        ("testFloatValue", testFloatValue),
        ("testInt64Value", testInt64Value),
        ("testUInt64Value", testUInt64Value),
        ("testInt32Value", testInt32Value),
        ("testUInt32Value", testUInt32Value),
        ("testBoolValue", testBoolValue),
        ("testStringValue", testStringValue),
        ("testBytesValue", testBytesValue)
    ]
}

XCTMain(
    [
        testCase(Test_Descriptor.allTests),
        testCase(Test_NamingUtils.allTests),
        testCase(Test_ProtoFileToModuleMappings.allTests),
        testCase(Test_SwiftLanguage.allTests),
        testCase(Test_SwiftProtobufNamer.allTests),
        testCase(Test_AllTypes.allTests),
        testCase(Test_AllTypes_Proto3.allTests),
        testCase(Test_Any.allTests),
        testCase(Test_Api.allTests),
        testCase(Test_BasicFields_Access_Proto2.allTests),
        testCase(Test_BasicFields_Access_Proto3.allTests),
        testCase(Test_BinaryDecodingOptions.allTests),
        testCase(Test_BinaryDelimited.allTests),
        testCase(Test_Conformance.allTests),
        testCase(Test_Duration.allTests),
        testCase(Test_Empty.allTests),
        testCase(Test_Enum.allTests),
        testCase(Test_EnumWithAliases.allTests),
        testCase(Test_Enum_Proto2.allTests),
        testCase(Test_Extensions.allTests),
        testCase(Test_ExtremeDefaultValues.allTests),
        testCase(Test_FieldMask.allTests),
        testCase(Test_FieldOrdering.allTests),
        testCase(Test_GroupWithinGroup.allTests),
        testCase(Test_JSON.allTests),
        testCase(Test_JSONPacked.allTests),
        testCase(Test_JSONrepeated.allTests),
        testCase(Test_JSONDecodingOptions.allTests),
        testCase(Test_JSONEncodingOptions.allTests),
        testCase(Test_JSON_Array.allTests),
        testCase(Test_JSON_Conformance.allTests),
        testCase(Test_JSON_Group.allTests),
        testCase(Test_Map.allTests),
        testCase(Test_MapFields_Access_Proto2.allTests),
        testCase(Test_MapFields_Access_Proto3.allTests),
        testCase(Test_Map_JSON.allTests),
        testCase(Test_Merge.allTests),
        testCase(Test_MessageSet.allTests),
        testCase(Test_FieldNamingInitials.allTests),
        testCase(Test_ExtensionNamingInitials_MessageScoped.allTests),
        testCase(Test_ExtensionNamingInitials_GlobalScoped.allTests),
        testCase(Test_ExtensionNamingInitials_GlobalScoped_NoPrefix.allTests),
        testCase(Test_OneofFields_Access_Proto2.allTests),
        testCase(Test_OneofFields_Access_Proto3.allTests),
        testCase(Test_Packed.allTests),
        testCase(Test_ParsingMerge.allTests),
        testCase(Test_ReallyLargeTagNumber.allTests),
        testCase(Test_RecursiveMap.allTests),
        testCase(Test_Required.allTests),
        testCase(Test_SmallRequired.allTests),
        testCase(Test_Reserved.allTests),
        testCase(Test_SimpleExtensionMap.allTests),
        testCase(Test_Struct.allTests),
        testCase(Test_JSON_ListValue.allTests),
        testCase(Test_Value.allTests),
        testCase(Test_JSON_Value.allTests),
        testCase(Test_TextFormat_Map_proto3.allTests),
        testCase(Test_TextFormat_Unknown.allTests),
        testCase(Test_TextFormat_WKT_proto3.allTests),
        testCase(Test_TextFormat_proto2.allTests),
        testCase(Test_TextFormat_proto2_extensions.allTests),
        testCase(Test_TextFormat_proto3.allTests),
        testCase(Test_Timestamp.allTests),
        testCase(Test_Type.allTests),
        testCase(Test_Unknown_proto2.allTests),
        testCase(Test_Unknown_proto3.allTests),
        testCase(Test_Wrappers.allTests)
    ]
)
