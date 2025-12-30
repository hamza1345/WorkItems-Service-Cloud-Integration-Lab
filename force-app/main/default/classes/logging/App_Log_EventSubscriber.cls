/**
 * @author Hamza Amari
 * @date 30/12/2025
 * @description Abonné aux événements App_Log__e pour persister les logs en base de données.
 * Responsabilités :
 * - Consommer les événements Platform Event App_Log__e
 * - Mapper les données d'événement vers App_Log__c
 * - Insérer les logs en bulk dans la base de données
 * - Gérer les erreurs sans interrompre le traitement
 * - Vérifier les flags de fonctionnalités avant persistance
 *
 * Sécurité :
 * - Valider l'accès CRUD à App_Log__c avant insertion
 * - Utiliser with sharing pour respecter les permissions
 *
 * Performance :
 * - Bulkifier les insertions
 * - Pas de SOQL supplémentaire
 * - Pas d'appels asynchrones imbriqués
 */
public with sharing class App_Log_EventSubscriber {
  private static final Logger LOGGER = LoggerFactory.getLogger('App_Log_EventSubscriber');

  /**
   * @description Gérer les événements entrants depuis le déclencheur.
   * @param logEvents Liste des événements App_Log__e à traiter
   */
  public static void handleMessage(List<App_Log__e> logEvents) {
    try {
      // Vérifier si la persistance est activée
      if (!FeatureFlags.persistLogs()) {
        LOGGER.debug('handleMessage', 'Persistance des logs désactivée, ignorant');
        return;
      }

      // Vérifier que la liste n'est pas vide
      if (logEvents == null || logEvents.isEmpty()) {
        LOGGER.warn('handleMessage', 'Liste d\'événements vide');
        return;
      }

      // Valider CRUD avant insertion
      if (!App_Log__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()) {
        LOGGER.warn('handleMessage', 'Pas d\'accès en création à App_Log__c');
        return;
      }

      // Convertir tous les événements en enregistrements
      List<App_Log__c> logsToInsert = new List<App_Log__c>();
      for (App_Log__e logEvent : logEvents) {
        App_Log__c logRecord = convertEventToRecord(logEvent);
        logsToInsert.add(logRecord);
      }

      // Insérer en bulk
      if (!logsToInsert.isEmpty()) {
        insert logsToInsert;
        LOGGER.info('handleMessage', 'Logs persistés : ' + logsToInsert.size());
      }
    } catch (DmlException e) {
      // Gestion gracieuse des erreurs DML
      LOGGER.error('handleMessage', 'Erreur DML lors de la persistance des logs', e);
      // Ne pas relancer pour éviter d'interrompre l'application
    } catch (Exception e) {
      // Gestion gracieuse des erreurs générales
      LOGGER.error('handleMessage', 'Erreur lors de la persistance des logs', e);
      // Ne pas relancer pour éviter d'interrompre l'application
    }
  }

  /**
   * @description Convertir un événement App_Log__e en enregistrement App_Log__c.
   * Mappage direct sans calcul métier.
   * @param logEvent Événement à convertir
   * @return Enregistrement App_Log__c mappé
   */
  private static App_Log__c convertEventToRecord(App_Log__e logEvent) {
    return new App_Log__c(
      Level__c = logEvent.Level__c,
      Message__c = logEvent.Message__c,
      Request_Id__c = logEvent.Request_Id__c,
      Class_Name__c = logEvent.Class_Name__c,
      Method_Name__c = logEvent.Method_Name__c,
      User_Id__c = logEvent.User_Id__c,
      Exception_Message__c = logEvent.Exception_Message__c,
      Exception_Stack_Trace__c = logEvent.Exception_Stack_Trace__c,
      Timestamp__c = System.now()
    );
  }
}
