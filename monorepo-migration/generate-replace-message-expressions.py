#!/usr/bin/env python3

import json
import logging
from pathlib import Path


log = logging.getLogger(__name__)
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.DEBUG,
)

DATA_DIR = (Path(__file__).parent / "data").absolute()
GITHUB_URL_TEMPLATE = "https://github.com/{repo_owner}/{repo_name}/{number_type}"
REPO_OWNER = "mozilla-mobile"
REPO_NAME_TO_IMPORT = "focus-ios"


def divide_chunks(sequence, n):
    for i in range(0, len(sequence), n):
        yield sequence[i : i + n]


def order_repo_names(repo_names):
    ordered_list = list(repo_names)
    ordered_list.remove(REPO_NAME_TO_IMPORT)
    # The regex of the repo to import may take precedence over other regexes.
    # Running them last makes sure the other URLs got replaced first.
    ordered_list.append(REPO_NAME_TO_IMPORT)
    return ordered_list


def main():
    with open(DATA_DIR / "repo-numbers.json") as f:
        repo_numbers = json.load(f)

    regexes = []

    for repo_name in order_repo_names(repo_numbers.keys()):
        numbers = repo_numbers[repo_name]
        if repo_name.startswith("$"):
            continue

        for number_type in ("issues", "pulls"):
            for chunk in divide_chunks(numbers[number_type], 100):
                regex = (r"regex:(\W)(({repo_owner}/)?{repo_name}){repo_suffix}#({current_numbers})(\D|$)==>\1{url}/\4\5" "\n").format(
                    repo_owner=REPO_OWNER,
                    repo_name=f"[{repo_name[0].upper()}{repo_name[0].lower()}]{repo_name[1:]}",
                    repo_suffix=r"?" if repo_name == REPO_NAME_TO_IMPORT else r"\s*",
                    current_numbers="|".join(str(number) for number in chunk),
                    url=GITHUB_URL_TEMPLATE.format(
                        repo_owner=REPO_OWNER,
                        repo_name=repo_name,
                        number_type="pull" if number_type == "pulls" else number_type,
                    ),
                )
                regexes.append(regex)

    # Add regexes if there are wrong replacements
    regexes += [
        "regex:^==>[focus-ios] ",
    ]

    with open(DATA_DIR / "message-expressions.txt", "w") as f:
        f.write("".join(regexes))

__name__ == "__main__" and main()
