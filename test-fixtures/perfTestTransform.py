import json
import os

device_key = os.environ.get("DEVICE_KEY")

PERFHERDER_DATA = {"framework": {"name":"mozperftest"},
                   "application": {"name": "fennec"},
                   "suites": []
                   }

with open('test.json') as json_file:
    data = json.load(json_file)
    for p in data:
        suite = {}
        suite["name"] = p["testName"]
        if device_key:
            suite["extraOptions"] = [device_key]
        suite["subtests"] = []
        for key, value in p.items():
            if key != "testName":
                subtest = {}
                subtest["name"] = key
                subtest["replicates"] = [value]
                subtest["value"] = float(value)
                suite["subtests"].append(subtest)
        PERFHERDER_DATA["suites"].append(suite)

print("PERFHERDER_DATA:", json.dumps(PERFHERDER_DATA))

with open("perfherder-data.json", "w") as f:
    f.write(json.dumps(PERFHERDER_DATA))
