import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_history.dart';
import '../utils/ai_service.dart';
import '../widgets/chat_message.dart';
import '../widgets/suggestion_button.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_sidebar.dart';
import '../screens/settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  bool _isTyping = false;
  bool _showAllSuggestions = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _isTyping = true;
      _showAllSuggestions = false;
    });
    
    _scrollToBottom();
    
    // Tạo tin nhắn trống cho AI
    final aiMessage = Message(text: "", isUser: false);
    setState(() {
      _messages.add(aiMessage);
    });
    
    // Sử dụng stream để cập nhật tin nhắn theo thời gian thực
    _aiService.generateResponseStream(text).listen(
      (fullResponse) {
        if (mounted) {
          setState(() {
            // Tìm vị trí tin nhắn AI trong danh sách
            final index = _messages.indexWhere((msg) => 
              msg == aiMessage || 
              (!msg.isUser && _messages.indexOf(msg) == _messages.length - 1)
            );
            
            if (index != -1) {
              // Tạo tin nhắn mới với nội dung cập nhật
              _messages[index] = Message(text: fullResponse, isUser: false);
            }
          });
          
          // Đảm bảo cuộn xuống sau mỗi cập nhật
          _scrollToBottom();
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isTyping = false;
            // Tìm vị trí tin nhắn AI
            final index = _messages.indexWhere((msg) => 
              msg == aiMessage || 
              (!msg.isUser && _messages.indexOf(msg) == _messages.length - 1)
            );
            
            if (index != -1) {
              _messages[index] = Message(text: "Đã xảy ra lỗi: $error", isUser: false);
            }
          });
        }
      },
    );
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _showAllSuggestions = false;
    });
    _aiService.startNewChat();
  }

  Future<void> _loadChatHistory(ChatHistory chatHistory) async {
    await _aiService.loadChatHistory(chatHistory);
    
    setState(() {
      _messages.clear();
      _messages.addAll(chatHistory.messages);
      _showAllSuggestions = false;
    });
    
    _scrollToBottom();
  }

  void _handleSuggestionTap(String suggestion) {
    _textController.text = suggestion;
    _handleSubmitted(suggestion);
  }

  void _toggleShowAllSuggestions() {
    setState(() {
      _showAllSuggestions = !_showAllSuggestions;
    });
  }

  Widget _buildSuggestionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: SuggestionButton(
                text: 'Tạo hình ảnh',
                icon: Icons.image,
                iconColor: Colors.green,
                onTap: () => _handleSuggestionTap('Tạo hình ảnh'),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.65,
              child: SuggestionButton(
                text: 'Tóm tắt văn bản',
                icon: Icons.description,
                iconColor: Colors.orange,
                onTap: () => _handleSuggestionTap('Tóm tắt văn bản'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: SuggestionButton(
                text: 'Thêm',
                icon: null,
                iconColor: Colors.transparent,
                onTap: _toggleShowAllSuggestions,
              ),
            ),
          ],
        ),
        if (_showAllSuggestions) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SuggestionButton(
              text: 'Phân tích hình ảnh',
              icon: Icons.remove_red_eye,
              iconColor: Colors.blue,
              onTap: () => _handleSuggestionTap('Phân tích hình ảnh'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SuggestionButton(
              text: 'Mã',
              icon: Icons.code,
              iconColor: Colors.purple,
              onTap: () => _handleSuggestionTap('Viết mã'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.42,
                child: SuggestionButton(
                  text: 'Lên kế hoạch',
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.amber,
                  onTap: () => _handleSuggestionTap('Lên kế hoạch'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.42,
                child: SuggestionButton(
                  text: 'Lên ý tưởng',
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.amber,
                  onTap: () => _handleSuggestionTap('Lên ý tưởng'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade200,
          elevation: 0,
          title: const Text(
            'BubbleChatAI',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(aiService: _aiService),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: ChatSidebar(
          aiService: _aiService,
          onChatSelected: _loadChatHistory,
          onNewChatPressed: _startNewChat,
          onClose: () {
            Navigator.pop(context);
          },
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  if (_messages.isEmpty) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        'Tôi có thể giúp gì cho bạn?',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 60),
                    _buildSuggestionButtons(),
                  ],
                  ..._messages.map((message) => ChatMessageWidget(message: message)),
                  if (_isTyping) const TypingIndicator(),
                ],
              ),
            ),
            ChatInputField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
            ),
          ],
        ),
      ),
    );
  }
} 