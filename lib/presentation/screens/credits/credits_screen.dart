import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: wider blend between gold -> deep orange (no whites)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1.0, -0.6),
                  end: const Alignment(1.0, 0.6),
                  colors: [
                    AppColors.gold,
                    Color.lerp(AppColors.gold, AppColors.primary, 0.45)!,
                    AppColors.primary,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Layer 2: warm radial wash (yellow -> transparent of same hue)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.3),
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withOpacity(0.14),
                    AppColors.gold.withOpacity(0.00),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Layer 3: deeper orange radial shadow to add depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, 0.45),
                  radius: 0.9,
                  colors: [
                    AppColors.primary.withOpacity(0.14),
                    AppColors.primary.withOpacity(0.00),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Foreground content
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Image.asset(
                          'assets/icons/icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 72, color: Colors.white),
                        ),
                      ),
                      const Text('Тензин', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      const Text('Гансаг-ги дагмэд', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        // translucent/iOS-like card with blur
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle('Зохион бүтээгч:'),
                                  const SizedBox(height: 12),
                                  _lineItem('Програм зохиогч, Ph.D Доктор - Г.Уртнасан'),
                                  const SizedBox(height: 8),
                                  _lineItem('Програм зохиогч, хөгжүүлэгч - Б.Эрдэнээ'),
                                  const SizedBox(height: 18),

                                  _sectionTitle('Мэдээллийн эх сурвалж:'),
                                  const SizedBox(height: 12),
                                  _sectionTitle('Гансаг-ги дагмэд'),
                                  const SizedBox(height: 10),
                                  _lineItem('Зохиогч: Д.Жавзандорж'),
                                  const SizedBox(height: 6),
                                  _lineItem('Эмхэтгэсэн: Я.Нарангэрэл'),
                                  const SizedBox(height: 6),
                                  _lineItem('Редактор: Ж.Даваадорж, Э.Төрболд'),
                                  const SizedBox(height: 18),

                                  Center(
                                    child: Column(
                                      children: const [
                                        SizedBox(height: 6),
                                        Icon(Icons.favorite, color: AppColors.heartRed, size: 26),
                                        SizedBox(height: 8),
                                        Text('© 2026', style: TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
    );
  }

  Widget _lineItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2.0, right: 8),
          child: Icon(Icons.circle, size: 8, color: AppColors.primary),
        ),
        Expanded(
          child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
        ),
      ],
    );
  }
}
 
