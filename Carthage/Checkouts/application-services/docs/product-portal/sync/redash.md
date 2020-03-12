---
title: Redash
---

### Table Described

The Sync team's telemetry goes through our data pipeline and lands in
Presto to be explored in [Redash](https://sql.telemetry.mozilla.org/).
Below is a description of the data available in the **sync\_summary**
table. Further documentation on this data is available [in the
telemetry-batch-view
repo](https://github.com/mozilla/telemetry-batch-view/blob/master/docs/SyncSummary.md),
and in the [general sync ping
documentation](http://gecko.readthedocs.io/en/latest/toolkit/components/telemetry/telemetry/data/sync-ping.html).

|Field Names            | Data Type                                            | Description
|-----------------------|------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|app\_build\_id         | varchar                                              | Firefox build ID (e.g. 20160801085519)
|app\_version           | varchar                                              | Firefox version (e.g. 50.0a2) - corresponds to the MOZ\_APP\_VERSION configure value
|app\_display\_version  | varchar                                              | The application version as shown in the about dialog. Almost always identical to app\_version. Corresponds to the MOZ\_APP\_VERSION\_DISPLAY configure value.
|app\_name              | varchar                                              | Will always be the string "Firefox" in desktop submitted pings.
|app\_channel           | varchar                                              | The update channel (e.g. "release", "nightly", etc) - corresponds to the MOZ\_UPDATE\_CHANNEL config variable.
|uid                    | varchar                                              | Hashed Sync/FxA ID
|deviceid               | varchar                                              | Hashed FxA device ID.
|when                   | bigint                                               | Unix timestamp of when sync occurred. Make sure to put in "quotes" since when is a reserved SQL word. Note that because this is taken from the client's clock, the time may be wildly inaccurate.
|took                   | bigint                                               | Number of milli-seconds it took to Sync.
|failure\_reason        | row(name varchar, value varchar)                     | Sync failure reason, or null if no failure.
|status                 | row(sync varchar, service varchar)                   | The status of sync after completion, or null is both statuses record success.
|why                    | varchar                                              | Currently always null, but eventually should be the reason the sync was performed (eg, timer, button press, score update, etc)
|devices                | array(row(id varchar, os varchar, version varchar))  | Array of the other devices in this user's device constellation.
|engines                | array(engine\_record)                                | A record of the engines that synced. Each element of the array is in the format of an [engine record](#engine-record).
|submission\_date\_s3   | varchar                                              | The date this ping was submitted to the telemetry servers. Because a ping will typically be sent for a previous session immediately after a browser restart, this submission date may be later than the date recorded in the ping. Note also that this is a timestamp supplied by the server so is likely to be more reliable than the dates recorded in the ping itself.

#### Engine Record

An engine record is defined as:

| Field Name        | Data Type                                                                 | Description
|-------------------|---------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
| name              | varchar                                                                   | The name of the engine.
| took              | bigint                                                                    | How many milliseconds this engine took to sync.
| status            | varchar                                                                   | The status of this engine after sync completed, or null is the status reflects success.
| failure\_reason   | row(name varchar, value varchar)                                          | Details of any errors recorded during the sync of this engine, or null on success.
| incoming          | row(applied bigint, failed bigint, newFailed bigint, reconciled bigint)   | Details of how many incoming records were applied, failed, failed for the first time in this sync, and reconciled.
| outgoing          | array(row(sent bigint, failed bigint)))                                   | For each batch of records uploaded as part of a Sync, how many records were sent in that batch and how many failed.
| validation        | validation\_record                                                        | Validation information for this engine. Null if validation cannot or did not run during this sync (common). If present, it's format is of a [validation record](#validation_record)

##### Validation Record

A validation record is defined as:

| Field Name        | Data Type                                 | Description
| ------------------|-------------------------------------------|----------------------------------------------------------------------------------------------------------------
| version           | bigint                                    | Version of the validator used to get this data.
| checked           | bigint                                    | Number of records the validator checked in this engine.
| took              | bigint                                    | How long validation took for this engine.
| problems          | array(row(name varchar, count varchar))   | The problems identified. Problems with a count of 0 are excluded. Null on failure or if no problems occurred.
| failure\_reason   | row(name varchar, value varchar)          | Details of any errors recorded during the validation, or null if validation succeeded.

### FAQ

Q1: In **engines**, we have **status** and **failureReason**, how are
they different from the columns with the same names?

A1: These are the exceptions and status for the engine itself, whereas
the columns at the top-level of the table are for the entire sync. The
error handling should be cleaned up, but in general, **failureReason**
will be reporting bugs, whereas "status" is reporting when we explicitly
decided that we couldn't apply a record.

---

Q2: Do we only log the **engines** array when we see
"service":"error.sync.failed\_partial" in **status**?

A2: I don't think that's true - eg, "select \* from sync\_summary where
engines is not null and status is null limit 10" shows records.

---

Q3: What values are valid in the validation record's **name** field?

A3: It's up to the engine and to the client. For desktop bookmarks,
they're documented
[here](https://dxr.mozilla.org/mozilla-central/source/services/sync/modules/bookmark_validator.js)
(or
[here](https://dxr.mozilla.org/mozilla-central/rev/1d025ac534a6333a8170a59a95a8a3673d4028ee/services/sync/modules/bookmark_validator.js#27-68)
if that link breaks).

### Event Telemetry

Sync will often write "events" to telemetry. These are made available
via the sync\_events\_v1 table.

#### Table Description

| Field Names             | Data Type              | Description
| ------------------------|------------------------|-------------------------------------------------------------------------------------------------------
| document\_id            | varchar                | The document ID of the original ping this event is from.
| app\_build\_id          | varchar                | From the original ping
| app\_display\_version   | varchar                | From the original ping
| app\_name               | varchar                | From the original ping
| app\_version            | varchar                | From the original ping
| app\_channel            | varchar                | From the original ping
| uid                     | varchar                | From the original ping
| why                     | varchar                | From the original ping
| deviceId                | varchar                | From the original ping
| event\_timestamp        | bigint                 | Number of milliseconds since the process started when the event was created. (??)
| event\_category         | varchar                | Always the string "sync"
| event\_method           | varchar                | The type of action taken on the object
| event\_object           | varchar                | The type of object being acted on
| event\_string\_value    | varchar                | Additional data
| event\_map\_values      | map(varchar, varchar)  | Additional data specific to this event.
| event\_flow\_id         | varchar                | An ID used to identify a pair of commands which span multiple devices (todo: explain this!)
| event\_device\_id       | varchar                | If this event is being targeted at a different sync device, this is the ID of the target.
| event\_device\_version  | varchar                | If this event is being targeted at a different sync device, this is the Firefox version it is running.
| event\_device\_os       | varchar                | If this event is being targeted at a different sync device, this is the OS it is running
| submission\_date\_s3    | varchar                | The date this ping was submitted.

#### Event Usage

##### Commands sent between clients

Sometimes Sync will send a "command" from one device to another. The
most obvious example of this is "send tab". Event telemetry is recorded
both by the sending device and the receiving device.

In all cases, the sending device will create a unique "flowID" which
will appear in event\_flow\_id, and it will send this value as part of
the command. The device receiving the command will record this flow ID
in the event it creates - so both the sending and receiving device will
record the same flowID.

In all cases, the sending device will record in the event the ID of the
device that is to receive the command. However, the receiving device
does not record the device that sent the command.

The sending device will record: event\_object="sendcommand",
event\_method will be the specific command being sent (eg, "displayURI"
for sendTab).

The receiving device will record: event\_object="processcommand",
event\_method will be the command being sent.

##### Commands sent by the repair process

Bookmark repair is fairly chatty when it comes to events - both the
device initiating the repair and any other devices participating in the
repair process record events, and they all use the same flowID - so it
should be possible to reconstruct the repair process by looking for all
events with the same flow ID.

The general repair process is:

1.  One device finds problems and starts a repair. It emits an event
    event\_object="repair", event\_method="started".
2.  It then attempts to find other devices able to help with the repair
    - if it finds any, it will emit event\_object="repair",
    event\_method="request", event\_string\_value="upload", and includes
    the device ID of the device it wants to respond - and waits.
3.  Hopefully the other device will see the repair request. If it finds
    any objects it can upload, it will emit an event
    event\_object="repairResponse", event\_method="uploading".
4.  Once the upload is complete, it will write an event
    event\_object="repairResponse", event\_method="finished".
5.  If the repair responder fails for some reason, it will emit
    event\_object="repairResponse", event\_method="failed" or "aborted"
6.  If initial device that sent the repair request doesn't see a
    response from the other device it will emit event\_object="repair",
    event\_method="silent". If the other device disappears completely,
    it will write event\_object="repair", event\_method="missing".
7.  The initial device will then check to see if it is still missing
    items, and if so, attempt to find a new client. If it can, it jumps
    back to (2) above.
8.  The initial device will eventually run out of clients, or will find
    all of its IDs. At that time it will emit event\_object="repair",
    event\_method="finished" - or if it gives up due to some error it
    will emit event\_object="repair", event\_method="failed"

whew! So in summary:

-   every repair should emit event\_object="repair",
    event\_method="started" as it starts, and either
    event\_object="repair", event\_method="finished/failed" as the last
    event.
-   There may be any number of repairResponse events written (including
    zero events if there are no suitable devices). Each of these should
    result in a event\_object="repairResponse",
    event\_method="finished/aborted"

### Bookmark Validation Data Roll-ups

#### telemetry.sync\_bmk\_total\_per\_day

This table is a roll-up of all bookmark validations (success and
failures).

This table is useful to calculate rates in conjunction with the
*telemetry.sync\_bmk\_validation\_problems* table.

| Column name                   | Data format              | Description
| ------------------------------|--------------------------|------------------------------------------------------------------------------------------
| sync\_day                     | integer (e.g. 20170518)  | The day we ran validation on the user
| total\_bookmark\_validations  | integer                  | Number of times we ran bookmark validation per day. This includes successful validations.
| total\_validated\_users       | integer                  | Number of users we ran bookmark validation on for each day.
| total\_bookmarks\_checked     | integer                  | Number of bookmarks we checked for validation problems.
| run\_start\_date              | integer                  | Date we imported the data to Presto.

#### telemetry.sync\_bmk\_validation\_problems

This table has a row for every validation problem detected during
validation.

**Example:** If a user has 4 different validation problems, we will log
each problem in their own row.

**Logic used for format:** This choice was made to avoid having endless
amounts of columns representing each validation problem checked (which
would mostly all be null) and to avoid having to add columns as we
detect new types of validation problems.

| Field name                          | Data type                           | Description
| ------------------------------------|-------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
| app\_build\_id                      | varchar                             | Firefox build ID (e.g. 20160801085519)
| app\_version                        | varchar                             | Firefox version (e.g. 50.0a2) - corresponds to the MOZ\_APP\_VERSION configure value
| app\_display\_version               | varchar                             | The application version as shown in the about dialog. Almost always identical to app\_version. Corresponds to the MOZ\_APP\_VERSION\_DISPLAY configure value.
| app\_name                           | varchar                             | Will always be the string "Firefox" in desktop submitted pings.
| app\_channel                        | varchar                             | The update channel (e.g. "release", "nightly", etc) - corresponds to the MOZ\_UPDATE\_CHANNEL config variable.
| uid                                 | varchar                             | Hashed Sync/FxA ID
| deviceid                            | varchar                             | Hashed FxA device ID.
| submission\_day                     | integer                             | Date data was added to Presto (e.g. 20170324)
| sync\_day                           | integer                             | Date of sync. (e.g. 20170320)
| when                                | bigint                              | Unix timestamp of when sync occurred. Make sure to put in "quotes" since when is a reserved SQL word. Note that because this is taken from the client's clock, the time may be wildly inaccurate.
| status                              | row(sync varchar, service varchar)  | The status of sync after completion, or null is both statuses record success.
| engine\_name                        | varchar                             | Should always be **bookmarks** in this table.
| engine\_status                      | varchar                             | The status of this engine after sync completed, or null if the status reflects success.
| engine\_failure\_reason             | row(name varchar, value varchar)    | Details of any errors recorded during the sync of this engine, or null on success.
| engine\_has\_problems               | true/false                          | engine\_has\_problems is always going to be true in sync\_bmk\_validation\_problems. Used to filter results out of all\_engine\_validation\_results
| engine\_validation\_version         | integer                             | Version of the validator used to get this data.
| engine\_validation\_checked         | bigint                              | Number of records the validator checked in this engine.
| engine\_validation\_took            | bigint                              | How long validation took for this engine.
| engine\_validation\_problem\_name   | varchar                             | Name of error recorded during the validation. Will never be null since this table only includes validation problems.
| engine\_validation\_problem\_count  | integer                             | Number of bookmarks afflicted by the problem during the validation check.
| run\_start\_date                    | integer                             | Date added to presto. (e.g. 20170331)

### Query Examples

The example below demonstrates how to select data in JSON object.

```sql
WITH errors AS (
  SELECT
    failurereason.name AS name,
    failurereason.value AS value
  FROM sync_summary
  WHERE failurereason IS NOT NULL
)
SELECT
    name,
    COUNT(value)
FROM errors
GROUP BY name
```

The next example shows how to handle unix time stamps and how to use the
Redash date picker. It's important to either cast the date or to use
the type constructor like below or you won't be able to use any
operators on the date which is required for the date picker.

```sql
WITH syncs AS (
    SELECT
        /* convert date from unix timestamp */
        date_trunc('day', from_unixtime("when"/1000)) AS day,
        status.service AS service
    FROM
        sync_summary
)
SELECT day, status, volume
FROM (
  SELECT
    day,
    'success' as status,
    SUM(
      CASE
      WHEN service IS NULL THEN 1
      ELSE 0
      END
    ) AS volume
  FROM syncs
  GROUP BY day
  UNION ALL
  SELECT
    day,
    'failed' as status,
    SUM(
      CASE
      WHEN service IS NOT NULL THEN 1
      ELSE 0
      END
    ) AS volume
  FROM syncs
  GROUP BY day
)
/* date picker */
WHERE day >= timestamp '{{start_date}}' AND day <= timestamp '{{end_date}}'

GROUP BY 1,2,3
ORDER BY 1,2,3
```

This example is how you would unpack the engines array into it's own
table to then query:

```sql
WITH engine_errors AS (
  SELECT
    uid,
    date_trunc('day', from_unixtime("when"/1000)) AS date,
    engine
  FROM sync_summary
/* The CROSS JOIN UNNEST will join the array to each row */
  CROSS JOIN UNNEST(engines) AS t (engine)
  --LIMIT 1000000
)
SELECT
    engine.name AS engine_name,
    SUM(
      CASE
      WHEN engine.failureReason IS NOT NULL THEN 1
      ELSE 0
      END
    ) AS errors
FROM engine_errors
WHERE date >= timestamp '{{start_date}}' AND date <= timestamp '{{end_date}}'
GROUP BY engine.name
```
