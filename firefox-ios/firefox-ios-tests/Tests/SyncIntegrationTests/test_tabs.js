/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

/*
 * The list of phases mapped to their corresponding profiles.  The object
 * here must be in strict JSON format, as it will get parsed by the Python
 * testrunner (no single quotes, extra comma's, etc).
 */
EnableEngines(["tabs"]);

var phases = { "phase1": "profile1" };


// expected tabs state
var tabs1 = [
    { uri: "https://example.com/",
      profile: "Fennec (administrator) on iOS"
    }
];

// sync and verify tabs
Phase("phase1", [
  [Sync],
  [Tabs.verify, tabs1]
]);
