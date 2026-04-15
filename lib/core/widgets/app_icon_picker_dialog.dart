import 'dart:math' as math;

import 'package:flutter/material.dart';

class IconPickerResult {
  const IconPickerResult({
    required this.iconName,
    required this.colorHex,
  });

  final String iconName;
  final String colorHex;
}

class AppIconItem {
  const AppIconItem({
    required this.name,
    required this.label,
    required this.categoryId,
    required this.icon,
  });

  final String name;
  final String label;
  final String categoryId;
  final IconData icon;
}

class AppIconPickerDialog extends StatefulWidget {
  const AppIconPickerDialog({
    super.key,
    required this.initialIconName,
    required this.initialColorHex,
    this.title = 'تخصيص الأيقونة',
  });

  final String initialIconName;
  final String initialColorHex;
  final String title;

  static const categoryLabels = <String, String>{
    'all': 'عام',
    'food': 'أكل',
    'transport': 'مواصلات',
    'health': 'علاج',
    'money': 'فلوس',
    'home': 'بيت',
    'fun': 'ترفيه',
    'work': 'شغل',
    'shopping': 'تسوق',
    'tech': 'تقنية',
    'other': 'أخرى',
  };

  static const categoryOrder = <String>[
    'all',
    'food',
    'transport',
    'health',
    'money',
    'home',
    'fun',
    'work',
    'shopping',
    'tech',
    'other',
  ];

