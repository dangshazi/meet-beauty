// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get tutorialPreviousStep => '上一步';

  @override
  String get tutorialNextStep => '下一步';

  @override
  String get tutorialComplete => '完成教学';

  @override
  String get tutorialFaceHint => '请将面部对准屏幕';

  @override
  String get tutorialCameraError => '相机初始化失败，请重试';

  @override
  String get tutorialCameraErrorDefault => '相机初始化失败，请重试';

  @override
  String get permissionRequired => '需要相机权限';

  @override
  String get permissionDescription => 'AR 化妆教学需要使用前置摄像头来检测面部区域。请授权相机权限后继续。';

  @override
  String get permissionOpenSettings => '前往设置开启';

  @override
  String get permissionRetry => '重试';

  @override
  String get resultOutOf => '满分 100';

  @override
  String get resultStepsCompleted => '步骤完成';

  @override
  String get resultDuration => '用时';

  @override
  String get resultFaceTracking => '面部追踪';

  @override
  String get resultBackHome => '返回首页';

  @override
  String get resultPracticeAgain => '再练一次';

  @override
  String get scoreExcellent => '太棒了！你的妆容效果非常出色！';

  @override
  String get scoreGood => '做得不错！继续加油你会越来越好。';

  @override
  String get scoreGoodSuggestion => '尝试完成所有步骤以获得更好的效果。';

  @override
  String get scoreNeedsWork => '继续练习吧！熟能生巧。';

  @override
  String get scoreNeedsWorkSuggestion => '请放慢节奏，认真对待每个步骤。';

  @override
  String get scoreTrackingTip => '请保持面部正对镜头，以获得更好的引导效果。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsAccumulateOverlays => '累积妆容效果';

  @override
  String get settingsAccumulateOverlaysDesc => '开启后，进入下一步时保留之前步骤的上妆效果';

  @override
  String get homeTitle => 'Meet Beauty';

  @override
  String get homeSubtitle => 'AI 化妆教练';

  @override
  String get homeFeatureAnalysis => '面部分析';

  @override
  String get homeFeatureAnalysisDesc => '获取个性化化妆建议';

  @override
  String get homeFeatureTutorial => 'AR 教学';

  @override
  String get homeFeatureTutorialDesc => '实时 AR 引导学习';

  @override
  String get homeFeatureScoring => '智能评分';

  @override
  String get homeFeatureScoringDesc => '即时反馈追踪进度';

  @override
  String get homeStartLearning => '开始学习';

  @override
  String get homeChooseStyle => '选择教学风格';

  @override
  String get analysisTitle => '面部分析';

  @override
  String get analysisInitializing => '正在初始化摄像头...';

  @override
  String get analysisAnalyzing => '正在分析面部...';

  @override
  String get analysisYourFeatures => '你的特征';

  @override
  String get analysisFaceShape => '脸型';

  @override
  String get analysisSkinTone => '肤色';

  @override
  String get analysisLipType => '唇形';

  @override
  String get analysisFaceDetected => '检测到面部！点击「拍摄并分析」继续。';

  @override
  String get analysisPositionFace => '请将面部对准摄像头';

  @override
  String get analysisGetRecommendations => '获取建议';

  @override
  String get analysisAnalyzingBtn => '分析中...';

  @override
  String get analysisCaptureAnalyze => '拍摄并分析';

  @override
  String get analysisCameraError => '摄像头错误';

  @override
  String get analysisRetry => '重试';

  @override
  String get analysisCameraPermission => '需要相机权限';

  @override
  String get analysisGrantPermission => '授予权限';

  @override
  String get recTitle => '你的推荐';

  @override
  String get recNoData => '暂无推荐';

  @override
  String get recStartLearning => '开始学习';

  @override
  String get recBasedOnFeatures => '基于你的面部特征';

  @override
  String recSteps(int count) {
    return '$count 步';
  }
}
