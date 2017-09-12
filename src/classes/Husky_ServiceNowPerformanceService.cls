global class Husky_ServiceNowPerformanceService {

	private static List<SCOM_Server__c> serverRecords;
	private static List<SCOM_Performance__c> performanceRecords;

	global class APIServerPerformance {
		webservice String User {get; set;}
		webservice String Access {get; set;}
		webservice String Name {get; set;}
		webservice String Asset {get; set;}
		webservice String Application {get; set;}
		webservice String MetricName {get; set;}
		webservice String MonitoringInstance {get; set;}
		webservice String KeyTime {get; set;}
		webservice String AverageValue {get; set;}
		webservice String MinimumValue {get; set;}
		webservice String MaxValue {get; set;}
		webservice String CurrentValue {get; set;}
		webservice String Unit {get; set;}
		webservice String Assettype {get; set;}
		webservice String App_flag {get; set;}
	}

	/************************* SOAP Interface ************************************/
	webservice static Husky_ServiceNowApiUtils.Response pushRecords (List<APIServerPerformance> records) {
		Husky_ServiceNowApiUtils.Response response = new Husky_ServiceNowApiUtils.Response();

		initialize();
		response.addResults(parseRecords(records));
		response.addResults(commitRecords());

		return response;
	}
	/*****************************************************************************/

	private static void initialize() {
		performanceRecords = new List<SCOM_Performance__c>();
		serverRecords = new List<SCOM_Server__c>();
	}

	private static List<Husky_ServiceNowApiUtils.Result> parseRecords(List<APIServerPerformance> records) {
		List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();
		Map<String, String> serverMap = new Map<String, String>();

		for(APIServerPerformance performanceRecord : records) {
			//Get Server Info
			serverMap.put(performanceRecord.Asset.subStringBefore('.'), performanceRecord.Assettype);

			//Get Performance Info
			String monitoringInstance = (!String.isBlank(performanceRecord.MonitoringInstance)) ?
				performanceRecord.MonitoringInstance : '_self';
			SCOM_Performance__c record = new SCOM_Performance__c();
			record.Type__c = 'Realtime';
			record.External_Key__c = performanceRecord.Asset + '-' + performanceRecord.MetricName + '-' +
				monitoringInstance + '-' + record.Type__c;
			record.Metric__c = performanceRecord.MetricName;
			record.Monitor_Instance__c = monitoringInstance;
			record.Time__c = DateTime.newInstance(Long.valueOf(performanceRecord.KeyTime + '000'));
			record.Avg_Metric_Value__c = (!String.isBlank(performanceRecord.AverageValue)) ?
				Decimal.valueOf(performanceRecord.AverageValue) : 0.00;
			record.Min_Metric_Value__c = (!String.isBlank(performanceRecord.MinimumValue)) ?
				Decimal.valueOf(performanceRecord.MinimumValue) : 0.00;
			record.Max_Metric_Value__c = (!String.isBlank(performanceRecord.MaxValue)) ?
				Decimal.valueOf(performanceRecord.MaxValue) : 0.00;
			record.Current_Metric_Value__c = (!String.isBlank(performanceRecord.CurrentValue)) ?
				Decimal.valueOf(performanceRecord.CurrentValue) : 0.00;
			record.Unit__c = performanceRecord.Unit;
			record.Server__r = new SCOM_Server__c(
				Name = performanceRecord.Asset
			);
			performanceRecords.add(record);
		}

		//Create Server Records
		for(String key : serverMap.keySet()) {
			SCOM_Server__c server = new SCOM_Server__c();
			server.Name = key;
			server.Host_Name__c = serverMap.get(key);
			server.External_Id__c = key;
			serverRecords.add(server);
		}

		return results;
	}

	private static List<Husky_ServiceNowApiUtils.Result> commitRecords() {
		List<SObject> dmlRecords = new List<SObject>();
		List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();
		List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();

		//Upsert
		upsertResults.addAll(Database.upsert(serverRecords, SCOM_Server__c.fields.Name, false));
		dmlRecords.addAll((List<SObject>) serverRecords);
		upsertResults.addAll(Database.upsert(performanceRecords, SCOM_Performance__c.fields.External_Key__c, false));
		dmlRecords.addAll((List<SObject>) performanceRecords);

		for(Integer i=0; i < upsertResults.size(); i++) {
			Database.UpsertResult upsertResult = upsertResults[i];
			String statusCode = upsertResult.isSuccess() ? Husky_ServiceNowApiUtils.STATUS_SUCCESS_UPSERT :
				Husky_ServiceNowApiUtils.STATUS_ERROR_UPSERT;
			String idString = (String) ((dmlRecords[i] instanceof SCOM_Server__c) ? dmlRecords[i].get('Name') :
				dmlRecords[i].get('External_Key__c'));
			Husky_ServiceNowApiUtils.Result result = new Husky_ServiceNowApiUtils.Result(upsertResult.isCreated(), idString,
				upsertResult.isSuccess(), statusCode);
			for(Database.Error err : upsertResult.getErrors()) {
				result.addError(new Husky_ServiceNowApiUtils.Error(err.getFields(), err.getMessage(), err.getStatusCode()));
			}
			results.add(result);
		}

		return results;
	}
}