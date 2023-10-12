import "dart:io";
import 'package:path/path.dart' as path;

const _pathDelimiter = "___";

class Token {
  final String value;
  final int position;
  Token(this.value, this.position);
}

String readIndexHTML(String filePath) {
  final File indexFile = File(path.join(filePath, "index.html"));
  if (!indexFile.existsSync()) {
    print(
        "Error: index.html file not found in the specified path: '$filePath'");
    exit(1);
  }
  final String indexContents = indexFile.readAsStringSync();
  return indexContents;
}

void writeIndexHTML(String filePath, String contents) {
  final Directory buildDirectory = Directory("$filePath/build");
  if (!buildDirectory.existsSync()) {
    buildDirectory.createSync();
  }

  // Find the head tag and insert the index.js script tag and the index.css tag
  final RegExp headTagRegExp = RegExp(r"<head>([\s\S]*?)<\/head>");
  final headMatch = headTagRegExp.firstMatch(contents);

  if (headMatch != null) {
    String headContent = headMatch.group(1) ?? "";
    String newHeadContent =
        '$headContent\n    <script defer src="index.js"></script>\n    <link rel="stylesheet" href="index.css">\n';
    contents = contents.replaceFirst(headContent, newHeadContent);
  }

  // Write modified HTML content to build/index.html
  final File buildIndexFile = File(path.join(filePath, "build", "index.html"));
  buildIndexFile.writeAsStringSync(contents);
}

String processRootHtmlContent(String rootHtmlContent, String filePath,
    StringBuffer jsBuffer, StringBuffer cssBuffer) {
  final Set<String> visitedTags = {};

  final newIndexHTMLContents = _replaceCustomTags(
      rootHtmlContent, filePath, visitedTags, jsBuffer, cssBuffer);

  return newIndexHTMLContents;
}

void writeCSS(String filePath, String contents) {
  final File cssFile = File(path.join(filePath, "build", "index.css"));
  cssFile.writeAsStringSync(contents);
}

void writeJS(String filePath, String contents) {
  final File jsFile = File(path.join(filePath, "build", "index.js"));
  jsFile.writeAsStringSync(contents);
}

String _replaceCustomTags(String htmlContent, String currentPath,
    Set<String> visited, StringBuffer jsBuffer, StringBuffer cssBuffer) {
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

    tagContents =
        _preprocessPinepackAttributes(tagContents, namespace, tagFilePath);

    // Extract and accumulate JS and CSS
    final componentJS = _extractJS(tagContents, namespace);
    final componentCSS = _extractCSS(tagContents, namespace);

    jsBuffer.write(componentJS);
    cssBuffer.write(componentCSS);

    // Recursively replace custom tags within this component
    final newContents = _replaceCustomTags(
        tagContents, currentPath, visited, jsBuffer, cssBuffer);

    // Namespace the HTML
    final namespacedHTML = _namespaceHTML(newContents, namespace);

    visited.remove(tagFilePath);

    return namespacedHTML;
  });
}

String _preprocessPinepackAttributes(
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

String _extractCSS(String componentContent, String namespace) {
  final RegExp styleRegExp = RegExp(r"<style>([\s\S]*?)<\/style>");
  final styleMatch = styleRegExp.firstMatch(componentContent);
  final componentCSS = styleMatch?.group(1) ?? "";
  return namespaceCSS(componentCSS, namespace);
}

String _namespaceHTML(String htmlContent, String namespace) {
  final namespacedHTML = htmlContent.replaceAllMapped(
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

  // Extract the portion inside the <template> tag
  final templateRegExp = RegExp(r"<template>([\s\S]*?)<\/template>");
  final templateMatch = templateRegExp.firstMatch(namespacedHTML);

  final extractedHTML = templateMatch?.group(1) ?? "";

  // New line: Wrap namespacedHTML in a div with the component ID
  final wrappedHTML = '<div id="$namespace">$extractedHTML    </div>';

  return wrappedHTML;
}

String _extractJS(String componentContent, String namespace) {
  final RegExp scriptRegExp = RegExp(r"<script>([\s\S]*?)<\/script>");
  final scriptMatch = scriptRegExp.firstMatch(componentContent);
  String extractedJS = scriptMatch?.group(1) ?? "";

  return namespaceJS(extractedJS, namespace);
}

String namespaceJS(String jsContent, String namespace) {
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
  result.write('(function() {\n');
  result.write(jsContent); // Original JavaScript code of the component
  result.write('\n\n');

  // Append the DOMContentLoaded logic
  result.write(domContentLoadedFunction);
  result.write('\n})();\n'); // Close the IIFE

  return result.toString();
}

String namespaceCSS(String cssContent, String namespace) {
  // Wrapping the namespaced CSS inside a specific selector tied to the component ID
  StringBuffer namespacedCSS = StringBuffer();
  namespacedCSS.write("#$namespace {\n");

  String modifiedCSS = cssContent.replaceAllMapped(
    RegExp(r'(\.|#)([a-zA-Z_][a-zA-Z0-9_-]*)'),
    (Match m) {
      final modifiedName = m.group(2);
      return '${m.group(1)}$namespace$_pathDelimiter$modifiedName';
    },
  );

  namespacedCSS.write(modifiedCSS);
  namespacedCSS.write("\n}");

  return namespacedCSS.toString();
}

String _generateNamespace(String filePath) {
  var namespace = filePath
      .replaceAll('.', _pathDelimiter)
      .replaceAll('-', '_')
      .replaceAll(path.separator, _pathDelimiter);

  return "pinepack___$namespace";
}
