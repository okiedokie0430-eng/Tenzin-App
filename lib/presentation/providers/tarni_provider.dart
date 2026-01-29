import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tarni_entry.dart';
import '../../data/repositories/tarni_repository.dart';
import 'dao_providers.dart';
import 'core_providers.dart';

final tarniRepositoryProvider = Provider((ref) => TarniRepository(ref.read(tarniDaoProvider), ref.read(secureStorageProvider)));

final tarniListProvider = StateNotifierProvider<TarniListNotifier, List<TarniEntry>>(
  (ref) => TarniListNotifier(ref.read(tarniRepositoryProvider)),
);

class TarniListNotifier extends StateNotifier<List<TarniEntry>> {
  final TarniRepository _repo;

  TarniListNotifier(this._repo) : super([]) {
    load();
  }

  Future<void> load() async {
    final items = await _repo.fetchAll();
    state = items;
  }

  Future<void> add(int magzushir, int janraisig) async {
    final entry = await _repo.create(magzushir, janraisig);
    if (entry != null) {
      state = [entry, ...state.where((e) => e.id != entry.id)];
    }
  }

  Future<void> updateEntry(String id, int magzushir, int janraisig) async {
    final ok = await _repo.update(id, magzushir, janraisig);
    if (!ok) return;
    state = state.map((e) => e.id == id ? TarniEntry(id: e.id, magzushirCount: magzushir, janraisigCount: janraisig, createdAt: e.createdAt) : e).toList();
  }

  Future<void> remove(String id) async {
    final ok = await _repo.delete(id);
    if (!ok) return;
    state = state.where((e) => e.id != id).toList();
  }
}
