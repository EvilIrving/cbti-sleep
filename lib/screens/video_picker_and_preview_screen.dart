import 'dart:io';

import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'video_editor_screen.dart';

class VideoPickerAndPreviewScreen extends StatefulWidget {
  const VideoPickerAndPreviewScreen({super.key});

  @override
  State<VideoPickerAndPreviewScreen> createState() => _VideoPickerAndPreviewScreenState();
}

class _VideoPickerAndPreviewScreenState extends State<VideoPickerAndPreviewScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      debugPrint('[VideoPicker] Opening insta assets picker...');
      
      final List<AssetEntity>? assets = await InstaAssetPicker.pickAssets(
        context,
        pickerConfig: const InstaAssetPickerConfig(
          title: '选择视频',
          // 禁用裁剪功能，因为我们有自己的视频编辑器
          cropDelegate: InstaAssetCropDelegate(
            cropRatios: [1.0], // 只有一个比例，这样就不会显示裁剪界面
          ),
        ),
        maxAssets: 1, // 只允许选择一个视频
        onCompleted: (Stream<InstaAssetsExportDetails> stream) {
          // 这里我们不需要处理裁剪流，直接在选择完成后处理
        },
      );

      if (assets == null || assets.isEmpty) {
        debugPrint('[VideoPicker] User canceled or no assets selected');
        return;
      }

      // 获取选中的视频文件
      final AssetEntity asset = assets.first;
      final File? file = await asset.file;
      
      if (file == null) {
        debugPrint('[VideoPicker] Failed to get file from asset');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('获取视频文件失败')));
        }
        return;
      }

      // 直接进入统一裁剪页面
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoEditorScreen(videoPath: file.path),
        ),
      );
    } catch (e) {
      debugPrint('[VideoPicker] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择视频失败: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final double cardWidth = MediaQuery.of(context).size.width - 32;
    final double cardHeight = cardWidth * 0.55;
    return Scaffold(
      backgroundColor: const Color(0xFF11131A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF11131A),
        // 移除title
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFC3A0),
                    Color(0xFFF48FB1),
                    Color(0xFF8E9BFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_circle, size: 64, color: Colors.white),
                  SizedBox(height: 12),
                  Text('开始创作', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum EditorMode { trim, cropCanvas }


