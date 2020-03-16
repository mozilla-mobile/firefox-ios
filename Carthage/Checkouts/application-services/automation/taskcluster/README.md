# Testing Application Services on Taskcluster

## Taskcluster − GitHub integration

Taskcluster is very flexible and not necessarily tied to GitHub,
but it does have an optional [GitHub integration service] that you can enable
on a repository [as a GitHub App].
When enabled, this service gets notified for every push, pull request, or GitHub release.
It then schedules some tasks based on reading [`.taskcluster.yml`] in the corresponding commit.

This file contains templates for creating one or more tasks,
but the logic it can support is fairly limited.
So a common pattern is to have it only run a single initial task called a *decision task*
that can have complex logic based on code and data in the repository
to build an arbitrary [task graph].

[GitHub integration service]: https://docs.taskcluster.net/docs/manual/using/github
[as a GitHub App]: https://github.com/apps/taskcluster
[`.taskcluster.yml`]: https://docs.taskcluster.net/docs/reference/integrations/taskcluster-github/docs/taskcluster-yml-v1
[task graph]: https://docs.taskcluster.net/docs/manual/using/task-graph


## Application Service’s decision task

This repository’s [`.taskcluster.yml`][tc.yml] schedules a single task
that runs the Python 3 script [`etc/taskcluster/decision_task.py`](decision_task.py).
It is called a *decision task* as it is responsible for deciding what other tasks to schedule.

The Docker image that runs the decision task
is hosted on Docker Hub at [`servobrowser/taskcluster-bootstrap`][hub].
It is built by [Docker Hub automated builds] based on a `Dockerfile`
in the [`taskcluster-bootstrap-docker-images`] GitHub repository.
Hopefully, this image does not need to be modified often
as it only needs to clone the repository and run Python.

[tc.yml]: ../../.taskcluster.yml
[hub]: https://hub.docker.com/r/servobrowser/taskcluster-bootstrap/
[Docker Hub automated builds]: https://docs.docker.com/docker-hub/builds/
[`taskcluster-bootstrap-docker-images`]: https://github.com/servo/taskcluster-bootstrap-docker-images/


## In-tree Docker images

[Similar to Firefox][firefox], Application Service’s decision task supports running other tasks in
Docker images built on-demand, based on `Dockerfile`s in the main repository.  Modifying a
`Dockerfile` and relying on those new changes can be done in the same pull request or commit.

To avoid rebuilding images on every pull request,
they are cached based on a hash of the source `Dockerfile`.
For now, to support this hashing, we make `Dockerfile`s be self-contained (with one exception).
Images are built without a [context],
so instructions like [`COPY`] cannot be used because there is nothing to copy from.
The exception is that the decision task adds support for a non-standard include directive:
when a `Dockerfile` first line is `% include` followed by a filename,
that line is replaced with the content of that file.

For example,
[`automation/taskcluster/docker/build.dockerfile`](docker/build.dockerfile) starts like so:

```Dockerfile
% include base.dockerfile

RUN \
    apt-get install -qy --no-install-recommends \
# […]
```

[firefox]: https://firefox-source-docs.mozilla.org/taskcluster/taskcluster/docker-images.html
[context]: https://docs.docker.com/engine/reference/commandline/build/#extended-description
[`COPY`]: https://docs.docker.com/engine/reference/builder/#copy


## Build artifacts

On Taskcluster with a decision task,
we can have a single build task save its resulting binary executable as an [artifact],
together with multiple testing tasks that each depend on the build task
(wait until it successfully finishes before they can start)
and start by downloading the artifact that was saved earlier.

The logic for all this is in [`decision_task.py`](decision_task.py)
and can be modified in any pull request.

[artifact]: https://docs.taskcluster.net/docs/manual/using/artifacts


## Log artifacts

Taskcluster automatically save the `stdio` output of a task as an artifact,
and as special support for seeing and streaming that output while the task is still running.


## Self-service, Bugzilla, and IRC

Taskcluster is designed to be “self-service” as much as possible,
with features like in-tree `.taskcluster.yml`
or the web UI for modifying the worker type definitions.
However some changes like adding a new worker type still require Taskcluster admin access.
For those, file requests on Bugzilla under [Taskcluster :: Service Request][req].

For asking for help less formally, try the `#app-services` or `#rust-components` channels on Mozilla Slack.

[req]: https://bugzilla.mozilla.org/enter_bug.cgi?product=Taskcluster&component=Service%20Request


## Configuration recap

We try to keep as much as possible of our Taskcluster configuration in this repository.
To modify those, submit a pull request.

* The [`.taskcluster.yml`][tc.yml] file,
  for starting decision tasks in reaction to GitHub events
* The [`automation/taskcluster/decision_task.py`](decision_task.py) file,
  defining what other tasks to schedule
