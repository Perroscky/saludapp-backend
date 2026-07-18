// ignore_for_file: unused_field

import 'package:postgres/postgres.dart';
import '../config/database.dart';

class CacheService {
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _defaultTTL = Duration(minutes: 10);
  
  static Future<List<Map<String, dynamic>>> getEspecialidades() async {
    final cacheKey = 'especialidades_all';
    
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid()) {
      print('✅ [CACHÉ] Sirviendo desde caché');
      return _cache[cacheKey]!.data;
    }
    
    print('🔄 [CACHÉ] Consultando base de datos...');
    final conn = await DatabaseConfig.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM especialidades ORDER BY nombre')
    );
    
    final data = result.map((row) {
      final map = row.toColumnMap();
      return {
        'id': _toInt(map['id']),
        'nombre': map['nombre']?.toString() ?? '',
        'descripcion': map['descripcion']?.toString() ?? '',
      };
    }).toList();
    
    _cache[cacheKey] = _CacheEntry(data);
    print('💾 [CACHÉ] Guardado en caché (TTL: 10 min)');
    
    return data;
  }
  
  static void invalidate(String key) {
    _cache.remove(key);
    print('🗑️ [CACHÉ] Caché invalidada para: $key');
  }
  
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  
  _CacheEntry(this.data) : createdAt = DateTime.now();
  
  bool isValid() {
    return DateTime.now().difference(createdAt) < const Duration(minutes: 10);
  }
}