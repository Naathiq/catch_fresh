import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CuttersScreen extends StatelessWidget {
  const CuttersScreen({super.key});

  Future<void> _openWhatsApp(BuildContext context, String rawPhone, String name) async {
    final cleanNumber = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullNumber = cleanNumber.startsWith('91') ? cleanNumber : '91$cleanNumber';
    final message = Uri.encodeComponent('Hello $name, I would like to book a harvest service.');

    final Uri nativeWhatsAppUri = Uri.parse('whatsapp://send?phone=$fullNumber&text=$message');
    final Uri webWhatsAppUri = Uri.parse('https://wa.me/$fullNumber?text=$message');
    final Uri apiWhatsAppUri = Uri.parse('https://api.whatsapp.com/send?phone=$fullNumber&text=$message');
    final Uri telUri = Uri.parse('tel:$cleanNumber');

    // 1. Try launching native WhatsApp app intent
    try {
      if (await canLaunchUrl(nativeWhatsAppUri)) {
        await launchUrl(nativeWhatsAppUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // 2. Try wa.me link with externalApplication
    try {
      if (await canLaunchUrl(webWhatsAppUri)) {
        await launchUrl(webWhatsAppUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // 3. Try wa.me link with platformDefault
    try {
      if (await canLaunchUrl(webWhatsAppUri)) {
        await launchUrl(webWhatsAppUri, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (_) {}

    // 4. Try api.whatsapp.com with platformDefault
    try {
      if (await canLaunchUrl(apiWhatsAppUri)) {
        await launchUrl(apiWhatsAppUri, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (_) {}

    // 5. Direct launch attempt for web WhatsApp
    try {
      await launchUrl(webWhatsAppUri, mode: LaunchMode.externalApplication);
      return;
    } catch (_) {}

    // 6. Graceful fallback: Open phone dialer if WhatsApp is unavailable on device
    try {
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('WhatsApp not detected. Connecting call to $name...'),
              backgroundColor: const Color(0xFF0D9488),
            ),
          );
        }
        return;
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open WhatsApp or call for $name ($rawPhone)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SERVICES', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
          const SizedBox(height: 4),
          const Text('Book a Cutter', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('Contact our trusted professionals for harvesting.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          const SizedBox(height: 32),

          _buildCutterCard(
            context: context,
            name: 'Nagoor Cutter',
            badge: 'No. 1',
            phone: '97916 35465',
            gradientColors: const [Color(0xFF0F172A), Color(0xFF1E3A8A)],
            iconColor: const Color(0xFF60A5FA),
          ),
          const SizedBox(height: 16),
          _buildCutterCard(
            context: context,
            name: 'Arumugam',
            badge: 'Expert',
            phone: '94423 28231',
            gradientColors: const [Color(0xFF0F172A), Color(0xFF064E3B)],
            iconColor: const Color(0xFF34D399),
          ),
        ],
      ),
    );
  }

  Widget _buildCutterCard({
    required BuildContext context,
    required String name,
    required String badge,
    required String phone,
    required List<Color> gradientColors,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () => _openWhatsApp(context, phone, name),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.support_agent_rounded, color: iconColor, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(badge, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(phone, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                ],
              ),
            ),
            // Call button that redirects to WhatsApp
            Tooltip(
              message: 'Chat on WhatsApp',
              child: InkWell(
                onTap: () => _openWhatsApp(context, phone, name),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
