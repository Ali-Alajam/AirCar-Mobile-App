// lib/my_cars_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'main.dart' show AddCarSheet;

/* ══════════════════════════════════════════════════
   MY CARS PAGE  – owner view all cars, edit, delete
══════════════════════════════════════════════════ */
class MyCarsPage extends StatelessWidget {
  const MyCarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF92400E),
        title: const Text('My Listed Cars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add new car',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddCarSheet(ownerId: uid),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cars')
            .where('ownerId', isEqualTo: uid)
           
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 80,
                      color: AppTheme.textSub.withOpacity(0.25)),
                  const SizedBox(height: 16),
                  const Text('No cars listed yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain)),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first car',
                      style:
                          TextStyle(color: AppTheme.textSub, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF92400E)),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Car',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddCarSheet(ownerId: uid),
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              return _CarManageCard(carId: doc.id, data: d);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF92400E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Car'),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddCarSheet(ownerId: uid),
        ),
      ),
    );
  }
}

/* ══════════════════════════════════════════════════
   CAR MANAGE CARD
══════════════════════════════════════════════════ */
class _CarManageCard extends StatelessWidget {
  final String carId;
  final Map<String, dynamic> data;

  const _CarManageCard({required this.carId, required this.data});

  @override
  Widget build(BuildContext context) {
    final available = data['available'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: available
                ? AppTheme.success.withOpacity(0.25)
                : AppTheme.error.withOpacity(0.2)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // ── Image + status badge
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  data['imageUrl'] ?? '',
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 170,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF92400E), Color(0xFFB45309)]),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: const Center(
                      child: Icon(Icons.directions_car_rounded,
                          color: Colors.white38, size: 56),
                    ),
                  ),
                ),
              ),
              // Availability badge
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () => _toggleAvailability(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: available ? AppTheme.success : AppTheme.error,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6)
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(
                        available ? 'Live' : 'Hidden',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.touch_app,
                          size: 11, color: Colors.white70),
                    ]),
                  ),
                ),
              ),
              // Price badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data['pricePerDay']} SAR/day',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // ── Info + actions
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & city
                Text(data['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textMain)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppTheme.textSub),
                  const SizedBox(width: 3),
                  Text('${data['city'] ?? ''}  •  ${data['year'] ?? ''}',
                      style: const TextStyle(
                          color: AppTheme.textSub, fontSize: 13)),
                ]),

                const SizedBox(height: 10),

                // Specs row
                Row(children: [
                  _SpecPill(
                      icon: Icons.settings, label: data['transmission'] ?? 'Auto'),
                  const SizedBox(width: 6),
                  _SpecPill(
                      icon: Icons.local_gas_station,
                      label: data['fuelType'] ?? 'Petrol'),
                  const SizedBox(width: 6),
                  _SpecPill(
                      icon: Icons.event_seat,
                      label: '${data['seats'] ?? 5} seats'),
                ]),

                const SizedBox(height: 12),

                // Booking count for this car
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('carId', isEqualTo: carId)
                      .snapshots(),
                  builder: (ctx, bSnap) {
                    final total = bSnap.data?.docs.length ?? 0;
                    final confirmed = bSnap.data?.docs
                            .where((b) =>
                                (b.data() as Map)['status'] == 'confirmed')
                            .length ??
                        0;
                    final pending = bSnap.data?.docs
                            .where((b) =>
                                (b.data() as Map)['status'] == 'pending')
                            .length ??
                        0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _BookingStat('Total', total, AppTheme.textSub),
                            _vDivider(),
                            _BookingStat(
                                'Confirmed', confirmed, AppTheme.success),
                            _vDivider(),
                            _BookingStat('Pending', pending, AppTheme.warning),
                          ]),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(children: [
                  // Toggle availability
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleAvailability(context),
                      icon: Icon(
                          available
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 15),
                      label: Text(available ? 'Hide' : 'Publish',
                          style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: available
                            ? AppTheme.textSub
                            : AppTheme.success,
                        side: BorderSide(
                            color: available
                                ? AppTheme.divider
                                : AppTheme.success),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditSheet(context),
                      icon:
                          const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Edit',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline, size: 15),
                      label: const Text('Delete',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 28, color: AppTheme.divider,
      margin: const EdgeInsets.symmetric(horizontal: 4));

  Future<void> _toggleAvailability(BuildContext context) async {
    final newVal = !(data['available'] == true);
    await FirebaseFirestore.instance
        .collection('cars')
        .doc(carId)
        .update({'available': newVal});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newVal ? '✅ Car is now Live' : '🔒 Car is now Hidden'),
        backgroundColor: newVal ? AppTheme.success : AppTheme.textSub,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.error),
          SizedBox(width: 8),
          Text('Delete Car'),
        ]),
        content: Text(
            'Are you sure you want to delete "${data['title']}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(carId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Car deleted'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCarSheet(carId: carId, data: data),
    );
  }
}

