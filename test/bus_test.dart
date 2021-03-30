import 'package:test/test.dart';

import 'package:bus/bus.dart';

// https://github.com/dart-lang/sdk/issues/39305
final Matcher throwsAssertionError = throwsA(isA<AssertionError>());
final Matcher throwsArgumentError = throwsA(isA<ArgumentError>());
final Matcher throwsStateError = throwsA(isA<StateError>());

class NullBus with Bus {
  @override
  List<Channel> get channels => null;

  var inits = 0;
  var destroys = 0;

  @override
  void onInit() {
    inits++;
  }

  @override
  void onDestroy() {
    destroys++;
  }
}

class EmptyBus with Bus {
  @override
  List<Channel> get channels => [];

  var inits = 0;
  var destroys = 0;

  @override
  void onInit() {
    inits++;
  }

  @override
  void onDestroy() {
    destroys++;
  }
}

class StringIntBus with Bus {
  @override
  List<Channel> get channels => [Channel(String), Channel(int)];

  var inits = 0;
  var destroys = 0;

  @override
  void onInit() {
    inits++;
  }

  @override
  void onDestroy() {
    destroys++;
  }
}

class StringStringBus with Bus {
  @override
  List<Channel> get channels => [
        Channel(String, name: 'ChannelA'),
        Channel(String, name: 'ChannelB'),
      ];

  var inits = 0;
  var destroys = 0;

  @override
  void onInit() {
    inits++;
  }

  @override
  void onDestroy() {
    destroys++;
  }
}

class Foo extends Object {}

