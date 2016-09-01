## Using Adjust for pre-installed apps

If you want to use the Adjust SDK to recognize users that found your app
pre-installed on their device, follow these steps.

1. Integrate Adjust as described in our [README].
2. Create a new tracker in your [dashboard].
3. Open your app delegate and add set the default tracker of your `ADJConfig`:

  ```objc
  ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];
  [adjustConfig setDefaultTracker:@"{TrackerToken}"];
  [Adjust appDidLaunch:adjustConfig];
  ```

  Replace `{TrackerToken}` with the tracker token you created in step 2.
  Please note that the dashboard displays a tracker URL (including
  `http://app.adjust.com/`). In your source code, you should specify only the
  six-character token and not the entire URL.

4. Build and run your app. You should see a line like the following in XCode:

    ```
    Default tracker: 'abc123'
    ```

[README]: ../README.md
[dashboard]: http://adjust.com
