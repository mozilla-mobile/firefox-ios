#!/usr/bin/env python3
"""Extracts performance metrics from an .xcresult bundle into test.json.

Writes a list of {"testName": ..., "<metric>": "<mean>"} objects, which is the
input format perfTestTransform.py expects.

Usage: xcresult_perf_extract.py <path-to-xcresult> [output-path]

Metric names come from the bundle itself rather than a fixed positional list, so
a change in the order Xcode emits them cannot silently mislabel a series.
"""

import json
import subprocess
import sys


def xcresult_get(path, identifier=None):
    """Returns the parsed legacy JSON for an xcresult object.

    --legacy is required: the modern `get test-results` API does not expose
    performanceMetrics.
    """
    cmd = ['xcrun', 'xcresulttool', 'get', '--path', path]
    if identifier:
        cmd += ['--id', identifier]
    cmd += ['--format', 'json', '--legacy']
    return json.loads(subprocess.check_output(cmd))


def leaf_tests(tests_node):
    """Flattens the nested subtests tree down to the individual test cases."""
    leaves = []

    def walk(node):
        subtests = node.get('subtests', {}).get('_values')
        if subtests:
            for child in subtests:
                walk(child)
        else:
            leaves.append(node)

    for summary in tests_node['summaries']['_values']:
        for testable in summary['testableSummaries']['_values']:
            for test in testable.get('tests', {}).get('_values', []):
                walk(test)
    return leaves


def mean(measurements):
    values = [float(v['_value']) for v in measurements.get('_values', [])]
    return sum(values) / len(values) if values else 0.0


def extract(xcresult_path):
    root = xcresult_get(xcresult_path)
    action = root['actions']['_values'][0]
    tests_ref = action['actionResult']['testsRef']['id']['_value']

    results = []
    for test in leaf_tests(xcresult_get(xcresult_path, tests_ref)):
        entry = {'testName': test['identifier']['_value']}

        duration = test.get('duration', {}).get('_value')
        if duration is not None:
            entry['Duration'] = '{:.2f}'.format(float(duration))

        summary_ref = test.get('summaryRef', {}).get('id', {}).get('_value')
        if summary_ref:
            summary = xcresult_get(xcresult_path, summary_ref)
            # Xcode 27 emits performanceMetrics with no _values for tests that
            # record no measurements, where earlier versions omitted the key.
            metrics = (summary.get('performanceMetrics') or {}).get('_values') or []
            for metric in metrics:
                name = metric.get('displayName', {}).get('_value')
                if name:
                    entry[name] = str(mean(metric.get('measurements', {})))

        results.append(entry)
    return results


def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        sys.exit('Usage: xcresult_perf_extract.py <path-to-xcresult> [output-path]')

    xcresult_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else 'test.json'

    results = extract(xcresult_path)
    if not results:
        sys.exit('No tests found in {}'.format(xcresult_path))

    with open(out_path, 'w') as f:
        json.dump(results, f, indent=2)
    print('Wrote {} test(s) to {}'.format(len(results), out_path))


if __name__ == '__main__':
    main()
