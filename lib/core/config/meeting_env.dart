import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pi_dev_agentia/core/config/env_loader_stub.dart'
    if (dart.library.io) 'package:pi_dev_agentia/core/config/env_loader_io.dart'
    as env_loader;

/// Returns value for [key] from .env for Meeting Hub (Zegocloud, ROCCO). Use after loadEnv() in main.
String getMeetingEnv(String key) {
  final fromDotenv = dotenv.isInitialized ? (dotenv.env[key] ?? '').trim() : '';
  if (fromDotenv.isNotEmpty) return fromDotenv;
  return env_loader.getEnv(key);
}
