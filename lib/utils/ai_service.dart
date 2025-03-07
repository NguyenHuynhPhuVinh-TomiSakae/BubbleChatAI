class AiService {
  Future<String> generateResponse(String query) async {
    // Giả lập phản hồi từ AI
    await Future.delayed(const Duration(seconds: 1));
    
    if (query.toLowerCase().contains('xin chào') || query.toLowerCase().contains('hello')) {
      return 'Xin chào! Tôi có thể giúp gì cho bạn?';
    } else if (query.toLowerCase().contains('thời tiết')) {
      return 'Tôi không có khả năng kiểm tra thời tiết hiện tại. Bạn có thể hỏi tôi điều gì khác không?';
    } else if (query.toLowerCase().contains('flutter')) {
      return 'Flutter là framework UI của Google để xây dựng ứng dụng đa nền tảng từ một codebase duy nhất.';
    } else {
      return 'Cảm ơn câu hỏi của bạn. Tôi là một AI giả lập đơn giản, vì vậy khả năng của tôi còn hạn chế.';
    }
  }
} 