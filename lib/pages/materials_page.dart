import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/material_item.dart';
import '../models/material_type.dart';
import 'add_edit_material_page.dart';

/// 物料池范围
enum _MaterialScope { public, private, pending }

Color _categoryColor(String category) {
  const colors = [
    Color(0xFF1976D2),
    Color(0xFF00897B),
    Color(0xFFE65100),
    Color(0xFF7B1FA2),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFF558B2F),
    Color(0xFF4527A0),
  ];
  return colors[category.hashCode.abs() % colors.length];
}

IconData _categoryIcon(String category) {
  const icons = [
    Icons.waving_hand_outlined,
    Icons.menu_book_outlined,
    Icons.refresh_outlined,
    Icons.check_circle_outline,
    Icons.campaign_outlined,
    Icons.emoji_events_outlined,
    Icons.star_outline,
    Icons.people_outline,
  ];
  return icons[category.hashCode.abs() % icons.length];
}

/// 我的物料页面（公共物料库 + 个人私有物料库 + 超管审核流）
class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _MaterialScope _currentScope = _MaterialScope.public;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _goToAddEdit({
    required AppMaterialType type,
    TextMaterial? textItem,
    ImageMaterial? imageItem,
    bool defaultToPublic = true,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditMaterialPage(
          type: type,
          textMaterial: textItem,
          imageMaterial: imageItem,
          defaultToPublic: defaultToPublic,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext ctx, String title) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (dlg) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('删除物料', style: TextStyle(fontSize: 16)),
            content: Text('确定要删除「$title」吗？删除后无法恢复。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlg, false),
                child: const Text('取消',
                    style: TextStyle(color: Color(0xFF888888))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dlg, true),
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final isSuper = provider.isSuperAdmin;
        final pendingCount = provider.totalPendingMaterialsCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text('物料与话术库'),
            actions: [
              PopupMenuButton<AppMaterialType>(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: '添加物料',
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (type) => _goToAddEdit(
                  type: type,
                  defaultToPublic: _currentScope == _MaterialScope.public,
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: AppMaterialType.text,
                    child: Row(children: [
                      Icon(Icons.text_fields,
                          color: Color(0xFF1976D2), size: 18),
                      SizedBox(width: 10),
                      Text('添加文字话术'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: AppMaterialType.image,
                    child: Row(children: [
                      Icon(Icons.image_outlined,
                          color: Color(0xFF00897B), size: 18),
                      SizedBox(width: 10),
                      Text('添加图片物料'),
                    ]),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '📝  文字话术'),
                Tab(text: '🖼️  宣传图片'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
            ),
          ),
          body: Column(
            children: [
              // 顶部物料池切换导航（公共池 / 个人专属池 / 待审核）
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    _ScopeTabButton(
                      label: '🌍 公共物料库',
                      count: _tabController.index == 0
                          ? provider.publicTextMaterials.length
                          : provider.publicImageMaterials.length,
                      isSelected: _currentScope == _MaterialScope.public,
                      selectedColor: const Color(0xFF1976D2),
                      onTap: () =>
                          setState(() => _currentScope = _MaterialScope.public),
                    ),
                    const SizedBox(width: 6),
                    _ScopeTabButton(
                      label: '🔒 我的专属池',
                      count: _tabController.index == 0
                          ? provider.myPrivateTextMaterials.length
                          : provider.myPrivateImageMaterials.length,
                      isSelected: _currentScope == _MaterialScope.private,
                      selectedColor: const Color(0xFF00897B),
                      onTap: () => setState(
                          () => _currentScope = _MaterialScope.private),
                    ),
                    if (isSuper) ...[
                      const SizedBox(width: 6),
                      _ScopeTabButton(
                        label: '📋 待审核',
                        count: pendingCount,
                        badgeColor: Colors.red,
                        isSelected: _currentScope == _MaterialScope.pending,
                        selectedColor: const Color(0xFFE65100),
                        onTap: () => setState(
                            () => _currentScope = _MaterialScope.pending),
                      ),
                    ],
                  ],
                ),
              ),

              // 物料内容列表
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTextTabContent(context, provider),
                    _buildImageTabContent(context, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextTabContent(BuildContext context, AppProvider provider) {
    switch (_currentScope) {
      case _MaterialScope.public:
        final byCat = provider.publicTextMaterialsByCategory;
        final cats = provider.publicTextCategories;
        return _TextMaterialsList(
          byCategory: byCat,
          categories: cats,
          isPublicPool: true,
          canManage: provider.isSuperAdmin,
          onAdd: () => _goToAddEdit(
              type: AppMaterialType.text, defaultToPublic: true),
          onEdit: (item) => _goToAddEdit(
              type: AppMaterialType.text,
              textItem: item,
              defaultToPublic: true),
          onDelete: (item) async {
            final ok = await _confirmDelete(context, item.title);
            if (ok && context.mounted) {
              provider.deleteTextMaterial(item.id);
            }
          },
        );

      case _MaterialScope.private:
        final byCat = provider.myTextMaterialsByCategory;
        final cats = provider.myTextCategories;
        return _TextMaterialsList(
          byCategory: byCat,
          categories: cats,
          isPublicPool: false,
          canManage: true, // 个人池自己始终可增删改
          onAdd: () => _goToAddEdit(
              type: AppMaterialType.text, defaultToPublic: false),
          onEdit: (item) => _goToAddEdit(
              type: AppMaterialType.text,
              textItem: item,
              defaultToPublic: false),
          onDelete: (item) async {
            final ok = await _confirmDelete(context, item.title);
            if (ok && context.mounted) {
              provider.deleteTextMaterial(item.id);
            }
          },
          onSubmitReview: (item) {
            provider.submitMaterialForReview(item.id, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚀 已提交申请加入公共物料池，等待超级管理员审核！'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );

      case _MaterialScope.pending:
        final pending = provider.pendingReviewTextMaterials;
        return _PendingReviewTextList(
          items: pending,
          onApprove: (item) {
            provider.approveMaterial(item.id, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 已通过「${item.title}」并同步至公共物料库！'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onReject: (item, reason) {
            provider.rejectMaterial(item.id, true, reason);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已驳回「${item.title}」'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        );
    }
  }

  Widget _buildImageTabContent(BuildContext context, AppProvider provider) {
    switch (_currentScope) {
      case _MaterialScope.public:
        final byCat = provider.publicImageMaterialsByCategory;
        final cats = provider.publicImageCategories;
        return _ImageMaterialsList(
          byCategory: byCat,
          categories: cats,
          isPublicPool: true,
          canManage: provider.isSuperAdmin,
          onAdd: () => _goToAddEdit(
              type: AppMaterialType.image, defaultToPublic: true),
          onEdit: (item) => _goToAddEdit(
              type: AppMaterialType.image,
              imageItem: item,
              defaultToPublic: true),
          onDelete: (item) async {
            final ok = await _confirmDelete(context, item.title);
            if (ok && context.mounted) {
              provider.deleteImageMaterial(item.id);
            }
          },
        );

      case _MaterialScope.private:
        final byCat = provider.myImageMaterialsByCategory;
        final cats = provider.myImageCategories;
        return _ImageMaterialsList(
          byCategory: byCat,
          categories: cats,
          isPublicPool: false,
          canManage: true,
          onAdd: () => _goToAddEdit(
              type: AppMaterialType.image, defaultToPublic: false),
          onEdit: (item) => _goToAddEdit(
              type: AppMaterialType.image,
              imageItem: item,
              defaultToPublic: false),
          onDelete: (item) async {
            final ok = await _confirmDelete(context, item.title);
            if (ok && context.mounted) {
              provider.deleteImageMaterial(item.id);
            }
          },
          onSubmitReview: (item) {
            provider.submitMaterialForReview(item.id, false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚀 图片物料已提交申请加入公共池，等待超管审核！'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );

      case _MaterialScope.pending:
        final pending = provider.pendingReviewImageMaterials;
        return _PendingReviewImageList(
          items: pending,
          onApprove: (item) {
            provider.approveMaterial(item.id, false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ 已通过图片「${item.title}」并同步至公共库！'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onReject: (item, reason) {
            provider.rejectMaterial(item.id, false, reason);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已驳回图片「${item.title}」'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        );
    }
  }
}

/// 顶部小 Tab 按钮
class _ScopeTabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color selectedColor;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ScopeTabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.selectedColor,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.1)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                ? selectedColor.withValues(alpha: 0.4)
                : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? selectedColor : const Color(0xFF555555),
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor ??
                        (isSelected
                            ? selectedColor
                            : Colors.grey.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// 文字话术列表组件
// ─────────────────────────────────────
class _TextMaterialsList extends StatelessWidget {
  final Map<String, List<TextMaterial>> byCategory;
  final List<String> categories;
  final bool isPublicPool;
  final bool canManage;
  final VoidCallback onAdd;
  final void Function(TextMaterial) onEdit;
  final void Function(TextMaterial) onDelete;
  final void Function(TextMaterial)? onSubmitReview;

  const _TextMaterialsList({
    required this.byCategory,
    required this.categories,
    required this.isPublicPool,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.onSubmitReview,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(isPublicPool ? '公共物料库暂无话术' : '您的专属私有池暂无话术',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(isPublicPool ? '添加第一条公共话术' : '添加我的第一条专属话术'),
              onPressed: onAdd,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final items = byCategory[cat] ?? [];
        final color = _categoryColor(cat);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10, top: i == 0 ? 0 : 16),
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
                  Icon(_categoryIcon(cat), size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ),
                  if (canManage)
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 12, color: color),
                            const SizedBox(width: 3),
                            Text('新增',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ...items.map((item) => _TextMaterialCard(
                  item: item,
                  color: color,
                  isPublicPool: isPublicPool,
                  canManage: canManage,
                  onEdit: () => onEdit(item),
                  onDelete: () => onDelete(item),
                  onSubmitReview: onSubmitReview != null
                      ? () => onSubmitReview!(item)
                      : null,
                )),
          ],
        );
      },
    );
  }
}

class _TextMaterialCard extends StatefulWidget {
  final TextMaterial item;
  final Color color;
  final bool isPublicPool;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSubmitReview;

  const _TextMaterialCard({
    required this.item,
    required this.color,
    required this.isPublicPool,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    this.onSubmitReview,
  });

  @override
  State<_TextMaterialCard> createState() => _TextMaterialCardState();
}

class _TextMaterialCardState extends State<_TextMaterialCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = widget.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 头部标题栏 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!widget.isPublicPool) ...[
                        const SizedBox(width: 6),
                        _ReviewStatusBadge(status: item.reviewStatus),
                      ],
                    ],
                  ),
                ),
                _CopyButton(
                    text: item.content, color: color, title: item.title),
                if (widget.canManage) ...[
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 16, color: Colors.grey[500]),
                    onPressed: widget.onEdit,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: '编辑',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: Colors.red),
                    onPressed: widget.onDelete,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    tooltip: '删除',
                  ),
                ],
              ],
            ),
          ),

          // ── 内容展示 ──
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Text(
                    item.content,
                    maxLines: _expanded ? null : 3,
                    overflow:
                        _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                if (item.content.length > 60)
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                      child: Text(
                        _expanded ? '收起 ▲' : '展开全文 ▼',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── 私有池专属操作：申请上架到公共池 ──
          if (!widget.isPublicPool &&
              item.reviewStatus != MaterialReviewStatus.pending &&
              item.reviewStatus != MaterialReviewStatus.approved) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  if (item.reviewStatus == MaterialReviewStatus.rejected &&
                      item.rejectReason.isNotEmpty) ...[
                    Expanded(
                      child: Text(
                        '驳回原因: ${item.rejectReason}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.red),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else
                    const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined, size: 14),
                    label: const Text('申请上架公共池',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                      side: const BorderSide(color: Color(0xFF1976D2)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: widget.onSubmitReview,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────
// 宣传图片列表组件
// ─────────────────────────────────────
class _ImageMaterialsList extends StatelessWidget {
  final Map<String, List<ImageMaterial>> byCategory;
  final List<String> categories;
  final bool isPublicPool;
  final bool canManage;
  final VoidCallback onAdd;
  final void Function(ImageMaterial) onEdit;
  final void Function(ImageMaterial) onDelete;
  final void Function(ImageMaterial)? onSubmitReview;

  const _ImageMaterialsList({
    required this.byCategory,
    required this.categories,
    required this.isPublicPool,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.onSubmitReview,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(isPublicPool ? '公共图片库暂无图片' : '您的专属池暂无图片物料',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(isPublicPool ? '添加第一张公共海报' : '上传我的专属素材'),
              onPressed: onAdd,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final items = byCategory[cat] ?? [];
        final color = _categoryColor(cat);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10, top: i == 0 ? 0 : 16),
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
                  Icon(_categoryIcon(cat), size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$cat  ${items.length}张',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ),
                  if (canManage)
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 12, color: color),
                            const SizedBox(width: 3),
                            Text('新增',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, j) {
                  return _ImageMaterialCard(
                    item: items[j],
                    color: color,
                    isPublicPool: isPublicPool,
                    canManage: canManage,
                    onEdit: () => onEdit(items[j]),
                    onDelete: () => onDelete(items[j]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImageMaterialCard extends StatelessWidget {
  final ImageMaterial item;
  final Color color;
  final bool isPublicPool;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ImageMaterialCard({
    required this.item,
    required this.color,
    required this.isPublicPool,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasRealImage = item.imageData != null && item.imageData!.isNotEmpty;

    return InkWell(
      onTap: () => _showImageDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: color.withValues(alpha: 0.08),
                      child: hasRealImage
                          ? Image.memory(
                              base64Decode(item.imageData!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 32, color: color),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined,
                                      size: 36, color: color),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      item.title,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  if (canManage)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.edit_outlined,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white, size: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasRealImage)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 10),
                            SizedBox(width: 2),
                            Text('预览',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.desc.isEmpty ? '点击查看海报' : item.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetail(BuildContext context) {
    final hasRealImage = item.imageData != null && item.imageData!.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶栏：标题与关闭
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // 图片本体（支持双指缩放）
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 380),
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.04),
                  child: hasRealImage
                      ? InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.8,
                          maxScale: 3.5,
                          child: Image.memory(
                            base64Decode(item.imageData!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 64, color: color),
                              const SizedBox(height: 8),
                              const Text('暂未上传高清海报图片',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
              ),

              // 底部说明与快捷复制
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.desc.isNotEmpty) ...[
                      const Text(
                        '推荐配文与使用场景：',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Text(
                          item.desc,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF2C3E50), height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        if (item.desc.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: item.desc));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('已复制推荐配文，可直接粘贴发给学生或朋友圈！'),
                                    backgroundColor: Color(0xFF00897B),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              label: const Text('复制推荐配文'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: color,
                                side: BorderSide(color: color),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('关 闭'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// 待审核面板（超管专属）
// ─────────────────────────────────────
class _PendingReviewTextList extends StatelessWidget {
  final List<TextMaterial> items;
  final void Function(TextMaterial) onApprove;
  final void Function(TextMaterial, String) onReject;

  const _PendingReviewTextList({
    required this.items,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 56, color: Colors.green),
            SizedBox(height: 12),
            Text('目前没有待审核的文字话术，太棒了！',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '【${item.category}】',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      '提交人: ${item.ownerName}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.content,
                      style: const TextStyle(
                          fontSize: 13, height: 1.5, color: Color(0xFF444444))),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _showRejectDialog(context, item),
                      child: const Text('驳回'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('通过入库'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => onApprove(item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, TextMaterial item) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('驳回申请 - ${item.title}'),
        content: TextField(
          controller: reasonCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '驳回原因/修改建议',
            hintText: '如：话术需补充针对性优惠说明',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              Navigator.pop(ctx);
              onReject(item, reason.isEmpty ? '不符合公共库收录规范' : reason);
            },
            child: const Text('确认驳回', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PendingReviewImageList extends StatelessWidget {
  final List<ImageMaterial> items;
  final void Function(ImageMaterial) onApprove;
  final void Function(ImageMaterial, String) onReject;

  const _PendingReviewImageList({
    required this.items,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 56, color: Colors.green),
            SizedBox(height: 12),
            Text('目前没有待审核的图片素材！',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.orange, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('【${item.category}】 · 提交人: ${item.ownerName}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                      if (item.desc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.desc,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => onApprove(item),
                      child: const Text('通过', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => onReject(item, '不符合公共库规范'),
                      child: const Text('驳回', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 审核状态 Badge
class _ReviewStatusBadge extends StatelessWidget {
  final String status;
  const _ReviewStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MaterialReviewStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('⏳ 审核中',
              style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
        );
      case MaterialReviewStatus.approved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('✅ 公共池',
              style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
        );
      case MaterialReviewStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('❌ 已驳回',
              style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('🔒 个人专属',
              style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
        );
    }
  }
}

// ─────────────────────────────────────
// 快捷复制按钮
// ─────────────────────────────────────
class _CopyButton extends StatefulWidget {
  final String text;
  final Color color;
  final String title;

  const _CopyButton({
    required this.text,
    required this.color,
    required this.title,
  });

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制「${widget.title}」'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _copied
              ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
              : widget.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check : Icons.copy,
              size: 13,
              color: _copied ? const Color(0xFF2E7D32) : widget.color,
            ),
            const SizedBox(width: 4),
            Text(
              _copied ? '已复制' : '复制',
              style: TextStyle(
                fontSize: 12,
                color: _copied ? const Color(0xFF2E7D32) : widget.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
