import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/message.dart';
import '../models/chat_history.dart';
import 'preferences.dart';

class AiService {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  ChatHistory? _currentChatHistory;
  
  // Thêm cache cho ảnh
  final Map<String, String> _imageCache = {};
  
  AiService() {
    _initializeModel();
    _prepareImageDirectory();
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
  
  Stream<String> generateResponseStream(String query, {List<String>? imageUrls}) async* {
    if (!_isInitialized) {
      yield "Chưa khởi tạo được kết nối với AI. Vui lòng kiểm tra API key trong cài đặt.";
      return;
    }
    
    try {
      if (_chatSession == null) {
        _chatSession = _model!.startChat(history: []);
      }

      // Tạo content với text và ảnh
      List<Part> parts = [];
      if (query.isNotEmpty) {
        parts.add(TextPart(query));
      }

      // Thêm ảnh vào parts nếu có
      if (imageUrls != null && imageUrls.isNotEmpty) {
        for (var imagePath in imageUrls) {
          try {
            // Kiểm tra xem ảnh đã được cache chưa
            final cachedPath = _imageCache[imagePath] ?? imagePath;
            final imagePart = await fileToPart('image/jpeg', cachedPath);
            parts.add(imagePart);
          } catch (e) {
            print('Lỗi khi xử lý ảnh $imagePath: $e');
          }
        }
      }

      final content = Content.multi(parts);
      String fullResponse = "";
      
      final responseStream = _chatSession!.sendMessageStream(content);
      
      final userMessage = Message(
        text: query,
        isUser: true,
        images: imageUrls ?? [],
      );
      
      // Cập nhật lịch sử chat
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
      
      // Lưu tin nhắn AI vào lịch sử
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

  // Thêm hàm helper để chuyển đổi File thành DataPart
  Future<DataPart> fileToPart(String mimeType, String path) async {
    return DataPart(mimeType, await File(path).readAsBytes());
  }

  // Cập nhật hàm upload ảnh để lưu vào bộ đệm
  Future<List<String>> uploadImages(List<File> images) async {
    List<String> cachedPaths = [];
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/chat_images');
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      for (var image in images) {
        final fileName = path.basename(image.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newFileName = '${timestamp}_$fileName';
        final targetPath = '${imageDir.path}/$newFileName';
        
        // Sao chép ảnh vào thư mục ứng dụng
        final newFile = await image.copy(targetPath);
        
        // Lưu vào cache
        _imageCache[image.path] = newFile.path;
        cachedPaths.add(newFile.path);
      }
      
      return cachedPaths;
    } catch (e) {
      print('Lỗi khi lưu ảnh: $e');
      // Nếu có lỗi, trả về đường dẫn gốc
      return images.map((file) => file.path).toList();
    }
  }
  
  // Thêm hàm để xóa ảnh cũ
  Future<void> cleanupOldImages({int maxAgeDays = 30}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/chat_images');
      
      if (!await imageDir.exists()) return;
      
      // Lấy tất cả lịch sử trò chuyện để kiểm tra ảnh đang sử dụng
      final allChatHistories = await Preferences.getChatHistories();
      
      // Thu thập tất cả các đường dẫn ảnh đang được sử dụng
      final Set<String> usedImagePaths = {};
      for (final history in allChatHistories) {
        for (final message in history.messages) {
          usedImagePaths.addAll(message.images);
        }
      }
      
      final now = DateTime.now();
      final files = await imageDir.list().toList();
      
      for (final entity in files) {
        if (entity is File) {
          final filePath = entity.path;
          
          // Bỏ qua file nếu nó đang được sử dụng trong bất kỳ cuộc trò chuyện nào
          if (usedImagePaths.contains(filePath)) {
            continue;
          }
          
          // Xóa file cũ nếu vượt quá thời gian maxAgeDays
          final fileName = path.basename(filePath);
          // Kiểm tra xem tên file có timestamp không
          if (fileName.contains('_')) {
            final timestampStr = fileName.split('_').first;
            if (int.tryParse(timestampStr) != null) {
              final timestamp = int.parse(timestampStr);
              final fileDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final difference = now.difference(fileDate).inDays;
              
              if (difference > maxAgeDays) {
                await entity.delete();
              }
            }
          }
        }
      }
    } catch (e) {
      print('Lỗi khi xóa ảnh cũ: $e');
    }
  }
  
  // Cập nhật hàm lưu lịch sử chat
  Future<void> saveChatHistory() async {
    if (_currentChatHistory != null) {
      await Preferences.saveChatHistoryItem(_currentChatHistory!);
    }
  }
  
  // Thêm hàm để lấy ảnh từ cache
  String? getCachedImagePath(String originalPath) {
    return _imageCache[originalPath];
  }

  // Chuẩn bị thư mục ảnh và dọn dẹp ảnh cũ khi khởi động
  Future<void> _prepareImageDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/chat_images');
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      // Dọn dẹp ảnh cũ khi khởi động
      await cleanupOldImages();
    } catch (e) {
      print('Lỗi khi chuẩn bị thư mục ảnh: $e');
    }
  }
} 