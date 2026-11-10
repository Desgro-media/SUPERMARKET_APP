import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_nav.dart';
import '../../core/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../shell/page_scroll.dart';
import '../../state/actions.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_widgets.dart';
import '../../widgets/page_widgets.dart';
import '../../widgets/pressable.dart';
import '../account/sign_in_sheet.dart';

/// The frame of an account / information page (`page()` in the web app): breadcrumbs, title, a grey lead sentence, then
/// the page's cards one under the other.
class InfoPage extends StatelessWidget {
  const InfoPage({super.key, required this.title, required this.children, this.lead, this.showTitle = true});

  final String title;
  final String? lead;
  final List<Widget> children;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PageScroll(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Crumbs([Crumbs.home, ('Account', () => AppNav.go(Routes.account)), (title, null)]),
              if (showTitle) PageTitle(title),
              if (lead != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(context.tr(lead!), style: ts(14, color: t.muted)),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 14), children[i]]],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Please sign in first": shown instead of the profile and similar pages while nobody is signed in.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key, required this.title, required this.text});

  final String title, text;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return InfoPage(
      title: title,
      children: [
        CardBox(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Text('\u{1F44B}', style: TextStyle(fontSize: 48, height: 1)),
              const SizedBox(height: 14),
              Text(context.tr('Please sign in first'), style: ts(20, w: FontWeight.w800, color: t.text, height: 1.15, ls: -.02)),
              const SizedBox(height: 10),
              Text(context.tr(text), textAlign: TextAlign.center, style: ts(14, color: t.muted)),
              const SizedBox(height: 18),
              AppButton(label: context.tr('Sign in or create account'), height: 46, onTap: () => showSignInSheet(context)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tappable card with an icon, a title and a small line (Call us, Email us, Opening hours ...) (`.help-card`).
class HelpCard extends StatelessWidget {
  const HelpCard({super.key, required this.icon, required this.title, required this.text, this.onTap});

  final String icon, title, text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final card = CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 28, color: t.brand600),
          const SizedBox(height: 6),
          Text(context.tr(title), style: ts(14, w: FontWeight.w700, color: t.text, height: 1.3)),
          const SizedBox(height: 4),
          Text(context.tr(text), style: ts(13, color: t.muted)),
        ],
      ),
    );
    return onTap == null ? card : Pressable(onTap: onTap, scale: .98, semanticLabel: context.tr(title), child: card);
  }
}

/// One question of the FAQ: tap to open the answer (`<details>` in the web app).
class FaqItem extends StatefulWidget {
  const FaqItem({super.key, required this.question, required this.answer, this.last = false});

  final String question, answer;
  final bool last;

  @override
  State<FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      decoration: BoxDecoration(border: widget.last ? null : Border(bottom: BorderSide(color: t.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: () => setState(() => _open = !_open),
            scale: .99,
            semanticLabel: context.tr(widget.question),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text(context.tr(widget.question), style: ts(14, w: FontWeight.w700, color: t.text, height: 1.4))),
                  const SizedBox(width: 12),
                  AnimatedRotation(turns: _open ? .5 : 0, duration: const Duration(milliseconds: 200), child: AppIcon('down', size: 16, color: t.muted, stroke: 2.4)),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open ? Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(context.tr(widget.answer), style: ts(14, color: t.muted))) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The "Send us a message" form of the support and contact pages. Nothing is sent anywhere (the demo has no server):
/// it validates, clears itself and says thanks, like the web app.
class MessageForm extends ConsumerStatefulWidget {
  const MessageForm({super.key, required this.messageLabel, this.name, this.contact});

  final String messageLabel;
  final String? name, contact;

  @override
  ConsumerState<MessageForm> createState() => _MessageFormState();
}

class _MessageFormState extends ConsumerState<MessageForm> {
  late final _name = TextEditingController(text: widget.name ?? '');
  late final _contact = TextEditingController(text: widget.contact ?? '');
  final _text = TextEditingController();
  final Map<String, String?> _errors = {};
  static final RegExp _contactRe = RegExp(r'^(\S+@\S+\.\S+|[+\d][\d\s-]{7,16})$');

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _text.dispose();
    super.dispose();
  }

  void _send() {
    String? req(String v) => v.trim().isEmpty ? 'This field is required' : null;
    setState(() {
      _errors['name'] = req(_name.text);
      _errors['contact'] = req(_contact.text) ?? (_contactRe.hasMatch(_contact.text.trim()) ? null : 'Enter a valid email or mobile number');
      _errors['text'] = req(_text.text);
    });
    if (_errors.values.any((e) => e != null)) return;
    _name.clear();
    _contact.clear();
    _text.clear();
    FocusScope.of(context).unfocus();
    ref.read(actionsProvider).toast('Thanks! Your message was sent. We will get back to you soon.');
  }

  @override
  Widget build(BuildContext context) {
    String? e(String k) => _errors[k] == null ? null : context.tr(_errors[k]!);
    return CardBox(
      title: 'Send us a message',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(label: context.tr('Your name'), controller: _name, required: true, error: e('name'), textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name]),
          const SizedBox(height: 12),
          AppField(label: context.tr('Email or mobile number'), controller: _contact, required: true, error: e('contact'), textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.username]),
          const SizedBox(height: 12),
          AppField(label: context.tr(widget.messageLabel), controller: _text, required: true, error: e('text'), maxLines: 4, minLines: 4, maxLength: 600, keyboardType: TextInputType.multiline),
          const SizedBox(height: 16),
          AppButton(label: context.tr('Send message'), height: 46, expand: true, onTap: _send),
        ],
      ),
    );
  }
}

/// A rounded box with a dashed outline (coupons).
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, required this.color, this.radius = 16, this.fill, this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12)});

  final Widget child;
  final Color color;
  final Color? fill;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashedRRect(color, radius, fill),
        child: Padding(padding: padding, child: child),
      );
}

class _DashedRRect extends CustomPainter {
  _DashedRRect(this.color, this.radius, this.fill);

  final Color color;
  final Color? fill;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    if (fill != null) canvas.drawRRect(rrect, Paint()..color = fill!);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect.deflate(.75));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, (d + 5).clamp(0, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color || old.fill != fill || old.radius != radius;
}
