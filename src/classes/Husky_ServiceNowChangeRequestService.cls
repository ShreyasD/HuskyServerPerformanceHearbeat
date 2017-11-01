global class Husky_ServiceNowChangeRequestService {

	private static List<SCOM_Change_Request__c> chRequestRecords;

	private static final String 	ACTIVE_DEFAULT 		= '0';
	private static final String 	APPROVAL_DEFAULT 	= 'Requested';
	private static final String 	PRIORITY_DEFAULT 	= 'Planned';
	private static final String 	SOURCETYPE_DEFAULT 	= 'Project';
	private static final String 	STATE_DEFAULT 		= 'Draft';
	private static final String 	URGENCY_DEFAULT 	= '3 - Low';

	/************************* SOAP Interface ************************************/
	webservice static Husky_ServiceNowApiUtils.Response pushRecords (List<APIChangeRequest> records) {
		Husky_ServiceNowApiUtils.Response response = new Husky_ServiceNowApiUtils.Response();

		initialize();
		response.addResults(parseRecords(records));
		response.addResults(commitRecords());

		return response;
	}
	/*****************************************************************************/


	private static void initialize() {
		chRequestRecords = new List<SCOM_Change_Request__c>();
	}

	private static List<Husky_ServiceNowApiUtils.Result> parseRecords(List<APIChangeRequest> records) {
		List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();

		for(APIChangeRequest chRequestRecord : records) {
			SCOM_Change_Request__c record = new SCOM_Change_Request__c();

			record.Active__c = getPicklistValue(chRequestRecord.active, ACTIVE_DEFAULT);
			record.Application__c = chRequestRecord.application ;
			record.Approval__c = getPicklistValue(chRequestRecord.approval, APPROVAL_DEFAULT);
			record.Approvers__c = chRequestRecord.approvers;
			record.Change_Request_Number__c = chRequestRecord.changeRequestNumber;
			record.End_Date__c = parseDateTime(chRequestRecord.endDate);
			record.Hyperlink__c = chRequestRecord.hyperlink;
			record.Implementation_Reviewers__c = chRequestRecord.implementationReviewers;
			record.Opened_At__c = parseDateTime(chRequestRecord.openedAt);
			record.Opened_By__c = chRequestRecord.openedBy;
			record.Parent__c = chRequestRecord.parent;
			record.Priority__c = getPicklistValue(chRequestRecord.priority, PRIORITY_DEFAULT);
			record.Project__c = chRequestRecord.project;
			record.Requested_By_Date__c = parseDateTime(chRequestRecord.requestedByDate);
			record.Short_Description__c = chRequestRecord.shortDescription;
			record.Source_Type__c = getPicklistValue(chRequestRecord.sourceType, SOURCETYPE_DEFAULT);
			record.Start_Date__c = parseDateTime(chRequestRecord.startDate);
			record.State__c = getPicklistValue(chRequestRecord.state, STATE_DEFAULT);
			record.Urgency__c = getPicklistValue(chRequestRecord.urgency, URGENCY_DEFAULT);

			chRequestRecords.add(record);
		}

		return results;
	}

	private static String getPicklistValue(String parsedValue, String defaultValue) {
		return (!String.isBlank(parsedValue)) ? parsedValue : defaultValue;
	}

	private static DateTime parseDateTime(String value) {
		return (!String.isBlank(value)) ? (Datetime) JSON.deserialize('\"'+value+'\"', Datetime.class) : System.now();
	}

	private static List<Husky_ServiceNowApiUtils.Result> commitRecords() {
		List<SObject> dmlRecords = new List<SObject>();
		List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();
		List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();

		//Upsert
		upsertResults.addAll(Database.upsert(chRequestRecords, SCOM_Change_Request__c.fields.Change_Request_Number__c, false));
		dmlRecords.addAll((List<SObject>) chRequestRecords);

		for(Integer i=0; i < upsertResults.size(); i++) {
			Database.UpsertResult upsertResult = upsertResults[i];
			String statusCode = upsertResult.isSuccess() ? Husky_ServiceNowApiUtils.STATUS_SUCCESS_UPSERT :
				Husky_ServiceNowApiUtils.STATUS_ERROR_UPSERT;
			String idString = (String) dmlRecords[i].get('Change_Request_Number__c');
			Husky_ServiceNowApiUtils.Result result = new Husky_ServiceNowApiUtils.Result(upsertResult.isCreated(), idString,
				upsertResult.isSuccess(), statusCode);
			for(Database.Error err : upsertResult.getErrors()) {
				result.addError(new Husky_ServiceNowApiUtils.Error(err.getFields(), err.getMessage(), err.getStatusCode()));
			}
			results.add(result);
		}

		return results;
	}

	global class APIChangeRequest {
		webservice String active					{get;set;}
		webservice String application				{get;set;}
		webservice String approval					{get;set;}
		webservice String approvers					{get;set;}
		webservice String changeRequestNumber		{get;set;}
		webservice String endDate					{get;set;}
		webservice String hyperlink					{get;set;}
		webservice String implementationReviewers	{get;set;}
		webservice String openedAt					{get;set;}
		webservice String openedBy					{get;set;}
		webservice String parent					{get;set;}
		webservice String priority					{get;set;}
		webservice String project					{get;set;}
		webservice String requestedByDate			{get;set;}
		webservice String shortDescription			{get;set;}
		webservice String sourceType				{get;set;}
		webservice String startDate					{get;set;}
		webservice String state						{get;set;}
		webservice String urgency					{get;set;}
	}

}