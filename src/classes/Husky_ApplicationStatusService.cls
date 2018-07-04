global class Husky_ApplicationStatusService {
	/************************* SOAP Interface ************************************/
	global class APIApplicationStatus {
      webservice String application {get; set;}
      webservice String monitor_type {get; set;}
      webservice String monitor_name {get; set;}
      webservice String dateString {get; set;}
      webservice String status {get; set;}
      webservice String kbase_article {get; set;}
      webservice String message {get; set;}
    }

    webservice static Husky_ServiceNowApiUtils.Response pushRecords (List<APIApplicationStatus> records) {
      Husky_ServiceNowApiUtils.Response response = new Husky_ServiceNowApiUtils.Response();
      initialize();
      response.addResults(parseRecords(records));
      response.addResults(commitRecords());
      return response;
    }
    /*****************************************************************************/

    private static List<SCOM_Application_Status__c> applicationStatusRecords;

    private static void initialize() {
      applicationStatusRecords = new List<SCOM_Application_Status__c>();
    }

    private static List<Husky_ServiceNowApiUtils.Result> parseRecords(List<APIApplicationStatus> records) {
	    List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();

	    try{ 
			for(APIApplicationStatus applicationStatus : records) {
				SCOM_Application_Status__c status = new SCOM_Application_Status__c();
				status.Name = applicationStatus.application;
				status.Monitor_Type__c = applicationStatus.monitor_type;
				status.Monitor_Name__c = applicationStatus.monitor_name;
				status.Date__c = getDate(applicationStatus.dateString);
				status.Status__c = applicationStatus.status;
				status.Kbase_Article__c = applicationStatus.kbase_article;
				status.Message__c = applicationStatus.message;
				status.External_Key__c = applicationStatus.application + '-' + 
					applicationStatus.monitor_type + '-' + applicationStatus.monitor_name;
				applicationStatusRecords.add(status);
			}
	    } catch (Exception ex) {
			String statusCode = Husky_ServiceNowApiUtils.STATUS_ERROR_PARSE;
			Husky_ServiceNowApiUtils.Result result = new Husky_ServiceNowApiUtils.Result(false, null, 
				false, statusCode);
			result.addError(new Husky_ServiceNowApiUtils.Error(null, ex.getMessage(), null));
			results.add(result);
	    }


	    return results;
	}

	private static List<Husky_ServiceNowApiUtils.Result> commitRecords() {
		List<SObject> dmlRecords = new List<SObject>();
		List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();
		List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();

		//Upsert
		upsertResults.addAll(Database.upsert(applicationStatusRecords, SCOM_Application_Status__c.fields.External_Key__c, false));
		dmlRecords.addAll((List<SObject>) applicationStatusRecords);

		for(Integer i=0; i < upsertResults.size(); i++) {
		  Database.UpsertResult upsertResult = upsertResults[i];
		  String statusCode = upsertResult.isSuccess() ? Husky_ServiceNowApiUtils.STATUS_SUCCESS_UPSERT : 
		    Husky_ServiceNowApiUtils.STATUS_ERROR_UPSERT;
		  String idString = (String) dmlRecords[i].get('Name');
		  Husky_ServiceNowApiUtils.Result result = new Husky_ServiceNowApiUtils.Result(upsertResult.isCreated(), idString, 
		    upsertResult.isSuccess(), statusCode);
		  for(Database.Error err : upsertResult.getErrors()) {
		    result.addError(new Husky_ServiceNowApiUtils.Error(err.getFields(), err.getMessage(), err.getStatusCode()));
		  }
		  results.add(result);
		}

		return results;
	}

	private static Datetime getDate(String dateString) {
		Integer year = Integer.valueOf(dateString.substring(0,4));
		Integer month = Integer.valueOf(dateString.substring(4,6));
		Integer day = Integer.valueOf(dateString.substring(6,8));
		Integer hours = Integer.valueOf(dateString.substring(8,10));
		Integer minutes = Integer.valueOf(dateString.substring(10,12));
		Integer seconds = Integer.valueOf(dateString.substring(12,14));
		return Datetime.newInstance(year, month, day, hours, minutes, seconds);
	}
}