# coding: utf8

# Copyright 2018 The Servo Project Developers. See the COPYRIGHT
# file at the top-level directory of this distribution.
#
# Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
# <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
# option. This file may not be copied, modified, or distributed
# except according to those terms.

"""
Project-independent library for Taskcluster decision tasks
"""

import base64
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
from typing import List

import taskcluster


# Public API
__all__ = [
    "CONFIG", "SHARED",
    "Task", "DockerWorkerTask", "BeetmoverTask",
    "build_full_task_graph", "populate_chain_of_trust_required_but_unused_files",
    "populate_chain_of_trust_task_graph",
]


class Config:
    """
    Global configuration, for users of the library to modify.
    """
    def __init__(self):
        self.task_name_template = "%s"
        self.index_prefix = "garbage.application-services-decisionlib"
        self.scopes_for_all_subtasks = []
        self.routes_for_all_subtasks = []
        self.docker_images_expire_in = "1 month"
        self.repacked_msi_files_expire_in = "1 month"

        # Set by docker-worker:
        # https://docs.taskcluster.net/docs/reference/workers/docker-worker/docs/environment
        self.decision_task_id = os.environ.get("TASK_ID")

        # Set in the decision task’s payload, such as defined in .taskcluster.yml
        self.task_owner = os.environ.get("TASK_OWNER")
        self.task_source = os.environ.get("TASK_SOURCE")
        self.build_worker_type = os.environ.get("BUILD_WORKER_TYPE")
        self.images_worker_type = os.environ.get("IMAGES_WORKER_TYPE")
        self.git_url = os.environ.get("APPSERVICES_HEAD_REPOSITORY")
        self.git_ref = os.environ.get("APPSERVICES_HEAD_BRANCH")
        self.git_sha = os.environ.get("APPSERVICES_HEAD_REV")

        # Map directory string to git sha for that directory.
        self._git_sha_for_directory = {}

    def git_sha_is_current_head(self):
        output = subprocess.check_output(["git", "rev-parse", "HEAD"])
        self.git_sha = output.decode("utf8").strip()

    def git_sha_for_directory(self, directory):
        try:
            return self._git_sha_for_directory[directory]
        except KeyError:
            output = subprocess.check_output(["git", "rev-parse", "HEAD:{}".format(directory)])
            sha = output.decode("utf8").strip()
            self._git_sha_for_directory[directory] = sha
            return sha


class Shared:
    """
    Global shared state.
    """
    def __init__(self):
        self.now = datetime.datetime.utcnow()
        self.tasks_cache = {}
        self.found_or_created_indexed_tasks = {}
        self.all_tasks = []

        # taskclusterProxy URLs:
        # https://docs.taskcluster.net/docs/reference/workers/docker-worker/docs/features
        self.queue_service = taskcluster.Queue(options={"baseUrl": "http://taskcluster/queue/v1/"})
        self.index_service = taskcluster.Index(options={"baseUrl": "http://taskcluster/index/v1/"})

    def from_now_json(self, offset):
        """
        Same as `taskcluster.fromNowJSON`, but uses the creation time of `self` for “now”.
        """
        return taskcluster.stringDate(taskcluster.fromNow(offset, dateObj=self.now))

    def schedule_task(self, taskId, taskDefinition):
        # print(json.dumps(taskDefinition, indent=4, separators=(',', ': ')))
        self.queue_service.createTask(taskId, taskDefinition)
        print("Scheduled %s" % taskDefinition['metadata']['name'])
        self.all_tasks.append(taskId)

    def build_task_graph(self):
        full_task_graph = {}

        # TODO: Switch to async python to speed up submission
        for task_id in self.all_tasks:
            full_task_graph[task_id] = {
                'task': SHARED.queue_service.task(task_id),
            }
        return full_task_graph

CONFIG = Config()
SHARED = Shared()

def chaining(op, attr):
    def method(self, *args, **kwargs):
        op(self, attr, *args, **kwargs)
        return self
    return method


def append_to_attr(self, attr, *args): getattr(self, attr).extend(args)
def prepend_to_attr(self, attr, *args): getattr(self, attr)[0:0] = list(args)
def update_attr(self, attr, **kwargs): getattr(self, attr).update(kwargs)

def build_full_task_graph():
    return SHARED.build_task_graph()

