trigger Husky_SCOMAvailabilityTrigger on SCOM_Availability__c (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

		if (Trigger.isBefore) {
	    	//call your handler.before method
	    
		} else if (Trigger.isAfter) {
	    	if(Trigger.isInsert) {
	    		Husky_SCOMUtilities.TriggerAfterInsertSCOMAvailability(Trigger.new);
	    	} else if (Trigger.isUpdate) {
	    		Husky_SCOMUtilities.TriggerAfterUpdateSCOMAvailability(Trigger.new, Trigger.oldMap);
	    	}
		}
}