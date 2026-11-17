import 'package:qulythuchi_core/qulythuchi_core.dart';

enum DefaultCategoryLocale { vi, en }

final class DefaultCategory {
  const DefaultCategory(this.vi, this.en, this.icon, {this.kind = CategoryKind.expense, this.children = const []});
  final String vi;
  final String en;

  /// Tên icon Material (ánh xạ ở `ui/widgets/category_icon.dart`).
  final String icon;
  final CategoryKind kind;
  final List<DefaultCategory> children;

  String name(DefaultCategoryLocale l) => l == DefaultCategoryLocale.vi ? vi : en;
}

/// Bộ danh mục mặc định cho người dùng Việt Nam: 8 nhóm chi + 3 nhóm thu, tổng 28 mục.
const defaultCategories = <DefaultCategory>[
  DefaultCategory(
    'Ăn uống',
    'Food & drinks',
    'restaurant',
    children: [
      DefaultCategory('Đi chợ, siêu thị', 'Groceries', 'shopping_basket'),
      DefaultCategory('Ăn ngoài', 'Eating out', 'ramen_dining'),
      DefaultCategory('Cà phê, đồ uống', 'Coffee & drinks', 'local_cafe'),
    ],
  ),
  DefaultCategory(
    'Nhà cửa',
    'Housing',
    'home',
    children: [
      DefaultCategory('Tiền nhà', 'Rent', 'house'),
      DefaultCategory('Điện', 'Electricity', 'bolt'),
      DefaultCategory('Nước', 'Water', 'water_drop'),
      DefaultCategory('Internet, điện thoại', 'Internet & phone', 'wifi'),
    ],
  ),
  DefaultCategory(
    'Đi lại',
    'Transport',
    'directions_car',
    children: [
      DefaultCategory('Xăng xe', 'Fuel', 'local_gas_station'),
      DefaultCategory('Gửi xe, cầu đường', 'Parking & tolls', 'local_parking'),
      DefaultCategory('Taxi, xe công nghệ', 'Taxi & ride-hailing', 'local_taxi'),
    ],
  ),
  DefaultCategory(
    'Mua sắm',
    'Shopping',
    'shopping_bag',
    children: [
      DefaultCategory('Quần áo', 'Clothing', 'checkroom'),
      DefaultCategory('Đồ gia dụng', 'Household', 'chair'),
    ],
  ),
  DefaultCategory(
    'Sức khỏe',
    'Health',
    'favorite',
    children: [
      DefaultCategory('Thuốc, khám bệnh', 'Medical', 'medical_services'),
      DefaultCategory('Bảo hiểm', 'Insurance', 'health_and_safety'),
    ],
  ),
  DefaultCategory('Giáo dục', 'Education', 'school'),
  DefaultCategory('Giải trí', 'Entertainment', 'movie', children: [DefaultCategory('Du lịch', 'Travel', 'flight')]),
  DefaultCategory('Hiếu hỷ, quà tặng', 'Gifts & donations', 'card_giftcard'),
  DefaultCategory('Lương', 'Salary', 'payments', kind: CategoryKind.income),
  DefaultCategory('Thưởng', 'Bonus', 'emoji_events', kind: CategoryKind.income),
  DefaultCategory(
    'Thu nhập khác',
    'Other income',
    'savings',
    kind: CategoryKind.income,
    children: [
      DefaultCategory('Lãi tiết kiệm', 'Interest', 'percent', kind: CategoryKind.income),
      DefaultCategory('Bán đồ', 'Sales', 'sell', kind: CategoryKind.income),
    ],
  ),
];
