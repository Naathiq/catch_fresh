import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'relay_icons.dart';

class RelayScreen extends StatelessWidget {
  final Map<dynamic, dynamic> liveData;
  final Map<dynamic, dynamic> commandsData;
  final Map<String, String> relayNames;
  final Map<String, String>? relayIcons;

  const RelayScreen({
    super.key,
    required this.liveData,
    required this.commandsData,
    required this.relayNames,
    this.relayIcons,
  });

  Future<void> _toggleRelay(int index, bool currentState) async {
    final ref = FirebaseDatabase.instance.ref('device01/commands/relay$index');
    await ref.set({
      'state': !currentState,
      'updatedAt': ServerValue.timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('CONTROL', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        const Text('Relay Control', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const Text('Commands are stored in Firebase and consumed by the ESP32.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 24),

        ...List.generate(4, (i) {
          final int relayNum = i + 1;
          final bool physicalState = liveData['relay$relayNum'] == true;
          final commandMap = commandsData['relay$relayNum'] as Map<dynamic, dynamic>?;
          final bool desiredState = commandMap != null ? commandMap['state'] == true : physicalState;
          final bool isPending = physicalState != desiredState;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isPending ? const Color(0xFFFBBF24).withOpacity(0.5) : const Color(0xFF94A3B8).withOpacity(0.13)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (relayIcons != null) ...[
                          Icon(getRelayIcon(relayIcons![relayNum.toString()]), color: const Color(0xFF2DD4BF), size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(relayNames[relayNum.toString()] ?? 'Relay $relayNum', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Physical: ${physicalState ? "ON" : "OFF"}',
                      style: TextStyle(color: physicalState ? const Color(0xFF34D399) : const Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: isPending ? const Color(0xFFFBBF24) : const Color(0xFF34D399)),
                        const SizedBox(width: 6),
                        Text(
                          isPending ? 'Waiting for ESP32...' : 'Synchronized',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: desiredState,
                  activeColor: const Color(0xFF2DD4BF),
                  inactiveThumbColor: const Color(0xFF64748B),
                  inactiveTrackColor: const Color(0xFF1E293B),
                  onChanged: (val) => _toggleRelay(relayNum, desiredState),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}