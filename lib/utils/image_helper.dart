import 'dart:convert';
import 'package:flutter/material.dart';

class ImageHelper {
  static Widget buildImage(dynamic imageData, {double width = 60, double height = 60}) {
    if (imageData == null || (imageData is String && imageData.isEmpty)) {
      return _buildPlaceholder(width, height);
    }
    
    // Nếu là URL
    if (imageData is String && 
        (imageData.startsWith('http://') || imageData.startsWith('https://'))) {
      return _buildNetworkImage(imageData, width, height);
    }
    
    // Nếu là đường dẫn asset
    if (imageData is String && imageData.startsWith('images/')) {
      return _buildAssetImage(imageData, width, height);
    }
    
    // Thử decode base64
    if (imageData is String) {
      try {
        return _buildBase64Image(imageData, width, height);
      } catch (e) {
        print("Lỗi khi hiển thị ảnh base64: $e");
        return _buildPlaceholder(width, height);
      }
    }
    
    // Trường hợp khác
    return _buildPlaceholder(width, height);
  }
  
  static Widget _buildNetworkImage(String url, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("Lỗi tải ảnh từ URL: $error");
          return _buildPlaceholder(width, height);
        },
      ),
    );
  }
  
  static Widget _buildAssetImage(String path, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          print("Lỗi tải ảnh từ asset: $error");
          return _buildPlaceholder(width, height);
        },
      ),
    );
  }
  
  static Widget _buildBase64Image(String base64String, double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          print("Lỗi decode base64: $error");
          return _buildPlaceholder(width, height);
        },
      ),
    );
  }
  
  static Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
    );
  }
}