const glob = require('glob');
const path = require('path');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin')

module.exports = {
  entry: {
    AllFramesAtDocumentEnd: glob.sync('./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentEnd/*.js'),
    AllFramesAtDocumentStart: glob.sync('./Client/Frontend/UserContent/UserScripts/AllFrames/AtDocumentStart/*.js'),
    MainFrameAtDocumentEnd: glob.sync('./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentEnd/*.js'),
    MainFrameAtDocumentStart: glob.sync('./Client/Frontend/UserContent/UserScripts/MainFrame/AtDocumentStart/*.js')
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'Client/Assets')
  },
  plugins: [
    new UglifyJsPlugin()
  ]
};
