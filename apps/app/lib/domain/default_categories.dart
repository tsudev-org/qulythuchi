import 'package:qulythuchi_core/qulythuchi_core.dart';

enum DefaultCategoryLocale { vi, en }

final class DefaultCategory {
  const DefaultCategory(
    this.vi,
    this.en,
    this.icon, {
    this.kind = CategoryKind.expense,
    this.children = const [],
    this.taxType = IncomeTaxType.unknown,
  });
  final String vi;
  final String en;

  /// Tên icon Material (ánh xạ ở `ui/widgets/category_icon.dart`).
  final String icon;
  final CategoryKind kind;
  final List<DefaultCategory> children;

  /// Phân loại thuế TNCN (chỉ danh mục thu).
  final IncomeTaxType taxType;

  String name(DefaultCategoryLocale l) => l == DefaultCategoryLocale.vi ? vi : en;
}

/// Bộ danh mục mặc định cho người dùng Việt Nam: 8 nhóm chi + 7 nhóm thu chuẩn (có phân loại thuế TNCN).
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
  ...standardIncomeCategories,
];

/// Bộ danh mục THU chuẩn: phân loại theo thuế TNCN Việt Nam để ước tính quyết toán (lương, vãng lai/freelance, kinh
/// doanh, đầu tư, miễn thuế). Người dùng cũ bổ sung bằng "Bổ sung danh mục thu chuẩn".
const standardIncomeCategories = <DefaultCategory>[
  DefaultCategory(
    'Lương',
    'Salary',
    'payments',
    kind: CategoryKind.income,
    taxType: IncomeTaxType.salary,
    children: [
      DefaultCategory('Phụ cấp', 'Allowance', 'payments', kind: CategoryKind.income, taxType: IncomeTaxType.salary),
    ],
  ),
  DefaultCategory('Thưởng', 'Bonus', 'emoji_events', kind: CategoryKind.income, taxType: IncomeTaxType.salary),
  DefaultCategory(
    'Freelance, dịch vụ',
    'Freelance & services',
    'work',
    kind: CategoryKind.income,
    taxType: IncomeTaxType.casual,
  ),
  DefaultCategory(
    'Kinh doanh, bán hàng',
    'Business & sales',
    'storefront',
    kind: CategoryKind.income,
    taxType: IncomeTaxType.business,
    children: [
      DefaultCategory('Cho thuê', 'Rental', 'house', kind: CategoryKind.income, taxType: IncomeTaxType.business),
    ],
  ),
  DefaultCategory(
    'Đầu tư',
    'Investment',
    'trending_up',
    kind: CategoryKind.income,
    taxType: IncomeTaxType.investment,
    children: [
      DefaultCategory('Lãi tiết kiệm', 'Interest', 'percent', kind: CategoryKind.income, taxType: IncomeTaxType.exempt),
      DefaultCategory('Cổ tức', 'Dividends', 'pie_chart', kind: CategoryKind.income, taxType: IncomeTaxType.investment),
    ],
  ),
  DefaultCategory(
    'Thu nhập khác',
    'Other income',
    'savings',
    kind: CategoryKind.income,
    children: [
      DefaultCategory('Bán đồ', 'Sales', 'sell', kind: CategoryKind.income),
      DefaultCategory(
        'Được tặng',
        'Gifts received',
        'redeem',
        kind: CategoryKind.income,
        taxType: IncomeTaxType.exempt,
      ),
      DefaultCategory('Hoàn tiền', 'Refunds', 'undo', kind: CategoryKind.income, taxType: IncomeTaxType.exempt),
    ],
  ),
];
