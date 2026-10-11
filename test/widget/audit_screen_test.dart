import 'package:atms/features/audit/presentation/audit_screen.dart';
import 'package:atms/features/audit/presentation/widgets/activity_tile.dart';
import 'package:atms/shared/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';
import '../helpers/task_fixtures.dart';

final _admin = personFixture('neema', 'Neema', role: UserRole.admin);
final _asha = personFixture('asha', 'Asha');

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedPeople(db, [_admin, _asha]);
  });

  for (final locale in testLocales) {
    group('AuditScreen [$locale]', () {
      final l10n = l10nFor(locale);

      testWidgets('empty log', (tester) async {
        await pumpLocalized(
          tester,
          const AuditScreen(),
          locale: locale,
          overrides: taskScreenOverrides(_admin, db, adminVerified: true),
        );
        expect(find.text(l10n.adminAuditTitle), findsOneWidget);
        expect(find.text(l10n.auditEmptyTitle), findsOneWidget);
      });

      testWidgets('non-confidential entries, newest first', (tester) async {
        await seedAudit(db, 'old', {
          'taskId': null,
          'actorId': 'neema',
          'action': 'user_added',
          'at': Timestamp.fromDate(testNow.subtract(const Duration(days: 1))),
          'viewerIds': [],
          'confidential': false,
        });
        await seedAudit(db, 'new', {
          'taskId': 't1',
          'actorId': 'asha',
          'action': 'task_cancelled',
          'after': {'cancelReason': 'Duplicate'},
          'at': Timestamp.fromDate(testNow),
          'viewerIds': ['asha'],
          'confidential': false,
        });
        await seedAudit(db, 'secret', {
          'taskId': 't2',
          'actorId': 'asha',
          'action': 'task_created',
          'at': Timestamp.fromDate(testNow),
          'viewerIds': ['asha'],
          'confidential': true,
        });
        await pumpLocalized(
          tester,
          const AuditScreen(),
          locale: locale,
          overrides: taskScreenOverrides(_admin, db, adminVerified: true),
        );
        final cancelled = find.text(
          l10n.activityCancelled('Asha', 'Duplicate'),
        );
        final added = find.text(l10n.activityUserAdded('Neema'));
        expect(cancelled, findsOneWidget);
        expect(added, findsOneWidget);
        expect(find.text(l10n.activityCreated('Asha')), findsNothing);
        expect(
          tester.getTopLeft(cancelled).dy,
          lessThan(tester.getTopLeft(added).dy),
        );
      });
    });
  }

  group('activityText', () {
    final en = l10nFor(testLocales.first);
    final people = {'asha': _asha, 'neema': _admin};

    AuditEntry entry(
      String action, {
      String actor = 'asha',
      Map<String, Object?> before = const {},
      Map<String, Object?> after = const {},
    }) => AuditEntry(
      id: 'e',
      action: AuditAction.parse(action),
      actorId: actor,
      before: before,
      after: after,
    );

    test('every action reads as a sentence with the actor', () {
      for (final action in AuditAction.values) {
        final text = activityText(entry(action.firestoreValue), people, en);
        expect(text, isNotEmpty, reason: action.name);
        expect(text, isNot(contains('_')), reason: action.name);
      }
    });

    test('reassigned names the new people; edited lists the fields', () {
      expect(
        activityText(
          entry(
            'task_reassigned',
            actor: 'neema',
            after: {
              'assigneeIds': ['asha'],
            },
          ),
          people,
          en,
        ),
        en.activityReassigned('Neema', 'Asha'),
      );
      expect(
        activityText(
          entry('task_edited', after: {'title': 'x', 'priority': 'urgent'}),
          people,
          en,
        ),
        en.activityEdited(
          'Asha',
          '${en.taskFieldTitle}, ${en.activityPriorityValue(en.priorityUrgent)}',
        ),
      );
    });

    test('rejected assignment explains why; system actor is named', () {
      expect(
        activityText(
          entry(
            'task_rejected',
            actor: '',
            after: {'assignmentError': 'assignee-inactive'},
          ),
          people,
          en,
        ),
        en.activityRejected(en.errorAssigneeInactive),
      );
      expect(
        activityText(entry('task_created', actor: ''), people, en),
        en.activityCreated(en.activitySystemActor),
      );
      expect(
        activityText(entry('task_created', actor: 'nobody'), people, en),
        en.activityCreated(en.unknownPerson),
      );
    });

    test('deadline change shows both dates', () {
      final text = activityText(
        entry(
          'deadline_changed',
          before: {'deadline': Timestamp.fromDate(testNow)},
          after: {
            'deadline': Timestamp.fromDate(
              testNow.add(const Duration(days: 1)),
            ),
          },
        ),
        people,
        en,
      );
      expect(text, startsWith('Asha changed the deadline from '));
    });
  });
}
