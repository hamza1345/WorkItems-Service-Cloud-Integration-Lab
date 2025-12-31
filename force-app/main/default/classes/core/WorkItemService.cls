/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Service pour Work_Item__c.
 * Orchestre la logique métier en utilisant Selector + Domain.
 * Gère les transactions, validations, et logging.
 */
public with sharing class WorkItemService {
  private static final Logger LOGGER = LoggerFactory.getLogger(
    'WorkItemService'
  );

  // Constantes pour limites par défaut
  private static final Integer DEFAULT_LIMIT = 50;
  private static final Integer MAX_LIMIT = 100;

  /**
   * @description Récupère les Work Items avec filtres UI/API.
   * Délègue à WorkItemSelector.search() pour centralisertous les SOQL.
   * 
   * @param status Filtre par statut (optionnel)
   * @param searchTerm Recherche texte (optionnel)
   * @param limitSize Nombre max de résultats (null = DEFAULT_LIMIT)
   * @return List<Work_Item__c> limitée et triée
   */
  public static List<Work_Item__c> getItems(
    String status,
    String searchTerm,
    Integer limitSize
  ) {
    try {
      LOGGER.info(
        'getItems',
        'Récupération Work Items - Status: ' + status + 
        ', Search: ' + searchTerm + 
        ', Limit: ' + limitSize
      );

      // Normaliser limitSize
      if (limitSize == null || limitSize <= 0) {
        limitSize = DEFAULT_LIMIT;
      }
      if (limitSize > MAX_LIMIT) {
        limitSize = MAX_LIMIT;
      }

      // Déléguer au Selector
      List<Work_Item__c> results = WorkItemSelector.search(status, searchTerm, limitSize);

      LOGGER.info('getItems', results.size() + ' Work Items récupérés');
      return results;
    } catch (Exception e) {
      LOGGER.error('getItems', 'Erreur lors de la récupération Work Items', e);
      throw e;
    }
  }

  /**
   * @description Sauvegarde un Work Item (insert ou update).
   * Laisse Trigger/Domain appliquer les règles métier et valeurs par défaut.
   * Gère les exceptions proprement.
   * 
   * @param item Work_Item__c à sauvegarder (avec ou sans Id)
   * @return Work_Item__c sauvegardé avec tous les champs
   */
  public static Work_Item__c saveItem(Work_Item__c item) {
    if (item == null) {
      String errorMessage = 'Work Item ne peut pas être null';
      LOGGER.error('saveItem', errorMessage);
      throw new IllegalArgumentException(errorMessage);
    }

    try {
      Boolean isInsert = (item.Id == null);
      String operation = isInsert ? 'INSERT' : 'UPDATE';

      LOGGER.info(
        'saveItem',
        operation + ' Work Item: ' + item.Name + ' (Id: ' + item.Id + ')'
      );

      // Insert ou Update (Trigger/Domain gèrent règles + validations)
      if (isInsert) {
        insert item;
        LOGGER.info('saveItem', 'Work Item inséré avec succès: ' + item.Id);
      } else {
        update item;
        LOGGER.info('saveItem', 'Work Item mis à jour avec succès: ' + item.Id);
      }

      // Récupérer l'enregistrement complet
      return WorkItemSelector.getById(item.Id);
    } catch (DmlException e) {
      LOGGER.error('saveItem', 'Erreur DML lors de la sauvegarde', e);
      throw e; // Re-throw pour que l'appelant puisse gérer
    } catch (Exception e) {
      LOGGER.error('saveItem', 'Erreur lors de la sauvegarde Work Item', e);
      throw e;
    }
  }

  /**
   * @description Marque un Work Item comme Done (terminé).
   * Récupère via Selector, set Status=Done, update (Trigger applique Completed_On + guards).
   * 
   * @param workItemId Id du Work Item à marquer comme Done
   * @return Work_Item__c mis à jour
   */
  public static Work_Item__c markDone(Id workItemId) {
    if (workItemId == null) {
      String errorMessage = 'Work Item Id ne peut pas être null';
      LOGGER.error('markDone', errorMessage);
      throw new IllegalArgumentException(errorMessage);
    }

    try {
      LOGGER.info('markDone', 'Marquage comme Done: ' + workItemId);

      // Récupérer via Selector (pas de SOQL direct)
      Work_Item__c item = WorkItemSelector.getById(workItemId);
      if (item == null) {
        String errorMessage = 'Work Item non trouvé: ' + workItemId;
        LOGGER.error('markDone', errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Set Status=Done
      item.Status__c = 'Done';

      // Update (Trigger/Domain appliquent Completed_On + validations)
      update item;

      LOGGER.info('markDone', 'Work Item marqué comme Done avec succès: ' + workItemId);

      // Enqueue sync externe (si activé)
      enqueueExternalSync(new Set<Id>{ workItemId });

      // Récupérer l'enregistrement complet
      return WorkItemSelector.getById(workItemId);
    } catch (DmlException e) {
      LOGGER.error('markDone', 'Erreur DML lors du marquage Done', e);
      throw e;
    } catch (Exception e) {
      LOGGER.error('markDone', 'Erreur lors du marquage Done', e);
      throw e;
    }
  }

  /**
   * @description Enqueue la synchronisation externe des Work Items (stub).
   * Vérifie FeatureFlags.disableExternalSync() avant d'enqueuer.
   * Implémentation Queueable viendra Jour 10.
   * 
   * @param workItemIds Set des Ids à synchroniser
   */
  public static void enqueueExternalSync(Set<Id> workItemIds) {
    if (workItemIds == null || workItemIds.isEmpty()) {
      LOGGER.debug('enqueueExternalSync', 'Set d\'Ids vide, aucune sync');
      return;
    }

    try {
      // Vérifier Feature Flag
      if (FeatureFlags.disableExternalSync()) {
        LOGGER.warn(
          'enqueueExternalSync',
          'Sync externe désactivée via Feature Flag pour ' + workItemIds.size() + ' items'
        );
        return;
      }

      // TODO Jour 10: Implémenter Queueable WorkItemSyncJob
      LOGGER.info(
        'enqueueExternalSync',
        'Stub: Sync externe enqueueée pour ' + workItemIds.size() + ' items (pas encore implémentée)'
      );

      // Placeholder pour Queueable
      // System.enqueueJob(new WorkItemSyncJob(workItemIds));
    } catch (Exception e) {
      LOGGER.error('enqueueExternalSync', 'Erreur lors de l\'enqueue sync externe', e);
      // Ne pas re-throw pour éviter de bloquer le flow principal
    }
  }

  /**
   * @description Crée un nouveau Work Item avec validation et valeurs par défaut.
   * @param name Nom du Work Item
   * @param description Description
   * @param category Catégorie
   * @param priority Priorité
   * @param dueDate Date d'échéance
   * @return Work_Item__c créé avec Id
   * @throws DmlException si l'insertion échoue
   */
  public static Work_Item__c createWorkItem(
    String name,
    String description,
    String category,
    String priority,
    Date dueDate
  ) {
    try {
      LOGGER.info('createWorkItem', 'Création d\'un nouveau Work Item : ' + name);

      // Créer l'objet
      Work_Item__c newItem = new Work_Item__c(
        Name = name,
        Description__c = description,
        Category__c = category,
        Priority__c = priority,
        Due_Date__c = dueDate
      );

      // Appliquer les valeurs par défaut
      List<Work_Item__c> itemsList = new List<Work_Item__c>{ newItem };
      WorkItemDomain.populateDefaults(itemsList);

      // Valider
      List<String> errors = WorkItemDomain.validate(itemsList);
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, '; ');
        LOGGER.error('createWorkItem', 'Validation échouée : ' + errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Insérer
      insert newItem;
      LOGGER.info('createWorkItem', 'Work Item créé avec succès : ' + newItem.Id);

      // Récupérer avec tous les champs
      return WorkItemSelector.getById(newItem.Id);
    } catch (DmlException e) {
      LOGGER.error('createWorkItem', 'Erreur DML lors de la création', e);
      throw e;
    } catch (Exception e) {
      LOGGER.error('createWorkItem', 'Erreur lors de la création', e);
      throw e;
    }
  }

  /**
   * @description Crée un Work Item avec External_Id pour intégration.
   * @param name Nom du Work Item
   * @param description Description
   * @param externalId Id externe du système source
   * @return Work_Item__c créé avec Id
   */
  public static Work_Item__c createWorkItemWithExternalId(
    String name,
    String description,
    String externalId
  ) {
    try {
      LOGGER.info(
        'createWorkItemWithExternalId',
        'Création Work Item avec External_Id : ' + externalId
      );

      // Vérifier si l'External_Id existe déjà
      Work_Item__c existing = WorkItemSelector.getByExternalId(externalId);
      if (existing != null) {
        String errorMessage =
          'Un Work Item avec External_Id ' +
          externalId +
          ' existe déjà : ' +
          existing.Name;
        LOGGER.warn('createWorkItemWithExternalId', errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Créer l'objet
      Work_Item__c newItem = new Work_Item__c(
        Name = name,
        Description__c = description,
        External_Id__c = externalId
      );

      // Appliquer les valeurs par défaut
      List<Work_Item__c> itemsList = new List<Work_Item__c>{ newItem };
      WorkItemDomain.populateDefaults(itemsList);

      // Valider
      List<String> errors = WorkItemDomain.validate(itemsList);
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, '; ');
        LOGGER.error(
          'createWorkItemWithExternalId',
          'Validation échouée : ' + errorMessage
        );
        throw new WorkItemServiceException(errorMessage);
      }

      // Insérer
      insert newItem;
      LOGGER.info(
        'createWorkItemWithExternalId',
        'Work Item créé avec succès : ' + newItem.Id
      );

      return WorkItemSelector.getById(newItem.Id);
    } catch (DmlException e) {
      LOGGER.error(
        'createWorkItemWithExternalId',
        'Erreur DML lors de la création',
        e
      );
      throw e;
    } catch (Exception e) {
      LOGGER.error('createWorkItemWithExternalId', 'Erreur lors de la création', e);
      throw e;
    }
  }

  /**
   * @description Met à jour un Work Item existant.
   * @param workItemId Id du Work Item à mettre à jour
   * @param updates Map des champs à mettre à jour
   * @return Work_Item__c mis à jour
   * @throws WorkItemServiceException si le Work Item n'existe pas
   */
  public static Work_Item__c updateWorkItem(
    Id workItemId,
    Map<String, Object> updates
  ) {
    try {
      LOGGER.info('updateWorkItem', 'Mise à jour Work Item : ' + workItemId);

      // Récupérer le Work Item
      Work_Item__c item = WorkItemSelector.getById(workItemId);
      if (item == null) {
        String errorMessage = 'Work Item non trouvé : ' + workItemId;
        LOGGER.error('updateWorkItem', errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Appliquer les mises à jour
      for (String fieldName : updates.keySet()) {
        item.put(fieldName, updates.get(fieldName));
      }

      // Valider
      List<Work_Item__c> itemsList = new List<Work_Item__c>{ item };
      List<String> errors = WorkItemDomain.validate(itemsList);
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, '; ');
        LOGGER.error('updateWorkItem', 'Validation échouée : ' + errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Mettre à jour
      update item;
      LOGGER.info('updateWorkItem', 'Work Item mis à jour avec succès');

      return WorkItemSelector.getById(workItemId);
    } catch (DmlException e) {
      LOGGER.error('updateWorkItem', 'Erreur DML lors de la mise à jour', e);
      throw e;
    } catch (Exception e) {
      LOGGER.error('updateWorkItem', 'Erreur lors de la mise à jour', e);
      throw e;
    }
  }

  /**
   * @description Change le statut d'un Work Item.
   * @param workItemId Id du Work Item
   * @param newStatus Nouveau statut
   * @return Work_Item__c mis à jour
   */
  public static Work_Item__c updateStatus(Id workItemId, String newStatus) {
    try {
      LOGGER.info(
        'updateStatus',
        'Changement statut pour ' + workItemId + ' vers ' + newStatus
      );

      // Récupérer le Work Item
      Work_Item__c item = WorkItemSelector.getById(workItemId);
      if (item == null) {
        String errorMessage = 'Work Item non trouvé : ' + workItemId;
        LOGGER.error('updateStatus', errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      String oldStatus = item.Status__c;

      // Vérifier la transition de statut
      if (!WorkItemDomain.isStatusTransitionValid(oldStatus, newStatus)) {
        String errorMessage =
          'Transition de statut invalide : ' +
          oldStatus +
          ' → ' +
          newStatus;
        LOGGER.warn('updateStatus', errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Changer le statut
      item.Status__c = newStatus;

      // Valider et appliquer les règles métier
      Map<Id, Work_Item__c> oldMap = new Map<Id, Work_Item__c>();
      oldMap.put(item.Id, new Work_Item__c(Id = item.Id, Status__c = oldStatus));

      List<Work_Item__c> itemsList = new List<Work_Item__c>{ item };
      WorkItemDomain.applyBusinessRules(itemsList, oldMap);

      // Mettre à jour
      update item;
      LOGGER.info(
        'updateStatus',
        'Statut changé avec succès : ' + oldStatus + ' → ' + newStatus
      );

      return WorkItemSelector.getById(workItemId);
    } catch (DmlException e) {
      LOGGER.error('updateStatus', 'Erreur DML lors du changement de statut', e);
      throw e;
    } catch (Exception e) {
      LOGGER.error('updateStatus', 'Erreur lors du changement de statut', e);
      throw e;
    }
  }

  /**
   * @description Marque un Work Item comme terminé (Done).
   * @param workItemId Id du Work Item
   * @return Work_Item__c mis à jour
   */
  public static Work_Item__c completeWorkItem(Id workItemId) {
    try {
      LOGGER.info('completeWorkItem', 'Marquage comme terminé : ' + workItemId);
      return updateStatus(workItemId, 'Done');
    } catch (Exception e) {
      LOGGER.error('completeWorkItem', 'Erreur lors du marquage comme terminé', e);
      throw e;
    }
  }

  /**
   * @description Supprime un Work Item.
   * @param workItemId Id du Work Item à supprimer
   * @throws WorkItemServiceException si le Work Item est Done
   */
  public static void deleteWorkItem(Id workItemId) {
    try {
      LOGGER.info('deleteWorkItem', 'Suppression Work Item : ' + workItemId);

      // Récupérer le Work Item
      Work_Item__c item = WorkItemSelector.getById(workItemId);
      if (item == null) {
        String errorMessage = 'Work Item non trouvé : ' + workItemId;
        LOGGER.error('deleteWorkItem', errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Vérifier le statut
      if (item.Status__c == 'Done') {
        String errorMessage =
          'Impossible de supprimer un Work Item terminé. ' +
          'Veuillez d\'abord changer le statut.';
        LOGGER.warn('deleteWorkItem', errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Supprimer
      delete item;
      LOGGER.info('deleteWorkItem', 'Work Item supprimé avec succès');
    } catch (DmlException e) {
      LOGGER.error('deleteWorkItem', 'Erreur DML lors de la suppression', e);
      throw e;
    } catch (Exception e) {
      LOGGER.error('deleteWorkItem', 'Erreur lors de la suppression', e);
      throw e;
    }
  }

  /**
   * @description Met à jour plusieurs Work Items en masse.
   * @param workItemIds Set des Ids à mettre à jour
   * @param updates Map des champs à mettre à jour (appliquée à tous)
   * @return List<Work_Item__c> mis à jour
   */
  public static List<Work_Item__c> bulkUpdateWorkItems(
    Set<Id> workItemIds,
    Map<String, Object> updates
  ) {
    try {
      LOGGER.info(
        'bulkUpdateWorkItems',
        'Mise à jour en masse de ' + workItemIds.size() + ' Work Items'
      );

      // Récupérer les Work Items
      List<Work_Item__c> items = WorkItemSelector.getByIds(workItemIds);
      if (items.isEmpty()) {
        LOGGER.warn('bulkUpdateWorkItems', 'Aucun Work Item trouvé');
        return new List<Work_Item__c>();
      }

      // Appliquer les mises à jour
      for (Work_Item__c item : items) {
        for (String fieldName : updates.keySet()) {
          item.put(fieldName, updates.get(fieldName));
        }
      }

      // Valider
      List<String> errors = WorkItemDomain.validate(items);
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, '; ');
        LOGGER.error('bulkUpdateWorkItems', 'Validation échouée : ' + errorMessage);
        throw new WorkItemServiceException(errorMessage);
      }

      // Mettre à jour
      update items;
      LOGGER.info(
        'bulkUpdateWorkItems',
        items.size() + ' Work Items mis à jour avec succès'
      );

      return WorkItemSelector.getByIds(workItemIds);
    } catch (DmlException e) {
      LOGGER.error(
        'bulkUpdateWorkItems',
        'Erreur DML lors de la mise à jour en masse',
        e
      );
      throw e;
    } catch (Exception e) {
      LOGGER.error('bulkUpdateWorkItems', 'Erreur lors de la mise à jour en masse', e);
      throw e;
    }
  }

  /**
   * @description Récupère tous les Work Items en retard.
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getOverdueWorkItems() {
    try {
      LOGGER.info('getOverdueWorkItems', 'Récupération des Work Items en retard');
      return WorkItemSelector.getOverdue();
    } catch (Exception e) {
      LOGGER.error(
        'getOverdueWorkItems',
        'Erreur lors de la récupération des Work Items en retard',
        e
      );
      throw e;
    }
  }

  /**
   * @description Récupère tous les Work Items actifs (non terminés).
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getActiveWorkItems() {
    try {
      LOGGER.info('getActiveWorkItems', 'Récupération des Work Items actifs');
      return WorkItemSelector.getAllActiveWorkItems();
    } catch (Exception e) {
      LOGGER.error(
        'getActiveWorkItems',
        'Erreur lors de la récupération des Work Items actifs',
        e
      );
      throw e;
    }
  }

  /**
   * @description Exception personnalisée pour le service.
   */
  public class WorkItemServiceException extends Exception {
  }
}
