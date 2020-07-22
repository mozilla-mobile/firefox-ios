const glob = require("glob");
const path = require("path");

const AllFramesAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentStart/*.js");
const AllFramesAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentEnd/*.js");
const MainFrameAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentStart/*.js");
const MainFrameAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentEnd/*.js");

// Ensure the first script loaded at document start is __firefox__.js
// since it defines the `window.__firefox__` global.
const needsFirefoxFile = {
  AllFramesAtDocumentStart,

  // PDF content does not execute user scripts designated to
  // run at document start for some reason. So, we also need
  // to include __firefox__.js for the document end scripts.
  // ¯\_(ツ)_/¯
  AllFramesAtDocumentEnd,
};

for (let [name, files] of Object.entries(needsFirefoxFile)) {
  if (path.basename(files[0]) !== "__firefox__.js") {
    throw `ERROR: __firefox__.js is expected to be the first script in ${name}.js`;
  }
}

module.exports = {
  mode: "production",
  entry: {
    AllFramesAtDocumentStart,
    AllFramesAtDocumentEnd,
    MainFrameAtDocumentStart,
    MainFrameAtDocumentEnd,
  },
  // optimization: { minimize: false }, // use for debugging
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "Client/Assets")
  },
  module: {
    rules: []
  },
  plugins: []
};
