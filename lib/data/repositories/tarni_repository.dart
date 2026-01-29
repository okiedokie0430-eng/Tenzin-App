import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/platform/secure_storage.dart';
import '../models/tarni_entry.dart';
import '../local/daos/tarni_dao.dart';

class TarniRepository {
  final TarniDao? _tarniDao;
  final SecureStorageService _storage;

  TarniRepository(this._tarniDao, this._storage);

  static const String _localFallbackId = 'local_tarni';
  static const String _backupFileName = 'tarni_backup.json';

  Future<File> _backupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_backupFileName');
  }

  Future<List<TarniEntry>> _readBackupList() async {
    try {
      final f = await _backupFile();
      if (!await f.exists()) return [];
      final contents = await f.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      return list.map((e) => TarniEntry.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeBackupList(List<TarniEntry> entries) async {
    try {
      final f = await _backupFile();
      final encoded = jsonEncode(entries.map((e) => e.toMap()).toList());
      await f.writeAsString(encoded);
    } catch (_) {}
  }

  Future<List<TarniEntry>> fetchAll() async {
    try {
      final userId = await _storage.getUserId() ?? _localFallbackId;
      final local = await _tarniDao?.getByUserId(userId) ?? [];
      if (local.isNotEmpty) return local;
      final backup = await _readBackupList();
      return backup.where((e) => e.userId == userId).toList();
    } catch (e) {
      try {
        // ignore: avoid_print
        print('TarniRepository.fetchAll failed (local): $e');
      } catch (_) {}
      return [];
    }
  }

  Future<TarniEntry?> create(int magzushir, int janraisig) async {
    try {
      final userId = await _storage.getUserId() ?? _localFallbackId;
      final now = DateTime.now();
      final entry = TarniEntry(id: '', userId: userId, magzushirCount: magzushir, janraisigCount: janraisig, createdAt: now);
      final rowId = await _tarniDao?.insert(userId, entry);
      final created = await _tarniDao?.getById('${rowId ?? ''}');
      final all = await _tarniDao?.getByUserId(userId) ?? [];
      await _writeBackupList(all);
      return created;
    } catch (e) {
      try {
        // ignore: avoid_print
        print('TarniRepository.create failed (local): $e');
      } catch (_) {}
      return null;
    }
  }

  Future<bool> update(String id, int magzushir, int janraisig) async {
    try {
      final userId = await _storage.getUserId() ?? _localFallbackId;
      await _tarniDao?.updateById(id, magzushir, janraisig);
      final all = await _tarniDao?.getByUserId(userId) ?? [];
      await _writeBackupList(all);
      return true;
    } catch (e) {
      try {
        // ignore: avoid_print
        print('TarniRepository.update failed (local): $e');
      } catch (_) {}
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final userId = await _storage.getUserId() ?? _localFallbackId;
      await _tarniDao?.deleteById(id);
      final all = await _tarniDao?.getByUserId(userId) ?? [];
      await _writeBackupList(all);
      return true;
    } catch (e) {
      try {
        // ignore: avoid_print
        print('TarniRepository.delete failed (local): $e');
      } catch (_) {}
      return false;
    }
  }
}
