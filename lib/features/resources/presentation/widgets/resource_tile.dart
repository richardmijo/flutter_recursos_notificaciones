import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_recursos_notificaciones/core/cache/custom_cache_manager.dart';
import 'package:flutter_recursos_notificaciones/features/resources/domain/resource.dart';

/// A tile widget that shows a resource and demonstrates best-practice usages:
/// - SVG for vector assets
/// - Cached network image with custom CacheManager
/// - Image.asset usage with cacheWidth/cacheHeight when applicable
class ResourceTile extends StatelessWidget {
  final Resource resource;
  const ResourceTile({Key? key, required this.resource}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            // Render according to resource type
            if (resource.type == ResourceType.svg)
              // Best practice: use an SVG asset for icons to reduce bundle size and scaling issues
              Row(
                children: [
                  SvgPicture.asset(
                    resource.source,
                    width: 80,
                    height: 80,
                    // provide placeholder color and semantics
                    semanticsLabel: 'SVG icon',
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text('SVG: scalable vector resource (small size).'))
                ],
              )
            else if (resource.type == ResourceType.asset)
              // If using raster asset (not used in the sample) prefer providing
              // cacheWidth/cacheHeight to scale early and reduce memory usage:
              Row(
                children: [
                  Image.asset(resource.source, width: 120, height: 80, cacheWidth: 480),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Raster Asset with resizing/caching enabled'))
                ],
              )
            else
              // For network images: use CachedNetworkImage + a custom cache manager
              CachedNetworkImage(
                cacheManager: CustomCacheManager.instance,
                imageUrl: resource.source,
                // Provide width/height to allow Flutter to compute a scaled version
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
                // We could also specify memCacheWidth/memCacheHeight for further control
              ),
          ],
        ),
      ),
    );
  }
}
