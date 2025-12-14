import '../domain/resource.dart';

/// A simple repository to expose resources used in demo pages.
/// In a real app this could fetch remote configuration or asset listings.
class ResourceRepository {
  const ResourceRepository();

  /// Returns a small set of example resources demonstrating different types.
  List<Resource> getResources() {
    return const [
      Resource(
        id: 'asset_svg',
        source: 'assets/images/icon.svg',
        type: ResourceType.svg,
        description:
            'Recurso vectorial (SVG) – ideal para íconos e ilustraciones sin perder calidad.',
      ),
      Resource(
        id: 'local_image',
        source: 'https://picsum.photos/seed/local/800/600',
        type: ResourceType.network,
        description:
            'Imagen remota estándar: demuestra el uso de caché y redimensionamiento.',
      ),
      Resource(
        id: 'large_image',
        source: 'https://picsum.photos/seed/large/1200/900',
        type: ResourceType.network,
        description:
            'Imagen remota grande: útil para observar el impacto en memoria y los tiempos de carga.',
      ),
    ];
  }
}
