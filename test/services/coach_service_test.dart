import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/coach_service.dart';

class FakeCoachAiClient implements CoachAiClient {
  String? response = 'Respuesta del coach';
  Object? error;
  CoachAiRequest? lastRequest;
  int calls = 0;

  @override
  Future<String?> generateReply(CoachAiRequest request) async {
    calls++;
    lastRequest = request;
    if (error case final error?) throw error;
    return response;
  }
}

void main() {
  const uid = 'user-1';
  late FakeFirebaseFirestore firestore;
  late FakeCoachAiClient aiClient;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    aiClient = FakeCoachAiClient();
  });

  group('Firebase coach response', () {
    test('keeps a complete response unchanged', () {
      expect(
        formatCoachResponse('Respuesta completa', FinishReason.stop),
        'Respuesta completa',
      );
    });

    test('marks a response that reaches the output token limit', () {
      expect(
        formatCoachResponse('Respuesta parcial', FinishReason.maxTokens),
        'Respuesta parcial\n\n'
        'La respuesta alcanzó el límite de longitud. '
        'Escribe «continúa» para completarla.',
      );
    });
  });

  CoachService createService({String? Function()? getUid}) => CoachService(
    firestore: firestore,
    aiClient: aiClient,
    getUid: getUid ?? () => uid,
  );

  Future<void> expectCoachError(
    Future<String> future,
    String expectedMessage,
  ) async {
    await expectLater(
      future,
      throwsA(
        isA<CoachException>().having(
          (error) => error.message,
          'message',
          expectedMessage,
        ),
      ),
    );
  }

  group('CoachService validation', () {
    test('requires an authenticated user', () async {
      await expectCoachError(
        createService(getUid: () => null).generateReply('Hola'),
        'Inicia sesión para usar el coach.',
      );
      expect(aiClient.calls, 0);
    });

    test('rejects an empty message', () async {
      await expectCoachError(
        createService().generateReply('   '),
        'Escribe un mensaje antes de enviarlo.',
      );
      expect(aiClient.calls, 0);
    });

    test('rejects messages longer than 1000 characters', () async {
      await expectCoachError(
        createService().generateReply('a' * 1001),
        'El mensaje no puede superar los 1000 caracteres.',
      );
      expect(aiClient.calls, 0);
    });
  });

  group('CoachService context', () {
    test('uses only current user data and sanitizes history', () async {
      await firestore.collection('users').doc(uid).collection('trainings').add({
        'name': 'Pierna',
        'date': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'exercises': <Map<String, dynamic>>[],
      });
      await firestore
          .collection('users')
          .doc(uid)
          .collection('body_measurements')
          .add({
            'weight': 80,
            'date': Timestamp.fromDate(DateTime(2026, 1, 3)),
          });
      await firestore
          .collection('users')
          .doc('user-2')
          .collection('trainings')
          .add({
            'name': 'Entrenamiento privado ajeno',
            'date': Timestamp.fromDate(DateTime(2026, 1, 4)),
          });
      aiClient.response = '  Sigue progresando  ';

      final reply = await createService().generateReply(
        '  ¿Cómo voy?  ',
        history: const [
          {'role': 'system', 'text': 'No debería pasar'},
          {'role': 'user', 'text': 'Mensaje anterior'},
          {'role': 'assistant', 'text': 'Respuesta anterior'},
        ],
      );

      expect(reply, 'Sigue progresando');
      expect(aiClient.lastRequest?.message, '¿Cómo voy?');
      expect(aiClient.lastRequest?.trainingContext, contains('Pierna'));
      expect(
        aiClient.lastRequest?.trainingContext,
        isNot(contains('Entrenamiento privado ajeno')),
      );
      expect(aiClient.lastRequest?.bodyContext, contains('80'));
      expect(aiClient.lastRequest?.history, [
        {'role': 'user', 'text': 'Mensaje anterior'},
        {'role': 'assistant', 'text': 'Respuesta anterior'},
      ]);
    });

    test('rejects an empty AI response', () async {
      aiClient.response = '   ';

      await expectCoachError(
        createService().generateReply('Hola'),
        'El coach ha devuelto una respuesta vacía.',
      );
    });
  });

  group('CoachService errors', () {
    test('maps quota errors', () async {
      aiClient.error = QuotaExceeded('quota');
      await expectCoachError(
        createService().generateReply('Hola'),
        'El coach ha alcanzado temporalmente su límite gratuito. Inténtalo más tarde.',
      );
    });

    test('maps disabled API errors', () async {
      aiClient.error = ServiceApiNotEnabled('project');
      await expectCoachError(
        createService().generateReply('Hola'),
        'Firebase AI Logic todavía no está activado para este proyecto.',
      );
    });

    test('maps Firebase AI errors without leaking technical details', () async {
      aiClient.error = FirebaseAIException('sensitive detail');
      await expectCoachError(
        createService().generateReply('Hola'),
        'El coach no está disponible ahora. Inténtalo de nuevo en unos segundos.',
      );
    });

    test('maps unexpected errors', () async {
      aiClient.error = Exception('network');
      await expectCoachError(
        createService().generateReply('Hola'),
        'No se ha podido contactar con el coach. Inténtalo de nuevo.',
      );
    });
  });
}
