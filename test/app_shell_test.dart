import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/app.dart';
import 'package:freecad_launcher/data/catalog/releases_catalog.dart' show CatalogFreshness;
import 'package:freecad_launcher/data/catalog/addon_catalog.dart';
import 'package:freecad_launcher/data/database.dart';
import 'package:freecad_launcher/platform/downloader.dart';
import 'package:freecad_launcher/platform/paths.dart';
import 'package:freecad_launcher/state/addons_controller.dart';
import 'package:freecad_launcher/state/app_services.dart';

import 'helpers/fake_addon_catalog.dart';
import 'helpers/fake_download.dart';

void main() {
  late AppDatabase database;
  late AppServices services;

  setUp(() {
    database = AppDatabase.inMemory();
    services = AppServices(
      paths: AppPaths(dataRoot: '/tmp/freecad_launcher_test'),
      database: database,
      addonsController: AddonsController(
        database: database,
        catalog: (FakeAddonCatalog(
          downloader: Downloader(
            source: FakeDownloadSource(),
            cacheDirectory: '/tmp/freecad_launcher_test/addons',
          ),
          dao: database.catalogCacheDao,
          cacheDirectory: '/tmp/freecad_launcher_test/addons',
        )..result = const AddonCatalogResult(
          addons: [],
          freshness: CatalogFreshness.fresh,
        )),
      ),
    );
  });

  tearDown(() => services.close());

  testWidgets('shell shows all navigation destinations', (tester) async {
    await tester.pumpWidget(FreeCadLauncherApp(services: services));
    await tester.pumpAndSettle();

    for (final label in ['Home', 'Profiles', 'Versions', 'Addons', 'Macros', 'Settings']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('navigating shows each section empty state', (tester) async {
    await tester.pumpWidget(FreeCadLauncherApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FreeCAD Launcher'), findsOneWidget);

    await tester.tap(find.text('Profiles'));
    await tester.pumpAndSettle();
    expect(find.text('No profiles yet'), findsOneWidget);

    await tester.tap(find.text('Versions'));
    await tester.pumpAndSettle();
    expect(find.text('No FreeCAD versions installed'), findsOneWidget);

    await tester.tap(find.text('Addons'));
    await tester.pumpAndSettle();
    expect(find.text('Catalog is empty'), findsOneWidget);

    await tester.tap(find.text('Macros'));
    await tester.pumpAndSettle();
    expect(find.text('No macros'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Data directory'), findsOneWidget);
    expect(find.text('/tmp/freecad_launcher_test'), findsOneWidget);
  });
}
