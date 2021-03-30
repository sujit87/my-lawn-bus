import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

import 'bus_state.dart';
import 'channel.dart';

/// A `Bus` passes data asynchronously via its predefined [channels],
/// in a basic publish/subscribe pattern.
///
/// Publishers pass data to subscribers via [publish]. Subscribers
/// choose to receive channel data as a [snapshot], or a [stream].
///
/// Channel streams immediately provide the latest data on subscription.
///
/// Make sure to call [destroy] when done with the bus.
///
/// It can be used as a super class, as a mixin,
/// or ad-hoc via a factory constructor.
abstract class Bus {
  var _state = BusState.Pending;

  final Map<Channel, BehaviorSubject> _subjects = {};

  /// Creates an ad-hoc instance of `Bus` with given [channels].
  factory Bus({List<Channel> channels}) => _Bus(channels: channels);

  /// Returns the [Logger] associated with this `Bus`.
  @protected
  Logger get log => Logger(runtimeType.toString());

  /// The current [BusState].
  BusState get state => _state;

  /// Whether this `Bus` has been initialized.
  bool get isInitialized => _state == BusState.Initialized;

  /// The channels defined on this `Bus`.
  List<Channel> get channels;

  /// Initializes the `Bus`, opening all [channels].
  ///
  /// This is also done implicitly if needed.
  @mustCallSuper
  void init() {
    switch (_state) {
      case BusState.Pending:
        channels?.forEach((channel) {
          _subjects[channel] = BehaviorSubject();
          log.fine('init: opened channel for $channel');
        });
        _state = BusState.Initialized;
        onInit();
        break;
      case BusState.Initialized:
        log.warning('init: can not initialize initialized bus');
        break;
      case BusState.Destroyed:
        throw StateError('init: can not initialize destroyed bus');
      default:
        throw StateError('init: illegal state $_state');
    }
  }

  /// Called when this `Bus` has been successfully initialized.
  ///
  /// This is called exactly once.
  void onInit() {}

  /// Destroys the `Bus`, closing all [channels].
  ///
  /// This should be called to free up resources,
  /// whenever a bus is no longer in use.
  @mustCallSuper
  void destroy() {
    switch (_state) {
      case BusState.Pending:
        log.warning('destroy: can not destroy pending bus');
        break;
      case BusState.Initialized:
        channels?.forEach((channel) {
          try {
            final subject = _subjects[channel];
            if (subject != null) {
              subject.close();
              log.fine('destroy: closed channel for $channel');
            }
          } catch (_) {
            // Do nothing.
          }
        });
        _subjects.clear();
        _state = BusState.Destroyed;
        onDestroy();
        break;
      case BusState.Destroyed:
        log.warning('destroy: can not destroy destroyed bus');
        break;
      default:
        throw StateError('destroy: illegal state $_state');
    }
  }

  /// Called when this `Bus` has been successfully destroyed.
  ///
  /// This is called exactly once.
  void onDestroy() {}

  BehaviorSubject _subject(Type type, String name) {
    // https://github.com/dart-lang/linter/issues/1381
    //ignore: close_sinks
    final subject = _subjects[Channel(type, name: name)];
    assert(
      subject != null,
      'Channel $type ${name == null ? '' : 'named $name '}is not registered',
    );
    return subject;
  }

  /// Returns a snapshot of channel of type [T], optionally named [name].
  T snapshot<T>({String name}) {
    assert(
      !(!(const Object() is! T)),
      'type must not be Object nor dynamic',
    );

    if (!isInitialized) {
      init();
    }

    return _subject(T, name).value;
  }

  /// Returns snapshots of all [channels],or of given [snapshotChannels].
  Map<Channel, dynamic> snapshots({List<Channel> snapshotChannels}) {
    if (!isInitialized) {
      init();
    }

    return Map.fromIterable(
      _subjects.keys
          .where((channel) => snapshotChannels?.contains(channel) ?? true),
      key: (channel) => channel,
      value: (channel) => _subjects[channel].value,
    );
  }

  /// Returns a stream of channel of type [T], optionally named [name].
  Stream<T> stream<T>({String name}) {
    assert(
      !(!(const Object() is! T)),
      'type must not be Object nor dynamic',
    );

    if (!isInitialized) {
      init();
    }

    return _subject(T, name).stream.cast<T>();
  }

  /// Returns a stream of all [channels], or of given [streamChannels].
  Stream<Map<Channel, dynamic>> streams({List<Channel> streamChannels}) {
    if (!isInitialized) {
      init();
    }

    return CombineLatestStream(
      _subjects.keys
          .where((channel) => streamChannels?.contains(channel) ?? true)
          .map((channel) =>
              _subjects[channel].map((value) => MapEntry(channel, value))),
      (listOfMapEntries) => Map.fromIterable(
        listOfMapEntries,
        key: (mapEntry) => mapEntry.key,
        value: (mapEntry) => mapEntry.value,
      ),
    );
  }

  /// Publishes data to channel of type [T], optionally named [name].
  ///
  /// Pass [data] directly, or via a [publisher] function.
  /// The publisher receives a snapshot of the channel and
  /// returns the data to be published.
  void publish<T>({String name, T data, T Function(T snapshot) publisher}) {
    assert(data != null || publisher != null,
        'data and publisher must not both be null');

    if (!isInitialized) {
      init();
    }

    if (data != null) {
      final type = data.runtimeType;
      assert(
        const Object().runtimeType != type,
        'type must not be Object nor dynamic',
      );

      log.finest('publish<$type>(${name == null ? '' : '$name, '}data)');
      _subject(type, name).add(data);
    } else {
      assert(
        !(!(const Object() is! T)),
        'type must not be Object nor dynamic',
      );

      log.finest('publish<$T>(${name == null ? '' : '$name, '}publisher)');
      // https://github.com/dart-lang/linter/issues/1381
      //ignore: close_sinks
      final subject = _subject(T, name);
      subject.add(publisher(subject.value));
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Bus && other.hashCode == hashCode;

  @override
  int get hashCode =>
      channels?.fold(runtimeType.hashCode,
          (previousValue, element) => previousValue ^ element.hashCode) ??
      0;

  @override
  String toString() => '$runtimeType($channels)';
}

// Private implementation, used by Bus factory constructor.
class _Bus with Bus {
  final List<Channel> _channels;

  _Bus({List<Channel> channels})
      : assert(channels != null, 'channels must not be null'),
        _channels = channels;

  List<Channel> get channels => _channels;
}
