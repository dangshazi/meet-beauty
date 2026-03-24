# AI 化妆教学 APP MVP 技术方案

## 1. 文档信息
- 产品名称：AI 化妆教学 APP
- 文档版本：V1.0
- 文档日期：2026-03-24
- 文档类型：MVP 技术方案
- 对应文档：[PRD-AI化妆教学APP.md](/Users/mingkun.li/Documents/code/sideline/meet-beauty/PRD-AI化妆教学APP.md)
- 对应文档：[开发任务清单-AI化妆教学APP.md](/Users/mingkun.li/Documents/code/sideline/meet-beauty/开发任务清单-AI化妆教学APP.md)

## 2. 方案目标
本方案服务于 MVP 首版落地，目标是以尽量低的实现复杂度，完成以下能力：
- 实时相机预览
- 人脸关键点检测
- 基于关键点的面部特征分析
- 基于规则的妆容推荐
- 基于 2D overlay 的 AR 教学
- 基于规则的轻量评分与反馈

本方案不追求首版的真实感极致和专业审美判断，而是优先保证：
- 主流程跑通
- 实时性能可接受
- 结构清晰，后续能升级

## 3. 技术选型
### 3.1 客户端框架
- Flutter

原因：
- 一套代码覆盖 iOS 和 Android
- 适合快速搭建 MVP
- UI 层、状态管理和页面迭代效率高

### 3.2 视觉能力
- MediaPipe Face Mesh
- OpenCV 或自定义几何算法

用途：
- Face Mesh 负责输出面部关键点
- OpenCV 或自定义算法负责 polygon、mask、颜色覆盖和简单规则判断

### 3.3 数据与配置
- 本地 JSON 或 Dart 常量配置

用途：
- 存储妆容模板
- 存储推荐规则阈值
- 存储步骤文案和颜色参数

### 3.4 后端策略
- MVP 默认不依赖后端

原因：
- 优先采用端侧处理，降低成本和隐私风险
- 减少联调复杂度和网络不稳定影响
- 便于快速演示和早期测试

## 4. 总体架构
```text
UI Layer
  ├─ Home Page
  ├─ Analysis / Recommendation Page
  ├─ Tutorial Camera Page
  └─ Result Page

Application Layer
  ├─ Tutorial Controller
  ├─ Analysis Controller
  ├─ Recommendation Engine
  └─ Scoring Engine

Domain Layer
  ├─ Face Landmark Model
  ├─ Face Feature Model
  ├─ Makeup Profile Model
  ├─ Tutorial Step Model
  └─ Score Result Model

Infra Layer
  ├─ Camera Service
  ├─ Face Mesh Service
  ├─ Overlay Renderer
  ├─ Local Config Repository
  └─ Event Logger
```

## 5. 核心模块设计
### 5.1 Camera Service
职责：
- 管理相机权限申请
- 管理相机初始化与销毁
- 输出预览流给 UI
- 输出图像帧给 Face Mesh Service

输入：
- 相机启停命令
- 页面生命周期事件

输出：
- CameraPreview 数据流
- 图像帧数据

关键点：
- 不要对每一帧都做全量分析，需要做采样或节流
- 页面切后台时要及时释放资源
- 要兼顾 iOS/Android 不同相机方向和镜像问题

### 5.2 Face Mesh Service
职责：
- 接收图像帧
- 调用 MediaPipe Face Mesh
- 返回 landmarks、脸部姿态和置信度

输出数据建议：
- `List<FacePoint>`
- `faceDetected: bool`
- `trackingConfidence: double`
- `timestamp`

关键点：
- 对低置信度结果做过滤
- 对抖动点做平滑处理
- 对无脸、多人脸、遮挡情况做状态识别

### 5.3 Feature Analysis Engine
职责：
- 将 landmarks 转换为可解释的面部特征
- 输出推荐模块所需标签

示例特征：
- 脸长宽比
- 下巴收窄程度
- 唇厚比
- 肤色基础分类

实现方式：
- 基于 landmarks 计算几何比例
- 基于面部 ROI 做简单颜色统计
- 不做训练模型和复杂分类器

输出模型示例：
```text
FaceFeatureResult
- faceShape: round | long | oval | unknown
- skinTone: cool | warm | neutral | unknown
- lipType: thin | medium | full | unknown
- confidenceLevel: low | medium | high
```

