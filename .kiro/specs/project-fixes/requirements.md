# 项目修复需求文档

## 介绍

本文档定义了修复cuddle_cat Flutter项目中存在的编译错误、API不匹配和代码质量问题的需求。项目当前存在大量测试失败、使用已弃用API等问题，需要系统性修复以确保项目能够正常运行。

## 需求

### 需求 1: 修复API兼容性问题

**用户故事:** 作为开发者，我希望项目中的所有代码都使用最新的Flutter API，这样项目就不会出现弃用警告。

#### 验收标准

1. WHEN 运行flutter analyze THEN 系统不应显示任何关于withOpacity弃用的警告
2. WHEN 检查所有Dart文件 THEN 所有withValues调用都应替换为withOpacity
3. WHEN 编译项目 THEN 不应出现API兼容性相关的错误

### 需求 2: 修复测试文件API不匹配

**用户故事:** 作为开发者，我希望所有测试文件都与实际实现的API保持一致，这样测试就能正常运行。

#### 验收标准

1. WHEN 运行flutter test THEN Cat模型相关的测试应该通过
2. WHEN 测试TravelProvider THEN 所有方法调用都应与实际实现匹配
3. WHEN 测试服务类 THEN 测试中使用的方法名和参数都应正确
4. WHEN 运行所有测试 THEN 不应出现undefined_method或undefined_getter错误

### 需求 3: 修复模型构造函数参数

**用户故事:** 作为开发者，我希望所有模型类的构造函数参数在测试和实际使用中保持一致，这样就不会出现参数不匹配的错误。

#### 验收标准

1. WHEN 创建Cat实例 THEN 所有必需参数都应正确提供
2. WHEN 创建Travel实例 THEN locationName和mood参数应该是必需的
3. WHEN 测试中使用模型 THEN 不应出现missing_required_argument错误
4. WHEN 使用DialogueMessage THEN 参数类型应该正确匹配

### 需求 4: 修复Provider方法实现

**用户故事:** 作为开发者，我希望所有Provider类都实现了测试中调用的方法，这样状态管理就能正常工作。

#### 验收标准

1. WHEN 调用TravelProvider方法 THEN addTravel、deleteTravel等方法应该存在
2. WHEN 使用CatProvider THEN currentCat属性和相关方法应该可用
3. WHEN 测试Provider功能 THEN 所有公共API都应该实现
4. WHEN 运行状态管理测试 THEN 不应出现方法未定义的错误

### 需求 5: 修复服务类方法实现

**用户故事:** 作为开发者，我希望所有服务类都提供测试中期望的方法，这样业务逻辑就能正常执行。

#### 验收标准

1. WHEN 使用AIService THEN generateResponse和analyzeEmotion方法应该存在
2. WHEN 使用CatService THEN feedCat、petCat、playWithCat等方法应该实现
3. WHEN 使用TravelService THEN saveTravelRecord、loadTravelRecords等方法应该可用
4. WHEN 调用服务方法 THEN 不应出现undefined_method错误

### 需求 6: 修复Widget测试兼容性

**用户故事:** 作为开发者，我希望所有Widget测试都能正确创建和测试组件，这样UI功能就能得到验证。

#### 验收标准

1. WHEN 测试ChatBubble THEN 构造函数参数应该正确
2. WHEN 测试TravelRecordCard THEN 所有必需参数都应提供
3. WHEN 测试CatInteractionPanel THEN Provider依赖应该正确设置
4. WHEN 运行Widget测试 THEN 不应出现参数类型不匹配的错误

### 需求 7: 确保项目可运行性

**用户故事:** 作为开发者，我希望修复所有问题后项目能够成功编译和运行，这样就能进行正常的开发和测试。

#### 验收标准

1. WHEN 运行flutter analyze THEN 不应有任何错误或严重警告
2. WHEN 运行flutter build THEN 项目应该成功编译
3. WHEN 启动应用 THEN 应用应该正常启动并显示主界面
4. WHEN 运行flutter test THEN 大部分测试应该通过或至少不出现编译错误