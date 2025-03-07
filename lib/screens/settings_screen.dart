import 'package:flutter/material.dart';
import '../utils/preferences.dart';
import '../utils/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  final AiService aiService;
  
  const SettingsScreen({super.key, required this.aiService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }
  
  Future<void> _loadApiKey() async {
    final apiKey = await Preferences.getApiKey();
    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _isLoading = false;
    });
  }
  
  Future<void> _saveApiKey() async {
    setState(() {
      _isLoading = true;
    });
    
    await widget.aiService.updateApiKey(_apiKeyController.text);
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key đã được lưu')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini API Key',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      hintText: 'Nhập API key của bạn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveApiKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Lưu API Key'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hướng dẫn:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Truy cập https://aistudio.google.com/app/apikey\n'
                    '2. Đăng ký tài khoản và tạo API key\n'
                    '3. Sao chép và dán API key vào ô trên\n'
                    '4. Nhấn "Lưu API Key"',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
    );
  }
} 