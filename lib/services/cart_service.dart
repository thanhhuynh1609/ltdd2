import 'package:shopping_app/pages/cart_page.dart';

class CartService {
  // Danh sách sản phẩm trong giỏ hàng
  static List<CartItem> cartItems = [];

  // Thêm sản phẩm vào giỏ hàng
  static void addToCart(CartItem item) {
    // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
    int existingIndex = cartItems.indexWhere((element) => 
      element.name == item.name && element.brand == item.brand);
    
    if (existingIndex != -1) {
      // Nếu sản phẩm đã tồn tại, tăng số lượng
      cartItems[existingIndex].quantity += 1;
    } else {
      // Nếu sản phẩm chưa tồn tại, thêm mới
      cartItems.add(item);
    }
  }

  // Xóa sản phẩm khỏi giỏ hàng
  static void removeFromCart(CartItem item) {
    cartItems.remove(item);
  }

  // Cập nhật số lượng sản phẩm
  static void updateQuantity(CartItem item, int quantity) {
    int index = cartItems.indexOf(item);
    if (index != -1) {
      if (quantity > 0) {
        cartItems[index].quantity = quantity;
      } else {
        cartItems.removeAt(index);
      }
    }
  }

  // Tính tổng tiền
  static double getTotalAmount() {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Xóa tất cả sản phẩm trong giỏ hàng
  static void clearCart() {
    cartItems.clear();
  }
}