  static final _baseIcons = <AppIconItem>[
    // food
    ..._iconsFor('food', [
      ('restaurant', 'وجبات', Icons.restaurant),
      ('local_pizza', 'بيتزا', Icons.local_pizza),
      ('coffee', 'قهوة', Icons.coffee),
      ('bakery', 'مخبوزات', Icons.bakery_dining),
      ('local_cafe', 'كافيه', Icons.local_cafe),
      ('icecream', 'حلويات', Icons.icecream),
      ('ramen', 'نودلز', Icons.ramen_dining),
      ('fastfood', 'وجبة سريعة', Icons.fastfood),
      ('breakfast', 'فطار', Icons.free_breakfast),
      ('egg', 'بيض', Icons.egg),
      ('cake', 'كيك', Icons.cake),
      ('lunch', 'غداء', Icons.lunch_dining),
    ]),
    // transport
    ..._iconsFor('transport', [
      ('car', 'سيارة', Icons.directions_car),
      ('bus', 'أوتوبيس', Icons.directions_bus),
      ('subway', 'مترو', Icons.directions_subway),
      ('train', 'قطار', Icons.train),
      ('flight', 'طيران', Icons.flight),
      ('bike', 'دراجة', Icons.directions_bike),
      ('taxi', 'تاكسي', Icons.local_taxi),
      ('walk', 'مشي', Icons.directions_walk),
      ('fuel', 'بنزين', Icons.local_gas_station),
      ('map', 'خرائط', Icons.map),
      ('traffic', 'مرور', Icons.traffic),
      ('ev', 'شحن', Icons.ev_station),
    ]),
    // health
    ..._iconsFor('health', [
      ('favorite', 'صحة', Icons.favorite),
      ('medication', 'دواء', Icons.medication),
      ('hospital', 'مستشفى', Icons.local_hospital),
      ('vaccines', 'تطعيم', Icons.vaccines),
      ('fitness', 'رياضة', Icons.fitness_center),
      ('spa', 'سبا', Icons.spa),
      ('healing', 'عناية', Icons.healing),
      ('monitor_heart', 'نبض', Icons.monitor_heart),
      ('emergency', 'طوارئ', Icons.emergency),
      ('psychology', 'دعم نفسي', Icons.psychology),
      ('bloodtype', 'تحاليل', Icons.bloodtype),
      ('health', 'رعاية', Icons.health_and_safety),
    ]),
    // money
    ..._iconsFor('money', [
      ('wallet', 'محفظة', Icons.account_balance_wallet),
      ('card', 'بطاقة', Icons.credit_card),
      ('bank', 'بنك', Icons.account_balance),
      ('cash', 'نقدي', Icons.payments),
      ('receipt', 'فاتورة', Icons.receipt_long),
      ('savings', 'ادخار', Icons.savings),
      ('attach_money', 'دولار', Icons.attach_money),
      ('currency_exchange', 'تحويل', Icons.currency_exchange),
      ('price_check', 'سعر', Icons.price_check),
      ('paid', 'مدفوع', Icons.paid),
      ('account_balance_wallet', 'حساب', Icons.wallet),
      ('trending', 'استثمار', Icons.trending_up),
    ]),
    // home
    ..._iconsFor('home', [
      ('home', 'منزل', Icons.home),
      ('bed', 'غرفة', Icons.bed),
      ('weekend', 'أثاث', Icons.weekend),
      ('kitchen', 'مطبخ', Icons.kitchen),
      ('shower', 'حمام', Icons.shower),
      ('light', 'إضاءة', Icons.lightbulb),
      ('cleaning', 'تنظيف', Icons.cleaning_services),
      ('chair', 'كرسي', Icons.chair),
      ('apartment', 'عمارة', Icons.apartment),
      ('key', 'مفتاح', Icons.key),
      ('roof', 'صيانة', Icons.home_repair_service),
      ('water', 'مياه', Icons.water_drop),
    ]),
    // fun
    ..._iconsFor('fun', [
      ('movie', 'فيلم', Icons.movie),
      ('music', 'موسيقى', Icons.music_note),
      ('sports_esports', 'جيمز', Icons.sports_esports),
      ('celebration', 'خروجات', Icons.celebration),
      ('beach', 'رحلة', Icons.beach_access),
      ('camera', 'تصوير', Icons.camera_alt),
      ('sports', 'رياضة', Icons.sports_soccer),
      ('park', 'حديقة', Icons.park),
      ('attractions', 'ملاهي', Icons.attractions),
      ('festival', 'حفلة', Icons.festival),
      ('theater', 'مسرح', Icons.theaters),
      ('palette', 'فن', Icons.palette),
    ]),
    // work
    ..._iconsFor('work', [
      ('work', 'شغل', Icons.work),
      ('business', 'شركة', Icons.business),
      ('meeting', 'اجتماع', Icons.groups),
      ('laptop', 'لاب توب', Icons.laptop),
      ('desk', 'مكتب', Icons.desk),
      ('assignment', 'تاسك', Icons.assignment),
      ('schedule', 'دوام', Icons.schedule),
      ('engineering', 'هندسة', Icons.engineering),
      ('support', 'خدمة', Icons.support_agent),
      ('design', 'تصميم', Icons.design_services),
      ('calculate', 'حسابات', Icons.calculate),
      ('checklist', 'قائمة', Icons.checklist),
    ]),
    // shopping
    ..._iconsFor('shopping', [
      ('shopping_cart', 'سلة', Icons.shopping_cart),
      ('store', 'متجر', Icons.store),
      ('shopping_bag', 'شنطة', Icons.shopping_bag),
      ('checkroom', 'ملابس', Icons.checkroom),
      ('diamond', 'اكسسوار', Icons.diamond),
      ('chair_alt', 'أثاث', Icons.chair_alt),
      ('toys', 'ألعاب', Icons.toys),
      ('watch', 'ساعة', Icons.watch),
      ('phone_iphone', 'موبايل', Icons.phone_iphone),
      ('redeem', 'هدايا', Icons.redeem),
      ('local_mall', 'مول', Icons.local_mall),
      ('sell', 'عروض', Icons.sell),
    ]),
    // tech
    ..._iconsFor('tech', [
      ('smartphone', 'موبايل', Icons.smartphone),
      ('computer', 'كمبيوتر', Icons.computer),
      ('wifi', 'إنترنت', Icons.wifi),
      ('memory', 'تقنية', Icons.memory),
      ('devices', 'أجهزة', Icons.devices),
      ('cable', 'كابلات', Icons.cable),
      ('router', 'راوتر', Icons.router),
      ('headset', 'سماعة', Icons.headset),
      ('monitor', 'شاشة', Icons.monitor),
      ('keyboard', 'كيبورد', Icons.keyboard),
      ('mouse', 'ماوس', Icons.mouse),
      ('cloud', 'سحابة', Icons.cloud),
    ]),
    // other
    ..._iconsFor('other', [
      ('category', 'عام', Icons.category),
      ('star', 'مميز', Icons.star),
      ('bookmark', 'مرجع', Icons.bookmark),
      ('bolt', 'سريع', Icons.bolt),
      ('pets', 'حيوانات', Icons.pets),
      ('school', 'تعليم', Icons.school),
      ('child_care', 'أطفال', Icons.child_care),
      ('card_giftcard', 'هدية', Icons.card_giftcard),
      ('local_florist', 'زهور', Icons.local_florist),
      ('public', 'عام', Icons.public),
      ('event', 'مناسبة', Icons.event),
      ('more_horiz', 'أخرى', Icons.more_horiz),
    ]),
  ];

  static List<AppIconItem> _iconsFor(
    String categoryId,
    List<(String, String, IconData)> data,
  ) {
    return data
        .map((e) => AppIconItem(
              name: e.$1,
              label: e.$2,
              categoryId: categoryId,
              icon: e.$3,
            ))
        .toList();
  }

  static List<AppIconItem> iconsForCategory(String categoryId) {
    if (categoryId == 'all') {
      return List<AppIconItem>.from(_baseIcons);
    }
    return _baseIcons.where((icon) => icon.categoryId == categoryId).toList();
  }

  static IconData iconDataForName(String name) {
    for (final item in _baseIcons) {
      if (item.name == name) return item.icon;
    }
    for (final item in _baseIcons) {
      if (name.contains(item.name)) return item.icon;
    }
    const legacyMap = <String, IconData>{
      'PiggyBank': Icons.savings,
      'Wallet2': Icons.account_balance_wallet,
      'UtensilsCrossed': Icons.restaurant,
      'BriefcaseBusiness': Icons.work,
      'HeartPulse': Icons.favorite,
      'ShoppingCart': Icons.shopping_cart,
      'CarFront': Icons.directions_car,
      'Home': Icons.home,
    };
    return legacyMap[name] ?? Icons.category;
  }

