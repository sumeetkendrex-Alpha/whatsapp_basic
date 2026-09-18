trigger CaseTrigger on Case (after insert) {
	CaseTriggerHandler.sendWhatsappMessage(Trigger.new);
}