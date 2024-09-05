#!/usr/bin/env python3

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import getopt, sys
import xml.etree.ElementTree as ET
import json
import re
from blockkit import Context, Divider, Header, Message, Section

# Modified from junit_to_markdown
# https://github.com/stevengoossensB/junit_to_markdown/tree/main

def parse_junit_xml(file_path):
    """
    Parses a JUnit XML file and extracts test suite data.

    Args:
        file_path (str): Path to the JUnit XML file.

    Returns:
        list of dict: A list of dictionaries, each representing a test case.
    """
    test_suites = []
    tree = ET.parse(file_path)
    root = tree.getroot()
    
    for testsuite in root.iter('testsuite'):
        suite = {
            'name': testsuite.get('name', ''),
            'tests': testsuite.get('tests', ''),
            'failures': testsuite.get('failures', ''),
            'test_cases': []
        }
        
        for testcase in testsuite.iter('testcase'):
            case = {
                'name': testcase.get('name', ''),
                'classname': testcase.get('classname', ''),
                'time': testcase.get('time', ''),
                'status': ':white_check_mark:'
            }

            failure = testcase.find('failure')
            error = testcase.find('error')
            if failure is not None:
                case['status'] = ':x:'
                case['message'] = failure.get('message','')
            if error is not None:
                case['status'] = ':stop-sign:'
                case['message'] = error.get('message', '')

            suite['test_cases'].append(case)
            
        test_suites.append(suite)

    return test_suites

def count_test_retry_failure(test_name, test_cases):
    count = 0
    for test_case in test_cases:
        if test_case.get('name', '') == test_name and not test_case.get('status') == ':white_check_mark:':
            count += 1
    return count

def count_tests(test_suites, is_smoke=True):
    done = []
    tests = {'passed': 0, 'failures': 0, 'warnings': 0, 'total_tests': 0}
    for test_suite in test_suites:
        test_cases = test_suite.get('test_cases', [])
        for test_case in test_cases:
            test_name = test_case.get('name')
            if not test_name in done:
                done.append(test_name)
                status = test_case.get('status')
                if status == ':white_check_mark:':
                    tests['passed'] += 1
                else:
                    if is_smoke:
                        fail_count = count_test_retry_failure(test_name, test_cases)
                        if fail_count < 3:
                            tests['warnings'] += 1
                        else:
                            tests['failures'] += 1
                    else:
                        tests['failures'] += 1

    tests['total_tests'] = tests['passed'] + tests['failures'] + tests['warnings']
    
    if not is_smoke:
        tests['warnings'] = 'N/A'

    return tests

def convert_to_slack_markdown(test_suites, is_smoke = True, browser='firefox-ios'):
    # Count number of pass/fail tests for reporting
    tests_info = count_tests(test_suites, is_smoke=is_smoke)
    
    # Fetch failed tests and put them in Slack format
    failed_tests_info = []
    for test_suite in test_suites:
        if int(test_suite.get('failures')):
            done = []
            markdown = '*{name}*'.format(name=re.sub('XCUITests?.', '', test_suite.get('name', '')))
            test_cases = test_suite.get('test_cases', [])
            for test_case in test_cases:
                if not test_case.get('status') == ':white_check_mark:' and not test_case.get('name', '') in done: 
                    # For smoke test only: See if the test passes in 2nd or 3rd attempt
                    if is_smoke:
                        fail_count = count_test_retry_failure(test_case.get('name', ''), test_cases)
                        if fail_count < 3:
                            test_case['status'] = ':warning:'
                    markdown += '\n- {test_case_name} {status}'.format(test_case_name=test_case.get('name'), status=test_case.get('status'))
                    done.append(test_case.get('name', ''))
            failed_tests_info.append(Section(text=markdown))
    
    # No test failures
    if tests_info['total_tests'] == 0:
        failed_tests_info = [ Section(text=':boom: No tests executed :boom:') ]
    elif len(failed_tests_info) == 0:
        failed_tests_info = [ Section(text=':tada: No test failures :tada:') ]

    # Put together the Slack message
    browser_emoji = ':firefox:'
    if browser == 'focus-ios':
        browser_emoji = ':firefox_focus:'
    header = Header(
        text='${{ env.pass_fail }} ${{ env.browser }} ' 
            + '{emoji}'.format(emoji=browser_emoji) 
            + ' ${{ env.xcodebuild_test_plan }} - ${{ env.ios_simulator }} iOS ${{ env.ios_version }}'
    )
    build_info = Section(
        fields= [
            '*Branch:* `${{ env.ref_name }}`',
            '*Github Actions Job:* <${{ env.server_url }}/${{ env.repository }}/actions/runs/${{ env.run_id }}|Link>',
            '*Commit:* <${{ env.server_url }}/${{ env.repository }}/commit/${{ env.sha }}|Link>'
        ]
    )
    summary = Section(
        fields=[
            '*Total Tests:* {total_tests}'.format(total_tests=tests_info['total_tests']),
            '*Passed:* {passed}'.format(passed=tests_info['passed']),
            '*Flakys:* {warnings}'.format(warnings=tests_info['warnings']),
            '*Failures:* {failures}'.format(failures=tests_info['failures']),
        ]
    )
    footer = Context(
        elements=[
            ':testops-notify: created by <https://mozilla-hub.atlassian.net/wiki/spaces/MTE/overview|Mobile Test Engineering>'
        ]
    )
    blocks = []
    blocks.append(header)
    blocks.append(Divider())
    blocks.append(build_info)
    blocks.append(Divider())
    blocks.append(summary)
    blocks.append(Divider())
    for test in failed_tests_info:
        blocks.append(test)
    blocks.append(Divider())
    blocks.append(footer)
    payload = Message (
        blocks = blocks
    ).build()
    
    return json.dumps(payload, indent=4)  

