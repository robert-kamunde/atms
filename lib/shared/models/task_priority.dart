import 'enum_parsing.dart';

enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const TaskPriority(this.firestoreValue);

  final String firestoreValue;

  static TaskPriority fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'priority');
}
