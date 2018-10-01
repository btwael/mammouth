import "package:mammouth/src/basic/fileSystem/abstractDirectory.dart";
import "package:mammouth/src/basic/fileSystem/abstractFile.dart";

abstract class Source extends AbstractFile {
  String get content;
}

class BasicSource extends Source {
  final String _content;

  BasicSource(this._content);

  String get name {
    return "";
  }

  Uri get uri {
    return null;
  }

  @override
  bool get isSource {
    return true;
  }

  @override
  bool get exist {
    return true;
  }

  @override
  String get content {
    return this._content;
  }

  @override
  AbstractDirectory get directory {
    return null;
  }
}
