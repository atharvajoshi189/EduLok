import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eduthon/services/language_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('profile') ?? "Profile",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          AppLocalizations.of(context)?.translate('profileComingSoon') ?? 'Profile Settings Coming Soon',
          style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