/* ── Spec pill ── */
class _SpecPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMain,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

/* ── Booking stat ── */
class _BookingStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _BookingStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$value',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSub)),
    ]);
  }
}

/* ══════════════════════════════════════════════════
   EDIT CAR SHEET
══════════════════════════════════════════════════ */
class _EditCarSheet extends StatefulWidget {
  final String carId;
  final Map<String, dynamic> data;

  const _EditCarSheet({required this.carId, required this.data});

  @override
  State<_EditCarSheet> createState() => _EditCarSheetState();
}

class _EditCarSheetState extends State<_EditCarSheet> {
  late TextEditingController _titleCtl;
  late TextEditingController _cityCtl;
  late TextEditingController _yearCtl;
  late TextEditingController _priceCtl;
  late TextEditingController _imgCtl;
  late TextEditingController _descCtl;
  late TextEditingController _mileageCtl;
  late String _transmission;
  late String _fuelType;
  late int _seats;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _titleCtl = TextEditingController(text: d['title'] ?? '');
    _cityCtl = TextEditingController(text: d['city'] ?? '');
    _yearCtl =
        TextEditingController(text: (d['year'] ?? '').toString());
    _priceCtl =
        TextEditingController(text: (d['pricePerDay'] ?? '').toString());
    _imgCtl = TextEditingController(text: d['imageUrl'] ?? '');
    _descCtl = TextEditingController(text: d['description'] ?? '');
    _mileageCtl = TextEditingController(text: d['mileage'] ?? '');
    _transmission = d['transmission'] ?? 'Automatic';
    _fuelType = d['fuelType'] ?? 'Petrol';
    _seats = (d['seats'] ?? 5) as int;
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtl, _cityCtl, _yearCtl, _priceCtl, _imgCtl, _descCtl, _mileageCtl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtl.text.trim().isEmpty ||
        int.tryParse(_yearCtl.text.trim()) == null ||
        int.tryParse(_priceCtl.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all required fields correctly'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carId)
          .update({
        'title': _titleCtl.text.trim(),
        'city': _cityCtl.text.trim(),
        'year': int.parse(_yearCtl.text.trim()),
        'pricePerDay': int.parse(_priceCtl.text.trim()),
        'imageUrl': _imgCtl.text.trim().isEmpty
            ? widget.data['imageUrl']
            : _imgCtl.text.trim(),
        'description': _descCtl.text.trim(),
        'transmission': _transmission,
        'fuelType': _fuelType,
        'seats': _seats,
        'mileage': _mileageCtl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Car updated successfully'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Edit Car Details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleCtl,
              decoration: const InputDecoration(
                  labelText: 'Car Title *',
                  prefixIcon: Icon(Icons.directions_car_rounded)),
            ),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: TextField(
                  controller: _cityCtl,
                  decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _yearCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Year *',
                      prefixIcon: Icon(Icons.calendar_today)),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: TextField(
                  controller: _priceCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'SAR / day *',
                      prefixIcon: Icon(Icons.attach_money)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _mileageCtl,
                  decoration: const InputDecoration(
                      labelText: 'Mileage (km)',
                      prefixIcon: Icon(Icons.speed)),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _transmission,
                  decoration:
                      const InputDecoration(labelText: 'Transmission'),
                  items: ['Automatic', 'Manual']
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _transmission = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fuelType,
                  decoration:
                      const InputDecoration(labelText: 'Fuel Type'),
                  items: ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _fuelType = v!),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            Row(children: [
              const Text('Seats: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSub,
                      fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _seats.toDouble(),
                  min: 2,
                  max: 8,
                  divisions: 6,
                  label: '$_seats',
                  activeColor: const Color(0xFF92400E),
                  onChanged: (v) => setState(() => _seats = v.round()),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF92400E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('$_seats',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            TextField(
              controller: _imgCtl,
              decoration: const InputDecoration(
                  labelText: 'Image URL (leave blank to keep current)',
                  prefixIcon: Icon(Icons.image_outlined)),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descCtl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined)),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF92400E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
