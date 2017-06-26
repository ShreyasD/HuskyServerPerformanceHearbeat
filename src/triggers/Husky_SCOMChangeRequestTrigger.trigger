trigger Husky_SCOMChangeRequestTrigger on SCOM_Change_Request__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

	if(Husky_SCOMUtilities.executeTriggerCode) {

		if (Trigger.isBefore) {
	    	//call your handler.before method
	    
		} else if (Trigger.isAfter) {
	    	//call handler.after method
	    
		}
	}
}