# -*- coding: utf-8 -*-

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

"""
Classes for managing the description of pings.
"""

import sys
from typing import Dict, List, Optional


from . import util


# Import a backport of PEP487 to support __init_subclass__
if sys.version_info < (3, 6):
    import pep487  # type: ignore

    base_object = pep487.PEP487Object  # type: ignore
else:
    base_object = object


RESERVED_PING_NAMES = ["baseline", "metrics", "events", "deletion_request"]


class Ping(base_object):  # type: ignore
    def __init__(
        self,
        name: str,
        description: str,
        bugs: List[str],
        notification_emails: List[str],
        data_reviews: Optional[List[str]] = None,
        include_client_id: bool = False,
        send_if_empty: bool = False,
        reasons: Dict[str, str] = None,
        _validated: bool = False,
    ):
        # Avoid cyclical import
        from . import parser

        self.name = name
        self.description = description
        self.bugs = bugs
        self.notification_emails = notification_emails
        if data_reviews is None:
            data_reviews = []
        self.data_reviews = data_reviews
        self.include_client_id = include_client_id
        self.send_if_empty = send_if_empty
        if reasons is None:
            reasons = {}
        self.reasons = reasons

        # _validated indicates whether this metric has already been jsonschema
        # validated (but not any of the Python-level validation).
        if not _validated:
            data = {
                "$schema": parser.PINGS_ID,
                self.name: self.serialize(),
            }  # type: Dict[str, util.JSONType]
            for error in parser.validate(data):
                raise ValueError(error)

    _generate_enums = [("reason_codes", "ReasonCodes")]

    @property
    def type(self) -> str:
        return "ping"

    @property
    def reason_codes(self) -> List[str]:
        return sorted(list(self.reasons.keys()))

    def serialize(self) -> Dict[str, util.JSONType]:
        """
        Serialize the metric back to JSON object model.
        """
        d = self.__dict__.copy()
        del d["name"]
        return d
