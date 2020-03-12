/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.sync15

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * This file defines Kotlin data classes for unpacking the Sync telemetry ping,
 * which the FFI returns as a JSON string from `sync15_history_sync` and
 * `sync15_bookmarks_sync`.
 *
 * The Kotlin API parses the string into a `SyncTelemetryPing`, and passes it
 * to Android Components, where it's unpacked and marshaled into Glean pings.
 * Glean doesn't currently support nested fields, so we send one ping per
 * engine (`EngineInfo`) per sync (`SyncInfo`).
 *
 * Applications like Fenix that embed Glean will automatically submit these
 * pings.
 */

enum class FailureName {
    Shutdown,
    Other,
    Unexpected,
    Auth,
    Http,
    Unknown
}

data class SyncTelemetryPing(
    val version: Int,
    val uid: String,
    val events: List<EventInfo>,
    val syncs: List<SyncInfo>
) {
    companion object {
        @JvmField val EMPTY_UID = "0".repeat(32)

        fun empty(): SyncTelemetryPing {
            return SyncTelemetryPing(
                version = 1,
                uid = EMPTY_UID,
                events = emptyList(),
                syncs = emptyList()
            )
        }

        fun fromJSON(jsonObject: JSONObject): SyncTelemetryPing {
            val events = unwrapFromJSON(jsonObject) {
                it.getJSONArray("events")
            }?.let {
                EventInfo.fromJSONArray(it)
            } ?: emptyList()
            val syncs = unwrapFromJSON(jsonObject) {
                it.getJSONArray("syncs")
            }?.let {
                SyncInfo.fromJSONArray(it)
            } ?: emptyList()
            return SyncTelemetryPing(
                version = jsonObject.getInt("version"),
                uid = stringOrNull(jsonObject, "uid") ?: EMPTY_UID,
                events = events,
                syncs = syncs
            )
        }

        fun fromJSONString(jsonObjectText: String): SyncTelemetryPing {
            return fromJSON(JSONObject(jsonObjectText))
        }
    }

    fun toJSON(): JSONObject {
        var result = JSONObject()
        result.put("version", version)
        result.put("uid", uid)
        if (!events.isEmpty()) {
            result.put("events", JSONArray().apply {
                events.forEach {
                    put(it.toJSON())
                }
            })
        }
        if (!syncs.isEmpty()) {
            result.put("syncs", JSONArray().apply {
                syncs.forEach {
                    put(it.toJSON())
                }
            })
        }
        return result
    }
}

data class SyncInfo(
    val at: Long,
    val took: Long,
    val engines: List<EngineInfo>,
    val failureReason: FailureReason?
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): SyncInfo {
            val engines = unwrapFromJSON(jsonObject) {
                it.getJSONArray("engines")
            }?.let {
                EngineInfo.fromJSONArray(it)
            } ?: emptyList()
            val failureReason = unwrapFromJSON(jsonObject) {
                it.getJSONObject("failureReason")
            }?.let {
                FailureReason.fromJSON(it)
            }
            return SyncInfo(
                at = jsonObject.getLong("when"),
                took = longOrZero(jsonObject, "took"),
                engines = engines,
                failureReason = failureReason
            )
        }

        fun fromJSONArray(jsonArray: JSONArray): List<SyncInfo> {
            val result: MutableList<SyncInfo> = mutableListOf()
            for (index in 0 until jsonArray.length()) {
                result.add(fromJSON(jsonArray.getJSONObject(index)))
            }
            return result
        }
    }

    fun toJSON(): JSONObject {
        var result = JSONObject()
        result.put("when", at)
        if (took > 0) {
            result.put("took", took)
        }
        if (!engines.isEmpty()) {
            result.put("engines", JSONArray().apply {
                engines.forEach {
                    put(it.toJSON())
                }
            })
        }
        failureReason?.let {
            result.put("failureReason", it.toJSON())
        }
        return result
    }
}

