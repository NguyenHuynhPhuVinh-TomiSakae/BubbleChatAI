import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'preferences.dart';

class AiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  
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
      
      _chatSession = _model!.startChat(history: []);
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
  
  Future<String> generateResponse(String query) async {
    if (!_isInitialized) {
      return "Chưa khởi tạo được kết nối với AI. Vui lòng kiểm tra API key trong cài đặt.";
    }
    
    try {
      final content = Content.text(query);
      final response = await _chatSession!.sendMessage(content);
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
      final content = Content.text(query);
      String fullResponse = "";
      
      final responseStream = _chatSession!.sendMessageStream(content);
      
      await for (final response in responseStream) {
        if (response.text != null) {
          fullResponse += response.text!;
          yield fullResponse;
        }
      }
    } catch (e) {
      yield 'Đã xảy ra lỗi: $e';
    }
  }
} 