import 'package:flutter/material.dart';
import '../../ui/mtds/mtds_scaffold.dart';
import '../../a11y/a11y.dart';

/// Calm Breath tool - 60 second breathing exercise
class CalmBreathScreen extends StatefulWidget {
  const CalmBreathScreen({super.key});

  @override
  State<CalmBreathScreen> createState() => _CalmBreathScreenState();
}

class _CalmBreathScreenState extends State<CalmBreathScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnimation;
  bool _isActive = false;
  int _secondsRemaining = 60;
  String _currentPhase = 'Tap to start';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8), // 4s in, 4s out
      vsync: this,
    );
    
    _breathAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _currentPhase = 'Breathe out...');
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isActive) {
          setState(() => _currentPhase = 'Breathe in...');
          _controller.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _currentPhase = 'Breathe in...';
    });
    
    _controller.forward();
    _startTimer();
  }

  void _stopBreathing() {
    setState(() {
      _isActive = false;
      _currentPhase = 'Great job!';
      _secondsRemaining = 60;
    });
    
    _controller.stop();
    _controller.reset();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isActive && _secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining == 0) {
          _stopBreathing();
        }
        return _secondsRemaining > 0;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = A11y.getClampedTextScale(context);
    
    return MtdsScaffold(
      appBar: AppBar(
        title: Text(
          'Calm Breath',
          style: TextStyle(
            fontSize: (20 * textScaler).toDouble(),
            color: const Color(0xFFF2F5F7),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF2F5F7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentPhase,
              style: TextStyle(
                color: const Color(0xFFF2F5F7),
                fontSize: (24 * textScaler).toDouble(),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.8),
                          const Color(0xFF6366F1).withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: _isActive ? _stopBreathing : _startBreathing,
                        child: Center(
                          child: Icon(
                            _isActive ? Icons.pause : Icons.play_arrow,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            Text(
              _isActive ? '${_secondsRemaining}s remaining' : '1 minute exercise',
              style: TextStyle(
                color: const Color(0xFFC7D1DD),
                fontSize: (18 * textScaler).toDouble(),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (!_isActive) ...[
              Text(
                'A simple breathing technique to calm your nervous system in just one minute.',
                style: TextStyle(
                  color: const Color(0xFFC7D1DD),
                  fontSize: (16 * textScaler).toDouble(),
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Follow the circle: inhale as it grows, exhale as it shrinks',
                style: TextStyle(
                  color: const Color(0xFFC7D1DD),
                  fontSize: (16 * textScaler).toDouble(),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}