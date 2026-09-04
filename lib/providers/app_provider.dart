import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clue.dart';
import '../models/material_item.dart';
import '../models/app_user.dart';
import '../data/default_materials.dart';
import '../services/firestore_service.dart';
import '../services/tencent_cloudbase_service.dart';
import '../services/crm_sync_service.dart';

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

  // 线索归属老师筛选（'all' 全部, 'mine' 我的, 或指定顾问姓名）
  String _ownerFilter = 'all';
  String get ownerFilter => _ownerFilter;

  void setOwnerFilter(String filter) {
    _ownerFilter = filter;
    notifyListeners();
  }

  // 数据是否已加载完成
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // 云端同步状态
  bool _isCloudConnected = false;
  bool get isCloudConnected => _isCloudConnected;

  String _syncStatus = '正在同步...';
  String get syncStatus => _syncStatus;

  // 私有线索池
  final List<Clue> _clues = [];
  List<Clue> get clues => List.unmodifiable(_clues);

  // 搜索关键词
  String _searchKeyword = '';
  String get searchKeyword => _searchKeyword;

  // 线索列表当前Tab索引
  int _clueTabIndex = 0;
  int get clueTabIndex => _clueTabIndex;

  StreamSubscription<List<Clue>>? _cluesSubscription;
  StreamSubscription<List<TextMaterial>>? _textMaterialsSubscription;

  AppProvider() {
    _init();
  }

  @override
  void dispose() {
    _cluesSubscription?.cancel();
    _textMaterialsSubscription?.cancel();
    super.dispose();
  }

  /// 初始化：加载本地用户、线索、物料并建立同步
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 初始化用户列表与权限
    final usersJson = prefs.getString('crm_users');
    if (usersJson != null) {
      final list = jsonDecode(usersJson) as List<dynamic>;
      _users.addAll(list.map((e) => AppUser.fromJson(e)));
    }

    // 若无用户数据，初始化预设初始超管和示范顾问
    if (_users.isEmpty) {
      _initDefaultUsers();
      await _saveUsersLocal();
    }

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

    // 2. 读本地线索与物料持久化（实现0秒冷启动）
    final cluesJson = prefs.getString('crm_clues');
    final textJson = prefs.getString('crm_text_materials');
    final imageJson = prefs.getString('crm_image_materials');

    if (cluesJson != null) {
      final list = jsonDecode(cluesJson) as List<dynamic>;
      _clues.addAll(list.map((e) => Clue.fromJson(e)));
    }

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
      _imageMaterials.addAll(list.map((e) => ImageMaterial.fromJson(e)));
    }

    if (cluesJson == null) {
      initMockData();
    }

    // 确保所有线索都有明确归属人（修复历史老数据或空归属人线索，超级管理员开箱即见）
    bool needResave = false;
    final defaultAdvisors = ['李广东', '郭培杨', '王主管', '张老师'];
    int advisorIdx = 0;
    for (final c in _clues) {
      if (c.ownerName.trim().isEmpty) {
        c.ownerName = defaultAdvisors[advisorIdx % defaultAdvisors.length];
        advisorIdx++;
        needResave = true;
      }
    }
    if (needResave) {
      _saveClues();
    }

    _isLoaded = true;
    notifyListeners();

    // 3. 静默建立多端极速同步通道
    _initCloudSync();
  }

  /// 初始化默认用户（超级管理员 + 招生顾问）
  void _initDefaultUsers() {
    _users.clear();
    _users.addAll([
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
      AppUser(
        id: 'usr_manager_wang',
        username: 'wangzhuguan',
        password: '123456',
        name: '王主管',
        role: UserRole.advisor,
        phone: '13733334444',
        canManageMaterials: false,
        createdBy: '超级管理员',
      ),
      AppUser(
        id: 'usr_1788340055423',
        username: 'lgd1992',
        password: '123456',
        name: '李广东',
        role: UserRole.advisor,
        phone: '15738801926',
        canManageMaterials: true,
        createdBy: '超级管理员',
      ),
      AppUser(
        id: 'usr_advisor_zhang',
        username: 'zhanglaoshi',
        password: '123456',
        name: '张老师',
        role: UserRole.advisor,
        phone: '13911112222',
        canManageMaterials: true,
        createdBy: '超级管理员',
      ),
      AppUser(
        id: 'usr_1788342882634',
        username: 'gpy1992',
        password: '123456',
        name: '郭培杨',
        role: UserRole.advisor,
        phone: '13290823050',
        canManageMaterials: true,
        createdBy: '超级管理员',
      ),
      AppUser(
        id: 'usr_advisor_li',
        username: 'lilaoshi',
        password: '123456',
        name: '李老师',
        role: UserRole.advisor,
        phone: '13733334444',
        canManageMaterials: false,
        createdBy: '超级管理员',
      ),
    ]);
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
        final map = {for (var u in _users) u.id: u};
        for (var ru in remoteUsers) {
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('crm_current_user_id', user.id);

    notifyListeners();
    return {'success': true, 'user': user};
  }

  /// 退出登录
  Future<void> logout() async {
    _currentUserObj = null;
    _currentUser = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('crm_current_user_id');
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

  /// 初始化云端同步与监听
  Future<void> _initCloudSync() async {
    // 1. 同步员工账号与物料
    unawaited(syncUsersFromCloud());
    unawaited(syncMaterialsFromCloud());

    // 2. 优先尝试智能同步引擎同步线索（全量双向对齐）
    try {
      final remoteClues = await _crmSyncService.fetchAllClues();
      if (remoteClues != null) {
        final remoteMap = {for (var rc in remoteClues) rc.id: rc};
        // 发现本地独有线索（如刚在 iPhone 离线创建的数据），自动上报云端！
        final localOnly =
            _clues.where((c) => !remoteMap.containsKey(c.id)).toList();
        if (localOnly.isNotEmpty) {
          unawaited(_crmSyncService.saveClues(localOnly));
          for (var c in localOnly) {
            remoteMap[c.id] = c;
          }
        }
        _clues.clear();
        _clues.addAll(remoteMap.values);
        _clues.sort((a, b) => b.createTime.compareTo(a.createTime));
        await _saveCluesLocalOnly();
        _isCloudConnected = true;
        _syncStatus = '实时同步中';
        notifyListeners();
        return;
      }
    } catch (_) {}

    _firestoreService.initialize();
  }

  /// 从云端同步文字与图片物料
  Future<void> syncMaterialsFromCloud() async {
    try {
      final remoteText = await _crmSyncService.fetchTextMaterials();
      if (remoteText != null && remoteText.isNotEmpty) {
        final map = {for (var m in _textMaterials) m.id: m};
        for (var rm in remoteText) {
          map[rm.id] = rm;
        }
        _textMaterials.clear();
        _textMaterials.addAll(map.values);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('crm_text_materials',
            jsonEncode(_textMaterials.map((m) => m.toJson()).toList()));
        notifyListeners();
      } else if (remoteText != null &&
          remoteText.isEmpty &&
          _textMaterials.isNotEmpty) {
        await _crmSyncService.saveTextMaterials(_textMaterials);
      }
    } catch (_) {}
  }

  /// 下拉刷新：强制从云端服务器拉取最新数据，并双向补齐未同步的本地线索
  Future<bool> refreshClues() async {
    _syncStatus = '正在同步最新数据...';
    notifyListeners();

    // 同时双向同步员工账号与物料
    unawaited(syncUsersFromCloud());
    unawaited(syncMaterialsFromCloud());

    // 1. 优先尝试 7x24 小时云端同步中枢（全球公网直连）
    try {
      final remoteClues = await _crmSyncService.fetchAllClues();
      if (remoteClues != null) {
        _isCloudConnected = true;
        _syncStatus = '实时同步中';

        final remoteMap = {for (var rc in remoteClues) rc.id: rc};
        final localOnly =
            _clues.where((c) => !remoteMap.containsKey(c.id)).toList();
        if (localOnly.isNotEmpty) {
          debugPrint('☁️ [CrmSync] 发现本地有 ${localOnly.length} 条未上报线索，正在自动双向上报...');
          await _crmSyncService.saveClues(localOnly);
          for (var c in localOnly) {
            remoteMap[c.id] = c;
          }
        }

        _clues.clear();
        _clues.addAll(remoteMap.values);
        _clues.sort((a, b) => b.createTime.compareTo(a.createTime));
        await _saveCluesLocalOnly();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [CrmSync] 下拉刷新异常: $e');
    }

    // 2. 备选尝试云端 Firestore
    try {
      final fbClues = await _firestoreService.fetchCluesFromServer();
      if (fbClues != null && fbClues.isNotEmpty) {
        _isCloudConnected = true;
        _syncStatus = '云端实时同步中';

        final remoteMap = {for (var rc in fbClues) rc.id: rc};
        final localOnly =
            _clues.where((c) => !remoteMap.containsKey(c.id)).toList();
        if (localOnly.isNotEmpty) {
          debugPrint('☁️ [Sync] 发现本地有 ${localOnly.length} 条未上云线索，正在自动双向上报...');
          await _firestoreService.batchUploadClues(localOnly);
          for (var c in localOnly) {
            remoteMap[c.id] = c;
          }
        }

        _clues.clear();
        _clues.addAll(remoteMap.values);
        _clues.sort((a, b) => b.createTime.compareTo(a.createTime));
        await _saveCluesLocalOnly();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [Firestore Sync] 下拉刷新异常: $e');
    }

    _syncStatus = '离线模式';
    notifyListeners();
    return false;
  }

  /// 仅保存到本地（避免循环触发云端保存）
  Future<void> _saveCluesLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_clues.map((c) => c.toJson()).toList());
    await prefs.setString('crm_clues', json);
  }

  /// 保存线索到本地存储并多通道双向同步
  Future<void> _saveClues({Clue? changedClue}) async {
    await _saveCluesLocalOnly();
    if (changedClue != null) {
      try {
        await _crmSyncService.saveClues([changedClue]);
      } catch (e) {
        debugPrint('⚠️ [CrmSync] 保存单个线索到云端异常: $e');
      }
      _tencentService.saveClue(changedClue);
      _firestoreService.saveClue(changedClue);
    }
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
    '无效线索'
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
        result = result.where((c) => c.ownerName == currentUser).toList();
      } else if (_ownerFilter != 'all') {
        result = result.where((c) => c.ownerName == _ownerFilter).toList();
      }
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
        result = result.where((c) => c.status != ClueStatus.enrolled).toList();
        break;
      case 1:
        final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        result = result
            .where((c) =>
                c.status != ClueStatus.enrolled &&
                c.nextVisitTime != null &&
                !c.nextVisitTime!.isBefore(todayStart))
            .toList();
        break;
      case 2:
        final now = DateTime.now();
        result = result.where((c) {
          if (c.status == ClueStatus.enrolled || c.nextVisitTime == null) return false;
          return c.nextVisitTime!.isBefore(now);
        }).toList();
        break;
      case 3: // 已试听
        result = result.where((c) => c.status == ClueStatus.attended).toList();
        break;
      case 4:
        result = result.where((c) => c.status == ClueStatus.enrolled).toList();
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
      // 管理员/超管：根据 _ownerFilter 进行自由筛选
      if (_ownerFilter == 'mine') {
        result = result.where((c) => c.ownerName == currentUser).toList();
      } else if (_ownerFilter != 'all') {
        result = result.where((c) => c.ownerName == _ownerFilter).toList();
      }
    }

    // 2. 按搜索关键词过滤
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
      case 0: // 全部（排除已报名，优先按下次回访时间由近及远升序，无回访时间的按创建时间倒序）
        result = result.where((c) => c.status != ClueStatus.enrolled).toList()
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
    }

    return result;
  }

  // 获取待回访线索列表（有下次回访时间的，按权限隔离）
  List<Clue> get todoClues {
    List<Clue> list = _clues.where((c) => c.nextVisitTime != null).toList();

    if (!canViewAllClues) {
      list = list.where((c) =>
          c.ownerName.isNotEmpty &&
          (c.ownerName == currentUser || c.ownerName == _currentUserObj?.username)).toList();
    } else {
      if (_ownerFilter == 'mine') {
        list = list.where((c) => c.ownerName == currentUser).toList();
      } else if (_ownerFilter != 'all') {
        list = list.where((c) => c.ownerName == _ownerFilter).toList();
      }
    }

    return list..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!));
  }

  // 新增线索（自动填充当前登录顾问为归属人）
  void addClue(Clue clue) {
    if (clue.ownerName.isEmpty && currentUser.isNotEmpty) {
      clue.ownerName = currentUser;
    }
    _clues.insert(0, clue);
    notifyListeners();
    _saveClues(changedClue: clue);
  }

  // 批量新增线索（支持 Excel/CSV 批量导入并全端同步）
  Future<void> batchAddClues(List<Clue> newClues) async {
    for (final clue in newClues) {
      if (clue.ownerName.isEmpty && currentUser.isNotEmpty) {
        clue.ownerName = currentUser;
      }
    }
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

  // 删除线索
  void deleteClue(String clueId) {
    _clues.removeWhere((c) => c.id == clueId);
    notifyListeners();
    _saveCluesLocalOnly();
    _tencentService.deleteClue(clueId);
    _firestoreService.deleteClue(clueId);
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

  // 新增回访记录
  void addVisitLog(String clueId, VisitLog log) {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.visitLogs.insert(0, log);
      clue.nextVisitTime = log.nextVisitTime;
      if (log.visitResult == VisitResult.intentUp) {
        clue.status = ClueStatus.invited;
        clue.intentLevel = IntentLevel.high;
      } else if (log.visitResult == VisitResult.noIntent) {
        clue.status = ClueStatus.paused;
      } else {
        clue.status = ClueStatus.contacted;
      }
      notifyListeners();
      _saveClues(changedClue: clue);
    }
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
  void enrollClue(String clueId, String classType, String remark) {
    final clue = getClueById(clueId);
    if (clue != null) {
      clue.status = ClueStatus.enrolled;
      clue.classType = classType;
      clue.remark = remark;
      clue.nextVisitTime = null;
      notifyListeners();
      _saveClues(changedClue: clue);
    }
  }

  /// 当前登录用户有权访问的基础线索全集（超管看全员/指定人，普通顾问严格看自己名下线索）
  List<Clue> get accessibleClues {
    if (canViewAllClues) {
      if (_ownerFilter == 'mine') {
        return _clues.where((c) => c.ownerName == currentUser).toList();
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

  // ─────────────────────────────────────
  // 双层物料池分层 Getter
  // ─────────────────────────────────────

  /// 1. 公共物料池（全员共享，审核已通过）
  List<TextMaterial> get publicTextMaterials => _textMaterials
      .where((m) => m.isPublic && m.reviewStatus == MaterialReviewStatus.approved)
      .toList();

  List<ImageMaterial> get publicImageMaterials => _imageMaterials
      .where((m) => m.isPublic && m.reviewStatus == MaterialReviewStatus.approved)
      .toList();

  /// 2. 个人私有物料池（当前登录老师创建的私有物料）
  List<TextMaterial> get myPrivateTextMaterials => _textMaterials
      .where((m) =>
          !m.isPublic &&
          (m.ownerName.isEmpty || m.ownerName == currentUser))
      .toList();

  List<ImageMaterial> get myPrivateImageMaterials => _imageMaterials
      .where((m) =>
          !m.isPublic &&
          (m.ownerName.isEmpty || m.ownerName == currentUser))
      .toList();

  /// 3. 待审核物料池（提交申请待超管审核的物料）
  List<TextMaterial> get pendingReviewTextMaterials => _textMaterials
      .where((m) => m.reviewStatus == MaterialReviewStatus.pending)
      .toList();

  List<ImageMaterial> get pendingReviewImageMaterials => _imageMaterials
      .where((m) => m.reviewStatus == MaterialReviewStatus.pending)
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
  }


  /// 初始化物料模拟数据（在 initMockData 中调用）
  void _initMockMaterials() {
    _textMaterials.addAll(DefaultMaterials.getDefaultTextMaterials());

    _imageMaterials.addAll([
      ImageMaterial(id: 'im1', category: '课程海报', title: '全程集训班招生海报', desc: '1080×1920px · 适合朋友圈'),
      ImageMaterial(id: 'im2', category: '课程海报', title: '周末走读班宣传图', desc: '750×1000px · 适合私信发送'),
      ImageMaterial(id: 'im3', category: '课程海报', title: '早鸟优惠限时海报', desc: '1080×1080px · 方形，适合微信'),
      ImageMaterial(id: 'im4', category: '成绩展示', title: '历届学员成绩汇总', desc: '多图合集 · 真实数据'),
      ImageMaterial(id: 'im5', category: '成绩展示', title: '高分学员录取截图', desc: '3张组合 · 院校录取通知书'),
      ImageMaterial(id: 'im6', category: '课程介绍', title: '课程大纲一览图', desc: '各科知识点覆盖'),
      ImageMaterial(id: 'im7', category: '课程介绍', title: '师资团队介绍', desc: '主讲老师照片+资质'),
      ImageMaterial(id: 'im8', category: '学员好评', title: '学员感谢截图合集', desc: '微信/朋友圈好评截图'),
    ]);
  }
}
