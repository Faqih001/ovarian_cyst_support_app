import 'package:flutter/material.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/models/community_post.dart';
import 'package:ovarian_cyst_support_app/services/data_persistence_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late List<CommunityPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to load posts from local storage
      final localPosts = await DataPersistenceService.getCommunityPosts();

      if (localPosts.isNotEmpty) {
        // If we have local posts, use them
        setState(() {
          _posts =
              localPosts
                  .map((postMap) => CommunityPost.fromMap(postMap))
                  .toList();
          _isLoading = false;
        });
      } else {
        // Otherwise use mock data (in a real app, you'd fetch from a server)
        final mockPosts = CommunityPost.getMockPosts();

        // Save mock posts to local storage for offline access
        await DataPersistenceService.saveCommunityPosts(
          mockPosts.map((post) => post.toMap()).toList(),
        );

        setState(() {
          _posts = mockPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If all else fails, use mock data without saving
      setState(() {
        _posts = CommunityPost.getMockPosts();
        _isLoading = false;
      });
      debugPrint('Error loading posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Community Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.1),
            child: Column(
              children: [
                const Text(
                  'Connect with others on a similar journey',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share experiences, ask questions, and provide support in a safe space',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadPosts,
                      color: AppColors.primary,
                      child:
                          _posts.isEmpty
                              ? const Center(
                                child: Text(
                                  'No posts yet. Be the first to share!',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: _posts.length,
                                itemBuilder: (context, index) {
                                  return _buildPostCard(_posts[index]);
                                },
                              ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreatePostDialog();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    // Calculate relative time
    final now = DateTime.now();
    final difference = now.difference(post.timestamp);

    String timeAgo;
    if (difference.inDays > 7) {
      timeAgo =
          '${post.timestamp.day}/${post.timestamp.month}/${post.timestamp.year}';
    } else if (difference.inDays > 0) {
      timeAgo =
          '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      timeAgo =
          '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo =
          '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      timeAgo = 'Just now';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      post.userAvatar.startsWith('http')
                          ? NetworkImage(post.userAvatar) as ImageProvider
                          : null,
                  child:
                      post.userAvatar.startsWith('http')
                          ? null
                          : Text(
                            post.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(post.content, style: const TextStyle(fontSize: 15)),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children:
                    post.tags.map((tag) {
                      return Chip(
                        label: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                          ),
                        ),
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLikedByCurrentUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            post.isLikedByCurrentUser
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        // In a real app, you would implement liking functionality
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likes}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.comment, color: AppColors.textLight, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.share, color: AppColors.textLight, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Share',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    final TextEditingController postController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share your thoughts with the community',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: postController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (postController.text.isNotEmpty) {
                  // Create a new post with a unique ID
                  final newId = '${_posts.length + 1}';
                  final newPost = CommunityPost(
                    id: newId,
                    userId: 'current_user',
                    username: 'You',
                    userAvatar: '',
                    content: postController.text,
                    timestamp: DateTime.now(),
                    tags: ['support'],
                    isLikedByCurrentUser: false,
                  );

                  // Add to local list
                  setState(() {
                    _posts.insert(0, newPost);
                  });

                  // Save to local storage
                  try {
                    await DataPersistenceService.saveCommunityPosts(
                      _posts.map((post) => post.toMap()).toList(),
                    );
                  } catch (e) {
                    debugPrint('Error saving post: $e');
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }
}
