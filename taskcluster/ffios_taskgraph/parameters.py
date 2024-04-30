# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os

from taskgraph.parameters import extend_parameters_schema
from taskgraph.util.vcs import get_repository
from voluptuous import All, Any, Range, Required


def get_defaults(repo_root):
    return {
        "commit_message": "",
        "pull_request_number": None,
    }


extend_parameters_schema(
    {
        Required("commit_message"): str,
        Required("pull_request_number"): Any(All(int, Range(min=1)), None),
    },
    defaults_fn=get_defaults,
)


def get_decision_parameters(graph_config, parameters):
    repo = get_repository(os.getcwd())
    parameters["commit_message"] = repo.get_commit_message()

    pr_number = os.environ.get("MOBILE_PULL_REQUEST_NUMBER", None)
    if pr_number:
        pr_number = int(pr_number)
    parameters["pull_request_number"] = pr_number

