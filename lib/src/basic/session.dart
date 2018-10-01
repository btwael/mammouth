import "package:mammouth/src/basic/fileSystem/abstractDirectory.dart";
import "package:mammouth/src/basic/fileSystem/abstractFileSystem.dart";
import "package:mammouth/src/language/php/version.dart";

class Package {
  String name;
  Version target;
  String buildDir;
  bool requireRuntime = false;
}

abstract class Session {
  Package _package;

  Version target; // THIS IS KEPT FOR TEST convert to getter

  Package get package => _package;

  void set package(Package package) {
    _package = package;
    this.target = package.target;
  }

  AbstractDirectory get projectRoot;

  void set projectRoot(AbstractDirectory dir);

  AbstractFileSystem get fileSystem;
}

class WebSession extends Session {
  Version target = new Version.fromString("5.3.0");

  AbstractDirectory projectRoot;

  AbstractFileSystem fileSystem;
}