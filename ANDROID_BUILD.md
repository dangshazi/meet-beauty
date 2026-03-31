# Android 打包指南

## 基本信息

| 配置项 | 值 |
|--------|-----|
| Application ID | `com.meetbeauty.meet_beauty` |
| Min SDK | Flutter 默认（API 21 / Android 5.0） |
| Target SDK | Flutter 默认（API 34 / Android 14） |
| Compile SDK | Flutter 默认（API 34） |
| Kotlin JVM Target | Java 17 |
| Flutter SDK | 3.38.10 |
| Dart SDK | ^3.10.0 |

## 构建命令

### Debug APK（开发/调试用）

```bash
flutter build apk --debug --no-tree-shake-icons
```

- 输出：`build/app/outputs/flutter-apk/app-debug.apk`
- 体积：约 **182 MB**（包含调试符号、Dart VM、三架构合一）
- 用途：开发测试，支持热重载

### Release APK（分架构，推荐）

```bash
flutter build apk --release --split-per-abi --no-tree-shake-icons
```

- 输出目录：`build/app/outputs/flutter-apk/`

| 架构 | 文件名 | 体积 | 适用场景 |
|------|--------|------|---------|
| arm64-v8a | `app-arm64-v8a-release.apk` | ~30.7 MB | 现代手机（推荐） |
| armeabi-v7a | `app-armeabi-v7a-release.apk` | ~25.1 MB | 老旧 32 位设备 |
| x86_64 | `app-x86_64-release.apk` | ~33.3 MB | Android 模拟器 |

### Release APK（合并架构，单包）

```bash
flutter build apk --release --no-tree-shake-icons
```

- 输出：`build/app/outputs/flutter-apk/app-release.apk`
- 体积：约 **80-90 MB**（包含所有架构）

### App Bundle（Google Play 发布用）

```bash
flutter build appbundle --release
```

- 输出：`build/app/outputs/bundle/release/app-release.aab`
- Google Play 会自动按用户设备分发最小包

## 安装方式

```bash
# USB 连接设备后直接安装
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 或用 flutter install
flutter install -d <device-id>

# 查看可用设备
flutter devices
```

## 签名配置

当前 Release 构建使用 **debug 签名**（仅用于测试）：

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

正式发布前需要配置正式签名，参考 [Flutter 官方文档](https://docs.flutter.dev/deployment/android#signing-the-app)。

---

## 踩坑记录

### 1. Font subsetting 崩溃（exit code -9）

**现象**：

```
Target aot_android_asset_bundle failed: IconTreeShakerException: Font subsetting failed with exit code -9.
BUILD FAILED
```

**原因**：Flutter 的图标字体裁剪器（Icon Tree Shaker）在处理 Material Icons 时内存溢出或崩溃，常见于包含大量图标引用的项目。

**解决**：构建时加 `--no-tree-shake-icons` 参数：

```bash
flutter build apk --release --no-tree-shake-icons
```

**代价**：APK 中 Material Icons 字体不会被裁剪，体积增加约 1-2 MB，影响可忽略。

### 2. Release 构建耗时极长

**现象**：首次 Release 构建 Gradle 阶段耗时超过 5 分钟，看起来像卡住了。

**原因**：
- Google ML Kit (`google_mlkit_face_detection`) 包含大量原生 C++ 库，编译慢
- AOT（Ahead-of-Time）编译需要为每个 CPU 架构生成机器码
- Gradle Daemon 冷启动开销

**应对**：
- 首次构建耐心等待（5-10 分钟正常）
- 后续增量构建会快很多（1-2 分钟）
- 用 `--split-per-abi` 减少单次 AOT 编译量
- 构建前关闭 Android 模拟器可释放内存

### 3. Provider 泛型类型擦除

**现象**：

```
ProviderNotFoundException: Error: Could not find the correct Provider<AnalysisController>
above this Consumer<AnalysisController> Widget
```

进入 Analysis 页面时报错，所有 `context.read<XxxController>()` 调用失败。

**原因**：`AppConfig.providers` 原来声明为 `List<ChangeNotifierProvider<ChangeNotifier>>`，导致所有 Provider 的具体泛型类型被擦除为 `ChangeNotifier`。`context.read<AnalysisController>()` 在 widget 树中只能找到 `Provider<ChangeNotifier>`，而非 `Provider<AnalysisController>`。

**修复**：改用 `List<SingleChildWidget>` 并显式指定每个 Provider 的泛型：

```dart
// 错误写法 — 类型擦除
static final List<ChangeNotifierProvider<ChangeNotifier>> providers = [
  ChangeNotifierProvider(create: (_) => AnalysisController()),
];

// 正确写法 — 保留具体类型
static final List<SingleChildWidget> providers = [
  ChangeNotifierProvider<AnalysisController>(
      create: (_) => AnalysisController()),
];
```

### 4. 模拟器无前置摄像头

**现象**：进入 Face Analysis 页面后显示 "Initializing camera..." 或 Camera Error。

**原因**：Android 模拟器默认只有后置虚拟摄像头，App 代码优先查找前置摄像头。

**应对**：
- 在真机上测试摄像头和人脸检测功能
- 集成测试使用 Mock 层绕过真实摄像头（参见 `TESTING.md`）
- 可在 Android Studio → AVD Manager → 高级设置中启用 Front Camera

### 5. Hot Reload 后 Provider 失效

**现象**：代码修改后执行 Hot Reload（`r` 键），部分页面报 `ProviderNotFoundException`。

**原因**：Hot Reload 保留旧的 widget 树状态，但新代码可能改变了 Provider 注册或类型签名，导致不一致。

**解决**：遇到 Provider 相关错误时，执行 **Hot Restart**（`R` 键）或完全重启 App（`q` 后重新 `flutter run`）。

---

## 注意事项

### Debug vs Release APK 体积对比

| 类型 | 体积 | 倍数 |
|------|------|------|
| Debug（合一） | ~182 MB | 基准 |
| Release（合一） | ~80-90 MB | 0.5x |
| Release（arm64 分包） | ~30.7 MB | 0.17x |

Debug 包大的原因：
- 包含完整 Dart VM（支持 JIT 和热重载）
- 包含调试符号和 source maps
- 原生库未压缩、未 ProGuard 优化
- 合并了 arm + arm64 + x86_64 三架构

### ML Kit 对 APK 体积的影响

`google_mlkit_face_detection` 是 APK 体积的主要来源（~20 MB 原生库）。这是设备端 AI 推理的代价，无法进一步压缩。如果未来需要减小体积，可考虑：
- 使用 App Bundle 格式发布（Google Play 自动裁剪无用架构）
- 使用 Dynamic Feature Modules 按需下载 ML Kit 模型

### 签名注意事项

- 当前 Release 使用 debug 签名，**仅限测试分发**
- debug 签名的 APK 无法上传 Google Play
- 正式发布前需要生成 keystore 并配置 `key.properties`
- **keystore 文件和密码不要提交到 Git**
