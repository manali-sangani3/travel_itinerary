import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/di/injection.dart';

class AddBookingPage extends StatefulWidget {
  final String tripId;
  const AddBookingPage({super.key, required this.tripId});
  @override
  State<AddBookingPage> createState() => _AddBookingPageState();
}

class _AddBookingPageState extends State<AddBookingPage> {
  final _form = GlobalKey<FormState>();
  String _type = 'flight';
  final _ref = TextEditingController();
  // flight
  final _airline = TextEditingController();
  final _flightNo = TextEditingController();
  final _departure = TextEditingController();
  final _arrival = TextEditingController();
  // hotel
  final _hotelName = TextEditingController();
  final _checkIn = TextEditingController();
  final _checkOut = TextEditingController();
  final _roomType = TextEditingController();
  // car
  final _carCompany = TextEditingController();
  final _pickup = TextEditingController();
  // activity
  final _activityName = TextEditingController();
  final _activityDate = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_ref, _airline, _flightNo, _departure, _arrival, _hotelName, _checkIn, _checkOut, _roomType, _carCompany, _pickup, _activityName, _activityDate]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final details = switch (_type) {
      'flight' => {'airline': _airline.text, 'flight_number': _flightNo.text, 'departure': _departure.text, 'arrival': _arrival.text},
      'hotel' => {'hotel_name': _hotelName.text, 'check_in': _checkIn.text, 'check_out': _checkOut.text, 'room_type': _roomType.text},
      'car_rental' => {'company': _carCompany.text, 'pickup': _pickup.text},
      _ => {'name': _activityName.text, 'date': _activityDate.text},
    };
    try {
      await sl<ApiClient>().post('/trips/${widget.tripId}/bookings', data: {'type': _type, 'reference_number': _ref.text.trim(), 'details': details});
      if (mounted) context.go('/trips/${widget.tripId}/bookings');
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Booking'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips/${widget.tripId}/bookings')),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking Type', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.bookingTypes.map((t) => ChoiceChip(
                  label: Text(t.replaceAll('_', ' ')),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                )).toList(),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Reference / Confirmation Number', hint: 'e.g. ABC123', controller: _ref, prefix: const Icon(Icons.tag_rounded, size: 20, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              Text('Details', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              if (_type == 'flight') ...[
                AppTextField(label: 'Airline', hint: 'e.g. Air India', controller: _airline),
                const SizedBox(height: 12),
                AppTextField(label: 'Flight Number', hint: 'e.g. AI202', controller: _flightNo),
                const SizedBox(height: 12),
                AppTextField(label: 'Departure', hint: 'City, Date & Time', controller: _departure),
                const SizedBox(height: 12),
                AppTextField(label: 'Arrival', hint: 'City, Date & Time', controller: _arrival),
              ] else if (_type == 'hotel') ...[
                AppTextField(label: 'Hotel Name', hint: 'e.g. Le Meridien', controller: _hotelName),
                const SizedBox(height: 12),
                AppTextField(label: 'Check-In', hint: 'DD/MM/YYYY HH:MM', controller: _checkIn),
                const SizedBox(height: 12),
                AppTextField(label: 'Check-Out', hint: 'DD/MM/YYYY HH:MM', controller: _checkOut),
                const SizedBox(height: 12),
                AppTextField(label: 'Room Type', hint: 'e.g. Deluxe King', controller: _roomType),
              ] else if (_type == 'car_rental') ...[
                AppTextField(label: 'Car Rental Company', hint: 'e.g. Hertz', controller: _carCompany),
                const SizedBox(height: 12),
                AppTextField(label: 'Pickup Location', hint: 'Airport / Hotel', controller: _pickup),
              ] else ...[
                AppTextField(label: 'Activity Name', hint: 'e.g. Louvre Museum Tour', controller: _activityName),
                const SizedBox(height: 12),
                AppTextField(label: 'Date', hint: 'DD/MM/YYYY', controller: _activityDate),
              ],
              const SizedBox(height: 32),
              AppButton(label: 'Save Booking', loading: _loading, onPressed: _submit),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
