import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/preferences.dart';
import '../utils/ai_service.dart';
import '../utils/theme_manager.dart';

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

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      case ThemeMode.system:
        return 'Hệ thống';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần Giao diện
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giao diện',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Chế độ giao diện'),
                              subtitle: Text(_getThemeModeText(themeManager.themeMode)),
                              trailing: DropdownButton<ThemeMode>(
                                value: themeManager.themeMode,
                                onChanged: (ThemeMode? newMode) {
                                  if (newMode != null) {
                                    themeManager.setThemeMode(newMode);
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: ThemeMode.system,
                                    child: Text('Hệ thống'),
                                  ),
                                  DropdownMenuItem(
                                    value: ThemeMode.light,
                                    child: Text('Sáng'),
                                  ),
                                  DropdownMenuItem(
                                    value: ThemeMode.dark,
                                    child: Text('Tối'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Phần API Key
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
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
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveApiKey,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Lưu API Key'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Phần hướng dẫn
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hướng dẫn:',
                              style: TextStyle(
                                fontSize: 18,
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
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 