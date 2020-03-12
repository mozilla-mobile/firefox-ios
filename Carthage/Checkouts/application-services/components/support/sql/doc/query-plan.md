# Getting query plans out of places/logins/other consumers.

If these crates are built with the `log_query_plans` feature enabled (or cargo decides to use a version of `sql-support` that has beeen built with that feature), then queries that go through sql-support will have their [query plans](https://www.sqlite.org/eqp.html) logged. The default place they get logged is stdout, however you can also specify a file by setting the `QUERY_PLAN_LOG` variable in the environment to a file where the plans will be appended.

Worth noting that new logs will be appended to `QUERY_PLAN_LOG`, we don't clear the file. This is so that you can more easily see how the query plan changed during testing.

The queries that go through this are any that are

1. Executed entirely within sql-support (we need both the query and it's parameters)
2. Take named (and not positional) parameters.

At the time of writing this, that includes:

- `try_query_row`
- `query_rows_and_then_named_cached`
- `query_rows_and_then_named`
- `query_row_and_then_named`
- `query_one`
- `execute_named_cached`
- Possibly more, check [ConnExt](https://github.com/mozilla/application-services/blob/master/components/support/sql/src/conn_ext.rs).

In particular, this excludes queries where the statement is prepared separately from execution.

## Usage

As mentioned, this is turned on with the log_query_plans feature. I don't know why, but I've had mediocre luck enabling it explicitly, but 100% success enabling it via `--all-features`. So that's what I recommend.

Note that for tests, if you're logging to stdout, you'll need to end the test command with `-- --no-capture`, or else it will hide stdout output from you. You also may want to pass `--test-threads 1` (also after the `--`) so that the plans are logged near the tests that are executing, but it doesn't matter that much, since we log the SQL before the plan.


Executing tests, having the output logged to stdout:

```
$ cargo test -p logins --all-features -- --no-capture
... <snip>
test engine::test::test_general ...
### QUERY PLAN
#### SQL:
      SELECT <bunch of fields here>
      FROM loginsL
      WHERE is_deleted = 0
        AND guid = :guid
      UNION ALL
      SELECT <same bunch of fields here>
      FROM loginsM
      WHERE is_overridden IS NOT 1
        AND guid = :guid
      ORDER BY hostname ASC
      LIMIT 1

#### PLAN:
QUERY PLAN
`--MERGE (UNION ALL)
   |--LEFT
   |  `--SEARCH TABLE loginsL USING INDEX sqlite_autoindex_loginsL_1 (guid=?)
   `--RIGHT
      `--SEARCH TABLE loginsM USING INDEX sqlite_autoindex_loginsM_1 (guid=?)
### END QUERY PLAN
... <snip>
```

Executing an example, with the output logged to a file.

```
$ env QUERY_PLAN_LOG=/path/to/my/logfile.txt cargo run -p places --all-features --example autocomplete -- <args for example go here>
# (many shells can also do this as follows)
$ QUERY_PLAN_LOG=/path/to/my/logfile.txt cargo run -p places --all-features --example autocomplete -- <args for example go here>
```

## Using from code

This is also available as types on `sql_support`.

```rust
println!("This prints the same output as is normally logged, and works \
          even when the logging feature is off: {}",
         sql_support:QueryPlan::new(conn, sql, params));
```

