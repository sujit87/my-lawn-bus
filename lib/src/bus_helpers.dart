import 'package:flutter/widgets.dart' show BuildContext, StreamBuilder, Widget;

import 'bus.dart';
import 'channel.dart';

/// A function that returns the [Bus] registered
/// either by type [B] or by name [busName].
typedef BusRegistry = B Function<B extends Bus>({String busName});

/// The global [BusRegistry], used by the helper functions.
BusRegistry globalBusRegistry;

Bus _bus<B extends Bus>(
  BusRegistry busRegistry,
  String busName,
) {
  assert(
    busRegistry != null || globalBusRegistry != null,
    'bus registry must not be null',
  );

  return (busRegistry ?? globalBusRegistry)<B>(busName: busName);
}

/// Returns the [Bus] registered either by type [B] or by name [busName].
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
B bus<B extends Bus>({
  BusRegistry busRegistry,
  String busName,
}) =>
    _bus<B>(
      busRegistry,
      busName,
    );

/// Returns a snapshot of the channel of type [C], optionally named
/// [channelName], on given [busInstance], or the [Bus] registered
/// either by type [B] or by name [busName].
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
///
/// Usage:
/// ```dart
/// var name = busSnapshot<LawnModel, LawnData>().lawnName;
/// ```
C busSnapshot<B extends Bus, C>({
  B busInstance,
  BusRegistry busRegistry,
  String busName,
  String channelName,
}) =>
    busInstance ??
    _bus<B>(
      busRegistry,
      busName,
    ).snapshot<C>(name: channelName);

/// Returns snapshots of all channels, or the specified [channels],
/// on given [busInstance], or the [Bus] registered either by
/// type [B] or by name [busName].
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
///
/// Usage:
/// The [Bus] i.e. [Model] that is used should contain at least two channels
/// in order to be useful.
/// ```dart
/// var data = busSnapshots<LawnModel>()[Channel(LawnData)] as LawnData;
/// print(data.lawnName);
/// ```
Map<Channel, dynamic> busSnapshots<B extends Bus>({
  B busInstance,
  BusRegistry busRegistry,
  String busName,
  List<Channel> channels,
}) =>
    busInstance ??
    _bus<B>(
      busRegistry,
      busName,
    ).snapshots(
      snapshotChannels: channels,
    );

/// Returns a stream of the channel of type [C], optionally named
/// [channelName], on given [busInstance], or the [Bus] registered
/// either by type [B] or by name [busName].
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
///
/// Usage:
/// ```dart
/// busStream<LawnModel, LawnData>().listen((lawnData) {
///   setState(() {
///     _lawnName = lawnData.lawnName ?? 'My Lawn';
///   });
/// });
/// ```
Stream<C> busStream<B extends Bus, C>({
  B busInstance,
  BusRegistry busRegistry,
  String busName,
  String channelName,
}) =>
    busInstance ??
    _bus<B>(
      busRegistry,
      busName,
    ).stream<C>(name: channelName);

/// Returns streams of all channels, or the specified [channels],
/// on given [busInstance], or the [Bus] registered either by
/// type [B] or by name [busName].
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
///
///
/// Usage:
/// The [Bus] i.e. [Model] that is used should contain at least two channels
/// in order to be useful.
/// ```dart
/// busStreams<LawnSizeZipeCodeModel>().listen((data) {
///   print(data);
/// });
/// ```
///
/// From `LawnSizeZipeCodeModel`:
/// ```dart
/// @override
/// List<Channel> get channels => [
///   Channel(LawnSizeZipCodeData),
///   Channel(LawnSizeZipCodeFormError),
/// ];
/// ```
Stream<dynamic> busStreams<B extends Bus>({
  B busInstance,
  BusRegistry busRegistry,
  String busName,
  List<Channel> channels,
}) =>
    busInstance ??
    _bus<B>(
      busRegistry,
      busName,
    ).streams(
      streamChannels: channels,
    );

