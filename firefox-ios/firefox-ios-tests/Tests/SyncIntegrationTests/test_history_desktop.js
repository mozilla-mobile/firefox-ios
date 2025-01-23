/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

/*
 * The list of phases mapped to their corresponding profiles.  The object
 * here must be in strict JSON format, as it will get parsed by the Python
 * testrunner (no single quotes, extra comma's, etc).
 */
EnableEngines(["history"]);

var phases = { "phase1": "profile1" };


// expected history state
var historyCreated = [
    { uri: "https://www.example.com/",
      visits: [
        { type: 1 ,
          date: 0 
        },
        { type: 2,
          date: -1
      	}
      ]
    }
];

// sync and verify history
Phase("phase1", [
  [Sync],
  [History.add, historyCreated],
  [Sync]
]);
