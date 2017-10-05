@isTest
private class Husky_SCOMDashboardControllerTest {

	@isTest static void testPerformanceStatusDashboard() {
		User usr = Husky_SCOM_TestData.createUser();
		System.runAs(usr) {
			Husky_SCOMDashboardController ctrl = new Husky_SCOMDashboardController();
			System.assertNotEquals(null, ctrl.criticalityStatusMap);
			System.assertNotEquals(null, ctrl.performanceToStatusMap);
			System.assertNotEquals(null, ctrl.performanceRecordsByCriticalityMap);
			System.assert(ctrl.criticalityStatusMap.size() > 0);
			System.assert(ctrl.performanceToStatusMap.size() > 0);
			System.assert(ctrl.performanceRecordsByCriticalityMap.size() > 0);

			System.assertEquals(SCOM_Server__c.Criticality__c.getDescribe().getPicklistValues().size(), ctrl.performanceRecordsByCriticalityMap.size());

			System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU, ctrl.getPerformanceMetricCPU());
			System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY, ctrl.getPerformanceMetricMEM());
			System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_GREEN, ctrl.getGreen());
			System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_ORANGE, ctrl.getOrange());
			System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_RED, ctrl.getRed());

			for (List<Husky_SCOMDashboardController.PerformanceWrapper> perfWrappers : ctrl.performanceRecordsByCriticalityMap.values())
				for(Husky_SCOMDashboardController.PerformanceWrapper perfWrapper : perfWrappers) {
					checkMemValue(perfWrapper);
					checkCPUValue(perfWrapper);
				}
		}
	}

	private static void checkMemValue(Husky_SCOMDashboardController.PerformanceWrapper wrapper) {
		if (wrapper.memActual < wrapper.memAvg) System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_GREEN, wrapper.getMemPerformanceStatus());
		else if (wrapper.memActual < wrapper.memThreshold) System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_ORANGE, wrapper.getMemPerformanceStatus());
		else System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_RED, wrapper.getMemPerformanceStatus());
	}

	private static void checkCPUValue(Husky_SCOMDashboardController.PerformanceWrapper wrapper) {
		if (wrapper.cpuActual <= wrapper.cpuAvg) System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_GREEN, wrapper.getCPUPerformanceStatus());
		else if (wrapper.cpuActual <= wrapper.cpuThreshold) System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_ORANGE, wrapper.getCPUPerformanceStatus());
		else System.assertEquals(Husky_SCOMUtilities.PERFORMANCE_RED, wrapper.getCPUPerformanceStatus());
	}

	@testSetup
	static void prepareData() {
		List<SCOM_Server__c> servers = Husky_SCOM_TestData.createServers(9);
		List<SCOM_Performance__c> performances = Husky_SCOM_TestData.createPerformanceForServers(servers);
		List<SCOM_Change_Request__c> chRequests = Husky_SCOM_TestData.createChangeRequests(30);
	}
}