class Masterclass {
  final int id;
  final String title;
  final String location;
  final double price;
  final String website;
  final String imageUrl;
  final String format;
  final String company;
  final String category;
  final int minAge;
  final double rating;
  final String description;
  final String eventDate;
  final String duration;
  final String organizer;
  final String audience;
  final String additionalTags;
  final String? contactTg;
  final String? contactVk;
  final String? contactPhone;

  Masterclass({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.website,
    required this.imageUrl,
    required this.format,
    required this.company,
    required this.category,
    required this.minAge,
    required this.rating,
    required this.description,
    required this.eventDate,
    required this.duration,
    required this.organizer,
    required this.audience,
    required this.additionalTags,
    this.contactTg,
    this.contactVk,
    this.contactPhone,
  });

  factory Masterclass.fromJson(Map<String, dynamic> json) {
    return Masterclass(
      id: (json['id'] as num).toInt(),
      title: json['title'],
      location: json['location'],
      price: (json['price'] as num).toDouble(),
      website: json['website'],
      imageUrl: json['image_url'],
      format: json['format'] ?? 'offline',
      company: json['company'] ?? 'single',
      category: json['category'] ?? '',
      minAge: json['min_age'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      description: json['description'] ?? '',
      eventDate: json['event_date'] ?? '',
      duration: json['duration'] ?? '',
      organizer: json['organizer'] ?? '',
      audience: json['audience'] ?? '',
      additionalTags: json['additional_tags'] ?? '',
      contactTg: json['contact_tg'],
      contactVk: json['contact_vk'],
      contactPhone: json['contact_phone'],
    );
  }
}
