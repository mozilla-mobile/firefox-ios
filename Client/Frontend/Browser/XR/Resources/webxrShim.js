//{
//    const REALAPI_URL = 'https://raw.githack.com/MozillaReality/webxr-ios-js/develop/dist/webxr.js';

    const API = [
        'XR',
        'XRSession',
        'XRRenderState',
        'XRFrame',
        'XRSpace',
        'XRReferenceSpace',
        'XRBoundedReferenceSpace',
        'XRView',
        'XRViewport',
        'XRRigidTransform',
        'XRPose',
        'XRViewerPose',
        'XRInputSource',
        'XRInputSourceArray',
        'XRWebGLLayer',
        'XRSessionEvent',
        'XRInputSourceEvent',
        'XRInputSourcesChangeEvent',
        'XRReferenceSpaceEvent'
    ];

    // Note: Currently (10/28/2019) EventTarget can't be extended on Safari
    //     unlike FireFox and Chrome. So declaring our own here for now.
    //       But we don't expose so "navigator.xr instanceof EventTarget" will end up
    //       being false out of this scope. Any problems with this limitation?
    class EventTarget {
        addEventListener() {
            // @TODO: Relax this add/remove/dispatch event limitations?
            throw new Error('Shim: We don\'t expect user adds event before stating session.');
        }
        removeEventListener() {
            throw new Error('Shim: We don\'t expect user removes event before stating session.');
        }
        dispatchEvent() {
            throw new Error('Shim: We don\'t expect user dispatches event before stating session.');
        }
    }

    const install = () => {
        for (const name of API) {
            if (window[name] !== undefined) { continue; }
            switch (name) {
                case 'XR':
                    installXR();
                    break;
                case 'XRRenderState':
                case 'XRFrame':
                case 'XRView':
                case 'XRViewport':
                case 'XRRigidTransform':
                case 'XRPose':
                case 'XRInputSource':
                case 'XRInputSourceArray':
                case 'XRWebGLLayer':
                    window[name] = class {
                        constructor() {
                            // Note: XRRigidTransform should be able to be instanciated by user
                            //       even before starting session but prohibiting as Shim limitation so far.
                            throw new Error('Shim: We don\'t expect user instanciates XR classes');
                        }
                    };
                    break;
                case 'XRSession':
                case 'XRSpace':
                    window[name] = class extends EventTarget {
                        constructor() {
                            throw new Error('Shim: We don\'t expect user instanciates XR classes');
                        }
                    };
                    break;
                case 'XRReferenceSpace':
                    window[name] = class extends XRSpace {
                        constructor() {
                            throw new Error('Shim: We don\'t expect user instanciates XR classes');
                        }
                    };
                    break;
                case 'XRBoundedReferenceSpace':
                    window[name] = class extends XRReferenceSpace {
                        constructor() {
                            throw new Error('Shim: We don\'t expect user instanciates XR classes');
                        }
                    };
                    break;
                case 'XRViewerPose':
                    window[name] = class extends XRPose {
                        constructor() {
                            throw new Error('Shim: We don\'t expect user instanciates XR classes');
                        }
                    };
                    break;
                case 'XRSessionEvent':
                case 'XRInputSourceEvent':
                case 'XRInputSourcesChangeEvent':
                case 'XRReferenceSpaceEvent':
                    window[name] = class extends Event {
                        constructor() {
                            throw new Error('Shim: We don\'t expect user instanciates XR classes');
                        }
                    };
                    break;
                default:
                    console.error('Unknown API name, ', name);
            };
        }
        if (navigator.xr === undefined) { navigator.xr = new XR(); }
    };

    const installXR = () => {
        let instanciated = false;
        window.XR = class extends EventTarget {
            constructor() {
                super();
                // Note: Allow instance creation only once and refuse from out of this scope.
                if (instanciated) {
                    throw new Error('Shim: We don\'t expect user instanciates XR classes');
                }
                instanciated = true;
            }
            isSessionSupported(mode) {
                // Note: We support only immersive-ar mode for now.
                //       See https://github.com/MozillaReality/webxr-ios-js/pull/34#discussion_r334910337
                return Promise.resolve(mode === 'immersive-ar');
            }
            requestSession(mode, opts) {
                console.log("going to load from ", REALAPI_URL)
                return new Promise((resolve, reject) => {
                    // Note: Uninstall fake XR classes here because the polyfill declares them.
                    //       Until the polyfill is loaded they are undefined.
                    //       Can this cause any problems?
                    uninstall();

                    const script = document.createElement('script');
                    script.setAttribute('src', REALAPI_URL);
                    script.setAttribute('type', 'text/javascript');

                    let loaded = false;
                    const loadFunction = () => {
                        if (loaded) return;
                        loaded = true;
                        console.log("now the script is really loaded", navigator.xr);
                        navigator.xr.requestSession(mode, opts).then(resolve).catch(reject);
                    };
                    script.onload = loadFunction;
                    script.onreadystatechange = loadFunction;
                    document.getElementsByTagName('head')[0].appendChild(script);
                });
            }
            get ondevicechange() { return null; }
            set ondevicechange(value) {
                // @TODO: Relax this limitation?
                throw new Error('Shim: We don\'t expect user sets devicechange event before starting session.');
            }
        };
    };

    const uninstall = () => {
        for (const name of API) {
            delete window[name];
        }
        delete navigator.xr;
    };

    install();
}
