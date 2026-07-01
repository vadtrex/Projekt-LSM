import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'src/app.dart';
import 'src/features/chat/data/models/chat_hive_model.dart';
import 'src/features/chat/data/models/message_hive_model.dart';
import 'src/features/chat/data/datasources/chat_local_data_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();

  await Hive.initFlutter();

  // Rejestracja adapterów dla modeli
  Hive.registerAdapter(ChatHiveModelAdapter());
  Hive.registerAdapter(MessageHiveModelAdapter());

  // Otwarcie boxów na starcie aplikacji
  await Hive.openBox<ChatHiveModel>(ChatLocalDataSourceImpl.chatBoxName);
  await Hive.openBox<MessageHiveModel>(ChatLocalDataSourceImpl.messageBoxName);

  runApp(const ProviderScope(child: LmChatApp()));
}
