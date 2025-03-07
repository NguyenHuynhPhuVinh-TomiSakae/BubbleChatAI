import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import '../models/message.dart';
import '../models/chat_history.dart';
import 'preferences.dart';

class AiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  ChatHistory? _currentChatHistory;
  
  AiService() {
    _initializeModel();
  }
  
  Future<void> _initializeModel() async {
    try {
      final apiKey = await Preferences.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        print("API key không được cung cấp");
        return;
      }
      
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 1,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'text/plain',
        ),
      );
      
      _isInitialized = true;
    } catch (e) {
      print("Lỗi khởi tạo model: $e");
    }
  }
  
  Future<void> updateApiKey(String apiKey) async {
    await Preferences.saveApiKey(apiKey);
    _isInitialized = false;
    await _initializeModel();
  }
  
  Future<void> startNewChat() async {
    if (!_isInitialized) return;
    
    _currentChatHistory = null;
    _chatSession = _model!.startChat(history: []);
  }
  
  Future<void> loadChatHistory(ChatHistory chatHistory) async {
    if (!_isInitialized) return;
    
    _currentChatHistory = chatHistory;
    
    // Chuyển đổi tin nhắn thành định dạng mà Gemini yêu cầu
    final history = <Content>[];
    
    for (int i = 0; i < chatHistory.messages.length; i++) {
      final message = chatHistory.messages[i];
      if (message.isUser) {
        history.add(Content.text(message.text));
      } else {
        history.add(Content.model([TextPart(message.text)]));
      }
    }
    
    _chatSession = _model!.startChat(history: history);
  }
  
  Future<String> generateResponse(String query) async {
    if (!_isInitialized) {
      return "Chưa khởi tạo được kết nối với AI. Vui lòng kiểm tra API key trong cài đặt.";
    }
    
    try {
      if (_chatSession == null) {
        _chatSession = _model!.startChat(history: []);
      }
      
      final content = Content.text(query);
      final response = await _chatSession!.sendMessage(content);
      
      // Lưu tin nhắn vào lịch sử nếu có
      if (_currentChatHistory != null) {
        final userMessage = Message(text: query, isUser: true);
        final aiMessage = Message(text: response.text ?? '', isUser: false);
        
        _currentChatHistory = _currentChatHistory!.addMessage(userMessage).addMessage(aiMessage);
        await Preferences.saveChatHistoryItem(_currentChatHistory!);
      } else if (response.text != null) {
        // Tạo lịch sử chat mới nếu chưa có
        final userMessage = Message(text: query, isUser: true);
        final aiMessage = Message(text: response.text!, isUser: false);
        
        _currentChatHistory = ChatHistory.create(
          _generateTitle(query),
          userMessage,
        ).addMessage(aiMessage);
        
        await Preferences.saveChatHistoryItem(_currentChatHistory!);
      }
      
      return response.text ?? 'Không nhận được phản hồi';
    } catch (e) {
      return 'Đã xảy ra lỗi: $e';
    }
  }
  
  Stream<String> generateResponseStream(String query) async* {
    if (!_isInitialized) {
      yield "Chưa khởi tạo được kết nối với AI. Vui lòng kiểm tra API key trong cài đặt.";
      return;
    }
    
    try {
      if (_chatSession == null) {
        _chatSession = _model!.startChat(history: []);
      }
      
      final content = Content.text(query);
      String fullResponse = "";
      
      final responseStream = _chatSession!.sendMessageStream(content);
      
      final userMessage = Message(text: query, isUser: true);
      
      // Tạo lịch sử chat mới nếu chưa có
      if (_currentChatHistory == null) {
        _currentChatHistory = ChatHistory.create(
          _generateTitle(query),
          userMessage,
        );
        await Preferences.saveChatHistoryItem(_currentChatHistory!);
      } else {
        _currentChatHistory = _currentChatHistory!.addMessage(userMessage);
        await Preferences.saveChatHistoryItem(_currentChatHistory!);
      }
      
      await for (final response in responseStream) {
        if (response.text != null) {
          fullResponse += response.text!;
          yield fullResponse;
        }
      }
      
      // Lưu tin nhắn AI vào lịch sử khi hoàn thành
      final aiMessage = Message(text: fullResponse, isUser: false);
      _currentChatHistory = _currentChatHistory!.addMessage(aiMessage);
      await Preferences.saveChatHistoryItem(_currentChatHistory!);
      
    } catch (e) {
      yield 'Đã xảy ra lỗi: $e';
    }
  }
  
  String _generateTitle(String query) {
    // Tạo tiêu đề từ câu hỏi đầu tiên
    if (query.length > 30) {
      return query.substring(0, 30) + '...';
    }
    return query;
  }
  
  ChatHistory? get currentChatHistory => _currentChatHistory;
} 