### 5.4 Recommendation Engine
职责：
- 根据 Feature Analysis 的结果返回妆容模板
- 返回推荐理由和教学入口参数

实现方式：
- 规则表驱动
- 支持阈值配置
- 支持兜底模板

示例规则：
```text
if faceShape == round and skinTone == warm
  -> recommendation = natural_lift_blush

if lipType == thin
  -> recommendation = gradient_lip_daily
```

设计原则：
- 必须始终有兜底结果
- 推荐结果要可解释
- 推荐失败时允许用户手动选择模板

### 5.5 Overlay Renderer
职责：
- 根据当前教学步骤与 landmarks 绘制 overlay
- 将口红、腮红等区域叠加到相机画面上
- 负责可视化高亮和颜色透明度控制

渲染对象：
- 唇部 polygon
- 左右腮红区域 polygon 或椭圆区域
- 当前步骤引导线或高亮描边

技术策略：
- 首版优先使用 Flutter Canvas / CustomPainter 或原生图层 overlay
- 不引入复杂 3D 渲染
- 每帧只重绘当前步骤需要的区域

关键点：
- 需要做 polygon 点位平滑，避免轮廓跳动
- 需要保证文案层和渲染层不互相遮挡
- 腮红区域可以先使用规则计算的简化形状，不追求极高拟真

### 5.6 Tutorial Controller
职责：
- 管理教学状态机
- 切换步骤、驱动文案、控制 overlay 参数
- 记录用户是否完成某一步

状态建议：
```text
idle -> analyzing -> recommended -> tutorial_running -> tutorial_completed -> result_ready
```

步骤状态建议：
```text
not_started -> active -> completed -> skipped
```

关键点：
- 流程推进由用户触发，避免自动跳步
- 每个步骤都要能重试
- 模板切换后要重建教学会话

### 5.7 Scoring Engine
职责：
- 在教学完成后给出轻量反馈
- 输出结构化评分和建议

MVP 可做规则：
- 覆盖率：overlay 目标区域与检测区域的匹配程度
- 越界率：颜色或目标区域外扩程度
- 完成度：是否完成每个步骤

输出示例：
```text
ScoreResult
- score: 82
- stars: 4
- tags: ["coverage_good", "slightly_outside_boundary"]
- encouragement: "整体不错，已经很接近目标区域了"
- suggestion: "腮红可以再轻一点，范围再集中一些"
```

关键点：
- 如果评分置信度不够，优先输出中性建议
- 不对用户外貌做结论
- 可先将评分能力设计成独立模块，便于后续替换为模型

## 6. 页面与数据流
### 6.1 首页
数据流：
- 用户点击开始学习
- 跳转分析页或直接进入模板选择

依赖模块：
- Local Config Repository
- Navigation Router

### 6.2 分析/推荐页
数据流：
- Camera Service 提供图像帧
- Face Mesh Service 输出 landmarks
- Feature Analysis Engine 计算特征
- Recommendation Engine 输出推荐模板
- 用户点击开始学习进入教学页

### 6.3 教学页
数据流：
- Tutorial Controller 激活当前步骤
- Overlay Renderer 根据步骤渲染对应区域
- 用户点击下一步推进状态机
- 完成后进入结果页

### 6.4 结果页
数据流：
- Scoring Engine 输出结果
- 页面展示分数、建议和再练按钮
- 用户进入下一轮练习或返回推荐页

## 7. 建议目录结构
```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    utils/
    logger/
  features/
    home/
      presentation/
    analysis/
      presentation/
      application/
      domain/
    recommendation/
      application/
      domain/
      data/
    tutorial/
      presentation/
      application/
      domain/
    result/
      presentation/
      application/
  services/
    camera/
    facemesh/
    overlay/
  shared/
    widgets/
    models/
    config/
```

## 8. 数据模型建议
### 8.1 FacePoint
```text
FacePoint
- x
- y
- z
```

### 8.2 FaceFeatureResult
```text
FaceFeatureResult
- faceShape
- skinTone
- lipType
- ratios
- confidenceLevel
```

### 8.3 MakeupProfile
```text
MakeupProfile
- id
- name
- category
- lipColor
- blushColor
- tutorialSteps
- recommendationReasons
```

