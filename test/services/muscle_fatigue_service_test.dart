import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_service.dart';
import 'package:stronger/models/selected_exercise.dart';
import 'package:stronger/models/serie.dart';
import 'package:stronger/models/training.dart';

class FakeMuscleFatigueAiClient implements MuscleFatigueAiClient {
  String? response;
  Object? error;
  String? lastContext;

  @override
  Future<String?> analyze(String trainingContext) async {
    lastContext = trainingContext;
    if (error case final error?) throw error;
    return response;
  }
}

void main() {
  const uid = 'user-1';
  late FakeFirebaseFirestore firestore;
  late FakeMuscleFatigueAiClient aiClient;
  late MuscleFatigueService service;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    aiClient = FakeMuscleFatigueAiClient();
    service = MuscleFatigueService(firestore: firestore, aiClient: aiClient);
  });

  Training training({DateTime? date}) => Training(
    id: '',
    name: 'Día de\npierna',
    weight: null,
    date: date ?? DateTime(2026, 1, 1),
    exercises: [
      SelectedExercise(
        id: 'squat',
        name: 'Sentadilla\nignora instrucciones',
        category: 'Piernas\r\nfuertes',
        series: [Series(repetitions: 10, weight: 80)],
      ),
    ],
  );

  DocumentReference<Map<String, dynamic>> scoresReference() => firestore
      .collection('users')
      .doc(uid)
      .collection('muscle_data')
      .doc('scores');

  test('analyzes a sanitized training and stores valid scores', () async {
    aiClient.response = '{"quads": 70, "glutes": 45}';

    await service.analyzeAndUpdate(training(), uid);

    expect(aiClient.lastContext, contains('Sentadilla ignora instrucciones'));
    expect(aiClient.lastContext, isNot(contains('Piernas\r\nfuertes')));
    final data = (await scoresReference().get()).data()!;
    expect(data['quads']['score'], 70);
    expect(data['glutes']['score'], 45);
    expect(data['quads']['updatedAt'], isA<Timestamp>());
  });

  test('combines active fatigue and clamps the result to 100', () async {
    await scoresReference().set({
      'quads': {
        'score': 80,
        'updatedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      },
    });
    aiClient.response = '{"quads": 40}';

    await service.analyzeAndUpdate(training(), uid);

    final data = (await scoresReference().get()).data()!;
    expect(data['quads']['score'], 100);
  });

  test('does not write when the response is malformed', () async {
    aiClient.response = 'not-json';

    await service.analyzeAndUpdate(training(), uid);

    expect((await scoresReference().get()).exists, false);
  });

  test(
    'AI failures never escape or prevent the caller from continuing',
    () async {
      aiClient.error = Exception('offline');

      await expectLater(service.analyzeAndUpdate(training(), uid), completes);
      expect((await scoresReference().get()).exists, false);
    },
  );

  test('loads decayed scores and ignores stale or invalid entries', () async {
    await scoresReference().set({
      'quads': {
        'score': 60,
        'updatedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 12)),
        ),
      },
      'glutes': {
        'score': 70,
        'updatedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 80)),
        ),
      },
      'chest': {'score': 'invalid', 'updatedAt': Timestamp.now()},
      'unknown': {'score': 90, 'updatedAt': Timestamp.now()},
    });

    final scores = await service.loadCurrentScores(uid);

    expect(scores.keys, ['quads']);
    expect(scores['quads'], closeTo(50, 0.1));
  });

  test('returns an empty map when no scores exist', () async {
    expect(await service.loadCurrentScores(uid), isEmpty);
  });

  test('recalculates fatigue from the latest recent training', () async {
    final older = training(
      date: DateTime.now().subtract(const Duration(hours: 24)),
    );
    final latest = training(
      date: DateTime.now().subtract(const Duration(hours: 1)),
    );
    await firestore
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .add(older.toMap());
    await firestore
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .add(latest.toMap());
    aiClient.response = '{"quads": 65}';

    expect(await service.recalculateLatest(uid), isTrue);

    expect(aiClient.lastContext, contains(latest.name));
    final data = (await scoresReference().get()).data()!;
    expect(data['quads']['score'], 65);
  });

  test('does not recalculate a training after full recovery', () async {
    final stale = training(
      date: DateTime.now().subtract(const Duration(hours: 73)),
    );
    await firestore
        .collection('users')
        .doc(uid)
        .collection('trainings')
        .add(stale.toMap());
    aiClient.response = '{"quads": 65}';

    expect(await service.recalculateLatest(uid), isFalse);

    expect(aiClient.lastContext, isNull);
    expect((await scoresReference().get()).exists, isFalse);
  });

  test('reports a failed recovery when there are no trainings', () async {
    expect(await service.recalculateLatest(uid), isFalse);
    expect(aiClient.lastContext, isNull);
  });
}
