import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/notification_item.dart';

class FirebaseNotificationService extends ChangeNotifier {
  // Singleton pattern
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Store unread count locally to avoid excessive Firestore reads
  int _unreadCount = 0;
  bool _initialized = false;
  String? _userId;

  // Constructor
  FirebaseNotificationService._internal();

  // Initialize the service
  Future<void> initialize(String userId) async {
    if (_initialized && _userId == userId) return;

    _userId = userId;

    // Request permission for notifications
    await _requestNotificationPermissions();

    // Subscribe to topics
    await _subscribeToTopics();

    // Set up message handling
    _setupMessageHandlers();

    // Get initial unread count
    await _updateUnreadCount();

    _initialized = true;
    _logger.i('Firebase Notification Service initialized for user $userId');
  }

  // Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _logger.i(
      'Firebase Messaging authorization status: ${settings.authorizationStatus}',
    );
  }

  // Subscribe to relevant topics
  Future<void> _subscribeToTopics() async {
    // Subscribe to general topics
    await _messaging.subscribeToTopic('general');
    await _messaging.subscribeToTopic('health_tips');

    // User-specific topic (using userId hash to keep it private)
    if (_userId != null) {
      final userTopic = 'user_${_userId!.hashCode}';
      await _messaging.subscribeToTopic(userTopic);
      _logger.d('Subscribed to user topic: $userTopic');
    }
  }

  // Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handle background messages in main.dart with:
    // @pragma('vm:entry-point')
    // Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    //   // Handle background message
    // }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _logger.d('Got a message in the foreground!');

      // Create a notification item from the message
      await _processRemoteMessage(message);

      // Update the unread count
      _unreadCount++;
      notifyListeners();

      // You can also show an in-app notification here
    });

    // Handle when notification is clicked and app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.d('Message clicked when app was in background');
      // Handle navigation here based on message data
    });
  }

  // Process remote message and save to Firestore
  Future<NotificationItem> _processRemoteMessage(RemoteMessage message) async {
    if (_userId == null) {
      throw Exception('User ID not set');
    }

    // Create notification data
    final notificationData = {
      'userId': _userId,
      'title': message.notification?.title ?? 'New Notification',
      'body': message.notification?.body ?? '',
      'category': _getCategoryFromMessage(message),
      'data': message.data,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'imageUrl':
          message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
    };

    // Save to Firestore
    final docRef = await _firestore
        .collection('notifications')
        .add(notificationData);

    // Get the created document with server timestamp
    final docSnapshot = await docRef.get();
    final data = docSnapshot.data() as Map<String, dynamic>;

    // Update local count
    _unreadCount++;
    notifyListeners();

    return NotificationItem.fromMap(data, docRef.id);
  }

  // Determine notification category based on message data
  String _getCategoryFromMessage(RemoteMessage message) {
    final category = message.data['category'] ?? 'system';

    // Validate that the category is a valid NotificationCategory
    try {
      NotificationCategory.values.firstWhere(
        (e) => e.toString() == 'NotificationCategory.$category',
      );
      return category;
    } catch (_) {
      return 'system';
    }
  }

  // Get unread notifications count
  int getUnreadCount() => _unreadCount;

  // Update unread count from Firestore
  Future<void> _updateUnreadCount() async {
    if (_userId == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      _unreadCount = querySnapshot.count ?? 0;
      notifyListeners();
    } catch (e) {
      _logger.e('Error fetching unread count: $e');
    }
  }

  // Get all notifications for current user with pagination
  Future<List<NotificationItem>> getNotifications({
    NotificationCategory? category,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    if (_userId == null) return [];

    try {
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true);

      // Filter by category if provided
      if (category != null) {
        query = query.where(
          'category',
          isEqualTo: category.toString().split('.').last,
        );
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Apply limit
      query = query.limit(limit);

      // Execute query
      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map(
            (doc) => NotificationItem.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      _logger.e('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      _updateUnreadCount();
    } catch (e) {
      _logger.e('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      // Get all unread notifications
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Create a batch to update all notifications
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Commit the batch
      await batch.commit();

      // Update local count
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _logger.e('Error marking all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      _updateUnreadCount();
    } catch (e) {
      _logger.e('Error deleting notification: $e');
    }
  }

  // Create a local notification (for testing)
  Future<void> createLocalNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    Map<String, dynamic>? data,
  }) async {
    if (_userId == null) return;

    final notificationData = {
      'userId': _userId,
      'title': title,
      'body': body,
      'category': category.toString().split('.').last,
      'data': data ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    try {
      await _firestore.collection('notifications').add(notificationData);
      await _updateUnreadCount();
    } catch (e) {
      _logger.e('Error creating local notification: $e');
    }
  }

  // Dispose
  @override
  void dispose() {
    _initialized = false;
    super.dispose();
  }
}
