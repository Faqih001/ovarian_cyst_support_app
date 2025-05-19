import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
  late Stream<QuerySnapshot> _postsStream;
  bool _isLoading = true;
  final TextEditingController _newPostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    _postsStream = firestoreService.getCommunityPosts();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _newPostController.dispose();
    super.dispose();
  }

  Future<void> _createPost(String content) async {
    if (content.trim().isEmpty) return;

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to post')),
      );
      return;
    }

    try {
      await firestoreService.createCommunityPost({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'userPhotoUrl': user.photoURL,
        'content': content.trim(),
        'likes': 0,
        'likedBy': [],
        'comments': [],
      });

      _newPostController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
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
                Column(
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
              ],
            ),
            const SizedBox(height: 8),
            Text(post.content),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.likedBy.contains(
                          Provider.of<AuthService>(context).user?.uid,
                        )
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.likedBy.contains(
                          Provider.of<AuthService>(context).user?.uid,
                        )
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
              controller: _newPostController,
              decoration: const InputDecoration(
                hintText: 'Share your thoughts...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _createPost(_newPostController.text),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLike(CommunityPost post) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to like posts')),
      );
      return;
    }

    try {
      final isLiked = post.likedBy.contains(user.uid);
      final newLikedBy = List<String>.from(post.likedBy);
      if (isLiked) {
        newLikedBy.remove(user.uid);
      } else {
        newLikedBy.add(user.uid);
      }

      await firestoreService.batchUpdate([
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
      );
      }
    }
  }
}
