import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _passportName = TextEditingController();
  final _passportNumber = TextEditingController();
  final _passportExpiry = TextEditingController();
  final _nationality = TextEditingController();
  final _homeAirport = TextEditingController();
  final _seatPref = TextEditingController();

  @override
  void dispose() {
    _passportName.dispose(); _passportNumber.dispose(); _passportExpiry.dispose();
    _nationality.dispose(); _homeAirport.dispose(); _seatPref.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.go('/trips')),
        actions: [
          TextButton(
            onPressed: () { context.read<AuthBloc>().add(LogoutRequested()); context.go('/login'); },
            child: Text('Sign Out', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error));
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + email
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              user?.email.isNotEmpty == true ? user!.email[0].toUpperCase() : '?',
                              style: AppTextStyles.h1.copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(user?.email ?? '', style: AppTextStyles.bodyLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Passport details
                  Text('Passport Details', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text('Stored encrypted on server', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(label: 'Full Name', hint: 'As on passport', controller: _passportName, prefix: const Icon(Icons.person_outlined, size: 20, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Passport Number', hint: 'AB1234567', controller: _passportNumber, prefix: const Icon(Icons.badge_outlined, size: 20, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Expiry Date', hint: 'DD/MM/YYYY', controller: _passportExpiry, prefix: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Nationality', hint: 'e.g. Indian', controller: _nationality, prefix: const Icon(Icons.flag_outlined, size: 20, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Travel preferences
                  Text('Travel Preferences', style: AppTextStyles.h3),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      children: [
                        AppTextField(label: 'Home Airport', hint: 'e.g. BOM', controller: _homeAirport, prefix: const Icon(Icons.local_airport_outlined, size: 20, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Seat Preference', hint: 'Window / Aisle / Middle', controller: _seatPref, prefix: const Icon(Icons.airline_seat_recline_normal_outlined, size: 20, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, s) => AppButton(
                      label: 'Save Profile',
                      loading: s is AuthLoading,
                      onPressed: () {
                        context.read<AuthBloc>().add(ProfileUpdateRequested({
                          'passport_details': {
                            'full_name': _passportName.text,
                            'passport_number': _passportNumber.text,
                            'expiry_date': _passportExpiry.text,
                            'nationality': _nationality.text,
                          },
                          'travel_preferences': {
                            'home_airport': _homeAirport.text,
                            'seat_preference': _seatPref.text,
                          },
                        }));
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