class Task:
    """
    A task definition, waiting to be created.

    Typical is to use chain the `with_*` methods to set or extend this object’s attributes,
    then call the `create` or `find_or_create` method to schedule a task.

    This is an abstract class that needs to be specialized for different worker implementations.
    """
    def __init__(self, name):
        self.name = name
        self.description = ""
        self.scheduler_id = os.environ.get("SCHEDULER_ID")
        self.provisioner_id = os.environ.get("PROVISIONER_ID")
        self.worker_type = os.environ.get("BUILD_WORKER_TYPE")
        self.deadline_in = "1 day"
        self.expires_in = "1 year"
        self.index_and_artifacts_expire_in = self.expires_in
        self.dependencies = []
        self.scopes = []
        self.routes = []
        self.extra = {}

    # All `with_*` methods return `self`, so multiple method calls can be chained.
    with_description = chaining(setattr, "description")
    with_scheduler_id = chaining(setattr, "scheduler_id")
    with_provisioner_id = chaining(setattr, "provisioner_id")
    with_worker_type = chaining(setattr, "worker_type")
    with_deadline_in = chaining(setattr, "deadline_in")
    with_expires_in = chaining(setattr, "expires_in")
    with_index_and_artifacts_expire_in = chaining(setattr, "index_and_artifacts_expire_in")

    with_dependencies = chaining(append_to_attr, "dependencies")
    with_scopes = chaining(append_to_attr, "scopes")
    with_routes = chaining(append_to_attr, "routes")

    with_extra = chaining(update_attr, "extra")

    def build_worker_payload(self):  # pragma: no cover
        """
        Overridden by sub-classes to return a dictionary in a worker-specific format,
        which is used as the `payload` property in a task definition request
        passed to the Queue’s `createTask` API.

        <https://docs.taskcluster.net/docs/reference/platform/taskcluster-queue/references/api#createTask>
        """
        raise NotImplementedError

    def create(self):
        """
        Call the Queue’s `createTask` API to schedule a new task, and return its ID.

        <https://docs.taskcluster.net/docs/reference/platform/taskcluster-queue/references/api#createTask>
        """
        worker_payload = self.build_worker_payload()

        assert CONFIG.decision_task_id
        assert CONFIG.task_owner
        assert CONFIG.task_source
        queue_payload = {
            "taskGroupId": CONFIG.decision_task_id,
            "dependencies": [CONFIG.decision_task_id] + self.dependencies,
            "schedulerId": self.scheduler_id,
            "provisionerId": self.provisioner_id,
            "workerType": self.worker_type,

            "created": SHARED.from_now_json(""),
            "deadline": SHARED.from_now_json(self.deadline_in),
            "expires": SHARED.from_now_json(self.expires_in),
            "metadata": {
                "name": CONFIG.task_name_template % self.name,
                "description": self.description,
                "owner": CONFIG.task_owner,
                "source": CONFIG.task_source,
            },

            "payload": worker_payload,
        }
        scopes = self.scopes + CONFIG.scopes_for_all_subtasks
        routes = self.routes + CONFIG.routes_for_all_subtasks
        if any(r.startswith("index.") for r in routes):
            self.extra.setdefault("index", {})["expires"] = \
                SHARED.from_now_json(self.index_and_artifacts_expire_in)

        dict_update_if_truthy(
            queue_payload,
            scopes=scopes,
            routes=routes,
            extra=self.extra,
        )

        task_id = taskcluster.slugId().decode("utf8")
        SHARED.schedule_task(task_id, queue_payload)
        return task_id

    def find_or_create(self, index_path=None):
        """
        Try to find a task in the Index and return its ID.

        The index path used is `{CONFIG.index_prefix}.{index_path}`.
        `index_path` defaults to `by-task-definition.{sha256}`
        with a hash of the worker payload and worker type.

        If no task is found in the index,
        it is created with a route to add it to the index at that same path if it succeeds.

        <https://docs.taskcluster.net/docs/reference/core/taskcluster-index/references/api#findTask>
        """
        if not index_path:
            worker_type = self.worker_type
            index_by = json.dumps([worker_type, self.build_worker_payload()]).encode("utf-8")
            index_path = "by-task-definition." + hashlib.sha256(index_by).hexdigest()
        index_path = "%s.%s" % (CONFIG.index_prefix, index_path)

        task_id = SHARED.found_or_created_indexed_tasks.get(index_path)
        if task_id is not None:
            return task_id

        try:
            task_id = SHARED.index_service.findTask(index_path)["taskId"]
            SHARED.all_tasks.append(task_id)
        except taskcluster.TaskclusterRestFailure as e:
            if e.status_code != 404:  # pragma: no cover
                raise
            self.routes.append("index." + index_path)
            task_id = self.create()

        SHARED.found_or_created_indexed_tasks[index_path] = task_id
        return task_id

    def reuse_or_create(self, cache_id=None):
        """
        See if we can re-use a task with the same cache_id or
        create a new one, this is similar as `find_or_create`
        except that the scope of this function is limited to
        its execution since nothing is persisted.
        """
        task_id = SHARED.tasks_cache.get(cache_id)
        if task_id is not None:
            return task_id
        task_id = self.create()
        SHARED.tasks_cache[cache_id] = task_id
        return task_id