data class EngineInfo(
    val name: String,
    val at: Long,
    val took: Long,
    val incoming: IncomingInfo?,
    val outgoing: List<OutgoingInfo>,
    val failureReason: FailureReason?,
    val validation: ValidationInfo?
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): EngineInfo {
            val incoming = unwrapFromJSON(jsonObject) {
                it.getJSONObject("incoming")
            }?.let {
                IncomingInfo.fromJSON(it)
            }
            val outgoing = unwrapFromJSON(jsonObject) {
                it.getJSONArray("outgoing")
            }?.let {
                OutgoingInfo.fromJSONArray(it)
            } ?: emptyList()
            val failureReason = unwrapFromJSON(jsonObject) {
                jsonObject.getJSONObject("failureReason")
            }?.let {
                FailureReason.fromJSON(it)
            }
            val validation = unwrapFromJSON(jsonObject) {
                jsonObject.getJSONObject("validation")
            }?.let {
                ValidationInfo.fromJSON(it)
            }
            return EngineInfo(
                name = jsonObject.getString("name"),
                at = jsonObject.getLong("when"),
                took = longOrZero(jsonObject, "took"),
                incoming = incoming,
                outgoing = outgoing,
                failureReason = failureReason,
                validation = validation
            )
        }

        fun fromJSONArray(jsonArray: JSONArray): List<EngineInfo> {
            val result: MutableList<EngineInfo> = mutableListOf()
            for (index in 0 until jsonArray.length()) {
                result.add(fromJSON(jsonArray.getJSONObject(index)))
            }
            return result
        }
    }

    fun toJSON(): JSONObject {
        val result = JSONObject()
        result.put("name", name)
        result.put("when", at)
        if (took > 0) {
            result.put("took", took)
        }
        incoming?.let {
            result.put("incoming", it.toJSON())
        }
        if (!outgoing.isEmpty()) {
            result.put("outgoing", JSONArray().apply {
                outgoing.forEach {
                    put(it.toJSON())
                }
            })
        }
        failureReason?.let {
            result.put("failureReason", it.toJSON())
        }
        validation?.let {
            result.put("validation", it.toJSON())
        }
        return result
    }
}

data class IncomingInfo(
    val applied: Int,
    val failed: Int,
    val newFailed: Int,
    val reconciled: Int
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): IncomingInfo {
            return IncomingInfo(
                applied = intOrZero(jsonObject, "applied"),
                failed = intOrZero(jsonObject, "failed"),
                newFailed = intOrZero(jsonObject, "newFailed"),
                reconciled = intOrZero(jsonObject, "reconciled")
            )
        }
    }

    fun toJSON(): JSONObject {
        return JSONObject().apply {
            if (applied > 0) {
                put("applied", applied)
            }
            if (failed > 0) {
                put("failed", failed)
            }
            if (newFailed > 0) {
                put("newFailed", newFailed)
            }
            if (reconciled > 0) {
                put("reconciled", reconciled)
            }
        }
    }
}

data class OutgoingInfo(
    val sent: Int,
    val failed: Int
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): OutgoingInfo {
            return OutgoingInfo(
                sent = intOrZero(jsonObject, "sent"),
                failed = intOrZero(jsonObject, "failed")
            )
        }

        fun fromJSONArray(jsonArray: JSONArray): List<OutgoingInfo> {
            val result: MutableList<OutgoingInfo> = mutableListOf()
            for (index in 0 until jsonArray.length()) {
                result.add(fromJSON(jsonArray.getJSONObject(index)))
            }
            return result
        }
    }

    fun toJSON(): JSONObject {
        return JSONObject().apply {
            if (sent > 0) {
                put("sent", sent)
            }
            if (failed > 0) {
                put("failed", failed)
            }
        }
    }
}

data class ValidationInfo(
    val version: Int,
    val problems: List<ProblemInfo>,
    val failureReason: FailureReason?
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): ValidationInfo {
            val problems = unwrapFromJSON(jsonObject) {
                it.getJSONArray("outgoing")
            }?.let {
                ProblemInfo.fromJSONArray(it)
            } ?: emptyList()
            val failureReason = unwrapFromJSON(jsonObject) {
                it.getJSONObject("failureReason")
            }?.let {
                FailureReason.fromJSON(it)
            }
            return ValidationInfo(
                version = jsonObject.getInt("version"),
                problems = problems,
                failureReason = failureReason
            )
        }
    }

    fun toJSON(): JSONObject {
        var result = JSONObject()
        result.put("version", version)
        if (!problems.isEmpty()) {
            result.put("problems", JSONArray().apply {
                problems.forEach {
                    put(it.toJSON())
                }
            })
        }
        failureReason?.let {
            result.put("failueReason", it.toJSON())
        }
        return result
    }
}

