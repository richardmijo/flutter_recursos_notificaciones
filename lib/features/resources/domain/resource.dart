// Resource model and enums used by the resources feature.
// This model abstracts different resource types the app can load and optimize.

enum ResourceType { asset, network, svg }

class Resource {
  final String id;
  final String source; // asset path or network URL
  final ResourceType type;
  final String description;

  const Resource({
    required this.id,
    required this.source,
    required this.type,
    required this.description,
  });
}
