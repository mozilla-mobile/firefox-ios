/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

/*
 * The list of phases mapped to their corresponding profiles.  The object
 * here must be in strict JSON format, as it will get parsed by the Python
 * testrunner (no single quotes, extra comma's, etc).
 */
EnableEngines(["tabs"]);

var phases = { "phase1": "profile1", "phase2": "profile1" };


var tabs1 = [
    { uri: "https://example.com/",
      profile: "Fennec on iOS"
    }
];

// sync and verify tabs
Phase("phase1", [
  [Tabs.add, tabs1],
  [Sync]
]);

Phase("phase2", [
  [Sync],
  [Sync],
  [Tabs.verify, tabs1],
  [Sync]
]);
