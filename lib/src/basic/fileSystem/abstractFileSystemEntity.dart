import "package:mammouth/src/basic/fileSystem/abstractDirectory.dart";

abstract class AbstractFileSystemEntity {
  String get name;

  Uri get uri;

  bool get exist;

  AbstractDirectory get directory;
}
