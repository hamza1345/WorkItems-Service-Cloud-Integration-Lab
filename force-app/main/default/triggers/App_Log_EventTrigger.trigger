/**
 * @author Hamza Amari
 * @date 30/12/2025
 * @description Déclencheur pour consommer les événements App_Log__e et les persister.
 * Responsabilités :
 * - Déclencher le gestionnaire d'événements après insertion
 * - Passer les événements au gestionnaire pour traitement bulk
 * - Aucune logique métier dans le déclencheur (respecter les standards)
 */
trigger App_Log_EventTrigger on App_Log__e (after insert) {
  if (Trigger.isAfter && Trigger.isInsert) {
    App_Log_EventSubscriber.handleMessage(Trigger.new);
  }
}
