/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Gestionnaire de trigger pour Work_Item__c.
 * Centralise toute la logique métier des triggers avec logging et gestion d'erreurs.
 * Respecte le principe de séparation des préoccupations (SoC).
 */
public with sharing class WorkItemTriggerHandler {
  private static final Logger LOGGER = LoggerFactory.getLogger(
    'WorkItemTriggerHandler'
  );

  /**
   * @description Vérifie si l'automation doit être bypassée.
   * Vérifie les Custom Permissions et Feature Flags.
   * @return true si l'automation est désactivée
   */
  private static Boolean shouldBypass() {
    // Vérifier Custom Permission globale
    if (FeatureFlag.hasPermission('Bypass_All_Automation')) {
      LOGGER.debug(
        'shouldBypass',
        'Bypass ALL automation via Custom Permission'
      );
      return true;
    }

    // Vérifier Custom Permission spécifique WorkItem
    if (FeatureFlag.hasPermission('Bypass_Work_Item_Automation')) {
      LOGGER.debug(
        'shouldBypass',
        'Bypass WorkItem automation via Custom Permission'
      );
      return true;
    }

    // Vérifier Feature Flag
    if (FeatureFlags.disableAutomation()) {
      LOGGER.debug('shouldBypass', 'Bypass automation via Feature Flag');
      return true;
    }

    return false;
  }

  /**
   * @description Gère l'événement beforeInsert.
   * Applique les valeurs par défaut et valide les enregistrements.
   * @param newRecords Liste des nouveaux enregistrements
   */
  public static void handleBeforeInsert(List<Work_Item__c> newRecords) {
    if (shouldBypass()) {
      LOGGER.info(
        'handleBeforeInsert',
        'Automation bypassée pour ' + newRecords.size() + ' enregistrements'
      );
      return;
    }

    try {
      LOGGER.info(
        'handleBeforeInsert',
        'Début du traitement de ' + newRecords.size() + ' enregistrements'
      );

      // Appliquer les valeurs par défaut
      WorkItemDomain.populateDefaults(newRecords);
      LOGGER.debug(
        'handleBeforeInsert',
        'Valeurs par défaut appliquées à ' + newRecords.size() + ' enregistrements'
      );

      // Valider les enregistrements
      List<String> errors = WorkItemDomain.validate(newRecords);
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, '; ');
        LOGGER.warn('handleBeforeInsert', 'Erreurs de validation : ' + errorMessage);

        // Ajouter l'erreur au premier enregistrement
        newRecords[0].addError(errorMessage);
      }

      LOGGER.info(
        'handleBeforeInsert',
        'Traitement terminé avec succès pour ' + newRecords.size() + ' enregistrements'
      );
    } catch (Exception e) {
      LOGGER.error(
        'handleBeforeInsert',
        'Erreur pendant le traitement beforeInsert',
        e
      );
      throw e;
    }
  }

  /**
   * @description Gère l'événement beforeUpdate.
   * Valide les enregistrements et applique les règles métier.
   * @param newRecords Liste des nouveaux enregistrements
   * @param oldRecords Liste des anciens enregistrements
   * @param newMap Map des nouveaux enregistrements par Id
   * @param oldMap Map des anciens enregistrements par Id
   */
  public static void handleBeforeUpdate(
    List<Work_Item__c> newRecords,
    List<Work_Item__c> oldRecords,
    Map<Id, Work_Item__c> newMap,
    Map<Id, Work_Item__c> oldMap
  ) {
    if (shouldBypass()) {
      LOGGER.info(
        'handleBeforeUpdate',
        'Automation bypassée pour ' + newRecords.size() + ' enregistrements'
      );
      return;
    }

    try {
      LOGGER.info(
        'handleBeforeUpdate',
        'Début du traitement de ' + newRecords.size() + ' enregistrements'
      );

      // Valider les enregistrements
      List<String> errors = WorkItemDomain.validate(newRecords);
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, '; ');
        LOGGER.warn('handleBeforeUpdate', 'Erreurs de validation : ' + errorMessage);

        // Ajouter l'erreur au premier enregistrement
        newRecords[0].addError(errorMessage);
      }

      // Appliquer les règles métier (ex: remplir Completed_On si Done)
      WorkItemDomain.applyBusinessRules(newRecords, oldMap);
      LOGGER.debug(
        'handleBeforeUpdate',
        'Règles métier appliquées à ' + newRecords.size() + ' enregistrements'
      );

      LOGGER.info(
        'handleBeforeUpdate',
        'Traitement terminé avec succès pour ' + newRecords.size() + ' enregistrements'
      );
    } catch (Exception e) {
      LOGGER.error(
        'handleBeforeUpdate',
        'Erreur pendant le traitement beforeUpdate',
        e
      );
      throw e;
    }
  }

  /**
   * @description Gère l'événement beforeDelete.
   * Empêche la suppression des Work Items avec statut "Done".
   * @param oldRecords Liste des enregistrements à supprimer
   * @param oldMap Map des enregistrements à supprimer par Id
   */
  public static void handleBeforeDelete(
    List<Work_Item__c> oldRecords,
    Map<Id, Work_Item__c> oldMap
  ) {
    if (shouldBypass()) {
      LOGGER.info(
        'handleBeforeDelete',
        'Automation bypassée pour ' + oldRecords.size() + ' enregistrements'
      );
      return;
    }

    try {
      LOGGER.info(
        'handleBeforeDelete',
        'Début du traitement de ' + oldRecords.size() + ' enregistrements'
      );

      // Empêcher la suppression des Work Items terminés
      for (Work_Item__c oldRecord : oldRecords) {
        if (oldRecord.Status__c == 'Done') {
          String errorMessage =
            'Impossible de supprimer un élément de travail terminé. ' +
            'Veuillez d\'abord changer le statut.';
          LOGGER.warn(
            'handleBeforeDelete',
            'Tentative de suppression d\'un Work Item Done : ' + oldRecord.Id
          );
          oldRecord.addError(errorMessage);
        }
      }

      LOGGER.info(
        'handleBeforeDelete',
        'Traitement terminé avec succès pour ' + oldRecords.size() + ' enregistrements'
      );
    } catch (Exception e) {
      LOGGER.error(
        'handleBeforeDelete',
        'Erreur pendant le traitement beforeDelete',
        e
      );
      throw e;
    }
  }

  /**
   * @description Gère l'événement afterInsert.
   * Peut être utilisé pour des actions asynchrones ou notifications.
   * @param newRecords Liste des nouveaux enregistrements
   * @param newMap Map des nouveaux enregistrements par Id
   */
  public static void handleAfterInsert(
    List<Work_Item__c> newRecords,
    Map<Id, Work_Item__c> newMap
  ) {
    if (shouldBypass()) {
      LOGGER.info(
        'handleAfterInsert',
        'Automation bypassée pour ' + newRecords.size() + ' enregistrements'
      );
      return;
    }

    try {
      LOGGER.info(
        'handleAfterInsert',
        'Début du traitement de ' + newRecords.size() + ' enregistrements'
      );

      // Logique future : notifications, intégrations, etc.
      // Pour l'instant, juste du logging
      for (Work_Item__c record : newRecords) {
        LOGGER.debug(
          'handleAfterInsert',
          'Work Item créé : ' +
          record.Name +
          ' avec statut ' +
          record.Status__c
        );
      }

      LOGGER.info(
        'handleAfterInsert',
        'Traitement terminé avec succès pour ' + newRecords.size() + ' enregistrements'
      );
    } catch (Exception e) {
      LOGGER.error(
        'handleAfterInsert',
        'Erreur pendant le traitement afterInsert',
        e
      );
      // Ne pas re-throw pour éviter de bloquer l'insertion
      // Les erreurs sont loguées
    }
  }

  /**
   * @description Gère l'événement afterUpdate.
   * Peut être utilisé pour des actions asynchrones ou notifications.
   * @param newRecords Liste des nouveaux enregistrements
   * @param oldRecords Liste des anciens enregistrements
   * @param newMap Map des nouveaux enregistrements par Id
   * @param oldMap Map des anciens enregistrements par Id
   */
  public static void handleAfterUpdate(
    List<Work_Item__c> newRecords,
    List<Work_Item__c> oldRecords,
    Map<Id, Work_Item__c> newMap,
    Map<Id, Work_Item__c> oldMap
  ) {
    if (shouldBypass()) {
      LOGGER.info(
        'handleAfterUpdate',
        'Automation bypassée pour ' + newRecords.size() + ' enregistrements'
      );
      return;
    }

    try {
      LOGGER.info(
        'handleAfterUpdate',
        'Début du traitement de ' + newRecords.size() + ' enregistrements'
      );

      // Détecter les changements de statut
      for (Work_Item__c newRecord : newRecords) {
        Work_Item__c oldRecord = oldMap.get(newRecord.Id);
        if (newRecord.Status__c != oldRecord.Status__c) {
          LOGGER.info(
            'handleAfterUpdate',
            'Changement de statut pour ' +
            newRecord.Name +
            ' : ' +
            oldRecord.Status__c +
            ' → ' +
            newRecord.Status__c
          );
        }
      }

      LOGGER.info(
        'handleAfterUpdate',
        'Traitement terminé avec succès pour ' + newRecords.size() + ' enregistrements'
      );
    } catch (Exception e) {
      LOGGER.error(
        'handleAfterUpdate',
        'Erreur pendant le traitement afterUpdate',
        e
      );
      // Ne pas re-throw pour éviter de bloquer la mise à jour
    }
  }

  /**
   * @description Gère l'événement afterDelete.
   * Peut être utilisé pour du nettoyage ou des notifications.
   * @param oldRecords Liste des enregistrements supprimés
   * @param oldMap Map des enregistrements supprimés par Id
   */
  public static void handleAfterDelete(
    List<Work_Item__c> oldRecords,
    Map<Id, Work_Item__c> oldMap
  ) {
    if (shouldBypass()) {
      LOGGER.info(
        'handleAfterDelete',
        'Automation bypassée pour ' + oldRecords.size() + ' enregistrements'
      );
      return;
    }

    try {
      LOGGER.info(
        'handleAfterDelete',
        'Début du traitement de ' + oldRecords.size() + ' enregistrements'
      );

      // Logique future : nettoyage, notifications, etc.
      for (Work_Item__c record : oldRecords) {
        LOGGER.info('handleAfterDelete', 'Work Item supprimé : ' + record.Name);
      }

      LOGGER.info(
        'handleAfterDelete',
        'Traitement terminé avec succès pour ' + oldRecords.size() + ' enregistrements'
      );
    } catch (Exception e) {
      LOGGER.error(
        'handleAfterDelete',
        'Erreur pendant le traitement afterDelete',
        e
      );
      // Ne pas re-throw
    }
  }

  /**
   * @description Gère l'événement afterUndelete.
   * Peut être utilisé pour restaurer des données liées.
   * @param restoredRecords Liste des enregistrements restaurés
   * @param restoredMap Map des enregistrements restaurés par Id
   */
  public static void handleAfterUndelete(
    List<Work_Item__c> restoredRecords,
    Map<Id, Work_Item__c> restoredMap
  ) {
    if (shouldBypass()) {
      LOGGER.info(
        'handleAfterUndelete',
        'Automation bypassée pour ' + restoredRecords.size() + ' enregistrements'
      );
      return;
    }

    try {
      LOGGER.info(
        'handleAfterUndelete',
        'Début du traitement de ' +
        restoredRecords.size() +
        ' enregistrements'
      );

      // Logique future : restauration de données liées
      for (Work_Item__c record : restoredRecords) {
        LOGGER.info(
          'handleAfterUndelete',
          'Work Item restauré : ' + record.Name
        );
      }

      LOGGER.info(
        'handleAfterUndelete',
        'Traitement terminé avec succès pour ' +
        restoredRecords.size() +
        ' enregistrements'
      );
    } catch (Exception e) {
      LOGGER.error(
        'handleAfterUndelete',
        'Erreur pendant le traitement afterUndelete',
        e
      );
      // Ne pas re-throw
    }
  }
}
