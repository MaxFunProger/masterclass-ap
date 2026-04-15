import '../../../core/api_client.dart';
import '../domain/masterclass.dart';

class MasterclassService {
  final ApiClient apiClient;

  MasterclassService(this.apiClient);

  Future<List<Masterclass>> getMasterclasses({
    String? format,
    String? company,
    List<String>? categories,
    int? minAge,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    List<String>? audience,
    String? tags,
    String? sortOrder,
    String? eventDateFrom,
    String? eventDateTo,
    int? offset,
    int? limit,
    List<int>? excludeIds,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (format != null) queryParams['format'] = format;
      if (company != null) queryParams['company'] = company;
      if (categories != null && categories.isNotEmpty)
        queryParams['category'] = categories.join(',');
      if (minAge != null) queryParams['min_age'] = minAge;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;
      if (minRating != null) queryParams['min_rating'] = minRating;
      if (audience != null && audience.isNotEmpty)
        queryParams['audience'] = audience.join(',');
      if (tags != null) queryParams['tags'] = tags;
      if (sortOrder != null) queryParams['sort_order'] = sortOrder;
      if (eventDateFrom != null) queryParams['event_date_from'] = eventDateFrom;
      if (eventDateTo != null) queryParams['event_date_to'] = eventDateTo;
      if (offset != null) queryParams['offset'] = offset;
      if (limit != null) queryParams['n'] = limit;
      if (excludeIds != null && excludeIds.isNotEmpty) {
        queryParams['exclude_ids'] = excludeIds.join(',');
      }

      final response =
          await apiClient.dio.get('/mclist', queryParameters: queryParams);

      final List<dynamic> list = response.data['masterclasses'];
      return list.map((e) => Masterclass.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load masterclasses: $e');
    }
  }
}
