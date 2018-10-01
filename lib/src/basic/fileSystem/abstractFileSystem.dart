import "package:mammouth/src/basic/option.dart";
import "package:mammouth/src/basic/fileSystem/abstractFile.dart";
import "package:mammouth/src/basic/fileSystem/abstractDirectory.dart";
import "package:mammouth/src/basic/source.dart";

abstract class AbstractFileSystem {
  Option<Source> getSource(String path);

  Option<AbstractDirectory> getDirectory(String path);

  void writeFile(String path, String content);

  void createDir(String path);

  void copyFile(AbstractFile file, String dest);
}
