class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String userAvatar;
  final String content;
  final DateTime timestamp;
  final List<String> tags;
  final int likes;
  final int comments;
  final bool isLikedByCurrentUser;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
    this.tags = const [],
    this.likes = 0,
    this.comments = 0,
    this.isLikedByCurrentUser = false,
  });

  // Create a mock post (for demo purposes)
  factory CommunityPost.mockPost({
    required String id,
    required String content,
    DateTime? timestamp,
  }) {
    return CommunityPost(
      id: id,
      userId: 'user_$id',
      username: 'User $id',
      userAvatar: 'https://i.pravatar.cc/150?u=$id',
      content: content,
      timestamp:
          timestamp ?? DateTime.now().subtract(Duration(hours: int.parse(id))),
      tags: ['support', 'sharing'],
      likes: (int.parse(id) * 5) % 30,
      comments: (int.parse(id) * 3) % 15,
      isLikedByCurrentUser: int.parse(id) % 2 == 0,
    );
  }

  // Create a list of mock posts (for demo purposes)
  static List<CommunityPost> getMockPosts() {
    return [
      CommunityPost.mockPost(
        id: '1',
        content:
            'Just had my first ultrasound after being diagnosed with an ovarian cyst. The doctor said it\'s a simple cyst and likely to resolve on its own. Has anyone else experienced this? What was your journey like?',
      ),
      CommunityPost.mockPost(
        id: '2',
        content:
            'Found out I have a 5cm dermoid cyst that needs surgery. Feeling anxious about the procedure. Any advice from those who\'ve gone through laparoscopic surgery?',
      ),
      CommunityPost.mockPost(
        id: '3',
        content:
            'Today marks one year since my ovarian cyst diagnosis. I\'ve learned so much about my body and how to manage pain. If anyone needs support or has questions, I\'m here to help!',
      ),
      CommunityPost.mockPost(
        id: '4',
        content:
            'Does anyone have recommendations for natural remedies that helped with cyst-related discomfort? I\'m trying to reduce my reliance on pain medication.',
      ),
      CommunityPost.mockPost(
        id: '5',
        content:
            'Had my follow-up appointment today and my cyst has shrunk from 4cm to 2.5cm in three months! Sharing this positive news to give hope to others.',
      ),
    ];
  }

  // Convert from Map to CommunityPost object
  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      id: map['id'],
      userId: map['userId'],
      username: map['username'],
      userAvatar: map['userAvatar'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      tags: List<String>.from(map['tags'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      isLikedByCurrentUser: map['isLikedByCurrentUser'] ?? false,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'tags': tags,
      'likes': likes,
      'comments': comments,
      'isLikedByCurrentUser': isLikedByCurrentUser,
    };
  }

  // Create a copy with updated values
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    String? content,
    DateTime? timestamp,
    List<String>? tags,
    int? likes,
    int? comments,
    bool? isLikedByCurrentUser,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}
