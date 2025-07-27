import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoir/widgets/primary_button.dart';
import 'package:pinput/pinput.dart';
import '../widgets/app_logo_header.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  late Timer _timer;
  int _start = 120;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pinController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void startTimer() {
    _start = 120;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (Timer timer) {
        if (_start == 0) {
          if (mounted) {
            setState(() {
              timer.cancel();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _start--;
            });
          }
        }
      },
    );
  }

  String get timerString {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x4D999999),
            spreadRadius: 0.5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              AppLogoHeader(
                size: 30,
                logoAsset: 'assets/Logo.png',
                title: 'OTP verification',
                textColor: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the OTP sent to +84 123456789',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),
              Focus(
                focusNode: _otpFocusNode,
                onKeyEvent: (node, event) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                      event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Pinput(
                  controller: _pinController,
                  length: 4,
                  separatorBuilder: (index) => const SizedBox(width: 20),
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: Color(0xFFE2D1F9), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x4D999999),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  onCompleted: (pin) => print('Completed: $pin'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                timerString,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't receive code ? ",
                    style: TextStyle(color: colorScheme.primary, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _start == 0 ? startTimer : null,
                    child: Text(
                      'Re-send',
                      style: TextStyle(
                        color: _start == 0 ? colorScheme.primary : Colors.grey,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Submit',
                background: colorScheme.primary,
                textSize: 18,
                onPress: () {
                  print('Submitted PIN: ${_pinController.text}');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}