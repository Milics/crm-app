import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/clue.dart';
import '../models/material_item.dart';

/// 云端 Firestore 存储与同步服务
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? _db;
  bool _isAvailable = false;

  /// 云端服务是否已准备就绪
  bool get isAvailable => _isAvailable;

  /// 初始化 Firestore（配置离线持久化）
  void initialize() {
    try {
      _db = FirebaseFirestore.instance;
      if (!kIsWeb) {
        try {
          _db!.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        } catch (e) {
          debugPrint('⚠️ [Firestore] 设置离线缓存选项异常 (已忽略): $e');
        }
      }
      _isAvailable = true;
      debugPrint('☁️ [Firestore] 云端数据库已初始化完成');
    } catch (e) {
      _isAvailable = false;
      debugPrint('⚠️ [Firestore] 初始化失败，将使用纯本地模式: $e');
    }
  }

  // ==================== 线索管理 ====================

  /// 集合引用
  CollectionReference<Map<String, dynamic>>? get _cluesRef =>
      _isAvailable && _db != null ? _db!.collection('crm_clues') : null;

  /// 实时监听所有线索
  Stream<List<Clue>>? get cluesStream {
    if (!_isAvailable || _cluesRef == null) return null;
    return _cluesRef!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Clue.fromJson(data);
      }).toList();
    });
  }

  /// 一次性获取所有线索（优先读本地缓存/离线）
  Future<List<Clue>?> fetchAllClues() async {
    if (!_isAvailable || _cluesRef == null) return null;
    try {
      final snapshot = await _cluesRef!.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Clue.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [Firestore] 获取线索失败: $e');
      return null;
    }
  }

  /// 强制从云端服务器（跳过本地旧缓存）拉取所有最新线索
  Future<List<Clue>?> fetchCluesFromServer() async {
    if (!_isAvailable || _cluesRef == null) return null;
    try {
      final snapshot =
          await _cluesRef!.get(const GetOptions(source: Source.server));
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Clue.fromJson(data);
      }).toList();
      debugPrint('☁️ [Firestore] 强制从服务器同步成功，获取到 ${list.length} 条线索');
      return list;
    } catch (e) {
      debugPrint('⚠️ [Firestore] Server 强制同步失败，尝试默认获取: $e');
      return fetchAllClues();
    }
  }

  /// 保存或更新单个线索
  Future<bool> saveClue(Clue clue) async {
    if (!_isAvailable || _cluesRef == null) return false;
    try {
      await _cluesRef!.doc(clue.id).set(clue.toJson(), SetOptions(merge: true));
      debugPrint('☁️ [Firestore] 线索已保存到云端: ${clue.id} (${clue.wxNick})');
      return true;
    } catch (e) {
      debugPrint('⚠️ [Firestore] 保存线索失败 (${clue.id}): $e');
      return false;
    }
  }

  /// 删除单个线索
  Future<bool> deleteClue(String clueId) async {
    if (!_isAvailable || _cluesRef == null) return false;
    try {
      await _cluesRef!.doc(clueId).delete();
      return true;
    } catch (e) {
      debugPrint('⚠️ [Firestore] 删除线索失败 ($clueId): $e');
      return false;
    }
  }

  /// 批量上传/迁移本地线索到云端
  Future<void> batchUploadClues(List<Clue> clues) async {
    if (!_isAvailable || _db == null || clues.isEmpty) return;
    try {
      final batch = _db!.batch();
      for (final clue in clues) {
        final docRef = _cluesRef!.doc(clue.id);
        batch.set(docRef, clue.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('☁️ [Firestore] 成功迁移 ${clues.length} 条线索到云端');
    } catch (e) {
      debugPrint('⚠️ [Firestore] 批量迁移线索失败: $e');
    }
  }

  // ==================== 物料库管理 ====================

  CollectionReference<Map<String, dynamic>>? get _textMaterialsRef =>
      _isAvailable && _db != null ? _db!.collection('crm_text_materials') : null;

  CollectionReference<Map<String, dynamic>>? get _imageMaterialsRef =>
      _isAvailable && _db != null ? _db!.collection('crm_image_materials') : null;

  /// 实时监听文字物料
  Stream<List<TextMaterial>>? get textMaterialsStream {
    if (!_isAvailable || _textMaterialsRef == null) return null;
    return _textMaterialsRef!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TextMaterial.fromJson(data);
      }).toList();
    });
  }

  /// 保存文字物料
  Future<bool> saveTextMaterial(TextMaterial material) async {
    if (!_isAvailable || _textMaterialsRef == null) return false;
    try {
      await _textMaterialsRef!
          .doc(material.id)
          .set(material.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('⚠️ [Firestore] 保存文字物料失败: $e');
      return false;
    }
  }

  /// 删除文字物料
  Future<bool> deleteTextMaterial(String id) async {
    if (!_isAvailable || _textMaterialsRef == null) return false;
    try {
      await _textMaterialsRef!.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('⚠️ [Firestore] 删除文字物料失败: $e');
      return false;
    }
  }

  /// 保存图片物料
  Future<bool> saveImageMaterial(ImageMaterial material) async {
    if (!_isAvailable || _imageMaterialsRef == null) return false;
    try {
      await _imageMaterialsRef!
          .doc(material.id)
          .set(material.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('⚠️ [Firestore] 保存图片物料失败: $e');
      return false;
    }
  }

  /// 删除图片物料
  Future<bool> deleteImageMaterial(String id) async {
    if (!_isAvailable || _imageMaterialsRef == null) return false;
    try {
      await _imageMaterialsRef!.doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('⚠️ [Firestore] 删除图片物料失败: $e');
      return false;
    }
  }

  /// 批量上传文字物料
  Future<void> batchUploadTextMaterials(List<TextMaterial> list) async {
    if (!_isAvailable || _db == null || list.isEmpty) return;
    try {
      final batch = _db!.batch();
      for (final item in list) {
        final docRef = _textMaterialsRef!.doc(item.id);
        batch.set(docRef, item.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ [Firestore] 批量迁移文字物料失败: $e');
    }
  }
}
