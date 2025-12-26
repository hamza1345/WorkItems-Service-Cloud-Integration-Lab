/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Gestionnaire pour les événements du déclencheur WorkItemTrigger.
 * Responsabilités :
 * - Acheminer les événements du déclencheur vers les méthodes de service appropriées
 * - Assurer les opérations bulkifiées (pas de SOQL dans les boucles)
 * - Gérer le flux des transactions et la gestion des erreurs
 * - Prévenir les exécutions récursives du déclencheur par contexte
 *
 * Événements du déclencheur gérés :
 * - beforeInsert : Validation, remplissage des champs
 * - afterInsert : Création des enregistrements associés, publication d'événements
 * - beforeUpdate : Validation, mise à jour des champs
 * - afterUpdate : Mise à jour des enregistrements associés, notifications
 * - beforeDelete : Validation de suppression
 * - afterDelete : Nettoyage, piste d'audit
 *
 * Stratégie anti-récursion :
 * - Suivi par contexte (before/after, insert/update/delete)
 * - Prévient les boucles infinies des mises à jour auto-déclenchées
 * - Utilise Set<Id> pour tracer les éléments de travail traités dans chaque contexte
 */
public with sharing class WorkItemTriggerHandler {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemTriggerHandler');

  // ========================================
  // CONTRÔLES ANTI-RÉCURSION
  // ========================================
  // Trace les IDs traités par contexte de déclencheur pour prévenir la récursion.
  // Chaque contexte (beforeInsert, afterInsert, etc.) a son propre Set
  // pour permettre un contrôle indépendant du même enregistrement dans les différentes phases.

  /**
   * @description IDs des éléments de travail traités dans le contexte beforeInsert.
   * Prévient le re-traitement des mêmes enregistrements si handleBeforeInsert est appelé plusieurs fois.
   */
  private static Set<Id> processedBeforeInsertIds = new Set<Id>();

  /**
   * @description IDs des éléments de travail traités dans le contexte afterInsert.
   * Prévient le re-traitement des mêmes enregistrements si handleAfterInsert est appelé plusieurs fois.
   */
  private static Set<Id> processedAfterInsertIds = new Set<Id>();

  /**
   * @description IDs des éléments de travail traités dans le contexte beforeUpdate.
   * Prévient le re-traitement des mêmes enregistrements si handleBeforeUpdate est appelé plusieurs fois.
   */
  private static Set<Id> processedBeforeUpdateIds = new Set<Id>();

  /**
   * @description IDs des éléments de travail traités dans le contexte afterUpdate.
   * Prévient le re-traitement des mêmes enregistrements si handleAfterUpdate est appelé plusieurs fois.
   */
  private static Set<Id> processedAfterUpdateIds = new Set<Id>();

  /**
   * @description IDs des éléments de travail traités dans le contexte beforeDelete.
   * Prévient le re-traitement des mêmes enregistrements si handleBeforeDelete est appelé plusieurs fois.
   */
  private static Set<Id> processedBeforeDeleteIds = new Set<Id>();

  /**
   * @description IDs des éléments de travail traités dans le contexte afterDelete.
   * Prévient le re-traitement des mêmes enregistrements si handleAfterDelete est appelé plusieurs fois.
   */
  private static Set<Id> processedAfterDeleteIds = new Set<Id>();

  // ========================================
  // MÉTHODES D'AIDE ANTI-RÉCURSION
  // ========================================

  /**
   * @description Vérifier si un enregistrement a déjà été traité dans le contexte actuel.
   * @param recordId ID à vérifier
   * @param processedIds Ensemble des IDs déjà traités pour ce contexte
   * @return true si l'enregistrement a déjà été traité (ignorer), false si nouveau
   */
  private static Boolean isAlreadyProcessed(Id recordId, Set<Id> processedIds) {
    return processedIds.contains(recordId);
  }

  /**
   * @description Marquer un enregistrement comme traité dans le contexte actuel.
   * @param recordId ID à marquer comme traité
   * @param processedIds Ensemble auquel ajouter l'ID
   */
  private static void markAsProcessed(Id recordId, Set<Id> processedIds) {
    processedIds.add(recordId);
  }

  /**
   * @description Marquer plusieurs enregistrements comme traités dans le contexte actuel.
   * @param recordIds IDs à marquer comme traités
   * @param processedIds Ensemble auquel ajouter les IDs
   */
  private static void markMultipleAsProcessed(List<Id> recordIds, Set<Id> processedIds) {
    processedIds.addAll(recordIds);
  }

  /**
   * @description Effacer les enregistrements traités pour le contexte actuel (rarement nécessaire, mais disponible).
   * À utiliser avec prudence - généralement réinitialisé par transaction.
   * @param processedIds Ensemble à effacer
   */
  private static void clearProcessed(Set<Id> processedIds) {
    processedIds.clear();
  }

  // ========================================
  // CONTRÔLES DE BYPASS D'AUTOMATION
  // ========================================

  /**
   * @description Vérifier si l'automation doit être contournée pour l'utilisateur actuel.
   * Teste les custom permissions dans l'ordre de priorité :
   * 1. Bypass_All_Automation (désactive TOUS les déclencheurs)
   * 2. Bypass_WorkItem_Automation (désactive SEULEMENT les déclencheurs WorkItem)
   * @return true si le bypass est activé, false sinon
   */
  private static Boolean shouldBypassAutomation() {
    // Vérifier permission globale en premier (priorité élevée)
    if (FeatureManagement.checkPermission('Bypass_All_Automation')) {
      LOGGER.warn(
        'shouldBypassAutomation',
        'Automation bypassed (Global) for user: ' + UserInfo.getUserName() + 
        ' | Profile: ' + UserInfo.getProfileId()
      );
      return true;
    }

    // Vérifier permission spécifique WorkItem
    if (FeatureManagement.checkPermission('Bypass_WorkItem_Automation')) {
      LOGGER.warn(
        'shouldBypassAutomation',
        'Automation bypassed (WorkItem) for user: ' + UserInfo.getUserName() + 
        ' | Profile: ' + UserInfo.getProfileId()
      );
      return true;
    }

    return false;
  }

  /**
   * @description Gérer les événements avant insertion.
   * @param newRecords Enregistrements en cours d'insertion
   *
   * Anti-Récursion : Trace les IDs traités dans le contexte beforeInsert.
   * Si le même enregistrement est traité deux fois dans beforeInsert,
   * le deuxième appel sera ignoré.
   */
  public static void handleBeforeInsert(List<Work_Item__c> newRecords) {
    try {
      // ✅ VÉRIFIER LE BYPASS GLOBAL EN PREMIER
      if (shouldBypassAutomation()) {
        return;
      }

      LOGGER.info('handleBeforeInsert', 'Traitement de ' + newRecords.size() + ' enregistrements');

      // Filtrer les enregistrements déjà traités pour prévenir la récursion
      List<Work_Item__c> recordsToProcess = new List<Work_Item__c>();
      for (Work_Item__c record : newRecords) {
        if (!isAlreadyProcessed(record.Id, processedBeforeInsertIds)) {
          recordsToProcess.add(record);
          markAsProcessed(record.Id, processedBeforeInsertIds);
        }
      }

      if (recordsToProcess.isEmpty()) {
        LOGGER.debug('handleBeforeInsert', 'Tous les enregistrements ont déjà été traités dans ce contexte, ignorant');
        return;
      }

      LOGGER.debug(
        'handleBeforeInsert',
        'Traitement de ' + recordsToProcess.size() + ' nouveaux enregistrements (filtrés sur ' + newRecords.size() + ')'
      );

      // TODO : Implémenter la logique avant insertion en utilisant recordsToProcess
    } catch (Exception e) {
      LOGGER.error('handleBeforeInsert', 'Erreur pendant l\'insertion', e);
      throw e;
    }
  }

  /**
   * @description Gérer les événements après insertion.
   * @param newRecords Enregistrements en cours d'insertion
   *
   * Anti-Récursion : Trace les IDs traités dans le contexte afterInsert.
   * Si la logique dans ce gestionnaire met à jour des éléments de travail, l'appel du déclencheur récursif
   * sera bloqué en vérifiant processedAfterInsertIds.
   */
  public static void handleAfterInsert(List<Work_Item__c> newRecords) {
    try {
      // ✅ VÉRIFIER LE BYPASS GLOBAL EN PREMIER
      if (shouldBypassAutomation()) {
        return;
      }

      LOGGER.info('handleAfterInsert', 'Traitement de ' + newRecords.size() + ' enregistrements');

      // Filtrer les enregistrements déjà traités pour prévenir la récursion
      List<Work_Item__c> recordsToProcess = new List<Work_Item__c>();
      for (Work_Item__c record : newRecords) {
        if (!isAlreadyProcessed(record.Id, processedAfterInsertIds)) {
          recordsToProcess.add(record);
          markAsProcessed(record.Id, processedAfterInsertIds);
        }
      }

      if (recordsToProcess.isEmpty()) {
        LOGGER.debug('handleAfterInsert', 'Tous les enregistrements ont déjà été traités dans ce contexte, ignorant');
        return;
      }

      LOGGER.debug(
        'handleAfterInsert',
        'Traitement de ' + recordsToProcess.size() + ' nouveaux enregistrements (filtrés sur ' + newRecords.size() + ')'
      );

      // TODO : Implémenter la logique après insertion en utilisant recordsToProcess
      // Exemple : Créer des enregistrements associés, publier des événements de plateforme, etc.
    } catch (Exception e) {
      LOGGER.error('handleAfterInsert', 'Erreur après insertion', e);
      throw e;
    }
  }

  /**
   * @description Gérer les événements avant mise à jour.
   * @param newRecords Enregistrements en cours de mise à jour
   * @param oldRecords Valeurs précédentes des enregistrements
   * @param newMap Carte des nouveaux enregistrements (Id -> Enregistrement)
   * @param oldMap Carte des anciens enregistrements (Id -> Enregistrement)
   *
   * Anti-Récursion : Trace les IDs traités dans le contexte beforeUpdate.
   * Si le même enregistrement est mis à jour plusieurs fois dans la même transaction,
   * seule la première mise à jour via beforeUpdate sera traitée.
   */
  public static void handleBeforeUpdate(
    List<Work_Item__c> newRecords,
    List<Work_Item__c> oldRecords,
    Map<Id, Work_Item__c> newMap,
    Map<Id, Work_Item__c> oldMap
  ) {
    try {
      // ✅ VÉRIFIER LE BYPASS GLOBAL EN PREMIER
      if (shouldBypassAutomation()) {
        return;
      }

      LOGGER.info('handleBeforeUpdate', 'Traitement de ' + newRecords.size() + ' enregistrements');

      // Filtrer les enregistrements déjà traités pour prévenir la récursion
      List<Work_Item__c> recordsToProcess = new List<Work_Item__c>();
      for (Work_Item__c record : newRecords) {
        if (!isAlreadyProcessed(record.Id, processedBeforeUpdateIds)) {
          recordsToProcess.add(record);
          markAsProcessed(record.Id, processedBeforeUpdateIds);
        }
      }

      if (recordsToProcess.isEmpty()) {
        LOGGER.debug('handleBeforeUpdate', 'Tous les enregistrements ont déjà été traités dans ce contexte, ignorant');
        return;
      }

      LOGGER.debug(
        'handleBeforeUpdate',
        'Traitement de ' + recordsToProcess.size() + ' nouveaux enregistrements (filtrés sur ' + newRecords.size() + ')'
      );

      // TODO : Implémenter la logique avant mise à jour en utilisant recordsToProcess
    } catch (Exception e) {
      LOGGER.error('handleBeforeUpdate', 'Erreur avant mise à jour', e);
      throw e;
    }
  }

  /**
   * @description Gérer les événements après mise à jour.
   * @param newRecords Enregistrements en cours de mise à jour
   * @param oldRecords Valeurs précédentes des enregistrements
   * @param newMap Carte des nouveaux enregistrements (Id -> Enregistrement)
   * @param oldMap Carte des anciens enregistrements (Id -> Enregistrement)
   *
   * Anti-Récursion : Trace les IDs traités dans le contexte afterUpdate.
   * Si ce gestionnaire publie des événements ou met à jour des enregistrements associés,
   * qui déclenche ensuite une autre mise à jour, cet ID d'enregistrement se trouvera dans
   * processedAfterUpdateIds et sera ignoré lors de la rentrée.
   */
  public static void handleAfterUpdate(
    List<Work_Item__c> newRecords,
    List<Work_Item__c> oldRecords,
    Map<Id, Work_Item__c> newMap,
    Map<Id, Work_Item__c> oldMap
  ) {
    try {
      // ✅ VÉRIFIER LE BYPASS GLOBAL EN PREMIER
      if (shouldBypassAutomation()) {
        return;
      }

      LOGGER.info('handleAfterUpdate', 'Traitement de ' + newRecords.size() + ' enregistrements');

      // Filtrer les enregistrements déjà traités pour prévenir la récursion
      List<Work_Item__c> recordsToProcess = new List<Work_Item__c>();
      for (Work_Item__c record : newRecords) {
        if (!isAlreadyProcessed(record.Id, processedAfterUpdateIds)) {
          recordsToProcess.add(record);
          markAsProcessed(record.Id, processedAfterUpdateIds);
        }
      }

      if (recordsToProcess.isEmpty()) {
        LOGGER.debug('handleAfterUpdate', 'Tous les enregistrements ont déjà été traités dans ce contexte, ignorant');
        return;
      }

      LOGGER.debug(
        'handleAfterUpdate',
        'Traitement de ' + recordsToProcess.size() + ' nouveaux enregistrements (filtrés sur ' + newRecords.size() + ')'
      );

      // TODO : Implémenter la logique après mise à jour en utilisant recordsToProcess
      // Exemple : Mettre à jour des enregistrements associés, publier des événements, envoyer des notifications, etc.
    } catch (Exception e) {
      LOGGER.error('handleAfterUpdate', 'Erreur après mise à jour', e);
      throw e;
    }
  }

  /**
   * @description Gérer les événements avant suppression.
   * @param oldRecords Enregistrements en cours de suppression
   *
   * Anti-Récursion : Trace les IDs traités dans le contexte beforeDelete.
   * Prévient le re-traitement de la même suppression si elle est déclenchée à nouveau.
   */
  public static void handleBeforeDelete(List<Work_Item__c> oldRecords) {
    try {
      // ✅ VÉRIFIER LE BYPASS GLOBAL EN PREMIER
      if (shouldBypassAutomation()) {
        return;
      }

      LOGGER.info('handleBeforeDelete', 'Traitement de ' + oldRecords.size() + ' enregistrements');

      // Filtrer les enregistrements déjà traités pour prévenir la récursion
      List<Work_Item__c> recordsToProcess = new List<Work_Item__c>();
      for (Work_Item__c record : oldRecords) {
        if (!isAlreadyProcessed(record.Id, processedBeforeDeleteIds)) {
          recordsToProcess.add(record);
          markAsProcessed(record.Id, processedBeforeDeleteIds);
        }
      }

      if (recordsToProcess.isEmpty()) {
        LOGGER.debug('handleBeforeDelete', 'Tous les enregistrements ont déjà été traités dans ce contexte, ignorant');
        return;
      }

      LOGGER.debug(
        'handleBeforeDelete',
        'Traitement de ' + recordsToProcess.size() + ' nouveaux enregistrements (filtrés sur ' + oldRecords.size() + ')'
      );

      // TODO : Implémenter la logique avant suppression en utilisant recordsToProcess
    } catch (Exception e) {
      LOGGER.error('handleBeforeDelete', 'Erreur avant suppression', e);
      throw e;
    }
  }

  /**
   * @description Gérer les événements après suppression.
   * @param oldRecords Enregistrements qui ont été supprimés
   *
   * Anti-Récursion : Trace les IDs traités dans le contexte afterDelete.
   * Prévient le re-traitement si les suppressions associées ou les mises à jour déclenchent le même gestionnaire.
   */
  public static void handleAfterDelete(List<Work_Item__c> oldRecords) {
    try {
      // ✅ VÉRIFIER LE BYPASS GLOBAL EN PREMIER
      if (shouldBypassAutomation()) {
        return;
      }

      LOGGER.info('handleAfterDelete', 'Traitement de ' + oldRecords.size() + ' enregistrements');

      // Filtrer les enregistrements déjà traités pour prévenir la récursion
      List<Work_Item__c> recordsToProcess = new List<Work_Item__c>();
      for (Work_Item__c record : oldRecords) {
        if (!isAlreadyProcessed(record.Id, processedAfterDeleteIds)) {
          recordsToProcess.add(record);
          markAsProcessed(record.Id, processedAfterDeleteIds);
        }
      }

      if (recordsToProcess.isEmpty()) {
        LOGGER.debug('handleAfterDelete', 'Tous les enregistrements ont déjà été traités dans ce contexte, ignorant');
        return;
      }

      LOGGER.debug(
        'handleAfterDelete',
        'Traitement de ' + recordsToProcess.size() + ' nouveaux enregistrements (filtrés sur ' + oldRecords.size() + ')'
      );

      // TODO : Implémenter la logique après suppression en utilisant recordsToProcess
      // Exemple : Nettoyage, enregistrement d'audit, suppressions en cascade, etc.
    } catch (Exception e) {
      LOGGER.error('handleAfterDelete', 'Erreur après suppression', e);
      throw e;
    }
  }
}
