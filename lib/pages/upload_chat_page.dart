import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/clue.dart';
import '../providers/app_provider.dart';
import 'ai_analysis_page.dart';

/// 上传聊天截图页面（真实相册多选 + 对话核心要点提炼 + 客户档案沉淀）
class UploadChatPage extends StatefulWidget {
  final String clueId;
  const UploadChatPage({super.key, required this.clueId});

  @override
  State<UploadChatPage> createState() => _UploadChatPageState();
}

class _UploadChatPageState extends State<UploadChatPage> {
  // 选中的真实聊天截图 Base64 数据
  final List<String> _selectedImages = [];
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isProcessing = false;

  // 快捷沟通标签（点击可快速录入对话核心特征）
  final List<String> _presetTags = [
    '基础薄弱',
    '价格敏感',
    '对比竞品',
    '家长决策',
    '担心考不上',
    '询问上课时间',
    '跨专业升本',
    '意向强烈',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      setState(() => _isProcessing = true);
      final picker = ImagePicker();

      if (source == ImageSource.gallery) {
        final pickedList = await picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 75,
        );
        for (final item in pickedList) {
          final bytes = await item.readAsBytes();
          _selectedImages.add(base64Encode(bytes));
        }
      } else {
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 75,
        );
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          _selectedImages.add(base64Encode(bytes));
        }
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择截图失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveRecords({bool thenOpenAi = false}) async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一张聊天截图！'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final provider = context.read<AppProvider>();
    final clue = provider.getClueById(widget.clueId);

    if (clue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('线索不存在'), backgroundColor: Colors.red),
      );
      setState(() => _isProcessing = false);
      return;
    }

    final newRecords = <ChatRecord>[];
    final notes = _notesCtrl.text.trim();

    for (int i = 0; i < _selectedImages.length; i++) {
      newRecords.add(
        ChatRecord(
          id: 'chat_${DateTime.now().millisecondsSinceEpoch}_$i',
          clueId: widget.clueId,
          imagePath: '',
          imageData: _selectedImages[i],
          ocrText: notes,
          createTime: DateTime.now(),
        ),
      );
    }

    await provider.addChatRecords(widget.clueId, newRecords);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 成功将 ${_selectedImages.length} 张聊天截图存入学员档案！'),
        backgroundColor: Colors.green,
      ),
    );

    if (thenOpenAi) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AiAnalysisPage(clue: clue)),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showImagePreview(String base64) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.memory(
                  base64Decode(base64),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('上传聊天截图'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部引导提示
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            color: Color(0xFF1976D2), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '上传微信对话截图并归档，系统自动沉淀至学员跟进时间轴，便于后续精准复盘与 AI 诊断。',
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 截图网格区域
                  Row(
                    children: [
                      const Text(
                        '聊天截图列表',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(已选 ${_selectedImages.length} 张)',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showPickerModal(),
                        icon: const Icon(Icons.add_photo_alternate_outlined,
                            size: 16),
                        label: const Text('继续选图', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (_selectedImages.isEmpty)
                    InkWell(
                      onTap: () => _showPickerModal(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: Color(0xFF1976D2)),
                            SizedBox(height: 8),
                            Text(
                              '点击添加微信聊天截图',
                              style: TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '支持相册多选或直接拍照',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return InkWell(
                            onTap: () => _showPickerModal(),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey[300]!, width: 1.2),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      color: Colors.grey[400], size: 28),
                                  const SizedBox(height: 4),
                                  Text('加截图',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        }

                        final imgBase64 = _selectedImages[index];
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePreview(imgBase64),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.black12,
                                  child: Image.memory(
                                    base64Decode(imgBase64),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedImages.removeAt(index)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 13),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // 对话要点记录框
                  const Text(
                    '对话核心要点提炼 / 备注',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),

                  // 快捷标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _presetTags.map((tag) {
                      return InkWell(
                        onTap: () {
                          final cur = _notesCtrl.text.trim();
                          if (cur.contains(tag)) return;
                          _notesCtrl.text =
                              cur.isEmpty ? '【$tag】' : '$cur 【$tag】';
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF1976D2)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '+ $tag',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _notesCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            '输入此段聊天中发现的学生核心诉求、顾虑点、意向科目或任何承诺事项...',
                        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey),
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 底部操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _saveRecords(thenOpenAi: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF1976D2)),
                      ),
                      child: const Text('仅保存至档案',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF1976D2))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _saveRecords(thenOpenAi: true),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('保存并AI分析',
                          style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B1FA2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerModal() {
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
                '选择聊天截图上传方式',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF1976D2)),
              title: const Text('从手机相册选取 (支持多选)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF00897B)),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
