Firefox for iOS Testing

Softvision Mobile QA - Firefox for iOS testing tasks and process

## Release

* **Frequency**: Each RC

* **Tasks performed by the QA team:**

   * Smoke and sanity testing
   * Exploratory testing
   * Localization testing
   * Bug triage
* **Specific Release testing tasks:**
   *  none
* **Feature coverage**: yes
* **Bug verification coverage**: uplifts

## Beta 

* **Frequency:** every other Beta depending on the number of changes
* **Tasks performed by the QA team:**
   * Smoke and sanity testing
   * Exploratory testing
   * Bug verification
* **Specific Beta testing tasks:**
   * Full functional & UI testing
   * Full Search testing
* **Feature coverage**: yes
* **Bug verification coverage**: uplifts

## Main

* **Frequency**: daily 
* **Tasks performed by the QA team**
   * Smoke and sanity testing
   * Exploratory testing
   * Bug triage
* **Specific Nightly testing tasks**:
   * Feature testing
   * Test case creation
   * Bug verification
* **Feature coverage**: yes
* **Bug verification coverage**: yes

## Release

* **Device coverage**: (unless otherwise specified): iPhones & iPads
   * **iOS version**: latest three versions
   
### Detailed informations about the tasks performed

#### Full-functional & UI testing

* Duration: 2 days 
* Frequency:
    * Usually on first and last Beta
* Description: 
    * Set of tests that cover all functionalities 
    * 2 runs: 1 tablet, and 1 for phone


#### Smoke & sanity testing

* Duration: 1 day
* Frequency: 
    * Release & Beta
    * Nightly: 2-3 times per week (depending on priority of the other tasks)
* Description:
    * Small suite of tests focused on all major functionalities 


#### Feature testing

* Duration: based on feature complexity
* Frequency: when a new feature is implemented
* Description:
    * Creation of test cases
    * Feature bug verification
    * Exploratory testing around the new implementation and different areas that might be affected

#### Bug verification

* Duration: based on bug complexity
* Frequency: daily
* Description:
    * Different devices covered
    * Verify the steps provided in the description on an affected build, in order to reproduce the bug (if it wasn't earlier) and on the build that contains the patch, to confirm the fix.

#### Search testing

   * Duration: 1 day
   * Frequency: RC
   * Description
      * Set of tests that cover the interaction of users with URL bar, search engines & search codes (VPN).

#### Bug Triage

* Duration: based on issue complexity
* Frequency: 
    * Daily/depending on the issues logged by the users 
* Description:
    * Issue investigation based on the information provided by the user

#### Exploratory testing

* Duration: based on area tested
* Frequency (performed with): 
    * Smoke & sanity testing
    * Full functional & UI tests
    * Bug verification
    * Bug triage
* Description:
    * Testing scenarios that are not covered in test runs
