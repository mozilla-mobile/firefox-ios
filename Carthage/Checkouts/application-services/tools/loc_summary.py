#
# This is a simple script to generate some summary lines-of-code metrics.
# Use it like this:
#
#    $> python locsummary.py [./path/to/code/directory]
#
# It shells out to tokei [1] to do the actual counting, which you must have
# installed with the `json` feature. It then massages the tokei output to
# give us a rough guesstimate at:
#
#   * How much code is shared code, that can be used on multiple platforms.
#   * How much of it is android-specific code.
#   * How much of it is ios-specific code.
#
# Since we aim to reduce total-cost-of-ownership of our storage and sync
# infrastructure by re-using code across platforms, we should hope that
# a high percentage of the code we've written is shared rather than
# platform-specific! The analysis is far from an exact science, but it
# provides a nice gut-check for our code re-use story.
#
# [1] https://github.com/XAMPPRocky/tokei
#

import os.path
import argparse
import subprocess
import json

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_PATH = os.path.join(ROOT_DIR, 'components')

# For each type of file in our repo, is it:
#  * shared code across platforms?
#  * specific to android?
#  * specific to ios?
#  * some sort of meta file that we shouldn't count at all?

FILETYPE_TO_SUMMARYTYPE = {
  'CHeader': 'ios',
  'Java': 'android',
  'Json': None,
  'Kotlin': 'android',
  'Markdown': None,
  'Prolog': 'android', # Our .pro files are actually proguard rules, not prolog...
  'Protobuf': 'shared',
  'Rust': 'shared',
  'Sql': 'shared',
  'Swift': 'ios',
  'Toml': None,
  'XcodeConfig': 'ios',
  'Xml': None,
}


def get_loc_summary(path):
  path = os.path.abspath(path)
  p = subprocess.run([
    'tokei',
    '--output', 'json',
    '--exclude', 'examples',
    path,
  ], stdout=subprocess.PIPE, universal_newlines=True)
  p.check_returncode()
  summary = {
    'shared': 0,
    'android': 0,
    'ios': 0,
    'all': 0,
  }
  lineOfCode = json.loads(p.stdout)['inner']
  for fileType in lineOfCode:
    summaryType = FILETYPE_TO_SUMMARYTYPE[fileType]
    if summaryType is not None:
      summary[summaryType] += lineOfCode[fileType]['code']
      summary['all'] += lineOfCode[fileType]['code']
  if path.startswith(ROOT_DIR):
    summary['path'] = os.path.join('.', path[len(ROOT_DIR) + 1:])
  else:
    summary['path'] = path
  return summary


def print_loc_summaries(paths):
  summaries = [get_loc_summary(path) for path in paths]
  headers = ['Path', 'Shared', 'Android', 'iOS', 'Total', 'Shared %']
  nameWidth = max(
    len(headers[0]),
    max(len(summary['path']) for summary in summaries)
  )
  numWidth = max(
    max(len(h) for h in headers[1:]),
    max(len(str(summary['all'])) for summary in summaries)
  )
  totalWidth = (nameWidth + 5) + (numWidth + 3) * 5 - 1
  print("-" * totalWidth)
  print(
    f"| {headers[0]:<{nameWidth}} | "
    f"{headers[1]:>{numWidth}} | "
    f"{headers[2]:>{numWidth}} | "
    f"{headers[3]:>{numWidth}} | "
    f"{headers[4]:>{numWidth}} | "
    f"{headers[5]:>{numWidth}} |"
  )
  print("-" * totalWidth)
  for summary in summaries:
    print(
        f"| {summary['path']:<{nameWidth}} | "
        f"{summary['shared']:>{numWidth}} | "
        f"{summary['android']:>{numWidth}} | "
        f"{summary['ios']:>{numWidth}} | "
        f"{summary['all']:>{numWidth}} | "
        f"{(summary['shared'] / summary['all']):>{numWidth}.2%} |"
    )
  print("-" * totalWidth)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="summarize lines-of-code statistics")
  parser.add_argument('paths', type=str, nargs='*', default=[DEFAULT_PATH])
  args = parser.parse_args()
  print_loc_summaries(args.paths)

