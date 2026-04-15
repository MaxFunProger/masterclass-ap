import '../../../core/api_client.dart';
import '../../masterclasses/domain/masterclass.dart';
import '../domain/user_profile.dart';

class ProfileService {
  final ApiClient apiClient;

  ProfileService(this.apiClient);

  Future<UserProfile> getProfile(String userId) async {
    try {
      final response = await apiClient.dio
          .get('/user/profile', queryParameters: {'user_id': userId});
      return UserProfile.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load profile');
    }
  }

  Future<List<Masterclass>> getFavorites(String userId) async {
    final response = await apiClient.dio
        .get('/user/favorites', queryParameters: {'user_id': userId});
    final raw = response.data['masterclasses'];
    if (raw == null) return [];
    final list = raw as List<dynamic>;
    return list
        .map((e) => Masterclass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(String userId, int masterclassId) async {
    try {
      await apiClient.dio.post('/user/favorites',
          data: {'user_id': userId, 'masterclass_id': masterclassId});
    } catch (e) {
      throw Exception('Failed to add favorite');
    }
  }

  Future<void> removeFavorite(String userId, int masterclassId) async {
    try {
      await apiClient.dio.delete('/user/favorites', queryParameters: {
        'user_id': userId,
        'masterclass_id': masterclassId
      });
    } catch (e) {
      throw Exception('Failed to remove favorite');
    }
  }
}
