const glob = require("glob");
const path = require("path");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");

module.exports = {
  mode: "production",
  entry: [
    "./Client/Frontend/WebExtensions/UserScripts/API/__browser__.js"
  ],
  output: {
    filename: "WebExtensionAPI.js",
    path: path.resolve(__dirname, "Client/Assets"),
    library: "api"
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
                  iOS: "11.0"
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
