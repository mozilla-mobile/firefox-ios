# coding: utf8

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
import enum
from enum import Enum
import os.path
from build_config import module_definitions, appservices_version
from decisionlib import *
from decisionlib import SignTask

# Tags that when matched in pull-requests titles will alter the CI tasks we run.
FULL_CI_TAG = '[ci full]'
SKIP_CI_TAG = '[ci skip]'
# Task owners for which we always run full CI. Typically bots.
FULL_CI_GH_USERS = ['dependabot@users.noreply.github.com']

def main(task_for):
    if task_for == "github-pull-request":
        task_owner = os.environ["TASK_OWNER"]
        pr_title = os.environ["GITHUB_PR_TITLE"]
        if SKIP_CI_TAG in pr_title:
            print("CI skip requested, exiting.")
            exit(0)
        elif FULL_CI_TAG in pr_title or task_owner in FULL_CI_GH_USERS:
            android_multiarch()
        else:
            android_linux_x86_64()
    elif task_for == "github-push":
        android_multiarch()
    elif task_for == "github-release":
        is_staging = os.environ['IS_STAGING'] == 'true'
        android_multiarch_release(is_staging)
    else:
        raise ValueError("Unrecognized $TASK_FOR value: %r", task_for)

    full_task_graph = build_full_task_graph()
    populate_chain_of_trust_task_graph(full_task_graph)
    populate_chain_of_trust_required_but_unused_files()

build_artifacts_expire_in = "1 month"
build_dependencies_artifacts_expire_in = "3 month"
log_artifacts_expire_in = "1 year"

build_env = {
    "RUST_BACKTRACE": "1",
    "RUSTFLAGS": "-Dwarnings",
    "CARGO_INCREMENTAL": "0",
    "CI": "1",
}
linux_build_env = {
    "TERM": "dumb",  # Keep Gradle output sensible.
    "CCACHE": "sccache",
    "RUSTC_WRAPPER": "sccache",
    "SCCACHE_IDLE_TIMEOUT": "1200",
    "SCCACHE_CACHE_SIZE": "40G",
    "SCCACHE_ERROR_LOG": "/build/sccache.log",
    "RUST_LOG": "sccache=info",
}

# Calls "$PLATFORM_libs" functions and returns
# their tasks IDs.
def libs_for(deploy_environment, *platforms):
    return list(map(lambda p: globals()[p + "_libs"](deploy_environment), platforms))

def android_libs(deploy_environment):
    task = (
        linux_build_task("Android libs (all architectures): build")
        .with_script("""
            pushd libs
            ./build-all.sh android
            popd
            tar -czf /build/repo/target.tar.gz libs/android
        """)
        .with_artifacts(
            "/build/repo/target.tar.gz",
        )
    )
    if deploy_environment == DeployEnvironment.NONE:
        return task.find_or_create("build.libs.android." + CONFIG.git_sha_for_directory("libs"))
    else:
        return task.create()

def desktop_linux_libs(deploy_environment):
    task = (
        linux_build_task("Desktop libs (Linux): build")
        .with_script("""
            pushd libs
            ./build-all.sh desktop
            popd
            tar -czf /build/repo/target.tar.gz libs/desktop
        """)
        .with_artifacts(
            "/build/repo/target.tar.gz",
        )
    )
    if deploy_environment == DeployEnvironment.NONE:
        return task.find_or_create("build.libs.desktop.linux." + CONFIG.git_sha_for_directory("libs"))
    else:
        return task.create()


def desktop_macos_libs(deploy_environment):
    task = (
        linux_cross_compile_build_task("Desktop libs (macOS): build")
        .with_script("""
            pushd libs
            ./build-all.sh darwin
            popd
            tar -czf /build/repo/target.tar.gz libs/desktop
        """)
        .with_artifacts(
            "/build/repo/target.tar.gz",
        )
    )
    if deploy_environment == DeployEnvironment.NONE:
        return task.find_or_create("build.libs.desktop.macos." + CONFIG.git_sha_for_directory("libs"))
    else:
        return task.create()


