// lib/booking_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt bàn')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: ReservationForm(),
          ),
        ),
      ),
    );
  }
}

class ReservationForm extends StatefulWidget {
  const ReservationForm({super.key});
  @override
  State<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final note = TextEditingController();
  bool _submitting = false;
  DateTime? _date;
  TimeOfDay? _time;
  int _party = 2;

  // ====== Giỏ hàng đặt món ======
  final List<_CartLine> _preOrderCart = [];
  int _cartCount = 0;

  final money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '',
    decimalDigits: 0,
  );

  // ====== Dữ liệu món theo nhóm ======
  final Map<String, List<_OrderItem>> catalog = {
    'Miền Bắc': [
      _OrderItem('Bò kéo pháo', 169000, 'assets/dishes/bo_keo_phao_1.png'),
      _OrderItem(
        'Đậu hũ trứng 3 Sành',
        99000,
        'assets/dishes/dau_hu_trung_1.png',
      ),
      _OrderItem(
        'Cá thác lác rút xương',
        139000,
        'assets/dishes/ca_thac_lat_rut_xuong_1.png',
      ),
      _OrderItem(
        'Nọng đặc vụ mắm tỏi',
        159000,
        'assets/dishes/nong_dac_vu_mam_toi_1.png',
      ),
    ],
    'Miền Trung': [
      _OrderItem(
        'Cá dìa nướng muối',
        159000,
        'assets/dishes/ca_dia_nuong_muoi_1.png',
      ),
      _OrderItem(
        'Hột vịt lộn om bầu',
        129000,
        'assets/dishes/hot_vit_lon_om_bau_1.png',
      ),
      _OrderItem(
        'Lẩu gà ớt hiểm (nhỏ)',
        199000,
        'assets/dishes/lau_ga_ot_hiem_1.png',
      ),
    ],
    'Miền Nam': [
      _OrderItem(
        'Tôm xông cay Tiền lửa',
        169000,
        'assets/dishes/tom_xong_cay_tien_lua_mien_nam_1.png',
      ),
      _OrderItem(
        'Chân gà sốt Thái',
        99000,
        'assets/dishes/chan_ga_sot_thai_1.png',
      ),
      _OrderItem('Mực sốt Thái', 169000, 'assets/dishes/muc_sot_thai_1.png'),
    ],
    'Đặc sản': [
      _OrderItem(
        'Khoai mạt nướng sốt 3 Sành',
        79000,
        'assets/dishes/khoai_mat_nuong_sot_3_sanh_1.png',
      ),
      _OrderItem(
        'Sụn gà muối tuyết',
        119000,
        'assets/dishes/sun_ga_muoi_tuyet_1.png',
      ),
      _OrderItem(
        'Khoai môn du kích',
        119000,
        'assets/dishes/khoai_mon_du_kich_1.png',
      ),
      _OrderItem(
        'Tóp mỡ mắm tỏi',
        129000,
        'assets/dishes/top_mo_mam_toi_1.png',
      ),
    ],
    'Món chính & Cơm/Mì': [
      _OrderItem(
        'Cơm ghẹ phủ trứng',
        149000,
        'assets/dishes/com_ghe_phu_trung_1.png',
      ),
      _OrderItem(
        'Mì xào Hợp Tác Xã',
        119000,
        'assets/dishes/mi_xao_hop_tac_xa_1.png',
      ),
      _OrderItem('Bò măng tây', 179000, 'assets/dishes/bo_mang_tay_1.png'),
    ],
    'Canh - Lẩu': [
      _OrderItem('Nghêu nấu khế', 99000, 'assets/dishes/ngheu_nau_khe_1.png'),
      _OrderItem(
        'Lẩu gà ớt hiểm',
        249000,
        'assets/dishes/lau_ga_ot_hiem_1.png',
      ),
    ],
    'Hải sản - Nướng': [
      _OrderItem(
        'Tôm nướng sốt 3 Sành',
        159000,
        'assets/dishes/tom_nuong_1.png',
      ),
      _OrderItem(
        'Cá dìa nướng muối',
        159000,
        'assets/dishes/ca_dia_nuong_muoi_1.png',
      ),
      _OrderItem(
        'Nạc nọng nướng',
        159000,
        'assets/dishes/nat_nong_nuong_1.png',
      ),
    ],
    'Ốc - Hải sản nóng': [
      _OrderItem(
        'Ốc bươu hấp tiêu',
        99000,
        'assets/dishes/oc_buou_hap_tieu_1.png',
      ),
    ],
    'Khô - Mắm - Nướng': [
      _OrderItem('Khô cá dứa', 79000, 'assets/dishes/kho_ca_dua_1.png'),
    ],
  };

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    note.dispose();
    super.dispose();
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: _date ?? DateTime(now.year, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // ====== Thêm món vào giỏ ======
  void _addToCart(_OrderItem it) {
    final idx = _preOrderCart.indexWhere((e) => e.item.name == it.name);
    if (idx >= 0) {
      _preOrderCart[idx] = _preOrderCart[idx].copyWith(
        qty: _preOrderCart[idx].qty + 1,
      );
    } else {
      _preOrderCart.add(_CartLine(item: it, qty: 1));
    }
    setState(
      () => _cartCount = _preOrderCart.fold<int>(0, (s, e) => s + e.qty),
    );
  }

  int get _totalPreOrder =>
      _preOrderCart.fold<int>(0, (s, e) => s + e.qty * e.item.price);

  // ====== Mở modal chọn món ======
  Future<void> _openPreOrderSheet() async {
    final tabs = catalog.keys.toList();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return DefaultTabController(
              length: tabs.length,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 4,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chọn món đặt trước',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.amber.shade600,
                    labelColor: Colors.amber.shade500,
                    unselectedLabelColor: Colors.white70,
                    tabs: [for (final t in tabs) Tab(text: t.toUpperCase())],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        for (final t in tabs)
                          _OrderGrid(
                            money: money,
                            items: catalog[t]!,
                            onAdd: (it) {
                              _addToCart(it);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  // ====== Xem giỏ hàng ======
  Future<void> _viewCart() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Giỏ món đặt trước',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _preOrderCart.isEmpty
                            ? const Center(
                                child: Text(
                                  'Chưa có món nào',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              )
                            : ListView.builder(
                                controller: controller,
                                itemCount: _preOrderCart.length,
                                itemBuilder: (_, i) {
                                  final line = _preOrderCart[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1C1C),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                line.item.name,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${money.format(line.item.price)}đ',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            if (line.qty > 1) {
                                              setModalState(() {
                                                _preOrderCart[i] = line
                                                    .copyWith(
                                                      qty: line.qty - 1,
                                                    );
                                              });
                                            } else {
                                              setModalState(() {
                                                _preOrderCart.removeAt(i);
                                              });
                                            }
                                            setState(() {
                                              _cartCount = _preOrderCart.fold(
                                                0,
                                                (s, e) => s + e.qty,
                                              );
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          '${line.qty}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setModalState(() {
                                              _preOrderCart[i] = line.copyWith(
                                                qty: line.qty + 1,
                                              );
                                            });
                                            setState(() {
                                              _cartCount = _preOrderCart.fold(
                                                0,
                                                (s, e) => s + e.qty,
                                              );
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${money.format(line.qty * line.item.price)}đ',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '${money.format(_totalPreOrder)} đ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Đóng',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) return _toast('Vui lòng chọn ngày.');
    if (_time == null) return _toast('Vui lòng chọn giờ.');

    setState(() => _submitting = true);
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final dt = _combine(_date!, _time!);

      // Chuyển đổi giỏ hàng thành list map
      final preOrderData = _preOrderCart
          .map(
            (line) => {
              'name': line.item.name,
              'price': line.item.price,
              'qty': line.qty,
            },
          )
          .toList();

      await FirebaseFirestore.instance.collection('reservations').add({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(_date!),
        'time': DateFormat('HH:mm').format(dt),
        'partySize': _party,
        'note': note.text.trim(),
        'preOrder': preOrderData, // Lưu món đặt trước
        'preOrderTotal': _totalPreOrder, // Tổng tiền món đặt trước
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'web',
        'status': 'pending',
        'tableId': null,
      });

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Thank you!'),
          content: Text(
            _preOrderCart.isEmpty
                ? 'Your reservation has been sent. We will contact you soon.'
                : 'Your reservation with pre-order (${money.format(_totalPreOrder)}đ) has been sent. We will contact you soon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      _formKey.currentState!.reset();
      name.clear();
      phone.clear();
      note.clear();
      setState(() {
        _date = null;
        _time = null;
        _party = 2;
        _preOrderCart.clear();
        _cartCount = 0;
      });
    } catch (_) {
      _toast('Gửi thất bại, thử lại nhé.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tonalColor = Theme.of(context).colorScheme.secondaryContainer;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 16,
            children: [
              Expanded(
                child: TextFormField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'Full name',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: tonalColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  validator: _req,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: tonalColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  validator: _req,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _pickDate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _date == null
                        ? 'Pick date'
                        : DateFormat('dd/MM/yyyy').format(_date!),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _pickTime,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _time == null ? 'Pick time' : _time!.format(context),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Party size: ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              DropdownButton<int>(
                value: _party,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
                items: [
                  for (final n in List.generate(12, (i) => i + 1))
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (v) => setState(() => _party = v ?? 2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: note,
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: tonalColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ====== PHẦN ĐẶT MÓN TRƯỚC ======
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tonalColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade600, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.amber.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Đặt món trước (tùy chọn)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_cartCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_cartCount món',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_preOrderCart.isNotEmpty) ...[
                  Text(
                    'Tổng: ${money.format(_totalPreOrder)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openPreOrderSheet,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text(
                          'Chọn món',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_preOrderCart.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _viewCart,
                          icon: const Icon(Icons.visibility),
                          label: const Text(
                            'Xem giỏ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.check),
            label: Text(
              _submitting ? 'Sending...' : 'Submit Reservation',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Models ======
class _OrderItem {
  final String name;
  final int price;
  final String image;
  const _OrderItem(this.name, this.price, this.image);
}

class _CartLine {
  final _OrderItem item;
  final int qty;
  const _CartLine({required this.item, required this.qty});
  _CartLine copyWith({int? qty}) => _CartLine(item: item, qty: qty ?? this.qty);
}

// ====== Widget Grid món ======
class _OrderGrid extends StatelessWidget {
  final List<_OrderItem> items;
  final void Function(_OrderItem) onAdd;
  final NumberFormat money;
  const _OrderGrid({
    required this.items,
    required this.onAdd,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cross = w >= 600 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.71,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final it = items[i];
        return Card(
          color: const Color(0xFF151515),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    it.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF202020),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white24,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${money.format(it.price)}đ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => onAdd(it),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'THÊM',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
