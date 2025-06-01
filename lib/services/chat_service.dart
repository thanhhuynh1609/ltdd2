import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopping_app/models/chat_message.dart';
import 'package:shopping_app/services/notification_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy danh sách tin nhắn của một cuộc trò chuyện
  static Stream<List<ChatMessage>> getChatMessages(String userId) {
    return _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Gửi tin nhắn mới
  static Future<void> sendMessage({
    required String userId,
    required String senderName,
    required String senderImage,
    required String message,
    required bool isAdmin,
  }) async {
    // Tạo tin nhắn mới
    ChatMessage chatMessage = ChatMessage(
      id: '',
      senderId: userId,
      senderName: senderName,
      senderImage: senderImage,
      message: message,
      isAdmin: isAdmin,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Lưu tin nhắn vào Firestore
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .add(chatMessage.toMap());

    // Cập nhật thông tin cuộc trò chuyện
    Map<String, dynamic> updateData = {
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(isAdmin ? 1 : 0),
      'unreadAdminCount': FieldValue.increment(isAdmin ? 0 : 1),
    };
    
    // Chỉ cập nhật userName và userImage khi người dùng gửi tin nhắn, không phải admin
    if (!isAdmin) {
      updateData['userId'] = userId;
      updateData['userName'] = senderName;
      updateData['userImage'] = senderImage;
    }
    
    await _firestore.collection('chats').doc(userId).set(
      updateData, 
      SetOptions(merge: true)
    );

    // Gửi thông báo nếu tin nhắn từ admin
    if (isAdmin) {
      await NotificationService.createNotification(
        userId: userId,
        title: "Tin nhắn mới từ Admin",
        message: message.length > 50 ? message.substring(0, 50) + "..." : message,
        type: "chat",
      );
    }
  }

  // Đánh dấu tất cả tin nhắn là đã đọc
  static Future<void> markAllAsRead(String userId, bool isAdmin) async {
    // Kiểm tra xem có tin nhắn chưa đọc không trước khi thực hiện cập nhật
    QuerySnapshot unreadMessages = await _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('isAdmin', isEqualTo: !isAdmin) // Người dùng đọc tin nhắn của admin và ngược lại
        .limit(1) // Chỉ cần kiểm tra xem có tin nhắn chưa đọc không
        .get();
    
    // Nếu không có tin nhắn chưa đọc, không cần thực hiện cập nhật
    if (unreadMessages.docs.isEmpty) {
      return;
    }
    
    // Lấy tất cả tin nhắn chưa đọc
    unreadMessages = await _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('isAdmin', isEqualTo: !isAdmin)
        .get();

    // Cập nhật từng tin nhắn
    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    // Kiểm tra xem có cần cập nhật số lượng tin nhắn chưa đọc không
    DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(userId).get();
    if (chatDoc.exists) {
      Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;
      int unreadCount = isAdmin ? (data['unreadAdminCount'] ?? 0) : (data['unreadCount'] ?? 0);
      
      if (unreadCount > 0) {
        // Cập nhật số lượng tin nhắn chưa đọc
        await _firestore.collection('chats').doc(userId).update({
          isAdmin ? 'unreadAdminCount' : 'unreadCount': 0,
        });
      }
    }
  }

  // Lấy danh sách tất cả các cuộc trò chuyện (cho admin)
  static Stream<QuerySnapshot> getAllChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Lấy số lượng tin nhắn chưa đọc
  static Stream<int> getUnreadCount(String userId, bool isAdmin) {
    return _firestore
        .collection('chats')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        return isAdmin ? (data['unreadAdminCount'] ?? 0) : (data['unreadCount'] ?? 0);
      }
      return 0;
    });
  }
}

