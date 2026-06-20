import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';

class AiChatService {
  final FirebaseFirestore _firestore;

  // ── API Keys ──────────────────────────────────────────────────────
  static const String _groqKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static const String _deepSeekKey = String.fromEnvironment(
    'DEEPSEEK_API_KEY',
    defaultValue: '',
  );

  static const String _openAiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  AiChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> getAiResponse(List<ChatMessageModel> history) async {
    final productsContext = await _fetchProductsContext();
    final storesContext = await _fetchStoresContext();
    final systemPrompt = _buildSystemPrompt(productsContext, storesContext);

    // ── Strategy: Groq → DeepSeek → OpenAI fallback ──────────────────
    try {
      return await _callOpenAICompatible(
        apiKey: _groqKey,
        baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
        model: 'llama-3.3-70b-versatile',
        systemPrompt: systemPrompt,
        history: history,
      );
    } catch (groqError) {
      try {
        return await _callOpenAICompatible(
          apiKey: _deepSeekKey,
          baseUrl: 'https://api.deepseek.com/v1/chat/completions',
          model: 'deepseek-chat',
          systemPrompt: systemPrompt,
          history: history,
        );
      } catch (deepSeekError) {
        try {
          return await _callOpenAICompatible(
            apiKey: _openAiKey,
            baseUrl: 'https://api.openai.com/v1/chat/completions',
            model: 'gpt-4o-mini',
            systemPrompt: systemPrompt,
            history: history,
          );
        } catch (openAiError) {
          return 'Đã xảy ra lỗi kết nối AI. Vui lòng thử lại sau.\n'
              '(Groq: $groqError)\n'
              '(DeepSeek: $deepSeekError)\n'
              '(OpenAI: $openAiError)';
        }
      }
    }
  }

  // ── Generic OpenAI-compatible call ────────────────────────────────
  Future<String> _callOpenAICompatible({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<ChatMessageModel> history,
  }) async {
    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];
    for (final msg in history) {
      messages.add({
        'role': msg.isAdmin ? 'assistant' : 'user',
        'content': msg.text,
      });
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.5,
        'max_tokens': 1024,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final content = json['choices']?[0]?['message']?['content'] as String?;
      if (content != null && content.isNotEmpty) return content.trim();
      throw Exception('Empty response from $model');
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      final msg = err['error']?['message'] ?? response.body;
      throw Exception('[$model] ${response.statusCode}: $msg');
    }
  }

  // ── Firestore context fetchers ─────────────────────────────────────
  Future<String> _fetchProductsContext() async {
    try {
      final snap = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return '- Sản phẩm: ${d['name']}\n'
            '  ID: ${doc.id}\n'
            '  Thương hiệu: ${d['brand']}\n'
            '  Giá: ${d['basePrice']} VNĐ\n'
            '  Mô tả: ${d['description']}\n'
            '  Kích cỡ có sẵn: ${(d['availableSizes'] as List?)?.join(', ')}\n'
            '  Màu sắc: ${(d['colors'] as List?)?.join(', ')}\n'
            '  Tồn kho: ${d['stock']} đôi\n'
            '  Đánh giá: ${d['averageRating'] ?? 'Chưa có'} (${d['reviewCount'] ?? 0} đánh giá)';
      }).join('\n\n');
      return list.isNotEmpty ? list : 'Hiện không có sản phẩm nào trong kho.';
    } catch (_) {
      return 'Không thể tải danh sách sản phẩm.';
    }
  }

  Future<String> _fetchStoresContext() async {
    try {
      final snap = await _firestore.collection('stores').get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return '- Cửa hàng: ${d['name']}\n'
            '  Địa chỉ: ${d['address']}\n'
            '  Điện thoại: ${d['phone'] ?? 'Không có'}';
      }).join('\n\n');
      return list.isNotEmpty ? list : 'Hiện không có thông tin chi nhánh.';
    } catch (_) {
      return 'Không thể tải thông tin chi nhánh.';
    }
  }

  String _buildSystemPrompt(String productsContext, String storesContext) {
    return 'Bạn là trợ lý ảo thân thiện và lịch sự của cửa hàng giày trực tuyến "Shoes X".\n'
        'Nhiệm vụ của bạn là tư vấn khách hàng về sản phẩm, kích cỡ, thương hiệu và thông tin chi nhánh cửa hàng.\n\n'
        'DỮ LIỆU TỪ HỆ THỐNG:\n'
        '--- DANH SÁCH SẢN PHẨM ---\n'
        '$productsContext\n\n'
        '--- CHI NHÁNH CỬA HÀNG ---\n'
        '$storesContext\n\n'
        'QUY TẮC BẮT BUỘC:\n'
        '1. CHỈ trả lời dựa trên dữ liệu sản phẩm và chi nhánh được cung cấp ở trên.\n'
        '2. KHÔNG bịa đặt tên sản phẩm, kích cỡ, màu sắc, giá cả hay địa chỉ chi nhánh không có trong dữ liệu.\n'
        '3. Nếu khách hỏi ngoài phạm vi (toán học, lập trình, nấu ăn, v.v...), hãy từ chối lịch sự: '
        '"Tôi là trợ lý ảo của Shoes X. Tôi chỉ có thể hỗ trợ thông tin về sản phẩm giày, chi nhánh và dịch vụ của Shoes X."\n'
        '4. Gợi ý sản phẩm phù hợp với nhu cầu của khách (kèm tên và giá).\n'
        '5. Trả lời bằng tiếng Việt.';
  }

  Future<void> seedApiKeyToDatabase() async {
    // Keys now loaded from compile-time env variables only
  }
}
