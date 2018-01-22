const glob = require("glob");
const path = require("path");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");

const AllFramesAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentStart/*.js");
const AllFramesAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentEnd/*.js");
const MainFrameAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentStart/*.js");
const MainFrameAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentEnd/*.js");

// Ensure the first script loaded is __firefox__.js since it
// defines the `window.__firefox__` global for all scripts.
if (path.basename(AllFramesAtDocumentStart[0]) !== "__firefox__.js") {
  throw "ERROR: __firefox__.js is expected to be the first script in AllFramesAtDocumentStart.js";
}

module.exports = {
  entry: {
    AllFramesAtDocumentStart: AllFramesAtDocumentStart,
    AllFramesAtDocumentEnd: AllFramesAtDocumentEnd,
    MainFrameAtDocumentStart: MainFrameAtDocumentStart,
    MainFrameAtDocumentEnd: MainFrameAtDocumentEnd
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "Client/Assets")
  },
  plugins: [
    new UglifyJsPlugin()
  ]
};
