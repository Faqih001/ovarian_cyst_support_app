import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationCategory {
  appointment, // Appointment related notifications
  medication, // Medication reminders
  healthTip, // Health tips and educational content
  community, // Community post updates, replies
  system, // System updates and alerts
  test, // Test results
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationCategory category;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.category,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
  });

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationCategory? category,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory NotificationItem.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return NotificationItem(
      id: documentId,
      userId: map['userId'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      category: NotificationCategory.values.firstWhere(
        (e) => e.toString() == 'NotificationCategory.${map['category']}',
        orElse: () => NotificationCategory.system,
      ),
      data: map['data'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] as bool? ?? false,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'category': category.toString().split('.').last,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? '1 day ago'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Get category icon
  IconData getCategoryIcon() {
    switch (category) {
      case NotificationCategory.appointment:
        return Icons.calendar_today;
      case NotificationCategory.medication:
        return Icons.medication;
      case NotificationCategory.healthTip:
        return Icons.health_and_safety;
      case NotificationCategory.community:
        return Icons.people;
      case NotificationCategory.test:
        return Icons.science;
      case NotificationCategory.system:
        return Icons.notifications;
    }
  }

  // Get category color
  Color getCategoryColor() {
    switch (category) {
      case NotificationCategory.appointment:
        return Colors.blue;
      case NotificationCategory.medication:
        return Colors.orange;
      case NotificationCategory.healthTip:
        return Colors.green;
      case NotificationCategory.community:
        return Colors.purple;
      case NotificationCategory.test:
        return Colors.teal;
      case NotificationCategory.system:
        return Colors.grey;
    }
  }
}
