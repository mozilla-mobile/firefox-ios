# IFAQ - Infrequently Asked Questions

#### **Why does EarlGrey need to modify the test's scheme and add a Copy Files Build Phase?**

EarlGrey synchronizes by keeping track of the app's internal state. It is essential that EarlGrey
therefore be embedded into the app. Since we do not want users to have EarlGrey directly link to
the app under test or create separate test rigs, we perform the embedding ourselves by adding a
Copy Files Build Phase that copies the *EarlGrey.framework* linked to the test target to the app
under test, as specified by the *$TEST_HOST* variable.

Also, EarlGrey needs to be loaded before the app to ensure that we do not miss any states that
should have been tracked, along with giving EarlGrey fine-grained control of the test's execution.
For this purpose, we add a *DYLD_INSERT_LIBRARIES* environment variable in the test's scheme.
