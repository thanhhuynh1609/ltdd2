import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shopping_app/Admin/admin_chat_page.dart';
import 'package:shopping_app/services/chat_service.dart';

class AdminChatList extends StatefulWidget {
  const AdminChatList({Key? key}) : super(key: key);

  @override
  State<AdminChatList> createState() => _AdminChatListState();
}

class _AdminChatListState extends State<AdminChatList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý tin nhắn"),
        backgroundColor: Color(0xFF4A5CFF),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService.getAllChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Chưa có cuộc trò chuyện nào",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              
              String userId = doc.id;
              String userName = data['userName'] ?? 'Người dùng';
              String userImage = data['userImage'] ?? '';
              String lastMessage = data['lastMessage'] ?? '';
              int unreadCount = data['unreadAdminCount'] ?? 0;
              
              // Format thời gian
              String formattedTime = '';
              if (data['lastMessageTime'] != null) {
                DateTime lastMessageTime = (data['lastMessageTime'] as Timestamp).toDate();
                formattedTime = DateFormat('HH:mm, dd/MM').format(lastMessageTime);
              }
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userImage.isNotEmpty
                        ? NetworkImage(userImage) as ImageProvider
                        : AssetImage('images/boy.jpg'),
                    radius: 24,
                  ),
                  title: Text(
                    userName,
                    style: TextStyle(
                      fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        lastMessage.length > 30
                            ? lastMessage.substring(0, 30) + '...'
                            : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: unreadCount > 0
                      ? Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminChatPage(
                          userId: userId,
                          userName: userName,
                          userImage: userImage,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}