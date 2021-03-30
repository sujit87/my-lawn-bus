/// Represents a channel on a [Bus], with a [type] and optional [name].
class Channel {
  final Type type;
  final String name;
  Channel(
    this.type, {
    this.name,
  }) : assert(type != null, 'Channel type must not be null');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name;

  @override
  int get hashCode =>
      runtimeType.hashCode ^ type.hashCode ^ (name?.hashCode ?? 0);

  @override
  String toString() => 'Channel($type${name == null ? '' : ', $name'})';
}
