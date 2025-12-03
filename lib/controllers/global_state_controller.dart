import 'package:get/get.dart';

/// Controller global para gerenciar atualizações de estado em todo o app
/// Força rebuilds quando mudanças importantes acontecem
class GlobalStateController extends GetxController {
  // Observables para forçar rebuilds
  final RxInt _forceRebuildCounter = 0.obs;
  final RxInt _profileUpdateCounter = 0.obs;
  final RxInt _themeUpdateCounter = 0.obs;
  
  // Getters para observar mudanças
  int get forceRebuildCounter => _forceRebuildCounter.value;
  int get profileUpdateCounter => _profileUpdateCounter.value;
  int get themeUpdateCounter => _themeUpdateCounter.value;

  /// Força rebuild global de toda a aplicação
  void forceGlobalRebuild() {
    _forceRebuildCounter.value++;
    update(['global_rebuild']);
    
    print('🔄 GlobalState: Forced global rebuild #${_forceRebuildCounter.value}');
  }

  /// Notifica que o perfil foi atualizado
  void notifyProfileUpdate() {
    _profileUpdateCounter.value++;
    _forceRebuildCounter.value++;
    
    update(['profile_update', 'global_rebuild']);
    
    // Força rebuild com delay para garantir propagação
    Future.delayed(const Duration(milliseconds: 10), () {
      update(['profile_update', 'global_rebuild']);
    });
    
    Future.delayed(const Duration(milliseconds: 50), () {
      update(['profile_update', 'global_rebuild']);
    });
    
    print('👤 GlobalState: Profile update #${_profileUpdateCounter.value}');
  }

  /// Notifica que o tema foi atualizado
  void notifyThemeUpdate() {
    _themeUpdateCounter.value++;
    _forceRebuildCounter.value++;
    
    update(['theme_update', 'global_rebuild']);
    
    // Força rebuild com delay para garantir propagação
    Future.delayed(const Duration(milliseconds: 10), () {
      update(['theme_update', 'global_rebuild']);
    });
    
    Future.delayed(const Duration(milliseconds: 50), () {
      update(['theme_update', 'global_rebuild']);
    });
    
    print('🎨 GlobalState: Theme update #${_themeUpdateCounter.value}');
  }

  /// Força limpeza completa de todos os caches
  void clearAllCaches() {
    print('🧹 GlobalState: Clearing all caches');
    
    // Força rebuild múltiplos
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 25), () {
        _forceRebuildCounter.value++;
        update(['cache_clear', 'global_rebuild']);
      });
    }
  }
}
