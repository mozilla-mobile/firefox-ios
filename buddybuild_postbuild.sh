#!/usr/bin/env bash
bash <(curl -s https://codecov.io/bash)

test_runner="XCUITests-Runner"

if [ "$BUDDYBUILD_SCHEME" = "Fennec" ]; then
  (cd $BUDDYBUILD_PRODUCT_DIR && zip -r $test_runner.zip $test_runner.app)
  curl -F ipa=@$BUDDYBUILD_IPA_PATH \
       -F test_runner=@$BUDDYBUILD_PRODUCT_DIR/$test_runner.zip -F test_identifiers="DomainAutocompleteTest.testAutocomplete" \
       -u $NIMBLEDROID_API_KEY: https://nimbledroid.com/api/v2/ipas
fi