void main() {
  group('constructors', () {
    test('factory constructor', () {
      expect(
        () => Bus(),
        throwsAssertionError,
      );

      final busA =
          Bus(channels: [Channel(String), Channel(int), Channel(double)]);
      expect(
        busA.channels,
        equals([Channel(String), Channel(int), Channel(double)]),
      );

      final busB = Bus(channels: [
        Channel(String, name: 'A'),
        Channel(int, name: 'B'),
        Channel(String, name: 'C'),
      ]);
      expect(
        busB.channels,
        equals([
          Channel(String, name: 'A'),
          Channel(int, name: 'B'),
          Channel(String, name: 'C'),
        ]),
      );
    });
  });
  group('getters', () {
    test('state, isInitialized', () {
      final nullBus = NullBus();
      final emptyBus = EmptyBus();
      final stringIntBus = StringIntBus();
      final stringStringBus = StringStringBus();
      final doubleBus = Bus(channels: [Channel(double)]);

      expect(nullBus.isInitialized, isFalse);
      expect(emptyBus.isInitialized, isFalse);
      expect(stringIntBus.isInitialized, isFalse);
      expect(stringStringBus.isInitialized, isFalse);
      expect(doubleBus.isInitialized, isFalse);

      nullBus.destroy();
      emptyBus.destroy();
      stringIntBus.destroy();
      stringStringBus.destroy();
      doubleBus.destroy();

      expect(nullBus.isInitialized, isFalse);
      expect(emptyBus.isInitialized, isFalse);
      expect(stringIntBus.isInitialized, isFalse);
      expect(stringStringBus.isInitialized, isFalse);
      expect(doubleBus.isInitialized, isFalse);

      nullBus.init();
      emptyBus.init();
      stringIntBus.init();
      stringStringBus.init();
      doubleBus.init();

      expect(nullBus.isInitialized, isTrue);
      expect(emptyBus.isInitialized, isTrue);
      expect(stringIntBus.isInitialized, isTrue);
      expect(stringStringBus.isInitialized, isTrue);
      expect(doubleBus.isInitialized, isTrue);

      nullBus.destroy();
      emptyBus.destroy();
      stringIntBus.destroy();
      stringStringBus.destroy();
      doubleBus.destroy();

      expect(nullBus.isInitialized, isFalse);
      expect(emptyBus.isInitialized, isFalse);
      expect(stringIntBus.isInitialized, isFalse);
      expect(stringStringBus.isInitialized, isFalse);
      expect(doubleBus.isInitialized, isFalse);
    });
  });
  group('methods', () {
    test('init(), destroy()', () {
      final stringIntBusA = StringIntBus();

      expect(stringIntBusA.inits, equals(0));
      expect(stringIntBusA.destroys, equals(0));

      stringIntBusA.destroy();

      expect(stringIntBusA.inits, equals(0));
      expect(stringIntBusA.destroys, equals(0));

      stringIntBusA.init();
      stringIntBusA.init();

      expect(stringIntBusA.inits, equals(1));
      expect(stringIntBusA.destroys, equals(0));

      stringIntBusA.publish<String>(data: 'string');
      stringIntBusA.publish<int>(data: 5);

      expect(stringIntBusA.snapshot<String>(), equals('string'));
      expect(stringIntBusA.snapshot<int>(), equals(5));

      stringIntBusA.destroy();
      stringIntBusA.destroy();

      expect(stringIntBusA.inits, equals(1));
      expect(stringIntBusA.destroys, equals(1));
      expect(() => stringIntBusA.init(), throwsStateError);

      expect(() => stringIntBusA.snapshot<String>(), throwsStateError);
      expect(() => stringIntBusA.snapshot<int>(), throwsStateError);

      expect(stringIntBusA.inits, equals(1));
      expect(stringIntBusA.destroys, equals(1));

      final stringIntBusB = StringIntBus();

      expect(stringIntBusB.inits, equals(0));
      expect(stringIntBusB.destroys, equals(0));

      stringIntBusB.destroy();

      expect(stringIntBusB.inits, equals(0));
      expect(stringIntBusB.destroys, equals(0));

      // Implicit init().
      stringIntBusB.publish<String>(data: 'stringB');
      stringIntBusB.publish<int>(data: 6);

      expect(stringIntBusB.inits, equals(1));
      expect(stringIntBusB.destroys, equals(0));

      expect(stringIntBusB.snapshot<String>(), equals('stringB'));
      expect(stringIntBusB.snapshot<int>(), equals(6));

      stringIntBusB.destroy();

      expect(stringIntBusB.inits, equals(1));
      expect(stringIntBusB.destroys, equals(1));

      final doubleBusA = Bus(channels: [Channel(double)]);

      doubleBusA.destroy();

      doubleBusA.init();
      doubleBusA.init();

      doubleBusA.publish<double>(data: 5.0);

      expect(doubleBusA.snapshot<double>(), equals(5.0));

      doubleBusA.destroy();
      doubleBusA.destroy();
      expect(() => doubleBusA.init(), throwsStateError);

      expect(() => doubleBusA.snapshot<double>(), throwsStateError);

      final doubleBusB = Bus(channels: [Channel(double)]);

      doubleBusB.destroy();

      // Implicit init().
      doubleBusB.publish<double>(data: 6.0);

      expect(doubleBusB.snapshot<double>(), equals(6.0));

      final stringStringBusA = StringStringBus();

      expect(stringStringBusA.inits, equals(0));
      expect(stringStringBusA.destroys, equals(0));

      stringStringBusA.destroy();

      expect(stringStringBusA.inits, equals(0));
      expect(stringStringBusA.destroys, equals(0));

      stringStringBusA.init();
      stringStringBusA.init();

      expect(stringStringBusA.inits, equals(1));
      expect(stringStringBusA.destroys, equals(0));

      stringStringBusA.publish<String>(name: 'ChannelA', data: 'stringA');
      stringStringBusA.publish<String>(name: 'ChannelB', data: 'stringB');

      expect(stringStringBusA.snapshot<String>(name: 'ChannelA'),
          equals('stringA'));
      expect(stringStringBusA.snapshot<String>(name: 'ChannelB'),
          equals('stringB'));

      stringStringBusA.destroy();
      stringStringBusA.destroy();

      expect(stringStringBusA.inits, equals(1));
      expect(stringStringBusA.destroys, equals(1));
      expect(() => stringStringBusA.init(), throwsStateError);

      expect(() => stringStringBusA.snapshot<String>(name: 'ChannelA'),
          throwsStateError);
      expect(() => stringStringBusA.snapshot<String>(name: 'ChannelB'),
          throwsStateError);

      expect(stringStringBusA.inits, equals(1));
      expect(stringStringBusA.destroys, equals(1));

      final stringStringBusB = StringStringBus();

      expect(stringStringBusB.inits, equals(0));
      expect(stringStringBusB.destroys, equals(0));

      stringStringBusB.destroy();

      expect(stringStringBusB.inits, equals(0));
      expect(stringStringBusB.destroys, equals(0));

      // Implicit init().
      stringStringBusB.publish<String>(name: 'ChannelA', data: 'stringA');
      stringStringBusB.publish<String>(name: 'ChannelB', data: 'stringA');

      expect(stringStringBusB.inits, equals(1));
      expect(stringStringBusB.destroys, equals(0));

      expect(stringStringBusB.snapshot<String>(name: 'ChannelA'),
          equals('stringA'));
      expect(stringStringBusB.snapshot<String>(name: 'ChannelB'),
          equals('stringA'));

      stringStringBusB.destroy();

      expect(stringStringBusB.inits, equals(1));
      expect(stringStringBusB.destroys, equals(1));
    });

    test('publish(), snapshot(), stream()', () {
      final stringIntBus = StringIntBus();

      expect(
        () => stringIntBus.publish(publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.publish<Object>(publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.publish<dynamic>(publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.publish<Object>(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.publish<dynamic>(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.publish(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.publish(data: Object()),
        throwsAssertionError,
      );

      expect(
        () => stringIntBus.publish<bool>(data: true),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.snapshot<bool>(),
        throwsAssertionError,
      );

      expect(
        () => stringIntBus.stream<bool>(),
        throwsAssertionError,
      );

      expect(
        () => stringIntBus.publish(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.publish(data: Foo()),
        throwsAssertionError,
      );
      expect(
        () => stringIntBus.snapshot(),
        throwsAssertionError,
      );

      expect(
        () => stringIntBus.stream(),
        throwsAssertionError,
      );

      stringIntBus.publish<String>(data: 'string');
      stringIntBus.publish<int>(data: 5);

      expect(stringIntBus.snapshot<String>(), equals('string'));
      expect(stringIntBus.snapshot<int>(), equals(5));

      stringIntBus.stream<String>().take(3).toList().then((list) => expect(
            list,
            equals(['string', 'stringB', 'stringC']),
          ));

      stringIntBus.stream<int>().take(3).toList().then((list) => expect(
            list,
            equals([5, 6, 7]),
          ));

      stringIntBus.publish<String>(data: 'stringB');
      stringIntBus.publish<int>(data: 6);
      stringIntBus.publish<String>(data: 'stringC');
      stringIntBus.publish<int>(data: 7);

      stringIntBus.publish(data: 'stringD');
      stringIntBus.publish(data: 8);

      expect(stringIntBus.snapshot<String>(), equals('stringD'));
      expect(stringIntBus.snapshot<int>(), equals(8));

      final stringStringBus = StringStringBus();

      expect(
        () => stringStringBus.publish(
            name: 'ChannelA', publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.publish<Object>(
            name: 'ChannelA', publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.publish<dynamic>(
            name: 'ChannelA', publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.publish<Object>(name: 'ChannelA', data: Object()),
        throwsAssertionError,
      );
      expect(
        () =>
            stringStringBus.publish<dynamic>(name: 'ChannelA', data: Object()),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.publish(name: 'ChannelA', data: Object()),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.publish(name: 'ChannelA', data: Object()),
        throwsAssertionError,
      );

      expect(
        () => stringStringBus.publish<bool>(name: 'ChannelA', data: true),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.snapshot<bool>(name: 'ChannelA'),
        throwsAssertionError,
      );

      expect(
        () => stringStringBus.stream<bool>(name: 'ChannelA'),
        throwsAssertionError,
      );

      expect(
        () => stringStringBus.publish(name: 'ChannelA', data: Object()),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.publish(name: 'ChannelA', data: Foo()),
        throwsAssertionError,
      );
      expect(
        () => stringStringBus.snapshot(name: 'ChannelA'),
        throwsAssertionError,
      );

      expect(
        () => stringStringBus.stream(name: 'ChannelA'),
        throwsAssertionError,
      );

      stringStringBus.publish<String>(name: 'ChannelA', data: 'stringA1');
      stringStringBus.publish<String>(name: 'ChannelB', data: 'stringB1');

      expect(stringStringBus.snapshot<String>(name: 'ChannelA'),
          equals('stringA1'));
      expect(stringStringBus.snapshot<String>(name: 'ChannelB'),
          equals('stringB1'));

      stringStringBus
          .stream<String>(name: 'ChannelA')
          .take(3)
          .toList()
          .then((list) => expect(
                list,
                equals(['stringA1', 'stringA2', 'stringA3']),
              ));

      stringStringBus
          .stream<String>(name: 'ChannelB')
          .take(3)
          .toList()
          .then((list) => expect(
                list,
                equals(['stringB1', 'stringB2', 'stringB3']),
              ));

      stringStringBus.publish<String>(name: 'ChannelA', data: 'stringA2');
      stringStringBus.publish<String>(name: 'ChannelB', data: 'stringB2');
      stringStringBus.publish<String>(name: 'ChannelA', data: 'stringA3');
      stringStringBus.publish<String>(name: 'ChannelB', data: 'stringB3');

      stringStringBus.publish(name: 'ChannelA', data: 'stringA4');
      stringStringBus.publish(name: 'ChannelB', data: 'stringB4');

      expect(stringStringBus.snapshot<String>(name: 'ChannelA'),
          equals('stringA4'));
      expect(stringStringBus.snapshot<String>(name: 'ChannelB'),
          equals('stringB4'));

      final doubleBus = Bus(channels: [Channel(double)]);

      expect(
        () => doubleBus.publish(publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.publish<Object>(publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.publish<dynamic>(publisher: (snapshot) => Object()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.publish<Object>(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.publish<dynamic>(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.publish(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.publish(data: Object()),
        throwsAssertionError,
      );

      expect(
        () => doubleBus.publish<int>(data: 5),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.snapshot<int>(),
        throwsAssertionError,
      );

      expect(
        () => doubleBus.stream<int>(),
        throwsAssertionError,
      );

      expect(
        () => doubleBus.publish(data: Object()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.publish(data: Foo()),
        throwsAssertionError,
      );
      expect(
        () => doubleBus.snapshot(),
        throwsAssertionError,
      );

      expect(
        () => doubleBus.stream(),
        throwsAssertionError,
      );

      doubleBus.publish<double>(data: 5.0);

      expect(doubleBus.snapshot<double>(), equals(5.0));

      doubleBus.stream<double>().take(3).toList().then((list) => expect(
            list,
            equals([5.0, 6.0, 7.0]),
          ));

      doubleBus.publish<double>(data: 6.0);
      doubleBus.publish<double>(data: 7.0);
      doubleBus.publish(data: 8.0);

      expect(doubleBus.snapshot<double>(), equals(8.0));
    });
    test('snapshots(), streams()', () {
      final stringIntBus = StringIntBus();

      stringIntBus.publish<String>(data: 'string');
      stringIntBus.publish<int>(data: 5);

      expect(stringIntBus.snapshots(),
          equals({Channel(String): 'string', Channel(int): 5}));
      expect(stringIntBus.snapshots(snapshotChannels: [Channel(String)]),
          equals({Channel(String): 'string'}));
      expect(stringIntBus.snapshots(snapshotChannels: [Channel(int)]),
          equals({Channel(int): 5}));

      stringIntBus.streams().take(5).toList().then((list) => expect(
            list,
            equals([
              {Channel(String): 'string', Channel(int): 5},
              {Channel(String): 'stringB', Channel(int): 5},
              {Channel(String): 'stringB', Channel(int): 6},
              {Channel(String): 'stringC', Channel(int): 6},
              {Channel(String): 'stringC', Channel(int): 7},
            ]),
          ));
      stringIntBus
          .streams(streamChannels: [Channel(String)])
          .take(5)
          .toList()
          .then((list) => expect(
                list,
                equals([
                  {Channel(String): 'string'},
                  {Channel(String): 'stringB'},
                  {Channel(String): 'stringB'},
                  {Channel(String): 'stringC'},
                  {Channel(String): 'stringC'},
                ]),
              ));
      stringIntBus
          .streams(streamChannels: [Channel(int)])
          .take(5)
          .toList()
          .then((list) => expect(
                list,
                equals([
                  {Channel(int): 5},
                  {Channel(int): 5},
                  {Channel(int): 6},
                  {Channel(int): 6},
                  {Channel(int): 7},
                ]),
              ));

      stringIntBus.publish<String>(data: 'stringB');
      stringIntBus.publish<int>(data: 6);
      stringIntBus.publish<String>(data: 'stringC');
      stringIntBus.publish<int>(data: 7);

      final boolDoubleBus = Bus(channels: [Channel(bool), Channel(double)]);

      boolDoubleBus.publish<bool>(data: false);
      boolDoubleBus.publish<double>(data: 5.0);

      expect(boolDoubleBus.snapshots(),
          equals({Channel(double): 5.0, Channel(bool): false}));
      expect(boolDoubleBus.snapshots(snapshotChannels: [Channel(bool)]),
          equals({Channel(bool): false}));
      expect(boolDoubleBus.snapshots(snapshotChannels: [Channel(double)]),
          equals({Channel(double): 5.0}));

      boolDoubleBus.streams().take(5).toList().then((list) => expect(
            list,
            equals([
              {Channel(bool): false, Channel(double): 5.0},
              {Channel(bool): true, Channel(double): 5.0},
              {Channel(bool): true, Channel(double): 6.0},
              {Channel(bool): false, Channel(double): 6.0},
              {Channel(bool): false, Channel(double): 7.0},
            ]),
          ));
      boolDoubleBus
          .streams(streamChannels: [Channel(bool)])
          .take(5)
          .toList()
          .then((list) => expect(
                list,
                equals([
                  {Channel(bool): false},
                  {Channel(bool): true},
                  {Channel(bool): true},
                  {Channel(bool): false},
                  {Channel(bool): false},
                ]),
              ));
      boolDoubleBus
          .streams(streamChannels: [Channel(double)])
          .take(5)
          .toList()
          .then((list) => expect(
                list,
                equals([
                  {Channel(double): 5.0},
                  {Channel(double): 5.0},
                  {Channel(double): 6.0},
                  {Channel(double): 6.0},
                  {Channel(double): 7.0},
                ]),
              ));

      boolDoubleBus.publish<bool>(data: true);
      boolDoubleBus.publish<double>(data: 6.0);
      boolDoubleBus.publish<bool>(data: false);
      boolDoubleBus.publish<double>(data: 7.0);

      final stringStringBus = StringStringBus();
      final channelA = Channel(String, name: 'ChannelA');
      final channelB = Channel(String, name: 'ChannelB');

      stringStringBus.publish<String>(name: 'ChannelA', data: 'stringA1');
      stringStringBus.publish<String>(name: 'ChannelB', data: 'stringB1');

      expect(stringStringBus.snapshots(),
          equals({channelA: 'stringA1', channelB: 'stringB1'}));
      expect(stringStringBus.snapshots(snapshotChannels: [channelA]),
          equals({channelA: 'stringA1'}));
      expect(stringStringBus.snapshots(snapshotChannels: [channelB]),
          equals({channelB: 'stringB1'}));

      stringStringBus.streams().take(5).toList().then((list) => expect(
            list,
            equals([
              {channelA: 'stringA1', channelB: 'stringB1'},
              {channelA: 'stringA2', channelB: 'stringB1'},
              {channelA: 'stringA2', channelB: 'stringB2'},
              {channelA: 'stringA3', channelB: 'stringB2'},
              {channelA: 'stringA3', channelB: 'stringB3'},
            ]),
          ));
      stringStringBus
          .streams(streamChannels: [channelA])
          .take(5)
          .toList()
          .then((list) => expect(
                list,
                equals([
                  {channelA: 'stringA1'},
                  {channelA: 'stringA1'},
                  {channelA: 'stringA2'},
                  {channelA: 'stringA2'},
                  {channelA: 'stringA3'},
                ]),
              ));
      stringStringBus
          .streams(streamChannels: [channelB])
          .take(5)
          .toList()
          .then((list) => expect(
                list,
                equals([
                  {channelB: 'stringB1'},
                  {channelB: 'stringB1'},
                  {channelB: 'stringB2'},
                  {channelB: 'stringB2'},
                  {channelB: 'stringB3'},
                ]),
              ));

      stringStringBus.publish<String>(name: 'ChannelA', data: 'stringA2');
      stringStringBus.publish<String>(name: 'ChannelB', data: 'stringB2');
      stringStringBus.publish<String>(name: 'ChannelA', data: 'stringA3');
      stringStringBus.publish<String>(name: 'ChannelB', data: 'stringB3');
    });
    test('toString()', () {
      expect(
        NullBus().toString(),
        equals('NullBus(null)'),
      );
      expect(
        EmptyBus().toString(),
        equals('EmptyBus([])'),
      );
      expect(
        StringIntBus().toString(),
        equals('StringIntBus([Channel(String), Channel(int)])'),
      );
      expect(
        StringStringBus().toString(),
        equals('StringStringBus('
            '[Channel(String, ChannelA), Channel(String, ChannelB)])'),
      );
      expect(
        Bus(channels: [Channel(double)]).toString(),
        equals('_Bus([Channel(double)])'),
      );
    });
  });
  group('operators', () {
    test('equality', () {
      expect(
        NullBus(),
        equals(NullBus()),
      );
      expect(
        EmptyBus(),
        equals(EmptyBus()),
      );
      expect(
        StringIntBus(),
        equals(StringIntBus()),
      );
      expect(
        StringStringBus(),
        equals(StringStringBus()),
      );
      expect(
        NullBus(),
        isNot(equals(EmptyBus())),
      );
      expect(
        EmptyBus(),
        isNot(equals(StringIntBus())),
      );
      expect(
        StringIntBus(),
        isNot(equals(Bus(channels: [Channel(String), Channel(int)]))),
      );
    });
  });
}
