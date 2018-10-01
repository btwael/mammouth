import "package:mammouth/src/basic/fileSystem/abstractDirectory.dart";
import "package:mammouth/src/basic/fileSystem/abstractFileSystemEntity.dart";

abstract class AbstractFile extends AbstractFileSystemEntity {
  bool get isSource;
}
