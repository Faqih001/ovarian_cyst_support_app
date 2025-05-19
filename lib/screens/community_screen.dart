import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/models/community_post.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late Stream<QuerySnapshot> _postsStream;
  final TextEditingController _postController = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    _postsStream = firestoreService.getCommunityPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_postController.text.trim().isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to post')),
      );
      return;
    }

    try {
      await firestoreService.createCommunityPost({
        'content': _postController.text.trim(),
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'userPhotoUrl': currentUser.photoURL,
        'likes': 0,
        'comments': [],
      });

      _postController.clear();
      setState(() => _isComposing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Community',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No posts yet. Be the first to share!'),
                  );
                }

                final posts = snapshot.data!.docs
                    .map((doc) => CommunityPost.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post);
                  },
                );
              },
            ),
          ),
          _buildComposer(),
        ],
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
                  backgroundImage: post.userAvatar.startsWith('http')
                      ? NetworkImage(post.userAvatar) as ImageProvider
                      : null,
                  child: post.userAvatar.startsWith('http')
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
                children: post.tags.map((tag) {
                  return Chip(
                    label: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                      ),
                    ),
                    backgroundColor: AppColors.accent.withAlpha(
                      (0.1 * 255).round(),
                    ),
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
                        color: post.isLikedByCurrentUser
                            ? AppColors.primary
                            : AppColors.primary.withAlpha(
                                (0.7 * 255).round(),
                              ),
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

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
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
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: _isComposing ? _submitPost : null,
          ),
        ],
      ),
    );
  }
}
