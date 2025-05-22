import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shopping_app/models/chat_message.dart';
import 'package:shopping_app/services/chat_service.dart';
import 'package:shopping_app/services/shared_pref.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String userId = "";
  String userName = "";
  String userImage = "";
  bool isLoading = true;
  bool _hasMarkedAsRead = false; // Thêm biến để theo dõi trạng thái đánh dấu đã đọc

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    userId = await SharedPreferenceHelper().getUserId() ?? "";
    userName = await SharedPreferenceHelper().getUserName() ?? "Người dùng";
    userImage = await SharedPreferenceHelper().getUserProfile() ?? "";

    if (userId.isNotEmpty) {
      setState(() {
        isLoading = false;
      });
      
      // Đánh dấu tin nhắn đã đọc sau khi UI đã được render
      if (!_hasMarkedAsRead) {
        _hasMarkedAsRead = true;
        Future.delayed(Duration(milliseconds: 500), () {
          ChatService.markAllAsRead(userId, false);
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await ChatService.sendMessage(
      userId: userId,
      senderName: userName,
      senderImage: userImage,
      message: _messageController.text.trim(),
      isAdmin: false,
    );

    _messageController.clear();
    
    // Cuộn xuống tin nhắn mới nhất
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chat với Admin",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF4A5CFF),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Danh sách tin nhắn
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.getChatMessages(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                                "Bắt đầu cuộc trò chuyện với Admin",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      List<ChatMessage> messages = snapshot.data!;
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          ChatMessage message = messages[index];
                          bool isMe = !message.isAdmin;
                          
                          return _buildMessageItem(message, isMe);
                        },
                      );
                    },
                  ),
                ),
                
                // Input tin nhắn
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, -1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: "Nhập tin nhắn...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 5,
                        ),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF4A5CFF),
                        child: IconButton(
                          icon: Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, bool isMe) {
    final time = DateFormat('HH:mm').format(message.timestamp);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('images/user.png'),
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFF4A5CFF) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: userImage.isNotEmpty
                  ? NetworkImage(userImage) as ImageProvider
                  : AssetImage('images/user.png'),
              backgroundColor: Colors.grey[300],
            ),
          ],
        ],
      ),
    );
  }
}

