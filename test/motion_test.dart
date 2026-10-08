import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_fix/core/motion/app_motion.dart';
import 'package:campus_fix/core/motion/animated_counter.dart';
import 'package:campus_fix/core/motion/interactive_card.dart';
import 'package:campus_fix/core/motion/motion_reveal.dart';
import 'package:campus_fix/core/motion/shimmer_loading.dart';
import 'package:campus_fix/core/motion/animated_complaint_timeline.dart';
import 'package:campus_fix/core/motion/animated_state_views.dart';
import 'package:campus_fix/models/complaint_model.dart';

void main() {
  group('AppMotion Tokens & Accessibility Tests', () {
    test('AppMotion tokens are defined with disciplined durations', () {
      expect(AppMotion.durationFast.inMilliseconds, lessThan(AppMotion.durationNormal.inMilliseconds));
      expect(AppMotion.durationNormal.inMilliseconds, lessThan(AppMotion.durationPage.inMilliseconds));
      expect(AppMotion.curveCinematic, isA<Cubic>());
      expect(AppMotion.isReducedMotion(), true); // True in automated testing binding
    });
  });

  group('AnimatedCounter Widget Tests', () {
    testWidgets('AnimatedCounter displays target value and prefix/suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 42,
              prefix: '#',
              suffix: ' items',
            ),
          ),
        ),
      );

      expect(find.text('#42 items'), findsOneWidget);
    });
  });

  group('InteractiveCard Widget Tests', () {
    testWidgets('InteractiveCard renders content and handles tap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCard(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapped, true);
    });
  });

  group('MotionReveal Widget Tests', () {
    testWidgets('MotionReveal renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MotionReveal(
              child: Text('Revealed Text'),
            ),
          ),
        ),
      );

      expect(find.text('Revealed Text'), findsOneWidget);
    });

    testWidgets('MotionReveal.staggered helper instantiates with computed delay', (tester) async {
      final widget = MotionReveal.staggered(
        index: 3,
        baseDelayMs: 50,
        intervalMs: 50,
        child: const Text('Staggered Item'),
      );

      expect(widget, isA<MotionReveal>());
    });
  });

  group('CampusShimmer & Skeleton Layout Tests', () {
    testWidgets('SkeletonStatGrid renders stat placeholders without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonStatGrid(),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('SkeletonComplaintList renders card placeholders without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonComplaintList(count: 3),
          ),
        ),
      );

      expect(find.byType(SkeletonComplaintList), findsOneWidget);
    });
  });

  group('AnimatedComplaintTimeline Widget Tests', () {
    testWidgets('AnimatedComplaintTimeline renders all 4 lifecycle stages', (tester) async {
      final now = DateTime.now();
      final complaint = ComplaintModel(
        complaintId: 'CF-2026-000101',
        studentId: 'student_123',
        studentName: 'Alex Student',
        title: 'Broken projector in Hall B',
        description: 'Lamp is burnt out.',
        category: 'Electrical',
        location: 'Science Block 202',
        status: 'IN_PROGRESS',
        createdAt: now,
        updatedAt: now,
        startedAt: now,
        assignedWorkerName: 'Robert Tech',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnimatedComplaintTimeline(complaint: complaint),
            ),
          ),
        ),
      );

      expect(find.text('LIFECYCLE TIMELINE'), findsOneWidget);
      expect(find.text('Stage 3 of 4'), findsOneWidget);
      expect(find.text('Reported'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('To Robert Tech'), findsOneWidget);
    });
  });

  group('AnimatedStateViews Tests', () {
    testWidgets('AnimatedEmptyState renders icon, message and button', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              title: 'Empty State Title',
              message: 'Nothing here.',
              buttonText: 'Action',
              onButtonPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Empty State Title'), findsOneWidget);
      expect(find.text('Nothing here.'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);

      await tester.tap(find.text('Action'));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('AnimatedSuccessView renders ticket ID and action buttons', (tester) async {
      bool trackClicked = false;
      bool doneClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSuccessView(
              complaintId: 'CF-2026-999888',
              title: 'Water Leak',
              onViewComplaint: () => trackClicked = true,
              onDone: () => doneClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Complaint Submitted!'), findsOneWidget);
      expect(find.text('Ticket ID: CF-2026-999888'), findsOneWidget);
      expect(find.text('Track Ticket'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.text('Track Ticket'));
      await tester.pump();
      expect(trackClicked, true);

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(doneClicked, true);
    });
  });
}
