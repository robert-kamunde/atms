import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/failure_messages.dart';
import '../../core/localization/l10n.dart';
import '../../core/services/offline_write.dart';

/// Shows a friendly, localized message for [failure]. Raw error text is
/// never shown.
void showFailureSnackBar(BuildContext context, AppFailure failure) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(content: Text(failureMessage(failure, context.l10n))),
  );
}

/// Shows a plain localized message.
void showMessageSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(message)));
}

/// Tells the user whether a change reached the server or is kept on the
/// phone until the connection returns (spec 4.9).
void showWriteOutcomeSnackBar(BuildContext context, WriteOutcome outcome) {
  final l10n = context.l10n;
  showMessageSnackBar(context, switch (outcome) {
    WriteOutcome.saved => l10n.savedMessage,
    WriteOutcome.savedOnPhone => l10n.savedOnPhoneMessage,
  });
}

/// Key of the app's root messenger, for messages that arrive when no
/// particular screen is waiting (e.g. an offline change refused later).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'rootMessenger');
