import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/services/ai_service.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/aura_widgets.dart';
import '../../streak/data/time_tracker.dart';

class _Msg {
  final bool user;
  final String text;
  final String? image;
  final bool error;
  const _Msg(this.user, this.text, {this.image, this.error = false});

  Map<String, dynamic> toJson() => {
        'u': user,
        't': text,
        if (image != null) 'i': image,
        if (error) 'e': true
      };
  factory _Msg.fromJson(Map<String, dynamic> j) =>
      _Msg(j['u'] as bool, j['t'] as String,
          image: j['i'] as String?, error: j['e'] == true);
}

class ChatbotScreen extends ConsumerStatefulWidget {
  /// Text to explain straight away (from a news story or a study card).
  final String? initialContext;
  const ChatbotScreen({super.key, this.initialContext});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  static const _key = 'tutor_chat_v2';
  static const _suggestions = [
    'Explain Article 371H in simple words',
    'Make a 7-day plan for APSSB CGL General Awareness',
    'Quiz me on Arunachal festivals',
    'When do we use "no sooner … than"?',
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _speech = stt.SpeechToText();
  List<_Msg> _msgs = [];
  String? _pendingImage;
  bool _busy = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _load();
    final ctx = widget.initialContext;
    if (ctx != null && ctx.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(ctx));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _speech.stop();
    super.dispose();
  }

  void _load() {
    try {
      final raw = ref.read(sharedPreferencesProvider).getString(_key);
      if (raw != null) {
        _msgs = [
          for (final m in jsonDecode(raw) as List)
            _Msg.fromJson(m as Map<String, dynamic>)
        ];
      }
    } catch (_) {}
  }

