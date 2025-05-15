import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shopping_app/services/database.dart';
import 'package:shopping_app/services/shared_pref.dart';

class FavoriteButton extends StatefulWidget {
  final String productId;
  final int initialVotes;
  final Function(bool) onFavoriteChanged;

  const FavoriteButton({
    Key? key,
    required this.productId,
    required this.initialVotes,
    required this.onFavoriteChanged,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFavorite = false;
  int votes = 0;
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    votes = widget.initialVotes;
    loadUserData();
  }

  Future<void> loadUserData() async {
    userId = await SharedPreferenceHelper().getUserId();
    if (userId != null) {
      checkIfFavorite();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkIfFavorite() async {
    if (userId == null) return;
    
    bool favorite = await DatabaseMethods().isProductFavorite(userId!, widget.productId);
    setState(() {
      isFavorite = favorite;
      isLoading = false;
    });
  }

  Future<void> toggleFavorite() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng đăng nhập để thêm vào yêu thích")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Cập nhật trạng thái yêu thích
      bool newFavoriteState = !isFavorite;
      
      // Cập nhật số lượt thích
      int newVotes = votes;
      if (newFavoriteState) {
        newVotes += 1;
      } else {
        newVotes = newVotes > 0 ? newVotes - 1 : 0;
      }

      // Cập nhật Firestore
      await DatabaseMethods().toggleFavoriteProduct(userId!, widget.productId, newFavoriteState);
      await DatabaseMethods().updateProductVotes(widget.productId, newVotes);

      setState(() {
        isFavorite = newFavoriteState;
        votes = newVotes;
        isLoading = false;
      });

      widget.onFavoriteChanged(newFavoriteState);
    } catch (e) {
      print("Error toggling favorite: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xfffd6f3e)),
            ),
          )
        : Row(
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: toggleFavorite,
              ),
              Text(
                votes.toString(),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
  }
}

