## Verifying Glean Ping Data
In order to verify what data is being sent through Glean, you can use the glean debug dashboard here: https://glean-debug-view-dev-237806.firebaseapp.com/

### Steps to test:
* Decide what your tag will be for you to track your Glean pings. It can be anything, but it should not contain spaces or characters that would need to be url escaped and it should be shorter than 20 characters. 
    * Example of valid tag: "Kayla-Glean-Test"
* Add your tag to the end of this Glean debug deeplinking url: "firefox://glean?tagPings="
    * With the above tag, the final url would look like this: "firefox://glean?tagPings=Kayla-Glean-Test"
* Open safari on either the simulator that has firefox installed with the build you are trying to test, or on a device that has the version of firefox you are trying to test installed
* Paste the deeplink url into the safari navigation bar and it should prompt you to open firefox, accept this prompt
* Use firefox to do things that would result in Glean data being sent
* Navigate to the glean debug dashboard here: https://glean-debug-view-dev-237806.firebaseapp.com/
    * You can also navigate to the debug dashboard for your specific tag by appending it to that url like this: https://glean-debug-view-dev-237806.firebaseapp.com/pings/Kayla-Glean-Test
* You should see data appear with the date received, ping type, and payload. You can view the json here to see if your data is being sent in the way you expect. 

You can read more about this in [Glean debugging docs](https://mozilla.github.io/glean/book/user/debugging/ios.html) as well.
