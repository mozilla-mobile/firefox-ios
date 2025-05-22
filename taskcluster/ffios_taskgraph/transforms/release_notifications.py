# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import resolve_keyed_by

transforms = TransformSequence()

@transforms.add
def build_notifications(config, tasks):
    for task in tasks:
        resolve_keyed_by(task, "notifications.emails", item_name=task["name"], level=config.params["level"])

        notifications = task.pop("notifications", None)
        if not notifications:
            continue

        emails = notifications["emails"]
        if not emails:
            continue

        subject = notifications["subject"].format(**config.params)
        message = notifications["message"].format(**config.params)

        task.setdefault("routes", []).extend((f"notify.email.{email}.on-completed" for email in emails))
        task.setdefault("extra", {}).update({
            "notify": {
                "email": {
                    "subject": subject,
                    "content": message,
                }
            }
        })

        yield task
