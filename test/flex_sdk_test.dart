import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_checkout_flutter/flex_checkout_flutter.dart';

void main() {
  group('FlexConfig.toMap', () {
    test('defaults customComponents to false when not specified', () {
      final map = const FlexConfig(clientId: 'test-id').toMap();
      expect(map['customComponents'], isFalse);
    });

    test('includes customComponents: true when set', () {
      final map = const FlexConfig(clientId: 'test-id', customComponents: true).toMap();
      expect(map['customComponents'], isTrue);
    });

    test('includes customComponents: false when explicitly set', () {
      final map = const FlexConfig(clientId: 'test-id', customComponents: false).toMap();
      expect(map['customComponents'], isFalse);
    });
  });

  group('FlexSDK.create', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('com.flex.checkout/methods');
    final List<MethodCall> calls = [];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('calls native initialize with clientId', () async {
      await FlexSDK.create(const FlexConfig(clientId: 'test-id'));
      expect(calls.first.method, equals('initialize'));
      expect((calls.first.arguments as Map)['clientId'], equals('test-id'));
    });

    test('passes customComponents: true to native initialize', () async {
      await FlexSDK.create(
        const FlexConfig(clientId: 'test-id', customComponents: true),
      );
      expect((calls.first.arguments as Map)['customComponents'], isTrue);
    });

    test('passes customComponents: false to native initialize', () async {
      await FlexSDK.create(
        const FlexConfig(clientId: 'test-id', customComponents: false),
      );
      expect((calls.first.arguments as Map)['customComponents'], isFalse);
    });

    test('passes full config with all fields to native initialize', () async {
      await FlexSDK.create(const FlexConfig(
        clientId: 'abc',
        environment: FlexEnvironment.qa,
        customComponents: true,
        developer: FlexDeveloperConfig(logs: true),
      ));
      final args = calls.first.arguments as Map;
      expect(args['clientId'], equals('abc'));
      expect(args['environment'], equals('qa'));
      expect(args['customComponents'], isTrue);
      expect(args['logs'], isTrue);
    });
  });
}
