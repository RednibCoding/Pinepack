import "dart:io";
import 'package:path/path.dart' as path;

// Constants
const _pathDelimiter = "___";

class Token {
  final String value;
  final int position;
  Token(this.value, this.position);
}

void writeIndexHTML(String rootPath, String contents) {
  contents = _addResourcesToHead(contents);
  writeResource(rootPath, "index.html", contents);
}

String processRootHtmlContent(String rootHtmlContent, String filePath,
    Map<String, String> jsComponents, Map<String, String> cssComponents) {
  final Set<String> visitedTags = {};

  final newIndexHTMLContents = _replaceCustomTags(
      rootHtmlContent, filePath, visitedTags, jsComponents, cssComponents);

  return newIndexHTMLContents;
}

void writeResource(String rootPath, String fileName, String contents) {
  final Directory dir = Directory(_getBuildPath(rootPath));
  dir.createSync(recursive: true);
  final File file = File(_getBuildPath(rootPath, fileName));
  file.writeAsStringSync(contents);
}

String _replaceCustomTags(
  String htmlContent,
  String currentPath,
  Set<String> visited,
  Map<String, String> jsComponents,
  Map<String, String> cssComponents,
) {
  // Use a regular expression to find custom tags.
  final RegExp tagRegExp = RegExp(r"<([a-zA-Z0-9._-]+)\s*\/>");
  return htmlContent.replaceAllMapped(tagRegExp, (match) {
    final tagName = match.group(1);

    // Replace dots in tagName with directory separators.
    final normalizedTagName = tagName?.replaceAll('.', path.separator);

    // Construct the file path.
    final tagFilePath = path.join(currentPath, "$normalizedTagName.html");

    // Generate a namespace from the path
    final namespace = _generateNamespace(normalizedTagName ?? "");

    if (visited.contains(tagFilePath)) {
      print("Error: Cyclic dependency detected at '$tagFilePath'");
      exit(1);
    }

    final File tagFile = File(tagFilePath);
    if (!tagFile.existsSync()) {
      print("Error: Component file '$tagFilePath' not found.");
      exit(1);
    }

    visited.add(tagFilePath);
    var tagContents = tagFile.readAsStringSync();

    tagContents = _preprocessPlaceholders(tagContents, namespace, tagFilePath);

    // Extract and accumulate JS and CSS
    final componentJS = _extractJS(tagContents, namespace);
    final componentCSS = _extractCSS(tagContents, namespace);

    jsComponents[namespace] = componentJS;
    cssComponents[namespace] = componentCSS;

    // Recursively replace custom tags within this component
    final newContents = _replaceCustomTags(
        tagContents, currentPath, visited, jsComponents, cssComponents);

    // Namespace the HTML
    final namespacedHTML = _namespaceHTML(newContents, namespace);

    visited.remove(tagFilePath);

    return namespacedHTML;
  });
}

String _preprocessPlaceholders(
    String htmlContent, String namespace, String filename) {
  StringBuffer result = StringBuffer();
  bool isCapturing = false;
  String captured = "";
  int lineNumber = 1;

  for (int i = 0; i < htmlContent.length; i++) {
    if (htmlContent[i] == '\n') {
      lineNumber++;
    }

    if (htmlContent[i] == '@' && !isCapturing) {
      isCapturing = true;
      continue;
    }

    if (isCapturing) {
      if (htmlContent[i].isNotEmpty &&
          ((htmlContent[i].codeUnitAt(0) >= 65 &&
                  htmlContent[i].codeUnitAt(0) <= 90) ||
              (htmlContent[i].codeUnitAt(0) >= 97 &&
                  htmlContent[i].codeUnitAt(0) <= 122) ||
              (htmlContent[i].codeUnitAt(0) >= 48 &&
                  htmlContent[i].codeUnitAt(0) <= 57 &&
                  captured.isNotEmpty) ||
              htmlContent[i].codeUnitAt(0) == 95)) {
        captured += htmlContent[i];
        continue;
      } else {
        if (captured.isEmpty) {
          print(
              "Compile Error in file $filename at line $lineNumber : Invalid identifier after @ symbol. Only identifiers are allowed after @.");
          exit(1);
        }
        result.write('<span data-innerHTML="$captured"></span>');
        isCapturing = false;
        captured = "";
      }
    }

    result.write(htmlContent[i]);
  }

  if (isCapturing && captured.isNotEmpty) {
    result.write('<span data-innerHTML="$captured"></span>');
  }

  return result.toString();
}

