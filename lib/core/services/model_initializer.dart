import 'package:flutter/material.dart';
import '../../ml/expiry_detector_service.dart';

/// Service to initialize ML model at app startup
class ModelInitializer {
  static final ModelInitializer _instance = ModelInitializer._internal();
  factory ModelInitializer() => _instance;
  ModelInitializer._internal();

  bool _initialized = false;
  bool _initializing = false;

  /// Initialize ML model in background
  Future<void> initialize({Function(String)? onStatus}) async {
    if (_initialized) {
      print('✓ Model already initialized');
      return;
    }

    if (_initializing) {
      print('⏳ Model initialization in progress');
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      return;
    }

    _initializing = true;
    onStatus?.call('Loading ML model...');

    try {
      final detectorService = ExpiryDetectorService();
      await detectorService.initialize();
      
      _initialized = true;
      onStatus?.call('Model ready');
      print('✅ ML model initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize model: $e');
      onStatus?.call('Failed to load model');
      _initialized = false;
    } finally {
      _initializing = false;
    }
  }

  bool get isInitialized => _initialized;
  bool get isInitializing => _initializing;
}

/// Splash screen with ML model initialization
class MLInitSplashScreen extends StatefulWidget {
  final Widget child;
  final bool initializeModel;

  const MLInitSplashScreen({
    Key? key,
    required this.child,
    this.initializeModel = true,
  }) : super(key: key);

  @override
  State<MLInitSplashScreen> createState() => _MLInitSplashScreenState();
}

class _MLInitSplashScreenState extends State<MLInitSplashScreen> {
  bool _ready = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    if (widget.initializeModel) {
      _initializeApp();
    } else {
      setState(() => _ready = true);
    }
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _status = 'Loading ML model...');
      
      await ModelInitializer().initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() => _status = status);
          }
        },
      );

      // Small delay to show success message
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (e) {
      // Even if init fails, show the app
      if (mounted) {
        setState(() => _ready = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Color(0xFF00FF7F),
              ),
              const SizedBox(height: 24),
              const Text(
                'ZeroSpill',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF7F)),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