def convert_to_github_markdown(test_suites, is_smoke = True):
    # Count number of pass/fail tests for reporting
    tests_info = count_tests(test_suites, is_smoke=is_smoke)

    markdown = ''
    for test_suite in test_suites:
        if int(test_suite['failures']):
            markdown += '## {name}\n\n'.format(name=re.sub('XCUITests?.', '', test_suite.get('name', '')))
            markdown += convert_test_cases_to_github_markdown(test_suite.get('test_cases', []), is_smoke = is_smoke)
    
    if tests_info['total_tests'] == 0:
        markdown += '__:boom: No tests executed :boom:__'
    elif markdown == '':
        markdown += '__:tada: No test failures :tada:__'
    else:
        tests_info_markdown = ''
        if is_smoke:
            tests_info_markdown += '| Total Tests | Passed | Flakys | Failures |\n'
            tests_info_markdown += '|-------------|--------|-------|----------|\n'
            tests_info_markdown += '|{total_tests}|{passed}|{warnings}|{failures}|'.format(
                total_tests=tests_info['total_tests'], 
                passed=tests_info['passed'], 
                warnings=tests_info['warnings'], 
                failures=tests_info['failures'])
        else:
            tests_info_markdown += '| Total Tests | Passed | Failures |\n'
            tests_info_markdown += '|-------------|--------|----------|\n'            
            tests_info_markdown += '|{total_tests}|{passed}|{failures}|'.format(
                total_tests=tests_info['total_tests'], 
                passed=tests_info['passed'], 
                failures=tests_info['failures'])
        markdown = tests_info_markdown + '\n'+ markdown

    return markdown

def convert_test_cases_to_github_markdown(test_cases, is_smoke = True):
    markdown = ''
    markdown += '| Test Name | Status | Message |\n'
    markdown += '|-----------|--------|---------|\n'
    
    done = []
    
    for test_case in test_cases:
        if not test_case.get('status') == ':white_check_mark:' and not test_case.get('name', '') in done:   
            # For smoke test only: See if the test passes in 2nd or 3rd attempt
            if is_smoke:
                fail_count = count_test_retry_failure(test_case.get('name'), test_cases)
                if fail_count < 3:
                    test_case['status'] = '⚠️'
            
            message = test_case.get('message', '')
            message = message = ('```{message}```'.format(message = message) if message != '' else '')
            markdown += '| {name} | {status} | {message} |'.format(
                name = test_case.get('name', ''),
                status = test_case.get('status'),
                message = message
            )
            markdown += '\n'   
            done.append(test_case.get('name'))
    
    return markdown

def convert_file_github(input_file, output_file, is_smoke = True):
    test_cases = parse_junit_xml(input_file)
    markdown = convert_to_github_markdown(test_cases, is_smoke = is_smoke)
    with open(output_file, 'w') as md_file:
        md_file.write(markdown)

def convert_file_slack(input_file, output_file, is_smoke = True, browser='firefox-ios'):
    test_cases = parse_junit_xml(input_file)
    markdown = convert_to_slack_markdown(test_cases, is_smoke = is_smoke, browser=browser)
    with open(output_file, 'w') as md_file:
        md_file.write(markdown)

if __name__ == '__main__':
    opts, args = getopt.getopt(sys.argv[1:], '', ['github', 'slack', 'smoke', 'full-functional', 'firefox-ios', 'focus-ios'])
    
    failures_only = False
    github_markdown = True
    is_smoke = False
    browser = 'firefox-ios'
    
    for opt, arg in opts:
        if opt == '--slack':
            github_markdown = False
        if opt == '--full-functional':
            is_smoke = False
        if opt == '--focus-ios':
            browser = "focus-ios"
        if opt == '--smoke':
            is_smoke = True
    
    if github_markdown:
        convert_file_github(args[0], args[1], is_smoke=is_smoke)
    else:
        convert_file_slack(args[0], args[1], is_smoke=is_smoke, browser=browser)