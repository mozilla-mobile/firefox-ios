from taskgraph.transforms.base import TransformSequence
from taskgraph.util.schema import resolve_keyed_by


transforms = TransformSequence()

@transforms.add
def resolve_keyed_by_build_type(config, tasks):
    for task in tasks:
        resolve_keyed_by(task, 'treeherder.symbol', task["name"], **{'build-type': task['attributes']['build-type']})
        build_type = task["attributes"]["build-type"]

        for workflow in task["worker"]["bitrise"]["workflows"]:
            for params in workflow.values():
                params.append({"BUILD_TASK_ID": {"task-reference": f"<promote-{build_type}>"}})

        yield task
