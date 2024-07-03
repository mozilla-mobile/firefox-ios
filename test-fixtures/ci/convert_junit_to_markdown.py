import getopt, sys
import xml.etree.ElementTree as ET
import json
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
                'status': '✅'
            }

            failure = testcase.find('failure')
            error = testcase.find('error')
            if failure is not None:
                case['status'] = '❌'
                case['message'] = failure.get('message','')
            if error is not None:
                case['status'] = '🛑'
                case['message'] = error.get('message', '')

            suite['test_cases'].append(case)
            
        test_suites.append(suite)

    return test_suites

def count_test_retry_failure(test_name, test_cases):
    count = 0
    for test_case in test_cases:
        if test_case.get('name', '') == test_name and not test_case.get('status') == '✅':
            count += 1
    return count

def convert_to_slack_markdown(test_suites, is_smoke = True):
    # Fetch failed tests and put them in Slack format
    failed_tests_info = []
    for test_suite in test_suites:
        if int(test_suite.get('failures')):
            done = []
            markdown = ""
            test_cases = test_suite.get('test_cases', [])
            for test_case in test_cases:
                if not test_case.get('status') == '✅' and not test_case.get('name','') in done:        
                    # For smoke test only: See if the test passes in 2nd or 3rd attempt
                    if is_smoke:
                        fail_count = count_test_retry_failure(test_case.get('name', ''), test_cases)
                        if fail_count < 3:
                            test_case['status'] = ':warning:'
                    
                    markdown += "`{test_case_name}` {status}\n".format(test_case_name=test_case.get("name"), status=test_case.get('status'))
                    done.append(test_case.get('name', ''))

            test_failure = Section(text=markdown)
            test_suite_footer = Context(
                elements=[test_suite.get('name', '').replace('XCUITest.' ,'')]
            )
            
            failed_tests_info.append(test_failure)
            failed_tests_info.append(test_suite_footer)
    
    # No test failures
    if len(failed_tests_info) == 0:
        failed_tests_info = [
            Section(text="🎉 No test failures 🎉")
        ]
    
    # Put together the Slack message
    header = Header(
        text="${{ env.pass_fail }} ${{ env.browser }} :firefox: ${{ env.xcodebuild_test_plan }} - ${{ env.ios_simulator }} iOS ${{ env.ios_version }}"
    )
    build_info = Section(
            text="*Branch*: `${{ env.ref_name }}`\n<${{ env.server_url }}/${{ env.repository }}/actions/runs/${{ env.run_id }}|*Github Actions Job*> :github:\n<${{ env.server_url }}/${{ env.repository }}/commit/${{ env.sha }}|Commit> :pull_request:"
        )
    footer = Context(
        elements=[
            ":testops-notify: created by <https://mozilla-hub.atlassian.net/wiki/spaces/MTE/overview|Mobile Test Engineering>"
        ]
    )
    blocks = []
    blocks.append(header)
    blocks.append(Divider())
    blocks.append(build_info)
    for test in failed_tests_info:
        blocks.append(test)
    blocks.append(Divider())
    blocks.append(footer)
    payload = Message (
        blocks = blocks
    ).build()
    
    return json.dumps(payload, indent=4)  

def convert_to_github_markdown(test_suites, is_smoke = True):
    markdown = ""
    
    for test_suite in test_suites:
        if int(test_suite['failures']):
            markdown += "## {name}\n\n".format(name = test_suite.get('name', '').replace('XCUITest.' ,''))
            markdown += convert_test_cases_to_github_markdown(test_suite.get('test_cases', []), is_smoke = True)
    
    if markdown == "":
        markdown += "## 🎉 No test failures 🎉"
    
    return markdown

def convert_test_cases_to_github_markdown(test_cases, is_smoke = True):
    markdown = ""
    markdown += "| Test Name | Status | Message |\n"
    markdown += "|-----------|--------|---------|\n"
    
    done = []
    
    for test_case in test_cases:
        if not test_case.get('status') == '✅' and not test_case.get('name', '') in done:   
            # For smoke test only: See if the test passes in 2nd or 3rd attempt
            if is_smoke:
                fail_count = count_test_retry_failure(test_case.get('name'), test_cases)
                if fail_count < 3:
                    test_case['status'] = '⚠️'
            
            message = test_case.get('message', '')
            message = message = ('```{message}```'.format(message = message) if message != '' else '')
            markdown += "| {name} | {status} | {message} |".format(
                name = test_case.get('name', ''),
                status = test_case.get('status'),
                message = message
            )
            markdown += "\n"   
            done.append(test_case.get('name'))
    
    return markdown

def convert_file_github(input_file, output_file, is_smoke = True):
    test_cases = parse_junit_xml(input_file)
    markdown = convert_to_github_markdown(test_cases, is_smoke = True)
    with open(output_file, 'w') as md_file:
        md_file.write(markdown)

def convert_file_slack(input_file, output_file, is_smoke = True):
    test_cases = parse_junit_xml(input_file)
    markdown = convert_to_slack_markdown(test_cases, is_smoke = True)
    with open(output_file, 'w') as md_file:
        md_file.write(markdown)

if __name__ == "__main__":
    opts, args = getopt.getopt(sys.argv[1:], "", ["github", "slack", "smoke", "full-functional"])
    
    failures_only = False
    github_markdown = True
    is_smoke = True
    
    for opt, arg in opts:
        if opt == "--slack":
            github_markdown = False
        if opt == "--full-functional":
            is_smoke = False
    
    if github_markdown:
        convert_file_github(args[0], args[1], is_smoke=is_smoke)
    else:
        convert_file_slack(args[0], args[1], is_smoke=is_smoke)