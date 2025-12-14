import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_recursos_notificaciones/core/cache/custom_cache_manager.dart';
import 'package:flutter_recursos_notificaciones/features/resources/domain/resource.dart';

/// Un widget 'tile' que muestra un recurso y demuestra buenas prácticas:
/// - SVG para recursos vectoriales
/// - Imagen de red en caché usando un CacheManager personalizado
/// - Uso de Image.asset con cacheWidth/cacheHeight cuando es aplicable
class ResourceTile extends StatelessWidget {
  final Resource resource;
  final Duration? loadDuration;
  final bool? isCached;
  final int? cachedBytes;
  const ResourceTile({
    Key? key,
    required this.resource,
    this.loadDuration,
    this.isCached,
    this.cachedBytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            // Fila de métricas pequeñas: muestra si está en caché y tiempo de carga aproximado
            Row(
              children: [
                if (resource.type == ResourceType.network) ...[
                  if (isCached ?? false)
                    Text(
                      'En caché: ${((cachedBytes ?? 0) / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Text(
                      'En caché: no',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ] else ...[
                  Text(
                    resource.type == ResourceType.svg
                        ? 'Incluido: SVG'
                        : 'Incluido: asset',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(width: 12),
                if (loadDuration != null)
                  Text(
                    'Carga: ${loadDuration!.inMilliseconds} ms',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            // Renderizar de acuerdo al tipo de recurso
            if (resource.type == ResourceType.svg)
              // Buena práctica: usar un asset SVG para íconos para reducir tamaño y evitar pixelado
              Row(
                children: [
                  SvgPicture.asset(
                    resource.source,
                    width: 80,
                    height: 80,
                    // proveer color y semántica
                    semanticsLabel: 'Icono SVG',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'SVG: recurso vectorial escalable (tamaño pequeño).',
                    ),
                  ),
                ],
              )
            else if (resource.type == ResourceType.asset)
              // Si se usa asset rasterizado (no usado en ejemplo) preferir proveer
              // cacheWidth/cacheHeight para escalar temprano y reducir uso de memoria:
              Row(
                children: [
                  Image.asset(
                    resource.source,
                    width: 120,
                    height: 80,
                    cacheWidth: 480,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Asset Rasterizado con redimensionamiento/caché habilitado',
                    ),
                  ),
                ],
              )
            else
              // Para imágenes de red: usar CachedNetworkImage + un cache manager personalizado
              CachedNetworkImage(
                cacheManager: CustomCacheManager.instance,
                imageUrl: resource.source,
                // Proveer width/height para permitir a Flutter computar una versión escalada
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  height: 200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade100,
                  height: 200,
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
                // Podríamos especificar memCacheWidth/memCacheHeight para mayor control
              ),
          ],
        ),
      ),
    );
  }
}
