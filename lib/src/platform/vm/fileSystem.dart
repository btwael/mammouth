import "dart:io";

import "package:path/path.dart" as p;

import "package:mammouth/src/basic/fileSystem/abstractDirectory.dart";
import "package:mammouth/src/basic/fileSystem/abstractFile.dart";
import "package:mammouth/src/basic/fileSystem/abstractFileSystem.dart";
import "package:mammouth/src/basic/fileSystem/abstractFileSystemEntity.dart";
import "package:mammouth/src/basic/option.dart" show Option;
import "package:mammouth/src/basic/source.dart" show Source;

class VMFile extends AbstractFile {
  File _file;

  VMFile(String path) : this._file = new File(path);

  String get name {
    return _file.uri.path
        .split("/")
        .last;
  }

  Uri get uri {
    return _file.uri;
  }

  bool get isSource {
    return true;
  }

  bool get exist {
    return this._file.existsSync();
  }

  VMDirectory get directory {
    return new VMDirectory(_file.parent.path);
  }
}

class VMSource extends Source {
  File _file;

  VMSource(String path) : this._file = new File(path);

  String get name {
    return _file.uri.path
        .split("/")
        .last;
  }

  Uri get uri {
    return _file.uri;
  }

  bool get isSource {
    return true;
  }

  bool get exist {
    return this._file.existsSync();
  }

  String get content {
    return this._file.readAsStringSync();
  }

  VMDirectory get directory {
    return new VMDirectory(_file.parent.path);
  }
}

class VMDirectory extends AbstractDirectory {
  Directory _directory;

  VMDirectory(String path) : this._directory = new Directory(path);

  String get name {
    return p.basename(_directory.uri.path);
  }

  Uri get uri {
    return _directory.uri;
  }

  bool get exist {
    return _directory.existsSync();
  }

  Iterable<AbstractFileSystemEntity> get content {
    return _directory.listSync().map((FileSystemEntity entity) {
      if(entity is Directory) {
        return new VMDirectory(entity.path);
      } else if(entity is File) {
        String extension = entity.path
            .split("/")
            .last
            .split(".")
            .last;
        if(extension == "mammouth" || extension == "mmt") {
          return new VMSource(entity.path);
        }
        return new VMFile(entity.path);
      }
    });
  }

  VMDirectory get directory {
    return new VMDirectory(_directory.parent.path);
  }
}

class VMFileSystem extends AbstractFileSystem {
  @override
  Option<Source> getSource(String path) {
    return new Option<Source>.Some(new VMSource(path));
  }

  @override
  Option<AbstractDirectory> getDirectory(String path) {
    return new Option<AbstractDirectory>.Some(new VMDirectory(path));
  }

  void writeFile(String path, String content) {
    new File(path)
      ..writeAsStringSync(content);
  }

  void createDir(String path) {
    new Directory(path)
      ..createSync();
  }

  void copyFile(AbstractFile file, String dest) {
    if(file is VMFile) {
      file._file.copySync(dest);
    }
  }
}
