/**
 * @author Hamza Amari
 * @date 28/12/2025
 * @description Trigger pour persister les logs App_Log__e vers App_Log__c.
 * 
 * Contextes supportés :
 * - after insert : Crée un enregistrement App_Log__c pour chaque événement reçu
 * 
 * Flux :
 * 1. Logger publie App_Log__e (Platform Event)
 * 2. Trigger reçoit les événements
 * 3. Mappe et convertit vers App_Log__c
 * 4. Insère en bulk dans la base de données
 * 5. Gère les erreurs sans interruption
 */
trigger App_Log_EventTrigger on App_Log__e (after insert) {
  if (Trigger.isAfter && Trigger.isInsert) {
    App_Log_EventTriggerHandler.persistLogs(Trigger.new);
  }
}
