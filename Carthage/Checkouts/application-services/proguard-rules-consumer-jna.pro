# ProGuard rules for consumers of this library.

# JNA specific rules
# See https://github.com/java-native-access/jna/blob/master/www/FrequentlyAskedQuestions.md#jna-on-android
-dontwarn java.awt.*
-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }