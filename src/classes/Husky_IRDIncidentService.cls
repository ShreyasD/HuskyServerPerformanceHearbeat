global class Husky_IRDIncidentService {
	/************************* SOAP Interface ************************************/
	global class APIIncident {
      webservice String inc_number {get; set;}
      webservice String assignment_group {get; set;}
      webservice String assigned_to {get; set;}
      webservice String caller {get; set;}
      webservice String category {get; set;}
      webservice String caused_by_change {get; set;}
      webservice String configuration_item {get; set;}
      webservice String impact {get; set;}
      webservice String location {get; set;}
      webservice Datetime opened {get; set;}
      webservice String openedby {get; set;}
      webservice String priority {get; set;}
      webservice String requested_for {get; set;}
      webservice String resolved_by {get; set;}
      webservice String resolved_date {get; set;}
      webservice String short_description {get; set;}
      webservice String source {get; set;}
      webservice String state {get; set;}
      webservice String subcategory {get; set;}
      webservice String urgency {get; set;}
      webservice String case_type {get; set;}
      webservice String url {get; set;}
    }

    webservice static Husky_ServiceNowApiUtils.Response pushRecords (List<APIIncident> records) {
      Husky_ServiceNowApiUtils.Response response = new Husky_ServiceNowApiUtils.Response();
      initialize();
      response.addResults(parseRecords(records));
      response.addResults(commitRecords());
      return response;
    }
    /*****************************************************************************/

    private static List<IRD_Incident__c> incidentRecords;

    private static void initialize() {
      incidentRecords = new List<IRD_Incident__c>();
    }

    private static List<Husky_ServiceNowApiUtils.Result> parseRecords(List<APIIncident> records) {
	    List<Husky_ServiceNowApiUtils.Result> results = new List<Husky_ServiceNowApiUtils.Result>();

	  	try{ 
			for(APIIncident record : records) {
				IRD_Incident__c incident = new IRD_Incident__c();
				incident.Name = record.inc_number;
				incident.Assignment_Group__c = record.assignment_group;
				incident.Assigned_To__c = record.assigned_to;
				incident.Caller__c = record.caller;
				incident.Category__c = record.category;
				incident.Caused_By_Change__c = record.caused_by_change;
				incident.Configuration_Item__c = record.configuration_item;
				incident.Impact__c = record.impact;
				incident.Location__c = record.location;
				incident.Opened__c = record.opened;
				incident.Opened_By__c = record.openedby;
				incident.Priority__c = record.priority;
				incident.Requested_For__c = record.requested_for;
				incident.Resolved_By__c = record.resolved_by;
				incident.Resolved_Date__c = (!String.isEmpty(record.resolved_Date)) ? 
					getDate(record.resolved_Date) : null;
				incident.Short_Description__c = record.short_description;
				incident.Source__c = record.source;
				incident.State__c = record.state;
				incident.Subcategory__c = record.subcategory;
				incident.Urgency__c = record.urgency;
				incident.Case_Type__c = record.case_type == null ? 'Incident' : record.case_type;
				incident.Hyper_link__c = record.url;
				incidentRecords.add(incident);
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
		upsertResults.addAll(Database.upsert(incidentRecords, IRD_Incident__c.fields.Name, false));
		dmlRecords.addAll((List<SObject>) incidentRecords);

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