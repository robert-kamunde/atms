import 'package:atms/core/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content-bearing context keys are redacted', () {
    final records = <LogRecord>[];
    void listener(LogRecord r) => records.add(r);
    AppLogger.addListener(listener);
    addTearDown(() => AppLogger.removeListener(listener));

    AppLogger.info(
      'Task opened',
      context: {
        'taskId': 't1',
        'title': 'Disciplinary case: John',
        'Description': 'secret',
        'comment': 'secret',
      },
    );

    expect(records, hasLength(1));
    final ctx = records.single.context;
    expect(ctx['taskId'], 't1');
    expect(ctx['title'], AppLogger.redactedValue);
    expect(ctx['Description'], AppLogger.redactedValue);
    expect(ctx['comment'], AppLogger.redactedValue);
    expect(ctx.values.join(), isNot(contains('Disciplinary')));
  });
}
