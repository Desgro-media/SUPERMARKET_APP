import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/catalogue.dart';
import '../../shell/sheets.dart';
import '../../state/actions.dart';
import '../../state/store.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_widgets.dart';

final RegExp _phone = RegExp(r'^[+\d][\d\s-]{7,16}$');
final RegExp _email = RegExp(r'^\S+@\S+\.\S+$');

/// The demo sign-in (V.openAuth in the web app): a name and an e-mail or mobile number, kept on this phone only.
Future<void> showSignInSheet(BuildContext context, {VoidCallback? after}) =>
    showAppSheet<void>(context, (_) => _SignInSheet(after: after));

class _SignInSheet extends ConsumerStatefulWidget {
  const _SignInSheet({this.after});

  final VoidCallback? after;

  @override
  ConsumerState<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<_SignInSheet> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  String? _nameError, _contactError;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim(), contact = _contact.text.trim();
    final nameOk = name.isNotEmpty;
    final contactOk = _email.hasMatch(contact) || _phone.hasMatch(contact);
    setState(() {
      _nameError = nameOk ? null : 'Please tell us your name';
      _contactError = contactOk ? null : 'Enter a valid email or mobile number';
    });
    if (!nameOk || !contactOk) return;
    ref.read(storeProvider.notifier).setUser({'name': name, 'contact': contact});
    Navigator.of(context).pop();
    ref.read(actionsProvider).toast('Welcome, ${name.split(' ').first}!');
    widget.after?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final storeName = ref.watch(catalogueProvider).config.name;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SheetFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F96C}', style: TextStyle(fontSize: 44, height: 1.1)),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 32),
              child: Text(
                context.tr('Welcome to $storeName'),
                style: ts(20, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('Sign in to check out faster. Demo only — no password needed and your details stay on this device.'),
              style: ts(14, color: t.muted),
            ),
            const SizedBox(height: 14),
            AppField(
              label: context.tr('Your name'),
              controller: _name,
              error: _nameError == null ? null : context.tr(_nameError!),
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            AppField(
              label: context.tr('Email or mobile number'),
              controller: _contact,
              error: _contactError == null ? null : context.tr(_contactError!),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            AppButton(label: context.tr('Continue'), height: 46, expand: true, onTap: _submit),
          ],
        ),
      ),
    );
  }
}
