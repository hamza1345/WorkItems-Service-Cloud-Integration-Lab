/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Trigger principal pour Work_Item__c.
 * Délègue toute la logique au WorkItemTriggerHandler pour respecter les bonnes pratiques.
 */
trigger WorkItemTrigger on Work_Item__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  // Before Insert
  if (Trigger.isBefore && Trigger.isInsert) {
    WorkItemTriggerHandler.handleBeforeInsert(Trigger.new);
  }

  // Before Update
  if (Trigger.isBefore && Trigger.isUpdate) {
    WorkItemTriggerHandler.handleBeforeUpdate(
      Trigger.new,
      Trigger.old,
      Trigger.newMap,
      Trigger.oldMap
    );
  }

  // Before Delete
  if (Trigger.isBefore && Trigger.isDelete) {
    WorkItemTriggerHandler.handleBeforeDelete(Trigger.old, Trigger.oldMap);
  }

  // After Insert
  if (Trigger.isAfter && Trigger.isInsert) {
    WorkItemTriggerHandler.handleAfterInsert(Trigger.new, Trigger.newMap);
  }

  // After Update
  if (Trigger.isAfter && Trigger.isUpdate) {
    WorkItemTriggerHandler.handleAfterUpdate(
      Trigger.new,
      Trigger.old,
      Trigger.newMap,
      Trigger.oldMap
    );
  }

  // After Delete
  if (Trigger.isAfter && Trigger.isDelete) {
    WorkItemTriggerHandler.handleAfterDelete(Trigger.old, Trigger.oldMap);
  }

  // After Undelete
  if (Trigger.isAfter && Trigger.isUndelete) {
    WorkItemTriggerHandler.handleAfterUndelete(Trigger.new, Trigger.newMap);
  }
}
