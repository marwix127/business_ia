import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stronger/UI/pages/body_page.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';
import 'package:stronger/infrastructure/services/firebase/corporal_service.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_service.dart';

class MockBodyAuthService extends Mock implements AuthService {}

class MockBodyUser extends Mock implements User {}

class MockBodyFatigueService extends Mock implements MuscleFatigueService {}

class MockBodyMeasurementService extends Mock
    implements BodyMeasurementService {}

void main() {
  const uid = 'user-1';
  late FakeFirebaseFirestore firestore;
  late BodyMeasurementService measurementService;
  late MockBodyFatigueService fatigueService;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    final authService = MockBodyAuthService();
    final user = MockBodyUser();
    when(() => authService.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn(uid);
    measurementService = BodyMeasurementService(
      firestore: firestore,
      authService: authService,
    );
    fatigueService = MockBodyFatigueService();
    when(
      () => fatigueService.loadCurrentScores(uid),
    ).thenAnswer((_) async => {});
    when(
      () => fatigueService.recalculateLatest(uid),
    ).thenAnswer((_) async => false);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    BodyMeasurementService? measurements,
    MuscleFatigueService? fatigue,
    String? Function()? uidGetter,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BodyPage(
          measurementService: measurements ?? measurementService,
          fatigueService: fatigue ?? fatigueService,
          getUid: uidGetter ?? () => uid,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('validates required and malformed measurements', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    expect(find.text('Requerido'), findsOneWidget);

    await tester.enterText(field('Peso (kg)'), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();
    expect(find.text('Número no válido'), findsOneWidget);
  });

  testWidgets('accepts decimal commas and stores a body measurement', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(field('Peso (kg)'), '80,5');
    await tester.enterText(field('Altura (cm)'), '180');
    await tester.enterText(field('% Grasa'), '20');
    await tester.enterText(field('Músculo (kg)'), '60');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('body_measurements')
        .get();
    expect(snapshot.docs, hasLength(1));
    expect(snapshot.docs.single['weight'], 80.5);
    expect(snapshot.docs.single['height'], 180);
    expect(snapshot.docs.single['fat_percentage'], 20);
    expect(snapshot.docs.single['muscle_mass'], 60);
    expect(find.text('Medición guardada correctamente'), findsOneWidget);
  });

  testWidgets('validates positive values and percentage upper limit', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(field('Peso (kg)'), '0');
    await tester.enterText(field('% Grasa'), '101');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pump();

    expect(find.textContaining('Debe ser mayor que 0'), findsOneWidget);
    expect(find.textContaining('Debe ser como máximo 100'), findsOneWidget);
  });

  testWidgets('prefills height from the latest measurement', (tester) async {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('body_measurements')
        .add({'height': 181.5, 'weight': 80, 'date': Timestamp.now()});

    await pumpPage(tester);

    final heightField = tester.widget<TextFormField>(field('Altura (cm)'));
    expect(heightField.controller?.text, '181.5');
  });

  testWidgets('reports an error when saving fails', (tester) async {
    final failingService = MockBodyMeasurementService();
    when(
      () => failingService.getLastMeasurement(),
    ).thenAnswer((_) async => null);
    when(
      () => failingService.getMeasurements(),
    ).thenAnswer((_) => const Stream<QuerySnapshot>.empty());
    when(
      () => failingService.addMeasurement(any()),
    ).thenThrow(Exception('controlled failure'));

    await pumpPage(tester, measurements: failingService);
    await tester.enterText(field('Peso (kg)'), '80');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error al guardar:'), findsOneWidget);
  });

  testWidgets('edits, cancels deletion and deletes a history record', (
    tester,
  ) async {
    final reference = await firestore
        .collection('users')
        .doc(uid)
        .collection('body_measurements')
        .add({
          'weight': 80.0,
          'height': 180.0,
          'fat_percentage': 20.0,
          'muscle_mass': 60.0,
          'date': Timestamp.fromDate(DateTime(2026, 2, 3, 10, 30)),
        });
    await pumpPage(tester);

    expect(find.text('03/02/2026 10:30'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.edit),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final editWeight = find.descendant(
      of: dialog,
      matching: find.widgetWithText(TextFormField, 'Peso (kg)'),
    );
    await tester.enterText(editWeight, '82,5');
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, 'Guardar'),
      ),
    );
    await tester.pumpAndSettle();

    expect((await reference.get())['weight'], 82.5);

    await tester.ensureVisible(find.byIcon(Icons.delete));
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    expect((await reference.get()).exists, isTrue);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
    await tester.pumpAndSettle();

    expect((await reference.get()).exists, isFalse);
    expect(find.textContaining('eliminada'), findsOneWidget);
  });

  testWidgets('shows a clear state when measurement history fails', (
    tester,
  ) async {
    final failingService = MockBodyMeasurementService();
    when(
      () => failingService.getLastMeasurement(),
    ).thenAnswer((_) async => null);
    when(() => failingService.getMeasurements()).thenAnswer(
      (_) => Stream<QuerySnapshot>.error(Exception('controlled failure')),
    );

    await pumpPage(tester, measurements: failingService);

    expect(find.text('Error al cargar datos'), findsOneWidget);
  });

  testWidgets('loads fatigue colors, changes view and refreshes scores', (
    tester,
  ) async {
    when(() => fatigueService.loadCurrentScores(uid)).thenAnswer(
      (_) async => {
        'chest': 10,
        'frontShoulders': 30,
        'biceps': 60,
        'calves': 90,
        'unknown': 20,
      },
    );
    await pumpPage(tester);

    await tester.tap(find.text('Fatiga'));
    await tester.pumpAndSettle();

    expect(find.text('Descansado'), findsOneWidget);
    expect(find.text('Recuperando'), findsOneWidget);
    expect(find.text('Cansado'), findsOneWidget);
    expect(find.text('Fatigado'), findsOneWidget);
    expect(find.text('Sin datos'), findsOneWidget);
    verify(() => fatigueService.loadCurrentScores(uid)).called(1);

    await tester.tap(find.text('Dorsal'));
    await tester.pump();
    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();

    verify(() => fatigueService.loadCurrentScores(uid)).called(1);
  });

  testWidgets('does not request fatigue data without an authenticated user', (
    tester,
  ) async {
    await pumpPage(tester, uidGetter: () => null);

    await tester.tap(find.text('Fatiga'));
    await tester.pumpAndSettle();

    verifyNever(() => fatigueService.loadCurrentScores(any()));
    expect(find.byTooltip('Actualizar'), findsOneWidget);
  });

  testWidgets('recovers missing fatigue from the latest training', (
    tester,
  ) async {
    var loadCount = 0;
    when(() => fatigueService.loadCurrentScores(uid)).thenAnswer((_) async {
      loadCount++;
      return loadCount == 1 ? {} : {'lats': 60};
    });
    when(
      () => fatigueService.recalculateLatest(uid),
    ).thenAnswer((_) async => true);

    await pumpPage(tester);
    await tester.tap(find.text('Fatiga'));
    await tester.pumpAndSettle();

    verify(() => fatigueService.recalculateLatest(uid)).called(1);
    verify(() => fatigueService.loadCurrentScores(uid)).called(2);
    expect(find.byTooltip('Actualizar'), findsOneWidget);
  });
}
