@isTest
private class Husky_ServiceNowPerformanceServiceTest {

	@isTest static void performanceSOAPWebserviceTest() {
		List<Husky_ServiceNowPerformanceService.APIServerPerformance> performances =
			new List<Husky_ServiceNowPerformanceService.APIServerPerformance>();
		Integer num = 4;
		List<SCOM_Server__c> servers = Husky_SCOM_TestData.createServers(num);
		for (SCOM_Server__c server : servers) {
			Husky_ServiceNowPerformanceService.APIServerPerformance record =
				new Husky_ServiceNowPerformanceService.APIServerPerformance();
			record.User = 'jschon';
			record.Asset = server.Name;
			record.Application = 'application ' + server.Name;
			record.MetricName = Husky_SCOMUtilities.PERFORMANCE_METRIC_CPU;
			record.MonitoringInstance = '_Total';
			record.KeyTime = String.valueOf(DateTime.now().millisecond());
			record.AverageValue = '50';
			record.MinimumValue = '25';
			record.MaxValue = '75';
			record.CurrentValue = '50';
			record.Unit = Husky_SCOMUtilities.PERFORMANCE_UNIT_CPU;
			performances.add(record);
			record = new Husky_ServiceNowPerformanceService.APIServerPerformance();
			record.User = 'jschon';
			record.Asset = server.Name;
			record.Application = 'application ' + server.Name;
			record.MetricName = Husky_SCOMUtilities.PERFORMANCE_METRIC_MEMORY;
			record.KeyTime = String.valueOf(DateTime.now().millisecond());
			record.AverageValue = '50';
			record.MinimumValue = '25';
			record.MaxValue = '75';
			record.CurrentValue = '50';
			record.Unit = Husky_SCOMUtilities.PERFORMANCE_UNIT_MEMORY;
			performances.add(record);
		}
		Husky_ServiceNowPerformanceService.pushRecords(performances);
		System.assertEquals(num*2, [SELECT Count() FROM SCOM_Performance__c]);
	}


}
