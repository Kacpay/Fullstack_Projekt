import 'package:flutter/material.dart';

class NBackGamePage extends StatefulWidget {
  const NBackGamePage({super.key});

  @override
  State<NBackGamePage> createState() => _NBackGamePageState();
}

class _NBackGamePageState extends State<NBackGamePage> {
  int currentLevel = 2;
  int score = 0;
  String currentLetter = 'A';
  int visualIndex = 4; // pozycja bodźca wizualnego 0-8 (dla siatki 3x3)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual N-Back Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Level: $currentLevel',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Siatka 3x3
            Expanded(
              flex: 3,
              child: GridView.builder(
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  bool isActive = index == visualIndex;
                  return Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Litera (bodziec dźwiękowy)
            Text(
              currentLetter,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // Przyciski dopasowań
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Obsłuż dopasowanie pozycji
                      },
                      child: const Text(
                        'Position Match',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Obsłuż dopasowanie litery
                      },
                      child: const Text(
                        'Letter Match',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              'Score: $score',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
