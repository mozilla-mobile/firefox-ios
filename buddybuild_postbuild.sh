#!/usr/bin/env bash

echo "listing build dir in postbuild"
echo $BUDDYBUILD_PRODUCT_DIR
ls $BUDDYBUILD_PRODUCT_DIR

bash <(curl -s https://codecov.io/bash)

test_runner="XCUITests-Runner"
branch_name=`git rev-parse --abbrev-ref HEAD`

if [ "$BUDDYBUILD_SCHEME" = "Fennec"  ] && [ $branch_name == "master" ]; then
  cd  $BUDDYBUILD_PRODUCT_DIR
  find . -name "*.dSYM" -print | zip /tmp/dsyms.zip -@
  curl -F ipa=@$BUDDYBUILD_IPA_PATH  -u $NIMBLEDROID_API_KEY: https://nimbledroid.com/api/v2/ipas \
       -F "dsyms=@/tmp/dsyms.zip" \
       -F device_config='ios10,ios11' \
       -F launch_args='nimbledroid'
       -F test_identifiers='ActivityStreamTest/testDefaultSites,DomainAutocompleteTest/testAutocomplete,DatabaseFixtureTest/testHistoryDatabaseFixture,BrowsingPDFTests/testBookmarkPDF,ActivityStreamTest/testTopSitesBookmarkNewTopSite,FindInPageTests/testFindInLargeDoc,FirstRunTourTests/testFirstRunTour'
# comment out the section where it upload the testrunner
#  (cd $BUDDYBUILD_TEST_DIR/Build/Products/Fennec-iphonesimulator && zip -r $test_runner.zip $test_runner.app)
#      -F test_runner=@$BUDDYBUILD_TEST_DIR/Build/Products/Fennec-iphonesimulator/$test_runner.zip
fi

