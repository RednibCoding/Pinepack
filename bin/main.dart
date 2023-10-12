import "dart:io";
import "package:args/args.dart";
import "package:pinepack/pinepack.dart";

void main(List<String> args) {
  void printUsage(ArgParser argParser) {
    print("Usage:\n\tpinepack <path> [flags]");
    print("flags:\n\t${argParser.usage}");
  }

  final ArgParser argParser = ArgParser()
    ..addFlag("pretty",
        negatable: false,
        help: "Generate human-readable code instead of minified code");

  // final argss = ["html"];
  final ArgResults argResults = argParser.parse(args);

  if (argResults.rest.isEmpty) {
    printUsage(argParser);
    exit(0);
  }

  final String path = argResults.rest.first;
  // final pretty = argResults["pretty"];

  // Maps to hold aggregated JS and CSS
  final jsComponents = <String, String>{};
  final cssComponents = <String, String>{};

  final indexHTMLContents = readFile(path, "index.html");
  final newIndexHTMLContents = processRootHtmlContent(
      indexHTMLContents, path, jsComponents, cssComponents);

  final jsBuffer = StringBuffer();
  final cssBuffer = StringBuffer();

  for (final key in jsComponents.keys) {
    jsBuffer.write(jsComponents[key]);
    cssBuffer.write(cssComponents[key]);
  }

  writeIndexHTML(path, newIndexHTMLContents);
  writeResource(path, "index.js", jsBuffer.toString());
  writeResource(path, "index.css", cssBuffer.toString());
}
