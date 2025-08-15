import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class _ProxyHttpOverrides extends HttpOverrides {
  final String proxyHostPort;
  final bool allowBadCertificate;
  _ProxyHttpOverrides(this.proxyHostPort, {this.allowBadCertificate = false});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY ' + proxyHostPort + ';';
    if (allowBadCertificate) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}

void main() async {
  print("🧪 开始测试DeepSeek AI聊天功能...");

  // 直接从.env文件读取配置
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print("❌ 错误: .env文件不存在");
    return;
  }

  final envContent = await envFile.readAsString();
  final envLines = envContent.split('\n');

  String? apiKey;
  String? apiEndpoint;
  // 代理相关
  bool useProxy = false;
  String? proxyHost;
  String? proxyPort;
  bool insecure = false;

  for (final line in envLines) {
    final l = line.trim();
    if (l.startsWith('DEEPSEEK_API_KEY=')) {
      apiKey = l.split('=')[1].trim();
    } else if (l.startsWith('DEEPSEEK_API_ENDPOINT=')) {
      apiEndpoint = l.split('=')[1].trim();
    } else if (l.startsWith('USE_HTTP_PROXY=')) {
      final v = l.split('=')[1].trim().toLowerCase();
      useProxy = (v == '1' || v == 'true' || v == 'yes' || v == 'on');
    } else if (l.startsWith('HTTP_PROXY=')) {
      final hp = l.split('=')[1].trim();
      if (hp.isNotEmpty && hp.contains(':')) {
        proxyHost = hp.split(':')[0];
        proxyPort = hp.split(':')[1];
      }
    } else if (l.startsWith('HTTP_PROXY_HOST=')) {
      proxyHost = l.split('=')[1].trim();
    } else if (l.startsWith('HTTP_PROXY_PORT=')) {
      proxyPort = l.split('=')[1].trim();
    } else if (l.startsWith('HTTP_PROXY_INSECURE=')) {
      final v = l.split('=')[1].trim().toLowerCase();
      insecure = (v == '1' || v == 'true' || v == 'yes' || v == 'on');
    }
  }

  print("🔑 API密钥: ${apiKey?.substring(0, 10)}...");
  print("🌐 API端点: $apiEndpoint");

  if (useProxy && proxyHost != null && proxyHost!.isNotEmpty && proxyPort != null && proxyPort!.isNotEmpty) {
    // 仅在此脚本内设置代理
    HttpOverrides.global = _ProxyHttpOverrides('$proxyHost:$proxyPort', allowBadCertificate: insecure);
    print("🌐 已启用测试脚本代理 -> $proxyHost:$proxyPort, 允许自签: $insecure");
  }

  if (apiKey == null || apiKey.isEmpty) {
    print("❌ 错误: API密钥未配置");
    return;
  }

  if (apiEndpoint == null || apiEndpoint.isEmpty) {
    apiEndpoint = 'https://api.deepseek.com/v1/chat/completions';
  }

  // 测试消息
  final testMessage = "你好，我今天心情不太好，能陪我聊聊吗？";
  print("\n📝 测试消息: $testMessage");

  try {
    print("\n⏳ 正在调用DeepSeek API...");

    // 构建请求体
    final requestBody = {
      "model": "deepseek-chat",
      "messages": [
        {
          "role": "system",
          "content": "你是一只温柔可爱的猫咪，名叫小橘。你有着孟加拉猫的活泼性格，总是用温暖的话语安慰主人。请用猫咪的口吻回复，适当加入一些猫咪的表情和动作描述。"
        },
        {
          "role": "user",
          "content": testMessage
        }
      ],
      "temperature": 0.8,
      "max_tokens": 1000,
      "stream": false,
    };

    final response = await http.post(
      Uri.parse(apiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 15));

    print("📡 响应状态码: ${response.statusCode}");

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final replyContent = responseData['choices'][0]['message']['content'];

      print("\n✅ AI回复成功!");
      print("💬 回复内容: $replyContent");

      // 检查使用情况
      if (responseData['usage'] != null) {
        final usage = responseData['usage'];
        print("📊 Token使用情况:");
        print("   - 输入tokens: ${usage['prompt_tokens']}");
        print("   - 输出tokens: ${usage['completion_tokens']}");
        print("   - 总计tokens: ${usage['total_tokens']}");
      }

    } else {
      print("❌ API调用失败");
      print("📡 状态码: ${response.statusCode}");
      print("📄 响应内容: ${response.body}");

      // 分析错误原因
      if (response.statusCode == 401) {
        print("🔍 建议: API密钥无效，请检查DEEPSEEK_API_KEY");
      } else if (response.statusCode == 429) {
        print("🔍 建议: 请求频率过高，请稍后重试");
      } else if (response.statusCode == 500) {
        print("🔍 建议: 服务器内部错误，请稍后重试");
      } else if (response.statusCode == 403) {
        print("🔍 建议: 权限不足/Key 权限问题");
      }
    }

  } catch (e, st) {
    print("\n❌ 请求失败: $e");

    final es = e.toString();
    if (es.contains('TimeoutException')) {
      print("🔍 建议: 网络连接超时，请检查网络连接或代理");
    } else if (es.contains('SocketException')) {
      print("🔍 建议: 网络连接失败，请检查网络设置和代理配置");
    } else if (es.contains('HandshakeException')) {
      print("🔍 建议: TLS 握手失败，若为开发环境可在 .env 配置 HTTP_PROXY_INSECURE=true 试试");
    } else {
      print("🔍 建议: 查看详细错误信息进行排查");
    }
    // 打印调用栈便于定位
    print(st);
  }

  print("\n🏁 测试完成");
}
