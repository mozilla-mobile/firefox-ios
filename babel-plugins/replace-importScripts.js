/// This plugin transforms `importScripts("file.js")` into `import "file.js";`
/// If useScriptLoader is set to true then it's transformed into
/// `import "script-loader!file.js";` allowing non-exported values to be accessible.
/// TODO(Issam): Add comments to explain why this is needed.
module.exports = function () {
  return {
    visitor: {
      CallExpression(path, state) {
        if (
          path.node.callee.name === "importScripts" &&
          path.node.arguments.length === 1 &&
          path.node.arguments[0].type === "StringLiteral"
        ) {
          const importPath = path.node.arguments[0].value.split("/").pop();
          const useScriptLoader = state.opts?.useScriptLoader || false;
          const transformedImport = useScriptLoader
            ? `require("script-loader!./${importPath}")`
            : `require("./${importPath}")`;
          path.replaceWithSourceString(transformedImport);
        }
      },
    },
  };
};