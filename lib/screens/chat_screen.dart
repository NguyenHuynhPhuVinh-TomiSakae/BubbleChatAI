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

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  bool _isTyping = false;
  bool _showAllSuggestions = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Khởi tạo và tác vụ nền
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }
  
  Future<void> _initializeChat() async {
    // Tải lịch sử chat hoặc cài đặt khác nếu cần
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
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
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Column(
              children: [
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
            ),
            crossFadeState: _showAllSuggestions 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brightness = Theme.of(context).brightness;
    
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: ChatSidebar(
          aiService: _aiService,
          onChatSelected: _loadChatHistory,
          onNewChatPressed: _startNewChat,
          onClose: () {
            Navigator.pop(context);
          },
        ),
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'BubbleChatAI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
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
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _messages.isEmpty 
                      ? 1 
                      : _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_messages.isEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 40),
                          const Center(
                            child: Text(
                              'Tôi có thể giúp gì cho bạn?',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 60),
                          _buildSuggestionButtons(),
                        ],
                      );
                    } else if (index < _messages.length) {
                      return ChatMessageWidget(message: _messages[index]);
                    } else if (_isTyping) {
                      return const TypingIndicator();
                    }
                    return null;
                  },
                ),
              ),
              ChatInputField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 