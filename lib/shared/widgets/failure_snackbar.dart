import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/failure_messages.dart';
import '../../core/localization/l10n.dart';

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
