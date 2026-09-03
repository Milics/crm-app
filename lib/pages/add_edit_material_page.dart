import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/material_item.dart';
import '../models/material_type.dart';

/// 添加/编辑物料页面
class AddEditMaterialPage extends StatefulWidget {
  final AppMaterialType type;
  final TextMaterial? textMaterial;
  final ImageMaterial? imageMaterial;
  final bool defaultToPublic;

  const AddEditMaterialPage({
    super.key,
    required this.type,
    this.textMaterial,
    this.imageMaterial,
    this.defaultToPublic = true,
  });

  @override
  State<AddEditMaterialPage> createState() => _AddEditMaterialPageState();
}

class _AddEditMaterialPageState extends State<AddEditMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _categoryCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;

  bool get _isEdit =>
      widget.textMaterial != null || widget.imageMaterial != null;
  bool get _isText => widget.type == AppMaterialType.text;

  List<String> _existingCategories = [];

  // 保存位置与审核选项
  late bool _saveToPublic;
  bool _applyForReview = false;

  // 图片物料专属：真实 Base64 图片数据
  String? _imageBase64;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final isSuper = provider.isSuperAdmin;

    if (_isText) {
      final m = widget.textMaterial;
      _categoryCtrl = TextEditingController(text: m?.category ?? '');
      _titleCtrl = TextEditingController(text: m?.title ?? '');
      _contentCtrl = TextEditingController(text: m?.content ?? '');
      _existingCategories = provider.publicTextCategories;
      _saveToPublic = m?.isPublic ?? (isSuper && widget.defaultToPublic);
      _applyForReview = m?.reviewStatus == MaterialReviewStatus.pending;
    } else {
      final m = widget.imageMaterial;
      _categoryCtrl = TextEditingController(text: m?.category ?? '');
      _titleCtrl = TextEditingController(text: m?.title ?? '');
      _contentCtrl = TextEditingController(text: m?.desc ?? '');
      _imageBase64 = m?.imageData;
      _existingCategories = provider.publicImageCategories;
      _saveToPublic = m?.isPublic ?? (isSuper && widget.defaultToPublic);
      _applyForReview = m?.reviewStatus == MaterialReviewStatus.pending;
    }
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isPickingImage = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final isSuper = provider.isSuperAdmin;
    final category = _categoryCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    final isPublic = isSuper ? _saveToPublic : false;
    final reviewStatus = isPublic
        ? MaterialReviewStatus.approved
        : (_applyForReview
            ? MaterialReviewStatus.pending
            : MaterialReviewStatus.none);

    if (_isText) {
      if (_isEdit) {
        provider.updateTextMaterial(
          widget.textMaterial!.copyWith(
            category: category,
            title: title,
            content: content,
            isPublic: isPublic,
            reviewStatus: reviewStatus,
          ),
        );
      } else {
        provider.addTextMaterial(TextMaterial(
          id: 'tm_${DateTime.now().millisecondsSinceEpoch}',
          category: category,
          title: title,
          content: content,
          ownerName: provider.currentUser,
          isPublic: isPublic,
          reviewStatus: reviewStatus,
        ));
      }
    } else {
      if (_imageBase64 == null || _imageBase64!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 请先点击上传一张宣传海报或图片！'),
            backgroundColor: Colors.deepOrange,
          ),
        );
        return;
      }

      if (_isEdit) {
        provider.updateImageMaterial(
          widget.imageMaterial!.copyWith(
            category: category,
            title: title,
            desc: content,
            imageData: _imageBase64,
            isPublic: isPublic,
            reviewStatus: reviewStatus,
          ),
        );
      } else {
        provider.addImageMaterial(ImageMaterial(
          id: 'im_${DateTime.now().millisecondsSinceEpoch}',
          category: category,
          title: title,
          desc: content,
          imageData: _imageBase64,
          ownerName: provider.currentUser,
          isPublic: isPublic,
          reviewStatus: reviewStatus,
        ));
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPublic
            ? '✅ 已保存至公共物料库并全员同步'
            : (_applyForReview ? '🚀 已保存至个人池并提交超管审核' : '✅ 已保存至我的私有物料池')),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isSuper = provider.isSuperAdmin;

    final primaryColor =
        _isText ? const Color(0xFF1976D2) : const Color(0xFF00897B);
    final pageTitle = _isEdit
        ? (_isText ? '编辑文字物料' : '编辑图片物料')
        : (_isText ? '添加文字物料' : '添加图片物料');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(pageTitle),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 归属池与审核选项
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSuper
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.admin_panel_settings,
                                size: 16, color: Color(0xFF1976D2)),
                            SizedBox(width: 6),
                            Text('保存目标物料池（管理员特权）',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🌍 全局公共池 (全员同步)',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                selected: _saveToPublic,
                                selectedColor: const Color(0xFF1976D2),
                                labelStyle: TextStyle(
                                    color: _saveToPublic
                                        ? Colors.white
                                        : Colors.black87),
                                onSelected: (v) =>
                                    setState(() => _saveToPublic = true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('🔒 我的专属池 (私有)',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                selected: !_saveToPublic,
                                selectedColor: const Color(0xFFE65100),
                                labelStyle: TextStyle(
                                    color: !_saveToPublic
                                        ? Colors.white
                                        : Colors.black87),
                                onSelected: (v) =>
                                    setState(() => _saveToPublic = false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lock_outline,
                                size: 16, color: Colors.blueGrey),
                            SizedBox(width: 6),
                            Text('保存至：🔒 我的专属物料池（个人自用）',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blueGrey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('🚀 同步申请上架到公共物料池',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('开启后将提交给超级管理员审核，通过后全员可见',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          value: _applyForReview,
                          activeThumbColor: const Color(0xFF1976D2),
                          onChanged: (val) =>
                              setState(() => _applyForReview = val),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // 分类
            _buildSection(
              label: '分类',
              required: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _categoryCtrl,
                    decoration: _inputDecoration(
                        hint: '输入或选择已有分类', color: primaryColor),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请填写分类' : null,
                  ),
                  if (_existingCategories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _existingCategories.map((cat) {
                        return GestureDetector(
                          onTap: () => _categoryCtrl.text = cat,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                    fontSize: 12, color: primaryColor)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 标题
            _buildSection(
              label: '标题',
              required: true,
              child: TextFormField(
                controller: _titleCtrl,
                decoration:
                    _inputDecoration(hint: '物料名称，简短易懂', color: primaryColor),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请填写标题' : null,
              ),
            ),

            const SizedBox(height: 16),

            // 图片物料专属：宣传海报 / 招生简章选择区
            if (!_isText) ...[
              _buildSection(
                label: '宣传海报 / 简章图片',
                required: true,
                child: _buildImagePickerArea(primaryColor),
              ),
              const SizedBox(height: 16),
            ],

            // 内容 / 说明
            _buildSection(
              label: _isText ? '话术内容' : '图片推荐配文与说明',
              required: true,
              child: TextFormField(
                controller: _contentCtrl,
                maxLines: _isText ? 8 : 4,
                decoration: _inputDecoration(
                  hint: _isText
                      ? '输入完整的话术文字内容，支持换行与表情 emoji'
                      : '简要说明此图片的适用场景与推荐配文，方便老师发朋友圈或微信沟通',
                  color: primaryColor,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请填写内容' : null,
              ),
            ),

            const SizedBox(height: 32),

            // 底部大保存按钮
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _save,
                child: const Text('保 存',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 图片物料专属海报选择预览组件
  Widget _buildImagePickerArea(Color color) {
    if (_isPickingImage) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 12),
            Text('正在压缩处理图片...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_imageBase64 != null && _imageBase64!.isNotEmpty) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black12,
              child: Image.memory(
                base64Decode(_imageBase64!),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('图片格式解析失败', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _imageBase64 = null),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('删除图片', style: TextStyle(color: Colors.red, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showImageSourceDialog(),
                icon: const Icon(Icons.change_circle_outlined, size: 16),
                label: const Text('重新选择', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => _showImageSourceDialog(),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 42, color: color),
            const SizedBox(height: 8),
            Text(
              '点击上传招生海报 / 课程简章图片',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '支持拍照或手机相册，自动高保真压缩并多端秒级同步',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择海报或图片来源',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1976D2)),
              title: const Text('从手机相册选取'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF00897B)),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required bool required,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              if (required)
                const Text(' *',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required Color color}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: 1.5),
      ),
    );
  }
}
