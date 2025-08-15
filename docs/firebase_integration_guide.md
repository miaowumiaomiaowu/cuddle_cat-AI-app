# Firebase 集成指南

## 🎯 为什么选择 Firebase

### 优势分析
1. **完全免费起步**: Spark计划提供充足的免费额度
2. **一站式服务**: 认证、数据库、存储、推送一体化
3. **实时同步**: 支持多设备数据实时同步
4. **Flutter官方支持**: 完善的Flutter插件生态
5. **自动扩展**: 无需担心服务器维护和扩容

### 免费额度详情
- **Firestore**: 1GB存储 + 50,000读取/天 + 20,000写入/天
- **Authentication**: 无限用户认证
- **Storage**: 1GB文件存储 + 1GB下载/天
- **Cloud Functions**: 125,000次调用/月
- **Hosting**: 10GB存储 + 10GB传输/月

## 📋 集成步骤

### 第一步：Firebase项目设置

#### 1.1 创建Firebase项目
```bash
# 访问 https://console.firebase.google.com/
# 1. 点击"创建项目"
# 2. 输入项目名称：cuddle-cat
# 3. 启用Google Analytics（可选）
# 4. 选择Analytics账户
```

#### 1.2 添加Android应用
```bash
# 1. 点击Android图标
# 2. 输入包名：com.hanjiayi.cuddle_cat
# 3. 输入应用昵称：暖猫
# 4. 下载google-services.json
# 5. 将文件放置到 android/app/ 目录
```

#### 1.3 添加iOS应用
```bash
# 1. 点击iOS图标  
# 2. 输入Bundle ID：com.hanjiayi.cuddle_cat
# 3. 输入应用昵称：暖猫
# 4. 下载GoogleService-Info.plist
# 5. 将文件添加到iOS项目
```

### 第二步：Flutter项目配置

#### 2.1 添加依赖
```yaml
# pubspec.yaml
dependencies:
  # Firebase核心
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_messaging: ^14.7.10
  
  # 认证相关
  google_sign_in: ^6.1.6
  
  # 状态管理
  provider: ^6.1.1
  
  # 本地存储
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
```

#### 2.2 初始化配置
```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

### 第三步：用户认证系统

#### 3.1 认证服务
```dart
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 当前用户
  User? get currentUser => _auth.currentUser;
  
  // 用户状态流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 邮箱注册
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('注册失败: $e');
      return null;
    }
  }

  // 邮箱登录
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('登录失败: $e');
      return null;
    }
  }

  // Google登录
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google登录失败: $e');
      return null;
    }
  }

  // 登出
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
```

#### 3.2 认证状态管理
```dart
// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signInWithEmail(email, password);
    
    _isLoading = false;
    notifyListeners();
    
    return result != null;
  }

  Future<bool> registerWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.registerWithEmail(email, password);
    
    _isLoading = false;
    notifyListeners();
    
    return result != null;
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signInWithGoogle();
    
    _isLoading = false;
    notifyListeners();
    
    return result != null;
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
```

### 第四步：Firestore数据库

#### 4.1 数据模型
```dart
// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }
}
```

#### 4.2 数据库服务
```dart
// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 用户集合引用
  CollectionReference get usersCollection => _db.collection('users');

  // 创建用户文档
  Future<void> createUser(UserModel user) async {
    await usersCollection.doc(user.id).set(user.toFirestore());
  }

  // 获取用户信息
  Future<UserModel?> getUser(String userId) async {
    final doc = await usersCollection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // 更新用户信息
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await usersCollection.doc(userId).update(data);
  }

  // 用户对话记录
  CollectionReference getUserConversations(String userId) {
    return usersCollection.doc(userId).collection('conversations');
  }

  // 用户情绪记录
  CollectionReference getUserEmotions(String userId) {
    return usersCollection.doc(userId).collection('emotions');
  }
}
```

### 第五步：数据同步策略

#### 5.1 离线支持
```dart
// 启用离线持久化
await FirebaseFirestore.instance.enablePersistence();
```

#### 5.2 实时监听
```dart
// 监听用户数据变化
Stream<UserModel?> watchUser(String userId) {
  return usersCollection.doc(userId).snapshots().map((doc) {
    if (doc.exists) {
      return UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  });
}
```

## 🔒 安全规则配置

### Firestore安全规则
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // 子集合规则
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## 📊 成本预估

### 免费额度使用预估
- **1000活跃用户/月**:
  - 读取: ~30,000次/天 (在免费额度内)
  - 写入: ~10,000次/天 (在免费额度内)
  - 存储: ~500MB (在免费额度内)

### 付费升级时机
- 当日读取超过50,000次
- 当日写入超过20,000次  
- 存储超过1GB
- 需要更多云函数调用

## 🚀 部署步骤

1. **开发环境测试**: 使用Firebase模拟器
2. **测试环境部署**: 创建测试项目
3. **生产环境部署**: 配置生产项目
4. **监控和分析**: 启用Firebase Analytics

这个方案可以让你的应用完全免费运行，直到用户规模达到一定程度再考虑付费升级。Firebase的免费额度对于初期发展非常充足！
