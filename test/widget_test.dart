import 'package:flutter_test/flutter_test.dart';

import 'package:baja_videos/main.dart';

void main() {
  testWidgets('Shema carga la navegacion principal', (tester) async {
    await tester.pumpWidget(const ShemaApp());

    expect(find.text('YouTube'), findsWidgets);
    expect(find.text('Mi musica'), findsWidgets);
    expect(find.text('Mis videos'), findsWidgets);
  });
}
