import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ovarian_cyst_support_app/constants.dart';
import 'package:ovarian_cyst_support_app/models/notification_item.dart';
import 'package:ovarian_cyst_support_app/services/firebase_notification_service.dart';
import 'package:ovarian_cyst_support_app/services/auth_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationCategory? _selectedCategory;
  DocumentSnapshot? _lastDocument;
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 20;

  final List<Tab> _tabs = const [
    Tab(text: 'All'),
    Tab(text: 'Unread'),
    Tab(text: 'Appointments'),
    Tab(text: 'Medications'),
    Tab(text: 'Health Tips'),
    Tab(text: 'Community'),
    Tab(text: 'System'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedCategory = null; // All notifications
            break;
          case 1:
            _selectedCategory = null; // Unread (handled specially)
            break;
          case 2:
            _selectedCategory = NotificationCategory.appointment;
            break;
          case 3:
            _selectedCategory = NotificationCategory.medication;
            break;
          case 4:
            _selectedCategory = NotificationCategory.healthTip;
            break;
          case 5:
            _selectedCategory = NotificationCategory.community;
            break;
          case 6:
            _selectedCategory = NotificationCategory.system;
            break;
        }
        _notifications = [];
        _lastDocument = null;
        _hasMore = true;
        _loadNotifications();
      });
    }
  }

  Future<void> _loadNotifications() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notificationService = Provider.of<FirebaseNotificationService>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(context, listen: false);

      // Initialize notification service with user ID if needed
      if (authService.user?.uid != null) {
        await notificationService.initialize(authService.user!.uid);
      }

      List<NotificationItem> newNotifications;
      if (_tabController.index == 1) {
        // Unread only - special case
        newNotifications = await _loadUnreadNotifications(notificationService);
      } else {
        // Regular category filtering
        newNotifications = await notificationService.getNotifications(
          category: _selectedCategory,
          limit: _pageSize,
          lastDocument: _lastDocument,
        );
      }

      if (mounted) {
        if (newNotifications.isEmpty) {
          setState(() {
            _hasMore = false;
          });
        } else {
          setState(() {
            _notifications.addAll(newNotifications);
            // Update last document for pagination
            if (newNotifications.length >= _pageSize) {
              // This would be handled better in a real implementation
              // _lastDocument = ...
            } else {
              _hasMore = false;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<NotificationItem>> _loadUnreadNotifications(
    FirebaseNotificationService service,
  ) async {
    // Get unread notifications
    final allNotifications = await service.getNotifications(
      limit: _pageSize,
      lastDocument: _lastDocument,
    );
    return allNotifications
        .where((notification) => !notification.isRead)
        .toList();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _notifications = [];
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadNotifications();
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;

    switch (_selectedCategory) {
      case NotificationCategory.appointment:
        icon = Icons.calendar_month;
        message = 'No appointment notifications';
        break;
      case NotificationCategory.medication:
        icon = Icons.medication;
        message = 'No medication reminders';
        break;
      case NotificationCategory.healthTip:
        icon = Icons.lightbulb;
        message = 'No health tips yet';
        break;
      case NotificationCategory.community:
        icon = Icons.forum;
        message = 'No community updates';
        break;
      default:
        icon = Icons.notifications_off;
        message = _tabController.index == 1
            ? 'No unread notifications'
            : 'No notifications yet';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New notifications will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final theme = Theme.of(context);
    final notificationService = Provider.of<FirebaseNotificationService>(
      context,
      listen: false,
    );

    // Format the date
    final formattedDate = DateFormat.yMMMd().add_jm().format(
      notification.createdAt,
    );

    // Get icon based on category
    IconData categoryIcon;
    Color categoryColor;

    switch (notification.category) {
      case NotificationCategory.appointment:
        categoryIcon = Icons.calendar_month;
        categoryColor = AppColors.primary;
        break;
      case NotificationCategory.medication:
        categoryIcon = Icons.medication;
        categoryColor = AppColors.accent;
        break;
      case NotificationCategory.healthTip:
        categoryIcon = Icons.lightbulb;
        categoryColor = Colors.amber;
        break;
      case NotificationCategory.community:
        categoryIcon = Icons.forum;
        categoryColor = Colors.green;
        break;
      case NotificationCategory.system:
        categoryIcon = Icons.system_update;
        categoryColor = Colors.grey;
        break;
      case NotificationCategory.test:
        categoryIcon = Icons.science;
        categoryColor = Colors.purple;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        notificationService.deleteNotification(notification.id);
        setState(() {
          _notifications.remove(notification);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                // This would need persistence logic to recreate the deleted notification
                _handleRefresh();
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () async {
          // Mark as read when tapped
          if (!notification.isRead) {
            await notificationService.markAsRead(notification.id);

            // Update the UI without full refresh
            setState(() {
              final index = _notifications.indexOf(notification);
              if (index != -1) {
                _notifications[index] = notification.copyWith(isRead: true);
              }
            });
          }

          // Handle navigation based on notification type
          _handleNotificationTap(notification);
        },
        child: Container(
          color: notification.isRead
              ? null
              : theme.colorScheme.primaryContainer.withAlpha(
                  (0.1 * 255).round(),
                ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: categoryColor.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 24),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(
                            (0.8 * 255).round(),
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color?.withAlpha(
                            (0.6 * 255).round(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Handle different navigation based on notification category and data
    if (notification.data != null) {
      switch (notification.category) {
        case NotificationCategory.appointment:
          final appointmentId = notification.data!['appointmentId'] as String?;
          if (appointmentId != null) {
            // Navigate to appointment details
            // Navigator.push(context, MaterialPageRoute(...));
          }
          break;

        case NotificationCategory.medication:
          final medicationId = notification.data!['medicationId'] as String?;
          if (medicationId != null) {
            // Navigate to medication details
            // Navigator.push(context, MaterialPageRoute(...));
          }
          break;

        case NotificationCategory.community:
          final postId = notification.data!['postId'] as String?;
          if (postId != null) {
            // Navigate to community post
            // Navigator.push(context, MaterialPageRoute(...));
          }
          break;

        default:
          // For other types, just display a modal with details
          _showNotificationDetailsDialog(notification);
      }
    } else {
      _showNotificationDetailsDialog(notification);
    }
  }

  void _showNotificationDetailsDialog(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(notification.body),
              const SizedBox(height: 16),
              Text(
                'Received: ${DateFormat.yMMMd().add_jm().format(notification.createdAt)}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha((0.7 * 255).round()),
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Mark all as read?'),
                  content: const Text(
                    'This will mark all your notifications as read.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final service =
                            Provider.of<FirebaseNotificationService>(
                              context,
                              listen: false,
                            );
                        service.markAllAsRead();
                        _handleRefresh();
                      },
                      child: const Text('Mark All Read'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoading &&
              _hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent * 0.9) {
            _loadNotifications();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: _notifications.isEmpty
              ? _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildEmptyState()
              : ListView.separated(
                  itemCount: _notifications.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == _notifications.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _buildNotificationItem(_notifications[index]);
                  },
                ),
        ),
      ),
    );
  }
}
