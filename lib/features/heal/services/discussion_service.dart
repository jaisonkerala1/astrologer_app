import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discussion_models.dart';

class DiscussionService {
  static const String _discussionsKey = 'discussions';
  static const String _commentsKey = 'comments';
  static const String _favoritesKey = 'favorites';
  static const String _astrologerHistoryKey = 'astrologer_history';

  // Save discussion post
  static Future<void> saveDiscussion(DiscussionPost post) async {
    final prefs = await SharedPreferences.getInstance();
    final discussions = await getDiscussions();
    discussions.insert(0, post);
    
    final discussionsJson = discussions.map((d) => d.toJson()).toList();
    await prefs.setString(_discussionsKey, jsonEncode(discussionsJson));
  }

  // Get all discussions
  static Future<List<DiscussionPost>> getDiscussions() async {
    final prefs = await SharedPreferences.getInstance();
    final discussionsJson = prefs.getString(_discussionsKey);
    
    if (discussionsJson == null) return [];
    
    final List<dynamic> discussionsList = jsonDecode(discussionsJson);
    return discussionsList.map((json) => DiscussionPost.fromJson(json)).toList();
  }

  // Save comment
  static Future<void> saveComment(String discussionId, DiscussionComment comment) async {
    final prefs = await SharedPreferences.getInstance();
    final comments = await getComments(discussionId);
    comments.insert(0, comment);
    
    final commentsJson = comments.map((c) => c.toJson()).toList();
    await prefs.setString('${_commentsKey}_$discussionId', jsonEncode(commentsJson));
  }

  // Get comments for a discussion
  static Future<List<DiscussionComment>> getComments(String discussionId) async {
    final prefs = await SharedPreferences.getInstance();
    final commentsJson = prefs.getString('${_commentsKey}_$discussionId');
    
    if (commentsJson == null) return [];
    
    final List<dynamic> commentsList = jsonDecode(commentsJson);
    return commentsList.map((json) => DiscussionComment.fromJson(json)).toList();
  }

  // Add to favorites
  static Future<void> addToFavorites(String discussionId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (!favorites.contains(discussionId)) {
      favorites.add(discussionId);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Remove from favorites
  static Future<void> removeFromFavorites(String discussionId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(discussionId);
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // Get favorites
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // Save astrologer activity
  static Future<void> saveAstrologerActivity(AstrologerActivity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final activities = await getAstrologerHistory();
    activities.insert(0, activity);
    
    // Keep only last 100 activities
    if (activities.length > 100) {
      activities.removeRange(100, activities.length);
    }
    
    final activitiesJson = activities.map((a) => a.toJson()).toList();
    await prefs.setString(_astrologerHistoryKey, jsonEncode(activitiesJson));
  }

  // Get astrologer history
  static Future<List<AstrologerActivity>> getAstrologerHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final activitiesJson = prefs.getString(_astrologerHistoryKey);
    
    if (activitiesJson == null) return [];
    
    final List<dynamic> activitiesList = jsonDecode(activitiesJson);
    return activitiesList.map((json) => AstrologerActivity.fromJson(json)).toList();
  }

  // Like/Unlike discussion
  static Future<void> toggleLike(String discussionId, bool isLiked) async {
    final discussions = await getDiscussions();
    final discussionIndex = discussions.indexWhere((d) => d.id == discussionId);
    
    if (discussionIndex != -1) {
      discussions[discussionIndex].isLiked = isLiked;
      discussions[discussionIndex].likes += isLiked ? 1 : -1;
      
      final prefs = await SharedPreferences.getInstance();
      final discussionsJson = discussions.map((d) => d.toJson()).toList();
      await prefs.setString(_discussionsKey, jsonEncode(discussionsJson));
    }
  }

  // Like/Unlike comment
  static Future<void> toggleCommentLike(String discussionId, String commentId, bool isLiked) async {
    final comments = await getComments(discussionId);
    final commentIndex = comments.indexWhere((c) => c.id == commentId);
    
    if (commentIndex != -1) {
      comments[commentIndex].isLiked = isLiked;
      comments[commentIndex].likes += isLiked ? 1 : -1;
      
      final prefs = await SharedPreferences.getInstance();
      final commentsJson = comments.map((c) => c.toJson()).toList();
      await prefs.setString('${_commentsKey}_$discussionId', jsonEncode(commentsJson));
    }
  }
}






































