import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isApiKeyError;

  ChatMessage({required this.text, required this.isUser, required this.timestamp, this.isApiKeyError = false});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  ChatSession? _chat;
  bool _apiKeyMissing = false;

  static const String _systemPrompt = '''
You are an expert APSSB/APPSC exam preparation tutor for Arunachal Pradesh government job exams.
Your role:
- Explain concepts from APSSB syllabus: General English, Quantitative Aptitude, General Knowledge, Reasoning.
- Answer questions about Arunachal Pradesh history, geography, culture, and current affairs.
- Solve practice questions step by step.
- Give study tips and time management strategies specific to APSSB/APPSC exams.
- Be encouraging and supportive.
Keep answers concise (2-5 sentences for simple questions, longer for complex ones).
Always respond in English unless the user writes in Hindi.
''';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString('user_gemini_api_key');
    final apiKey = (customKey != null && customKey.isNotEmpty) ? customKey : AppConstants.effectiveGeminiApiKey;

    if (apiKey.isEmpty) {
      setState(() => _apiKeyMissing = true);
      return;
    }
    
    setState(() => _apiKeyMissing = false);

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );
      _chat = model.startChat();
      // Add welcome message if empty
      if (_messages.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Namste! 🙏 I am your APSSB/APPSC AI tutor. Ask me anything about the exam syllabus, practice questions, or study strategies!',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() => _apiKeyMissing = true);
    }
  }

  Future<void> _showApiKeyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString('user_gemini_api_key') ?? '';
    final controller = TextEditingController(text: customKey);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Gemini API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your free Gemini API key from aistudio.google.com to use the AI Tutor.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newKey = controller.text.trim();
                await prefs.setString('user_gemini_api_key', newKey);
                Navigator.pop(context);
                _initChat();
              },
              child: const Text('Save & Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _chat == null) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat!.sendMessage(Content.text(text));
      final reply = response.text ?? 'Sorry, I could not generate a response. Please try again.';
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Chatbot] Error: $e');
      final isKeyError = e.toString().toLowerCase().contains('key') || e.toString().toLowerCase().contains('api') || e.toString().contains('API');
      setState(() {
        _messages.add(ChatMessage(
          text: isKeyError 
              ? 'Gemini API Key Error. Please tap the Key icon in the top right to paste a valid free key from aistudio.google.com'
              : 'Connection error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isApiKeyError: isKeyError,
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.psychology_rounded, color: AppColors.primary, size: 18),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tutor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('APSSB/APPSC Expert', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: _showApiKeyDialog,
          ),
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.m),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppColors.success, size: 8),
                SizedBox(width: 4),
                Text('Online', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: _apiKeyMissing
          ? _buildApiKeyMissingView()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),
                _buildSuggestedQuestions(),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildApiKeyMissingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.key_off_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'Gemini API Key Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'To enable AI Tutor, add your free Gemini API key in lib/core/constants/app_constants.dart',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.m),
            ElevatedButton(
              onPressed: _showApiKeyDialog,
              child: const Text('Open Key Dialog'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (msg.isApiKeyError) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showApiKeyDialog,
                icon: const Icon(Icons.key),
                label: const Text('Open Key Dialog'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.divider,
                color: AppColors.primary,
                minHeight: 2,
              ),
            ),
            SizedBox(width: 8),
            Text('Thinking...', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    if (_messages.length > 2) return const SizedBox.shrink();
    final suggestions = [
      'What topics are in APSSB CGL syllabus?',
      'Explain number series tricks',
      'Important GK facts about Arunachal',
      'How to improve English for APSSB?',
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        children: suggestions.map((q) => GestureDetector(
          onTap: () => _sendMessage(q),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(q, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.m,
        right: AppSpacing.m,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s,
        top: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask anything about APSSB...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _sendMessage,
              textInputAction: TextInputAction.send,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
