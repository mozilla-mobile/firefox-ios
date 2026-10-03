(function () {
    "use strict";

    const host = window.location.hostname;

    // Esegui InsensitiveX esclusivamente su X/Twitter.
    if (
        host !== "x.com" &&
        host !== "www.x.com" &&
        host !== "twitter.com" &&
        host !== "www.twitter.com"
    ) {
        return;
    }

    let initialState;

    try {
        Object.defineProperty(window, "__INITIAL_STATE__", {
            configurable: true,
            enumerable: true,

            get: function () {
                return initialState;
            },

            set: function (state) {
                try {
                    if (
                        state &&
                        state.featureSwitch &&
                        state.featureSwitch.customOverrides
                    ) {
                        state.featureSwitch.customOverrides[
                            "rweb_age_assurance_flow_enabled"
                        ] = false;
                    }
                } catch (error) {
                    console.error("InsensitiveX modification failed:", error);
                }

                initialState = state;
            }
        });
    } catch (error) {
        console.error("InsensitiveX initialization failed:", error);
    }
})();
