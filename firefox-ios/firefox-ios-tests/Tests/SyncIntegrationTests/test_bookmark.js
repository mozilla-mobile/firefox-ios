/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

/*
 * The list of phases mapped to their corresponding profiles.  The object
 * here must be in strict JSON format, as it will get parsed by the Python
 * testrunner (no single quotes, extra comma's, etc).
 */
EnableEngines(["bookmarks"]);

var phases = { "phase1": "profile1" };


// expected bookmark state
var bookmarksExpected = {
"mobile": [{
  uri: "https://www.example.com/",
  title: "Example Domain"}]
};

// sync and verify bookmarks
Phase("phase1", [
  [Sync],
  [Bookmarks.verify, bookmarksExpected],
]);
