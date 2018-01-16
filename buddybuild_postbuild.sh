#!/usr/bin/env bash
bash <(curl -s https://codecov.io/bash)

if [ "$BUDDYBUILD_SCHEME" = "Fennec" ]; then
  curl -F ipa=@$BUDDYBUILD_IPA_PATH -u $NIMBLEDROID_API_KEY: https://nimbledroid.com/api/v2/ipas
fi