class BeetmoverTask(Task):
    def __init__(self, name):
        super().__init__(name)
        self.provisioner_id = "scriptworker-k8s"
        self.app_name = None
        self.app_version = None
        self.upstream_artifacts = []
        self.artifact_map = []

    with_app_name = chaining(setattr, "app_name")
    with_app_version = chaining(setattr, "app_version")
    with_upstream_artifact = chaining(append_to_attr, "upstream_artifacts")
    with_artifact_map = chaining(setattr, "artifact_map")

    def build_worker_payload(self):
        payload = {
            "maxRunTime": 10 * 60,
            "releaseProperties": {
                "appName": self.app_name,
            },
            "upstreamArtifacts": self.upstream_artifacts,
            "artifactMap": self.artifact_map,
            "version": self.app_version,
        }

        return payload


class SignTask(Task):
    def __init__(self, name):
        super().__init__(name)
        self.provisioner_id = "scriptworker-k8s"
        self.upstream_artifacts = []

    with_upstream_artifact = chaining(append_to_attr, "upstream_artifacts")

    def build_worker_payload(self):
        payload = {
            "maxRunTime": 10 * 60,
            "upstreamArtifacts": self.upstream_artifacts,
        }

        return payload


class DockerWorkerArtifact:
    def __init__(self, worker_fs_path, taskcluster_path):
        self.worker_fs_path = worker_fs_path
        self.taskcluster_path = taskcluster_path


class DockerWorkerTask(Task):
    """
    Task definition for a worker type that runs the `generic-worker` implementation.

    Scripts are interpreted with `bash`.

    <https://github.com/taskcluster/docker-worker>
    """

    artifacts: List[DockerWorkerArtifact]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # We use this specific version because our decision task also runs on this one.
        # We also use that same version in docker/build.dockerfile
        self.docker_image = "ubuntu:bionic-20180821"
        self.max_run_time_minutes = 30
        self.scripts = []
        self.env = {}
        self.caches = {}
        self.features = {}
        self.artifacts = []

    with_docker_image = chaining(setattr, "docker_image")
    with_max_run_time_minutes = chaining(setattr, "max_run_time_minutes")
    with_script = chaining(append_to_attr, "scripts")
    with_early_script = chaining(prepend_to_attr, "scripts")
    with_caches = chaining(update_attr, "caches")
    with_env = chaining(update_attr, "env")

    def with_artifacts(self, worker_fs_path, taskcluster_path=None):
        """Adds artifact to task definition

        Args:
            worker_fs_path: path to artifact on worker
            taskcluster_path: as represented on taskcluster. Defaults to "public/{the url basename of worker_path}"

        Returns:

        """
        self.artifacts.append(DockerWorkerArtifact(
            worker_fs_path,
            taskcluster_path or "public/" + url_basename(worker_fs_path)
        ))
        return self

    def build_worker_payload(self):
        """
        Return a `docker-worker` worker payload.

        <https://docs.taskcluster.net/docs/reference/workers/docker-worker/docs/payload>
        """
        worker_payload = {
            "image": self.docker_image,
            "maxRunTime": self.max_run_time_minutes * 60,
            "command": [
                "/bin/bash", "--login", "-x", "-e", "-c",
                deindent("\n".join(self.scripts))
            ],
        }
        if self.features.get("chainOfTrust"):
            if isinstance(self.docker_image, dict):
                cot = self.extra.setdefault("chainOfTrust", {})
                cot.setdefault('inputs', {})['docker-image'] = self.docker_image['taskId']
        return dict_update_if_truthy(
            worker_payload,
            env=self.env,
            cache=self.caches,
            features=self.features,
            artifacts={
                artifact.taskcluster_path: {
                    "type": "file",
                    "path": artifact.worker_fs_path,
                    "expires": SHARED.from_now_json(self.index_and_artifacts_expire_in),
                }
                for artifact in self.artifacts
            },
        )

    def with_features(self, *names):
        """
        Enable the give `docker-worker` features.

        <https://docs.taskcluster.net/docs/reference/workers/docker-worker/docs/features>
        """
        self.features.update({name: True for name in names})
        return self

    def with_curl_script(self, url, file_path):
        return self \
        .with_script("""
            mkdir -p $(dirname {file_path})
            curl -sfSL --retry 5 --retry-delay 10 --connect-timeout 10 {url} -o {file_path}
        """.format(url=url, file_path=file_path))

    def with_curl_artifact_script(self, task_id, artifact_name, out_directory=""):
        return self \
        .with_dependencies(task_id) \
        .with_curl_script(
            "https://firefox-ci-tc.services.mozilla.com/api/queue/v1/task/%s/artifacts/public/%s"
                % (task_id, artifact_name),
            os.path.join(out_directory, url_basename(artifact_name)),
        )

    def with_repo(self):
        """
        Make a shallow clone the git repository at the start of the task.
        This uses `CONFIG.git_url`, `CONFIG.git_ref`, and `CONFIG.git_sha`,
        and creates the clone in a `/repo` directory
        at the root of the Docker container’s filesystem.

        `git` and `ca-certificate` need to be installed in the Docker image.
        """
        return self \
        .with_env(**git_env()) \
        .with_early_script("""
            cd repo
            git fetch --quiet --tags "$APPSERVICES_HEAD_REPOSITORY" "$APPSERVICES_HEAD_BRANCH"
            git reset --hard "$APPSERVICES_HEAD_REV"
        """)

    def with_dockerfile(self, dockerfile, use_indexed_task=True):
        """
        Build a Docker image based on the given `Dockerfile`, and use it for this task.

        `dockerfile` is a path in the filesystem where this code is running.
        Some non-standard syntax is supported, see `expand_dockerfile`.

        The image is indexed based on a hash of the expanded `Dockerfile`,
        and cached for `CONFIG.docker_images_expire_in`.

        Images are built without any *context*.
        <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#understand-build-context>
        """
        basename = os.path.basename(dockerfile)
        suffix = ".dockerfile"
        assert basename.endswith(suffix)
        image_name = basename[:-len(suffix)]

        dockerfile_contents = expand_dockerfile(dockerfile)
        digest = hashlib.sha256(dockerfile_contents).hexdigest()

        image_build_task = (
            DockerWorkerTask("Docker image: " + image_name)
            .with_worker_type(CONFIG.images_worker_type)
            .with_max_run_time_minutes(30)
            .with_index_and_artifacts_expire_in(CONFIG.docker_images_expire_in)
            .with_features("dind")
            .with_env(DOCKERFILE=dockerfile_contents)
            .with_artifacts("/image.tar.lz4")
            .with_script("""
                echo "$DOCKERFILE" | docker build -t taskcluster-built -
                docker save taskcluster-built | lz4 > /image.tar.lz4
            """)
            .with_docker_image(
                # https://github.com/servo/taskcluster-bootstrap-docker-images#image-builder
                "servobrowser/taskcluster-bootstrap:image-builder@sha256:" \
                "0a7d012ce444d62ffb9e7f06f0c52fedc24b68c2060711b313263367f7272d9d"
            )
        )
        if self.features.get("chainOfTrust"):
            image_build_task.with_features("chainOfTrust")
        task_index = "appservices-docker-image." + digest
        if use_indexed_task:
            image_build_task_id = image_build_task.find_or_create(task_index)
        else:
            image_build_task_id = image_build_task.reuse_or_create(task_index)

        return self \
        .with_dependencies(image_build_task_id) \
        .with_docker_image({
            "type": "task-image",
            "path": "public/image.tar.lz4",
            "taskId": image_build_task_id,
        })


