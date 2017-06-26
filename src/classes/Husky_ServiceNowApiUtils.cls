/**
 * See https://github.com/financialforcedev/fflib-apex-common for more info
 *
 * Install library via
 *   https://githubsfdeploy.herokuapp.com/app/githubdeploy/financialforcedev/fflib-apex-common
 */

/**
 * Encapsulates all service layer logic for a given function or module in the application
 * 
 * For more guidelines and details see 
 *   https://developer.salesforce.com/page/Apex_Enterprise_Patterns_-_Service_Layer
 *
 **/
global with sharing class  Husky_ServiceNowApiUtils {

	/** Return codes for record */
    global final static String STATUS_SUCCESS_PARSE = 'PARSING_SUCCESS';
    global final static String STATUS_SUCCESS_UPSERT = 'UPSERT_SUCCESS';
    global final static String STATUS_ERROR_PARSE = 'PARSING_ERROR';
    global final static String STATUS_ERROR_UPSERT = 'UPSERT_ERROR';
    global final static String STATUS_ERROR_INVALID_RECORD = 'INVALID_RECORD';

	global class Response {
		webservice List<Result> results {get; set;}

		public void addResults(List<Result> results) {
        	if(this.results == null) this.results = new List<Result>();
        	this.results.addAll(results);
      	}
	}
	
	global class Result {
      webservice Boolean created {get; set;}
      webservice String id {get; set;}
      webservice Boolean success {get; set;}
      WebService List<Error> errors {get; set;}
      webservice String statusCode {get; set;}

      public Result(Boolean created, String id,
        Boolean success, String statusCode) {
        this.created = created;
        this.id = id;
        this.success = success;
        this.statusCode = statusCode;
        this.errors = new List<Error>();
      }

      public void addError(Error err) {
        this.errors.add(err);
      }
    }

    global class Error {
      webservice List<String> fields {get; set;}
      webservice String message {get; set;}
      webservice StatusCode statusCode {get; set;}

      public Error(List<String> fields, String message, 
        StatusCode statusCode) {
        this.fields = fields;
        this.message = message;
        this.statusCode = statusCode;
      }
    }
}