import "package:mammouth/src/basic/fileSystem/abstractFileSystemEntity.dart";

abstract class AbstractDirectory extends AbstractFileSystemEntity {
  Iterable<AbstractFileSystemEntity> get content;
}
