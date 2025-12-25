/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Routes all Work_Item__c events to WorkItemTriggerHandler for centralized processing.
 * Supports: before insert, after insert, before update, after update, before delete, after delete.
 */
trigger WorkItemTrigger on Work_Item__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete
) {
  WorkItemTriggerHandler handler = new WorkItemTriggerHandler();

  if (Trigger.isBefore && Trigger.isInsert) {
    handler.handleBeforeInsert(Trigger.new);
  } else if (Trigger.isAfter && Trigger.isInsert) {
    handler.handleAfterInsert(Trigger.new);
  } else if (Trigger.isBefore && Trigger.isUpdate) {
    handler.handleBeforeUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
  } else if (Trigger.isAfter && Trigger.isUpdate) {
    handler.handleAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
  } else if (Trigger.isBefore && Trigger.isDelete) {
    handler.handleBeforeDelete(Trigger.old);
  } else if (Trigger.isAfter && Trigger.isDelete) {
    handler.handleAfterDelete(Trigger.old);
  }
}
