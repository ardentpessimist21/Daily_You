// Copyright (C) 2026 Demizo and contributors
// SPDX-License-Identifier: GPL-3.0-only
// Additional terms under GPLv3 section 7 apply; see ADDITIONAL_TERMS.md.

import 'package:daily_you/config_provider.dart';
import 'package:daily_you/device_info_service.dart';
import 'package:daily_you/fork/links.dart';
import 'package:daily_you/l10n/generated/app_localizations.dart';
import 'package:daily_you/utils/password_store.dart';
import 'package:daily_you/widgets/app_dialog.dart';
import 'package:daily_you/widgets/auth_popup.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart';

/// "Forgot password?": reset with fingerprint or a one-time recovery code.
class PasswordRecovery {
  /// Whether fingerprint can be used to reset the password.
  static bool get canUseFingerprint =>
      ConfigProvider.instance.get(Settings.biometricUnlock) &&
      (DeviceInfoService().supportsBiometrics ?? false);

  /// Makes a new recovery code and shows it once.
  static Future<void> makeNewCode(BuildContext context) async {
    final code = await RecoveryCodeStore.generate();
    if (!context.mounted) return;
    await showRecoveryCode(context, code);
  }

  /// The forgot-password steps from the unlock screen. True once a new
  /// password is set, which also unlocks the app.
  static Future<bool> forgot(BuildContext context) async {
    final method = await showAppDialog<_Method>(
      context: context,
      builder: (context) => const _ChooseMethodDialog(),
    );
    if (method == null || !context.mounted) return false;

    final bool verified;
    if (method == _Method.fingerprint) {
      verified = await _verifyFingerprint(context);
    } else {
      verified = await showAppDialog<bool>(
              context: context,
              builder: (context) => const _EnterCodeDialog()) ??
          false;
    }
    if (!verified || !context.mounted) return false;

    var saved = false;
    await showAppDialog(
      context: context,
      builder: (context) => AuthPopup(
        mode: AuthPopupMode.setPassword,
        title: AppLocalizations.of(context)!.forgotPasswordNewPassword,
        showBiometrics: false,
        dismissable: true,
        onSuccess: (_) => saved = true,
      ),
    );
    if (!saved) return false;
    // A used code is spent; the new one is shown right away.
    await RecoveryCodeStore.clear();
    if (context.mounted) await makeNewCode(context);
    return true;
  }

  static Future<bool> _verifyFingerprint(BuildContext context) async {
    try {
      return await LocalAuthentication().authenticate(
        persistAcrossBackgrounding: false,
        biometricOnly: true,
        localizedReason: AppLocalizations.of(context)!.forgotPasswordTitle,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}

enum _Method { fingerprint, code }

class _ChooseMethodDialog extends StatelessWidget {
  const _ChooseMethodDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fingerprint = PasswordRecovery.canUseFingerprint;
    final code = RecoveryCodeStore.hasCode;
    return AlertDialog(
      title: Text(l10n.forgotPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!fingerprint && !code)
            Text(l10n.forgotPasswordNoWay)
          else ...[
            if (fingerprint)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fingerprint_rounded),
                title: Text(l10n.forgotPasswordUseFingerprint),
                onTap: () => Navigator.pop(context, _Method.fingerprint),
              ),
            if (code)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.password_rounded),
                title: Text(l10n.forgotPasswordUseCode),
                onTap: () => Navigator.pop(context, _Method.code),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

class _EnterCodeDialog extends StatefulWidget {
  const _EnterCodeDialog();

  @override
  State<_EnterCodeDialog> createState() => _EnterCodeDialogState();
}

class _EnterCodeDialogState extends State<_EnterCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _checking = false;
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _wrong = false;
    });
    final ok = await RecoveryCodeStore.validate(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _checking = false;
        _wrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.forgotPasswordUseCode),
      content: TextField(
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _check(),
        style: const TextStyle(letterSpacing: 1.5),
        decoration: InputDecoration(
          labelText: l10n.recoveryCodeLabel,
          hintText: 'K7M2-9XQ4-T8LP',
          errorText: _wrong ? l10n.recoveryCodeWrong : null,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        _checking
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3)),
              )
            : FilledButton(
                onPressed: _check,
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
      ],
    );
  }
}

/// Shows a new recovery code once, with Copy.
Future<void> showRecoveryCode(BuildContext context, String code) =>
    showAppDialog(
      context: context,
      builder: (context) => _RecoveryCodeDialog(code: code),
    );

class _RecoveryCodeDialog extends StatelessWidget {
  const _RecoveryCodeDialog({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.recoveryCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.recoveryCodeExplain),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                code,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              child: TextButton.icon(
                icon: const Icon(Icons.copy_rounded),
                label: Text(l10n.recoveryCodeCopy),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!EntryLinks.showsOwnCopiedMessage(
                      DeviceInfoService().androidSdk)) {
                    messenger?.showSnackBar(SnackBar(
                      content: Text(l10n.recoveryCodeCopied),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.recoveryCodeSaved),
          ),
        ],
      ),
    );
  }
}

/// "Welcome back, *Hanah*" with the name from Settings, or "Unlock the app"
/// when no name is set.
Widget unlockTitle(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final name = ConfigProvider.instance.get(Settings.homeGreetingName).trim();
  if (name.isEmpty) return Text(l10n.unlockAppPrompt);
  const marker = '\u0000';
  final parts = l10n.unlockWelcomeBack(marker).split(marker);
  return Text.rich(
    TextSpan(children: [
      TextSpan(text: parts.first),
      TextSpan(text: name, style: const TextStyle(fontStyle: FontStyle.italic)),
      if (parts.length > 1) TextSpan(text: parts.sublist(1).join()),
    ]),
    textAlign: TextAlign.center,
  );
}