  void _save() {
    // Keep the last 40 messages; drop old photos to keep storage small.
    final keep = _msgs.length > 40 ? _msgs.sublist(_msgs.length - 40) : _msgs;
    final slim = [
      for (int i = 0; i < keep.length; i++)
        i < keep.length - 4
            ? _Msg(keep[i].user, keep[i].text, error: keep[i].error)
            : keep[i]
    ];
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(slim.map((m) => m.toJson()).toList()));
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic);
        }
      });

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if ((text.isEmpty && _pendingImage == null) || _busy) return;
    final image = _pendingImage;
    setState(() {
      _msgs.add(_Msg(true, text.isEmpty ? 'Explain this question' : text,
          image: image));
      _pendingImage = null;
      _busy = true;
      _input.clear();
    });
    _toBottom();

    final history = _msgs.where((m) => !m.error).toList();
    final recent =
        history.length > 12 ? history.sublist(history.length - 12) : history;
    try {
      final reply = await AiService.generate([
        for (int i = 0; i < recent.length; i++)
          recent[i].user
              ? AiTurn.user(recent[i].text,
                  imageBase64: i == recent.length - 1 ? recent[i].image : null)
              : AiTurn.model(recent[i].text)
      ]);
      _msgs.add(_Msg(false, reply));
    } on AiException catch (e) {
      _msgs.add(_Msg(false, e.message, error: true));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _save();
    _toBottom();
  }

  Future<void> _attach() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GlassList(children: [
            GlassListRow(
                icon: CupertinoIcons.camera,
                title: 'Photo of a question',
                onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            GlassListRow(
                icon: CupertinoIcons.photo,
                title: 'Choose from gallery',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ]),
        ),
      ),
    );
    if (source == null) return;
    try {
      final f = await ImagePicker().pickImage(
          source: source, maxWidth: 1000, maxHeight: 1000, imageQuality: 72);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() => _pendingImage = base64Encode(bytes));
    } catch (_) {
      _snack('Couldn\'t open the photo.');
    }
  }

  Future<void> _mic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
        onError: (_) => setState(() => _listening = false));
    if (!ok) {
      _snack('Voice input needs microphone permission.');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) => setState(() {
        _input.text = r.recognizedWords;
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
        if (r.finalResult) _listening = false;
      }),
      listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation, localeId: 'en_IN'),
    );
  }

  void _snack(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  void _newChat() {
    setState(() => _msgs = []);
    _save();
  }

  @override
  Widget build(BuildContext context) => TimeTracked(
        section: 'read',
        sub: 'tutor',
        child: _buildContent(context),
      );

  Widget _buildContent(BuildContext context) {
    final a = context.aura;
    return AuraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(CupertinoIcons.back),
            onPressed: () => context.pop(),
          ),
          title: const Text('AI tutor'),
          actions: [
            if (_msgs.isNotEmpty)
              IconButton(
                  tooltip: 'New chat',
                  icon: const Icon(CupertinoIcons.square_pencil),
                  onPressed: _newChat),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
              child: _msgs.isEmpty
                  ? _empty(context)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(
                          AuraSpace.gutter, 8, AuraSpace.gutter, 16),
                      itemCount: _msgs.length + (_busy ? 1 : 0),
                      itemBuilder: (_, i) => i == _msgs.length
                          ? const _Typing()
                          : _Bubble(msg: _msgs[i]),
                    ),
            ),
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AuraSpace.gutter, 0, AuraSpace.gutter, 8),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(base64Decode(_pendingImage!),
                        width: 56, height: 56, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('Photo attached',
                          style: AuraType.sans(13, a.inkMuted))),
                  IconButton(
                    tooltip: 'Remove photo',
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    onPressed: () => setState(() => _pendingImage = null),
                  ),
                ]),
              ),
            _inputBar(context),
          ]),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final a = context.aura;
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(AuraSpace.gutter, 24, AuraSpace.gutter, 16),
      children: [
        Icon(CupertinoIcons.sparkles, color: a.accent, size: 30),
        const SizedBox(height: 14),
        Text('Ask anything from your syllabus',
            style: AuraType.serif(26, a.ink, height: 1.2)),
        const SizedBox(height: 8),
        Text(
            'Type, speak, or snap a photo of a question. Answers can be wrong, so confirm '
            'important facts with your books or official sources.',
            style: AuraType.sans(14.5, a.inkMuted, height: 1.5)),
        const SizedBox(height: 24),
        GlassList(indent: 18, children: [
          for (final s in _suggestions)
            GlassListRow(
                icon: CupertinoIcons.arrow_up_right,
                title: s,
                onTap: () => _send(s)),
        ]),
      ],
    );
  }

  Widget _inputBar(BuildContext context) {
    final a = context.aura;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: a.bg.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: a.hairline)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        IconButton(
            tooltip: 'Add photo',
            icon: const Icon(CupertinoIcons.camera),
            onPressed: _busy ? null : _attach),
        Expanded(
          child: TextField(
            controller: _input,
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: _listening ? 'Listening…' : 'Ask the tutor',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: a.hairline)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: a.hairline)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: a.accent)),
            ),
          ),
        ),
        IconButton(
          tooltip: _listening ? 'Stop' : 'Speak',
          icon: Icon(
              _listening ? CupertinoIcons.stop_circle_fill : CupertinoIcons.mic,
              color: _listening ? a.danger : null),
          onPressed: _busy ? null : _mic,
        ),
        IconButton.filled(
          tooltip: 'Send',
          style: IconButton.styleFrom(
              backgroundColor: a.accent, foregroundColor: a.onAccent),
          icon: const Icon(CupertinoIcons.arrow_up, size: 20),
          onPressed: _busy ? null : () => _send(),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    final user = msg.user;
    final style = AuraType.sans(15, user ? a.onAccent : a.ink, height: 1.5);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * (user ? 0.78 : 0.9)),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: user
              ? a.accent
              : (msg.error ? a.danger.withValues(alpha: 0.08) : a.surfaceSolid),
          border: user
              ? null
              : Border.all(
                  color:
                      msg.error ? a.danger.withValues(alpha: 0.3) : a.hairline),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(user ? 20 : 6),
            bottomRight: Radius.circular(user ? 6 : 20),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (msg.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(base64Decode(msg.image!),
                  height: 160, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ],
          if (user || msg.error)
            SelectableText(msg.text, style: style)
          else
            MarkdownBody(
              data: msg.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: style,
                listBullet: style,
                strong: style.copyWith(fontWeight: FontWeight.w700),
                h1: AuraType.serif(20, a.ink),
                h2: AuraType.serif(18, a.ink),
                h3: AuraType.sans(16, a.ink, weight: FontWeight.w600),
                code: AuraType.sans(14, a.ink)
                    .copyWith(backgroundColor: a.bgTint),
                blockquoteDecoration: BoxDecoration(
                  color: a.bgTint,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          if (!user && !msg.error)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                icon: Icon(CupertinoIcons.doc_on_doc,
                    size: 16, color: a.inkFaint),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: msg.text));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Copied')));
                },
              ),
            ),
        ]),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: a.surfaceSolid,
          border: Border.all(color: a.hairline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 14,
              height: 14,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: a.accent)),
          const SizedBox(width: 10),
          Text('Thinking…', style: AuraType.sans(13.5, a.inkMuted)),
        ]),
      ),
    );
  }
}