def desktop_win32_x86_64_libs(deploy_environment):
    task = (
        linux_build_task("Desktop libs (win32-x86-64): build")
        .with_script("""
            pushd libs
            ./build-all.sh win32-x86-64
            popd
            tar -czf /build/repo/target.tar.gz libs/desktop
        """)
        .with_artifacts(
            "/build/repo/target.tar.gz",
        )
    )
    if deploy_environment == DeployEnvironment.NONE:
        return task.find_or_create("build.libs.desktop.win32-x86-64." + CONFIG.git_sha_for_directory("libs"))
    else:
        return task.create()


def android_task(task_name, libs_tasks):
    task = linux_cross_compile_build_task(task_name)
    for libs_task in libs_tasks:
        task.with_curl_artifact_script(libs_task, "target.tar.gz")
        task.with_script("tar -xzf target.tar.gz")
    return task

def ktlint_detekt():
    linux_build_task("detekt").with_script("./gradlew --no-daemon clean detekt").create()
    linux_build_task("ktlint").with_script("./gradlew --no-daemon clean ktlint").create()

def android_linux_x86_64():
    ktlint_detekt()
    libs_tasks = libs_for(DeployEnvironment.NONE, "android", "desktop_linux", "desktop_macos", "desktop_win32_x86_64")
    task = (
        android_task("Build and test (Android - linux-x86-64)", libs_tasks)
        .with_script("""
            echo "rust.targets=linux-x86-64,x86_64\n" > local.properties
        """)
        .with_script("""
            yes | sdkmanager --update
            yes | sdkmanager --licenses
            ./gradlew --no-daemon clean
            ./gradlew --no-daemon assembleDebug
            ./gradlew --no-daemon testDebug
        """)
    )
    for module_info in module_definitions():
        module = module_info['name']
        if module.endswith("-megazord"):
            task.with_script("./automation/check_megazord.sh {}".format(module[0:-9].replace("-", "_")))
    return task.create()

def gradle_module_task_name(module, gradle_task_name):
    return ":%s:%s" % (module, gradle_task_name)

def gradle_module_task(libs_tasks, module_info, deploy_environment):
    module = module_info['name']
    task = android_task("{} - Build and test".format(module), libs_tasks)
    # This is important as by default the Rust plugin will only cross-compile for Android + host platform.
    task.with_script('echo "rust.targets=arm,arm64,x86_64,x86,darwin,linux-x86-64,win32-x86-64-gnu\n" > local.properties')
    (
        task
        .with_script("""
            yes | sdkmanager --update
            yes | sdkmanager --licenses
            ./gradlew --no-daemon clean
        """)
        .with_script("sccache --zero-stats")
        .with_script("./gradlew --no-daemon {}".format(gradle_module_task_name(module, "testDebug")))
        .with_script("./gradlew --no-daemon {}".format(gradle_module_task_name(module, "assembleRelease")))
        .with_script("./gradlew --no-daemon {}".format(gradle_module_task_name(module, "publish")))
        .with_script("./gradlew --no-daemon {}".format(gradle_module_task_name(module, "checkMavenArtifacts")))
        .with_script("sccache --show-stats")
    )
    for publication in module_info['publications']:
        for artifact in publication.to_artifacts(('', '.sha1', '.md5')):
            task.with_artifacts(artifact['build_fs_path'], artifact['taskcluster_path'])
    if deploy_environment == DeployEnvironment.RELEASE and module_info['uploadSymbols']:
        task.with_scopes("secrets:get:project/application-services/symbols-token")
        task.with_script("./automation/upload_android_symbols.sh {}".format(module_info['path']))
    return task.create()

def build_gradle_modules_tasks(deploy_environment):
    libs_tasks = libs_for(deploy_environment, "android", "desktop_linux", "desktop_macos", "desktop_win32_x86_64")
    module_build_tasks = {}
    for module_info in module_definitions():
        module_build_tasks[module_info['name']] = gradle_module_task(libs_tasks, module_info, deploy_environment)
    return module_build_tasks

