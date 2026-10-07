import 'package:flutter/foundation.dart';

import 'enum_parsing.dart';
import 'firestore_converters.dart';
import 'transition_action.dart';

/// Processing state of a [TransitionRequest], filled by the server.
enum TransitionResultStatus {
  pending('pending'),
  applied('applied'),
  rejected('rejected');

  const TransitionResultStatus(this.firestoreValue);

  final String firestoreValue;

  static TransitionResultStatus fromFirestore(Object? raw) =>
      parseEnum(values, raw, (v) => v.firestoreValue, field: 'result.status');
}

/// The server's answer to a [TransitionRequest]. Written only by Cloud
/// Functions.
@immutable
class TransitionResult {
  const TransitionResult({
    required this.status,
    this.reasonCode,
    this.rejectedBecauseActor,
    this.at,
  });

  factory TransitionResult.fromMap(Map<String, Object?> map) =>
      TransitionResult(
        status: TransitionResultStatus.fromFirestore(map['status']),
        reasonCode: FirestoreConverters.stringOrNull(map['reasonCode']),
        rejectedBecauseActor: FirestoreConverters.stringOrNull(
          map['rejectedBecauseActor'],
        ),
        at: FirestoreConverters.dateOrNull(map['at']),
      );

  final TransitionResultStatus status;

  /// Machine-readable reason, e.g. `already_moved`, `not_step_owner`.
  final String? reasonCode;

  /// Display name of whoever already moved the step (for the
  /// "already approved by Asha at 10:42" message).
  final String? rejectedBecauseActor;
  final DateTime? at;

  Map<String, Object?> toMap() => {
    'status': status.firestoreValue,
    'reasonCode': reasonCode,
    'rejectedBecauseActor': rejectedBecauseActor,
    'at': FirestoreConverters.timestampOrNull(at),
  };

  @override
  bool operator ==(Object other) =>
      other is TransitionResult &&
      other.status == status &&
      other.reasonCode == reasonCode &&
      other.rejectedBecauseActor == rejectedBecauseActor &&
      other.at == at;

  @override
  int get hashCode => Object.hash(status, reasonCode, rejectedBecauseActor, at);
}

/// A request to move a workflow task: `orgs/{org}/transitionRequests/{id}`.
///
/// The phone only *asks*; a Cloud Function validates and applies it
/// (spec 4.4). The client creates it with [toClientCreateMap] and never
/// writes [result].
@immutable
class TransitionRequest {
  const TransitionRequest({
    required this.id,
    required this.taskId,
    required this.fromStep,
    required this.action,
    required this.requestedBy,
    this.toStep,
    this.comment,
    this.result,
  });

  factory TransitionRequest.fromMap(String id, Map<String, Object?> map) {
    final rawResult = map['result'];
    return TransitionRequest(
      id: id,
      taskId: FirestoreConverters.string(map['taskId'], field: 'taskId'),
      fromStep:
          FirestoreConverters.intOrNull(map['fromStep']) ??
          (throw const FormatException('Missing fromStep')),
      action: TransitionAction.fromFirestore(map['action']),
      toStep: FirestoreConverters.intOrNull(map['toStep']),
      comment: FirestoreConverters.stringOrNull(map['comment']),
      requestedBy: FirestoreConverters.string(
        map['requestedBy'],
        field: 'requestedBy',
      ),
      result: rawResult is Map<String, Object?>
          ? TransitionResult.fromMap(rawResult)
          : null,
    );
  }

  static const Set<String> serverOnlyFields = {'result'};

  final String id;
  final String taskId;
  final int fromStep;
  final TransitionAction action;

  /// Target step, only for [TransitionAction.sendBack].
  final int? toStep;
  final String? comment;
  final String requestedBy;
  final TransitionResult? result;

  Map<String, Object?> toMap() => {
    'taskId': taskId,
    'fromStep': fromStep,
    'action': action.firestoreValue,
    'toStep': toStep,
    'comment': comment,
    'requestedBy': requestedBy,
    'result': result?.toMap(),
  };

  /// What the client sends. Never contains [result].
  Map<String, Object?> toClientCreateMap() => {
    'taskId': taskId,
    'fromStep': fromStep,
    'action': action.firestoreValue,
    'toStep': toStep,
    'comment': comment,
    'requestedBy': requestedBy,
  };

  @override
  bool operator ==(Object other) =>
      other is TransitionRequest &&
      other.id == id &&
      other.taskId == taskId &&
      other.fromStep == fromStep &&
      other.action == action &&
      other.toStep == toStep &&
      other.comment == comment &&
      other.requestedBy == requestedBy &&
      other.result == result;

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    fromStep,
    action,
    toStep,
    comment,
    requestedBy,
    result,
  );

  @override
  String toString() =>
      'TransitionRequest(id: $id, taskId: $taskId, action: ${action.name})';
}
