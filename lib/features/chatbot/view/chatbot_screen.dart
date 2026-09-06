import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageBase64;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageBase64,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'imageBase64': imageBase64,
      };

  factory _ChatMessage.fromMap(Map<String, dynamic> map) => _ChatMessage(
        text: map['text'] as String? ?? '',
        isUser: map['isUser'] as bool? ?? false,
        timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
            DateTime.now(),
        imageBase64: map['imageBase64'] as String?,
      );
}

class _ChatSession {
  final String id;
  String title;
  DateTime updatedAt;
  List<_ChatMessage> messages;

  _ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toMap()).toList(),
      };

  factory _ChatSession.fromMap(Map<String, dynamic> map) => _ChatSession(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? 'Chat',
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        messages: (map['messages'] as List<dynamic>? ?? [])
            .map((m) => _ChatMessage.fromMap(Map<String, dynamic>.from(m)))
            .toList(),
      );
}

class ChatbotScreen extends StatefulWidget {
  final String? initialContext;
  const ChatbotScreen({super.key, this.initialContext});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;

  String? _pendingImageBase64;
  List<_ChatSession> _sessions = [];
  String _currentSessionId = '';

  static const String _apiKey =
      'AQ.Ab8RN6KS4k7zMX9Rza6IEIwyovwJueGIwOhUWAuueYFNj7torg';
  static const String _model = 'gemini-2.5-flash-lite-preview-06-17';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey';

  static const String _systemPrompt =
      'You are an expert APSSB/APPSC exam preparation tutor for Arunachal Pradesh government job exams.\n'
      'Your role:\n'
      '- Explain concepts from APSSB syllabus: General English, Quantitative Aptitude, General Knowledge, Reasoning.\n'
      '- Answer questions about Arunachal Pradesh history, geography, culture, administration, and current affairs.\n'
      '- Solve practice questions step by step.\n'
      '- Give study tips and time management strategies specific to APSSB/APPSC exams.\n'
      '- When analysing images (like study notes, question papers, maps, or book pages), provide comprehensive, detailed explanations and solve any question visible.\n'
      'Provide rich, complete, detailed explanations with bullet points and bold headers.\n'
      'Always respond in English unless the user writes in Hindi.\n'
      'Format responses cleanly with markdown.';

