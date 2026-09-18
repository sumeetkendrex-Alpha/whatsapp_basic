trigger OrderItemTrigger on OrderItem (after insert) {
	OrderItemTriggerHandler.sendMessageToOwner2(Trigger.new);

}