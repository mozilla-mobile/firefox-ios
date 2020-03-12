# Common code used by the automation python scripts.

import subprocess

def step_msg(msg):
    print(f"> \033[34m{msg}\033[0m")

def fatal_err(msg):
    print(f"\033[31mError: {msg}\033[0m")
    exit(1)

# Run command and let subprocess throw an exception when
# a command returns a non-zero status.
def run_cmd_checked(*args, **kwargs):
    kwargs["check"] = True
    return subprocess.run(*args, **kwargs)

# Ensure there is no un-commited or staged files in the working tree.
def ensure_working_tree_clean():
    if run_cmd_checked(["git", "status", "--porcelain"], capture_output=True).stdout:
        fatal_err("The working tree has un-commited or staged files.")
