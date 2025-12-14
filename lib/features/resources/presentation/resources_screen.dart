import 'package:flutter/material.dart';

import 'package:flutter_recursos_notificaciones/features/resources/data/resource_repository.dart';
import 'package:flutter_recursos_notificaciones/features/resources/domain/resource.dart';
import 'package:flutter_recursos_notificaciones/features/resources/presentation/widgets/resource_tile.dart';

/// ResourcesScreen demonstrates efficient usage of assets and remote resources.
/// This screen shows examples of SVGs, cached network images, and tips to reduce
/// memory and bundle size. It follows a small 'feature' structure with a
/// repository returning demo resources.
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final repository = const ResourceRepository();
  late final List<Resource> resources;
  bool _precache = true;

  @override
  void initState() {
    super.initState();
    resources = repository.getResources();
    // Precache assets for smoother UX, especially when navigating into views.
    // This is a tradeoff: it increases memory used but improves perceived speed.
    if (_precache) {
      _precacheAssets();
    }
  }

  void _precacheAssets() async {
    for (final res in resources) {
      if (res.type == ResourceType.asset) {
        // For raster asset, precache with a target for scaled size if needed
        await precacheImage(AssetImage(res.source), context);
      } else if (res.type == ResourceType.network) {
        // For network images, prefetching is done with the network cache manager
        // or by calling `CachedNetworkImageProvider(url).resolve()` to warm the
        // image in the memory cache — avoid prefetching too many large images
        // to prevent high network/bandwidth usage.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Optimización de recursos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.image),
                const SizedBox(width: 8),
                Expanded(child: Text('Ejemplos y buenas prácticas para recursos')),
                Switch(
                  value: _precache,
                  onChanged: (v) => setState(() => _precache = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: resources.length,
              itemBuilder: (context, idx) {
                final r = resources[idx];
                return ResourceTile(resource: r);
              },
            ),
          ),
        ],
      ),
    );
  }
}
