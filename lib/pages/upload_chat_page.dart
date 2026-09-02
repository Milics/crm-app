import 'package:flutter/material.dart';

/// 上传聊天截图独立页（原型图：图片网格 + 两个操作按钮）
class UploadChatPage extends StatefulWidget {
  final String clueId;
  const UploadChatPage({super.key, required this.clueId});

  @override
  State<UploadChatPage> createState() => _UploadChatPageState();
}

class _UploadChatPageState extends State<UploadChatPage> {
  // 模拟已上传图片（颜色代替真实图片）
  final List<Color> _mockImages = [
    Colors.blue[100]!,
    Colors.green[100]!,
    Colors.orange[100]!,
    Colors.purple[100]!,
    Colors.teal[100]!,
    Colors.red[100]!,
    Colors.indigo[100]!,
    Colors.cyan[100]!,
    Colors.lime[100]!,
  ];

  bool _uploading = false;

  Future<void> _uploadAndAnalyze() async {
    setState(() => _uploading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _uploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('上传成功，AI正在分析中...'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _uploadOnly() async {
    setState(() => _uploading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _uploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('截图已保存到客户档案')),
      );
      Navigator.pop(context);
    }
  }

  void _addMockImage() {
    setState(() {
      final colors = [
        Colors.pink[100]!,
        Colors.amber[100]!,
        Colors.deepPurple[100]!,
      ];
      _mockImages.add(colors[_mockImages.length % colors.length]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('上传聊天截图')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明文字
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '支持上传多张微信聊天截图，系统将自动识别对话内容并存入客户历史对话库',
                            style: TextStyle(
                                color: Colors.blue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 已选择标题
                  Row(
                    children: [
                      const Text(
                        '已选择',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Icon(Icons.cloud_upload_outlined,
                          color: Colors.grey[400]),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 图片网格
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _mockImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _mockImages.length) {
                        // 添加按钮
                        return GestureDetector(
                          onTap: _addMockImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey[300]!,
                                  style: BorderStyle.solid),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    color: Colors.grey[400], size: 32),
                                const SizedBox(height: 4),
                                Text('添加',
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _mockImages[index],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white70,
                                size: 32,
                              ),
                            ),
                          ),
                          // 删除按钮
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _mockImages.removeAt(index)),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 底部操作区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 识别统计
                Text(
                  '已上传 ${_mockImages.length} 张截图，共识别 ${_mockImages.length * 14} 条对话',
                  style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                // 上传并分析按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _uploading || _mockImages.isEmpty
                            ? null
                            : _uploadAndAnalyze,
                    style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14)),
                    child: _uploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('上传并AI分析',
                            style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),

                // 仅上传存档按钮
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _uploading || _mockImages.isEmpty
                        ? null
                        : _uploadOnly,
                    style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('仅上传存档',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
