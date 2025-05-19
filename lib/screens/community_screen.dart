import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/models/community_post.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';
import 'package:ovarian_cyst_support_app/services/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final FirestoreService _firestoreService;
  late final AuthService _authService;
  late Stream<QuerySnapshot> _postsStream;
  final TextEditingController _postController = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _postsStream = _firestoreService.getCommunityPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_postController.text.trim().isEmpty) return;

    final currentUser = _authService.user;
    if (!mounted) return;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to post')),
      );
      return;
    }

    try {
      await _firestoreService.createCommunityPost({
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'userPhotoUrl': currentUser.photoURL,
        'content': _postController.text.trim(),
        'likes': 0,
        'likedBy': [],
        'comments': [],
        'tags': [], // Adding empty tags list
      });

      if (!mounted) return;
      _postController.clear();
      setState(() => _isComposing = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting: $e')),
      );
    }
  }

  Future<void> _handleLike(CommunityPost post) async {
    final currentUser = _authService.user;
    if (!mounted) return;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts')),
      );
      return;
    }

    try {
      final isLiked = post.likedBy.contains(currentUser.uid);
      final newLikedBy = List<String>.from(post.likedBy);
      if (isLiked) {
        newLikedBy.remove(currentUser.uid);
      } else {
        newLikedBy.add(currentUser.uid);
      }

      await _firestoreService.batchUpdate([
        {
          'ref': FirebaseFirestore.instance
              .collection('communityPosts')
              .doc(post.id),
          'data': {
            'likes': isLiked ? post.likes - 1 : post.likes + 1,
            'likedBy': newLikedBy,
          },
        },
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
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

                final posts = snapshot.data?.docs
                        .map((doc) => CommunityPost.fromFirestore(doc))
                        .toList() ??
                    [];

                if (posts.isEmpty) {
                  return const Center(
                    child: Text('No posts yet. Be the first to share!'),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildPostCard(post);
                  },
                );
              },
            ),
          ),
          _buildNewPostComposer(),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final currentUser = _authService.user;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.userPhotoUrl != null
                      ? NetworkImage(post.userPhotoUrl!)
                      : null,
                  child: post.userPhotoUrl == null
                      ? Text(post.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.content),
            const SizedBox(height: 8),
            if (post.tags.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                children: post.tags
                    .map((tag) => Chip(
                          label: Text('#$tag'),
                          backgroundColor: AppColors.primary.withAlpha(26),
                          labelStyle: TextStyle(color: AppColors.primary),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.likedBy.contains(currentUser?.uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.likedBy.contains(currentUser?.uid)
                            ? Colors.red
                            : null,
                      ),
                      onPressed: () => _handleLike(post),
                    ),
                    Text('${post.likes}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment_outlined),
                    const SizedBox(width: 4),
                    Text('${post.comments.length}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPostComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts...',
                border: InputBorder.none,
              ),
              maxLines: null,
              onChanged: (text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isComposing ? () => _submitPost() : null,
            color: _isComposing ? AppColors.primary : Colors.grey,
          ),
        ],
      ),
    );
  }
}
