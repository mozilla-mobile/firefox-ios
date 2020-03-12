# How we manage transactions (aka, how we avoid `SQLITE_BUSY`)

We use sqlite in `wal` mode. Thus we never expect readers to block or have any locking considerations. Multiple writers will always cause contention, possibly resulting in `SQLITE_BUSY`, and need to be managed.

Note that multiple writers will only cause `SQLITE_BUSY` after some timeout period has expired. Each writer will block for this timeout period in the hope that the other writer completes and it can begin. The current default is 5 seconds.
    
So there are 2 sane options:

* Ensure there's only ever one writer at a time (eg, via a dedicated writer thread) - `SQLITE_BUSY` will never happen, although writing will be queued - a single writer which takes many seconds will block all other writes. This may cause UX issues (eg, visited links not being immediately correct) and given mobile constraints, may never be writen at all (eg, aggressive app termination)

* Allow multiple writers. If you keep the writes short and fast, you should never hit the timeout period and everything should be fine. However, this scenario *does* allow for `SQLITE_BUSY` errors.
    
Complicating things is that transactions are not only about integrity, they also improve performance. Consider our history-sync "incoming" implementation - when processing 5k records, we can see a performance improvement of around 5x by using a single transaction for all records vs a transaction per record. We can choose between a fast sync with a long-lived transactions that might exceed our timeout budget, or a slow sync with many short transactions that will be within budget.

But in this scenario there are no "integrity" concerns, just performance. And sadly, it's not really possible to "split" a sync up so that it can be interleaved on a single writer thread - ie, once a sync starts, it needs to complete - and much of the time taken for a sync is on the network - it would probably not be workable for sync to block the only writer thread while it makes network requests.

This leaves us with a dilemma:

* If we use a single writer thread we would use a single-transaction for sync - but even this leaves writes blocked for a very long time (and includes time on the network). ie, writes may have *very* high latency, may never complete if the app is terminated - but would never experience `SQLITE_BUSY`.

* If we allowed multiple writer threads, we would use a transaction-per-record for sync, meaning both threads would almost certainly complete in their timeout budget - although the sync would take many many minutes to complete.

So we've come up with a compromise: we use 2 writer threads, but:

* One is dedicated to the small and fast writes (eg, a visit, creation of a bookmark, etc).

* One is dedicated to Sync, but it uses a strategy whereby we use these "performance transactions", but only for a set period of time. For example, when processing 5k records, we use one transaction per (say) 1000ms. We squeeze as many of the 5k records as we can into this time period and commit and start a new transaction as necessary.
    
This means that the other "small and fast" writer is never blocked for more than this period. This thread should never see a timeout due to this "chunking" technique - we do our best to ensure the sync writer never holds a transaction over this period.

However, this *will* still result in `SQLITE_BUSY` being possible. The 2 scenarios are:

* One of our "small and fast" writes isn't as small and fast as we expect - the sync writer will see `SQLITE_BUSY`. This generally isn't an actual problem - it's "just" a failed sync and the next sync might work fine.

* Even with our "1000ms transaction budget", some other sync transactions still end up taking more than our timeout. This will result in one of the "small and fast" writes failing. Without building a retry queue, we may need to accept this data-loss - but we should work out strategies for understanding how often it happens.