def android_multiarch():
    ktlint_detekt()
    build_gradle_modules_tasks(DeployEnvironment.NONE)

def android_multiarch_release(is_staging):
    module_build_tasks = build_gradle_modules_tasks(DeployEnvironment.STAGING_RELEASE if is_staging else DeployEnvironment.RELEASE)

    version = appservices_version()
    bucket_name = os.environ['BEETMOVER_BUCKET']
    bucket_public_url = os.environ['BEETMOVER_BUCKET_PUBLIC_URL']

    for module_info in module_definitions():
        module = module_info['name']
        build_task = module_build_tasks[module]
        sign_task = (
            SignTask("Sign Android module: {}".format(module))
            .with_description("Signs module")
            .with_worker_type("appservices-t-signing" if is_staging else "appservices-3-signing")
            # We want to make sure ALL builds succeeded before doing a release.
            .with_dependencies(*module_build_tasks.values())
            .with_upstream_artifact({
                "paths": [artifact["taskcluster_path"]
                          for publication in module_info["publications"]
                          for artifact in publication.to_artifacts(('',))],
                "formats": ["autograph_gpg"],
                "taskId": build_task,
                "taskType": "build"
            })
            .with_scopes(
                "project:mozilla:application-services:releng:signing:cert:{}-signing".format(
                    "dep" if is_staging else "release")
            )
            .create()
        )

        (
            BeetmoverTask("Publish Android module: {} via beetmover".format(module))
            .with_description("Publish release module {} to {}".format(module, bucket_public_url))
            .with_worker_type(os.environ['BEETMOVER_WORKER_TYPE'])
            .with_dependencies(sign_task)
            .with_upstream_artifact({
                "paths": [artifact['taskcluster_path']
                          for publication in module_info["publications"]
                          for artifact in publication.to_artifacts(('', '.sha1', '.md5'))],
                "taskId": build_task,
                "taskType": "build",
            })
            .with_upstream_artifact({
                "paths": [artifact['taskcluster_path']
                          for publication in module_info["publications"]
                          for artifact in publication.to_artifacts(('.asc',))],
                "taskId": sign_task,
                "taskType": "signing",
            })
            .with_app_name("appservices")
            .with_artifact_map([{
                "locale": "en-US",
                "taskId": build_task,
                "paths": {
                    artifact["taskcluster_path"]: {
                        "checksums_path": "",  # TODO beetmover marks this as required, but it's not needed
                        "destinations": [artifact["maven_destination"]],
                    }
                    for publication in module_info["publications"]
                    for artifact in publication.to_artifacts(('', '.sha1', '.md5'))
                }
            }, {
                "locale": "en-US",
                "taskId": sign_task,
                "paths": {
                    artifact["taskcluster_path"]: {
                        "checksums_path": "",  # TODO beetmover marks this as required, but it's not needed
                        "destinations": [artifact["maven_destination"]],
                    }
                    for publication in module_info["publications"]
                    for artifact in publication.to_artifacts(('.asc',))
                },
            }])
            .with_app_version(version)
            .with_scopes(
                "project:mozilla:application-services:releng:beetmover:bucket:{}".format(bucket_name),
                "project:mozilla:application-services:releng:beetmover:action:push-to-maven"
            )
            .with_routes("notify.email.a-s-ci-failures@mozilla.com.on-failed")
            .create()
        )

def dockerfile_path(name):
    return os.path.join(os.path.dirname(__file__), "docker", name + ".dockerfile")

def linux_task(name):
    task = (
        DockerWorkerTask(name)
        .with_worker_type(os.environ.get("BUILD_WORKER_TYPE"))
    )
    if os.environ["TASK_FOR"] == "github-release":
        task.with_features("chainOfTrust")
    return task

