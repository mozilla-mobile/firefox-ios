const glob = require("glob");
const path = require("path");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");

const AllFramesAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentStart/*.js");
const AllFramesAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentEnd/*.js");
const MainFrameAtDocumentStart = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentStart/*.js");
const MainFrameAtDocumentEnd = glob.sync("./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentEnd/*.js");
const DocumentServices = glob.sync("./Client/Frontend/UserContent/UserScripts/DocumentServices/*.js");

MainFrameAtDocumentStart.push("./content-blocker-lib-ios/js/TrackingProtectionStats.js");

// Ensure the first script loaded at document start is __firefox__.js
// since it defines the `window.__firefox__` global.
const needsFirefoxFile = {
  AllFramesAtDocumentStart,
  // PDF content does not execute user scripts designated to 
  // run at document start for some reason. ¯\_(ツ)_/¯
  AllFramesAtDocumentEnd,
  DocumentServices,
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
    DocumentServices,
  },
  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "Client/Assets")
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules\/(?!(readability|page-metadata-parser)\/).*/,
        use: {
          loader: "babel-loader",
          options: {
            presets: [
              ["env", {
                targets: {
                  iOS: "10.3"
                }
              }]
            ]
          }
        }
      }
    ]
  },
  plugins: [
    new UglifyJsPlugin()
  ]
};
