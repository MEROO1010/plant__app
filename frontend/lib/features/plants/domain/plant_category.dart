class PlantCategory {
  const PlantCategory({required this.id, required this.name, required this.slug, this.description, this.icon, this.color});

  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String? color;

  factory PlantCategory.fromJson(Map<String, dynamic> json) => PlantCategory(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug, 'description': description, 'icon': icon, 'color': color};
}