  @override
  void initState() {
    super.initState();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _initSpeech();
    _loadSessions();

    if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
      _messages.add(_ChatMessage(
        text: 'Summarise this article for APSSB exam preparation:\n\n${widget.initialContext}',
        isUser: true,
        timestamp: DateTime.now(),
      ));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendAutoSummary(widget.initialContext!);
      });
    } else {
      _messages.add(_ChatMessage(
        text:
            'Namaste! 🙏 I am your APSSB/APPSC AI tutor. Ask me anything about syllabus topics, past year questions, or study strategies!',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (e) => debugPrint('[Speech] Error: $e'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[Speech] Init error: $e');
    }
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ai_tutor_sessions');
      if (raw != null) {
        final list = (jsonDecode(raw) as List)
            .map((e) => _ChatSession.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        if (mounted) {
          setState(() {
            _sessions = list;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstUserMsg = _messages.firstWhere(
        (m) => m.isUser,
        orElse: () => _ChatMessage(
            text: 'APSSB Practice Session',
            isUser: true,
            timestamp: DateTime.now()),
      );
      final title = firstUserMsg.text.length > 28
          ? '${firstUserMsg.text.substring(0, 28)}...'
          : firstUserMsg.text;

      final existingIdx =
          _sessions.indexWhere((s) => s.id == _currentSessionId);
      final session = _ChatSession(
        id: _currentSessionId,
        title: title,
        updatedAt: DateTime.now(),
        messages: List<_ChatMessage>.from(_messages),
      );

      if (existingIdx != -1) {
        _sessions[existingIdx] = session;
      } else {
        _sessions.insert(0, session);
      }

      if (_sessions.length > 20) {
        _sessions = _sessions.sublist(0, 20);
      }

      await prefs.setString(
        'ai_tutor_sessions',
        jsonEncode(_sessions.map((s) => s.toMap()).toList()),
      );
    } catch (_) {}
  }

  void _startNewSession() {
    setState(() {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _messages.clear();
      _messages.add(_ChatMessage(
        text:
            'Namaste! 🙏 Started a new chat. Ask me anything about APSSB/APPSC exams!',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _pendingImageBase64 = null;
    });
    Navigator.of(context).maybePop();
  }

  void _loadSession(_ChatSession session) {
    setState(() {
      _currentSessionId = session.id;
      _messages.clear();
      _messages.addAll(session.messages);
      _pendingImageBase64 = null;
    });
    Navigator.of(context).maybePop();
    _scrollToBottom();
  }

  void _deleteSession(String id) async {
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ai_tutor_sessions',
      jsonEncode(_sessions.map((s) => s.toMap()).toList()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _sendAutoSummary(String context) async {
    setState(() => _isLoading = true);
    try {
      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    'Provide an in-depth, structured summary of this article for APSSB and APPSC exam preparation with key facts, government policies, and exam relevance:\n\n$context'
              }
            ]
          }
        ],
      });
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = (data['candidates'][0]['content']['parts'] as List);
        final reply = parts
            .where((p) =>
                p.containsKey('text') && (p['text'] as String).isNotEmpty)
            .map((p) => p['text'] as String)
            .join('')
            .trim();
        if (mounted) {
          setState(() {
            _messages.add(_ChatMessage(
                text: reply, isUser: false, timestamp: DateTime.now()));
            _isLoading = false;
          });
          _saveCurrentSession();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: '⚠️ Could not summarise article. Please check your connection.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    }
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    final hasImage = _pendingImageBase64 != null;
    if (trimmed.isEmpty && !hasImage) return;
    if (_isLoading) return;

    final userText =
        trimmed.isEmpty && hasImage ? 'Analyse this image' : trimmed;
    final sentImageBase64 = _pendingImageBase64;

    _controller.clear();
    setState(() {
      _pendingImageBase64 = null;
      _messages.add(_ChatMessage(
        text: userText,
        isUser: true,
        timestamp: DateTime.now(),
        imageBase64: sentImageBase64,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final List<Map<String, dynamic>> contents = [];

      final recentMessages = _messages.length > 11
          ? _messages.sublist(_messages.length - 11)
          : _messages;

      for (int i = 0; i < recentMessages.length; i++) {
        final m = recentMessages[i];
        final List<Map<String, dynamic>> parts = [];

        if (m.imageBase64 != null && i == recentMessages.length - 1) {
          parts.add({
            'inlineData': {
              'mimeType': 'image/jpeg',
              'data': m.imageBase64,
            }
          });
        }
        parts.add({'text': m.text});

        contents.add({
          'role': m.isUser ? 'user' : 'model',
          'parts': parts,
        });
      }

      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt}
          ]
        },
        'contents': contents,
      });

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final parts = (data['candidates'][0]['content']['parts'] as List);
        final reply = parts
            .where((p) =>
                p.containsKey('text') && (p['text'] as String).isNotEmpty)
            .map((p) => p['text'] as String)
            .join('')
            .trim();

        if (mounted) {
          setState(() {
            _messages.add(_ChatMessage(
                text: reply, isUser: false, timestamp: DateTime.now()));
            _isLoading = false;
          });
          _saveCurrentSession();
        }
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AI Tutor] Error: $e');
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text:
                '⚠️ Could not reach the AI Tutor right now. Please check your internet connection and try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    }
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    final storageStatus = await Permission.storage.request();
    if (!status.isGranted && !storageStatus.isGranted) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (pickedFile == null) return;

    final bytes = await File(pickedFile.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    setState(() {
      _pendingImageBase64 = base64Image;
    });
  }

  Future<void> _toggleListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Microphone permission required for speech recognition.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onError: (e) => debugPrint('[Speech] Error: $e'),
      );
    }

    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
            if (result.finalResult) {
              _isListening = false;
              _speech.stop();
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          pauseFor: const Duration(seconds: 4),
          localeId: 'en_IN',
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AI Tutor History',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: ElevatedButton.icon(
                onPressed: _startNewSession,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'PREVIOUS CHATS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Expanded(
              child: _sessions.isEmpty
                  ? const Center(
                      child: Text(
                        'No previous chats yet',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final s = _sessions[index];
                        final isSelected = s.id == _currentSessionId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor:
                              AppColors.primary.withValues(alpha: 0.08),
                          leading: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 16, color: AppColors.textHint),
                            onPressed: () => _deleteSession(s.id),
                          ),
                          onTap: () => _loadSession(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Chat History',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tutor',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('APSSB/APPSC Expert',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: _startNewSession,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m, vertical: AppSpacing.s),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return _buildTypingIndicator();
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_messages.length <= 2 && widget.initialContext == null)
            _buildSuggestions(),
          if (_pendingImageBase64 != null) _buildPendingImageStrip(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPendingImageStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(_pendingImageBase64!),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photo attached',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('Type a question or tap Send to analyse.',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 20, color: AppColors.textHint),
            onPressed: () {
              setState(() => _pendingImageBase64 = null);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return GestureDetector(
      onLongPress: isUser
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: msg.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied full response to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child:
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUser
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (msg.imageBase64 != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(msg.imageBase64!),
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (msg.text.isNotEmpty &&
                                msg.text != 'Analyse this image')
                              const SizedBox(height: 6),
                          ],
                          if (msg.text.isNotEmpty &&
                              (msg.imageBase64 == null ||
                                  msg.text != 'Analyse this image'))
                            Text(
                              msg.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                        ],
                      )
                    : SelectionArea(
                        child: MarkdownBody(
                          data: msg.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            strong: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            em: const TextStyle(
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                            code: const TextStyle(
                              backgroundColor: Color(0xFFE8F5E9),
                              color: AppColors.primaryDark,
                              fontSize: 13,
                            ),
                            listBullet: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (isUser) const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                    minHeight: 2,
                  ),
                ),
                SizedBox(width: 8),
                Text('Thinking...',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'APSSB CGL syllabus topics?',
      'Number series tricks',
      'GK facts about Arunachal',
      'English grammar tips',
    ];
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 4),
        children: suggestions.map((q) {
          return GestureDetector(
            onTap: () => _sendMessage(q),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                q,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s,
        right: AppSpacing.m,
        top: AppSpacing.s,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleListening,
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening ? AppColors.error : AppColors.textSecondary,
            ),
            tooltip: _isListening ? 'Stop listening' : 'Voice input',
          ),
          IconButton(
            onPressed: _isLoading ? null : _pickImage,
            icon: Icon(
              _pendingImageBase64 != null
                  ? Icons.image_rounded
                  : Icons.image_outlined,
              color: _pendingImageBase64 != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            tooltip: 'Attach photo',
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: _isListening
                    ? 'Listening...'
                    : (_pendingImageBase64 != null
                        ? 'Ask question about this image...'
                        : 'Ask anything about APSSB...'),
                hintStyle: TextStyle(
                  color: _isListening ? AppColors.error : AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
              maxLines: null,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
