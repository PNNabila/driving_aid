import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String filter = "ALL";
  final List<Map<String, dynamic>> logs = [
    {
      "type": "SIREN",
      "direction": "CENTER",
      "time": "17.30, 10/12/2025",
      "duration": "1.49 s",
      "isSiren": true
    },
    {
      "type": "HORN",
      "direction": "LEFT",
      "time": "17.38, 10/12/2025",
      "duration": "0.50 s",
      "isSiren": false
    },
    {
      "type": "HORN",
      "direction": "RIGHT",
      "time": "17.50, 10/12/2025",
      "duration": "1.00 s",
      "isSiren": false
    },
    {
      "type": "SIREN",
      "direction": "CENTER",
      "time": "18.00, 10/12/2025",
      "duration": "2.00 s",
      "isSiren": true
    },
  ];

  // --- FUNGSI BARU: Otomatis memunculkan logo berdasarkan arah ---
  IconData _getDirectionIcon(String direction) {
    if (direction == "LEFT") return Icons.arrow_back;
    if (direction == "RIGHT") return Icons.arrow_forward;
    return Icons.adjust; // Icon bulat target untuk CENTER
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = filter == "ALL"
        ? logs
        : logs.where((l) => l['type'] == filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("HISTORY"),
        automaticallyImplyLeading: false, // Menghilangkan panah kembali
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _filterBtn("ALL"),
              _filterBtn("HORN"),
              _filterBtn("SIREN")
            ],
          ),
          const Divider(thickness: 2),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final log = filteredList[index];
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading:
                        const Icon(Icons.notifications_none_rounded, size: 35),
                    title: Row(
                      children: [
                        Text(log['type'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: log['isSiren']
                                    ? Colors.red
                                    : Colors.blue[900])),
                        const SizedBox(width: 10),
                        Text(log['time'], style: const TextStyle(fontSize: 12)),
                      ],
                    ),

                    // --- PERUBAHAN DI SINI: Lambang Siren/Horn + Lambang Arah ---
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          // 1. Logo Tipe (Siren merah / Horn kuning)
                          Icon(
                            log['isSiren'] ? Icons.warning : Icons.campaign,
                            size: 16,
                            color: log['isSiren']
                                ? Colors.red
                                : Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),

                          // 2. Logo Arah (Kiri / Kanan / Tengah)
                          Icon(
                            _getDirectionIcon(log['direction']),
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),

                          // 3. Teks Arah
                          Text(
                            log['direction'],
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),

                    trailing: IntrinsicWidth(
                        child: Row(children: [
                      const VerticalDivider(
                          color: Colors.black,
                          thickness: 1,
                          indent: 10,
                          endIndent: 10),
                      Text(log['duration'],
                          style: const TextStyle(fontWeight: FontWeight.bold))
                    ])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBtn(String label) {
    bool isSelected = filter == label;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? const Color(0xFF2C4A73) : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black),
      onPressed: () => setState(() => filter = label),
      child: Text(label),
    );
  }
}
