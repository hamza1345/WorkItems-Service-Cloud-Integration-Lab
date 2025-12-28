/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Couche de service pour les opérations de Work_Item__c.
 * Responsabilités :
 * - Orchestrer les opérations métier (créer, mettre à jour, supprimer, assigner)
 * - Coordonner entre les couches Métier, Sélecteur et services externes
 * - Gérer la gestion des transactions et la récupération d'erreurs
 * - Implémenter les flux de travail métier complexes
 * - Publier les événements de plateforme pour le traitement asynchrone
 *
 * Cette classe contient les SEULES opérations de base de données (SOQL/DML) pour les éléments de travail.
 * Toutes les requêtes et mises à jour sont déléguées aux méthodes du Sélecteur.
 */
public with sharing class WorkItemService {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemService');

  /**
   * @description Créer un nouvel élément de travail avec validation.
   * @param workItem Élément de travail à créer
   * @return Id de l'élément de travail créé
   */
  public static Id createWorkItem(Work_Item__c workItem) {
    try {
      LOGGER.info('createWorkItem', 'Création de l\'élément de travail : ' + workItem.Name);

      // Valider
      List<String> errors = WorkItemDomain.validate(new List<Work_Item__c>{ workItem });
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, ', ');
        LOGGER.warn('createWorkItem', 'Erreurs de validation : ' + errorMessage);
        throw new IllegalArgumentException(errorMessage);
      }

      // Remplir les valeurs par défaut
      WorkItemDomain.populateDefaults(new List<Work_Item__c>{ workItem });

      // Insérer
      insert workItem;
      LOGGER.info('createWorkItem', 'Élément de travail créé avec l\'Id : ' + workItem.Id);

      return workItem.Id;
    } catch (Exception e) {
      LOGGER.error('createWorkItem', 'Échec de la création de l\'élément de travail', e);
      throw e;
    }
  }

  /**
   * @description Mettre à jour l'élément de travail avec détection des modifications.
   * @param workItem Élément de travail à mettre à jour
   */
  public static void updateWorkItem(Work_Item__c workItem) {
    try {
      LOGGER.info('updateWorkItem', 'Mise à jour de l\'élément de travail : ' + workItem.Id);

      // Valider
      List<String> errors = WorkItemDomain.validate(new List<Work_Item__c>{ workItem });
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, ', ');
        LOGGER.warn('updateWorkItem', 'Erreurs de validation : ' + errorMessage);
        throw new IllegalArgumentException(errorMessage);
      }

      update workItem;
      LOGGER.info('updateWorkItem', 'Élément de travail mis à jour avec succès');
    } catch (Exception e) {
      LOGGER.error('updateWorkItem', 'Échec de la mise à jour de l\'élément de travail', e);
      throw e;
    }
  }

  /**
   * @description Supprimer l'élément de travail avec nettoyage en cascade.
   * @param workItemId Id de l'élément de travail à supprimer
   */
  public static void deleteWorkItem(Id workItemId) {
    try {
      LOGGER.info('deleteWorkItem', 'Suppression de l\'élément de travail : ' + workItemId);

      delete new Work_Item__c(Id = workItemId);
      LOGGER.info('deleteWorkItem', 'Élément de travail supprimé avec succès');
    } catch (Exception e) {
      LOGGER.error('deleteWorkItem', 'Échec de la suppression de l\'élément de travail', e);
      throw e;
    }
  }

  /**
   * @description Assigner l'élément de travail à un utilisateur.
   * @param workItemId Id de l'élément de travail
   * @param userId Id de l'utilisateur à assigner
   */
  public static void assignWorkItem(Id workItemId, Id userId) {
    try {
      LOGGER.info('assignWorkItem', 'Attribution de l\'élément de travail ' + workItemId + ' à l\'utilisateur ' + userId);

      Work_Item__c workItem = new Work_Item__c(Id = workItemId);
      // TODO : Ajouter la logique d'attribution
      update workItem;

      LOGGER.info('assignWorkItem', 'Élément de travail attribué avec succès');
    } catch (Exception e) {
      LOGGER.error('assignWorkItem', 'Échec de l\'attribution de l\'élément de travail', e);
      throw e;
    }
  }

  /**
   * @description Mettre à jour le statut de l'élément de travail avec validation de transition.
   * @param workItemId Id de l'élément de travail
   * @param newStatus Nouvelle valeur de statut
   */
  public static void updateStatus(Id workItemId, String newStatus) {
    try {
      LOGGER.info('updateStatus', 'Mise à jour du statut à : ' + newStatus);

      Work_Item__c workItem = WorkItemSelector.getById(workItemId);
      if (workItem == null) {
        throw new IllegalArgumentException('Élément de travail non trouvé');
      }

      // Valider la transition
      Boolean isValid = WorkItemDomain.isStatusTransitionValid(workItem.Status__c, newStatus);
      if (!isValid) {
        String errorMessage = 'Transition de statut invalide de ' + workItem.Status__c + ' à ' + newStatus;
        LOGGER.warn('updateStatus', errorMessage);
        throw new IllegalArgumentException(errorMessage);
      }

      workItem.Status__c = newStatus;
      update workItem;

      LOGGER.info('updateStatus', 'Statut mis à jour avec succès à : ' + newStatus);
    } catch (Exception e) {
      LOGGER.error('updateStatus', 'Échec de la mise à jour du statut', e);
      throw e;
    }
  }

  /**
   * @description Mise à jour en masse du statut des éléments de travail.
   * @param workItemIds Liste des Ids d'éléments de travail
   * @param newStatus Nouveau statut pour tous les éléments
   */
  public static void bulkUpdateStatus(List<Id> workItemIds, String newStatus) {
    try {
      LOGGER.info('bulkUpdateStatus', 'Mise à jour de ' + workItemIds.size() + ' éléments au statut : ' + newStatus);

      // Vérifier si la liste n'est pas vide
      if (workItemIds == null || workItemIds.isEmpty()) {
        LOGGER.warn('bulkUpdateStatus', 'Aucun élément de travail fourni');
        return;
      }

      List<Work_Item__c> workItems = WorkItemSelector.getByIds(workItemIds);

      // Mettre à jour le statut pour chaque élément
      for (Work_Item__c item : workItems) {
        item.Status__c = newStatus;
      }

      update workItems;
      LOGGER.info('bulkUpdateStatus', 'Mise à jour en masse terminée avec succès');
    } catch (Exception e) {
      LOGGER.error('bulkUpdateStatus', 'Échec de la mise à jour en masse du statut', e);
      throw e;
    }
  }
}
