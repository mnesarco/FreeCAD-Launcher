// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freecad_launcher/core/errors.dart';
import 'package:freecad_launcher/core/result.dart';
import 'package:freecad_launcher/domain/bundles/bundle_planner.dart';
import 'package:freecad_launcher/state/bundle_apply_controller.dart';

class _Call {
  const _Call(this.kind, this.addonId, this.branchRef, {this.installRequirements});

  final String kind;
  final String addonId;
  final String branchRef;
  final bool? installRequirements;
}

void main() {
  late List<_Call> calls;
  late BundleApplyController controller;

  BundleApplyPlanItem item(
    String addonId,
    BundleItemAction action, {
    String? branchRef = 'master',
    bool hasRequirements = false,
  }) {
    return BundleApplyPlanItem(
      addonId: addonId,
      action: action,
      branchRef: branchRef,
      addonName: addonId,
      hasRequirements: hasRequirements,
    );
  }

  setUp(() {
    calls = [];
    controller = BundleApplyController(
      install:
          ({
            required String addonId,
            required String branchRef,
            required String profileId,
            required bool installRequirements,
          }) async {
            calls.add(
              _Call(
                'install',
                addonId,
                branchRef,
                installRequirements: installRequirements,
              ),
            );
            return const Ok(null);
          },
      update:
          ({
            required String addonId,
            required String branchRef,
            required String profileId,
          }) async {
            calls.add(_Call('update', addonId, branchRef));
            return const Ok(null);
          },
    );
  });

  test('executes installs and updates in order and skips the rest', () async {
    final summary = await controller.apply(
      profileId: 'profile-1',
      items: [
        item('A2plus', BundleItemAction.install),
        item('MacroTool', BundleItemAction.skip),
        item('Ghost', BundleItemAction.unavailable, branchRef: null),
        item('WithReqs', BundleItemAction.install, hasRequirements: true),
        item('Old', BundleItemAction.update),
      ],
      installRequirements: true,
    );

    expect(calls.map((call) => '${call.kind}:${call.addonId}'), [
      'install:A2plus',
      'install:WithReqs',
      'update:Old',
    ]);
    expect(calls.first.installRequirements, isFalse);
    expect(calls[1].installRequirements, isTrue);
    expect(summary.count(BundleApplyItemStatus.installed), 2);
    expect(summary.count(BundleApplyItemStatus.updated), 1);
    expect(summary.count(BundleApplyItemStatus.skipped), 2);
    expect(summary.count(BundleApplyItemStatus.failed), 0);
    expect(controller.applying.value, isFalse);
    expect(controller.completed.value, 5);
    expect(controller.total.value, 5);
  });

  test('does not install requirements when not requested', () async {
    await controller.apply(
      profileId: 'profile-1',
      items: [item('WithReqs', BundleItemAction.install, hasRequirements: true)],
    );

    expect(calls.single.installRequirements, isFalse);
  });

  test('collects failures and keeps going', () async {
    controller = BundleApplyController(
      install:
          ({
            required String addonId,
            required String branchRef,
            required String profileId,
            required bool installRequirements,
          }) async {
            calls.add(_Call('install', addonId, branchRef));
            if (addonId == 'Broken') {
              return const Err(AppError(message: 'disk full'));
            }
            return const Ok(null);
          },
      update:
          ({
            required String addonId,
            required String branchRef,
            required String profileId,
          }) async => const Ok(null),
    );

    final summary = await controller.apply(
      profileId: 'profile-1',
      items: [
        item('Broken', BundleItemAction.install),
        item('A2plus', BundleItemAction.install),
      ],
    );

    expect(summary.count(BundleApplyItemStatus.failed), 1);
    expect(summary.failures.single.item.addonId, 'Broken');
    expect(summary.failures.single.error, contains('disk full'));
    expect(summary.count(BundleApplyItemStatus.installed), 1);
    expect(controller.completed.value, 2);
  });

  test('reports progress while running', () async {
    final gate = Completer<void>();
    controller = BundleApplyController(
      install:
          ({
            required String addonId,
            required String branchRef,
            required String profileId,
            required bool installRequirements,
          }) async {
            await gate.future;
            return const Ok(null);
          },
      update:
          ({
            required String addonId,
            required String branchRef,
            required String profileId,
          }) async => const Ok(null),
    );

    final run = controller.apply(
      profileId: 'profile-1',
      items: [item('A2plus', BundleItemAction.install)],
    );
    await pumpEventQueue();

    expect(controller.applying.value, isTrue);
    expect(controller.currentAddonId.value, 'A2plus');
    expect(controller.total.value, 1);
    expect(controller.completed.value, 0);

    gate.complete();
    final summary = await run;

    expect(controller.applying.value, isFalse);
    expect(controller.currentAddonId.value, isNull);
    expect(controller.completed.value, 1);
    expect(summary.count(BundleApplyItemStatus.installed), 1);
  });
}
