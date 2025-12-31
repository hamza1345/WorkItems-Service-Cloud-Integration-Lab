/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Selector pour Work_Item__c.
 * Centralise toutes les requêtes SOQL avec CRUD checks et logging.
 * Suit le pattern Selector Layer de l'architecture enterprise.
 */
public with sharing class WorkItemSelector {
  private static final Logger LOGGER = LoggerFactory.getLogger(
    'WorkItemSelector'
  );

  /**
   * @description Récupère tous les champs d'un Work Item.
   * @return String contenant tous les champs séparés par des virgules
   */
  private static String getAllFields() {
    return 'Id, Name, Status__c, Priority__c, Due_Date__c, ' +
      'Completed_On__c, Description__c, Category__c, ' +
      'External_Id__c, CreatedDate, LastModifiedDate';
  }

  /**
   * @description Vérifie les permissions CRUD avant une requête.
   * @param operation Type d'opération : 'READ', 'CREATE', 'UPDATE', 'DELETE'
   * @throws SecurityException si l'utilisateur n'a pas les permissions
   */
  private static void checkCRUDPermissions(String operation) {
    Schema.DescribeSObjectResult describeResult = Work_Item__c.SObjectType.getDescribe();

    if (operation == 'READ' && !describeResult.isAccessible()) {
      String errorMsg = 'Pas de permission READ sur Work_Item__c';
      LOGGER.error('checkCRUDPermissions', errorMsg);
      throw new SecurityException(errorMsg);
    } else if (operation == 'CREATE' && !describeResult.isCreateable()) {
      String errorMsg = 'Pas de permission CREATE sur Work_Item__c';
      LOGGER.error('checkCRUDPermissions', errorMsg);
      throw new SecurityException(errorMsg);
    } else if (operation == 'UPDATE' && !describeResult.isUpdateable()) {
      String errorMsg = 'Pas de permission UPDATE sur Work_Item__c';
      LOGGER.error('checkCRUDPermissions', errorMsg);
      throw new SecurityException(errorMsg);
    } else if (operation == 'DELETE' && !describeResult.isDeletable()) {
      String errorMsg = 'Pas de permission DELETE sur Work_Item__c';
      LOGGER.error('checkCRUDPermissions', errorMsg);
      throw new SecurityException(errorMsg);
    }
  }

  /**
   * @description Récupère un Work Item par son Id.
   * @param workItemId Id du Work Item
   * @return Work_Item__c ou null si non trouvé
   */
  public static Work_Item__c getById(Id workItemId) {
    checkCRUDPermissions('READ');

    try {
      LOGGER.debug('getById', 'Recherche Work Item : ' + workItemId);

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE Id = :workItemId ' +
        'LIMIT 1'
      );

      if (results.isEmpty()) {
        LOGGER.warn('getById', 'Work Item non trouvé : ' + workItemId);
        return null;
      }

      LOGGER.debug('getById', 'Work Item trouvé : ' + results[0].Name);
      return results[0];
    } catch (Exception e) {
      LOGGER.error('getById', 'Erreur lors de la récupération du Work Item', e);
      throw e;
    }
  }

  /**
   * @description Récupère plusieurs Work Items par leurs Ids.
   * @param workItemIds Set d'Ids des Work Items
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getByIds(Set<Id> workItemIds) {
    checkCRUDPermissions('READ');

    if (workItemIds == null || workItemIds.isEmpty()) {
      LOGGER.debug('getByIds', 'Set d\'Ids vide, retour liste vide');
      return new List<Work_Item__c>();
    }

    try {
      LOGGER.debug('getByIds', 'Recherche ' + workItemIds.size() + ' Work Items');

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE Id IN :workItemIds ' +
        'ORDER BY Name'
      );

      LOGGER.info('getByIds', results.size() + ' Work Items trouvés sur ' + workItemIds.size() + ' recherchés');
      return results;
    } catch (Exception e) {
      LOGGER.error('getByIds', 'Erreur lors de la récupération des Work Items', e);
      throw e;
    }
  }

  /**
   * @description Récupère les Work Items par statut.
   * @param status Statut à rechercher
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getByStatus(String status) {
    checkCRUDPermissions('READ');

    if (String.isBlank(status)) {
      LOGGER.debug('getByStatus', 'Statut vide, retour liste vide');
      return new List<Work_Item__c>();
    }

    try {
      LOGGER.debug('getByStatus', 'Recherche Work Items avec statut : ' + status);

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE Status__c = :status ' +
        'ORDER BY Due_Date__c ASC, Priority__c DESC'
      );

      LOGGER.info('getByStatus', results.size() + ' Work Items trouvés avec statut ' + status);
      return results;
    } catch (Exception e) {
      LOGGER.error('getByStatus', 'Erreur lors de la récupération par statut', e);
      throw e;
    }
  }

  /**
   * @description Récupère les Work Items par catégorie.
   * @param category Catégorie à rechercher
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getByCategory(String category) {
    checkCRUDPermissions('READ');

    if (String.isBlank(category)) {
      LOGGER.debug('getByCategory', 'Catégorie vide, retour liste vide');
      return new List<Work_Item__c>();
    }

    try {
      LOGGER.debug('getByCategory', 'Recherche Work Items avec catégorie : ' + category);

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE Category__c = :category ' +
        'ORDER BY Due_Date__c ASC'
      );

      LOGGER.info('getByCategory', results.size() + ' Work Items trouvés avec catégorie ' + category);
      return results;
    } catch (Exception e) {
      LOGGER.error('getByCategory', 'Erreur lors de la récupération par catégorie', e);
      throw e;
    }
  }

  /**
   * @description Récupère les Work Items en retard (Due_Date < today et Status != Done).
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getOverdue() {
    checkCRUDPermissions('READ');

    try {
      Date today = System.today();
      LOGGER.debug('getOverdue', 'Recherche Work Items en retard (avant ' + today + ')');

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE Due_Date__c < :today ' +
        'AND Status__c != \'Done\' ' +
        'ORDER BY Due_Date__c ASC'
      );

      LOGGER.info('getOverdue', results.size() + ' Work Items en retard trouvés');
      return results;
    } catch (Exception e) {
      LOGGER.error('getOverdue', 'Erreur lors de la récupération des Work Items en retard', e);
      throw e;
    }
  }

  /**
   * @description Récupère un Work Item par son External_Id.
   * @param externalId External Id à rechercher
   * @return Work_Item__c ou null si non trouvé
   */
  public static Work_Item__c getByExternalId(String externalId) {
    checkCRUDPermissions('READ');

    if (String.isBlank(externalId)) {
      LOGGER.debug('getByExternalId', 'External Id vide, retour null');
      return null;
    }

    try {
      LOGGER.debug('getByExternalId', 'Recherche Work Item avec External_Id : ' + externalId);

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE External_Id__c = :externalId ' +
        'LIMIT 1'
      );

      if (results.isEmpty()) {
        LOGGER.warn('getByExternalId', 'Work Item non trouvé avec External_Id : ' + externalId);
        return null;
      }

      LOGGER.debug('getByExternalId', 'Work Item trouvé : ' + results[0].Name);
      return results[0];
    } catch (Exception e) {
      LOGGER.error('getByExternalId', 'Erreur lors de la récupération par External_Id', e);
      throw e;
    }
  }

  /**
   * @description Récupère tous les Work Items actifs (Status != Done).
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getAllActiveWorkItems() {
    checkCRUDPermissions('READ');

    try {
      LOGGER.debug('getAllActiveWorkItems', 'Recherche tous les Work Items actifs');

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE Status__c != \'Done\' ' +
        'ORDER BY Priority__c DESC, Due_Date__c ASC'
      );

      LOGGER.info('getAllActiveWorkItems', results.size() + ' Work Items actifs trouvés');
      return results;
    } catch (Exception e) {
      LOGGER.error('getAllActiveWorkItems', 'Erreur lors de la récupération des Work Items actifs', e);
      throw e;
    }
  }

  /**
   * @description Récupère les Work Items créés après une certaine date.
   * @param fromDate Date de début
   * @return List<Work_Item__c>
   */
  public static List<Work_Item__c> getCreatedAfter(Date fromDate) {
    checkCRUDPermissions('READ');

    if (fromDate == null) {
      LOGGER.debug('getCreatedAfter', 'Date nulle, retour liste vide');
      return new List<Work_Item__c>();
    }

    try {
      DateTime fromDateTime = DateTime.newInstance(fromDate.year(), fromDate.month(), fromDate.day());
      LOGGER.debug('getCreatedAfter', 'Recherche Work Items créés après ' + fromDate);

      List<Work_Item__c> results = Database.query(
        'SELECT ' + getAllFields() + ' ' +
        'FROM Work_Item__c ' +
        'WHERE CreatedDate >= :fromDateTime ' +
        'ORDER BY CreatedDate DESC'
      );

      LOGGER.info('getCreatedAfter', results.size() + ' Work Items trouvés créés après ' + fromDate);
      return results;
    } catch (Exception e) {
      LOGGER.error('getCreatedAfter', 'Erreur lors de la récupération par date de création', e);
      throw e;
    }
  }

  /**
   * @description Exception personnalisée pour les erreurs de sécurité.
   */
  public class SecurityException extends Exception {
  }
}
