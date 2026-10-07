import 'package:atms/core/config/app_config.dart';
import 'package:atms/core/config/bootstrap.dart';
import 'package:atms/core/config/emulator_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('environment parsing falls back to prod for unknown values', () {
    expect(AppEnvironment.parse('dev'), AppEnvironment.dev);
    expect(AppEnvironment.parse(' STAGING '), AppEnvironment.staging);
    expect(AppEnvironment.parse('prod'), AppEnvironment.prod);
    expect(AppEnvironment.parse('develop'), AppEnvironment.prod);
  });

  test('missing Firebase options means not configured', () {
    expect(AppConfig.unconfigured.isFirebaseConfigured, isFalse);
    // Tests run without --dart-define, so this must also be unconfigured.
    expect(AppConfig.fromEnvironment().isFirebaseConfigured, isFalse);
  });

  test('bootstrap without options does not throw or touch Firebase', () async {
    expect(
      await bootstrap(AppConfig.unconfigured),
      isA<BootstrapNotConfigured>(),
    );
  });

  test('complete options are recognised', () {
    const options = FirebaseClientOptions(
      apiKey: 'k',
      appId: 'a',
      messagingSenderId: 'm',
      projectId: 'p',
      storageBucket: '',
      iosBundleId: '',
    );
    expect(options.isComplete, isTrue);
    expect(options.toFirebaseOptions().storageBucket, isNull);
  });

  test('emulator host', () {
    expect(
      resolveEmulatorHost(
        override: '',
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      '10.0.2.2',
    );
    expect(
      resolveEmulatorHost(
        override: '',
        platform: TargetPlatform.iOS,
        isWeb: false,
      ),
      'localhost',
    );
    expect(
      resolveEmulatorHost(
        override: '192.168.1.5',
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      '192.168.1.5',
    );
    expect(EmulatorPorts.auth, 9099);
    expect(EmulatorPorts.firestore, 8080);
    expect(EmulatorPorts.functions, 5001);
    expect(EmulatorPorts.storage, 9199);
  });
}
