import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_recursos_notificaciones/core/cache/custom_cache_manager.dart';

import 'package:flutter_recursos_notificaciones/features/resources/data/resource_repository.dart';
import 'package:flutter_recursos_notificaciones/features/resources/domain/resource.dart';
import 'package:flutter_recursos_notificaciones/features/resources/presentation/widgets/resource_tile.dart';

/// ResourcesScreen demuestra el uso eficiente de assets y recursos remotos.
/// Esta pantalla muestra ejemplos de SVGs, imágenes de red en caché y consejos para reducir
/// el uso de memoria y el tamaño del bundle. Sigue una estructura pequeña de 'feature' con un
/// repositorio que devuelve recursos de demostración.
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final repository = const ResourceRepository();
  late List<Resource> resources;
  bool _precache = true;
  int _cachedCount = 0;
  int _cachedBytes = 0;
  final Map<String, Duration?> _loadTimes = {};
  final Map<String, bool> _isCachedMap = {};
  final Map<String, int> _cachedBytesMap = {};
  bool _isMeasuring = false;

  void _simulateHeavyLoad() {
    final start = resources.length + 1;
    final more = List.generate(
      20,
      (i) => Resource(
        id: 'sim_${start + i}',
        source: 'https://picsum.photos/seed/sim${start + i}/1200/900',
        type: ResourceType.network,
        description: 'Imagen grande simulada ${start + i}',
      ),
    );
    setState(() {
      resources = [...resources, ...more];
    });
  }

  @override
  void initState() {
    super.initState();
    resources = repository.getResources();
    // Precargar assets para una experiencia más fluida.
    // Esto es un compromiso: aumenta el uso de memoria pero mejora la velocidad percibida.
    if (_precache) {
      _precacheAssets();
    }
  }

  void _precacheAssets() async {
    for (final res in resources) {
      if (res.type == ResourceType.asset) {
        // Para assets rasterizados, precargar con un tamaño objetivo si es necesario
        await precacheImage(AssetImage(res.source), context);
      } else if (res.type == ResourceType.network) {
        // Para imágenes de red, el prefetching se hace con el administrador de caché de red
        // o llamando a `CachedNetworkImageProvider(url).resolve()` para calentar la
        // imagen en la caché de memoria — evitar prefetching de demasiadas imágenes grandes
        // para prevenir alto uso de red/ancho de banda.
      }
    }
    // Actualizar estadísticas de caché después del paso de prefetch.
    await _refreshCacheStats();
  }

  Future<void> _prefetchNetworkImages() async {
    // Precargar imágenes de red usando el administrador de caché — descarga y guarda archivos
    final networkResources = resources.where(
      (r) => r.type == ResourceType.network,
    );
    for (final r in networkResources) {
      try {
        await CustomCacheManager.instance.getSingleFile(r.source);
      } catch (e) {
        // ignorar errores para la demostración
      }
    }
    await _refreshCacheStats();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prefetch completado')));
    }
  }

  Future<void> _clearDiskCache() async {
    await CustomCacheManager.instance.emptyCache();
    await _refreshCacheStats();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Caché de disco vaciada')));
    }
  }

  void _clearMemoryCache() {
    // La caché de imágenes pintadas mantiene bitmaps decodificados; limpiar reduce uso de memoria inmediatamente.
    PaintingBinding.instance.imageCache.clear();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Caché en memoria vaciada')));
    }
  }

  Future<void> _refreshCacheStats() async {
    int cachedCount = 0;
    int cachedBytes = 0;
    for (final r in resources.where((r) => r.type == ResourceType.network)) {
      try {
        final fi = await CustomCacheManager.instance.getFileFromCache(r.source);
        if (fi != null) {
          cachedCount++;
          final f = fi.file;
          if (await f.exists()) {
            final length = await f.length();
            cachedBytes += length;
            _isCachedMap[r.id] = true;
            _cachedBytesMap[r.id] = length;
          }
        } else {
          _isCachedMap[r.id] = false;
          _cachedBytesMap[r.id] = 0;
        }
      } catch (_) {
        // ignorar errores para la demostración
        _isCachedMap[r.id] = false;
        _cachedBytesMap[r.id] = 0;
      }
    }
    setState(() {
      _cachedCount = cachedCount;
      _cachedBytes = cachedBytes;
    });
  }

  Future<Duration?> _measureImageLoad(
    String url, {
    bool forceClear = false,
  }) async {
    // Opcionalmente limpiar caché del archivo específico antes de medir
    if (forceClear) {
      await CustomCacheManager.instance.removeFile(url);
    }
    final provider = CachedNetworkImageProvider(
      url,
      cacheManager: CustomCacheManager.instance,
    );
    final completer = Completer<Duration?>();
    final sw = Stopwatch()..start();
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool syncCall) {
        sw.stop();
        completer.complete(sw.elapsed);
        stream.removeListener(listener);
      },
      onError: (dynamic _, __) {
        completer.complete(null);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  Future<void> _measureAllLoadTimes({bool ensureUncachedFirst = true}) async {
    if (_isMeasuring) return;
    setState(() => _isMeasuring = true);
    _loadTimes.clear();
    // Opcionalmente limpiar caché de disco para que la primera medición refleje tiempo de red
    if (ensureUncachedFirst) await CustomCacheManager.instance.emptyCache();
    for (final r in resources) {
      if (r.type == ResourceType.network) {
        final d = await _measureImageLoad(
          r.source,
          forceClear: !ensureUncachedFirst,
        );
        _loadTimes[r.id] = d;
      } else if (r.type == ResourceType.svg) {
        // Para assets SVG, medimos el tiempo de lectura del string como una aproximación
        final sw = Stopwatch()..start();
        try {
          await rootBundle.loadString(r.source);
          sw.stop();
          _loadTimes[r.id] = sw.elapsed;
        } catch (_) {
          _loadTimes[r.id] = null;
        }
      } else {
        // Para assets de imagen (jpg/png), medimos una resolución rápida del asset
        final p = AssetImage(r.source);
        final completer = Completer<Duration?>();
        final sw = Stopwatch()..start();
        final stream = p.resolve(const ImageConfiguration());
        late ImageStreamListener listener;
        listener = ImageStreamListener(
          (_, __) {
            sw.stop();
            completer.complete(sw.elapsed);
            stream.removeListener(listener);
          },
          onError: (_, __) {
            completer.complete(null);
            stream.removeListener(listener);
          },
        );
        stream.addListener(listener);
        final d = await completer.future;
        _loadTimes[r.id] = d;
      }
      // Actualizar estado para mostrar el progreso visualmente
      setState(() {});
    }
    await _refreshCacheStats();
    setState(() => _isMeasuring = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Optimización de Recursos')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Sección de Configuración
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.speed, color: Colors.amber),
                    title: const Text('Precarga de Recursos'),
                    subtitle: const Text(
                      'Habilita la carga anticipada de assets para evitar "saltos" en la UI.',
                    ),
                    trailing: Switch(
                      value: _precache,
                      onChanged: (v) => setState(() => _precache = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sección de Gestión de Caché
                Text(
                  'Gestión de Caché',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text(
                          'Controla manualmente la memoria y el almacenamiento para ver cómo afecta al rendimiento.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.download, size: 18),
                              label: const Text('Precargar Red'),
                              onPressed: _prefetchNetworkImages,
                              tooltip: 'Descarga imágenes remotas al disco',
                            ),
                            ActionChip(
                              avatar: const Icon(
                                Icons.delete_outline,
                                size: 18,
                              ),
                              label: const Text('Limpiar Disco'),
                              onPressed: _clearDiskCache,
                              tooltip:
                                  'Borra archivos cacheados en almacenamiento',
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.memory, size: 18),
                              label: const Text('Limpiar RAM'),
                              onPressed: _clearMemoryCache,
                              tooltip: 'Limpia la memoria de imagen inmediata',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sección de Pruebas y Diagnóstico
                Text(
                  'Pruebas de Rendimiento',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_photo_alternate),
                              onPressed: _simulateHeavyLoad,
                              label: const Text('Simular Carga (+20)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple.shade50,
                                foregroundColor: Colors.deepPurple,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.timer_outlined),
                              onPressed: _isMeasuring
                                  ? null
                                  : () async {
                                      await _measureAllLoadTimes(
                                        ensureUncachedFirst: true,
                                      );
                                    },
                              label: const Text('Medir (Sin Caché)'),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.timer),
                              onPressed: _isMeasuring
                                  ? null
                                  : () async {
                                      await _measureAllLoadTimes(
                                        ensureUncachedFirst: false,
                                      );
                                    },
                              label: const Text('Medir (Con Caché)'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sección de Estadísticas
                Card(
                  color: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estadísticas de Caché',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Items: $_cachedCount | Tamaño: ${(_cachedBytes / 1024).toStringAsFixed(2)} KB',
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _refreshCacheStats,
                          tooltip: 'Actualizar estadísticas',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const Center(
                  child: Text(
                    'Lista de Recursos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de recursos (No es scrollable por sí misma para no tener conflicto, usamos shrinkWrap o physics)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resources.length,
                  itemBuilder: (context, idx) {
                    final r = resources[idx];
                    return ResourceTile(
                      resource: r,
                      loadDuration: _loadTimes[r.id],
                      isCached: _isCachedMap[r.id] ?? false,
                      cachedBytes: _cachedBytesMap[r.id],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
