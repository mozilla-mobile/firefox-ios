/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

/*
 * The list of phases mapped to their corresponding profiles.  The object
 * here must be in strict JSON format, as it will get parsed by the Python
 * testrunner (no single quotes, extra comma's, etc).
 */
EnableEngines(["bookmarks", "passwords", "history"]);

var phases = { "phase1": "profile1" };


// expected bookmark state
var bookmarksCreated = {
"mobile": [{
  uri: "http://www.example.com/",
  title: "Example Domain"}]
};

// expected password state
var password_list = [{ 
    hostname: "https://accounts.google.com",
    submitURL: "https://accounts.google.com/signin/challenge/sl/password",
    realm: null,
    username: "iosmztest",
    password: "test15mz",
    usernameField: "Email",
    passwordField: "Passwd",
  }];

// sync and verify password and bookmarks
Phase("phase1", [
  [Sync],
  [Passwords.add, password_list],
  [Bookmarks.add, bookmarksCreated],
  [Sync]
]);
