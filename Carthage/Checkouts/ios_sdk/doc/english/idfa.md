## Remove IDFA support

If your app got rejected by Apple because your app is using the advertising
identifier, this document is for you.

1. Contact us at [support@adjust.com](mailto:support@adjust.com). We would like
   to make sure that you are aware of the consequences of removing IDFA
   support.

2. After you talked with us, or when you just can't wait any longer, proceed
   with the following steps to remove the IDFA support.

### Remove the AdSupport framework

- In the Project Navigator select your project. Make sure your target is
  selected in the top left corner of the right hand window.

- Select the `Build Phases` tab and expand the group `Link Binary with
  Libraries`.

- Select the `AdSupport.framework` and press the `-` button to remove it.

- In the Project Navigator, expand the group `Frameworks`.

- If the `AdSupport.framework` is in there, right click it, select `Delete` and
  confirm `Remove Reference`.

### Add the compiler flag `ADJUST_NO_IDFA`

- In the Project Navigator select your project. Make sure your target is
  selected in the top left corner of the right hand window.

- Select the `Build Settings` tab and search for `Other C Flags` in the search
  field below.

- Double click on the right side of the `Other C Flags` line to change its
  value

- Press on the `+` button at the bottom of the overlay and paste the following
  text into the selected line:

    ```
    -DADJUST_NO_IDFA
    ```
