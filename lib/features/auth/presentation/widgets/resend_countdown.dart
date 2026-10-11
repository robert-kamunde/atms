import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/l10n.dart';

/// "Send the code again" button that unlocks [delay] after [sentAt] and
/// shows the seconds left until then.
class ResendCountdown extends StatefulWidget {
  const ResendCountdown({
    super.key,
    required this.sentAt,
    required this.now,
    required this.onResend,
    this.enabled = true,
    this.delay = AppConstants.resendCodeDelay,
  });

  final DateTime sentAt;
  final DateTime Function() now;
  final VoidCallback onResend;
  final bool enabled;
  final Duration delay;

  @override
  State<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends State<ResendCountdown> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    final elapsed = widget.now().difference(widget.sentAt);
    _secondsLeft = (widget.delay - elapsed).inSeconds.clamp(
      0,
      widget.delay.inSeconds,
    );
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final waiting = _secondsLeft > 0;
    return TextButton(
      key: const Key('resendCodeButton'),
      onPressed: waiting || !widget.enabled ? null : widget.onResend,
      child: Text(
        waiting ? l10n.resendCodeIn(_secondsLeft) : l10n.actionResendCode,
      ),
    );
  }
}
