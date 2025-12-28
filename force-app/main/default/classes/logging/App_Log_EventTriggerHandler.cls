/**
 * @author Hamza Amari
 * @date 28/12/2025
 * @description Gestionnaire pour le trigger App_Log_EventTrigger.
 * Persiste les logs App_Log__e vers App_Log__c.
 * 
 * Responsabilités :
 * - Mapper les événements App_Log__e vers App_Log__c
 * - Valider les permissions CRUD
 * - Insérer en bulk
 * - Gérer les erreurs sans interrompre le traitement
 * - Vérifier les feature flags avant persistance
 *
 * Sécurité :
 * - Utiliser with sharing pour respecter les permissions
 * - Valider l'accès CRUD avant insertion
 *
 * Performance :
 * - Bulkifié (pas de limite DML)
 * - Pas de SOQL supplémentaire
 * - Pas d'appels asynchrones
 */
public with sharing class App_Log_EventTriggerHandler {
  private static final Logger LOGGER = LoggerFactory.getLogger('App_Log_EventTriggerHandler');

  /**
   * @description Persister une liste d'événements App_Log__e vers App_Log__c.
   * @param logEvents Liste des événements à persister
   */
  public static void persistLogs(List<App_Log__e> logEvents) {
    try {
      // Vérifier si la persistance est activée via feature flag
      if (!FeatureFlags.persistLogs()) {
        LOGGER.debug('persistLogs', 'Persistance des logs désactivée, ignorant événements');
        return;
      }

      // Vérifier les permissions CRUD
      if (!App_Log__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()) {
        LOGGER.warn('persistLogs', 'Pas de permission pour créer App_Log__c, ignorant');
        return;
      }

      // Convertir les événements en enregistrements
      List<App_Log__c> logsToInsert = new List<App_Log__c>();
      for (App_Log__e logEvent : logEvents) {
        logsToInsert.add(convertEventToRecord(logEvent));
      }

      // Insérer en bulk si nous avons des enregistrements
      if (!logsToInsert.isEmpty()) {
        insert logsToInsert;
        LOGGER.info('persistLogs', 'Persisté ' + logsToInsert.size() + ' logs avec succès');
      }
    } catch (DmlException e) {
      LOGGER.error('persistLogs', 'Erreur DML lors de la persistance des logs', e);
      // Ne pas relancer l'exception - garder le traitement asynchrone résilient
    } catch (Exception e) {
      LOGGER.error('persistLogs', 'Erreur inattendue lors de la persistance des logs', e);
      // Ne pas relancer l'exception
    }
  }

  /**
   * @description Convertir un événement App_Log__e en enregistrement App_Log__c.
   * @param logEvent Événement à convertir
   * @return Enregistrement App_Log__c mappé
   */
  private static App_Log__c convertEventToRecord(App_Log__e logEvent) {
    return new App_Log__c(
      Level__c = logEvent.Level__c,
      Message__c = logEvent.Message__c,
      Source__c = logEvent.Source__c,
      RecordId__c = logEvent.RecordId__c,
      CorrelationId__c = logEvent.CorrelationId__c,
      Tags__c = logEvent.Tags__c,
      StackTrace__c = logEvent.StackTrace__c
    );
  }
}