def linux_build_task(name):
    use_indexed_docker_image = os.environ["TASK_FOR"] != "github-release"
    task = (
        linux_task(name)
        # https://docs.taskcluster.net/docs/reference/workers/docker-worker/docs/caches
        .with_scopes("docker-worker:cache:application-services-*")
        .with_caches(**{
            "application-services-cargo-registry": "/root/.cargo/registry",
            "application-services-cargo-git": "/root/.cargo/git",
            "application-services-sccache": "/root/.cache/sccache",
            "application-services-gradle": "/root/.gradle",
            "application-services-rustup": "/root/.rustup",
        })
        .with_index_and_artifacts_expire_in(build_artifacts_expire_in)
        .with_artifacts("/build/sccache.log")
        .with_max_run_time_minutes(120)
        .with_dockerfile(dockerfile_path("build"), use_indexed_docker_image)
        .with_env(**build_env, **linux_build_env)
        .with_script("""
            rustup toolchain install stable
            rustup default stable
            rustup target add x86_64-linux-android i686-linux-android armv7-linux-androideabi aarch64-linux-android
        """)
        .with_repo()
        .with_script("""
            ./libs/verify-android-environment.sh
        """)
    )
    # Send email notifications for failures on master.
    if os.environ["TASK_FOR"] == "github-push":
        task.with_routes("notify.email.a-s-ci-failures@mozilla.com.on-failed")
    return task

def linux_cross_compile_build_task(name):
    return (
        linux_build_task(name)
        .with_scopes('project:releng:services/tooltool/api/download/internal')
        .with_features('taskclusterProxy') # So we can fetch from tooltool.
        .with_script("""
            rustup target add x86_64-apple-darwin

            pushd libs
            ./cross-compile-macos-on-linux-desktop-libs.sh
            popd

            # Rust requires dsymutil on the PATH: https://github.com/rust-lang/rust/issues/52728.
            export PATH=$PATH:/tmp/clang/bin

            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_NSS_STATIC=1
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_NSS_DIR=/build/repo/libs/desktop/darwin/nss
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_SQLCIPHER_LIB_DIR=/build/repo/libs/desktop/darwin/sqlcipher/lib
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_CC=/tmp/clang/bin/clang
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_TOOLCHAIN_PREFIX=/tmp/cctools/bin
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_AR=/tmp/cctools/bin/x86_64-darwin11-ar
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_RANLIB=/tmp/cctools/bin/x86_64-darwin11-ranlib
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_LD_LIBRARY_PATH=/tmp/clang/lib
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_RUSTFLAGS="-C linker=/tmp/clang/bin/clang -C link-arg=-B -C link-arg=/tmp/cctools/bin -C link-arg=-target -C link-arg=x86_64-darwin11 -C link-arg=-isysroot -C link-arg=/tmp/MacOSX10.11.sdk -C link-arg=-Wl,-syslibroot,/tmp/MacOSX10.11.sdk -C link-arg=-Wl,-dead_strip"
            # For ring's use of `cc`.
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_APPLE_DARWIN_CFLAGS_x86_64_apple_darwin="-B /tmp/cctools/bin -target x86_64-darwin11 -isysroot /tmp/MacOSX10.11.sdk -Wl,-syslibroot,/tmp/MacOSX10.11.sdk -Wl,-dead_strip"

            rustup target add x86_64-pc-windows-gnu
            # The wrong linker gets used otherwise: https://github.com/rust-lang/rust/issues/33465.
            export ORG_GRADLE_PROJECT_RUST_ANDROID_GRADLE_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C linker=x86_64-w64-mingw32-gcc"
        """)
    )

CONFIG.task_name_template = "Application Services - %s"
CONFIG.index_prefix = "project.application-services.application-services"
CONFIG.docker_images_expire_in = build_dependencies_artifacts_expire_in
CONFIG.repacked_msi_files_expire_in = build_dependencies_artifacts_expire_in


class DeployEnvironment(Enum):
    RELEASE = enum.auto()
    STAGING_RELEASE = enum.auto()
    NONE = enum.auto()


if __name__ == "__main__":  # pragma: no cover
    main(task_for=os.environ["TASK_FOR"])