### 8.4 TutorialStep
```text
TutorialStep
- id
- title
- instruction
- targetRegion
- overlayStyle
- order
```

### 8.5 ScoreResult
```text
ScoreResult
- score
- stars
- feedbackTags
- encouragement
- suggestion
```

## 9. 关键算法说明
### 9.1 唇部区域计算
方案：
- 使用 Face Mesh 中的唇部关键点集合构建 polygon
- 对 polygon 做闭合和平滑
- 使用填充颜色和透明度绘制唇部区域

MVP 注意点：
- 不追求纹理级真实感
- 重点是教学高亮和位置指示

### 9.2 腮红区域计算
方案：
- 基于脸颊和鼻翼、眼下位置的相对关系计算左右腮红中心点
- 根据脸型决定区域更偏圆形、椭圆形或上提方向
- 首版可以使用椭圆区域代替真实刷痕

MVP 注意点：
- 位置正确性优先于形状真实感
- 可以根据推荐模板调整角度和大小

### 9.3 脸型分类
方案：
- 计算脸长、脸宽、下颌宽、额头宽等比例
- 用阈值规则判定圆脸、长脸、椭圆脸等基础类型

MVP 注意点：
- 不追求学术严谨分类
- 分类结果只用于推荐参考

### 9.4 肤色分类
方案：
- 在额头或面颊 ROI 计算平均色值
- 转换到简单暖/冷/中性分类

MVP 注意点：
- 易受光照影响，需要容忍 unknown 结果
- 分类失败时使用中性兜底模板

### 9.5 评分逻辑
方案：
- 统计目标区域内的覆盖比例
- 统计超出边界的比例
- 根据结果映射到反馈标签

MVP 注意点：
- 先保证“不误伤”，再追求“更聪明”
- 无法稳定判定时给中性反馈

## 10. 性能优化策略
### 10.1 帧处理节流
- 不对每一帧做完整分析，可按固定间隔处理
- 教学 overlay 可以高频刷新，分析与评分可低频执行

### 10.2 关键点平滑
- 使用滑动平均或指数平滑降低抖动
- 对突变点做异常过滤

### 10.3 渲染优化
- 仅重绘必要区域
- 将静态 UI 与动态 overlay 分层
- 减少不必要的 setState 或全树刷新

### 10.4 生命周期管理
- 页面切后台暂停相机和分析
- 页面销毁时释放 detector、camera 和纹理资源

## 11. 异常与降级方案
### 11.1 无法识别人脸
- 提示用户调整角度和光线
- 允许重试
- 允许跳过分析进入固定模板

### 11.2 推荐失败
- 使用默认模板兜底
- 提示“先从基础日常妆开始”

### 11.3 评分不稳定
- 降级为仅展示完成状态和通用建议
- 不展示具体分数

### 11.4 性能不足
- 降低分析频率
- 降低 overlay 复杂度
- 减少实时特效层级

## 12. 埋点与日志建议
关键埋点：
- app_open
- start_analysis
- analysis_success
- analysis_fail
- recommendation_shown
- tutorial_start
- tutorial_step_complete
- tutorial_finish
- result_retry

错误日志：
- camera_init_error
- permission_denied
- facemesh_error
- overlay_render_error
- scoring_error

## 13. 安全与隐私
- MVP 端侧优先，不默认上传人脸图像
- 仅申请必要的相机权限
- 分析结果仅用于当前会话推荐和教学
- 如后续引入云端能力，需要单独补隐私设计

## 14. 后续升级路径
### Phase 2 以后可升级方向
- 引入更精细的分割模型替代部分 polygon 渲染
- 引入更复杂的脸型和肤色分类器
- 引入手部检测与动作识别
- 引入个性化学习记录
- 引入商品推荐与品牌色号映射

## 15. 技术结论
对 MVP 来说，最稳妥的技术路线是：
- Flutter 做跨平台客户端
- MediaPipe Face Mesh 做关键点定位
- 规则引擎做面部分析和妆容推荐
- 2D overlay 做 AR 教学
- 轻量规则评分做结果反馈

这条路线的优点是：
- 能快速上线验证
- 实现复杂度可控
- 足够支撑“推荐 + 教学”这个差异化卖点
- 后续可以逐步升级成更强的 AI 化妆教练系统
