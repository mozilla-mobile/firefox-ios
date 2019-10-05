/* Any copyright is dedicated to the Public Domain.
   http://creativecommons.org/publicdomain/zero/1.0/ */

/*
 * The list of phases mapped to their corresponding profiles.  The object
 * here must be in strict JSON format, as it will get parsed by the Python
 * testrunner (no single quotes, extra comma's, etc).
 */
EnableEngines(["passwords"]);

var phases = { "phase1": "profile1" };


// expected tabs state
var password_list = [{ 
    hostname: "https://accounts.google.com",
    submitURL: "https://accounts.google.com/signin/challenge/sl/password",
    realm: null,
    username: "iosmztest",
    password: "test15mz",
    usernameField: "Email",
    passwordField: "Passwd",
  }];

// sync and verify tabs
Phase("phase1", [
  [Sync],
  [Passwords.add, password_list],
  [Sync]
]);