def expand_dockerfile(dockerfile):
    """
    Read the file at path `dockerfile`,
    and transitively expand the non-standard `% include` header if it is present.
    """
    with open(dockerfile, "rb") as f:
        dockerfile_contents = f.read()

    include_marker = b"% include"
    if not dockerfile_contents.startswith(include_marker):
        return dockerfile_contents

    include_line, _, rest = dockerfile_contents.partition(b"\n")
    included = include_line[len(include_marker):].strip().decode("utf8")
    path = os.path.join(os.path.dirname(dockerfile), included)
    return b"\n".join([expand_dockerfile(path), rest])


def git_env():
    assert CONFIG.git_url
    assert CONFIG.git_ref
    assert CONFIG.git_sha
    return {
        "APPSERVICES_HEAD_REPOSITORY": CONFIG.git_url,
        "APPSERVICES_HEAD_BRANCH": CONFIG.git_ref,
        "APPSERVICES_HEAD_REV": CONFIG.git_sha,
    }

def dict_update_if_truthy(d, **kwargs):
    for key, value in kwargs.items():
        if value:
            d[key] = value
    return d


def deindent(string):
    return re.sub("\n +", "\n ", string).strip()


def url_basename(url):
    return url.rpartition("/")[-1]

def populate_chain_of_trust_required_but_unused_files():
    # These files are needed to keep chainOfTrust happy. However,
    # they are not needed for a-s at the moment. For more details, see:
    # https://github.com/mozilla-releng/scriptworker/pull/209/files#r184180585

    for file_names in ('actions.json', 'parameters.yml'):
        with open(file_names, 'w') as f:
            json.dump({}, f)    # Yaml is a super-set of JSON.


def populate_chain_of_trust_task_graph(full_task_graph):
    # taskgraph must follow the format:
    # {
    #    task_id: full_task_definition
    # }
    with open('task-graph.json', 'w') as f:
        json.dump(full_task_graph, f)
