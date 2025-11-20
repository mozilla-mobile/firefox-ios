/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

function loadBergamot(Module) {
  var BERGAMOT_VERSION_FULL = "v0.6.0+4a6a44c0";
  null;

  var Module = typeof Module != "undefined" ? Module : {};

  var moduleOverrides = Object.assign({}, Module);

  var arguments_ = [];

  var thisProgram = "./this.program";

  var quit_ = (status, toThrow) => {
    throw toThrow;
  };

  var ENVIRONMENT_IS_WEB = typeof window == "object";

  var ENVIRONMENT_IS_WORKER = typeof importScripts == "function";

  var ENVIRONMENT_IS_NODE =
    typeof process == "object" &&
    typeof process.versions == "object" &&
    typeof process.versions.node == "string";

  var scriptDirectory = "";

  function locateFile(path) {
    if (Module.locateFile) {
      return Module.locateFile(path, scriptDirectory);
    }
    return scriptDirectory + path;
  }

  var read_, readAsync, readBinary, setWindowTitle;

  if (ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER) {
    if (ENVIRONMENT_IS_WORKER) {
      scriptDirectory = self.location.href;
    } else if (typeof document != "undefined" && document.currentScript) {
      scriptDirectory = document.currentScript.src;
    }
    if (scriptDirectory.indexOf("blob:") !== 0) {
      scriptDirectory = scriptDirectory.substr(
        0,
        scriptDirectory.replace(/[?#].*/, "").lastIndexOf("/") + 1
      );
    } else {
      scriptDirectory = "";
    }
    {
      read_ = url => {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, false);
        xhr.send(null);
        return xhr.responseText;
      };
      if (ENVIRONMENT_IS_WORKER) {
        readBinary = url => {
          var xhr = new XMLHttpRequest();
          xhr.open("GET", url, false);
          xhr.responseType = "arraybuffer";
          xhr.send(null);
          return new Uint8Array(xhr.response);
        };
      }
      readAsync = (url, onload, onerror) => {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.responseType = "arraybuffer";
        xhr.onload = () => {
          if (xhr.status == 200 || (xhr.status == 0 && xhr.response)) {
            onload(xhr.response);
            return;
          }
          onerror();
        };
        xhr.onerror = onerror;
        xhr.send(null);
      };
    }
    setWindowTitle = title => (document.title = title);
  } else {
  }

  var out = Module.print || console.log.bind(console);

  var err = Module.printErr || console.warn.bind(console);

  Object.assign(Module, moduleOverrides);

  moduleOverrides = null;

  if (Module.arguments) {
    arguments_ = Module.arguments;
  }

  if (Module.thisProgram) {
    thisProgram = Module.thisProgram;
  }

  if (Module.quit) {
    quit_ = Module.quit;
  }

  var tempRet0 = 0;

  var setTempRet0 = value => {
    tempRet0 = value;
  };

  var wasmBinary;

  if (Module.wasmBinary) {
    wasmBinary = Module.wasmBinary;
  }

  var noExitRuntime = Module.noExitRuntime || true;

  if (typeof WebAssembly != "object") {
    abort("no native wasm support detected");
  }

  function setValue(ptr, value, type = "i8", noSafe) {
    if (type.charAt(type.length - 1) === "*") {
      type = "i32";
    }
    switch (type) {
      case "i1":
        HEAP8[ptr >> 0] = value;
        break;

      case "i8":
        HEAP8[ptr >> 0] = value;
        break;

      case "i16":
        HEAP16[ptr >> 1] = value;
        break;

      case "i32":
        HEAP32[ptr >> 2] = value;
        break;

      case "i64":
        ((tempI64 = [
          value >>> 0,
          ((tempDouble = value),
          +Math.abs(tempDouble) >= 1
            ? tempDouble > 0
              ? (Math.min(+Math.floor(tempDouble / 4294967296), 4294967295) |
                  0) >>>
                0
              : ~~+Math.ceil(
                  (tempDouble - +(~~tempDouble >>> 0)) / 4294967296
                ) >>> 0
            : 0),
        ]),
          (HEAP32[ptr >> 2] = tempI64[0]),
          (HEAP32[(ptr + 4) >> 2] = tempI64[1]));
        break;

      case "float":
        HEAPF32[ptr >> 2] = value;
        break;

      case "double":
        HEAPF64[ptr >> 3] = value;
        break;

      default:
        abort("invalid type for setValue: " + type);
    }
  }

  var wasmMemory;

  var ABORT = false;

  var EXITSTATUS;

  function assert(condition, text) {
    if (!condition) {
      abort(text);
    }
  }

  var UTF8Decoder =
    typeof TextDecoder != "undefined" ? new TextDecoder("utf8") : undefined;

  function UTF8ArrayToString(heapOrArray, idx, maxBytesToRead) {
    var endIdx = idx + maxBytesToRead;
    var endPtr = idx;
    while (heapOrArray[endPtr] && !(endPtr >= endIdx)) {
      ++endPtr;
    }
    if (endPtr - idx > 16 && heapOrArray.buffer && UTF8Decoder) {
      return UTF8Decoder.decode(heapOrArray.subarray(idx, endPtr));
    }
    var str = "";
    while (idx < endPtr) {
      var u0 = heapOrArray[idx++];
      if (!(u0 & 128)) {
        str += String.fromCharCode(u0);
        continue;
      }
      var u1 = heapOrArray[idx++] & 63;
      if ((u0 & 224) == 192) {
        str += String.fromCharCode(((u0 & 31) << 6) | u1);
        continue;
      }
      var u2 = heapOrArray[idx++] & 63;
      if ((u0 & 240) == 224) {
        u0 = ((u0 & 15) << 12) | (u1 << 6) | u2;
      } else {
        u0 =
          ((u0 & 7) << 18) | (u1 << 12) | (u2 << 6) | (heapOrArray[idx++] & 63);
      }
      if (u0 < 65536) {
        str += String.fromCharCode(u0);
      } else {
        var ch = u0 - 65536;
        str += String.fromCharCode(55296 | (ch >> 10), 56320 | (ch & 1023));
      }
    }

    return str;
  }

  function UTF8ToString(ptr, maxBytesToRead) {
    return ptr ? UTF8ArrayToString(HEAPU8, ptr, maxBytesToRead) : "";
  }

  function stringToUTF8Array(str, heap, outIdx, maxBytesToWrite) {
    if (!(maxBytesToWrite > 0)) {
      return 0;
    }
    var startIdx = outIdx;
    var endIdx = outIdx + maxBytesToWrite - 1;
    for (var i = 0; i < str.length; ++i) {
      var u = str.charCodeAt(i);
      if (u >= 55296 && u <= 57343) {
        var u1 = str.charCodeAt(++i);
        u = (65536 + ((u & 1023) << 10)) | (u1 & 1023);
      }
      if (u <= 127) {
        if (outIdx >= endIdx) {
          break;
        }
        heap[outIdx++] = u;
      } else if (u <= 2047) {
        if (outIdx + 1 >= endIdx) {
          break;
        }
        heap[outIdx++] = 192 | (u >> 6);
        heap[outIdx++] = 128 | (u & 63);
      } else if (u <= 65535) {
        if (outIdx + 2 >= endIdx) {
          break;
        }
        heap[outIdx++] = 224 | (u >> 12);
        heap[outIdx++] = 128 | ((u >> 6) & 63);
        heap[outIdx++] = 128 | (u & 63);
      } else {
        if (outIdx + 3 >= endIdx) {
          break;
        }
        heap[outIdx++] = 240 | (u >> 18);
        heap[outIdx++] = 128 | ((u >> 12) & 63);
        heap[outIdx++] = 128 | ((u >> 6) & 63);
        heap[outIdx++] = 128 | (u & 63);
      }
    }
    heap[outIdx] = 0;
    return outIdx - startIdx;
  }

  function stringToUTF8(str, outPtr, maxBytesToWrite) {
    return stringToUTF8Array(str, HEAPU8, outPtr, maxBytesToWrite);
  }

  function lengthBytesUTF8(str) {
    var len = 0;
    for (var i = 0; i < str.length; ++i) {
      var u = str.charCodeAt(i);
      if (u >= 55296 && u <= 57343) {
        u = (65536 + ((u & 1023) << 10)) | (str.charCodeAt(++i) & 1023);
      }
      if (u <= 127) {
        ++len;
      } else if (u <= 2047) {
        len += 2;
      } else if (u <= 65535) {
        len += 3;
      } else {
        len += 4;
      }
    }
    return len;
  }

  var UTF16Decoder =
    typeof TextDecoder != "undefined" ? new TextDecoder("utf-16le") : undefined;

  function UTF16ToString(ptr, maxBytesToRead) {
    var endPtr = ptr;
    var idx = endPtr >> 1;
    var maxIdx = idx + maxBytesToRead / 2;
    while (!(idx >= maxIdx) && HEAPU16[idx]) {
      ++idx;
    }
    endPtr = idx << 1;
    if (endPtr - ptr > 32 && UTF16Decoder) {
      return UTF16Decoder.decode(HEAPU8.subarray(ptr, endPtr));
    }
    var str = "";
    for (var i = 0; !(i >= maxBytesToRead / 2); ++i) {
      var codeUnit = HEAP16[(ptr + i * 2) >> 1];
      if (codeUnit == 0) {
        break;
      }
      str += String.fromCharCode(codeUnit);
    }
    return str;
  }

  function stringToUTF16(str, outPtr, maxBytesToWrite) {
    if (maxBytesToWrite === undefined) {
      maxBytesToWrite = 2147483647;
    }
    if (maxBytesToWrite < 2) {
      return 0;
    }
    maxBytesToWrite -= 2;
    var startPtr = outPtr;
    var numCharsToWrite =
      maxBytesToWrite < str.length * 2 ? maxBytesToWrite / 2 : str.length;
    for (var i = 0; i < numCharsToWrite; ++i) {
      var codeUnit = str.charCodeAt(i);
      HEAP16[outPtr >> 1] = codeUnit;
      outPtr += 2;
    }
    HEAP16[outPtr >> 1] = 0;
    return outPtr - startPtr;
  }

  function lengthBytesUTF16(str) {
    return str.length * 2;
  }

  function UTF32ToString(ptr, maxBytesToRead) {
    var i = 0;
    var str = "";
    while (!(i >= maxBytesToRead / 4)) {
      var utf32 = HEAP32[(ptr + i * 4) >> 2];
      if (utf32 == 0) {
        break;
      }
      ++i;
      if (utf32 >= 65536) {
        var ch = utf32 - 65536;
        str += String.fromCharCode(55296 | (ch >> 10), 56320 | (ch & 1023));
      } else {
        str += String.fromCharCode(utf32);
      }
    }
    return str;
  }

  function stringToUTF32(str, outPtr, maxBytesToWrite) {
    if (maxBytesToWrite === undefined) {
      maxBytesToWrite = 2147483647;
    }
    if (maxBytesToWrite < 4) {
      return 0;
    }
    var startPtr = outPtr;
    var endPtr = startPtr + maxBytesToWrite - 4;
    for (var i = 0; i < str.length; ++i) {
      var codeUnit = str.charCodeAt(i);
      if (codeUnit >= 55296 && codeUnit <= 57343) {
        var trailSurrogate = str.charCodeAt(++i);
        codeUnit =
          (65536 + ((codeUnit & 1023) << 10)) | (trailSurrogate & 1023);
      }
      HEAP32[outPtr >> 2] = codeUnit;
      outPtr += 4;
      if (outPtr + 4 > endPtr) {
        break;
      }
    }
    HEAP32[outPtr >> 2] = 0;
    return outPtr - startPtr;
  }

  function lengthBytesUTF32(str) {
    var len = 0;
    for (var i = 0; i < str.length; ++i) {
      var codeUnit = str.charCodeAt(i);
      if (codeUnit >= 55296 && codeUnit <= 57343) {
        ++i;
      }
      len += 4;
    }
    return len;
  }

  function allocateUTF8(str) {
    var size = lengthBytesUTF8(str) + 1;
    var ret = _malloc(size);
    if (ret) {
      stringToUTF8Array(str, HEAP8, ret, size);
    }
    return ret;
  }

  function writeArrayToMemory(array, buffer) {
    HEAP8.set(array, buffer);
  }

  function writeAsciiToMemory(str, buffer, dontAddNull) {
    for (var i = 0; i < str.length; ++i) {
      HEAP8[buffer++ >> 0] = str.charCodeAt(i);
    }
    if (!dontAddNull) {
      HEAP8[buffer >> 0] = 0;
    }
  }

  var buffer, HEAP8, HEAPU8, HEAP16, HEAPU16, HEAP32, HEAPU32, HEAPF32, HEAPF64;

  function updateGlobalBufferAndViews(buf) {
    const mb = (buf.byteLength / 1_000_000).toFixed();
    Module.print(`Growing wasm buffer to ${mb}MB (${buf.byteLength} bytes).`);

    buffer = buf;
    Module.HEAP8 = HEAP8 = new Int8Array(buf);
    Module.HEAP16 = HEAP16 = new Int16Array(buf);
    Module.HEAP32 = HEAP32 = new Int32Array(buf);
    Module.HEAPU8 = HEAPU8 = new Uint8Array(buf);
    Module.HEAPU16 = HEAPU16 = new Uint16Array(buf);
    Module.HEAPU32 = HEAPU32 = new Uint32Array(buf);
    Module.HEAPF32 = HEAPF32 = new Float32Array(buf);
    Module.HEAPF64 = HEAPF64 = new Float64Array(buf);
  }

  var INITIAL_MEMORY = Module.INITIAL_MEMORY || 16777216;

  if (Module.wasmMemory) {
    wasmMemory = Module.wasmMemory;
  } else {
    wasmMemory = new WebAssembly.Memory({
      initial: INITIAL_MEMORY / 65536,
      maximum: 2147483648 / 65536,
    });
  }

  if (wasmMemory) {
    buffer = wasmMemory.buffer;
  }

  INITIAL_MEMORY = buffer.byteLength;

  updateGlobalBufferAndViews(buffer);

  var wasmTable;

  var __ATPRERUN__ = [];

  var __ATINIT__ = [];

  var __ATPOSTRUN__ = [];

  var runtimeInitialized = false;

  function keepRuntimeAlive() {
    return noExitRuntime;
  }

  function preRun() {
    if (Module.preRun) {
      if (typeof Module.preRun == "function") {
        Module.preRun = [Module.preRun];
      }
      while (Module.preRun.length) {
        addOnPreRun(Module.preRun.shift());
      }
    }
    callRuntimeCallbacks(__ATPRERUN__);
  }

  function initRuntime() {
    runtimeInitialized = true;
    callRuntimeCallbacks(__ATINIT__);
  }

  function postRun() {
    if (Module.postRun) {
      if (typeof Module.postRun == "function") {
        Module.postRun = [Module.postRun];
      }
      while (Module.postRun.length) {
        addOnPostRun(Module.postRun.shift());
      }
    }
    callRuntimeCallbacks(__ATPOSTRUN__);
  }

  function addOnPreRun(cb) {
    __ATPRERUN__.unshift(cb);
  }

  function addOnInit(cb) {
    __ATINIT__.unshift(cb);
  }

  function addOnPostRun(cb) {
    __ATPOSTRUN__.unshift(cb);
  }

  var runDependencies = 0;

  var runDependencyWatcher = null;

  var dependenciesFulfilled = null;

  function addRunDependency(id) {
    runDependencies++;
    if (Module.monitorRunDependencies) {
      Module.monitorRunDependencies(runDependencies);
    }
  }

  function removeRunDependency(id) {
    runDependencies--;
    if (Module.monitorRunDependencies) {
      Module.monitorRunDependencies(runDependencies);
    }
    if (runDependencies == 0) {
      if (runDependencyWatcher !== null) {
        clearInterval(runDependencyWatcher);
        runDependencyWatcher = null;
      }
      if (dependenciesFulfilled) {
        var callback = dependenciesFulfilled;
        dependenciesFulfilled = null;
        callback();
      }
    }
  }

  Module.preloadedImages = {};

  Module.preloadedAudios = {};

  function abort(what) {
    {
      if (Module.onAbort) {
        Module.onAbort(what);
      }
    }
    what = "Aborted(" + what + ")";
    err(what);
    ABORT = true;
    EXITSTATUS = 1;
    what += ". Build with -s ASSERTIONS=1 for more info.";
    var e = new WebAssembly.RuntimeError(what);
    throw e;
  }

  var dataURIPrefix = "data:application/octet-stream;base64,";

  function isDataURI(filename) {
    return filename.startsWith(dataURIPrefix);
  }

  var wasmBinaryFile;

  wasmBinaryFile = "bergamot-translator.wasm";

  if (!isDataURI(wasmBinaryFile)) {
    wasmBinaryFile = locateFile(wasmBinaryFile);
  }

  function getBinary(file) {
    try {
      if (file == wasmBinaryFile && wasmBinary) {
        return new Uint8Array(wasmBinary);
      }
      if (readBinary) {
        return readBinary(file);
      }
      throw "both async and sync fetching of the wasm failed";
    } catch (err) {
      abort(err);
    }
  }

  function getBinaryPromise() {
    if (!wasmBinary && (ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER)) {
      if (typeof fetch == "function") {
        return fetch(wasmBinaryFile, {
          credentials: "same-origin",
        })
          .then(function (response) {
            if (!response.ok) {
              throw (
                "failed to load wasm binary file at '" + wasmBinaryFile + "'"
              );
            }
            return response.arrayBuffer();
          })
          .catch(function () {
            return getBinary(wasmBinaryFile);
          });
      }
    }
    return Promise.resolve().then(function () {
      return getBinary(wasmBinaryFile);
    });
  }

  function createWasm() {
    var info = {
      env: asmLibraryArg,
      wasm_gemm: createWasmGemm(),
      wasi_snapshot_preview1: asmLibraryArg,
    };
    function receiveInstance(instance, module) {
      var exports = instance.exports;
      Module.asm = exports;
      wasmTable = Module.asm.__indirect_function_table;
      addOnInit(Module.asm.__wasm_call_ctors);
      exportAsmFunctions(exports);
      removeRunDependency("wasm-instantiate");
    }
    addRunDependency("wasm-instantiate");
    function receiveInstantiationResult(result) {
      receiveInstance(result.instance);
    }
    function instantiateArrayBuffer(receiver) {
      // This function has been patched from the original version.
      // See Bug 1988289.
      return getBinaryPromise()
        .then(binary => {
          const module = new WebAssembly.Module(binary);
          const instance = new WebAssembly.Instance(module, info);
          return { module, instance };
        })
        .then(function (instance) {
          return instance;
        })
        .then(receiver, function (reason) {
          err("failed to asynchronously prepare wasm: " + reason);
          abort(reason);
        });
    }
    function instantiateAsync() {
      if (
        !wasmBinary &&
        typeof WebAssembly.instantiateStreaming == "function" &&
        !isDataURI(wasmBinaryFile) &&
        typeof fetch == "function"
      ) {
        return fetch(wasmBinaryFile, {
          credentials: "same-origin",
        }).then(function (response) {
          var result = WebAssembly.instantiateStreaming(response, info);
          return result.then(receiveInstantiationResult, function (reason) {
            err("wasm streaming compile failed: " + reason);
            err("falling back to ArrayBuffer instantiation");
            return instantiateArrayBuffer(receiveInstantiationResult);
          });
        });
      }
      return instantiateArrayBuffer(receiveInstantiationResult);
    }
    if (Module.instantiateWasm) {
      try {
        var exports = Module.instantiateWasm(info, receiveInstance);
        return exports;
      } catch (e) {
        err("Module.instantiateWasm callback failed with error: " + e);
        return false;
      }
    }
    instantiateAsync();
    return {};
  }

  var tempDouble;

  var tempI64;

  var ASM_CONSTS = {
    1427332($0, $1, $2, $3, $4) {
      if (!Module.getOrCreateSentenceSegmenter) {
        Module.getOrCreateSentenceSegmenter = (function () {
          let segmenters = new Map();
          return function (lang) {
            let segmenter = segmenters.get(lang);
            if (!segmenter) {
              segmenter = new Intl.Segmenter(lang, {
                granularity: "sentence",
              });
              segmenters.set(lang, segmenter);
            }
            return segmenter;
          };
        })();
      }
      const inputUTF16 = UTF8ToString($0);
      const lang = UTF8ToString($1);
      const segmenter = Module.getOrCreateSentenceSegmenter(lang);
      const sentencesUTF16 = Array.from(segmenter.segment(inputUTF16));
      const sentenceCount = sentencesUTF16.length;
      const bytesPerInt = 4;
      const startsPtr = _malloc(sentenceCount * bytesPerInt);
      const endsPtr = _malloc(sentenceCount * bytesPerInt);
      if (!startsPtr || !endsPtr) {
        throw new Error("Failed to allocate WASM memory for segmentation.");
      }
      let sentenceEndUTF8 = 0;
      sentencesUTF16.forEach(({ segment: sentenceUTF16 }, index) => {
        const sentenceStartUTF8 = sentenceEndUTF8;
        sentenceEndUTF8 += lengthBytesUTF8(sentenceUTF16);
        setValue(startsPtr + index * bytesPerInt, sentenceStartUTF8, "i32");
        setValue(endsPtr + index * bytesPerInt, sentenceEndUTF8, "i32");
      });
      setValue($2, sentenceCount, "i32");
      setValue($3, startsPtr, "i32");
      setValue($4, endsPtr, "i32");
    },
  };

  function callRuntimeCallbacks(callbacks) {
    while (callbacks.length) {
      var callback = callbacks.shift();
      if (typeof callback == "function") {
        callback(Module);
        continue;
      }
      var func = callback.func;
      if (typeof func == "number") {
        if (callback.arg === undefined) {
          getWasmTableEntry(func)();
        } else {
          getWasmTableEntry(func)(callback.arg);
        }
      } else {
        func(callback.arg === undefined ? null : callback.arg);
      }
    }
  }

  function asmjsMangle(x) {
    var unmangledSymbols = ["stackAlloc", "stackSave", "stackRestore"];
    return x.indexOf("dynCall_") == 0 || unmangledSymbols.includes(x)
      ? x
      : "_" + x;
  }

  function exportAsmFunctions(asm) {
    var global_object = this;
    for (var __exportedFunc in asm) {
      var jsname = asmjsMangle(__exportedFunc);
      global_object[jsname] = Module[jsname] = asm[__exportedFunc];
    }
  }

  var wasmTableMirror = [];

  function getWasmTableEntry(funcPtr) {
    var func = wasmTableMirror[funcPtr];
    if (!func) {
      if (funcPtr >= wasmTableMirror.length) {
        wasmTableMirror.length = funcPtr + 1;
      }
      wasmTableMirror[funcPtr] = func = wasmTable.get(funcPtr);
    }
    return func;
  }

  function ___assert_fail(condition, filename, line, func) {
    abort(
      "Assertion failed: " +
        UTF8ToString(condition) +
        ", at: " +
        [
          filename ? UTF8ToString(filename) : "unknown filename",
          line,
          func ? UTF8ToString(func) : "unknown function",
        ]
    );
  }

  function ___cxa_allocate_exception(size) {
    return _malloc(size + 16) + 16;
  }

  var exceptionCaught = [];

  var exceptionLast = 0;

  var uncaughtExceptionCount = 0;

  function ___cxa_rethrow() {
    var catchInfo = exceptionCaught.pop();
    if (!catchInfo) {
      abort("no exception to throw");
    }
    var info = catchInfo.get_exception_info();
    var ptr = catchInfo.get_base_ptr();
    if (!info.get_rethrown()) {
      exceptionCaught.push(catchInfo);
      info.set_rethrown(true);
      info.set_caught(false);
      uncaughtExceptionCount++;
    } else {
      catchInfo.free();
    }
    exceptionLast = ptr;
    throw ptr;
  }

  function ExceptionInfo(excPtr) {
    this.excPtr = excPtr;
    this.ptr = excPtr - 16;
    this.set_type = function (type) {
      HEAP32[(this.ptr + 4) >> 2] = type;
    };
    this.get_type = function () {
      return HEAP32[(this.ptr + 4) >> 2];
    };
    this.set_destructor = function (destructor) {
      HEAP32[(this.ptr + 8) >> 2] = destructor;
    };
    this.get_destructor = function () {
      return HEAP32[(this.ptr + 8) >> 2];
    };
    this.set_refcount = function (refcount) {
      HEAP32[this.ptr >> 2] = refcount;
    };
    this.set_caught = function (caught) {
      caught = caught ? 1 : 0;
      HEAP8[(this.ptr + 12) >> 0] = caught;
    };
    this.get_caught = function () {
      return HEAP8[(this.ptr + 12) >> 0] != 0;
    };
    this.set_rethrown = function (rethrown) {
      rethrown = rethrown ? 1 : 0;
      HEAP8[(this.ptr + 13) >> 0] = rethrown;
    };
    this.get_rethrown = function () {
      return HEAP8[(this.ptr + 13) >> 0] != 0;
    };
    this.init = function (type, destructor) {
      this.set_type(type);
      this.set_destructor(destructor);
      this.set_refcount(0);
      this.set_caught(false);
      this.set_rethrown(false);
    };
    this.add_ref = function () {
      var value = HEAP32[this.ptr >> 2];
      HEAP32[this.ptr >> 2] = value + 1;
    };
    this.release_ref = function () {
      var prev = HEAP32[this.ptr >> 2];
      HEAP32[this.ptr >> 2] = prev - 1;
      return prev === 1;
    };
  }

  function ___cxa_throw(ptr, type, destructor) {
    var info = new ExceptionInfo(ptr);
    info.init(type, destructor);
    exceptionLast = ptr;
    uncaughtExceptionCount++;
    throw ptr;
  }

  var SYSCALLS = {
    buffers: [null, [], []],
    printChar(stream, curr) {
      var buffer = SYSCALLS.buffers[stream];
      if (curr === 0 || curr === 10) {
        (stream === 1 ? out : err)(UTF8ArrayToString(buffer, 0));
        buffer.length = 0;
      } else {
        buffer.push(curr);
      }
    },
    varargs: undefined,
    get() {
      SYSCALLS.varargs += 4;
      var ret = HEAP32[(SYSCALLS.varargs - 4) >> 2];
      return ret;
    },
    getStr(ptr) {
      var ret = UTF8ToString(ptr);
      return ret;
    },
    get64(low, high) {
      return low;
    },
  };

  function ___syscall_faccessat(dirfd, path, amode, flags) {
    path = SYSCALLS.getStr(path);
    path = SYSCALLS.calculateAt(dirfd, path);
    return SYSCALLS.doAccess(path, amode);
  }

  function ___syscall_fcntl64(fd, cmd, varargs) {
    SYSCALLS.varargs = varargs;
    return 0;
  }

  function ___syscall_fstat64(fd, buf) {}

  function ___syscall_getcwd(buf, size) {}

  function ___syscall_ioctl(fd, op, varargs) {
    SYSCALLS.varargs = varargs;
    return 0;
  }

  function ___syscall_lstat64(path, buf) {}

  function ___syscall_newfstatat(dirfd, path, buf, flags) {}

  function ___syscall_openat(dirfd, path, flags, varargs) {
    SYSCALLS.varargs = varargs;
  }

  function ___syscall_renameat(olddirfd, oldpath, newdirfd, newpath) {}

  function ___syscall_rmdir(path) {}

  function ___syscall_stat64(path, buf) {}

  function ___syscall_unlinkat(dirfd, path, flags) {}

  var structRegistrations = {};

  function runDestructors(destructors) {
    while (destructors.length) {
      var ptr = destructors.pop();
      var del = destructors.pop();
      del(ptr);
    }
  }

  function simpleReadValueFromPointer(pointer) {
    return this.fromWireType(HEAPU32[pointer >> 2]);
  }

  var awaitingDependencies = {};

  var registeredTypes = {};

  var typeDependencies = {};

  var char_0 = 48;

  var char_9 = 57;

  function makeLegalFunctionName(name) {
    if (undefined === name) {
      return "_unknown";
    }
    name = name.replace(/[^a-zA-Z0-9_]/g, "$");
    var f = name.charCodeAt(0);
    if (f >= char_0 && f <= char_9) {
      return "_" + name;
    }
    return name;
  }

  function createNamedFunction(name, body) {
    name = makeLegalFunctionName(name);
    return function () {
      null;
      return body.apply(this, arguments);
    };
  }

  function extendError(baseErrorType, errorName) {
    var errorClass = createNamedFunction(errorName, function (message) {
      this.name = errorName;
      this.message = message;
      var stack = new Error(message).stack;
      if (stack !== undefined) {
        this.stack =
          this.toString() + "\n" + stack.replace(/^Error(:[^\n]*)?\n/, "");
      }
    });
    errorClass.prototype = Object.create(baseErrorType.prototype);
    errorClass.prototype.constructor = errorClass;
    errorClass.prototype.toString = function () {
      if (this.message === undefined) {
        return this.name;
      }
      return this.name + ": " + this.message;
    };
    return errorClass;
  }

  var InternalError = undefined;

  function throwInternalError(message) {
    throw new InternalError(message);
  }

  function whenDependentTypesAreResolved(
    myTypes,
    dependentTypes,
    getTypeConverters
  ) {
    myTypes.forEach(function (type) {
      typeDependencies[type] = dependentTypes;
    });
    function onComplete(typeConverters) {
      var myTypeConverters = getTypeConverters(typeConverters);
      if (myTypeConverters.length !== myTypes.length) {
        throwInternalError("Mismatched type converter count");
      }
      for (var i = 0; i < myTypes.length; ++i) {
        registerType(myTypes[i], myTypeConverters[i]);
      }
    }
    var typeConverters = new Array(dependentTypes.length);
    var unregisteredTypes = [];
    var registered = 0;
    dependentTypes.forEach((dt, i) => {
      if (registeredTypes.hasOwnProperty(dt)) {
        typeConverters[i] = registeredTypes[dt];
      } else {
        unregisteredTypes.push(dt);
        if (!awaitingDependencies.hasOwnProperty(dt)) {
          awaitingDependencies[dt] = [];
        }
        awaitingDependencies[dt].push(() => {
          typeConverters[i] = registeredTypes[dt];
          ++registered;
          if (registered === unregisteredTypes.length) {
            onComplete(typeConverters);
          }
        });
      }
    });
    if (0 === unregisteredTypes.length) {
      onComplete(typeConverters);
    }
  }

  function __embind_finalize_value_object(structType) {
    var reg = structRegistrations[structType];
    delete structRegistrations[structType];
    var rawConstructor = reg.rawConstructor;
    var rawDestructor = reg.rawDestructor;
    var fieldRecords = reg.fields;
    var fieldTypes = fieldRecords
      .map(field => field.getterReturnType)
      .concat(fieldRecords.map(field => field.setterArgumentType));
    whenDependentTypesAreResolved([structType], fieldTypes, fieldTypes => {
      var fields = {};
      fieldRecords.forEach((field, i) => {
        var fieldName = field.fieldName;
        var getterReturnType = fieldTypes[i];
        var getter = field.getter;
        var getterContext = field.getterContext;
        var setterArgumentType = fieldTypes[i + fieldRecords.length];
        var setter = field.setter;
        var setterContext = field.setterContext;
        fields[fieldName] = {
          read: ptr => {
            return getterReturnType.fromWireType(getter(getterContext, ptr));
          },
          write: (ptr, o) => {
            var destructors = [];
            setter(
              setterContext,
              ptr,
              setterArgumentType.toWireType(destructors, o)
            );
            runDestructors(destructors);
          },
        };
      });
      return [
        {
          name: reg.name,
          fromWireType: function (ptr) {
            var rv = {};
            for (var i in fields) {
              rv[i] = fields[i].read(ptr);
            }
            rawDestructor(ptr);
            return rv;
          },
          toWireType: function (destructors, o) {
            for (var fieldName in fields) {
              if (!(fieldName in o)) {
                throw new TypeError('Missing field:  "' + fieldName + '"');
              }
            }
            var ptr = rawConstructor();
            for (fieldName in fields) {
              fields[fieldName].write(ptr, o[fieldName]);
            }
            if (destructors !== null) {
              destructors.push(rawDestructor, ptr);
            }
            return ptr;
          },
          argPackAdvance: 8,
          readValueFromPointer: simpleReadValueFromPointer,
          destructorFunction: rawDestructor,
        },
      ];
    });
  }

  function __embind_register_bigint(
    primitiveType,
    name,
    size,
    minRange,
    maxRange
  ) {}

  function getShiftFromSize(size) {
    switch (size) {
      case 1:
        return 0;

      case 2:
        return 1;

      case 4:
        return 2;

      case 8:
        return 3;

      default:
        throw new TypeError("Unknown type size: " + size);
    }
  }

  function embind_init_charCodes() {
    var codes = new Array(256);
    for (var i = 0; i < 256; ++i) {
      codes[i] = String.fromCharCode(i);
    }
    embind_charCodes = codes;
  }

  var embind_charCodes = undefined;

  function readLatin1String(ptr) {
    var ret = "";
    var c = ptr;
    while (HEAPU8[c]) {
      ret += embind_charCodes[HEAPU8[c++]];
    }
    return ret;
  }

  var BindingError = undefined;

  function throwBindingError(message) {
    throw new BindingError(message);
  }

  function registerType(rawType, registeredInstance, options = {}) {
    if (!("argPackAdvance" in registeredInstance)) {
      throw new TypeError(
        "registerType registeredInstance requires argPackAdvance"
      );
    }
    var name = registeredInstance.name;
    if (!rawType) {
      throwBindingError(
        'type "' + name + '" must have a positive integer typeid pointer'
      );
    }
    if (registeredTypes.hasOwnProperty(rawType)) {
      if (options.ignoreDuplicateRegistrations) {
        return;
      }
      throwBindingError("Cannot register type '" + name + "' twice");
    }
    registeredTypes[rawType] = registeredInstance;
    delete typeDependencies[rawType];
    if (awaitingDependencies.hasOwnProperty(rawType)) {
      var callbacks = awaitingDependencies[rawType];
      delete awaitingDependencies[rawType];
      callbacks.forEach(cb => cb());
    }
  }

  function __embind_register_bool(rawType, name, size, trueValue, falseValue) {
    var shift = getShiftFromSize(size);
    name = readLatin1String(name);
    registerType(rawType, {
      name,
      fromWireType: function (wt) {
        return !!wt;
      },
      toWireType: function (destructors, o) {
        return o ? trueValue : falseValue;
      },
      argPackAdvance: 8,
      readValueFromPointer: function (pointer) {
        var heap;
        if (size === 1) {
          heap = HEAP8;
        } else if (size === 2) {
          heap = HEAP16;
        } else if (size === 4) {
          heap = HEAP32;
        } else {
          throw new TypeError("Unknown boolean type size: " + name);
        }
        return this.fromWireType(heap[pointer >> shift]);
      },
      destructorFunction: null,
    });
  }

  function ClassHandle_isAliasOf(other) {
    if (!(this instanceof ClassHandle)) {
      return false;
    }
    if (!(other instanceof ClassHandle)) {
      return false;
    }
    var leftClass = this.$$.ptrType.registeredClass;
    var left = this.$$.ptr;
    var rightClass = other.$$.ptrType.registeredClass;
    var right = other.$$.ptr;
    while (leftClass.baseClass) {
      left = leftClass.upcast(left);
      leftClass = leftClass.baseClass;
    }
    while (rightClass.baseClass) {
      right = rightClass.upcast(right);
      rightClass = rightClass.baseClass;
    }
    return leftClass === rightClass && left === right;
  }

  function shallowCopyInternalPointer(o) {
    return {
      count: o.count,
      deleteScheduled: o.deleteScheduled,
      preservePointerOnDelete: o.preservePointerOnDelete,
      ptr: o.ptr,
      ptrType: o.ptrType,
      smartPtr: o.smartPtr,
      smartPtrType: o.smartPtrType,
    };
  }

  function throwInstanceAlreadyDeleted(obj) {
    function getInstanceTypeName(handle) {
      return handle.$$.ptrType.registeredClass.name;
    }
    throwBindingError(getInstanceTypeName(obj) + " instance already deleted");
  }

  var finalizationRegistry = false;

  function detachFinalizer(handle) {}

  function runDestructor($$) {
    if ($$.smartPtr) {
      $$.smartPtrType.rawDestructor($$.smartPtr);
    } else {
      $$.ptrType.registeredClass.rawDestructor($$.ptr);
    }
  }

  function releaseClassHandle($$) {
    $$.count.value -= 1;
    var toDelete = 0 === $$.count.value;
    if (toDelete) {
      runDestructor($$);
    }
  }

  function downcastPointer(ptr, ptrClass, desiredClass) {
    if (ptrClass === desiredClass) {
      return ptr;
    }
    if (undefined === desiredClass.baseClass) {
      return null;
    }
    var rv = downcastPointer(ptr, ptrClass, desiredClass.baseClass);
    if (rv === null) {
      return null;
    }
    return desiredClass.downcast(rv);
  }

  var registeredPointers = {};

  function getInheritedInstanceCount() {
    return Object.keys(registeredInstances).length;
  }

  function getLiveInheritedInstances() {
    var rv = [];
    for (var k in registeredInstances) {
      if (registeredInstances.hasOwnProperty(k)) {
        rv.push(registeredInstances[k]);
      }
    }
    return rv;
  }

  var deletionQueue = [];

  function flushPendingDeletes() {
    while (deletionQueue.length) {
      var obj = deletionQueue.pop();
      obj.$$.deleteScheduled = false;
      obj.delete();
    }
  }

  var delayFunction = undefined;

  function setDelayFunction(fn) {
    delayFunction = fn;
    if (deletionQueue.length && delayFunction) {
      delayFunction(flushPendingDeletes);
    }
  }

  function init_embind() {
    Module.getInheritedInstanceCount = getInheritedInstanceCount;
    Module.getLiveInheritedInstances = getLiveInheritedInstances;
    Module.flushPendingDeletes = flushPendingDeletes;
    Module.setDelayFunction = setDelayFunction;
  }

  var registeredInstances = {};

  function getBasestPointer(class_, ptr) {
    if (ptr === undefined) {
      throwBindingError("ptr should not be undefined");
    }
    while (class_.baseClass) {
      ptr = class_.upcast(ptr);
      class_ = class_.baseClass;
    }
    return ptr;
  }

  function getInheritedInstance(class_, ptr) {
    ptr = getBasestPointer(class_, ptr);
    return registeredInstances[ptr];
  }

  function makeClassHandle(prototype, record) {
    if (!record.ptrType || !record.ptr) {
      throwInternalError("makeClassHandle requires ptr and ptrType");
    }
    var hasSmartPtrType = !!record.smartPtrType;
    var hasSmartPtr = !!record.smartPtr;
    if (hasSmartPtrType !== hasSmartPtr) {
      throwInternalError("Both smartPtrType and smartPtr must be specified");
    }
    record.count = {
      value: 1,
    };
    return attachFinalizer(
      Object.create(prototype, {
        $$: {
          value: record,
        },
      })
    );
  }

  function RegisteredPointer_fromWireType(ptr) {
    var rawPointer = this.getPointee(ptr);
    if (!rawPointer) {
      this.destructor(ptr);
      return null;
    }
    var registeredInstance = getInheritedInstance(
      this.registeredClass,
      rawPointer
    );
    if (undefined !== registeredInstance) {
      if (0 === registeredInstance.$$.count.value) {
        registeredInstance.$$.ptr = rawPointer;
        registeredInstance.$$.smartPtr = ptr;
        return registeredInstance.clone();
      }
      var rv = registeredInstance.clone();
      this.destructor(ptr);
      return rv;
    }
    function makeDefaultHandle() {
      if (this.isSmartPointer) {
        return makeClassHandle(this.registeredClass.instancePrototype, {
          ptrType: this.pointeeType,
          ptr: rawPointer,
          smartPtrType: this,
          smartPtr: ptr,
        });
      }
      return makeClassHandle(this.registeredClass.instancePrototype, {
        ptrType: this,
        ptr,
      });
    }
    var actualType = this.registeredClass.getActualType(rawPointer);
    var registeredPointerRecord = registeredPointers[actualType];
    if (!registeredPointerRecord) {
      return makeDefaultHandle.call(this);
    }
    var toType;
    if (this.isConst) {
      toType = registeredPointerRecord.constPointerType;
    } else {
      toType = registeredPointerRecord.pointerType;
    }
    var dp = downcastPointer(
      rawPointer,
      this.registeredClass,
      toType.registeredClass
    );
    if (dp === null) {
      return makeDefaultHandle.call(this);
    }
    if (this.isSmartPointer) {
      return makeClassHandle(toType.registeredClass.instancePrototype, {
        ptrType: toType,
        ptr: dp,
        smartPtrType: this,
        smartPtr: ptr,
      });
    }
    return makeClassHandle(toType.registeredClass.instancePrototype, {
      ptrType: toType,
      ptr: dp,
    });
  }

  function attachFinalizer(handle) {
    if ("undefined" === typeof FinalizationRegistry) {
      attachFinalizer = handle => handle;
      return handle;
    }
    finalizationRegistry = new FinalizationRegistry(info => {
      releaseClassHandle(info.$$);
    });
    attachFinalizer = handle => {
      var $$ = handle.$$;
      var hasSmartPtr = !!$$.smartPtr;
      if (hasSmartPtr) {
        var info = {
          $$,
        };
        finalizationRegistry.register(handle, info, handle);
      }
      return handle;
    };
    detachFinalizer = handle => finalizationRegistry.unregister(handle);
    return attachFinalizer(handle);
  }

  function ClassHandle_clone() {
    if (!this.$$.ptr) {
      throwInstanceAlreadyDeleted(this);
    }
    if (this.$$.preservePointerOnDelete) {
      this.$$.count.value += 1;
      return this;
    }
    var clone = attachFinalizer(
      Object.create(Object.getPrototypeOf(this), {
        $$: {
          value: shallowCopyInternalPointer(this.$$),
        },
      })
    );
    clone.$$.count.value += 1;
    clone.$$.deleteScheduled = false;
    return clone;
  }

  function ClassHandle_delete() {
    if (!this.$$.ptr) {
      throwInstanceAlreadyDeleted(this);
    }
    if (this.$$.deleteScheduled && !this.$$.preservePointerOnDelete) {
      throwBindingError("Object already scheduled for deletion");
    }
    detachFinalizer(this);
    releaseClassHandle(this.$$);
    if (!this.$$.preservePointerOnDelete) {
      this.$$.smartPtr = undefined;
      this.$$.ptr = undefined;
    }
  }

  function ClassHandle_isDeleted() {
    return !this.$$.ptr;
  }

  function ClassHandle_deleteLater() {
    if (!this.$$.ptr) {
      throwInstanceAlreadyDeleted(this);
    }
    if (this.$$.deleteScheduled && !this.$$.preservePointerOnDelete) {
      throwBindingError("Object already scheduled for deletion");
    }
    deletionQueue.push(this);
    if (deletionQueue.length === 1 && delayFunction) {
      delayFunction(flushPendingDeletes);
    }
    this.$$.deleteScheduled = true;
    return this;
  }

  function init_ClassHandle() {
    ClassHandle.prototype.isAliasOf = ClassHandle_isAliasOf;
    ClassHandle.prototype.clone = ClassHandle_clone;
    ClassHandle.prototype.delete = ClassHandle_delete;
    ClassHandle.prototype.isDeleted = ClassHandle_isDeleted;
    ClassHandle.prototype.deleteLater = ClassHandle_deleteLater;
  }

  function ClassHandle() {}

  function ensureOverloadTable(proto, methodName, humanName) {
    if (undefined === proto[methodName].overloadTable) {
      var prevFunc = proto[methodName];
      proto[methodName] = function () {
        if (!proto[methodName].overloadTable.hasOwnProperty(arguments.length)) {
          throwBindingError(
            "Function '" +
              humanName +
              "' called with an invalid number of arguments (" +
              arguments.length +
              ") - expects one of (" +
              proto[methodName].overloadTable +
              ")!"
          );
        }
        return proto[methodName].overloadTable[arguments.length].apply(
          this,
          arguments
        );
      };
      proto[methodName].overloadTable = [];
      proto[methodName].overloadTable[prevFunc.argCount] = prevFunc;
    }
  }

  function exposePublicSymbol(name, value, numArguments) {
    if (Module.hasOwnProperty(name)) {
      if (
        undefined === numArguments ||
        (undefined !== Module[name].overloadTable &&
          undefined !== Module[name].overloadTable[numArguments])
      ) {
        throwBindingError("Cannot register public name '" + name + "' twice");
      }
      ensureOverloadTable(Module, name, name);
      if (Module.hasOwnProperty(numArguments)) {
        throwBindingError(
          "Cannot register multiple overloads of a function with the same number of arguments (" +
            numArguments +
            ")!"
        );
      }
      Module[name].overloadTable[numArguments] = value;
    } else {
      Module[name] = value;
      if (undefined !== numArguments) {
        Module[name].numArguments = numArguments;
      }
    }
  }

  function RegisteredClass(
    name,
    constructor,
    instancePrototype,
    rawDestructor,
    baseClass,
    getActualType,
    upcast,
    downcast
  ) {
    this.name = name;
    this.constructor = constructor;
    this.instancePrototype = instancePrototype;
    this.rawDestructor = rawDestructor;
    this.baseClass = baseClass;
    this.getActualType = getActualType;
    this.upcast = upcast;
    this.downcast = downcast;
    this.pureVirtualFunctions = [];
  }

  function upcastPointer(ptr, ptrClass, desiredClass) {
    while (ptrClass !== desiredClass) {
      if (!ptrClass.upcast) {
        throwBindingError(
          "Expected null or instance of " +
            desiredClass.name +
            ", got an instance of " +
            ptrClass.name
        );
      }
      ptr = ptrClass.upcast(ptr);
      ptrClass = ptrClass.baseClass;
    }
    return ptr;
  }

  function constNoSmartPtrRawPointerToWireType(destructors, handle) {
    if (handle === null) {
      if (this.isReference) {
        throwBindingError("null is not a valid " + this.name);
      }
      return 0;
    }
    if (!handle.$$) {
      throwBindingError(
        'Cannot pass "' + _embind_repr(handle) + '" as a ' + this.name
      );
    }
    if (!handle.$$.ptr) {
      throwBindingError(
        "Cannot pass deleted object as a pointer of type " + this.name
      );
    }
    var handleClass = handle.$$.ptrType.registeredClass;
    var ptr = upcastPointer(handle.$$.ptr, handleClass, this.registeredClass);
    return ptr;
  }

  function genericPointerToWireType(destructors, handle) {
    var ptr;
    if (handle === null) {
      if (this.isReference) {
        throwBindingError("null is not a valid " + this.name);
      }
      if (this.isSmartPointer) {
        ptr = this.rawConstructor();
        if (destructors !== null) {
          destructors.push(this.rawDestructor, ptr);
        }
        return ptr;
      }
      return 0;
    }
    if (!handle.$$) {
      throwBindingError(
        'Cannot pass "' + _embind_repr(handle) + '" as a ' + this.name
      );
    }
    if (!handle.$$.ptr) {
      throwBindingError(
        "Cannot pass deleted object as a pointer of type " + this.name
      );
    }
    if (!this.isConst && handle.$$.ptrType.isConst) {
      throwBindingError(
        "Cannot convert argument of type " +
          (handle.$$.smartPtrType
            ? handle.$$.smartPtrType.name
            : handle.$$.ptrType.name) +
          " to parameter type " +
          this.name
      );
    }
    var handleClass = handle.$$.ptrType.registeredClass;
    ptr = upcastPointer(handle.$$.ptr, handleClass, this.registeredClass);
    if (this.isSmartPointer) {
      if (undefined === handle.$$.smartPtr) {
        throwBindingError("Passing raw pointer to smart pointer is illegal");
      }
      switch (this.sharingPolicy) {
        case 0:
          if (handle.$$.smartPtrType === this) {
            ptr = handle.$$.smartPtr;
          } else {
            throwBindingError(
              "Cannot convert argument of type " +
                (handle.$$.smartPtrType
                  ? handle.$$.smartPtrType.name
                  : handle.$$.ptrType.name) +
                " to parameter type " +
                this.name
            );
          }
          break;

        case 1:
          ptr = handle.$$.smartPtr;
          break;

        case 2:
          if (handle.$$.smartPtrType === this) {
            ptr = handle.$$.smartPtr;
          } else {
            var clonedHandle = handle.clone();
            ptr = this.rawShare(
              ptr,
              Emval.toHandle(function () {
                clonedHandle.delete();
              })
            );
            if (destructors !== null) {
              destructors.push(this.rawDestructor, ptr);
            }
          }
          break;

        default:
          throwBindingError("Unsupporting sharing policy");
      }
    }
    return ptr;
  }

  function nonConstNoSmartPtrRawPointerToWireType(destructors, handle) {
    if (handle === null) {
      if (this.isReference) {
        throwBindingError("null is not a valid " + this.name);
      }
      return 0;
    }
    if (!handle.$$) {
      throwBindingError(
        'Cannot pass "' + _embind_repr(handle) + '" as a ' + this.name
      );
    }
    if (!handle.$$.ptr) {
      throwBindingError(
        "Cannot pass deleted object as a pointer of type " + this.name
      );
    }
    if (handle.$$.ptrType.isConst) {
      throwBindingError(
        "Cannot convert argument of type " +
          handle.$$.ptrType.name +
          " to parameter type " +
          this.name
      );
    }
    var handleClass = handle.$$.ptrType.registeredClass;
    var ptr = upcastPointer(handle.$$.ptr, handleClass, this.registeredClass);
    return ptr;
  }

  function RegisteredPointer_getPointee(ptr) {
    if (this.rawGetPointee) {
      ptr = this.rawGetPointee(ptr);
    }
    return ptr;
  }

  function RegisteredPointer_destructor(ptr) {
    if (this.rawDestructor) {
      this.rawDestructor(ptr);
    }
  }

  function RegisteredPointer_deleteObject(handle) {
    if (handle !== null) {
      handle.delete();
    }
  }

  function init_RegisteredPointer() {
    RegisteredPointer.prototype.getPointee = RegisteredPointer_getPointee;
    RegisteredPointer.prototype.destructor = RegisteredPointer_destructor;
    RegisteredPointer.prototype.argPackAdvance = 8;
    RegisteredPointer.prototype.readValueFromPointer =
      simpleReadValueFromPointer;
    RegisteredPointer.prototype.deleteObject = RegisteredPointer_deleteObject;
    RegisteredPointer.prototype.fromWireType = RegisteredPointer_fromWireType;
  }

  function RegisteredPointer(
    name,
    registeredClass,
    isReference,
    isConst,
    isSmartPointer,
    pointeeType,
    sharingPolicy,
    rawGetPointee,
    rawConstructor,
    rawShare,
    rawDestructor
  ) {
    this.name = name;
    this.registeredClass = registeredClass;
    this.isReference = isReference;
    this.isConst = isConst;
    this.isSmartPointer = isSmartPointer;
    this.pointeeType = pointeeType;
    this.sharingPolicy = sharingPolicy;
    this.rawGetPointee = rawGetPointee;
    this.rawConstructor = rawConstructor;
    this.rawShare = rawShare;
    this.rawDestructor = rawDestructor;
    if (!isSmartPointer && registeredClass.baseClass === undefined) {
      if (isConst) {
        this.toWireType = constNoSmartPtrRawPointerToWireType;
        this.destructorFunction = null;
      } else {
        this.toWireType = nonConstNoSmartPtrRawPointerToWireType;
        this.destructorFunction = null;
      }
    } else {
      this.toWireType = genericPointerToWireType;
    }
  }

  function replacePublicSymbol(name, value, numArguments) {
    if (!Module.hasOwnProperty(name)) {
      throwInternalError("Replacing nonexistant public symbol");
    }
    if (
      undefined !== Module[name].overloadTable &&
      undefined !== numArguments
    ) {
      Module[name].overloadTable[numArguments] = value;
    } else {
      Module[name] = value;
      Module[name].argCount = numArguments;
    }
  }

  function dynCallLegacy(sig, ptr, args) {
    var f = Module["dynCall_" + sig];
    return args && args.length
      ? f.apply(null, [ptr].concat(args))
      : f.call(null, ptr);
  }

  function dynCall(sig, ptr, args) {
    if (sig.includes("j")) {
      return dynCallLegacy(sig, ptr, args);
    }
    return getWasmTableEntry(ptr).apply(null, args);
  }

  function getDynCaller(sig, ptr) {
    var argCache = [];
    return function () {
      argCache.length = 0;
      Object.assign(argCache, arguments);
      return dynCall(sig, ptr, argCache);
    };
  }

  function embind__requireFunction(signature, rawFunction) {
    signature = readLatin1String(signature);
    function makeDynCaller() {
      if (signature.includes("j")) {
        return getDynCaller(signature, rawFunction);
      }
      return getWasmTableEntry(rawFunction);
    }
    var fp = makeDynCaller();
    if (typeof fp != "function") {
      throwBindingError(
        "unknown function pointer with signature " +
          signature +
          ": " +
          rawFunction
      );
    }
    return fp;
  }

  var UnboundTypeError = undefined;

  function getTypeName(type) {
    var ptr = ___getTypeName(type);
    var rv = readLatin1String(ptr);
    _free(ptr);
    return rv;
  }

  function throwUnboundTypeError(message, types) {
    var unboundTypes = [];
    var seen = {};
    function visit(type) {
      if (seen[type]) {
        return;
      }
      if (registeredTypes[type]) {
        return;
      }
      if (typeDependencies[type]) {
        typeDependencies[type].forEach(visit);
        return;
      }
      unboundTypes.push(type);
      seen[type] = true;
    }
    types.forEach(visit);
    throw new UnboundTypeError(
      message + ": " + unboundTypes.map(getTypeName).join([", "])
    );
  }

  function __embind_register_class(
    rawType,
    rawPointerType,
    rawConstPointerType,
    baseClassRawType,
    getActualTypeSignature,
    getActualType,
    upcastSignature,
    upcast,
    downcastSignature,
    downcast,
    name,
    destructorSignature,
    rawDestructor
  ) {
    name = readLatin1String(name);
    getActualType = embind__requireFunction(
      getActualTypeSignature,
      getActualType
    );
    if (upcast) {
      upcast = embind__requireFunction(upcastSignature, upcast);
    }
    if (downcast) {
      downcast = embind__requireFunction(downcastSignature, downcast);
    }
    rawDestructor = embind__requireFunction(destructorSignature, rawDestructor);
    var legalFunctionName = makeLegalFunctionName(name);
    exposePublicSymbol(legalFunctionName, function () {
      throwUnboundTypeError(
        "Cannot construct " + name + " due to unbound types",
        [baseClassRawType]
      );
    });
    whenDependentTypesAreResolved(
      [rawType, rawPointerType, rawConstPointerType],
      baseClassRawType ? [baseClassRawType] : [],
      function (base) {
        base = base[0];
        var baseClass;
        var basePrototype;
        if (baseClassRawType) {
          baseClass = base.registeredClass;
          basePrototype = baseClass.instancePrototype;
        } else {
          basePrototype = ClassHandle.prototype;
        }
        var constructor = createNamedFunction(legalFunctionName, function () {
          if (Object.getPrototypeOf(this) !== instancePrototype) {
            throw new BindingError("Use 'new' to construct " + name);
          }
          if (undefined === registeredClass.constructor_body) {
            throw new BindingError(name + " has no accessible constructor");
          }
          var body = registeredClass.constructor_body[arguments.length];
          if (undefined === body) {
            throw new BindingError(
              "Tried to invoke ctor of " +
                name +
                " with invalid number of parameters (" +
                arguments.length +
                ") - expected (" +
                Object.keys(registeredClass.constructor_body).toString() +
                ") parameters instead!"
            );
          }
          return body.apply(this, arguments);
        });
        var instancePrototype = Object.create(basePrototype, {
          constructor: {
            value: constructor,
          },
        });
        constructor.prototype = instancePrototype;
        var registeredClass = new RegisteredClass(
          name,
          constructor,
          instancePrototype,
          rawDestructor,
          baseClass,
          getActualType,
          upcast,
          downcast
        );
        var referenceConverter = new RegisteredPointer(
          name,
          registeredClass,
          true,
          false,
          false
        );
        var pointerConverter = new RegisteredPointer(
          name + "*",
          registeredClass,
          false,
          false,
          false
        );
        var constPointerConverter = new RegisteredPointer(
          name + " const*",
          registeredClass,
          false,
          true,
          false
        );
        registeredPointers[rawType] = {
          pointerType: pointerConverter,
          constPointerType: constPointerConverter,
        };
        replacePublicSymbol(legalFunctionName, constructor);
        return [referenceConverter, pointerConverter, constPointerConverter];
      }
    );
  }

  function heap32VectorToArray(count, firstElement) {
    var array = [];
    for (var i = 0; i < count; i++) {
      array.push(HEAP32[(firstElement >> 2) + i]);
    }
    return array;
  }

  function __embind_register_class_constructor(
    rawClassType,
    argCount,
    rawArgTypesAddr,
    invokerSignature,
    invoker,
    rawConstructor
  ) {
    assert(argCount > 0);
    var rawArgTypes = heap32VectorToArray(argCount, rawArgTypesAddr);
    invoker = embind__requireFunction(invokerSignature, invoker);
    whenDependentTypesAreResolved([], [rawClassType], function (classType) {
      classType = classType[0];
      var humanName = "constructor " + classType.name;
      if (undefined === classType.registeredClass.constructor_body) {
        classType.registeredClass.constructor_body = [];
      }
      if (
        undefined !== classType.registeredClass.constructor_body[argCount - 1]
      ) {
        throw new BindingError(
          "Cannot register multiple constructors with identical number of parameters (" +
            (argCount - 1) +
            ") for class '" +
            classType.name +
            "'! Overload resolution is currently only performed using the parameter count, not actual type info!"
        );
      }
      classType.registeredClass.constructor_body[argCount - 1] = () => {
        throwUnboundTypeError(
          "Cannot construct " + classType.name + " due to unbound types",
          rawArgTypes
        );
      };
      whenDependentTypesAreResolved([], rawArgTypes, function (argTypes) {
        argTypes.splice(1, 0, null);
        classType.registeredClass.constructor_body[argCount - 1] =
          craftInvokerFunction(
            humanName,
            argTypes,
            null,
            invoker,
            rawConstructor
          );
        return [];
      });
      return [];
    });
  }

  function craftInvokerFunction(
    humanName,
    argTypes,
    classType,
    cppInvokerFunc,
    cppTargetFunc
  ) {
    var argCount = argTypes.length;
    if (argCount < 2) {
      throwBindingError(
        "argTypes array size mismatch! Must at least get return value and 'this' types!"
      );
    }
    var isClassMethodFunc = argTypes[1] !== null && classType !== null;
    var needsDestructorStack = false;
    for (var i = 1; i < argTypes.length; ++i) {
      if (
        argTypes[i] !== null &&
        argTypes[i].destructorFunction === undefined
      ) {
        needsDestructorStack = true;
        break;
      }
    }
    var returns = argTypes[0].name !== "void";
    var expectedArgCount = argCount - 2;
    var argsWired = new Array(expectedArgCount);
    var invokerFuncArgs = [];
    var destructors = [];
    return function () {
      if (arguments.length !== expectedArgCount) {
        throwBindingError(
          "function " +
            humanName +
            " called with " +
            arguments.length +
            " arguments, expected " +
            expectedArgCount +
            " args!"
        );
      }
      destructors.length = 0;
      var thisWired;
      invokerFuncArgs.length = isClassMethodFunc ? 2 : 1;
      invokerFuncArgs[0] = cppTargetFunc;
      if (isClassMethodFunc) {
        thisWired = argTypes[1].toWireType(destructors, this);
        invokerFuncArgs[1] = thisWired;
      }
      for (var i = 0; i < expectedArgCount; ++i) {
        argsWired[i] = argTypes[i + 2].toWireType(destructors, arguments[i]);
        invokerFuncArgs.push(argsWired[i]);
      }
      var rv = cppInvokerFunc.apply(null, invokerFuncArgs);
      function onDone(rv) {
        if (needsDestructorStack) {
          runDestructors(destructors);
        } else {
          for (var i = isClassMethodFunc ? 1 : 2; i < argTypes.length; i++) {
            var param = i === 1 ? thisWired : argsWired[i - 2];
            if (argTypes[i].destructorFunction !== null) {
              argTypes[i].destructorFunction(param);
            }
          }
        }
        if (returns) {
          return argTypes[0].fromWireType(rv);
        }
      }
      return onDone(rv);
    };
  }

  function __embind_register_class_function(
    rawClassType,
    methodName,
    argCount,
    rawArgTypesAddr,
    invokerSignature,
    rawInvoker,
    context,
    isPureVirtual
  ) {
    var rawArgTypes = heap32VectorToArray(argCount, rawArgTypesAddr);
    methodName = readLatin1String(methodName);
    rawInvoker = embind__requireFunction(invokerSignature, rawInvoker);
    whenDependentTypesAreResolved([], [rawClassType], function (classType) {
      classType = classType[0];
      var humanName = classType.name + "." + methodName;
      if (methodName.startsWith("@@")) {
        methodName = Symbol[methodName.substring(2)];
      }
      if (isPureVirtual) {
        classType.registeredClass.pureVirtualFunctions.push(methodName);
      }
      function unboundTypesHandler() {
        throwUnboundTypeError(
          "Cannot call " + humanName + " due to unbound types",
          rawArgTypes
        );
      }
      var proto = classType.registeredClass.instancePrototype;
      var method = proto[methodName];
      if (
        undefined === method ||
        (undefined === method.overloadTable &&
          method.className !== classType.name &&
          method.argCount === argCount - 2)
      ) {
        unboundTypesHandler.argCount = argCount - 2;
        unboundTypesHandler.className = classType.name;
        proto[methodName] = unboundTypesHandler;
      } else {
        ensureOverloadTable(proto, methodName, humanName);
        proto[methodName].overloadTable[argCount - 2] = unboundTypesHandler;
      }
      whenDependentTypesAreResolved([], rawArgTypes, function (argTypes) {
        var memberFunction = craftInvokerFunction(
          humanName,
          argTypes,
          classType,
          rawInvoker,
          context
        );
        if (undefined === proto[methodName].overloadTable) {
          memberFunction.argCount = argCount - 2;
          proto[methodName] = memberFunction;
        } else {
          proto[methodName].overloadTable[argCount - 2] = memberFunction;
        }
        return [];
      });
      return [];
    });
  }

  var emval_free_list = [];

  var emval_handle_array = [
    {},
    {
      value: undefined,
    },
    {
      value: null,
    },
    {
      value: true,
    },
    {
      value: false,
    },
  ];

  function __emval_decref(handle) {
    if (handle > 4 && 0 === --emval_handle_array[handle].refcount) {
      emval_handle_array[handle] = undefined;
      emval_free_list.push(handle);
    }
  }

  function count_emval_handles() {
    var count = 0;
    for (var i = 5; i < emval_handle_array.length; ++i) {
      if (emval_handle_array[i] !== undefined) {
        ++count;
      }
    }
    return count;
  }

  function get_first_emval() {
    for (var i = 5; i < emval_handle_array.length; ++i) {
      if (emval_handle_array[i] !== undefined) {
        return emval_handle_array[i];
      }
    }
    return null;
  }

  function init_emval() {
    Module.count_emval_handles = count_emval_handles;
    Module.get_first_emval = get_first_emval;
  }

  var Emval = {
    toValue: handle => {
      if (!handle) {
        throwBindingError("Cannot use deleted val. handle = " + handle);
      }
      return emval_handle_array[handle].value;
    },
    toHandle: value => {
      switch (value) {
        case undefined:
          return 1;

        case null:
          return 2;

        case true:
          return 3;

        case false:
          return 4;

        default: {
          var handle = emval_free_list.length
            ? emval_free_list.pop()
            : emval_handle_array.length;
          emval_handle_array[handle] = {
            refcount: 1,
            value,
          };
          return handle;
        }
      }
    },
  };

  function __embind_register_emval(rawType, name) {
    name = readLatin1String(name);
    registerType(rawType, {
      name,
      fromWireType: function (handle) {
        var rv = Emval.toValue(handle);
        __emval_decref(handle);
        return rv;
      },
      toWireType: function (destructors, value) {
        return Emval.toHandle(value);
      },
      argPackAdvance: 8,
      readValueFromPointer: simpleReadValueFromPointer,
      destructorFunction: null,
    });
  }

  function _embind_repr(v) {
    if (v === null) {
      return "null";
    }
    var t = typeof v;
    if (t === "object" || t === "array" || t === "function") {
      return v.toString();
    }
    return "" + v;
  }

  function floatReadValueFromPointer(name, shift) {
    switch (shift) {
      case 2:
        return function (pointer) {
          return this.fromWireType(HEAPF32[pointer >> 2]);
        };

      case 3:
        return function (pointer) {
          return this.fromWireType(HEAPF64[pointer >> 3]);
        };

      default:
        throw new TypeError("Unknown float type: " + name);
    }
  }

  function __embind_register_float(rawType, name, size) {
    var shift = getShiftFromSize(size);
    name = readLatin1String(name);
    registerType(rawType, {
      name,
      fromWireType: function (value) {
        return value;
      },
      toWireType: function (destructors, value) {
        return value;
      },
      argPackAdvance: 8,
      readValueFromPointer: floatReadValueFromPointer(name, shift),
      destructorFunction: null,
    });
  }

  function integerReadValueFromPointer(name, shift, signed) {
    switch (shift) {
      case 0:
        return signed
          ? function readS8FromPointer(pointer) {
              return HEAP8[pointer];
            }
          : function readU8FromPointer(pointer) {
              return HEAPU8[pointer];
            };

      case 1:
        return signed
          ? function readS16FromPointer(pointer) {
              return HEAP16[pointer >> 1];
            }
          : function readU16FromPointer(pointer) {
              return HEAPU16[pointer >> 1];
            };

      case 2:
        return signed
          ? function readS32FromPointer(pointer) {
              return HEAP32[pointer >> 2];
            }
          : function readU32FromPointer(pointer) {
              return HEAPU32[pointer >> 2];
            };

      default:
        throw new TypeError("Unknown integer type: " + name);
    }
  }

  function __embind_register_integer(
    primitiveType,
    name,
    size,
    minRange,
    maxRange
  ) {
    name = readLatin1String(name);
    if (maxRange === -1) {
      maxRange = 4294967295;
    }
    var shift = getShiftFromSize(size);
    var fromWireType = value => value;
    if (minRange === 0) {
      var bitshift = 32 - 8 * size;
      fromWireType = value => (value << bitshift) >>> bitshift;
    }
    var isUnsignedType = name.includes("unsigned");
    var checkAssertions = (value, toTypeName) => {};
    var toWireType;
    if (isUnsignedType) {
      toWireType = function (destructors, value) {
        checkAssertions(value, this.name);
        return value >>> 0;
      };
    } else {
      toWireType = function (destructors, value) {
        checkAssertions(value, this.name);
        return value;
      };
    }
    registerType(primitiveType, {
      name,
      fromWireType: fromWireType,
      toWireType: toWireType,
      argPackAdvance: 8,
      readValueFromPointer: integerReadValueFromPointer(
        name,
        shift,
        minRange !== 0
      ),
      destructorFunction: null,
    });
  }

  function __embind_register_memory_view(rawType, dataTypeIndex, name) {
    var typeMapping = [
      Int8Array,
      Uint8Array,
      Int16Array,
      Uint16Array,
      Int32Array,
      Uint32Array,
      Float32Array,
      Float64Array,
    ];
    var TA = typeMapping[dataTypeIndex];
    function decodeMemoryView(handle) {
      handle = handle >> 2;
      var heap = HEAPU32;
      var size = heap[handle];
      var data = heap[handle + 1];
      return new TA(buffer, data, size);
    }
    name = readLatin1String(name);
    registerType(
      rawType,
      {
        name,
        fromWireType: decodeMemoryView,
        argPackAdvance: 8,
        readValueFromPointer: decodeMemoryView,
      },
      {
        ignoreDuplicateRegistrations: true,
      }
    );
  }

  function __embind_register_smart_ptr(
    rawType,
    rawPointeeType,
    name,
    sharingPolicy,
    getPointeeSignature,
    rawGetPointee,
    constructorSignature,
    rawConstructor,
    shareSignature,
    rawShare,
    destructorSignature,
    rawDestructor
  ) {
    name = readLatin1String(name);
    rawGetPointee = embind__requireFunction(getPointeeSignature, rawGetPointee);
    rawConstructor = embind__requireFunction(
      constructorSignature,
      rawConstructor
    );
    rawShare = embind__requireFunction(shareSignature, rawShare);
    rawDestructor = embind__requireFunction(destructorSignature, rawDestructor);
    whenDependentTypesAreResolved(
      [rawType],
      [rawPointeeType],
      function (pointeeType) {
        pointeeType = pointeeType[0];
        var registeredPointer = new RegisteredPointer(
          name,
          pointeeType.registeredClass,
          false,
          false,
          true,
          pointeeType,
          sharingPolicy,
          rawGetPointee,
          rawConstructor,
          rawShare,
          rawDestructor
        );
        return [registeredPointer];
      }
    );
  }

  function __embind_register_std_string(rawType, name) {
    name = readLatin1String(name);
    var stdStringIsUTF8 = name === "std::string";
    registerType(rawType, {
      name,
      fromWireType: function (value) {
        var length = HEAPU32[value >> 2];
        var str;
        if (stdStringIsUTF8) {
          var decodeStartPtr = value + 4;
          for (var i = 0; i <= length; ++i) {
            var currentBytePtr = value + 4 + i;
            if (i == length || HEAPU8[currentBytePtr] == 0) {
              var maxRead = currentBytePtr - decodeStartPtr;
              var stringSegment = UTF8ToString(decodeStartPtr, maxRead);
              if (str === undefined) {
                str = stringSegment;
              } else {
                str += String.fromCharCode(0);
                str += stringSegment;
              }
              decodeStartPtr = currentBytePtr + 1;
            }
          }
        } else {
          var a = new Array(length);
          for (var i = 0; i < length; ++i) {
            a[i] = String.fromCharCode(HEAPU8[value + 4 + i]);
          }
          str = a.join("");
        }
        _free(value);
        return str;
      },
      toWireType: function (destructors, value) {
        if (value instanceof ArrayBuffer) {
          value = new Uint8Array(value);
        }
        var getLength;
        var valueIsOfTypeString = typeof value == "string";
        if (
          !(
            valueIsOfTypeString ||
            value instanceof Uint8Array ||
            value instanceof Uint8ClampedArray ||
            value instanceof Int8Array
          )
        ) {
          throwBindingError("Cannot pass non-string to std::string");
        }
        if (stdStringIsUTF8 && valueIsOfTypeString) {
          getLength = () => lengthBytesUTF8(value);
        } else {
          getLength = () => value.length;
        }
        var length = getLength();
        var ptr = _malloc(4 + length + 1);
        HEAPU32[ptr >> 2] = length;
        if (stdStringIsUTF8 && valueIsOfTypeString) {
          stringToUTF8(value, ptr + 4, length + 1);
        } else if (valueIsOfTypeString) {
          for (var i = 0; i < length; ++i) {
            var charCode = value.charCodeAt(i);
            if (charCode > 255) {
              _free(ptr);
              throwBindingError(
                "String has UTF-16 code units that do not fit in 8 bits"
              );
            }
            HEAPU8[ptr + 4 + i] = charCode;
          }
        } else {
          for (var i = 0; i < length; ++i) {
            HEAPU8[ptr + 4 + i] = value[i];
          }
        }
        if (destructors !== null) {
          destructors.push(_free, ptr);
        }
        return ptr;
      },
      argPackAdvance: 8,
      readValueFromPointer: simpleReadValueFromPointer,
      destructorFunction(ptr) {
        _free(ptr);
      },
    });
  }

  function __embind_register_std_wstring(rawType, charSize, name) {
    name = readLatin1String(name);
    var decodeString, encodeString, getHeap, lengthBytesUTF, shift;
    if (charSize === 2) {
      decodeString = UTF16ToString;
      encodeString = stringToUTF16;
      lengthBytesUTF = lengthBytesUTF16;
      getHeap = () => HEAPU16;
      shift = 1;
    } else if (charSize === 4) {
      decodeString = UTF32ToString;
      encodeString = stringToUTF32;
      lengthBytesUTF = lengthBytesUTF32;
      getHeap = () => HEAPU32;
      shift = 2;
    }
    registerType(rawType, {
      name,
      fromWireType: function (value) {
        var length = HEAPU32[value >> 2];
        var HEAP = getHeap();
        var str;
        var decodeStartPtr = value + 4;
        for (var i = 0; i <= length; ++i) {
          var currentBytePtr = value + 4 + i * charSize;
          if (i == length || HEAP[currentBytePtr >> shift] == 0) {
            var maxReadBytes = currentBytePtr - decodeStartPtr;
            var stringSegment = decodeString(decodeStartPtr, maxReadBytes);
            if (str === undefined) {
              str = stringSegment;
            } else {
              str += String.fromCharCode(0);
              str += stringSegment;
            }
            decodeStartPtr = currentBytePtr + charSize;
          }
        }
        _free(value);
        return str;
      },
      toWireType: function (destructors, value) {
        if (!(typeof value == "string")) {
          throwBindingError(
            "Cannot pass non-string to C++ string type " + name
          );
        }
        var length = lengthBytesUTF(value);
        var ptr = _malloc(4 + length + charSize);
        HEAPU32[ptr >> 2] = length >> shift;
        encodeString(value, ptr + 4, length + charSize);
        if (destructors !== null) {
          destructors.push(_free, ptr);
        }
        return ptr;
      },
      argPackAdvance: 8,
      readValueFromPointer: simpleReadValueFromPointer,
      destructorFunction(ptr) {
        _free(ptr);
      },
    });
  }

  function __embind_register_value_object(
    rawType,
    name,
    constructorSignature,
    rawConstructor,
    destructorSignature,
    rawDestructor
  ) {
    structRegistrations[rawType] = {
      name: readLatin1String(name),
      rawConstructor: embind__requireFunction(
        constructorSignature,
        rawConstructor
      ),
      rawDestructor: embind__requireFunction(
        destructorSignature,
        rawDestructor
      ),
      fields: [],
    };
  }

  function __embind_register_value_object_field(
    structType,
    fieldName,
    getterReturnType,
    getterSignature,
    getter,
    getterContext,
    setterArgumentType,
    setterSignature,
    setter,
    setterContext
  ) {
    structRegistrations[structType].fields.push({
      fieldName: readLatin1String(fieldName),
      getterReturnType,
      getter: embind__requireFunction(getterSignature, getter),
      getterContext,
      setterArgumentType,
      setter: embind__requireFunction(setterSignature, setter),
      setterContext,
    });
  }

  function __embind_register_void(rawType, name) {
    name = readLatin1String(name);
    registerType(rawType, {
      isVoid: true,
      name,
      argPackAdvance: 0,
      fromWireType: function () {
        return undefined;
      },
      toWireType: function (destructors, o) {
        return undefined;
      },
    });
  }

  function __emscripten_date_now() {
    return Date.now();
  }

  var nowIsMonotonic = true;

  function __emscripten_get_now_is_monotonic() {
    return nowIsMonotonic;
  }

  function requireRegisteredType(rawType, humanName) {
    var impl = registeredTypes[rawType];
    if (undefined === impl) {
      throwBindingError(
        humanName + " has unknown type " + getTypeName(rawType)
      );
    }
    return impl;
  }

  function __emval_lookupTypes(argCount, argTypes) {
    var a = new Array(argCount);
    for (var i = 0; i < argCount; ++i) {
      a[i] = requireRegisteredType(
        HEAP32[(argTypes >> 2) + i],
        "parameter " + i
      );
    }
    return a;
  }

  function __emval_call(handle, argCount, argTypes, argv) {
    handle = Emval.toValue(handle);
    var types = __emval_lookupTypes(argCount, argTypes);
    var args = new Array(argCount);
    for (var i = 0; i < argCount; ++i) {
      var type = types[i];
      args[i] = type.readValueFromPointer(argv);
      argv += type.argPackAdvance;
    }
    var rv = handle.apply(undefined, args);
    return Emval.toHandle(rv);
  }

  function __emval_incref(handle) {
    if (handle > 4) {
      emval_handle_array[handle].refcount += 1;
    }
  }

  function __emval_take_value(type, argv) {
    type = requireRegisteredType(type, "_emval_take_value");
    var v = type.readValueFromPointer(argv);
    return Emval.toHandle(v);
  }

  function __localtime_js(time, tmPtr) {
    var date = new Date(HEAP32[time >> 2] * 1e3);
    HEAP32[tmPtr >> 2] = date.getSeconds();
    HEAP32[(tmPtr + 4) >> 2] = date.getMinutes();
    HEAP32[(tmPtr + 8) >> 2] = date.getHours();
    HEAP32[(tmPtr + 12) >> 2] = date.getDate();
    HEAP32[(tmPtr + 16) >> 2] = date.getMonth();
    HEAP32[(tmPtr + 20) >> 2] = date.getFullYear() - 1900;
    HEAP32[(tmPtr + 24) >> 2] = date.getDay();
    var start = new Date(date.getFullYear(), 0, 1);
    var yday = ((date.getTime() - start.getTime()) / (1e3 * 60 * 60 * 24)) | 0;
    HEAP32[(tmPtr + 28) >> 2] = yday;
    HEAP32[(tmPtr + 36) >> 2] = -(date.getTimezoneOffset() * 60);
    var summerOffset = new Date(date.getFullYear(), 6, 1).getTimezoneOffset();
    var winterOffset = start.getTimezoneOffset();
    var dst =
      (summerOffset != winterOffset &&
        date.getTimezoneOffset() == Math.min(winterOffset, summerOffset)) | 0;
    HEAP32[(tmPtr + 32) >> 2] = dst;
  }

  function __mmap_js(addr, len, prot, flags, fd, off, allocated, builtin) {
    return -52;
  }

  function __munmap_js(addr, len, prot, flags, fd, offset) {}

  function _tzset_impl(timezone, daylight, tzname) {
    var currentYear = new Date().getFullYear();
    var winter = new Date(currentYear, 0, 1);
    var summer = new Date(currentYear, 6, 1);
    var winterOffset = winter.getTimezoneOffset();
    var summerOffset = summer.getTimezoneOffset();
    var stdTimezoneOffset = Math.max(winterOffset, summerOffset);
    HEAP32[timezone >> 2] = stdTimezoneOffset * 60;
    HEAP32[daylight >> 2] = Number(winterOffset != summerOffset);
    function extractZone(date) {
      var match = date.toTimeString().match(/\(([A-Za-z ]+)\)$/);
      return match ? match[1] : "GMT";
    }
    var winterName = extractZone(winter);
    var summerName = extractZone(summer);
    var winterNamePtr = allocateUTF8(winterName);
    var summerNamePtr = allocateUTF8(summerName);
    if (summerOffset < winterOffset) {
      HEAP32[tzname >> 2] = winterNamePtr;
      HEAP32[(tzname + 4) >> 2] = summerNamePtr;
    } else {
      HEAP32[tzname >> 2] = summerNamePtr;
      HEAP32[(tzname + 4) >> 2] = winterNamePtr;
    }
  }

  function __tzset_js(timezone, daylight, tzname) {
    if (__tzset_js.called) {
      return;
    }
    __tzset_js.called = true;
    _tzset_impl(timezone, daylight, tzname);
  }

  function _abort() {
    abort("");
  }

  var readAsmConstArgsArray = [];

  function readAsmConstArgs(sigPtr, buf) {
    readAsmConstArgsArray.length = 0;
    var ch;
    buf >>= 2;
    while ((ch = HEAPU8[sigPtr++])) {
      var readAsmConstArgsDouble = ch < 105;
      if (readAsmConstArgsDouble && buf & 1) {
        buf++;
      }
      readAsmConstArgsArray.push(
        readAsmConstArgsDouble ? HEAPF64[buf++ >> 1] : HEAP32[buf]
      );
      ++buf;
    }
    return readAsmConstArgsArray;
  }

  function _emscripten_asm_const_int(code, sigPtr, argbuf) {
    var args = readAsmConstArgs(sigPtr, argbuf);
    return ASM_CONSTS[code].apply(null, args);
  }

  function _emscripten_get_heap_max() {
    return 2147483648;
  }

  var _emscripten_get_now;

  _emscripten_get_now = () => performance.now();

  function _emscripten_memcpy_big(dest, src, num) {
    HEAPU8.copyWithin(dest, src, src + num);
  }

  function emscripten_realloc_buffer(size) {
    try {
      wasmMemory.grow((size - buffer.byteLength + 65535) >>> 16);
      updateGlobalBufferAndViews(wasmMemory.buffer);
      return 1;
    } catch (e) {}
  }

  function _emscripten_resize_heap(requestedSize) {
    var oldSize = HEAPU8.length;
    requestedSize = requestedSize >>> 0;
    var maxHeapSize = _emscripten_get_heap_max();
    if (requestedSize > maxHeapSize) {
      return false;
    }
    let alignUp = (x, multiple) => x + ((multiple - (x % multiple)) % multiple);
    for (var cutDown = 1; cutDown <= 4; cutDown *= 2) {
      var overGrownHeapSize = oldSize * (1 + 0.2 / cutDown);
      overGrownHeapSize = Math.min(
        overGrownHeapSize,
        requestedSize + 100663296
      );
      var newSize = Math.min(
        maxHeapSize,
        alignUp(Math.max(requestedSize, overGrownHeapSize), 65536)
      );
      var replacement = emscripten_realloc_buffer(newSize);
      if (replacement) {
        return true;
      }
    }
    return false;
  }

  var ENV = {};

  function getExecutableName() {
    return thisProgram || "./this.program";
  }

  function getEnvStrings() {
    if (!getEnvStrings.strings) {
      var lang =
        (
          (typeof navigator == "object" &&
            navigator.languages &&
            navigator.languages[0]) ||
          "C"
        ).replace("-", "_") + ".UTF-8";
      var env = {
        USER: "web_user",
        LOGNAME: "web_user",
        PATH: "/",
        PWD: "/",
        HOME: "/home/web_user",
        LANG: lang,
        _: getExecutableName(),
      };
      for (var x in ENV) {
        if (ENV[x] === undefined) {
          delete env[x];
        } else {
          env[x] = ENV[x];
        }
      }
      var strings = [];
      for (var x in env) {
        strings.push(x + "=" + env[x]);
      }
      getEnvStrings.strings = strings;
    }
    return getEnvStrings.strings;
  }

  function _environ_get(__environ, environ_buf) {
    var bufSize = 0;
    getEnvStrings().forEach(function (string, i) {
      var ptr = environ_buf + bufSize;
      HEAP32[(__environ + i * 4) >> 2] = ptr;
      writeAsciiToMemory(string, ptr);
      bufSize += string.length + 1;
    });
    return 0;
  }

  function _environ_sizes_get(penviron_count, penviron_buf_size) {
    var strings = getEnvStrings();
    HEAP32[penviron_count >> 2] = strings.length;
    var bufSize = 0;
    strings.forEach(function (string) {
      bufSize += string.length + 1;
    });
    HEAP32[penviron_buf_size >> 2] = bufSize;
    return 0;
  }

  function _exit(status) {
    exit(status);
  }

  function _fd_close(fd) {
    return 0;
  }

  function _fd_read(fd, iov, iovcnt, pnum) {
    var stream = SYSCALLS.getStreamFromFD(fd);
    var num = SYSCALLS.doReadv(stream, iov, iovcnt);
    HEAP32[pnum >> 2] = num;
    return 0;
  }

  function _fd_seek(fd, offset_low, offset_high, whence, newOffset) {}

  function _fd_write(fd, iov, iovcnt, pnum) {
    var num = 0;
    for (var i = 0; i < iovcnt; i++) {
      var ptr = HEAP32[iov >> 2];
      var len = HEAP32[(iov + 4) >> 2];
      iov += 8;
      for (var j = 0; j < len; j++) {
        SYSCALLS.printChar(fd, HEAPU8[ptr + j]);
      }
      num += len;
    }
    HEAP32[pnum >> 2] = num;
    return 0;
  }

  function getRandomDevice() {
    if (
      typeof crypto == "object" &&
      typeof crypto.getRandomValues == "function"
    ) {
      var randomBuffer = new Uint8Array(1);
      return function () {
        crypto.getRandomValues(randomBuffer);
        return randomBuffer[0];
      };
    }
    return function () {
      abort("randomDevice");
    };
  }

  function _getentropy(buffer, size) {
    if (!_getentropy.randomDevice) {
      _getentropy.randomDevice = getRandomDevice();
    }
    for (var i = 0; i < size; i++) {
      HEAP8[(buffer + i) >> 0] = _getentropy.randomDevice();
    }
    return 0;
  }

  function _pclose() {
    err("missing function: pclose");
    abort(-1);
  }

  function _setTempRet0(val) {
    setTempRet0(val);
  }

  function __isLeapYear(year) {
    return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
  }

  function __arraySum(array, index) {
    var sum = 0;
    for (var i = 0; i <= index; sum += array[i++]) {}
    return sum;
  }

  var __MONTH_DAYS_LEAP = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  var __MONTH_DAYS_REGULAR = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  function __addDays(date, days) {
    var newDate = new Date(date.getTime());
    while (days > 0) {
      var leap = __isLeapYear(newDate.getFullYear());
      var currentMonth = newDate.getMonth();
      var daysInCurrentMonth = (
        leap ? __MONTH_DAYS_LEAP : __MONTH_DAYS_REGULAR
      )[currentMonth];
      if (days > daysInCurrentMonth - newDate.getDate()) {
        days -= daysInCurrentMonth - newDate.getDate() + 1;
        newDate.setDate(1);
        if (currentMonth < 11) {
          newDate.setMonth(currentMonth + 1);
        } else {
          newDate.setMonth(0);
          newDate.setFullYear(newDate.getFullYear() + 1);
        }
      } else {
        newDate.setDate(newDate.getDate() + days);
        return newDate;
      }
    }
    return newDate;
  }

  function _strftime(s, maxsize, format, tm) {
    var tm_zone = HEAP32[(tm + 40) >> 2];
    var date = {
      tm_sec: HEAP32[tm >> 2],
      tm_min: HEAP32[(tm + 4) >> 2],
      tm_hour: HEAP32[(tm + 8) >> 2],
      tm_mday: HEAP32[(tm + 12) >> 2],
      tm_mon: HEAP32[(tm + 16) >> 2],
      tm_year: HEAP32[(tm + 20) >> 2],
      tm_wday: HEAP32[(tm + 24) >> 2],
      tm_yday: HEAP32[(tm + 28) >> 2],
      tm_isdst: HEAP32[(tm + 32) >> 2],
      tm_gmtoff: HEAP32[(tm + 36) >> 2],
      tm_zone: tm_zone ? UTF8ToString(tm_zone) : "",
    };
    var pattern = UTF8ToString(format);
    var EXPANSION_RULES_1 = {
      "%c": "%a %b %d %H:%M:%S %Y",
      "%D": "%m/%d/%y",
      "%F": "%Y-%m-%d",
      "%h": "%b",
      "%r": "%I:%M:%S %p",
      "%R": "%H:%M",
      "%T": "%H:%M:%S",
      "%x": "%m/%d/%y",
      "%X": "%H:%M:%S",
      "%Ec": "%c",
      "%EC": "%C",
      "%Ex": "%m/%d/%y",
      "%EX": "%H:%M:%S",
      "%Ey": "%y",
      "%EY": "%Y",
      "%Od": "%d",
      "%Oe": "%e",
      "%OH": "%H",
      "%OI": "%I",
      "%Om": "%m",
      "%OM": "%M",
      "%OS": "%S",
      "%Ou": "%u",
      "%OU": "%U",
      "%OV": "%V",
      "%Ow": "%w",
      "%OW": "%W",
      "%Oy": "%y",
    };
    for (var rule in EXPANSION_RULES_1) {
      pattern = pattern.replace(new RegExp(rule, "g"), EXPANSION_RULES_1[rule]);
    }
    var WEEKDAYS = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
    ];
    var MONTHS = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    function leadingSomething(value, digits, character) {
      var str = typeof value == "number" ? value.toString() : value || "";
      while (str.length < digits) {
        str = character[0] + str;
      }
      return str;
    }
    function leadingNulls(value, digits) {
      return leadingSomething(value, digits, "0");
    }
    function compareByDay(date1, date2) {
      function sgn(value) {
        return value < 0 ? -1 : value > 0 ? 1 : 0;
      }
      var compare;
      if ((compare = sgn(date1.getFullYear() - date2.getFullYear())) === 0) {
        if ((compare = sgn(date1.getMonth() - date2.getMonth())) === 0) {
          compare = sgn(date1.getDate() - date2.getDate());
        }
      }
      return compare;
    }
    function getFirstWeekStartDate(janFourth) {
      switch (janFourth.getDay()) {
        case 0:
          return new Date(janFourth.getFullYear() - 1, 11, 29);

        case 1:
          return janFourth;

        case 2:
          return new Date(janFourth.getFullYear(), 0, 3);

        case 3:
          return new Date(janFourth.getFullYear(), 0, 2);

        case 4:
          return new Date(janFourth.getFullYear(), 0, 1);

        case 5:
          return new Date(janFourth.getFullYear() - 1, 11, 31);

        case 6:
          return new Date(janFourth.getFullYear() - 1, 11, 30);
      }
    }
    function getWeekBasedYear(date) {
      var thisDate = __addDays(
        new Date(date.tm_year + 1900, 0, 1),
        date.tm_yday
      );
      var janFourthThisYear = new Date(thisDate.getFullYear(), 0, 4);
      var janFourthNextYear = new Date(thisDate.getFullYear() + 1, 0, 4);
      var firstWeekStartThisYear = getFirstWeekStartDate(janFourthThisYear);
      var firstWeekStartNextYear = getFirstWeekStartDate(janFourthNextYear);
      if (compareByDay(firstWeekStartThisYear, thisDate) <= 0) {
        if (compareByDay(firstWeekStartNextYear, thisDate) <= 0) {
          return thisDate.getFullYear() + 1;
        }
        return thisDate.getFullYear();
      }
      return thisDate.getFullYear() - 1;
    }
    var EXPANSION_RULES_2 = {
      "%a": function (date) {
        return WEEKDAYS[date.tm_wday].substring(0, 3);
      },
      "%A": function (date) {
        return WEEKDAYS[date.tm_wday];
      },
      "%b": function (date) {
        return MONTHS[date.tm_mon].substring(0, 3);
      },
      "%B": function (date) {
        return MONTHS[date.tm_mon];
      },
      "%C": function (date) {
        var year = date.tm_year + 1900;
        return leadingNulls((year / 100) | 0, 2);
      },
      "%d": function (date) {
        return leadingNulls(date.tm_mday, 2);
      },
      "%e": function (date) {
        return leadingSomething(date.tm_mday, 2, " ");
      },
      "%g": function (date) {
        return getWeekBasedYear(date).toString().substring(2);
      },
      "%G": function (date) {
        return getWeekBasedYear(date);
      },
      "%H": function (date) {
        return leadingNulls(date.tm_hour, 2);
      },
      "%I": function (date) {
        var twelveHour = date.tm_hour;
        if (twelveHour == 0) {
          twelveHour = 12;
        } else if (twelveHour > 12) {
          twelveHour -= 12;
        }
        return leadingNulls(twelveHour, 2);
      },
      "%j": function (date) {
        return leadingNulls(
          date.tm_mday +
            __arraySum(
              __isLeapYear(date.tm_year + 1900)
                ? __MONTH_DAYS_LEAP
                : __MONTH_DAYS_REGULAR,
              date.tm_mon - 1
            ),
          3
        );
      },
      "%m": function (date) {
        return leadingNulls(date.tm_mon + 1, 2);
      },
      "%M": function (date) {
        return leadingNulls(date.tm_min, 2);
      },
      "%n": function () {
        return "\n";
      },
      "%p": function (date) {
        if (date.tm_hour >= 0 && date.tm_hour < 12) {
          return "AM";
        }
        return "PM";
      },
      "%S": function (date) {
        return leadingNulls(date.tm_sec, 2);
      },
      "%t": function () {
        return "\t";
      },
      "%u": function (date) {
        return date.tm_wday || 7;
      },
      "%U": function (date) {
        var days = date.tm_yday + 7 - date.tm_wday;
        return leadingNulls(Math.floor(days / 7), 2);
      },
      "%V": function (date) {
        var val = Math.floor((date.tm_yday + 7 - ((date.tm_wday + 6) % 7)) / 7);
        if ((date.tm_wday + 371 - date.tm_yday - 2) % 7 <= 2) {
          val++;
        }
        if (!val) {
          val = 52;
          var dec31 = (date.tm_wday + 7 - date.tm_yday - 1) % 7;
          if (
            dec31 == 4 ||
            (dec31 == 5 && __isLeapYear((date.tm_year % 400) - 1))
          ) {
            val++;
          }
        } else if (val == 53) {
          var jan1 = (date.tm_wday + 371 - date.tm_yday) % 7;
          if (jan1 != 4 && (jan1 != 3 || !__isLeapYear(date.tm_year))) {
            val = 1;
          }
        }
        return leadingNulls(val, 2);
      },
      "%w": function (date) {
        return date.tm_wday;
      },
      "%W": function (date) {
        var days = date.tm_yday + 7 - ((date.tm_wday + 6) % 7);
        return leadingNulls(Math.floor(days / 7), 2);
      },
      "%y": function (date) {
        return (date.tm_year + 1900).toString().substring(2);
      },
      "%Y": function (date) {
        return date.tm_year + 1900;
      },
      "%z": function (date) {
        var off = date.tm_gmtoff;
        var ahead = off >= 0;
        off = Math.abs(off) / 60;
        off = (off / 60) * 100 + (off % 60);
        return (ahead ? "+" : "-") + String("0000" + off).slice(-4);
      },
      "%Z": function (date) {
        return date.tm_zone;
      },
      "%%": function () {
        return "%";
      },
    };
    pattern = pattern.replace(/%%/g, "\0\0");
    for (var rule in EXPANSION_RULES_2) {
      if (pattern.includes(rule)) {
        pattern = pattern.replace(
          new RegExp(rule, "g"),
          EXPANSION_RULES_2[rule](date)
        );
      }
    }
    pattern = pattern.replace(/\0\0/g, "%");
    var bytes = intArrayFromString(pattern, false);
    if (bytes.length > maxsize) {
      return 0;
    }
    writeArrayToMemory(bytes, s);
    return bytes.length - 1;
  }

  function _strftime_l(s, maxsize, format, tm) {
    return _strftime(s, maxsize, format, tm);
  }

  InternalError = Module.InternalError = extendError(Error, "InternalError");

  embind_init_charCodes();

  BindingError = Module.BindingError = extendError(Error, "BindingError");

  init_ClassHandle();

  init_embind();

  init_RegisteredPointer();

  UnboundTypeError = Module.UnboundTypeError = extendError(
    Error,
    "UnboundTypeError"
  );

  init_emval();

  function intArrayFromString(stringy, dontAddNull, length) {
    var len = length > 0 ? length : lengthBytesUTF8(stringy) + 1;
    var u8array = new Array(len);
    var numBytesWritten = stringToUTF8Array(
      stringy,
      u8array,
      0,
      u8array.length
    );
    if (dontAddNull) {
      u8array.length = numBytesWritten;
    }
    return u8array;
  }

  var asmLibraryArg = {
    __assert_fail: ___assert_fail,
    __cxa_allocate_exception: ___cxa_allocate_exception,
    __cxa_rethrow: ___cxa_rethrow,
    __cxa_throw: ___cxa_throw,
    __syscall_faccessat: ___syscall_faccessat,
    __syscall_fcntl64: ___syscall_fcntl64,
    __syscall_fstat64: ___syscall_fstat64,
    __syscall_getcwd: ___syscall_getcwd,
    __syscall_ioctl: ___syscall_ioctl,
    __syscall_lstat64: ___syscall_lstat64,
    __syscall_newfstatat: ___syscall_newfstatat,
    __syscall_openat: ___syscall_openat,
    __syscall_renameat: ___syscall_renameat,
    __syscall_rmdir: ___syscall_rmdir,
    __syscall_stat64: ___syscall_stat64,
    __syscall_unlinkat: ___syscall_unlinkat,
    _embind_finalize_value_object: __embind_finalize_value_object,
    _embind_register_bigint: __embind_register_bigint,
    _embind_register_bool: __embind_register_bool,
    _embind_register_class: __embind_register_class,
    _embind_register_class_constructor: __embind_register_class_constructor,
    _embind_register_class_function: __embind_register_class_function,
    _embind_register_emval: __embind_register_emval,
    _embind_register_float: __embind_register_float,
    _embind_register_integer: __embind_register_integer,
    _embind_register_memory_view: __embind_register_memory_view,
    _embind_register_smart_ptr: __embind_register_smart_ptr,
    _embind_register_std_string: __embind_register_std_string,
    _embind_register_std_wstring: __embind_register_std_wstring,
    _embind_register_value_object: __embind_register_value_object,
    _embind_register_value_object_field: __embind_register_value_object_field,
    _embind_register_void: __embind_register_void,
    _emscripten_date_now: __emscripten_date_now,
    _emscripten_get_now_is_monotonic: __emscripten_get_now_is_monotonic,
    _emval_call: __emval_call,
    _emval_decref: __emval_decref,
    _emval_incref: __emval_incref,
    _emval_take_value: __emval_take_value,
    _localtime_js: __localtime_js,
    _mmap_js: __mmap_js,
    _munmap_js: __munmap_js,
    _tzset_js: __tzset_js,
    abort: _abort,
    emscripten_asm_const_int: _emscripten_asm_const_int,
    emscripten_get_heap_max: _emscripten_get_heap_max,
    emscripten_get_now: _emscripten_get_now,
    emscripten_memcpy_big: _emscripten_memcpy_big,
    emscripten_resize_heap: _emscripten_resize_heap,
    environ_get: _environ_get,
    environ_sizes_get: _environ_sizes_get,
    exit: _exit,
    fd_close: _fd_close,
    fd_read: _fd_read,
    fd_seek: _fd_seek,
    fd_write: _fd_write,
    getentropy: _getentropy,
    memory: wasmMemory,
    pclose: _pclose,
    setTempRet0: _setTempRet0,
    strftime_l: _strftime_l,
  };

  var asm = createWasm();

  var calledRun;

  function ExitStatus(status) {
    this.name = "ExitStatus";
    this.message = "Program terminated with exit(" + status + ")";
    this.status = status;
  }

  dependenciesFulfilled = function runCaller() {
    if (!calledRun) {
      run();
    }
    if (!calledRun) {
      dependenciesFulfilled = runCaller;
    }
  };

  function run(args) {
    args = args || arguments_;
    if (runDependencies > 0) {
      return;
    }
    preRun();
    if (runDependencies > 0) {
      return;
    }
    function doRun() {
      if (calledRun) {
        return;
      }
      calledRun = true;
      Module.calledRun = true;
      if (ABORT) {
        return;
      }
      initRuntime();
      if (Module.onRuntimeInitialized) {
        Module.onRuntimeInitialized();
      }
      postRun();
    }
    if (Module.setStatus) {
      Module.setStatus("Running...");
      setTimeout(function () {
        setTimeout(function () {
          Module.setStatus("");
        }, 1);
        doRun();
      }, 1);
    } else {
      doRun();
    }
  }

  Module.run = run;

  function exit(status, implicit) {
    EXITSTATUS = status;
    procExit(status);
  }

  function procExit(code) {
    EXITSTATUS = code;
    if (!keepRuntimeAlive()) {
      if (Module.onExit) {
        Module.onExit(code);
      }
      ABORT = true;
    }
    quit_(code, new ExitStatus(code));
  }

  if (Module.preInit) {
    if (typeof Module.preInit == "function") {
      Module.preInit = [Module.preInit];
    }
    while (Module.preInit.length) {
      Module.preInit.pop()();
    }
  }

  run();

  /* Use an optimized gemm implementation if available, otherwise use the fallback
   * implementation.
   */
  function createWasmGemm() {
    // A map of expected gemm function to the corresponding fallback gemm function names.
    const GEMM_TO_FALLBACK_FUNCTIONS_MAP = {
      int8_prepare_a: "int8PrepareAFallback",
      int8_prepare_b: "int8PrepareBFallback",
      int8_prepare_b_from_transposed: "int8PrepareBFromTransposedFallback",
      int8_prepare_b_from_quantized_transposed:
        "int8PrepareBFromQuantizedTransposedFallback",
      int8_prepare_bias: "int8PrepareBiasFallback",
      int8_multiply_and_add_bias: "int8MultiplyAndAddBiasFallback",
      int8_select_columns_of_b: "int8SelectColumnsOfBFallback",
    };

    // Name of the optimized gemm implementation.
    const OPTIMIZED_GEMM = "mozIntGemm";

    const optimizedGemmModule = WebAssembly[OPTIMIZED_GEMM];
    if (!optimizedGemmModule) {
      return fallbackGemm(GEMM_TO_FALLBACK_FUNCTIONS_MAP);
    }

    const optimizedGemmModuleExports = new WebAssembly.Instance(
      optimizedGemmModule(),
      { "": { memory: wasmMemory } }
    ).exports;
    for (let key in GEMM_TO_FALLBACK_FUNCTIONS_MAP) {
      if (!optimizedGemmModuleExports[key]) {
        return fallbackGemm(GEMM_TO_FALLBACK_FUNCTIONS_MAP);
      }
    }
    Module.print(`Using optimized gemm (${OPTIMIZED_GEMM}) implementation`);
    return optimizedGemmModuleExports;
  }

  // Return the fallback gemm implementation.
  function fallbackGemm(gemmToFallbackFunctionsMap) {
    // The fallback gemm implementation
    const FALLBACK_GEMM = "asm";

    let fallbackGemmModuleExports = {};
    for (let key in gemmToFallbackFunctionsMap) {
      fallbackGemmModuleExports[key] = (...a) =>
        Module[FALLBACK_GEMM][gemmToFallbackFunctionsMap[key]](...a);
    }
    Module.print(`Using fallback gemm implementation`);
    return fallbackGemmModuleExports;
  }

  return Module;
}
