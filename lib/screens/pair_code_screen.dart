import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/supabase_client.dart';
import '../core/storage_service.dart';
import 'home_screen.dart';

class PairCodeScreen extends StatefulWidget {
  final String userName;

  const PairCodeScreen({super.key, required this.userName});

  @override
  State<PairCodeScreen> createState() => _PairCodeScreenState();
}

class _PairCodeScreenState extends State<PairCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  String _generatePairCode() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _createPair() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _generatePairCode();
      final now = DateTime.now().toIso8601String();

      final res = await supabase
          .from('pairs')
          .insert({
            'invite_code': code,
            'partner1_name': widget.userName,
            'partner1_mood': '✨',
            'partner1_activity': 'Отдыхаю',
            'partner1_updated_at': now,
            'partner2_name': 'Половинка',
            'partner2_mood': '✨',
            'partner2_activity': 'Отдыхает',
            'partner2_updated_at': now,
          })
          .select()
          .single();

      final pairId = res['id'].toString();

      await StorageService.savePairData(
        pairId: pairId,
        userName: widget.userName,
        partnerName: 'Половинка',
        isPartner1: true,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(pairId: pairId, userName: widget.userName),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка создания: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinPair() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Введите код пары');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final row = await supabase
          .from('pairs')
          .select()
          .eq('invite_code', code)
          .maybeSingle();

      if (row == null) {
        setState(() => _errorMessage = 'Пара с кодом $code не найдена');
        return;
      }

      final pairId = row['id'].toString();
      final partner1Name = row['partner1_name']?.toString() ?? 'Половинка';

      await supabase
          .from('pairs')
          .update({
            'partner2_name': widget.userName,
            'partner2_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', pairId);

      await StorageService.savePairData(
        pairId: pairId,
        userName: widget.userName,
        partnerName: partner1Name,
        isPartner1: false,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(pairId: pairId, userName: widget.userName),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка подключения: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E1E1E)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Свяжи свою пару',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Создай код для половинки или введи уже готовый',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createPair,
                icon: const Icon(Icons.favorite, color: Colors.white, size: 20),
                label: Text(
                  _isLoading ? 'Секунду...' : 'Я создаю пару',
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D6D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ИЛИ',
                      style: GoogleFonts.rubik(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 28),

              Text(
                'ВВЕДИ КОД',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.rubik(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
                decoration: InputDecoration(
                  hintText: 'НАПРИМЕР: AB12CD',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    letterSpacing: 1,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFF0EBE5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF4D6D),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _joinPair,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Присоединиться к паре',
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
