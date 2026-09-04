import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/clue.dart';
import '../services/crm_sync_service.dart';
import 'clue_detail_page.dart';


/// 线索列表页（私有线索池，含子Tab筛选）
class ClueListPage extends StatefulWidget {
  const ClueListPage({super.key});

  @override
  State<ClueListPage> createState() => _ClueListPageState();
}

class _ClueListPageState extends State<ClueListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  final List<String> _tabs = ['全部', '待回访', '已逾期', '已试听', '已报名'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<AppProvider>().setClueTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchCtrl.clear();
    });
    context.read<AppProvider>().setSearchKeyword('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '搜索昵称/微信号/手机/科目/班型/来源',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              context.read<AppProvider>().setSearchKeyword('');
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) {
                    setState(() {});
                    context.read<AppProvider>().setSearchKeyword(v);
                  },
                ),
              )
            : Consumer<AppProvider>(
                  builder: (context, p, _) {
                    String title = '我的线索';
                    if (p.canViewAllClues) {
                      if (p.ownerFilter == 'all') {
                        title = '全员线索 (管理模式)';
                      } else if (p.ownerFilter == 'mine') {
                        title = '我的线索';
                      } else {
                        title = '${p.ownerFilter}的线索';
                      }
                    }
                    return Text(title);
                  },
                ),
        actions: [
          if (_isSearching)
            TextButton(
              onPressed: _stopSearch,
              child: const Text('取消', style: TextStyle(color: Colors.white, fontSize: 15)),
            )
          else ...[
            Consumer<AppProvider>(
              builder: (context, p, _) {
                if (!p.canViewAllClues) return const SizedBox.shrink();
                // 排除当前登录人自身，避免与“我的私有线索”重复
                final otherAdvisors = p.allAdvisorNames
                    .where((name) => name != p.currentUser && name.isNotEmpty)
                    .toList();

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list_alt, color: Colors.white),
                  tooltip: '按顾问筛选线索',
                  onSelected: (val) => p.setOwnerFilter(val),
                  itemBuilder: (ctx) => [
                    CheckedPopupMenuItem(
                      value: 'all',
                      checked: p.ownerFilter == 'all',
                      child: const Text('👥 全体学员线索'),
                    ),
                    CheckedPopupMenuItem(
                      value: 'mine',
                      checked: p.ownerFilter == 'mine',
                      child: const Text('💼 我的私有线索'),
                    ),
                    if (otherAdvisors.isNotEmpty) const PopupMenuDivider(),
                    ...otherAdvisors.map(
                      (name) => CheckedPopupMenuItem(
                        value: name,
                        checked: p.ownerFilter == name,
                        child: Text('👤 $name'),
                      ),
                    ),
                  ],
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '搜索线索',
              onPressed: _startSearch,
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final clues = provider.filteredClues;
          final isEnrolledTab = _tabController.index == 4;
          final isTodoTab = _tabController.index == 1;
          final keyword = provider.searchKeyword.trim();

          // 待回访多阶梯任务分组（今日、明日、后天、即将回访）
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final tomorrowStart = todayStart.add(const Duration(days: 1));
          final dayAfterStart = todayStart.add(const Duration(days: 2));
          final futureStart = todayStart.add(const Duration(days: 3));

          final todayClues = isTodoTab
              ? (clues.where((c) => c.nextVisitTime != null && !c.nextVisitTime!.isBefore(todayStart) && c.nextVisitTime!.isBefore(tomorrowStart)).toList()
                ..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!)))
              : <Clue>[];

          final tomorrowClues = isTodoTab
              ? (clues.where((c) => c.nextVisitTime != null && !c.nextVisitTime!.isBefore(tomorrowStart) && c.nextVisitTime!.isBefore(dayAfterStart)).toList()
                ..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!)))
              : <Clue>[];

          final dayAfterClues = isTodoTab
              ? (clues.where((c) => c.nextVisitTime != null && !c.nextVisitTime!.isBefore(dayAfterStart) && c.nextVisitTime!.isBefore(futureStart)).toList()
                ..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!)))
              : <Clue>[];

          final futureClues = isTodoTab
              ? (clues.where((c) => c.nextVisitTime != null && !c.nextVisitTime!.isBefore(futureStart)).toList()
                ..sort((a, b) => a.nextVisitTime!.compareTo(b.nextVisitTime!)))
              : <Clue>[];

          return RefreshIndicator(
            onRefresh: () async {
              final success = await provider.refreshClues();
              if (context.mounted) {
                final err = CrmSyncService().lastError;
                final msg = success
                    ? '☁️ 已从云端同步最新数据'
                    : (err != null ? '⚠️ 同步失败: $err' : '⚠️ 同步失败，请检查网络');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    duration: const Duration(seconds: 3),
                    backgroundColor: success ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            child: Column(
              children: [
                if (keyword.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFE3F2FD),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFF1976D2)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '共找到 ${clues.length} 条关于 "$keyword" 的线索',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1976D2)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            context.read<AppProvider>().setSearchKeyword('');
                            setState(() {});
                          },
                          child: const Text(
                            '清除',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // 状态与意向快捷筛选胶囊栏（已试听 Tab 下只显示意向度）
                _StatusAndIntentionFilterBar(
                  baseClues: provider.baseFilteredClues,
                  selectedFilter: provider.selectedFilter,
                  onSelect: (filter) => provider.setSelectedFilter(filter),
                  isOnlyIntent: provider.clueTabIndex == 3,
                ),
                Expanded(
                  child: clues.isEmpty && !isTodoTab
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    0.18),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    keyword.isNotEmpty
                                        ? Icons.search_off_outlined
                                        : (isEnrolledTab
                                            ? Icons.school_outlined
                                            : Icons.inbox_outlined),
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    keyword.isNotEmpty
                                        ? '未找到与 "$keyword" 相关的线索'
                                        : (provider.selectedFilter.isNotEmpty
                                            ? '暂无「${provider.selectedFilter}」的学员线索'
                                            : (isEnrolledTab
                                                ? '暂无报名学员'
                                                : '暂无线索')),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    keyword.isNotEmpty
                                        ? '请尝试搜索其他昵称、微信号、手机号或科目'
                                        : (provider.selectedFilter.isNotEmpty
                                            ? '可点击上方胶囊切换其他状态，或点击【全部】'
                                            : (isEnrolledTab
                                                ? '线索转为报名后会出现在这里'
                                                : (_tabController.index == 0
                                                    ? '点击下方 + 新建线索，或下拉刷新同步云端'
                                                    : '当前分类下没有线索'))),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  if (keyword.isNotEmpty ||
                                      provider.selectedFilter.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    OutlinedButton(
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        provider.setSearchKeyword('');
                                        provider.setSelectedFilter('');
                                        setState(() {});
                                      },
                                      child: const Text('清除所有筛选条件'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        )
                      : (isTodoTab
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              children: [
                                _TodayTaskCard(
                                  todayClues: todayClues,
                                  onTap: (clue) => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClueDetailPage(clueId: clue.id),
                                    ),
                                  ),
                                ),
                                if (tomorrowClues.isNotEmpty) ...[
                                  _TodoSectionHeader(
                                    title: '明日回访任务',
                                    count: tomorrowClues.length,
                                    color: const Color(0xFF00897B),
                                  ),
                                  ...tomorrowClues.map(
                                    (c) => _ClueCard(
                                      clue: c,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ClueDetailPage(clueId: c.id),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (dayAfterClues.isNotEmpty) ...[
                                  _TodoSectionHeader(
                                    title: '后天回访任务',
                                    count: dayAfterClues.length,
                                    color: const Color(0xFF5E35B1),
                                  ),
                                  ...dayAfterClues.map(
                                    (c) => _ClueCard(
                                      clue: c,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ClueDetailPage(clueId: c.id),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (futureClues.isNotEmpty) ...[
                                  _TodoSectionHeader(
                                    title: '即将回访任务',
                                    count: futureClues.length,
                                    color: const Color(0xFF1976D2),
                                  ),
                                  ...futureClues.map(
                                    (c) => _ClueCard(
                                      clue: c,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ClueDetailPage(clueId: c.id),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              itemCount: clues.length,
                              itemBuilder: (context, index) {
                                final clue = clues[index];
                                if (isEnrolledTab) {
                                  return _EnrolledCard(
                                    clue: clue,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClueDetailPage(clueId: clue.id),
                                      ),
                                    ),
                                  );
                                }
                                return _ClueCard(
                                  clue: clue,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClueDetailPage(clueId: clue.id),
                                    ),
                                  ),
                                );
                              },
                            )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 横向滚动的「状态与意向度」快速筛选胶囊栏组件（智能隐藏无数据标签）
class _StatusAndIntentionFilterBar extends StatelessWidget {
  final List<Clue> baseClues;
  final String selectedFilter;
  final ValueChanged<String> onSelect;
  final bool isOnlyIntent;

  const _StatusAndIntentionFilterBar({
    required this.baseClues,
    required this.selectedFilter,
    required this.onSelect,
    this.isOnlyIntent = false,
  });

  @override
  Widget build(BuildContext context) {
    if (baseClues.isEmpty) {
      return const SizedBox.shrink();
    }

    // 统计各意向度数量
    final highCount = baseClues.where((c) => c.intentText == '高意向').length;
    final medCount = baseClues.where((c) => c.intentText == '中意向').length;
    final lowCount = baseClues.where((c) => c.intentText == '低意向').length;

    // 统计各跟进状态数量
    final followingCount =
        baseClues.where((c) => c.statusText == '待跟进').length;
    final contactedCount =
        baseClues.where((c) => c.statusText == '联系中').length;
    final invitedCount = baseClues.where((c) => c.statusText == '已邀约').length;
    final attendedCount = baseClues.where((c) => c.statusText == '已试听').length;
    final enrolledCount = baseClues.where((c) => c.statusText == '已报名').length;
    final pausedCount =
        baseClues.where((c) => c.statusText == '无效线索').length;

    final hasIntents = highCount > 0 || medCount > 0 || lowCount > 0;
    final hasStatuses = !isOnlyIntent &&
        (followingCount > 0 ||
            contactedCount > 0 ||
            invitedCount > 0 ||
            attendedCount > 0 ||
            enrolledCount > 0 ||
            pausedCount > 0);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // 全部
            _FilterCapsuleChip(
              label: '全部 (${baseClues.length})',
              isSelected: selectedFilter.isEmpty,
              color: const Color(0xFF1976D2),
              onTap: () => onSelect(''),
            ),

            // 意向度胶囊（仅显示有数据的标签）
            if (highCount > 0) ...[
              const SizedBox(width: 8),
              _FilterCapsuleChip(
                label: '🔥 高意向 ($highCount)',
                isSelected: selectedFilter == '高意向',
                color: const Color(0xFFD32F2F),
                onTap: () => onSelect(selectedFilter == '高意向' ? '' : '高意向'),
              ),
            ],
            if (medCount > 0) ...[
              const SizedBox(width: 8),
              _FilterCapsuleChip(
                label: '⚡ 中意向 ($medCount)',
                isSelected: selectedFilter == '中意向',
                color: const Color(0xFFE65100),
                onTap: () => onSelect(selectedFilter == '中意向' ? '' : '中意向'),
              ),
            ],
            if (lowCount > 0) ...[
              const SizedBox(width: 8),
              _FilterCapsuleChip(
                label: '❄️ 低意向 ($lowCount)',
                isSelected: selectedFilter == '低意向',
                color: const Color(0xFF757575),
                onTap: () => onSelect(selectedFilter == '低意向' ? '' : '低意向'),
              ),
            ],

            // 分割线与跟进状态胶囊（若为已试听 isOnlyIntent 模式则仅展示意向度）
            if (!isOnlyIntent) ...[
              if (hasIntents && hasStatuses)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 1,
                  height: 16,
                  color: Colors.grey[300],
                ),

              // 跟进状态胶囊（仅显示有数据的标签，已试听排第一）
              if (attendedCount > 0) ...[
                const SizedBox(width: 8),
                _FilterCapsuleChip(
                  label: '🎧 已试听 ($attendedCount)',
                  isSelected: selectedFilter == '已试听',
                  color: const Color(0xFF0097A7),
                  onTap: () => onSelect(selectedFilter == '已试听' ? '' : '已试听'),
                ),
              ],
              if (followingCount > 0) ...[
                const SizedBox(width: 8),
                _FilterCapsuleChip(
                  label: '⏳ 待跟进 ($followingCount)',
                  isSelected: selectedFilter == '待跟进',
                  color: const Color(0xFF0288D1),
                  onTap: () => onSelect(selectedFilter == '待跟进' ? '' : '待跟进'),
                ),
              ],
              if (contactedCount > 0) ...[
                const SizedBox(width: 8),
                _FilterCapsuleChip(
                  label: '💬 联系中 ($contactedCount)',
                  isSelected: selectedFilter == '联系中',
                  color: const Color(0xFF00897B),
                  onTap: () => onSelect(selectedFilter == '联系中' ? '' : '联系中'),
                ),
              ],
              if (invitedCount > 0) ...[
                const SizedBox(width: 8),
                _FilterCapsuleChip(
                  label: '📅 已邀约 ($invitedCount)',
                  isSelected: selectedFilter == '已邀约',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => onSelect(selectedFilter == '已邀约' ? '' : '已邀约'),
                ),
              ],
              if (enrolledCount > 0) ...[
                const SizedBox(width: 8),
                _FilterCapsuleChip(
                  label: '🎓 已报名 ($enrolledCount)',
                  isSelected: selectedFilter == '已报名',
                  color: const Color(0xFF2E7D32),
                  onTap: () => onSelect(selectedFilter == '已报名' ? '' : '已报名'),
                ),
              ],
              if (pausedCount > 0) ...[
                const SizedBox(width: 8),
                _FilterCapsuleChip(
                  label: '🚫 无效线索 ($pausedCount)',
                  isSelected: selectedFilter == '无效线索',
                  color: const Color(0xFF9E9E9E),
                  onTap: () => onSelect(selectedFilter == '无效线索' ? '' : '无效线索'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterCapsuleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterCapsuleChip({
    required this.label,
    required this.isSelected,
    this.color = const Color(0xFF1976D2),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}



/// 线索卡片组件（匹配原型图样式）
class _ClueCard extends StatelessWidget {
  final Clue clue;
  final VoidCallback onTap;

  const _ClueCard({required this.clue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasNextVisit = clue.nextVisitTime != null;
    final isOverdue =
        hasNextVisit && clue.nextVisitTime!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 专升本学情微勋章（方案B：届别 + 报考专业门类）
              _StudentProfileBadge(clue: clue),
              const SizedBox(width: 12),

              // 信息区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 昵称行
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            clue.wxNick,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 标签行：状态 + 意向
                    Row(
                      children: [
                        _StatusBadge(status: clue.status),
                        if (clue.intentLevel != IntentLevel.none) ...[
                          const SizedBox(width: 6),
                          _IntentBadge(level: clue.intentLevel),
                        ],
                      ],
                    ),
                    if (clue.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: clue.tags.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFFCBD5E1), width: 0.5),
                            ),
                            child: Text(
                              '#$t',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF475569),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 6),

                    // 回访时间
                    if (hasNextVisit)
                      Text(
                        '下次回访时间：${DateFormat('yyyy-MM-dd HH:mm').format(clue.nextVisitTime!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                      )
                    else
                      Text(
                        '未设置回访时间',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400]),
                      ),
                  ],
                ),
              ),

              // 来源与归属顾问标签
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SourceTag(source: clue.source),
                  Builder(
                    builder: (context) {
                      final provider = context.watch<AppProvider>();
                      final isManager = provider.canViewAllClues;
                      final hasOwner = clue.ownerName.trim().isNotEmpty;

                      if (hasOwner) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                                  width: 0.5),
                            ),
                            child: Text(
                              '👤 ${clue.ownerName}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      } else if (isManager) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFFE65100).withValues(alpha: 0.3),
                                  width: 0.5),
                            ),
                            child: const Text(
                              '👤 待分配',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 专升本学情微勋章（方案B：届别 + 报考专业门类）
class _StudentProfileBadge extends StatelessWidget {
  final Clue clue;
  const _StudentProfileBadge({required this.clue});

  @override
  Widget build(BuildContext context) {
    // 1. 提取届别文案 (如 "24级", "25届")
    String gradeStr = clue.grade.trim();
    if (gradeStr.isEmpty) {
      gradeStr = '升本';
    } else {
      if (gradeStr.length > 4) {
        gradeStr = gradeStr.substring(0, 4);
      }
    }

    // 2. 提取专业门类文案 (如 "经管", "理工", "文史", "教育", "艺术", "医学")
    String subjectStr = clue.subject.trim();
    if (subjectStr.isEmpty) {
      subjectStr = '待定';
    } else if (subjectStr.length > 3) {
      subjectStr = subjectStr.substring(0, 2);
    }

    // 3. 根据专业门类匹配专属考情色彩体系
    Color primaryColor;
    Color bgColor;

    final s = clue.subject.toLowerCase();
    if (s.contains('经管') ||
        s.contains('管') ||
        s.contains('经') ||
        s.contains('财') ||
        s.contains('商') ||
        s.contains('会')) {
      primaryColor = const Color(0xFF1565C0); // 经管蓝
      bgColor = const Color(0xFFE3F2FD);
    } else if (s.contains('理') ||
        s.contains('工') ||
        s.contains('计') ||
        s.contains('信') ||
        s.contains('电') ||
        s.contains('机')) {
      primaryColor = const Color(0xFF6A1B9A); // 理工紫
      bgColor = const Color(0xFFF3E5F5);
    } else if (s.contains('文') ||
        s.contains('史') ||
        s.contains('语') ||
        s.contains('法')) {
      primaryColor = const Color(0xFFE65100); // 文史暖橙
      bgColor = const Color(0xFFFFF3E0);
    } else if (s.contains('教') ||
        s.contains('师') ||
        s.contains('幼') ||
        s.contains('学前')) {
      primaryColor = const Color(0xFF2E7D32); // 教育翡翠绿
      bgColor = const Color(0xFFE8F5E9);
    } else if (s.contains('美') ||
        s.contains('艺') ||
        s.contains('设') ||
        s.contains('音')) {
      primaryColor = const Color(0xFFC2185B); // 艺术玫红
      bgColor = const Color(0xFFFCE4EC);
    } else if (s.contains('医') || s.contains('护') || s.contains('药')) {
      primaryColor = const Color(0xFF00897B); // 医学青绿
      bgColor = const Color(0xFFE0F2F1);
    } else {
      primaryColor = const Color(0xFF455A64); // 默认石板青灰
      bgColor = const Color(0xFFECEFF1);
    }

    return Container(
      width: 46,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.28),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            gradeStr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: primaryColor.withValues(alpha: 0.82),
              height: 1.05,
            ),
          ),
          Container(
            width: 18,
            height: 0.8,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: primaryColor.withValues(alpha: 0.25),
          ),
          Text(
            subjectStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

/// 线索状态标签
class _StatusBadge extends StatelessWidget {
  final ClueStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ClueStatus.following:
        color = Colors.blue;
        break;
      case ClueStatus.contacted:
        color = Colors.orange;
        break;
      case ClueStatus.invited:
        color = Colors.green;
        break;
      case ClueStatus.attended:
        color = Colors.teal;
        break;
      case ClueStatus.enrolled:
        color = const Color(0xFF7B1FA2);
        break;
      case ClueStatus.paused:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// 意向标签
class _IntentBadge extends StatelessWidget {
  final IntentLevel level;
  const _IntentBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level) {
      case IntentLevel.high:
        color = Colors.red;
        break;
      case IntentLevel.medium:
        color = Colors.orange;
        break;
      case IntentLevel.low:
        color = Colors.grey;
        break;
      case IntentLevel.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }
}

/// 来源标签（统一外观：白底+灰边+深色文字，品牌icon区分）
class _SourceTag extends StatelessWidget {
  final String source;
  const _SourceTag({required this.source});

  // 统一的标签容器外观
  static const _bgColor = Color(0xFFF7F8FA);
  static const _borderColor = Color(0xFFDEE2E8);
  static const _textColor = Color(0xFF444444);

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(source),
          const SizedBox(width: 5),
          Text(
            source,
            style: const TextStyle(
              fontSize: 12,
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(String source) {
    switch (source) {
      case '抖音':
        // 抖音：纯黑圆形背景 + 鲜明白色原生音乐音符矢量Icon
        return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFF161823),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.music_note_rounded,
            size: 12,
            color: Colors.white,
          ),
        );

      case '微信':
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF07C160),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 10,
            color: Colors.white,
          ),
        );

      case '小红书':
        // 小红书：品牌红圆角方块 + 清晰白色"书"字
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFFF2442),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: const Text(
            '书',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

      case '地推':
        return const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF1976D2));

      case '转介绍':
        return const Icon(Icons.people_alt_rounded, size: 15, color: Color(0xFF00897B));

      case '老带新':
        return const Icon(Icons.stars_rounded, size: 15, color: Color(0xFF7B1FA2));

      default:
        return const Icon(Icons.tag_rounded, size: 15, color: Color(0xFF757575));
    }
  }
}

// ─────────────────────────────────────
// 已报名专属卡片
// ─────────────────────────────────────
class _EnrolledCard extends StatelessWidget {
  final Clue clue;
  final VoidCallback onTap;

  const _EnrolledCard({required this.clue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const enrolledColor = Color(0xFF7B1FA2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 头像（紫色系）
              CircleAvatar(
                radius: 24,
                backgroundColor: enrolledColor.withValues(alpha: 0.12),
                child: Text(
                  clue.wxNick.isNotEmpty ? clue.wxNick[0] : '?',
                  style: const TextStyle(
                    color: enrolledColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 信息区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 昵称
                    Text(
                      clue.wxNick,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // 已报名标签 + 班型
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: enrolledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: enrolledColor.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            '已报名',
                            style: TextStyle(
                              fontSize: 11,
                              color: enrolledColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (clue.classType.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                clue.classType,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6A1B9A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // 报名日期
                    Row(
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '报名日期：${DateFormat('yyyy-MM-dd').format(clue.createTime)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),

                    // 微信号（有则显示）
                    if (clue.wxId.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.tag, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            clue.wxId,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 右侧：来源 + 箭头
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SourceTag(source: clue.source),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// 今日回访任务卡片
// ─────────────────────────────────────
class _TodayTaskCard extends StatelessWidget {
  final List<Clue> todayClues;
  final void Function(Clue) onTap;

  const _TodayTaskCard({required this.todayClues, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasTasks = todayClues.isNotEmpty;
    final now = DateTime.now();
    final dateStr =
        '${now.month}月${now.day}日 · 周${['一', '二', '三', '四', '五', '六', '日'][now.weekday - 1]}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: hasTasks
            ? const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasTasks ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (hasTasks ? const Color(0xFF1976D2) : Colors.black)
                .withValues(alpha: hasTasks ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: hasTasks
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFF1976D2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.today_outlined,
                    size: 16,
                    color:
                        hasTasks ? Colors.white : const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日回访任务',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: hasTasks
                              ? Colors.white
                              : const Color(0xFF333333),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasTasks
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // 任务数量徽章
                if (hasTasks)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${todayClues.length} 个任务',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            // 分割线
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: hasTasks
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.12),
              ),
            ),

            // 内容：任务列表 or 无任务提示
            if (!hasTasks)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text(
                    '今日无回访任务，好好休息 🎉',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              )
            else
              ...todayClues.map((clue) {
                final t = clue.nextVisitTime!;
                final timeStr =
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                final isOverdue = t.isBefore(now);

                return GestureDetector(
                  onTap: () => onTap(clue),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // 时间
                        Container(
                          width: 44,
                          alignment: Alignment.center,
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isOverdue
                                  ? Colors.orange[300]
                                  : Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.3),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        // 昵称 + 状态/意向标签 + 学科班型
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      clue.wxNick,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _TodayStatusBadge(status: clue.status),
                                  if (clue.intentLevel != IntentLevel.none) ...[
                                    const SizedBox(width: 4),
                                    _TodayIntentBadge(level: clue.intentLevel),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  clue.ownerName.isNotEmpty
                                      ? '👤 ${clue.ownerName}'
                                      : '👤 待分配',
                                  if (clue.subject.isNotEmpty) clue.subject,
                                  if (clue.classType.isNotEmpty)
                                    clue.classType,
                                ].join(' · '),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // 逾期标记
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '逾期',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white),
                            ),
                          )
                        else
                          const Icon(Icons.chevron_right,
                              color: Colors.white54, size: 18),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// 今日回访条目专属状态徽标（针对深色渐变卡片高对比优化）
class _TodayStatusBadge extends StatelessWidget {
  final ClueStatus status;
  const _TodayStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case ClueStatus.following:
        bg = const Color(0xFF38BDF8).withValues(alpha: 0.25);
        fg = const Color(0xFFBAE6FD);
        break;
      case ClueStatus.contacted:
        bg = const Color(0xFFFB923C).withValues(alpha: 0.25);
        fg = const Color(0xFFFED7AA);
        break;
      case ClueStatus.invited:
        bg = const Color(0xFF4ADE80).withValues(alpha: 0.25);
        fg = const Color(0xFFBBF7D0);
        break;
      case ClueStatus.attended:
        bg = const Color(0xFF2DD4BF).withValues(alpha: 0.25);
        fg = const Color(0xFF99F6E4);
        break;
      case ClueStatus.enrolled:
        bg = const Color(0xFFC084FC).withValues(alpha: 0.25);
        fg = const Color(0xFFE9D5FF);
        break;
      case ClueStatus.paused:
        bg = Colors.white.withValues(alpha: 0.15);
        fg = Colors.white60;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 今日回访条目专属意向徽标（针对深色渐变卡片高对比优化）
class _TodayIntentBadge extends StatelessWidget {
  final IntentLevel level;
  const _TodayIntentBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (level) {
      case IntentLevel.high:
        bg = const Color(0xFFEF5350).withValues(alpha: 0.32);
        fg = const Color(0xFFFFCDD2);
        break;
      case IntentLevel.medium:
        bg = const Color(0xFFFFA726).withValues(alpha: 0.32);
        fg = const Color(0xFFFFE0B2);
        break;
      case IntentLevel.low:
        bg = Colors.white.withValues(alpha: 0.15);
        fg = Colors.white70;
        break;
      case IntentLevel.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 待回访多阶梯任务分组标题栏（带彩色指示条与半透明数量胶囊）
class _TodoSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _TodoSectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