String _modifyAttributes(String htmlContent, String namespace) {
  return htmlContent.replaceAllMapped(
    RegExp(r'class="([^"]+)"|id="([^"]+)"'),
    (Match m) {
      if (m.group(1) != null) {
        final modifiedClass = m.group(1)!;
        return 'class="$namespace$_pathDelimiter$modifiedClass"';
      } else if (m.group(2) != null) {
        final modifiedId = _generateNamespace(m.group(2)!);
        return 'id="$namespace$_pathDelimiter$modifiedId"';
      }
      return m.group(0)!; // Should not reach here
    },
  );
}

String _extractTemplate(String htmlContent) {
  final templateRegExp = RegExp(r"<template>([\s\S]*?)<\/template>");
  final templateMatch = templateRegExp.firstMatch(htmlContent);
  return templateMatch?.group(1) ?? "";
}

String _wrapInUniqueTag(String extractedHTML, String namespace) {
  return '<span id="$namespace">$extractedHTML    </span>';
}

String _namespaceHTML(String htmlContent, String namespace) {
  final namespacedHTML = _modifyAttributes(htmlContent, namespace);
  final extractedHTML = _extractTemplate(namespacedHTML);
  final wrappedHTML = _wrapInUniqueTag(extractedHTML, namespace);
  return wrappedHTML;
}

String _extractJS(String componentContent, String namespace) {
  final scriptMatch = _extractResource("script", componentContent);
  return _namespaceJS(scriptMatch, namespace);
}

String _extractCSS(String componentContent, String namespace) {
  final scriptMatch = _extractResource("style", componentContent);
  return _namespaceCSS(scriptMatch, namespace);
}

String _extractResource(String tag, String content) {
  final RegExp regex = RegExp('<$tag>([\\s\\S]*?)</$tag>');
  return regex.firstMatch(content)?.group(1) ?? "";
}

String _namespaceJS(String jsContent, String namespace) {
  final componentId = namespace;
  // Your component-specific DOMContentLoaded logic
  final domContentLoadedFunction = '''
document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("#$componentId [data-innerHTML]").forEach((elem) => {
    const attributeValue = elem.getAttribute("data-innerHTML");
    const localValue = eval(attributeValue);
    if (typeof localValue === "function") {
      elem.innerHTML = localValue();
    } else {
      elem.innerHTML = localValue;
    }
  });
});
  ''';

  // Wrap the JavaScript code for the component in an IIFE
  StringBuffer result = StringBuffer();
  result.write("/*****  $componentId   *****/\n");
  result.write('(function() {\n');
  result.write(jsContent.trim()); // Original JavaScript code of the component
  result.write('\n\n');

  // Append the DOMContentLoaded logic
  result.write(domContentLoadedFunction.trim());
  result.write('})();\n\n'); // Close the IIFE

  return result.toString();
}

String _namespaceCSS(String cssContent, String namespace) {
  // Wrapping the namespaced CSS inside a specific selector tied to the component ID
  StringBuffer namespacedCSS = StringBuffer();
  namespacedCSS.write("/*****  $namespace   *****/\n");
  namespacedCSS.write("#$namespace {\n");

  String modifiedCSS = cssContent.replaceAllMapped(
    RegExp(r'(\.|#)([a-zA-Z_][a-zA-Z0-9_-]*)'),
    (Match m) {
      final cssClassName = m.group(2);
      final type = m.group(1); // . or #
      return '$type$namespace$_pathDelimiter$cssClassName';
    },
  );

  namespacedCSS.write(modifiedCSS.trim());
  namespacedCSS.write("\n}\n");

  return namespacedCSS.toString();
}

String _generateNamespace(String filePath) {
  var namespace = filePath
      .replaceAll('.', _pathDelimiter)
      .replaceAll('-', '_')
      .replaceAll(path.separator, _pathDelimiter);

  return "pinepack___$namespace";
}

// Utility functions for reading and writing files
String readFile(String filePath, String fileName) {
  final File file = File(path.join(filePath, fileName));
  if (!file.existsSync()) {
    print("Error: File not found at '$filePath'");
    exit(1);
  }
  return file.readAsStringSync();
}

String _addResourcesToHead(String contents) {
  // Find the head tag and insert the index.js script tag and the index.css tag
  final RegExp headTagRegExp = RegExp(r"<head>([\s\S]*?)<\/head>");
  final headMatch = headTagRegExp.firstMatch(contents);
  String headContent = headMatch?.group(1) ?? "";
  return contents.replaceFirst(headContent,
      '$headContent\n<script defer src="index.js"></script>\n<link rel="stylesheet" href="index.css">\n');
}

// Utility function to generate fully qualified resource paths
String _getBuildPath(String rootPath, [String? fileName]) {
  if (fileName == null) {
    return path.join(rootPath, "build");
  }
  return path.join(rootPath, "build", fileName);
}
