abstract class Dependency<Data> {
  const Dependency.strong() : this._(const []);

  const Dependency.weak(List<String> ids) : this._(ids);

  final List<String> ids;

  const Dependency._(this.ids);

  String key([String? id]) => [...ids, if (id != null) id].join('&');
}
