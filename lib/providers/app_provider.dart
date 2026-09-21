import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clue.dart';
import '../models/material_item.dart';
import '../models/app_user.dart';
import '../data/default_materials.dart';
import '../services/firestore_service.dart';
import '../services/tencent_cloudbase_service.dart';
import '../services/crm_sync_service.dart';
import '../models/initial_real_clues.dart';

/// 全局状态管理 Provider
class AppProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final TencentCloudBaseService _tencentService = TencentCloudBaseService();
  final CrmSyncService _crmSyncService = CrmSyncService();

  // 用户与权限管理
  final List<AppUser> _users = [];
  List<AppUser> get users => List.unmodifiable(_users);

  AppUser? _currentUserObj;
  AppUser? get currentUserObj => _currentUserObj;

  String _currentUser = '';
  String get currentUser => _currentUserObj?.name.isNotEmpty == true
      ? _currentUserObj!.name
      : _currentUser;

  // 权限快捷 Getter
  bool get isSuperAdmin => _currentUserObj?.isSuperAdmin ?? false;
  bool get canManageUsers => _currentUserObj?.canManageUsers ?? false;
  bool get canViewAllClues => _currentUserObj?.canViewAllClues ?? false;
  bool get canExportData => true; // 所有人基础功能一致，可导出各自数据
  bool get canDeleteClues => true;
  bool get canManageMaterials => _currentUserObj?.canManageMaterials ?? false;

  // 线索归属老师筛选（'mine' 默认显示自己的, 'all' 全部, 或指定顾问姓名）
  String _ownerFilter = 'mine';
  String get ownerFilter => _ownerFilter;

  void setOwnerFilter(String filter) {
    _ownerFilter = filter;
    notifyListeners();
  }

  // 届别/年级筛选（'all' 全部, 或指定届别如 '25级'、'24级'）
  String _gradeFilter = 'all';
  String get gradeFilter => _gradeFilter;

  Future<void> setGradeFilter(String filter) async {
    _gradeFilter = filter;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('crm_grade_filter', filter);
    } catch (_) {}
  }

  /// 是否激活了任何高阶筛选条件（届别或顾问）
  bool get hasActiveFilter =>
      (_gradeFilter != 'all' && _gradeFilter.isNotEmpty) ||
      (canViewAllClues && _ownerFilter != 'mine');

  /// 一键重置所有高阶筛选条件（恢复全部届别与默认显示自己）
  Future<void> resetFilters() async {
    _gradeFilter = 'all';
    _ownerFilter = 'mine';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('crm_grade_filter', 'all');
    } catch (_) {}
  }

  // 数据是否已加载完成
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // 云端同步状态
  bool _isCloudConnected = false;
  bool get isCloudConnected => _isCloudConnected;

  String _syncStatus = '正在同步...';
  String get syncStatus => _syncStatus;

  // 是否正在与云端进行数据同步
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  static const Set<String> _mockClueIds = {
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
    '11', '12', '13', '14', '15', 'sync_test_01',
    '1788343427076', '1788197247395', '1788196502601', '1788196332812',
    '1788189895199', '1788186240315', '1788184925476', '1788184879093',
    '1788165706686', '1788164371780', '1788163280908'
  };

  static const Set<String> _mockClueNames = {
    '小雪同学', '李明明', '王小燕', '张大伟', '赵文文',
    '刘思雨', '陈佳佳', '吴晓峰', '林小雨', '周鹏程',
    '苏梦琪', '杨晨曦', '方芳', '谢一鸣', '韩冰冰'
  };

  static bool _isMockClue(Clue c) {
    if (_mockClueIds.contains(c.id)) return true;
    if (c.id.startsWith('sync_test')) return true;
    final nick = c.wxNick.trim();
    if (nick.contains('测试') || nick.contains('郭培杨测试')) return true;
    if (_mockClueNames.contains(nick)) return true;
    return false;
  }

  // 私有线索池
  final List<Clue> _clues = [];
  List<Clue> get clues => List.unmodifiable(_clues);

  // 已删除线索的ID集合（墓碑机制：防止云端拉取刷新时已删线索复活）
  Set<String> _deletedClueIds = {};
  Set<String> get deletedClueIds => Set.unmodifiable(_deletedClueIds);

  // 本地新建且尚未成功上报云端的线索ID集合（用于精准识别自建离线线索，避免历史已删线索死而复生）
  Set<String> _pendingCreationClueIds = {};
  Set<String> get pendingCreationClueIds =>
      Set.unmodifiable(_pendingCreationClueIds);

  // 搜索关键词
  String _searchKeyword = '';
  String get searchKeyword => _searchKeyword;

  // 线索列表当前Tab索引
  int _clueTabIndex = 0;
  int get clueTabIndex => _clueTabIndex;

  StreamSubscription<List<Clue>>? _cluesSubscription;
  StreamSubscription<List<TextMaterial>>? _textMaterialsSubscription;
  Timer? _retryTimer;
  bool _isDisposed = false;

  AppProvider() {
    _init();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    _cluesSubscription?.cancel();
    _textMaterialsSubscription?.cancel();
    super.dispose();
  }

  /// 保存已删除的线索ID集合（持久化墓碑）
  Future<void> _saveDeletedClueIdsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _deletedClueIds.toList();
      if (list.length > 500) {
        list.removeRange(0, list.length - 500);
        _deletedClueIds = list.toSet();
      }
      await prefs.setStringList('crm_deleted_clue_ids', list);
    } catch (e) {
      debugPrint('⚠️ [_saveDeletedClueIdsLocal] 墓碑持久化异常: $e');
    }
  }

  /// 保存本地新建待上报线索ID集合
  Future<void> _savePendingCreationClueIdsLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          'crm_pending_creation_clues', _pendingCreationClueIds.toList());
    } catch (e) {
      debugPrint('⚠️ [_savePendingCreationClueIdsLocal] 持久化异常: $e');
    }
  }

  /// 初始化：加载本地用户、线索、物料并建立同步
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载已删除线索的墓碑记录
    final deletedList = prefs.getStringList('crm_deleted_clue_ids');
    if (deletedList != null) {
      _deletedClueIds = deletedList.toSet();
    }

    // 加载本地自建待上报线索
    final pendingList = prefs.getStringList('crm_pending_creation_clues');
    if (pendingList != null) {
      _pendingCreationClueIds = pendingList.toSet();
    }

    // 1. 初始化用户列表与权限
    final usersJson = prefs.getString('crm_users');
    if (usersJson != null) {
      final list = jsonDecode(usersJson) as List<dynamic>;
      _users.addAll(list.map((e) => AppUser.fromJson(e)));
    }

    // 自动清洗历史遗留测试账号（彻底剔除王主管、张老师、旧郭培杨、旧李老师等）
    const mockUserIds = {
      'usr_manager_wang',
      'usr_advisor_zhang',
      'usr_1788342882634',
      'usr_advisor_li',
      'usr_1788340055423',
    };
    _users.removeWhere((u) => mockUserIds.contains(u.id));
    if (_users.isEmpty) {
      _initDefaultUsers();
    }
    await _saveUsersLocal();

    // 恢复登录态
    final currentUserId = prefs.getString('crm_current_user_id');
    if (currentUserId != null) {
      try {
        final found = _users.firstWhere((u) => u.id == currentUserId);
        if (found.isActive) {
          _currentUserObj = found;
          _currentUser = found.name;
        }
      } catch (_) {}
    }
    // 默认兜底：若未登录，默认激活超级管理员账号，确保权限与筛选与管理员无缝衔接
    if (_currentUserObj == null && _users.isNotEmpty) {
      final defaultAdmin = _users.firstWhere(
        (u) => u.isSuperAdmin && u.isActive,
        orElse: () => _users.first,
      );
      _currentUserObj = defaultAdmin;
      _currentUser = defaultAdmin.name;
    }

    // 🛡️ 核心数据安全防护 1：解除由于远端返回空导致的墓碑误判，确保真实线索绝不受墓碑拦截
    final realSeeds = InitialRealClues.getClues();
    final realSeedIds = realSeeds.map((c) => c.id).toSet();
    _deletedClueIds.removeWhere((id) => realSeedIds.contains(id));
    await _saveDeletedClueIdsLocal();

    // 2. 读本地线索与物料持久化（实现0秒冷启动）
    final cluesJson = prefs.getString('crm_clues');
    final textJson = prefs.getString('crm_text_materials');
    final imageJson = prefs.getString('crm_image_materials');

    if (cluesJson != null) {
      final list = jsonDecode(cluesJson) as List<dynamic>;
      _clues.addAll(list
          .map((e) => Clue.fromJson(e))
          .where((c) => !_isMockClue(c) && !_deletedClueIds.contains(c.id)));
    }

    // 全量清洗并彻底丢弃历史测试线索与演示线索
    _clues.removeWhere((c) => _isMockClue(c) || _deletedClueIds.contains(c.id));

    // 🛡️ 核心数据安全防护 2：若本地旧缓存中的来源为自招、标签为空或缺少聊天截图，与真实种子比对并安全补齐
    final realSeedMap = {for (var s in realSeeds) s.id: s};
    for (int i = 0; i < _clues.length; i++) {
      final localClue = _clues[i];
      final seed = realSeedMap[localClue.id];
      if (seed != null) {
        final bool shouldFixSource =
            (localClue.source.isEmpty || localClue.source == '自招') &&
                seed.source != '自招';
        final bool shouldFixTags =
            localClue.tags.isEmpty && seed.tags.isNotEmpty;
        final bool shouldFixIntent = (localClue.intentLevel == IntentLevel.medium ||
                localClue.intentLevel == IntentLevel.none) &&
            seed.intentLevel == IntentLevel.high &&
            localClue.visitLogs.isEmpty;
        final bool shouldFixNext =
            localClue.nextVisitTime == null && seed.nextVisitTime != null;
        final bool shouldFixAi = (localClue.aiAnalysisReport == null ||
                localClue.aiAnalysisReport!.isEmpty) &&
            seed.aiAnalysisReport != null;

        // 🛡️ 补全聊天截图图片二进制数据
        List<ChatRecord> fixedChats = localClue.chatRecords;
        if (seed.chatRecords.isNotEmpty) {
          bool chatsFixed = false;
          final updatedChats = <ChatRecord>[];
          for (final lc in localClue.chatRecords) {
            // 优先按 ID 匹配，找不到则按 OCR 文本匹配
            final sc = seed.chatRecords.where((s) => s.id == lc.id).firstOrNull ??
                seed.chatRecords
                    .where((s) =>
                        s.ocrText.trim().isNotEmpty &&
                        s.ocrText.trim() == lc.ocrText.trim())
                    .firstOrNull;
            if (sc != null &&
                (lc.imageData == null || lc.imageData!.isEmpty) &&
                (sc.imageData != null && sc.imageData!.isNotEmpty)) {
              updatedChats.add(lc.copyWith(imageData: sc.imageData));
              chatsFixed = true;
            } else {
              updatedChats.add(lc);
            }
          }
          if (localClue.chatRecords.isEmpty && seed.chatRecords.isNotEmpty) {
            updatedChats.addAll(seed.chatRecords);
            chatsFixed = true;
          }
          if (chatsFixed) {
            fixedChats = updatedChats;
          }
        }

        // 🛡️ 本地回访记录业务语义幂等去重（彻底清理差几毫秒的双胞胎重复记录）
        final dedupLogs = <VisitLog>[];
        for (final l in localClue.visitLogs) {
          final isDup = dedupLogs.any((ex) {
            final sameContent = ex.visitContent.trim() == l.visitContent.trim();
            final timeDiff = ex.createTime.difference(l.createTime).inSeconds.abs();
            return sameContent && timeDiff <= 60;
          });
          if (!isDup) {
            dedupLogs.add(l);
          }
        }

        if (shouldFixSource ||
            shouldFixTags ||
            shouldFixIntent ||
            shouldFixNext ||
            shouldFixAi ||
            fixedChats.length != localClue.chatRecords.length ||
            dedupLogs.length != localClue.visitLogs.length) {
          _clues[i] = localClue.copyWith(
            source: shouldFixSource ? seed.source : localClue.source,
            tags: shouldFixTags ? seed.tags : localClue.tags,
            intentLevel:
                shouldFixIntent ? seed.intentLevel : localClue.intentLevel,
            nextVisitTime:
                shouldFixNext ? seed.nextVisitTime : localClue.nextVisitTime,
            aiAnalysisReport:
                shouldFixAi ? seed.aiAnalysisReport : localClue.aiAnalysisReport,
            aiAnalysisTime:
                shouldFixAi ? seed.aiAnalysisTime : localClue.aiAnalysisTime,
            chatRecords: fixedChats,
            visitLogs: dedupLogs,
          );
        }
      }
    }

    // 🛡️ 核心数据安全防护 3：增量补齐种子库中存在但本地缺失的真实线索（消灭冷启动由于本地旧缓存导致的线索缺失与闪烁）
    final localClueIds = _clues.map((c) => c.id).toSet();
    for (final seed in realSeeds) {
      if (!localClueIds.contains(seed.id) && !_deletedClueIds.contains(seed.id)) {
        _clues.add(seed);
      }
    }
    await _saveCluesLocalOnly();

    if (textJson != null) {
      final list = jsonDecode(textJson) as List<dynamic>;
      _textMaterials.addAll(list.map((e) => TextMaterial.fromJson(e)));

      // 自动补全官方8大分类、80条专升本金牌实战话术（增量合并，绝不覆盖已有自建话术）
      final defaultList = DefaultMaterials.getDefaultTextMaterials();
      final existingIds = _textMaterials.map((m) => m.id).toSet();
      bool hasNew = false;
      for (final m in defaultList) {
        if (!existingIds.contains(m.id)) {
          _textMaterials.add(m);
          hasNew = true;
        }
      }
      if (hasNew) {
        _saveMaterials();
      }
    } else {
      _initMockMaterials();
    }

    if (imageJson != null) {
      final list = jsonDecode(imageJson) as List<dynamic>;
      _imageMaterials.addAll(list
          .map((e) => ImageMaterial.fromJson(e))
          .where(_isValidRealImage));
    } else {
      _imageMaterials.clear();
    }
    _saveMaterials();

    if (cluesJson == null) {
      // 首次启动或全新初始化：保持纯净空线索库，供录入真实学员
      _clues.clear();
      _saveCluesLocalOnly();
    }

    // 确保所有线索都有明确归属人，并对历史非标年级（如 24/25/12）与科目进行自动清洗归一
    bool needResave = false;
    final defaultAdvisors = ['超级管理员'];
    int advisorIdx = 0;
    for (final c in _clues) {
      if (c.ownerName.trim().isEmpty) {
        c.ownerName = defaultAdvisors[advisorIdx % defaultAdvisors.length];
        advisorIdx++;
        needResave = true;
      }
      final normG = normalizeGrade(c.grade);
      if (normG != c.grade) {
        c.grade = normG;
        needResave = true;
      }
      if (c.subject == '艺术') {
        c.subject = '美术专业综合';
        needResave = true;
      }
    }
    if (needResave) {
      _saveClues();
    }

    if (_gradeFilter == 'all') {
      _gradeFilter = prefs.getString('crm_grade_filter') ?? 'all';
    }

    _isLoaded = true;
    notifyListeners();

    // 3. 静默建立多端极速同步通道
    _initCloudSync();
  }

  /// 初始化默认用户（仅保留超级管理员）
  void _initDefaultUsers() {
    _users.clear();
    _users.add(
      AppUser(
        id: 'usr_super_admin',
        username: 'admin',
        password: 'admin123',
        name: '超级管理员',
        role: UserRole.superAdmin,
        phone: '13800138000',
        canManageMaterials: true,
        createdBy: '系统初始化',
      ),
    );
  }

  /// 保存用户列表到本地并异步广播到云端同步服务
  Future<void> _saveUsersLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_users.map((u) => u.toJson()).toList());
    await prefs.setString('crm_users', json);
    // 异步同步到云端服务器
    unawaited(_crmSyncService.saveUsers(_users));
  }

  /// 从云端拉取并双向同步员工账号列表
  Future<bool> syncUsersFromCloud() async {
    try {
      final remoteUsers = await _crmSyncService.fetchUsers();
      if (remoteUsers != null && remoteUsers.isNotEmpty) {
        const mockUserIds = {
          'usr_manager_wang',
          'usr_advisor_zhang',
          'usr_1788342882634',
          'usr_advisor_li',
          'usr_1788340055423',
        };
        final cleanRemote =
            remoteUsers.where((u) => !mockUserIds.contains(u.id)).toList();
        final map = {
          for (var u in _users.where((u) => !mockUserIds.contains(u.id)))
            u.id: u
        };
        for (var ru in cleanRemote) {
          map[ru.id] = ru;
        }
        _users.clear();
        _users.addAll(map.values);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'crm_users', jsonEncode(_users.map((u) => u.toJson()).toList()));
        notifyListeners();
        return true;
      } else if (remoteUsers != null && remoteUsers.isEmpty && _users.isNotEmpty) {
        await _crmSyncService.saveUsers(_users);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [SyncUsers] 同步员工账号失败: $e');
    }
    return false;
  }

  // ==================== 账号与权限管理方法 ====================

  /// 登录鉴权（支持智能嗅探云端最新创建的账号）
  Future<Map<String, dynamic>> loginAuth(String username, String password) async {
    final trimmedUsername = username.trim();
    final trimmedPassword = password.trim();

    AppUser? findUser() {
      try {
        return _users.firstWhere((u) => u.username == trimmedUsername);
      } catch (_) {
        return null;
      }
    }

    // 1. 先查本地缓存
    var user = findUser();

    // 2. 如果本地未查到，极速向同步云端拉取最新账号表
    if (user == null) {
      await syncUsersFromCloud();
      user = findUser();
    }

    if (user == null) {
      return {'success': false, 'message': '账号不存在，请联系超级管理员添加'};
    }

    if (user.password != trimmedPassword) {
      // 密码错误时，也尝试同步一次最新密码
      await syncUsersFromCloud();
      user = findUser();
      if (user != null && user.password != trimmedPassword) {
        return {'success': false, 'message': '密码错误，请重新输入'};
      }
    }

    if (user == null) {
      return {'success': false, 'message': '账号不存在，请联系超级管理员添加'};
    }

    if (!user.isActive) {
      return {
        'success': false,
        'message': '❌ 该账号已被管理员禁用，请联系超级管理员开启！'
      };
    }

    _currentUserObj = user;
    _currentUser = user.name;
    _ownerFilter = 'mine';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('crm_current_user_id', user.id);

    notifyListeners();

    // 登录成功后立即触发全量云端数据拉取
    unawaited(refreshClues());

    return {'success': true, 'user': user};
  }

  /// 退出登录
  Future<void> logout() async {
    _currentUserObj = null;
    _currentUser = '';
    _ownerFilter = 'mine';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('crm_current_user_id');
    notifyListeners();
  }

  /// 仅供单元测试快速切换登录态
  @visibleForTesting
  void setCurrentUserForTesting(AppUser user) {
    _currentUserObj = user;
    _currentUser = user.name;
    _ownerFilter = 'mine';
    notifyListeners();
  }

  /// 添加新账号（仅管理员/超管可调用）
  Future<Map<String, dynamic>> addUser(AppUser newUser) async {
    if (_users.any((u) => u.username == newUser.username)) {
      return {'success': false, 'message': '该账号名已存在，请使用其他账号名'};
    }

    _users.add(newUser);
    await _saveUsersLocal();
    notifyListeners();
    return {'success': true, 'message': '员工账号添加成功'};
  }

  /// 更新账号信息与权限
  Future<bool> updateUser(AppUser updatedUser) async {
    final idx = _users.indexWhere((u) => u.id == updatedUser.id);
    if (idx != -1) {
      _users[idx] = updatedUser;
      if (_currentUserObj?.id == updatedUser.id) {
        _currentUserObj = updatedUser;
        _currentUser = updatedUser.name;
      }
      await _saveUsersLocal();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 切换账号启用/禁用状态
  Future<Map<String, dynamic>> toggleUserStatus(String userId) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx == -1) return {'success': false, 'message': '用户不存在'};

    final user = _users[idx];

    // 禁止禁用自身
    if (_currentUserObj?.id == userId) {
      return {'success': false, 'message': '无法禁用当前登录的账号'};
    }

    // 禁止禁用最后一个启用的超级管理员
    if (user.isSuperAdmin && user.isActive) {
      final activeSuperCount =
          _users.where((u) => u.isSuperAdmin && u.isActive).length;
      if (activeSuperCount <= 1) {
        return {'success': false, 'message': '系统中至少需保留一个启用的超级管理员'};
      }
    }

    _users[idx] = user.copyWith(isActive: !user.isActive);
    await _saveUsersLocal();
    notifyListeners();
    return {
      'success': true,
      'isActive': _users[idx].isActive,
      'message': _users[idx].isActive ? '账号已启用' : '账号已禁用'
    };
  }

  /// 重置密码
  Future<bool> resetUserPassword(String userId, String newPassword) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = _users[idx].copyWith(password: newPassword.trim());
      if (_currentUserObj?.id == userId) {
        _currentUserObj = _users[idx];
      }
      await _saveUsersLocal();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 删除账号
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    if (_currentUserObj?.id == userId) {
      return {'success': false, 'message': '无法删除当前正在登录的账号'};
    }

    final user = _users.firstWhere((u) => u.id == userId, orElse: () => _users.first);
    if (user.isSuperAdmin) {
      final superCount = _users.where((u) => u.isSuperAdmin).length;
      if (superCount <= 1) {
        return {'success': false, 'message': '无法删除唯一的超级管理员账号'};
      }
    }

    _users.removeWhere((u) => u.id == userId);
    await _saveUsersLocal();
    unawaited(_crmSyncService.deleteUser(userId));
    notifyListeners();
    return {'success': true, 'message': '账号已成功删除'};
  }

  /// 智能合并本地与云端同一线索的数据（保证任何一端的新回访与状态更新均不丢失）
  Clue _mergeClue(Clue local, Clue remote, {required List<Clue> needsUpload}) {
    // 1. 合并回访记录 (visitLogs) - 智能业务语义幂等去重
    // 不仅按 ID 去重，更按 (visitContent + createTime分钟级) 识别同一次跟进，彻底消灭差几毫秒的双胞胎重复记录
    final allLogs = <VisitLog>[...remote.visitLogs, ...local.visitLogs];
    final deduplicatedLogs = <VisitLog>[];
    bool localHasNewLogs = false;

    bool isSameVisit(VisitLog a, VisitLog b) {
      if (a.id == b.id) return true;
      final sameContent = a.visitContent.trim() == b.visitContent.trim();
      final timeDiffSec = a.createTime.difference(b.createTime).inSeconds.abs();
      return sameContent && timeDiffSec <= 60;
    }

    VisitLog mergeTwoLogs(VisitLog existing, VisitLog incoming) {
      final hasAiIncoming =
          incoming.aiReport != null && incoming.aiReport!.trim().isNotEmpty;
      final bestAi = hasAiIncoming ? incoming.aiReport : existing.aiReport;
      final bestNext = incoming.nextVisitTime ?? existing.nextVisitTime;
      final bestConcerns =
          {...existing.concerns, ...incoming.concerns}.toList();
      return VisitLog(
        id: existing.id.compareTo(incoming.id) < 0
            ? existing.id
            : incoming.id,
        clueId: existing.clueId,
        contactMethod: incoming.contactMethod,
        visitResult: incoming.visitResult,
        visitContent: incoming.visitContent.isNotEmpty
            ? incoming.visitContent
            : existing.visitContent,
        concerns: bestConcerns,
        nextVisitTime: bestNext,
        createTime: existing.createTime.isBefore(incoming.createTime)
            ? existing.createTime
            : incoming.createTime,
        aiReport: bestAi,
      );
    }

    for (final incoming in allLogs) {
      final existingIdx = deduplicatedLogs
          .indexWhere((item) => isSameVisit(item, incoming));
      if (existingIdx >= 0) {
        deduplicatedLogs[existingIdx] =
            mergeTwoLogs(deduplicatedLogs[existingIdx], incoming);
      } else {
        deduplicatedLogs.add(incoming);
      }
    }

    for (final l in local.visitLogs) {
      if (!remote.visitLogs.any((r) => isSameVisit(r, l))) {
        localHasNewLogs = true;
        break;
      }
    }

    final mergedLogs = deduplicatedLogs
      ..sort((a, b) => b.createTime.compareTo(a.createTime));

    // 2. 合并聊天记录 (chatRecords) - 图像二进制数据与语义内容双向绝对保全
    final allChats = <ChatRecord>[...remote.chatRecords, ...local.chatRecords];
    final deduplicatedChats = <ChatRecord>[];
    bool localHasNewChats = false;

    bool isSameChat(ChatRecord a, ChatRecord b) {
      if (a.id == b.id) return true;
      if (a.ocrText.trim().isNotEmpty && b.ocrText.trim().isNotEmpty) {
        return a.ocrText.trim() == b.ocrText.trim();
      }
      return false;
    }

    ChatRecord mergeTwoChats(ChatRecord existing, ChatRecord incoming) {
      final existingHasImg =
          existing.imageData != null && existing.imageData!.trim().isNotEmpty;
      final incomingHasImg =
          incoming.imageData != null && incoming.imageData!.trim().isNotEmpty;
      final bestImg = existingHasImg
          ? existing.imageData
          : (incomingHasImg ? incoming.imageData : null);
      final bestPath =
          existing.imagePath.isNotEmpty ? existing.imagePath : incoming.imagePath;
      final bestOcr =
          existing.ocrText.isNotEmpty ? existing.ocrText : incoming.ocrText;
      return existing.copyWith(
        imageData: bestImg,
        imagePath: bestPath,
        ocrText: bestOcr,
      );
    }

    for (final incoming in allChats) {
      final idx =
          deduplicatedChats.indexWhere((item) => isSameChat(item, incoming));
      if (idx >= 0) {
        deduplicatedChats[idx] =
            mergeTwoChats(deduplicatedChats[idx], incoming);
      } else {
        deduplicatedChats.add(incoming);
      }
    }

    for (final lc in local.chatRecords) {
      if (!remote.chatRecords.any((rc) => isSameChat(rc, lc))) {
        localHasNewChats = true;
        break;
      }
    }
    for (final mc in deduplicatedChats) {
      final remoteMatch =
          remote.chatRecords.where((rc) => isSameChat(rc, mc)).firstOrNull;
      if (remoteMatch == null ||
          ((remoteMatch.imageData == null || remoteMatch.imageData!.isEmpty) &&
              mc.imageData != null &&
              mc.imageData!.isNotEmpty)) {
        localHasNewChats = true;
      }
    }

    final mergedChats = deduplicatedChats
      ..sort((a, b) => b.createTime.compareTo(a.createTime));

    // 3. 合并标签 (tags)：集合去重且过滤空白
    final mergedTags = <String>{...local.tags, ...remote.tags}
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // 4. 决定状态、意向与次回访时间
    DateTime? localLatestLogTime =
        local.visitLogs.isNotEmpty ? local.visitLogs.first.createTime : null;
    DateTime? remoteLatestLogTime =
        remote.visitLogs.isNotEmpty ? remote.visitLogs.first.createTime : null;

    bool preferLocal = localHasNewLogs ||
        (localLatestLogTime != null &&
            (remoteLatestLogTime == null ||
                localLatestLogTime.isAfter(remoteLatestLogTime)));

    // 🛡️ 核心保全规则 1：下次回访时间 (nextVisitTime) 非空绝对保全，严禁被 null 清空！
    DateTime? mergedNextVisitTime;
    if (local.nextVisitTime != null && remote.nextVisitTime == null) {
      mergedNextVisitTime = local.nextVisitTime;
    } else if (local.nextVisitTime == null && remote.nextVisitTime != null) {
      mergedNextVisitTime = remote.nextVisitTime;
    } else if (local.nextVisitTime != null && remote.nextVisitTime != null) {
      mergedNextVisitTime =
          preferLocal ? local.nextVisitTime : remote.nextVisitTime;
    } else {
      mergedNextVisitTime = null;
    }

    // 🛡️ 核心保全规则 2：AI 深度分析报告 (aiAnalysisReport) 非空绝对保全与最新时间戳竞争
    String? mergedAiReport;
    DateTime? mergedAiTime;
    final bool localHasAi = local.aiAnalysisReport != null &&
        local.aiAnalysisReport!.trim().isNotEmpty;
    final bool remoteHasAi = remote.aiAnalysisReport != null &&
        remote.aiAnalysisReport!.trim().isNotEmpty;

    if (localHasAi && !remoteHasAi) {
      mergedAiReport = local.aiAnalysisReport;
      mergedAiTime = local.aiAnalysisTime ?? DateTime.now();
    } else if (!localHasAi && remoteHasAi) {
      mergedAiReport = remote.aiAnalysisReport;
      mergedAiTime = remote.aiAnalysisTime ?? DateTime.now();
    } else if (localHasAi && remoteHasAi) {
      if (local.aiAnalysisTime != null && remote.aiAnalysisTime != null) {
        if (local.aiAnalysisTime!.isAfter(remote.aiAnalysisTime!)) {
          mergedAiReport = local.aiAnalysisReport;
          mergedAiTime = local.aiAnalysisTime;
        } else {
          mergedAiReport = remote.aiAnalysisReport;
          mergedAiTime = remote.aiAnalysisTime;
        }
      } else {
        mergedAiReport =
            preferLocal ? local.aiAnalysisReport : remote.aiAnalysisReport;
        mergedAiTime =
            preferLocal ? local.aiAnalysisTime : remote.aiAnalysisTime;
      }
    } else {
      mergedAiReport = null;
      mergedAiTime = null;
    }

    // 🛡️ 核心保全规则 3：来源渠道 (source) 绝对防冲刷！
    // 微信、小红书、抖音、老带新、转介绍、电话打入等明确引流渠道，绝不被兜底默认值 '自招' 冲刷！
    String mergedSource;
    final lSource = local.source.trim();
    final rSource = remote.source.trim();
    final bool lIsDefaultSource = lSource.isEmpty || lSource == '自招';
    final bool rIsDefaultSource = rSource.isEmpty || rSource == '自招';
    if (lIsDefaultSource && !rIsDefaultSource) {
      mergedSource = rSource; // 远端为具体渠道，绝对保全
    } else if (!lIsDefaultSource && rIsDefaultSource) {
      mergedSource = lSource; // 本地为具体渠道，绝对保全
    } else {
      mergedSource = preferLocal
          ? (lSource.isNotEmpty ? lSource : rSource)
          : (rSource.isNotEmpty ? rSource : lSource);
    }
    if (mergedSource.isEmpty) mergedSource = '自招';

    // 🛡️ 核心保全规则 4：班型 (classType) 非空非默认保全
    String mergedClassType;
    final lClass = local.classType.trim();
    final rClass = remote.classType.trim();
    final bool lIsDefaultClass = lClass.isEmpty || lClass == '无';
    final bool rIsDefaultClass = rClass.isEmpty || rClass == '无';
    if (lIsDefaultClass && !rIsDefaultClass) {
      mergedClassType = rClass;
    } else if (!lIsDefaultClass && rIsDefaultClass) {
      mergedClassType = lClass;
    } else {
      mergedClassType = preferLocal
          ? (lClass.isNotEmpty ? lClass : rClass)
          : (rClass.isNotEmpty ? rClass : lClass);
    }

    // 🛡️ 核心保全规则 5：普通文本非空优先，绝不用空串覆盖非空值！
    String mergeText(String l, String r) {
      final lt = l.trim();
      final rt = r.trim();
      if (lt.isEmpty) return rt;
      if (rt.isEmpty) return lt;
      return preferLocal ? lt : rt;
    }

    // 🛡️ 核心保全规则 6：意向级别 (intentLevel) 保全
    // 高意向 (high) 极具业务价值，若一方是 high 且另一方仅为默认中意向 (medium) 且未显式下调，优先保全 high
    IntentLevel mergedIntentLevel;
    if (local.intentLevel == IntentLevel.none &&
        remote.intentLevel != IntentLevel.none) {
      mergedIntentLevel = remote.intentLevel;
    } else if (local.intentLevel != IntentLevel.none &&
        remote.intentLevel == IntentLevel.none) {
      mergedIntentLevel = local.intentLevel;
    } else if (local.intentLevel != remote.intentLevel) {
      if (remote.intentLevel == IntentLevel.high &&
          local.intentLevel == IntentLevel.medium &&
          !localHasNewLogs) {
        mergedIntentLevel = IntentLevel.high;
      } else if (local.intentLevel == IntentLevel.high &&
          remote.intentLevel == IntentLevel.medium) {
        mergedIntentLevel = IntentLevel.high;
      } else {
        mergedIntentLevel =
            preferLocal ? local.intentLevel : remote.intentLevel;
      }
    } else {
      mergedIntentLevel = local.intentLevel;
    }

    final mergedClue = Clue(
      id: local.id,
      wxNick: mergeText(local.wxNick, remote.wxNick),
      wxId: mergeText(local.wxId, remote.wxId),
      phone: mergeText(local.phone, remote.phone),
      grade: mergeText(local.grade, remote.grade),
      school: mergeText(local.school, remote.school),
      subject: mergeText(local.subject, remote.subject),
      source: mergedSource,
      classType: mergedClassType,
      ownerName: mergeText(local.ownerName, remote.ownerName),
      status: preferLocal ? local.status : remote.status,
      intentLevel: mergedIntentLevel,
      nextVisitTime: mergedNextVisitTime,
      remark: preferLocal
          ? (local.remark.isNotEmpty ? local.remark : remote.remark)
          : (remote.remark.isNotEmpty ? remote.remark : local.remark),
      enrollAmount: local.enrollAmount ?? remote.enrollAmount,
      aiAnalysisReport: mergedAiReport,
      aiAnalysisTime: mergedAiTime,
      createTime: local.createTime.isBefore(remote.createTime)
          ? local.createTime
          : remote.createTime,
      visitLogs: mergedLogs,
      chatRecords: mergedChats,
      tags: mergedTags,
    );

    // 🛡️ 核心保全规则 7：自愈补推（若合并后字段比云端更丰富，自动加入上传队列自愈修复云端）
    final bool hasNewAiForRemote = (localHasAi && !remoteHasAi) ||
        (localHasAi &&
            remoteHasAi &&
            local.aiAnalysisTime != null &&
            remote.aiAnalysisTime != null &&
            local.aiAnalysisTime!.isAfter(remote.aiAnalysisTime!));
    final bool hasNewNextVisitForRemote =
        local.nextVisitTime != null && remote.nextVisitTime == null;
    final bool hasMoreLogs = mergedLogs.length > remote.visitLogs.length;
    final bool hasMoreChats = mergedChats.length > remote.chatRecords.length;
    final bool sourceEnriched = mergedSource != remote.source;
    final bool tagsEnriched = mergedTags.length > remote.tags.length ||
        !mergedTags.every((t) => remote.tags.contains(t));
    final bool intentEnriched = mergedIntentLevel != remote.intentLevel &&
        mergedIntentLevel == IntentLevel.high;
    final bool schoolEnriched =
        mergedClue.school.isNotEmpty && remote.school.isEmpty;

    if (preferLocal ||
        localHasNewChats ||
        hasNewAiForRemote ||
        hasNewNextVisitForRemote ||
        hasMoreLogs ||
        hasMoreChats ||
        sourceEnriched ||
        tagsEnriched ||
        intentEnriched ||
        schoolEnriched) {
      needsUpload.add(mergedClue);
    }

    return mergedClue;
  }

  @visibleForTesting
  Clue mergeClueForTesting(Clue local, Clue remote, {required List<Clue> needsUpload}) {
    return _mergeClue(local, remote, needsUpload: needsUpload);
  }

  @visibleForTesting
  Future<void> mergeAndApplyRemoteCluesForTesting(List<Clue> remoteClues) {
    return _mergeAndApplyRemoteClues(remoteClues);
  }

  @visibleForTesting
  void clearPendingCreationForTesting(String clueId) {
    _pendingCreationClueIds.remove(clueId);
  }

  @visibleForTesting
  void recordDeletedClueIdForTesting(String id) {
    _deletedClueIds.add(id);
  }

  /// 智能合并并应用远端线索列表（双向无损对齐，新回访永不被冲刷，数据绝对安全）
  Future<void> _mergeAndApplyRemoteClues(List<Clue> remoteClues) async {
    // 0. 优先同步对齐云端墓碑表（确保在其他设备真正被删除的线索不被误复活）
    try {
      final cloudDeleted = await _crmSyncService.fetchDeletedClueIds();
      if (cloudDeleted != null && cloudDeleted.isNotEmpty) {
        _deletedClueIds.addAll(cloudDeleted);
        unawaited(_saveDeletedClueIdsLocal());
      }
    } catch (_) {}

    // 🛡️ 核心安全防线：若远端返回 0 条线索（如服务重启、冷启动或网络响应空），
    // 绝对禁止认定全员被删，必须无条件保全本地已有真实数据，并将本地真实线索反向上报至云端！
    if (remoteClues.isEmpty) {
      if (_clues.isNotEmpty) {
        debugPrint(
            '🛡️ [CrmSync] 远端返回 0 条线索，触发空数据保护屏障，保全本地 ${_clues.length} 条真实线索并反向上报！');
        unawaited(_crmSyncService.saveClues(_clues));
      }
      _isCloudConnected = true;
      _syncStatus = '实时同步中';
      _isSyncing = false;
      notifyListeners();
      return;
    }

    // 自动剿灭云端测试残留线索
    final mockRemotes = remoteClues.where(_isMockClue).toList();
    for (var mc in mockRemotes) {
      unawaited(_crmSyncService.deleteClue(mc.id));
    }

    // 1. 过滤已在本地明确删除的线索，并顺手同步剿灭云端残留（防复活）
    final validRemotes = remoteClues.where((c) {
      if (_isMockClue(c)) return false;
      if (_deletedClueIds.contains(c.id)) {
        unawaited(_crmSyncService.deleteClue(c.id));
        return false;
      }
      return true;
    }).toList();

    final remoteMap = {for (var rc in validRemotes) rc.id: rc};
    final localMap = {
      for (var lc in _clues.where((c) =>
          !_isMockClue(c) && !_deletedClueIds.contains(c.id)))
        lc.id: lc
    };

    final List<Clue> mergedResult = [];
    final List<Clue> needsUpload = [];

    // 2. 遍历远端线索：若本地已存在同名线索，执行智能融合；若不存在，直接采纳
    for (final rc in validRemotes) {
      if (localMap.containsKey(rc.id)) {
        final merged =
            _mergeClue(localMap[rc.id]!, rc, needsUpload: needsUpload);
        mergedResult.add(merged);
      } else {
        mergedResult.add(rc);
      }
    }

    // 3. 遍历本地独有线索（本地存在但远端不存在）
    // 🛡️ 核心数据安全防线：判定线索是否已被删除，必须且仅能以明确的墓碑名单（_deletedClueIds）为准！
    // 严禁因为远端缺失（如容器休眠重启、数据未落盘、网络丢包等）误将本地存活的真实线索自杀删除！
    // 只要本地线索不在墓碑名单中，必须 100% 保全，并加入 needsUpload 自动自愈补推修复云端！
    for (final lc in localMap.values) {
      if (_deletedClueIds.contains(lc.id)) continue;
      if (!remoteMap.containsKey(lc.id)) {
        debugPrint(
            '🛡️ [CrmSync] 发现本地存活线索 ${lc.wxNick} (ID: ${lc.id}) 在云端缺失，启动分布式自愈补推！');
        mergedResult.add(lc);
        needsUpload.add(lc);
      }
    }

    // 成功同步到云端后，从 _pendingCreationClueIds 中移除已在云端存在的线索
    _pendingCreationClueIds.removeWhere((id) => remoteMap.containsKey(id));
    unawaited(_savePendingCreationClueIdsLocal());
    unawaited(_saveDeletedClueIdsLocal());

    // 3. 及时将本地增量（新增回访/独有线索）推向云端
    if (needsUpload.isNotEmpty) {
      debugPrint(
          '☁️ [CrmSync] 智能合并发现 ${needsUpload.length} 条线索有本地更新，正在自动双向上报...');
      unawaited(_crmSyncService.saveClues(needsUpload));
    }

    _clues.clear();
    _clues.addAll(mergedResult);
    _clues.sort((a, b) => b.createTime.compareTo(a.createTime));
    await _saveCluesLocalOnly();
    _isCloudConnected = true;
    _syncStatus = '实时同步中';
    _isSyncing = false;
    notifyListeners();

    // 4. 后台静默拉取云端已删除墓碑名单，同步净化本地
    unawaited(() async {
      try {
        final cloudDeleted = await _crmSyncService.fetchDeletedClueIds();
        if (cloudDeleted != null && cloudDeleted.isNotEmpty) {
          final toRemove = cloudDeleted.toSet();
          bool changed = false;
          for (final id in toRemove) {
            if (!_deletedClueIds.contains(id)) {
              _deletedClueIds.add(id);
              changed = true;
            }
          }
          final countBefore = _clues.length;
          _clues.removeWhere((c) => toRemove.contains(c.id));
          if (_clues.length != countBefore) {
            changed = true;
            await _saveCluesLocalOnly();
            notifyListeners();
          }
          if (changed) {
            await _saveDeletedClueIdsLocal();
          }
        }
      } catch (_) {}
    }());
  }

  /// 初始化云端同步与监听（含智能唤醒重试队列）
  Future<void> _initCloudSync() async {
    _isSyncing = true;
    _syncStatus = '正在同步云端数据...';
    notifyListeners();

    // 1. 同步员工账号与物料
    unawaited(syncUsersFromCloud());
    unawaited(syncMaterialsFromCloud());

    // 2. 优先尝试智能同步引擎同步线索（轻量模式秒级拉取，全量双向对齐）
    try {
      final remoteClues = await _crmSyncService.fetchAllClues(summary: true);
      if (remoteClues != null) {
        await _mergeAndApplyRemoteClues(remoteClues);
        return;
      }
    } catch (_) {}

    // 如果首次拉取失败或返回空（可能处于 Render 休眠冷启动中），启动平滑自动唤醒重试队列
    _startWakeupRetryQueue();

    _firestoreService.initialize();
  }

  /// 智能唤醒重试队列（在 Render 免费实例冷启动唤醒过程中平滑拉取）
  void _startWakeupRetryQueue() {
    // 单元测试环境直接跳过网络延迟重试，避免 pending timers 报错
    if (WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding')) {
      _isSyncing = false;
      return;
    }

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelays = [3, 6, 10];

    void attemptRetry() {
      if (_isDisposed) return;
      if (retryCount >= maxRetries) {
        _isSyncing = false;
        _syncStatus = _isCloudConnected ? '实时同步中' : '离线模式';
        notifyListeners();
        return;
      }

      final delaySec = retryDelays[retryCount];
      retryCount++;

      _retryTimer = Timer(Duration(seconds: delaySec), () async {
        if (_isDisposed) return;
        try {
          final remoteClues = await _crmSyncService.fetchAllClues(summary: true);
          if (remoteClues != null && !_isDisposed) {
            await _mergeAndApplyRemoteClues(remoteClues);
            debugPrint('🟢 [CrmSync] 智能唤醒重试成功，已同步 ${_clues.length} 条线索！');
            return;
          }
        } catch (_) {}

        if (!_isDisposed) {
          attemptRetry();
        }
      });
    }

    attemptRetry();
  }

  /// 从云端同步文字与图片物料（全量双向对齐）
  Future<bool> syncMaterialsFromCloud() async {
    bool hasChanges = false;
    try {
      // 1. 同步文字话术物料
      final remoteText = await _crmSyncService.fetchTextMaterials();
      if (remoteText != null && remoteText.isNotEmpty) {
        final map = {for (var m in _textMaterials) m.id: m};
        bool textChanged = false;
        for (var rm in remoteText) {
          if (!map.containsKey(rm.id) || map[rm.id]!.content != rm.content) {
            map[rm.id] = rm;
            textChanged = true;
          }
        }
        if (textChanged) {
          _textMaterials.clear();
          _textMaterials.addAll(map.values);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('crm_text_materials',
              jsonEncode(_textMaterials.map((m) => m.toJson()).toList()));
          hasChanges = true;
        }
      } else if (remoteText != null &&
          remoteText.isEmpty &&
          _textMaterials.isNotEmpty) {
        unawaited(_crmSyncService.saveTextMaterials(_textMaterials));
      }

      // 2. 同步宣传图片物料（🌟 核心：双向拉取与合并对齐）
      final remoteImages = await _crmSyncService.fetchImageMaterials();
      if (remoteImages != null) {
        final cleanRemote = remoteImages.where(_isValidRealImage).toList();
        final imgMap = {
          for (var m in _imageMaterials.where(_isValidRealImage)) m.id: m
        };
        for (var rim in cleanRemote) {
          if (!imgMap.containsKey(rim.id) ||
              imgMap[rim.id]!.imageData != rim.imageData) {
            imgMap[rim.id] = rim;
          }
        }
        _imageMaterials.clear();
        _imageMaterials.addAll(imgMap.values);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('crm_image_materials',
            jsonEncode(_imageMaterials.map((m) => m.toJson()).toList()));
        hasChanges = true;
      }

      if (hasChanges) {
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 同步物料库异常: $e');
      return false;
    }
  }

  /// 下拉刷新：强制从云端服务器拉取最新数据，并双向补齐未同步的本地线索
  Future<bool> refreshClues() async {
    _isSyncing = true;
    _syncStatus = '正在同步最新数据...';
    notifyListeners();

    // 同时双向同步员工账号与物料
    unawaited(syncUsersFromCloud());
    unawaited(syncMaterialsFromCloud());

    // 1. 优先尝试 7x24 小时云端同步中枢（轻量模式秒级响应，移动网络0.05秒同步，绝不超时）
    try {
      final remoteClues = await _crmSyncService.fetchAllClues(summary: true);
      if (remoteClues != null) {
        await _mergeAndApplyRemoteClues(remoteClues);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 下拉刷新异常: $e');
    }

    // 2. 备选尝试云端 Firestore
    try {
      final fbClues = await _firestoreService.fetchCluesFromServer();
      if (fbClues != null && fbClues.isNotEmpty) {
        await _mergeAndApplyRemoteClues(fbClues);
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Firestore Sync] 下拉刷新异常: $e');
    }

    _isSyncing = false;
    _syncStatus = '离线模式';
    notifyListeners();
    return false;
  }

  /// 按需拉取单学员的高清聊天截图原图（用于学员详情页/时间轴，仅拉取单条线索，数据量小且极速响应）
  Future<void> ensureClueDetailsLoaded(String clueId) async {
    final idx = _clues.indexWhere((c) => c.id == clueId);
    if (idx == -1) return;
    final current = _clues[idx];

    // 若本地已有聊天记录且图片已具备，无需重复请求
    final hasMissingImages = current.chatRecords.any(
        (cr) => (cr.imageData == null || cr.imageData!.isEmpty));
    if (!hasMissingImages) return;

    try {
      final remoteClue = await _crmSyncService.fetchClueDetail(clueId);
      if (remoteClue != null && remoteClue.chatRecords.isNotEmpty) {
        final updatedChats = <ChatRecord>[];
        for (final localCr in current.chatRecords) {
          final matchedRemote = remoteClue.chatRecords
              .where((rc) =>
                  rc.id == localCr.id ||
                  (rc.ocrText.isNotEmpty && rc.ocrText.trim() == localCr.ocrText.trim()))
              .firstOrNull;
          if (matchedRemote != null &&
              matchedRemote.imageData != null &&
              matchedRemote.imageData!.isNotEmpty) {
            updatedChats.add(localCr.copyWith(imageData: matchedRemote.imageData));
          } else {
            updatedChats.add(localCr);
          }
        }

        _clues[idx] = current.copyWith(chatRecords: updatedChats);
        notifyListeners();
        debugPrint('🟢 [CrmSync] 已成功按需为学员 ${current.wxNick} (ID: $clueId) 补齐高清微信原图！');
      }
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 按需拉取学员图片异常: $e');
    }
  }

  /// 仅保存到本地（避免循环触发云端保存，加入配额自适应与异常捕获防崩溃）
  Future<void> _saveCluesLocalOnly() async {
    try {
      _clues.removeWhere(_isMockClue);
      final prefs = await SharedPreferences.getInstance();

      // 优先尝试保存全量数据（包含本地已下载的高清图片数据）
      try {
        final json = jsonEncode(_clues.map((c) => c.toJson()).toList());
        // Web 端 LocalStorage 配额通常为 5MB，若超过 3MB，直接转为轻量存储避免触发 QuotaExceededError
        if (kIsWeb && json.length > 3 * 1024 * 1024) {
          throw Exception('Web localStorage quota protection: payload size exceeds 3MB');
        }
        await prefs.setString('crm_clues', json);
      } catch (storageErr) {
        debugPrint('🛡️ [_saveCluesLocalOnly] 触发存储配额防线，自动降级为轻量化存储: $storageErr');
        // 降级方案：剥离 chatRecords 中的超大 Base64 原图，保留全部文本、AI 深度报告、次回访时间与跟进记录（仅 ~52KB）
        final lightweightJson = jsonEncode(
            _clues.map((c) => c.toJson(includeImageData: false)).toList());
        await prefs.setString('crm_clues', lightweightJson);
      }
    } catch (e) {
      debugPrint('⚠️ [_saveCluesLocalOnly] 本地持久化最终异常: $e');
    }
  }

  /// 保存线索到本地存储并多通道双向同步
  Future<void> _saveClues({Clue? changedClue}) async {
    _clues.removeWhere(_isMockClue);
    await _saveCluesLocalOnly();
    if (changedClue != null && !_isMockClue(changedClue)) {
      try {
        await _crmSyncService.saveClues([changedClue]);
      } catch (e) {
        debugPrint('⚠️ [CrmSync] 保存单个线索到云端异常: $e');
      }
      try {
        _tencentService.saveClue(changedClue);
      } catch (_) {}
      try {
        _firestoreService.saveClue(changedClue);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// 手动强制触发全量双向同步（一键将本地未上报数据推上云端，并拉回最新数据）
  Future<bool> forceSyncAll() async {
    try {
      final success = await refreshClues();
      await syncUsersFromCloud();
      await syncMaterialsFromCloud();
      return success;
    } catch (_) {
      return false;
    }
  }

  /// 保存物料到本地存储并广播到同步服务
  Future<void> _saveMaterials({TextMaterial? textMaterial}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'crm_text_materials',
        jsonEncode(_textMaterials.map((m) => m.toJson()).toList()));
    await prefs.setString(
        'crm_image_materials',
        jsonEncode(_imageMaterials.map((m) => m.toJson()).toList()));

    unawaited(_crmSyncService.saveTextMaterials(_textMaterials));
    unawaited(_crmSyncService.saveImageMaterials(_imageMaterials));

    if (textMaterial != null) {
      _firestoreService.saveTextMaterial(textMaterial);
    }
  }


  // 初始化模拟数据
  void initMockData() {
    final now = DateTime.now();

    // 1. 小雪同学 — 抖音 / 高意向 / 联系中 / 2次回访
    final clue1 = Clue(
      id: '1', wxNick: '小雪同学', wxId: 'xiaoxue_2025', phone: '13812345678',
      grade: '24级', school: '河南经贸职业学院',
      subject: '经管', source: '抖音', classType: '全程集训班',
      status: ClueStatus.contacted, intentLevel: IntentLevel.high,
      tags: ['跨专业', '价格敏感'],
      nextVisitTime: now.add(const Duration(days: 1)),
      createTime: now.subtract(const Duration(days: 10)),
      visitLogs: [
        VisitLog(id: 'v1', clueId: '1', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.normal,
          visitContent: '初次接触，对英语专升本感兴趣，目前在上大学二年级，明年准备考。让她先了解一下课程。',
          concerns: ['学费', '基础'], nextVisitTime: now.subtract(const Duration(days: 3)),
          createTime: now.subtract(const Duration(days: 10))),
        VisitLog(id: 'v2', clueId: '1', contactMethod: ContactMethod.phone,
          visitResult: VisitResult.intentUp,
          visitContent: '第二次跟进，她说已经看了课程介绍，觉得价格偏贵，需要再想想。告知了分期付款方式。',
          concerns: ['学费', '时间'], nextVisitTime: now.add(const Duration(days: 1)),
          createTime: now.subtract(const Duration(days: 3))),
      ],
    );

    // 2. 李明明 — 地推 / 高意向 / 约试听
    final clue2 = Clue(
      id: '2', wxNick: '李明明', wxId: 'lmm_study', phone: '13698765432',
      grade: '23级', school: '河南职业技术学院',
      subject: '理工', source: '地推', classType: '周末走读班',
      status: ClueStatus.invited, intentLevel: IntentLevel.high,
      tags: ['基础薄弱', '目标名校'],
      nextVisitTime: now.add(const Duration(hours: 3)),
      createTime: now.subtract(const Duration(days: 7)),
      visitLogs: [
        VisitLog(id: 'v3', clueId: '2', contactMethod: ContactMethod.face,
          visitResult: VisitResult.trialBooked,
          visitContent: '地推获客，对高数辅导有需求，之前挂科过一次。意向较强，约好明天下午2点到门店详谈，确认报名。',
          concerns: ['基础'], nextVisitTime: now.add(const Duration(hours: 3)),
          createTime: now.subtract(const Duration(days: 7))),
      ],
    );

    // 3. 王小燕 — 小红书 / 中意向 / 待跟进
    final clue3 = Clue(
      id: '3', wxNick: '王小燕', wxId: 'yanyan_xhs', phone: '15923456789',
      grade: '24级', school: '郑州电力高等专科学校',
      subject: '文史', source: '小红书', classType: '',
      status: ClueStatus.following, intentLevel: IntentLevel.medium,
      tags: ['在职备考', '时间紧张'],
      nextVisitTime: now.add(const Duration(days: 3)),
      createTime: now.subtract(const Duration(days: 5)),
      visitLogs: [
        VisitLog(id: 'v3b', clueId: '3', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.followUp,
          visitContent: '小红书私信过来询问专升本备考时间，说她现在工作比较忙，想了解周末走读班的安排。',
          concerns: ['时间'], nextVisitTime: now.add(const Duration(days: 3)),
          createTime: now.subtract(const Duration(days: 5))),
      ],
    );

    // 4. 张大伟 — 抖音 / 已报名
    final clue4 = Clue(
      id: '4', wxNick: '张大伟', wxId: 'zdw88', phone: '18611223344',
      grade: '22级', school: '焦作大学',
      subject: '教育', source: '抖音', classType: '寒暑假集训班',
      status: ClueStatus.enrolled, intentLevel: IntentLevel.high,
      tags: ['二战升本', '住宿需求'],
      nextVisitTime: null,
      createTime: now.subtract(const Duration(days: 15)),
      visitLogs: [
        VisitLog(id: 'v4a', clueId: '4', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.normal,
          visitContent: '第一次沟通，对教育学考研感兴趣，想提前备考。',
          concerns: ['基础'], nextVisitTime: now.subtract(const Duration(days: 10)),
          createTime: now.subtract(const Duration(days: 15))),
        VisitLog(id: 'v4b', clueId: '4', contactMethod: ContactMethod.phone,
          visitResult: VisitResult.intentUp,
          visitContent: '二次跟进，明确意向，推荐寒暑假集训班，当场报名意向强烈。',
          concerns: [], nextVisitTime: now.subtract(const Duration(days: 3)),
          createTime: now.subtract(const Duration(days: 10))),
        VisitLog(id: 'v4c', clueId: '4', contactMethod: ContactMethod.face,
          visitResult: VisitResult.normal,
          visitContent: '已转化为正式学员，到店签订合同，缴费完成。',
          concerns: [], nextVisitTime: null,
          createTime: now.subtract(const Duration(days: 3))),
      ],
    );

    // 5. 赵文文 — 地推 / 低意向 / 已逾期
    final clue5 = Clue(
      id: '5', wxNick: '赵文文', wxId: 'zww_666',
      subject: '文史', source: '地推', classType: '',
      status: ClueStatus.following, intentLevel: IntentLevel.low,
      nextVisitTime: now.subtract(const Duration(days: 2)),
      createTime: now.subtract(const Duration(days: 8)),
      visitLogs: [
        VisitLog(id: 'v5', clueId: '5', contactMethod: ContactMethod.phone,
          visitResult: VisitResult.unreachable,
          visitContent: '打了两次电话没接，发微信也没回，下次再试试。',
          concerns: [], nextVisitTime: now.subtract(const Duration(days: 2)),
          createTime: now.subtract(const Duration(days: 5))),
      ],
    );

    // 6. 刘思雨 — 抖音 / 信息不全
    final clue6 = Clue(
      id: '6', wxNick: '刘思雨', wxId: '',
      subject: '', source: '抖音', classType: '',
      status: ClueStatus.following, intentLevel: IntentLevel.none,
      nextVisitTime: null, createTime: now.subtract(const Duration(days: 2)),
      visitLogs: [],
    );

    // 7. 陈佳佳 — 转介绍 / 高意向 / 已试听
    final clue7 = Clue(
      id: '7', wxNick: '陈佳佳', wxId: 'jiajia_study', phone: '13788990011',
      subject: '经管', source: '转介绍', classType: '全程集训班',
      status: ClueStatus.attended, intentLevel: IntentLevel.high,
      nextVisitTime: now.add(const Duration(hours: 8)),
      createTime: now.subtract(const Duration(days: 12)),
      visitLogs: [
        VisitLog(id: 'v7a', clueId: '7', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.normal,
          visitContent: '由老学员王同学转介绍过来，对经管专升本有明确意向，想了解英语课程。',
          concerns: ['基础'], nextVisitTime: now.subtract(const Duration(days: 8)),
          createTime: now.subtract(const Duration(days: 12))),
        VisitLog(id: 'v7b', clueId: '7', contactMethod: ContactMethod.phone,
          visitResult: VisitResult.followUp,
          visitContent: '电话沟通，她说家人还不太支持，学费方面有顾虑，需要再和家人商量。',
          concerns: ['学费', '时间'], nextVisitTime: now.subtract(const Duration(days: 4)),
          createTime: now.subtract(const Duration(days: 8))),
        VisitLog(id: 'v7c', clueId: '7', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.intentUp,
          visitContent: '家人同意了！她说想报全程班，询问具体上课时间和教材情况。意向提升，约明天面谈。',
          concerns: [], nextVisitTime: now.add(const Duration(hours: 8)),
          createTime: now.subtract(const Duration(days: 1))),
      ],
    );

    // 8. 吴晓峰 — 老带新 / 中意向
    final clue8 = Clue(
      id: '8', wxNick: '吴晓峰', wxId: 'wxf2025',
      subject: '理工', source: '老带新', classType: '周末走读班',
      status: ClueStatus.contacted, intentLevel: IntentLevel.medium,
      nextVisitTime: now.add(const Duration(days: 2)),
      createTime: now.subtract(const Duration(days: 4)),
      visitLogs: [
        VisitLog(id: 'v8', clueId: '8', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.normal,
          visitContent: '是现在学员吴同学的同班同学，想一起报班，对数学+英语双科有需求。初次沟通，发送了课程介绍。',
          concerns: ['学费'], nextVisitTime: now.add(const Duration(days: 2)),
          createTime: now.subtract(const Duration(days: 4))),
      ],
    );

    // 9. 林小雨 — 小红书 / 无意向 / 已流失
    final clue9 = Clue(
      id: '9', wxNick: '林小雨', wxId: 'lxy_pink',
      subject: '美术', source: '小红书', classType: '',
      status: ClueStatus.paused, intentLevel: IntentLevel.none,
      nextVisitTime: null,
      createTime: now.subtract(const Duration(days: 20)),
      visitLogs: [
        VisitLog(id: 'v9a', clueId: '9', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.normal,
          visitContent: '小红书私信来询问，对美术专升本感兴趣，但说距离太远。',
          concerns: ['住宿', '距离'], nextVisitTime: now.subtract(const Duration(days: 14)),
          createTime: now.subtract(const Duration(days: 20))),
        VisitLog(id: 'v9b', clueId: '9', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.noIntent,
          visitContent: '再次联系，说决定在本地报班了，明确表示不考虑我们。',
          concerns: [], nextVisitTime: null,
          createTime: now.subtract(const Duration(days: 14))),
      ],
    );

    // 10. 周鹏程 — 转介绍 / 中意向 / 待跟进
    final clue10 = Clue(
      id: '10', wxNick: '周鹏程', wxId: 'zpc_2024',
      subject: '教育', source: '转介绍', classType: '',
      status: ClueStatus.following, intentLevel: IntentLevel.medium,
      nextVisitTime: now.add(const Duration(days: 5)),
      createTime: now.subtract(const Duration(days: 3)),
      visitLogs: [
        VisitLog(id: 'v10', clueId: '10', contactMethod: ContactMethod.phone,
          visitResult: VisitResult.followUp,
          visitContent: '朋友介绍，说对教育学感兴趣，但还没确定考哪个学校，需要进一步了解院校情况。',
          concerns: ['时间'], nextVisitTime: now.add(const Duration(days: 5)),
          createTime: now.subtract(const Duration(days: 3))),
      ],
    );

    // 11. 苏梦琪 — 老带新 / 高意向 / 已逾期
    final clue11 = Clue(
      id: '11', wxNick: '苏梦琪', wxId: 'smq_study',
      subject: '经管', source: '老带新', classType: '全程集训班',
      status: ClueStatus.invited, intentLevel: IntentLevel.high,
      nextVisitTime: now.subtract(const Duration(days: 1)),
      createTime: now.subtract(const Duration(days: 6)),
      visitLogs: [
        VisitLog(id: 'v11a', clueId: '11', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.intentUp,
          visitContent: '学姐带来的，说学姐考上了很受她影响，自己也想考。意向非常高，问了班型和价格。',
          concerns: [], nextVisitTime: now.subtract(const Duration(days: 3)),
          createTime: now.subtract(const Duration(days: 6))),
        VisitLog(id: 'v11b', clueId: '11', contactMethod: ContactMethod.phone,
          visitResult: VisitResult.followUp,
          visitContent: '打电话确认报名，但说最近期末考试，等考完再来交钱，让我过两天再联系。',
          concerns: ['时间'], nextVisitTime: now.subtract(const Duration(days: 1)),
          createTime: now.subtract(const Duration(days: 3))),
      ],
    );

    // 12. 杨晨曦 — 抖音 / 低意向 / 信息不全
    final clue12 = Clue(
      id: '12', wxNick: '杨晨曦', wxId: '',
      subject: '理工', source: '抖音', classType: '',
      status: ClueStatus.following, intentLevel: IntentLevel.low,
      nextVisitTime: now.add(const Duration(days: 7)),
      createTime: now.subtract(const Duration(days: 1)),
      visitLogs: [],
    );

    // 13. 方芳 — 地推 / 已报名
    final clue13 = Clue(
      id: '13', wxNick: '方芳', wxId: 'fangfang88',
      subject: '文史', source: '地推', classType: '单科提分班',
      status: ClueStatus.enrolled, intentLevel: IntentLevel.high,
      nextVisitTime: null,
      createTime: now.subtract(const Duration(days: 25)),
      visitLogs: [
        VisitLog(id: 'v13a', clueId: '13', contactMethod: ContactMethod.face,
          visitResult: VisitResult.trialBooked,
          visitContent: '街头地推认识，对语文单科提分有需求，以前报过其他机构效果不好。',
          concerns: ['效果'], nextVisitTime: now.subtract(const Duration(days: 20)),
          createTime: now.subtract(const Duration(days: 25))),
        VisitLog(id: 'v13b', clueId: '13', contactMethod: ContactMethod.face,
          visitResult: VisitResult.intentUp,
          visitContent: '参加免费试听课，对授课效果很满意，当场报名单科提分班，已缴费。',
          concerns: [], nextVisitTime: null,
          createTime: now.subtract(const Duration(days: 20))),
      ],
    );

    // 14. 谢一鸣 — 小红书 / 中意向 / 多次回访
    final clue14 = Clue(
      id: '14', wxNick: '谢一鸣', wxId: 'xym_notes',
      subject: '经管', source: '小红书', classType: '',
      status: ClueStatus.contacted, intentLevel: IntentLevel.medium,
      nextVisitTime: now.add(const Duration(days: 4)),
      createTime: now.subtract(const Duration(days: 14)),
      visitLogs: [
        VisitLog(id: 'v14a', clueId: '14', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.normal,
          visitContent: '看了我们小红书发的备考攻略主动来咨询，对专升本整体流程不太清楚。',
          concerns: ['基础'], nextVisitTime: now.subtract(const Duration(days: 10)),
          createTime: now.subtract(const Duration(days: 14))),
        VisitLog(id: 'v14b', clueId: '14', contactMethod: ContactMethod.wechat,
          visitResult: VisitResult.followUp,
          visitContent: '发送了院校信息和往年录取情况，他说还在比较其他机构，让他再考虑几天。',
          concerns: ['学费'], nextVisitTime: now.add(const Duration(days: 4)),
          createTime: now.subtract(const Duration(days: 10))),
      ],
    );

    // 15. 韩冰冰 — 转介绍 / 无信息
    final clue15 = Clue(
      id: '15', wxNick: '韩冰冰', wxId: '',
      subject: '', source: '转介绍', classType: '',
      status: ClueStatus.following, intentLevel: IntentLevel.none,
      nextVisitTime: null,
      createTime: now.subtract(const Duration(hours: 2)),
      visitLogs: [],
    );

    _clues.addAll([
      clue1, clue2, clue3, clue4, clue5,
      clue6, clue7, clue8, clue9, clue10,
      clue11, clue12, clue13, clue14, clue15,
    ]);
    _initMockMaterials();
    _saveClues();
    _saveMaterials();
  }

  /// 重置并恢复初始演示数据
  void resetToMockData() {
    _clues.clear();
    _textMaterials.clear();
    _imageMaterials.clear();
    initMockData();
    notifyListeners();
  }

  // 搜索线索
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  // 设置线索Tab
  void setClueTabIndex(int index) {
    _clueTabIndex = index;
    _selectedFilter = '';
    notifyListeners();
  }

  // 意向/状态/标签快捷筛选
  String _selectedFilter = '';
  String get selectedTag => _selectedFilter;
  String get selectedFilter => _selectedFilter;

  void setSelectedTag(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  /// 预设意向度列表
  static const List<String> intentionFilters = ['高意向', '中意向', '低意向'];

  /// 预设跟进状态列表
  static const List<String> statusFilters = [
    '待跟进',
    '联系中',
    '已邀约',
    '已试听',
    '已报名',
    '暂搁置'
  ];

  /// 获取当前所有线索中使用过的所有标签（去重）
  List<String> get allTags {
    final set = <String>{};
    for (final c in _clues) {
      set.addAll(c.tags);
    }
    return set.toList();
  }

  /// 获取当前系统中所有出现过的顾问老师姓名列表（用于管理员筛选）
  List<String> get allAdvisorNames {
    final set = <String>{};
    for (final u in _users) {
      if (u.name.isNotEmpty) set.add(u.name);
    }
    for (final c in _clues) {
      if (c.ownerName.isNotEmpty) set.add(c.ownerName);
    }
    return set.toList();
  }

  /// 年级/届别规范化归一（将 25 -> 25级, 2024 -> 24级, 过滤 12 等异常乱码）
  static String normalizeGrade(String raw) {
    final g = raw.trim();
    if (g.isEmpty) return '';
    // 2024级 / 2024届 / 2024 -> 24级
    final y4Match = RegExp(r'^20(\d{2})[级届]?$').firstMatch(g);
    if (y4Match != null) {
      return '${y4Match.group(1)}级';
    }
    // 24 / 25 / 26 / 23 / 22 / 27 等纯2位数字（20~29年） -> 补齐为 "XX级"
    if (RegExp(r'^(2[0-9])$').hasMatch(g)) {
      return '${g}级';
    }
    // 24届 / 25届 -> 24级 / 25级
    final jieMatch = RegExp(r'^(2[0-9])届$').firstMatch(g);
    if (jieMatch != null) {
      return '${jieMatch.group(1)}级';
    }
    // 标准格式 "2X级"
    if (RegExp(r'^(2[0-9])级$').hasMatch(g)) {
      return g;
    }
    // 大专年级映射
    if (g == '大三') return '24级';
    if (g == '大二') return '25级';
    if (g == '大一') return '26级';
    // 异常手误或测试乱填（如 "12"、非规范文本），过滤不入库
    return '';
  }

  /// 获取当前系统中所有出现过的届别/年级列表（用于筛选，纯净规范不重复）
  List<String> get allGrades {
    final set = <String>{};
    for (final c in _clues) {
      final g = normalizeGrade(c.grade);
      if (g.isNotEmpty) {
        set.add(g);
      }
    }
    // 确保核心在招届别始终展示在筛选列表中
    set.add('26级');
    set.add('25级');
    set.add('24级');
    set.add('23级');
    final list = set.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  /// 获取未加胶囊筛选前的基础线索列表（用于动态计算各状态/意向的有数据胶囊）
  List<Clue> get baseFilteredClues {
    List<Clue> result = List.from(_clues);
    if (!canViewAllClues) {
      // 普通顾问：严格只查看归属于自己的私有线索
      result = result.where((c) =>
          c.ownerName.isNotEmpty &&
          (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
    } else {
      if (_ownerFilter == 'mine') {
        result = result.where((c) =>
            c.ownerName.isNotEmpty &&
            (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
      } else if (_ownerFilter != 'all') {
        result = result.where((c) => c.ownerName == _ownerFilter).toList();
      }
    }
    // 年级/届别筛选（做规范化兼容匹配）
    if (_gradeFilter != 'all' && _gradeFilter.isNotEmpty) {
      result = result.where((c) => normalizeGrade(c.grade) == _gradeFilter).toList();
    }
    if (_searchKeyword.trim().isNotEmpty) {
      final kw = _searchKeyword.trim().toLowerCase();
      result = result.where((c) {
        return c.wxNick.toLowerCase().contains(kw) ||
            c.wxId.toLowerCase().contains(kw) ||
            c.phone.toLowerCase().contains(kw) ||
            c.school.toLowerCase().contains(kw) ||
            c.grade.toLowerCase().contains(kw) ||
            c.subject.toLowerCase().contains(kw) ||
            c.source.toLowerCase().contains(kw) ||
            c.classType.toLowerCase().contains(kw) ||
            c.ownerName.toLowerCase().contains(kw) ||
            c.remark.toLowerCase().contains(kw) ||
            c.tags.any((t) => t.toLowerCase().contains(kw));
      }).toList();
    }
    switch (_clueTabIndex) {
      case 0:
        result = result
            .where((c) =>
                c.status != ClueStatus.enrolled &&
                c.status != ClueStatus.paused)
            .toList();
        break;
      case 1:
        final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        result = result
            .where((c) =>
                c.status != ClueStatus.enrolled &&
                c.status != ClueStatus.paused &&
                c.nextVisitTime != null &&
                !c.nextVisitTime!.isBefore(todayStart))
            .toList();
        break;
      case 2:
        final now = DateTime.now();
        result = result.where((c) {
          if (c.status == ClueStatus.enrolled || c.status == ClueStatus.paused || c.nextVisitTime == null) return false;
          return c.nextVisitTime!.isBefore(now);
        }).toList();
        break;
      case 3: // 已试听
        result = result.where((c) => c.status == ClueStatus.attended).toList();
        break;
      case 4:
        result = result.where((c) => c.status == ClueStatus.enrolled).toList();
        break;
      case 5: // 暂搁置
        result = result.where((c) => c.status == ClueStatus.paused).toList();
        break;
    }
    return result;
  }

  // 获取过滤后的线索列表（按权限、归属人、子Tab、标签、关键词筛选）
  List<Clue> get filteredClues {
    List<Clue> result = List.from(_clues);

    // 1. 权限与归属人数据隔离
    if (!canViewAllClues) {
      // 普通顾问：严格只查看归属于自己的私有线索
      result = result.where((c) =>
          c.ownerName.isNotEmpty &&
          (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
    } else {
      // 管理员/超管：根据 _ownerFilter 进行自由筛选（默认 'mine' 仅看自己）
      if (_ownerFilter == 'mine') {
        result = result.where((c) =>
            c.ownerName.isNotEmpty &&
            (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
      } else if (_ownerFilter != 'all') {
        result = result.where((c) => c.ownerName == _ownerFilter).toList();
      }
    }

    // 2. 年级/届别筛选（做规范化兼容匹配）
    if (_gradeFilter != 'all' && _gradeFilter.isNotEmpty) {
      result = result.where((c) => normalizeGrade(c.grade) == _gradeFilter).toList();
    }

    // 3. 按搜索关键词过滤
    if (_searchKeyword.trim().isNotEmpty) {
      final kw = _searchKeyword.trim().toLowerCase();
      result = result.where((c) {
        return c.wxNick.toLowerCase().contains(kw) ||
            c.wxId.toLowerCase().contains(kw) ||
            c.phone.toLowerCase().contains(kw) ||
            c.school.toLowerCase().contains(kw) ||
            c.grade.toLowerCase().contains(kw) ||
            c.subject.toLowerCase().contains(kw) ||
            c.source.toLowerCase().contains(kw) ||
            c.classType.toLowerCase().contains(kw) ||
            c.ownerName.toLowerCase().contains(kw) ||
            c.remark.toLowerCase().contains(kw) ||
            c.tags.any((t) => t.toLowerCase().contains(kw));
      }).toList();
    }

    // 3. 按选中的「意向 / 状态 / 标签」胶囊过滤
    if (_selectedFilter.isNotEmpty) {
      if (intentionFilters.contains(_selectedFilter)) {
        result = result.where((c) => c.intentText == _selectedFilter).toList();
      } else if (statusFilters.contains(_selectedFilter)) {
        result = result.where((c) => c.statusText == _selectedFilter).toList();
      } else {
        result = result.where((c) => c.tags.contains(_selectedFilter)).toList();
      }
    }

    // 4. 按Tab过滤与排序
    switch (_clueTabIndex) {
      case 0: // 全部（排除已报名和暂搁置，优先按下次回访时间由近及远升序，无回访时间的按创建时间倒序）
        result = result
            .where((c) =>
                c.status != ClueStatus.enrolled &&
                c.status != ClueStatus.paused)
            .toList()
          ..sort((a, b) {
            if (a.nextVisitTime != null && b.nextVisitTime != null) {
              return a.nextVisitTime!.compareTo(b.nextVisitTime!);
            } else if (a.nextVisitTime != null) {
              return -1;
            } else if (b.nextVisitTime != null) {
              return 1;
            } else {
              return b.createTime.compareTo(a.createTime);
            }
          });
        break;

      case 1: // 待回访（严格排除已逾期，仅保留今天及未来的回访，按时间升序）
        final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        result = result
            .where((c) =>
                c.status != ClueStatus.enrolled &&
                c.status != ClueStatus.paused &&
                c.nextVisitTime != null &&
                !c.nextVisitTime!.isBefore(todayStart))
            .toList()
          ..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!));
        break;

      case 2: // 已逾期（逾期越久越紧急排在最前）
        final now = DateTime.now();
        result = result
            .where((c) =>
                c.status != ClueStatus.enrolled &&
                c.status != ClueStatus.paused &&
                c.nextVisitTime != null &&
                c.nextVisitTime!.isBefore(now))
            .toList()
          ..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!));
        break;

      case 3: // 已试听
        result = result
            .where((c) => c.status == ClueStatus.attended)
            .toList()
          ..sort((a, b) => b.createTime.compareTo(a.createTime));
        break;

      case 4: // 已报名
        result = result
            .where((c) => c.status == ClueStatus.enrolled)
            .toList()
          ..sort((a, b) => b.createTime.compareTo(a.createTime));
        break;

      case 5: // 暂搁置（按创建时间倒序）
        result = result
            .where((c) => c.status == ClueStatus.paused)
            .toList()
          ..sort((a, b) => b.createTime.compareTo(a.createTime));
        break;
    }

    return result;
  }

  // 获取待回访线索列表（有下次回访时间的，排除已报名和暂搁置，按权限隔离）
  List<Clue> get todoClues {
    List<Clue> list = _clues
        .where((c) =>
            c.nextVisitTime != null &&
            c.status != ClueStatus.enrolled &&
            c.status != ClueStatus.paused)
        .toList();

    if (!canViewAllClues) {
      list = list.where((c) =>
          c.ownerName.isNotEmpty &&
          (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
    } else {
      if (_ownerFilter == 'mine') {
        list = list.where((c) =>
            c.ownerName.isNotEmpty &&
            (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
      } else if (_ownerFilter != 'all') {
        list = list.where((c) => c.ownerName == _ownerFilter).toList();
      }
    }

    return list..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!));
  }

  // 新增线索（自动填充当前登录顾问为归属人）
  void addClue(Clue clue) {
    if (_deletedClueIds.contains(clue.id)) {
      _deletedClueIds.remove(clue.id);
      unawaited(_saveDeletedClueIdsLocal());
    }
    _pendingCreationClueIds.add(clue.id);
    unawaited(_savePendingCreationClueIdsLocal());

    if (clue.ownerName.isEmpty && currentUser.isNotEmpty) {
      clue.ownerName = currentUser;
    }
    _clues.insert(0, clue);
    notifyListeners();
    _saveClues(changedClue: clue);
  }

  // 批量新增线索（支持 Excel/CSV 批量导入并全端同步）
  Future<void> batchAddClues(List<Clue> newClues) async {
    bool hasDeleted = false;
    for (final clue in newClues) {
      if (_deletedClueIds.contains(clue.id)) {
        _deletedClueIds.remove(clue.id);
        hasDeleted = true;
      }
      _pendingCreationClueIds.add(clue.id);
      if (clue.ownerName.isEmpty && currentUser.isNotEmpty) {
        clue.ownerName = currentUser;
      }
    }
    if (hasDeleted) {
      unawaited(_saveDeletedClueIdsLocal());
    }
    unawaited(_savePendingCreationClueIdsLocal());
    _clues.insertAll(0, newClues);
    notifyListeners();
    await _saveClues();
  }

  // 根据ID获取线索
  Clue? getClueById(String id) {
    try {
      return _clues.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // 删除线索（强保证：本地立即原子记录墓碑并移除，云端中枢彻底同步删除）
  Future<void> deleteClue(String clueId) async {
    // 1. 记入墓碑黑名单，防止网络时差或刷新拉取导致已删线索复活
    _deletedClueIds.add(clueId);
    _pendingCreationClueIds.remove(clueId);
    unawaited(_saveDeletedClueIdsLocal());
    unawaited(_savePendingCreationClueIdsLocal());

    // 2. 立即从本地内存与持久化存储中移除
    _clues.removeWhere((c) => c.id == clueId);
    notifyListeners();
    await _saveCluesLocalOnly();

    // 3. 云端同步中枢执行物理删除（优先等待 3 秒内确认）
    try {
      await _crmSyncService
          .deleteClue(clueId)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 删除线索云端同步稍有延迟，已受墓碑机制保护: $e');
    }

    // 4. 辅助通道同步删除
    try {
      _tencentService.deleteClue(clueId);
    } catch (_) {}
    try {
      _firestoreService.deleteClue(clueId);
    } catch (_) {}
  }

  // 更新线索基本信息
  void updateClue({
    required String clueId,
    required String wxNick,
    required String wxId,
    required String phone,
    String grade = '',
    String school = '',
    required String subject,
    required String source,
    required String classType,
    required ClueStatus status,
    required IntentLevel intentLevel,
    required String remark,
    List<String>? tags,
    DateTime? nextVisitTime,
  }) {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.wxNick = wxNick;
      clue.wxId = wxId;
      clue.phone = phone;
      clue.grade = grade;
      clue.school = school;
      clue.subject = subject;
      clue.source = source;
      clue.classType = classType;
      clue.status = status;
      clue.intentLevel = intentLevel;
      clue.remark = remark;
      if (tags != null) clue.tags = tags;
      if (nextVisitTime != null) clue.nextVisitTime = nextVisitTime;
      notifyListeners();
      _saveClues(changedClue: clue);
    }
  }

  // 指派/转派线索归属顾问（支持超管一键分配与全网同步）
  void reassignClueOwner(String clueId, String newOwnerName) {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.ownerName = newOwnerName;
      notifyListeners();
      _saveClues(changedClue: clue);
    }
  }

  // 新增回访记录（强保证：本地立即原子级落盘，确保在任何网络或切页情况下均不丢失）
  Future<bool> addVisitLog(
    String clueId,
    VisitLog log, {
    ClueStatus? newStatus,
    IntentLevel? newIntentLevel,
  }) async {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.visitLogs.insert(0, log);
      clue.nextVisitTime = log.nextVisitTime;
      if (newStatus != null) {
        clue.status = newStatus;
      } else {
        if (log.visitResult == VisitResult.intentUp) {
          clue.status = ClueStatus.invited;
        } else if (log.visitResult == VisitResult.noIntent) {
          clue.status = ClueStatus.paused;
        } else {
          clue.status = ClueStatus.contacted;
        }
      }
      if (newIntentLevel != null) {
        clue.intentLevel = newIntentLevel;
      } else if (log.visitResult == VisitResult.intentUp) {
        clue.intentLevel = IntentLevel.high;
      }

      // 1. 立即通知 UI 更新（实现页面秒级响应）
      notifyListeners();

      // 2. 强安全屏障：等待本地 SharedPreferences/localStorage 100% 写入成功
      await _saveCluesLocalOnly();

      // 3. 强力保证：优先等待云端在 3 秒内快速确认落盘（即便弱网或离线也不阻碍本地顺利返回）
      if (!_isMockClue(clue)) {
        try {
          await _crmSyncService
              .saveClues([clue])
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('⚠️ [CrmSync] 回访记录上传云端稍有延迟，已受智能合并保护: $e');
        }
        try {
          _tencentService.saveClue(clue);
        } catch (_) {}
        try {
          _firestoreService.saveClue(clue);
        } catch (_) {}
      }

      return true;
    }
    return false;
  }

  // 批量追加聊天截图并触发云端与本地双向同步
  Future<void> addChatRecords(String clueId, List<ChatRecord> records) async {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.chatRecords.addAll(records);
      notifyListeners();
      await _saveClues(changedClue: clue);
    }
  }

  // 保存最新的 AI 大模型分析报告，并自动推送到云端同步
  Future<void> saveAiAnalysisReport(String clueId, String report) async {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.aiAnalysisReport = report;
      clue.aiAnalysisTime = DateTime.now();
      notifyListeners();
      await _saveClues(changedClue: clue);
    }
  }

  // 转为报名
  void enrollClue(String clueId, String classType, String remark, {double? enrollAmount}) {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.status = ClueStatus.enrolled;
      clue.classType = classType;
      clue.remark = remark;
      if (enrollAmount != null) {
        clue.enrollAmount = enrollAmount;
      }
      clue.nextVisitTime = null;
      notifyListeners();
      _saveClues(changedClue: clue);
    }
  }

  // 修改报名详情信息（已报名学员更新班型、金额及备注）
  void updateEnrollInfo(String clueId, String classType, double? enrollAmount, String remark) {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.classType = classType;
      clue.enrollAmount = enrollAmount;
      clue.remark = remark;
      notifyListeners();
      _saveClues(changedClue: clue);
    }
  }

  /// 当前登录用户有权访问的基础线索全集（超管看全员/指定人，普通顾问严格看自己名下线索）
  List<Clue> get accessibleClues {
    if (canViewAllClues) {
      if (_ownerFilter == 'mine') {
        return _clues.where((c) =>
            c.ownerName.isNotEmpty &&
            (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
      } else if (_ownerFilter != 'all') {
        return _clues.where((c) => c.ownerName == _ownerFilter).toList();
      }
      return List.unmodifiable(_clues);
    } else {
      return _clues.where((c) =>
          c.ownerName.isNotEmpty &&
          (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
    }
  }

  // 统计数据（严格根据当前用户权限隔离计算）
  int get totalClues => accessibleClues.length;
  int get todoCount => todoClues.length;
  int get overdueCount {
    final now = DateTime.now();
    return accessibleClues
        .where((c) =>
            c.nextVisitTime != null && c.nextVisitTime!.isBefore(now))
        .length;
  }
  int get totalVisits =>
      accessibleClues.fold(0, (sum, c) => sum + c.visitLogs.length);
  int get invitedCount =>
      accessibleClues.where((c) => c.status == ClueStatus.invited).length;
  int get attendedCount =>
      accessibleClues.where((c) => c.status == ClueStatus.attended).length;
  int get enrolledCount =>
      accessibleClues.where((c) => c.status == ClueStatus.enrolled).length;

  // 各来源线索数量
  Map<String, int> get sourceStats {
    final map = <String, int>{};
    for (final c in accessibleClues) {
      final key = c.source.isEmpty ? '其他' : c.source;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }
  // 各科目线索数量（统一归一化为 13 门标准专升本考试科目简写）
  Map<String, int> get subjectStats {
    const standardOrder = [
      '高数',
      '管理',
      '语文',
      '经济',
      '法学',
      '教心',
      '生理病理',
      '中医',
      '动植遗传',
      '美术',
      '音乐',
      '舞蹈',
      '体育',
    ];

    final map = <String, int>{for (var s in standardOrder) s: 0};

    String normalize(String raw) {
      final s = raw.trim();
      if (s.isEmpty) return '未填写';
      if (s.contains('高数') || s.contains('高等数学') || s.contains('理工') || s.contains('计算机')) {
        return '高数';
      }
      if (s.contains('管理') || s.contains('经管') || s.contains('工商')) {
        return '管理';
      }
      if (s.contains('语文') || s.contains('大学语文') || s.contains('文史')) {
        return '语文';
      }
      if (s.contains('经济')) {
        return '经济';
      }
      if (s.contains('法学')) {
        return '法学';
      }
      if (s.contains('教心') || s.contains('教育学') || s.contains('教育') || s.contains('心理')) {
        return '教心';
      }
      if (s.contains('生理') || s.contains('病理') || s.contains('解剖') || s.contains('医学')) {
        return '生理病理';
      }
      if (s.contains('中医')) {
        return '中医';
      }
      if (s.contains('动植') || s.contains('动物') || s.contains('植物') || s.contains('遗传') || s.contains('农学')) {
        return '动植遗传';
      }
      if (s.contains('美术') || s.contains('艺术') || s.contains('设计')) {
        return '美术';
      }
      if (s.contains('音乐') || s.contains('声乐')) {
        return '音乐';
      }
      if (s.contains('舞蹈')) {
        return '舞蹈';
      }
      if (s.contains('体育')) {
        return '体育';
      }
      return s;
    }

    for (final c in accessibleClues) {
      final normKey = normalize(c.subject);
      map[normKey] = (map[normKey] ?? 0) + 1;
    }

    // 过滤掉数量为0且非必须的额外键，保留有数据的或13个标准科目
    return map;
  }

  // 生成唯一ID
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // ─────────────────────────────────────
  // 物料管理
  // ─────────────────────────────────────

  final List<TextMaterial> _textMaterials = [];
  final List<ImageMaterial> _imageMaterials = [];

  List<TextMaterial> get textMaterials => List.unmodifiable(_textMaterials);
  List<ImageMaterial> get imageMaterials => List.unmodifiable(_imageMaterials);

  /// 校验物料是否为真实有效的图片素材（严格排除历史遗留模拟占位物料）
  static bool _isValidRealImage(ImageMaterial m) {
    const mockIds = {
      'im1', 'im2', 'im3', 'im4', 'im5', 'im6', 'im7', 'im8'
    };
    if (mockIds.contains(m.id)) return false;
    final hasData = m.imageData != null && m.imageData!.trim().isNotEmpty;
    final hasUrl = m.imageUrl != null && m.imageUrl!.trim().isNotEmpty;
    return hasData || hasUrl;
  }

  // ─────────────────────────────────────
  // 双层物料池分层 Getter
  // ─────────────────────────────────────

  /// 1. 公共物料池（全员共享，审核已通过）
  List<TextMaterial> get publicTextMaterials => _textMaterials
      .where((m) => m.isPublic && m.reviewStatus == MaterialReviewStatus.approved)
      .toList();

  List<ImageMaterial> get publicImageMaterials => _imageMaterials
      .where((m) =>
          m.isPublic &&
          m.reviewStatus == MaterialReviewStatus.approved &&
          _isValidRealImage(m))
      .toList();

  /// 2. 个人私有物料池（当前登录老师创建的专属物料，包含私有自用、审核中及已通过上架公共池的个人自有物料）
  List<TextMaterial> get myPrivateTextMaterials => _textMaterials.where((m) {
        // 1. 严格排除系统官方预置话术（官方公共话术绝不属于任何顾问的专属池）
        if (m.id.startsWith('tm_cb_') || m.id.startsWith('tm_def_')) {
          return false;
        }

        // 2. 归属人检查：必须属于当前登录用户（若 ownerName 为空则只在非公开时归属）
        final isMyMaterial = m.ownerName.isNotEmpty
            ? m.ownerName == currentUser
            : (!m.isPublic);
        if (!isMyMaterial) return false;

        // 3. 私有自用、待审核、被驳回状态的自建话术，直接属于当前用户的专属池
        if (!m.isPublic) return true;

        // 4. 审核通过已上架公共池的物料，仅当其源自个人专属池(fromPrivatePool == true)才保留在专属池
        return m.fromPrivatePool;
      }).toList();

  List<ImageMaterial> get myPrivateImageMaterials => _imageMaterials.where((m) {
        if (!_isValidRealImage(m)) return false;

        // 归属人检查
        final isMyMaterial = m.ownerName.isNotEmpty
            ? m.ownerName == currentUser
            : (!m.isPublic);
        if (!isMyMaterial) return false;

        // 私有自用、待审核、被驳回状态直接展示
        if (!m.isPublic) return true;

        // 已上架物料仅保留源自专属池的
        return m.fromPrivatePool;
      }).toList();

  /// 3. 待审核物料池（提交申请待超管审核的物料）
  List<TextMaterial> get pendingReviewTextMaterials => _textMaterials
      .where((m) => m.reviewStatus == MaterialReviewStatus.pending)
      .toList();

  List<ImageMaterial> get pendingReviewImageMaterials => _imageMaterials
      .where((m) =>
          m.reviewStatus == MaterialReviewStatus.pending &&
          _isValidRealImage(m))
      .toList();

  /// 待审核物料总数
  int get totalPendingMaterialsCount =>
      pendingReviewTextMaterials.length + pendingReviewImageMaterials.length;

  /// 按分类分组公共文字物料
  Map<String, List<TextMaterial>> get publicTextMaterialsByCategory {
    final map = <String, List<TextMaterial>>{};
    for (final m in publicTextMaterials) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  /// 按分类分组个人文字物料
  Map<String, List<TextMaterial>> get myTextMaterialsByCategory {
    final map = <String, List<TextMaterial>>{};
    for (final m in myPrivateTextMaterials) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  /// 按分类分组公共图片物料
  Map<String, List<ImageMaterial>> get publicImageMaterialsByCategory {
    final map = <String, List<ImageMaterial>>{};
    for (final m in publicImageMaterials) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  /// 按分类分组个人图片物料
  Map<String, List<ImageMaterial>> get myImageMaterialsByCategory {
    final map = <String, List<ImageMaterial>>{};
    for (final m in myPrivateImageMaterials) {
      map.putIfAbsent(m.category, () => []).add(m);
    }
    return map;
  }

  /// 所有公共文字物料分类
  List<String> get publicTextCategories {
    final seen = <String>{};
    return publicTextMaterials
        .map((m) => m.category)
        .where((c) => seen.add(c))
        .toList();
  }

  /// 所有个人文字物料分类
  List<String> get myTextCategories {
    final seen = <String>{};
    return myPrivateTextMaterials
        .map((m) => m.category)
        .where((c) => seen.add(c))
        .toList();
  }

  /// 所有公共图片物料分类
  List<String> get publicImageCategories {
    final seen = <String>{};
    return publicImageMaterials
        .map((m) => m.category)
        .where((c) => seen.add(c))
        .toList();
  }

  /// 所有个人图片物料分类
  List<String> get myImageCategories {
    final seen = <String>{};
    return myPrivateImageMaterials
        .map((m) => m.category)
        .where((c) => seen.add(c))
        .toList();
  }

  // ─────────────────────────────────────
  // 审核流方法
  // ─────────────────────────────────────

  /// 申请上架到公共池
  void submitMaterialForReview(String id, bool isText) {
    if (isText) {
      final idx = _textMaterials.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _textMaterials[idx] = _textMaterials[idx].copyWith(
          reviewStatus: MaterialReviewStatus.pending,
        );
        notifyListeners();
        _saveMaterials(textMaterial: _textMaterials[idx]);
      }
    } else {
      final idx = _imageMaterials.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _imageMaterials[idx] = _imageMaterials[idx].copyWith(
          reviewStatus: MaterialReviewStatus.pending,
        );
        notifyListeners();
        _saveMaterials();
      }
    }
  }

  /// 超级管理员通过审核：加入公共池全员同步
  void approveMaterial(String id, bool isText) {
    if (isText) {
      final idx = _textMaterials.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _textMaterials[idx] = _textMaterials[idx].copyWith(
          isPublic: true,
          reviewStatus: MaterialReviewStatus.approved,
          rejectReason: '',
        );
        notifyListeners();
        _saveMaterials(textMaterial: _textMaterials[idx]);
      }
    } else {
      final idx = _imageMaterials.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _imageMaterials[idx] = _imageMaterials[idx].copyWith(
          isPublic: true,
          reviewStatus: MaterialReviewStatus.approved,
          rejectReason: '',
        );
        notifyListeners();
        _saveMaterials();
      }
    }
  }

  /// 超级管理员驳回申请
  void rejectMaterial(String id, bool isText, String reason) {
    if (isText) {
      final idx = _textMaterials.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _textMaterials[idx] = _textMaterials[idx].copyWith(
          isPublic: false,
          reviewStatus: MaterialReviewStatus.rejected,
          rejectReason: reason,
        );
        notifyListeners();
        _saveMaterials(textMaterial: _textMaterials[idx]);
      }
    } else {
      final idx = _imageMaterials.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _imageMaterials[idx] = _imageMaterials[idx].copyWith(
          isPublic: false,
          reviewStatus: MaterialReviewStatus.rejected,
          rejectReason: reason,
        );
        notifyListeners();
        _saveMaterials();
      }
    }
  }

  // ─────────────────────────────────────
  // CRUD 操作
  // ─────────────────────────────────────

  void addTextMaterial(TextMaterial m) {
    _textMaterials.add(m);
    notifyListeners();
    _saveMaterials(textMaterial: m);
  }

  void updateTextMaterial(TextMaterial updated) {
    final idx = _textMaterials.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _textMaterials[idx] = updated;
      notifyListeners();
      _saveMaterials(textMaterial: updated);
    }
  }

  void deleteTextMaterial(String id) {
    _textMaterials.removeWhere((m) => m.id == id);
    notifyListeners();
    _saveMaterials();
    unawaited(_crmSyncService.deleteTextMaterial(id));
    if (_isCloudConnected) {
      _firestoreService.deleteTextMaterial(id);
    }
  }

  void addImageMaterial(ImageMaterial m) {
    _imageMaterials.add(m);
    notifyListeners();
    _saveMaterials();
  }

  void updateImageMaterial(ImageMaterial updated) {
    final idx = _imageMaterials.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _imageMaterials[idx] = updated;
      notifyListeners();
      _saveMaterials();
    }
  }

  void deleteImageMaterial(String id) {
    _imageMaterials.removeWhere((m) => m.id == id);
    notifyListeners();
    _saveMaterials();
    unawaited(_crmSyncService.deleteImageMaterial(id));
  }


  /// 初始化物料数据（在 initMockData 中调用：注入80条金牌话术，图片物料保持纯净空列表）
  void _initMockMaterials() {
    _textMaterials.addAll(DefaultMaterials.getDefaultTextMaterials());
    _imageMaterials.clear();
  }

  // ─────────────────────────────────────
  // 🛡️ 企业级客户端数据备份与灾难恢复中心
  // ─────────────────────────────────────

  /// 导出完整系统备份数据（包含学员档案、沟通截图Base64、AI诊断长文、时间轴等全量字段）
  String exportBackupJson() {
    final exportData = {
      'backupVersion': '2.0',
      'system': '专升本招生CRM',
      'exportTime': DateTime.now().toIso8601String(),
      'exportedBy': currentUser,
      'totalClues': _clues.length,
      'clues': _clues.map((c) => c.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 从备份 JSON 数据进行灾难恢复（深度合并保全现有数据，实图优先，AI优先）
  Future<int> restoreFromBackupJson(String jsonStr) async {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      List<dynamic> rawClues = [];
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('clues') && decoded['clues'] is List) {
          rawClues = decoded['clues'] as List<dynamic>;
        } else if (decoded.containsKey('data') && decoded['data'] is List) {
          rawClues = decoded['data'] as List<dynamic>;
        }
      } else if (decoded is List) {
        rawClues = decoded;
      }

      if (rawClues.isEmpty) {
        throw Exception('备份文件中未发现有效学员线索数据');
      }

      int restoredCount = 0;
      final incomingClues = rawClues
          .map((e) => Clue.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((c) => !_isMockClue(c))
          .toList();

      final needsUpload = <Clue>[];
      for (final incoming in incomingClues) {
        final existingIdx = _clues.indexWhere((c) => c.id == incoming.id);
        if (existingIdx >= 0) {
          final merged = _mergeClue(_clues[existingIdx], incoming, needsUpload: needsUpload);
          _clues[existingIdx] = merged;
          needsUpload.add(merged);
        } else {
          _clues.add(incoming);
          needsUpload.add(incoming);
        }
        restoredCount++;
      }

      // 保存本地与云端广播同步
      await _saveCluesLocalOnly();
      notifyListeners();

      if (needsUpload.isNotEmpty) {
        unawaited(_crmSyncService.saveClues(needsUpload));
      }

      return restoredCount;
    } catch (e) {
      debugPrint('⚠️ [restoreFromBackupJson] 备份恢复异常: $e');
      rethrow;
    }
  }
}