data class ProblemInfo(
    val name: String,
    val count: Int
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): ProblemInfo {
            return ProblemInfo(
                name = jsonObject.getString("name"),
                count = intOrZero(jsonObject, "count")
            )
        }

        fun fromJSONArray(jsonArray: JSONArray): List<ProblemInfo> {
            val result: MutableList<ProblemInfo> = mutableListOf()
            for (index in 0 until jsonArray.length()) {
                result.add(fromJSON(jsonArray.getJSONObject(index)))
            }
            return result
        }
    }

    fun toJSON(): JSONObject {
        return JSONObject().apply {
            put("name", name)
            if (count > 0) {
                put("count", count)
            }
        }
    }
}

data class FailureReason(
    val name: FailureName,
    val message: String? = null,
    val code: Int = -1
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): FailureReason? {
            return jsonObject.getString("name").let {
                when (it) {
                    "shutdownerror" -> FailureReason(
                        name = FailureName.Shutdown
                    )
                    "othererror" -> FailureReason(
                        name = FailureName.Other,
                        message = jsonObject.getString("error")
                    )
                    "unexpectederror" -> FailureReason(
                        name = FailureName.Unexpected,
                        message = jsonObject.getString("error")
                    )
                    "autherror" -> FailureReason(
                        name = FailureName.Auth,
                        message = jsonObject.getString("from")
                    )
                    "httperror" -> FailureReason(
                        name = FailureName.Http,
                        code = jsonObject.getInt("code")
                    )
                    else -> FailureReason(
                        name = FailureName.Unknown
                    )
                }
            }
        }
    }

    fun toJSON(): JSONObject {
        var result = JSONObject()
        when (name) {
            FailureName.Shutdown -> {
                result.put("name", "shutdownerror")
            }
            FailureName.Other -> {
                result.put("name", "othererror")
                message?.let {
                    result.put("error", it)
                }
            }
            FailureName.Unexpected, FailureName.Unknown -> {
                result.put("name", "unexpectederror")
                message?.let {
                    result.put("error", it)
                }
            }
            FailureName.Auth -> {
                result.put("name", "autherror")
                message?.let {
                    result.put("from", it)
                }
            }
            FailureName.Http -> {
                result.put("name", "httperror")
                result.put("code", code)
            }
        }
        return result
    }
}

data class EventInfo(
    val obj: String,
    val method: String,
    val value: String?,
    val extra: Map<String, String>
) {
    companion object {
        fun fromJSON(jsonObject: JSONObject): EventInfo {
            val extra = unwrapFromJSON(jsonObject) {
                jsonObject.getJSONObject("extra")
            }?.let {
                val extra = mutableMapOf<String, String>()
                for (key in it.keys()) {
                    extra[key] = it.getString(key)
                }
                extra
            } ?: emptyMap<String, String>()
            return EventInfo(
                obj = jsonObject.getString("object"),
                method = jsonObject.getString("method"),
                value = stringOrNull(jsonObject, "value"),
                extra = extra
            )
        }

        fun fromJSONArray(jsonArray: JSONArray): List<EventInfo> {
            val result: MutableList<EventInfo> = mutableListOf()
            for (index in 0 until jsonArray.length()) {
                result.add(fromJSON(jsonArray.getJSONObject(index)))
            }
            return result
        }
    }

    fun toJSON(): JSONObject {
        return JSONObject().apply {
            put("object", obj)
            put("method", method)
            value?.let {
                put("value", it)
            }
            if (!extra.isEmpty()) {
                put("extra", extra)
            }
        }
    }
}

private fun longOrZero(jsonObject: JSONObject, key: String): Long {
    return unwrapFromJSON(jsonObject) {
        it.getLong(key)
    } ?: 0
}

private fun intOrZero(jsonObject: JSONObject, key: String): Int {
    return unwrapFromJSON(jsonObject) {
        it.getInt(key)
    } ?: 0
}

/**
 * Extracts an optional property value from a JSON object, returning `null` if
 * the property doesn't exist.
 */
inline fun <T> unwrapFromJSON(jsonObject: JSONObject, func: (JSONObject) -> T): T? {
    return try {
        func(jsonObject)
    } catch (e: JSONException) {
        null
    }
}

/**
 * Extracts an optional string value from a JSON object.
 */
fun stringOrNull(jsonObject: JSONObject, key: String): String? {
    return unwrapFromJSON(jsonObject) {
        it.getString(key)
    }
}
