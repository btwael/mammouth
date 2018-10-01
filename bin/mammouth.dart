import "dart:io";

import "package:args/args.dart" show ArgParser, ArgResults;
import "package:path/path.dart" as p;
import "package:yaml/yaml.dart" show loadYaml, YamlMap;

import "package:mammouth/src/mammouth.dart" show Mammouth;
import "package:mammouth/src/language/php/version.dart" as php;
import "package:mammouth/src/platform/vm/fileSystem.dart";
import "package:mammouth/src/platform/vm/session.dart" show VMSession;

void main(List<String> arguments) {
  arguments = ["build", "./bin/test"];
  // Build the arguments parser
  ArgParser argParser = new ArgParser();
  argParser.addCommand("build")
    ..addOption("output", abbr: "o");

  ArgResults result = argParser.parse(arguments);

  if(result.command != null && result.command?.name == "build") {
    String path = result.command.rest.first;
    if(FileSystemEntity.isFileSync(path)) {
    } else if(FileSystemEntity.isDirectorySync(path)) {
      Directory directory = new Directory(path);
      String mammouthFilePath = directory.uri.resolve("mammouth.yaml")
          .toFilePath();
      if(FileSystemEntity.typeSync(mammouthFilePath) !=
          FileSystemEntityType.notFound) {
        new Mammouth()
          ..compilePackage(path, () {
            return new VMSession();
          });
      } else {
        // TODO:
      }
    } else {
      // TODO:
    }
  }
}