/// Publishes data to channel of type [C], optionally named [channelName],
/// on given [busInstance], or the [Bus] registered either by type [B] or
/// by name [busName].
///
/// Pass [data] directly, or via a [publisher] function. The publisher
/// receives a snapshot of the channel and returns the data to be published.
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
///
///
/// Usage:
/// This updates property [lawnName] in the LawnModel.
/// ```dart
/// busPublish<LawnModel, LawnData>(
///   data: LawnData(lawnName: modifiedName),
/// );
/// ```
void busPublish<B extends Bus, C>({
  B busInstance,
  BusRegistry busRegistry,
  String busName,
  String channelName,
  C data,
  C Function(C snapshot) publisher,
}) =>
    busInstance ??
    _bus<B>(
      busRegistry,
      busName,
    ).publish<C>(
      name: channelName,
      publisher: publisher,
      data: data,
    );

/// A builder function used with [busStreamBuilder] and [busStreamsBuilder].
typedef BusChannelDataBuilder<B extends Bus, T> = Widget Function(
    BuildContext context, B bus, T data);

/// Returns a [StreamBuilder] for the channel of type [C], optionally named
/// [channelName], on given [busInstance], or the [Bus] registered either
/// by type [B] or by name [busName].
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
///
/// Usage:
/// ```dart
/// return busStreamBuilder<LawnModel, LawnData>(
///   builder: (context, model, _lawnData) {
///     return Row(
///       children: <Widget>[
///         Text('${_lawnData.lawnName}'),
///       ],
///     );
///   },
/// );
/// ```
/// If a screen needs to present data from a stream [busStreamBuilder] can be
/// used as a stream builder (similar to Provider, BLoC and other state
/// management solutions) to build [Widgets] with reactive data.
StreamBuilder<C> busStreamBuilder<B extends Bus, C>({
  B busInstance,
  BusRegistry busRegistry,
  String busName,
  String channelName,
  BusChannelDataBuilder<B, C> builder,
}) {
  assert(builder != null, 'builder must not be null.');

  final bus = busInstance ??
      _bus<B>(
        busRegistry,
        busName,
      );

  return StreamBuilder<C>(
    initialData: bus.snapshot<C>(name: channelName),
    stream: bus.stream<C>(name: channelName),
    builder: (context, snapshot) {
      return builder(
        context,
        bus,
        snapshot.data,
      );
    },
  );
}

/// Returns a [StreamBuilder] for all channels,
/// or the specified [channels], on given [busInstance],
/// or the [Bus] registered either by type [B] or by name [busName].
///
/// If [busRegistry] is not specified, then [globalBusRegistry] is used.
///
/// Usage:
/// The [Bus] i.e. [Model] that is used should contain at least two channels
/// in order to be useful.
/// ```dart
/// return busStreamsBuilder<LawnSizeZipCodeModel>(
///   busInstance: _model,
///   builder: (context, model, data) {
///     final formError = data[Channel(LawnSizeZipCodeFormError)]
///         as LawnSizeZipCodeFormError;
///     final formData =
///         data[Channel(LawnSizeZipCodeData)] as LawnSizeZipCodeData;
///     return Text('CONTINUE');
///   },
/// );
/// ```
///
/// From `LawnSizeZipeCodeModel`:
/// ```dart
/// @override
/// List<Channel> get channels => [
///   Channel(LawnSizeZipCodeData),
///   Channel(LawnSizeZipCodeFormError),
/// ];
/// ```
StreamBuilder<Map<Channel, dynamic>> busStreamsBuilder<B extends Bus>({
  B busInstance,
  BusRegistry busRegistry,
  String busName,
  List<Channel> channels,
  BusChannelDataBuilder<B, Map<Channel, dynamic>> builder,
}) {
  assert(builder != null, 'builder must not be null.');

  final bus = busInstance ??
      _bus<B>(
        busRegistry,
        busName,
      );
  return StreamBuilder<Map<Channel, dynamic>>(
      initialData: bus.snapshots(
        snapshotChannels: channels,
      ),
      stream: bus.streams(
        streamChannels: channels,
      ),
      builder: (context, snapshot) {
        return builder(
          context,
          bus,
          snapshot.data,
        );
      });
}
