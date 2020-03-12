# New Subscription
```rust
let storage = Storage.connect();
let new_sub = Subscription.get_subscription(
    storage,
    origin_attributes,
    app_server_key,
    privileged) {
    let con = Connection.new();
    let uaid = conn.get_uaid();
    let chid = generate_channel_id();
    if let Some(endpoint_data) = con.subscribe(chid, None, privileged) {
        // start PushRecord
        let private_key = Crypto.generate_key();
        // build and store the PushRecord
        storage.create_record(
            uaid: &uaid,
            chid: &chid,
            origin_attributes: &origin_attributes,
            endpoint: endpoint_data.endpoint,
            auth: endpoint_data.auth,
            private_key: &private_key,
            system_record: privileged
        );
        // return the subscription info to the caller.
        Subscription {
            channelid = chid,
            endpoint = endpoint_data.endpoint;
            keys: SubscriptionKeys{
                p256dh: private_key.public(),
                auth: private_key.auth()
            }
        }
}
```

# process incoming notification
```rust

Notifier.process_notification(notification: Notification) {
    let storage = Storage.connect();
    let dman = DeliveryManager.new(storage);
    if ! dman.is_system(&notification.chid) {
        if ! dman.check_quota(&notification.chid) {
            //reject over quota
        }
    }
    let uaid = Connection::get_uaid();
    // get the pushrecord from storage.
    if let Some(pr) = storage.get_record(uaid, notification.channel_id) {
        let content = if ! pr.system_record {
            push_crypto::decrypt(notification);
        } else {
            notification.body
        };

        dman.dispatch(&notification.chid, content);
        return;
    }
    //TODO: Raise errors, etc.
}
