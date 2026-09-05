import 'app/app.dart';

// Keep the package entry point backwards-compatible for tests and integrations
// that historically imported the application types from `main.dart`.
export 'app/app.dart';

Future<void> main() => bootstrap();
