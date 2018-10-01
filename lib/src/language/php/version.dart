class Version {
  final int major;
  final int minor;
  final int patch;

  Version(this.major, this.minor, this.patch);

  Version.fromString(String string)
      : this.major = int.parse(string.split(".")[0]),
        this.minor = int.parse(string.split(".")[1]),
        this.patch = int.parse(string.split(".")[2]);

  bool get supportBracketArray =>
      major > 5 || (major == 5 && minor >= 4); // >=5.4
}