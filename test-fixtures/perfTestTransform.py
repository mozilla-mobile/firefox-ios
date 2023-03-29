import json

PERFHERDER_DATA = { "framework": 'mozperftest',
                   "application": { "name": 'firefox-ios' },
                     "suites": []
                    }
# get json data from ./test.json
with open('test.json') as f:
    data = json.load(f)
    for i in data:
        suite = {}
        suite['name'] = i['testName']
        subtests = []
        for key in i:
            if key != 'testName':
                subtest = {}
                subtest['name'] = key
                subtest['replicates'] = [i[key]]
                subtests.append(subtest)
                suite['subtests'] = subtests
                PERFHERDER_DATA['suites'].append(suite)

print("PERFHERDER_DATA:", json.dumps(PERFHERDER_DATA))