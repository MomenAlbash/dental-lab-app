import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/assistant/data/models/assistant_models.dart';
import 'package:dental_lab_app/features/branding/data/models/branding_model.dart';
import 'package:dental_lab_app/features/deletion/data/models/deletion_plan_model.dart';
import 'package:dental_lab_app/features/representatives/data/models/representative_agent_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandingModel', () {
    test('reads a valid hex into a colour', () {
      final branding = BrandingModel.fromJson({
        'primaryColorHex': '#D04400',
        'scope': 'admin',
        'backgroundStyle': 'charcoal',
      });

      expect(branding.primaryColor, const Color(0xFFD04400));
      expect(branding.backgroundStyle, BrandingBackground.charcoal);
    });

    test('a malformed hex reads as no colour, not as black', () {
      // A mistyped brand colour should leave the app looking like itself
      // rather than painting every button black.
      for (final bad in ['D04400', '#D044', '#ZZZZZZ', '']) {
        expect(
          BrandingModel(primaryColorHex: bad).primaryColor,
          isNull,
          reason: 'expected "$bad" to be rejected',
        );
      }
    });

    test('an unknown background falls back rather than leaving none', () {
      expect(
        BrandingBackground.fromKey('neon'),
        BrandingBackground.charcoal,
      );
      expect(BrandingControlStyle.fromKey(null), BrandingControlStyle.classic);
    });

    test('a lab with no brand set still has a usable fallback', () {
      expect(BrandingModel.fallback.primaryColor, isNull);
      expect(BrandingModel.fallback.hasLogo, isFalse);
    });
  });

  group('AppTheme.branded', () {
    test('a null brand colour leaves the theme untouched', () {
      final theme = AppTheme.light;
      expect(identical(AppTheme.branded(theme, null), theme), isTrue);
    });

    test('only the accent moves — surfaces stay as designed', () {
      // Letting a brand colour leak into surfaces is how white-labelling
      // turns into an unreadable screen.
      final base = AppTheme.light;
      final branded = AppTheme.branded(base, const Color(0xFF0055FF));

      expect(branded.colorScheme.primary, const Color(0xFF0055FF));
      expect(branded.colorScheme.surface, base.colorScheme.surface);
      expect(branded.scaffoldBackgroundColor, base.scaffoldBackgroundColor);
    });
  });

  group('DeletionPlanModel', () {
    test('keeps hard stops apart from what a user may clear', () {
      // A restoration type on real cases must never get a delete button; a
      // doctor's login user may.
      final plan = DeletionPlanModel.fromJson({
        'canDelete': false,
        'hardStops': ['لهذا الطبيب مرضى مسجّلون'],
        'resolvableSteps': [
          {
            'entityType': 'user',
            'message': 'لهذا الطبيب حساب دخول',
            'items': [
              {'id': 'u1', 'label': 'khaled@lab'},
            ],
          },
        ],
      });

      expect(plan.canDelete, isFalse);
      expect(plan.hardStops, hasLength(1));
      expect(plan.resolvableCount, 1);
      expect(plan.resolvableSteps.single.isResolvable, isTrue);
      // There is something to do, so it is not blocked outright.
      expect(plan.isBlockedOutright, isFalse);
    });

    test('a hard stop with nothing resolvable is blocked outright', () {
      final plan = DeletionPlanModel.fromJson({
        'canDelete': false,
        'hardStops': ['مستخدم في حالات'],
      });

      expect(plan.isBlockedOutright, isTrue);
      expect(plan.resolvableCount, 0);
    });

    test('a step with no items is not offered as resolvable', () {
      final step = DeletionBlockerStepModel.fromJson({
        'entityType': 'user',
        'items': <dynamic>[],
      });

      expect(step.isResolvable, isFalse);
    });

    test('a blocking row falls back to its id when unlabelled', () {
      final item = DeletionBlockerItemModel.fromJson({'id': 'u1'});
      expect(item.displayLabel, 'u1');
    });
  });

  group('RepresentativeAgentModel', () {
    test('an open spell reads as running', () {
      final spell = RepresentativeAgentModel.fromJson({
        'id': 'a1',
        'representativeUserId': 'r1',
        'agentUserId': 'g1',
        'agentName': 'سامر',
        'startDate': '2026-03-01T00:00:00Z',
        'isActive': true,
      });

      expect(spell.isActive, isTrue);
      expect(spell.periodLabel, contains('حتى الآن'));
      expect(spell.agentLabel, 'سامر');
    });
  });

  group('AssistantCapabilityModel', () {
    test('matches on keywords in either language, not just the label', () {
      final capability = AssistantCapabilityModel.fromJson({
        'id': 'late-cases',
        'label': 'Late cases',
        'labelAr': 'الحالات المتأخرة',
        'keywords': ['late', 'متأخر', 'تأخير'],
      });

      expect(capability.matches('متأخر'), isTrue);
      expect(capability.matches('late'), isTrue);
      expect(capability.matches('Late ca'), isTrue);
      expect(capability.matches('فواتير'), isFalse);
    });

    test('an empty query matches everything', () {
      const capability = AssistantCapabilityModel(id: 'x');
      expect(capability.matches('  '), isTrue);
    });

    test('falls back to the English label when Arabic is missing', () {
      const capability = AssistantCapabilityModel(id: 'x', label: 'Revenue');
      expect(capability.displayLabel, 'Revenue');
    });
  });

  group('AssistantAnswerModel', () {
    test('reports how many rows were left out', () {
      final answer = AssistantAnswerModel.fromJson({
        'intentId': 'late-cases',
        'shape': 'entities',
        'totalCount': 12,
        'entities': [
          for (var i = 0; i < 5; i++) {'id': '$i', 'title': 'حالة $i'},
        ],
      });

      expect(answer.entities, hasLength(5));
      expect(answer.truncatedCount, 7);
    });

    test('nothing truncated when everything fit', () {
      final answer = AssistantAnswerModel.fromJson({
        'intentId': 'x',
        'shape': 'entities',
        'totalCount': 2,
        'entities': [
          {'id': '1', 'title': 'أ'},
          {'id': '2', 'title': 'ب'},
        ],
      });

      expect(answer.truncatedCount, 0);
    });

    test('a series answer keeps one line per currency', () {
      // Money is never blended across currencies here any more than anywhere
      // else in the product.
      final answer = AssistantAnswerModel.fromJson({
        'intentId': 'revenue',
        'shape': 'series',
        'series': [
          {
            'currency': {'id': 'c1', 'code': 'USD', 'symbol': r'$'},
            'total': 1200.0,
            'points': [
              {'label': 'مارس', 'value': 1200.0},
            ],
          },
          {
            'currency': {'id': 'c2', 'code': 'SYP'},
            'total': 500000.0,
          },
        ],
      });

      expect(answer.series, hasLength(2));
      expect(answer.series.first.totalLabel, contains(r'$'));
    });

    test('an entity with nowhere to go carries no action url', () {
      // A per-user work count has no screen of its own, and a row that looks
      // tappable but does nothing is worse than one that never offered.
      final entity = AssistantEntityModel.fromJson({
        'id': 'u1',
        'title': 'أحمد',
      });

      expect(entity.actionUrl, isNull);
    });

    test('a doctor can owe in several currencies at once', () {
      final entity = AssistantEntityModel.fromJson({
        'id': 'd1',
        'title': 'د. خالد',
        'trailingMoney': [
          {
            'amount': 100.0,
            'currency': {'id': 'c1', 'code': 'USD', 'symbol': r'$'},
          },
          {
            'amount': 50000.0,
            'currency': {'id': 'c2', 'code': 'SYP'},
          },
        ],
      });

      expect(entity.trailingMoney, hasLength(2));
      expect(entity.trailingMoney.first.label, contains(r'$'));
    });
  });

  group('SmartAssistantItemModel', () {
    test('an unknown rule falls back to its key rather than to silence', () {
      final item = SmartAssistantItemModel.fromJson({
        'rule': 'some-new-rule',
        'severity': 'warning',
        'caseId': 'c1',
        'caseNumber': '1024',
        'actionUrl': '/cases/c1',
      });

      expect(item.label, 'some-new-rule');
    });

    test('a known rule reads as a sentence', () {
      final item = SmartAssistantItemModel.fromJson({
        'rule': 'late',
        'severity': 'critical',
        'caseId': 'c1',
        'caseNumber': '1024',
        'actionUrl': '/cases/c1',
      });

      expect(item.label, 'حالة تخطّت الوقت المتوقع');
    });
  });
}
