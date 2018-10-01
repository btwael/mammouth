import "package:mammouth/src/basic/fileSystem/abstractDirectory.dart";
import "package:mammouth/src/basic/fileSystem/abstractFileSystem.dart";
import "package:mammouth/src/basic/session.dart";
import "package:mammouth/src/platform/vm/fileSystem.dart";

class VMSession extends Session {
  VMFileSystem _fileSystem = new VMFileSystem();

  AbstractDirectory projectRoot;

  AbstractFileSystem get fileSystem => _fileSystem;
}