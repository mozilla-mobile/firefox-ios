# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import absolute_import, print_function, unicode_literals

from taskgraph.target_tasks import _target_task, filter_for_tasks_for


@_target_task('l10n_screenshots')
def target_tasks_default(full_task_graph, parameters, graph_config):
    """Target the tasks which have indicated they should be run on this project
    via the `run_on_projects` attributes."""
    def filter(task, parameters):
        return task.kind == "generate-screenshots"

    return [l for l, t in full_task_graph.tasks.iteritems() if filter(t, parameters)]
