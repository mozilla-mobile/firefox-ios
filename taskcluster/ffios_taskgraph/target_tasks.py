# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from taskgraph.target_tasks import register_target_task


@register_target_task('l10n_screenshots')
def target_tasks_default(full_task_graph, parameters, graph_config):
    """Target the tasks which have indicated they should be run on this project
    via the `run_on_projects` attributes."""
    def filter(task, parameters):
        return task.kind == "generate-screenshots"

    return [l for l, t in full_task_graph.tasks.items() if filter(t, parameters)]

@register_target_task('bitrise_performance_test')
def target_tasks_default(full_task_graph, parameters, graph_config):
    """Target the tasks which have indicated they should be run on this project
    via the `run_on_projects` attributes."""
    def filter(task, parameters):
        return task.kind == "bitrise-performance"

    return [l for l, t in full_task_graph.tasks.items() if filter(t, parameters)]

@register_target_task('firebase_performance_test')
def target_tasks_default(full_task_graph, parameters, graph_config):
    """Target the tasks which have indicated they should be run on this project
    via the `run_on_projects` attributes."""
    def filter(task, parameters):
        return task.kind == "firebase-performance"

    return [l for l, t in full_task_graph.tasks.items() if filter(t, parameters)]

@register_target_task("promote")
def target_tasks_promote(full_task_graph, parameters, graph_config):
    return _filter_release_promotion(
        full_task_graph,
        parameters,
        filtered_for_candidates=[],
        shipping_phase="promote",
    )
def does_task_match_release_type(task, release_type):
    return task.attributes.get("release-type") == release_type

def _filter_release_promotion(
    full_task_graph, parameters, filtered_for_candidates, shipping_phase
):
    def filter(task, parameters):
        # Include promotion tasks; these will be optimized out
        if task.label in filtered_for_candidates:
            return True

        return task.attributes.get(
            "shipping_phase"
        ) == shipping_phase and does_task_match_release_type(
            task, parameters["release_type"]
        )

    return [l for l, t in full_task_graph.tasks.items() if filter(t, parameters)]
