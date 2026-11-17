import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/viewmodels/dashboard_viewmodel.dart';

void main() {
  late DashboardViewModel vm;

  setUp(() => vm = DashboardViewModel(seedDemoData: false));
  tearDown(() => vm.dispose());

  test('rejects invalid matric numbers', () {
    expect(vm.startTrip('hall_a', '123'), StartTripResult.invalidMatric);
  });

  test('queues students when the hall is full', () {
    expect(vm.startTrip('hall_a', 'B23CS0001'), StartTripResult.started);
    expect(vm.startTrip('hall_a', 'B23CS0002'), StartTripResult.started);
    expect(vm.startTrip('hall_a', 'b23cs0003'), StartTripResult.queued);
    expect(vm.isFull('hall_a'), true);
    expect(vm.queue('hall_a').single.matric, 'B23CS0003');
  });

  test('blocks duplicates and approves queue after a return', () {
    vm.startTrip('hall_a', 'B23CS0001');
    vm.startTrip('hall_a', 'B23CS0002');
    vm.startTrip('hall_a', 'B23CS0003');
    expect(vm.startTrip('hall_dsi', 'B23CS0001'), StartTripResult.duplicate);
    expect(vm.approveNext('hall_a'), false);

    vm.returnTrip(vm.activeTrips('hall_a').first.id);
    expect(vm.approveNext('hall_a'), true);
    expect(vm.queue('hall_a'), isEmpty);
    expect(vm.historyFor('B23CS0001').length, 1);
  });
}
