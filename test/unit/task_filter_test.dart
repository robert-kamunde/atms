import 'package:atms/features/tasks/domain/task_filter.dart';
import 'package:atms/shared/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/task_fixtures.dart';

void main() {
  group('TaskFilter', () {
    test('empty filter matches everything', () {
      expect(const TaskFilter().isEmpty, isTrue);
      expect(const TaskFilter().matches(taskFixture(), testNow), isTrue);
    });

    test('status, priority, assignee and department', () {
      final t = taskFixture(
        status: TaskStatus.blocked,
        priority: TaskPriority.low,
        assigneeIds: ['asha', 'baraka'],
        deptId: 'hr',
      );
      expect(
        const TaskFilter(status: TaskStatus.blocked).matches(t, testNow),
        isTrue,
      );
      expect(
        const TaskFilter(status: TaskStatus.todo).matches(t, testNow),
        isFalse,
      );
      expect(
        const TaskFilter(priority: TaskPriority.urgent).matches(t, testNow),
        isFalse,
      );
      expect(
        const TaskFilter(assigneeId: 'baraka').matches(t, testNow),
        isTrue,
      );
      expect(const TaskFilter(assigneeId: 'juma').matches(t, testNow), isFalse);
      expect(const TaskFilter(deptId: 'hr').matches(t, testNow), isTrue);
      expect(const TaskFilter(deptId: 'ict').matches(t, testNow), isFalse);
    });

    test('due dates: today, this week, overdue (open tasks only)', () {
      final now = testNow.toLocal();
      DateTime at(int days, int hour) =>
          DateTime(now.year, now.month, now.day + days, hour);
      final today = taskFixture(deadline: at(0, 23));
      final nextMonth = taskFixture(deadline: at(30, 9));
      final late = taskFixture(
        deadline: testNow.subtract(const Duration(hours: 1)),
      );
      final lateDone = taskFixture(
        deadline: testNow.subtract(const Duration(hours: 1)),
        status: TaskStatus.done,
      );
      const todayF = TaskFilter(due: DueFilter.today);
      const weekF = TaskFilter(due: DueFilter.thisWeek);
      const overdueF = TaskFilter(due: DueFilter.overdue);
      expect(todayF.matches(today, testNow), isTrue);
      expect(todayF.matches(nextMonth, testNow), isFalse);
      expect(weekF.matches(today, testNow), isTrue);
      expect(weekF.matches(nextMonth, testNow), isFalse);
      expect(overdueF.matches(late, testNow), isTrue);
      expect(overdueF.matches(lateDone, testNow), isFalse);
      expect(overdueF.matches(today, testNow), isFalse);
    });

    test('this week ends after Sunday', () {
      // 8 Oct 2026 is a Thursday.
      final range = deadlineRangeFor(DueFilter.thisWeek, testNow);
      expect(range.end!.weekday, DateTime.monday);
      expect(range.end!.difference(range.start!).inDays, 4);
    });

    test('query part keeps status, priority, department and due', () {
      const f = TaskFilter(
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        assigneeId: 'a',
        deptId: 'd',
        due: DueFilter.today,
      );
      expect(
        f.queryPart,
        const TaskFilter(
          status: TaskStatus.todo,
          priority: TaskPriority.high,
          deptId: 'd',
          due: DueFilter.today,
        ),
      );
      expect(f.hasPageFilters, isTrue);
      expect(f.queryPart.hasPageFilters, isFalse);
      expect(f.copyWith(assigneeId: () => null).hasPageFilters, isFalse);
      expect(const TaskFilter(deptId: 'd').hasPageFilters, isFalse);
    });
  });
}