  static Future<IconPickerResult?> show(
    BuildContext context, {
    required String initialIconName,
    required String initialColorHex,
    String title = 'تخصيص الأيقونة',
  }) {
    return showDialog<IconPickerResult>(
      context: context,
      builder: (_) => Dialog(
        child: AppIconPickerDialog(
          initialIconName: initialIconName,
          initialColorHex: initialColorHex,
          title: title,
        ),
      ),
    );
  }

  @override
  State<AppIconPickerDialog> createState() => _AppIconPickerDialogState();
}

class _AppIconPickerDialogState extends State<AppIconPickerDialog> {
  late String _selectedCategoryId;
  late String _selectedIconName;
  late Color _selectedColor;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _selectedIconName = widget.initialIconName;
    _selectedColor = _hexToColor(widget.initialColorHex);
    _selectedCategoryId = 'all';
  }

  @override
  Widget build(BuildContext context) {
    final icons = AppIconPickerDialog.iconsForCategory(_selectedCategoryId);
    final theme = Theme.of(context);
    final colorHex = _colorToHex(_selectedColor);
    return SizedBox(
      width: 720,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _topSegment(theme),
            const SizedBox(height: 12),
            if (_step == 0) ...[
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'الكاتيجوري',
                ),
                items: AppIconPickerDialog.categoryOrder
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(AppIconPickerDialog.categoryLabels[id] ?? id),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategoryId = value);
                },
              ),
              const SizedBox(height: 8),
              Container(
                height: 300,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                  color: theme.colorScheme.surface,
                ),
                child: GridView.builder(
                  itemCount: icons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = icons[index];
                    final active = _selectedIconName == item.name;
                    return InkWell(
                      onTap: () => setState(() => _selectedIconName = item.name),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            item.icon,
                            size: 24,
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('التالي'),
                  ),
                ],
              ),
            ] else ...[
              _ColorWheel(
                color: _selectedColor,
                onChanged: (color) => setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        AppIconPickerDialog.iconDataForName(_selectedIconName),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('اللون المختار: $colorHex'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => setState(() => _step = 0),
                    child: const Text('رجوع'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      IconPickerResult(
                        iconName: _selectedIconName,
                        colorHex: _colorToHex(_selectedColor),
                      ),
                    ),
                    child: const Text('تأكيد'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _topSegment(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const pad = 4.0;
          final thumbWidth = (constraints.maxWidth - (pad * 3)) / 2;
          return Container(
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  top: pad,
                  bottom: pad,
                  start: _step == 0 ? pad : (pad * 2) + thumbWidth,
                  width: thumbWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E7F5C),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _step = 0),
                        child: Center(
                          child: Text(
                            'اختيار الأيقونة',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _step == 0
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _step = 1),
                        child: Center(
                          child: Text(
                            'اختيار اللون',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _step == 1
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _hexToColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  String _colorToHex(Color color) {
    return '#'
        '${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}';
  }
}

class _ColorWheel extends StatelessWidget {
  const _ColorWheel({
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: _ColorWheelGesture(
        color: color,
        onChanged: onChanged,
      ),
    );
  }
}

class _ColorWheelGesture extends StatefulWidget {
  const _ColorWheelGesture({
    required this.color,
    required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorWheelGesture> createState() => _ColorWheelGestureState();
}

class _ColorWheelGestureState extends State<_ColorWheelGesture> {
  void _update(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = localPosition - center;
    final radius = size.shortestSide / 2;
    final distance = vector.distance.clamp(0, radius);
    final saturation = (distance / radius).clamp(0.0, 1.0);
    final hue = ((math.atan2(vector.dy, vector.dx) * 180 / math.pi) + 360) % 360;
    final color = HSVColor.fromAHSV(1, hue, saturation, 1).toColor();
    widget.onChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final hsv = HSVColor.fromColor(widget.color);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final radius = size.shortestSide / 2;
        final angle = hsv.hue * math.pi / 180;
        final distance = hsv.saturation * radius;
        final center = Offset(size.width / 2, size.height / 2);
        final knob = Offset(
          center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance,
        );
        return GestureDetector(
          onPanDown: (d) => _update(d.localPosition, size),
          onPanUpdate: (d) => _update(d.localPosition, size),
          child: Stack(
            children: [
              CustomPaint(
                size: size,
                painter: _WheelPainter(),
              ),
              Positioned(
                left: knob.dx - 10,
                top: knob.dy - 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: List.generate(
          13,
          (index) => HSVColor.fromAHSV(1, (index * 30).toDouble(), 1, 1).toColor(),
        ),
      ).createShader(rect);
    canvas.drawCircle(center, radius, sweep);

    final radial = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.white, Colors.transparent],
        stops: const [0, 1],
      ).createShader(rect);
    canvas.drawCircle(center, radius, radial);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
