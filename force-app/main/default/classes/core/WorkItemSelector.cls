/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Couche Sélecteur pour les requêtes de Work_Item__c.
 * Responsabilités :
 * - Centraliser toutes les requêtes SOQL pour Work_Item__c
 * - Créer des requêtes dynamiques basées sur les filtres
 * - Gérer la validation CRUD
 * - Implémenter les modèles de requête courants
 *
 * RÈGLE : C'est la SEULE classe avec des requêtes SOQL.
 * Toutes les méthodes doivent être marquées @TestVisible.
 * Pas de logique métier - uniquement la récupération de données.
 */
public with sharing class WorkItemSelector {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemSelector');

  /**
   * @description Obtenir l'élément de travail par Id avec tous les champs.
   * @param workItemId Id à interroger
   * @return Enregistrement de l'élément de travail ou null s'il n'est pas trouvé ou pas accessible
   */
  public static Work_Item__c getById(Id workItemId) {
    try {
      // Valider la CRUD
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        LOGGER.warn('getById', 'Pas d\'accès en lecture à Work_Item__c');
        return null;
      }

      // Exécuter la requête
      List<Work_Item__c> results = [
        SELECT
          Id,
          Name,
          Status__c,
          Description__c,
          Due_Date__c
        FROM Work_Item__c
        WHERE Id = :workItemId
        LIMIT 1
      ];

      return results.isEmpty() ? null : results[0];
    } catch (Exception e) {
      LOGGER.error('getById', 'Échec de la requête pour l\'Id : ' + workItemId, e);
      return null;
    }
  }

  /**
   * @description Obtenir plusieurs éléments de travail par Ids.
   * @param workItemIds Ensemble des Ids à interroger
   * @return Liste des éléments de travail
   */
  public static List<Work_Item__c> getByIds(List<Id> workItemIds) {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        LOGGER.warn('getByIds', 'Pas d\'accès en lecture à Work_Item__c');
        return new List<Work_Item__c>();
      }

      if (workItemIds == null || workItemIds.isEmpty()) {
        return new List<Work_Item__c>();
      }

      return [
        SELECT
          Id,
          Name,
          Status__c,
          Description__c,
          Due_Date__c
        FROM Work_Item__c
        WHERE Id IN :workItemIds
      ];
    } catch (Exception e) {
      LOGGER.error('getByIds', 'Échec de la requête', e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Obtenir tous les éléments de travail triés par date de création.
   * @return Liste des éléments de travail
   */
  public static List<Work_Item__c> getAll() {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return new List<Work_Item__c>();
      }

      return [
        SELECT Id, Name, Status__c, Description__c, Due_Date__c
        FROM Work_Item__c
        ORDER BY CreatedDate DESC
      ];
    } catch (Exception e) {
      LOGGER.error('getAll', 'Échec de la requête', e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Obtenir les éléments de travail par statut.
   * @param status Valeur du statut (p. ex., 'In_Progress')
   * @return Liste des éléments de travail
   */
  public static List<Work_Item__c> getByStatus(String status) {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return new List<Work_Item__c>();
      }

      return [
        SELECT Id, Name, Status__c, Description__c, Due_Date__c
        FROM Work_Item__c
        WHERE Status__c = :status
      ];
    } catch (Exception e) {
      LOGGER.error('getByStatus', 'Échec de la requête pour le statut : ' + status, e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Obtenir les éléments de travail dont la date d'échéance est dans N jours.
   * @param days Nombre de jours à partir d'aujourd'hui
   * @return Liste des éléments de travail
   */
  public static List<Work_Item__c> getDueWithinDays(Integer days) {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return new List<Work_Item__c>();
      }

      Date dueDate = System.today().addDays(days);

      return [
        SELECT Id, Name, Status__c, Due_Date__c
        FROM Work_Item__c
        WHERE Due_Date__c <= :dueDate AND Status__c != 'Done'
        ORDER BY Due_Date__c ASC
      ];
    } catch (Exception e) {
      LOGGER.error('getDueWithinDays', 'Échec de la requête pour les jours : ' + days, e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Obtenir les éléments de travail par Id externe (pour la synchronisation).
   * @param externalIds Ensemble des Ids externes
   * @return Map d'Id externe -> Élément de travail
   */
  public static Map<String, Work_Item__c> getByExternalId(Set<String> externalIds) {
    Map<String, Work_Item__c> resultMap = new Map<String, Work_Item__c>();

    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return resultMap;
      }

      if (externalIds == null || externalIds.isEmpty()) {
        return resultMap;
      }

      List<Work_Item__c> results = [
        SELECT Id, Name, Status__c
        FROM Work_Item__c
        WHERE Id IN :externalIds
      ];

      for (Work_Item__c item : results) {
        resultMap.put(item.Id, item);
      }

      return resultMap;
    } catch (Exception e) {
      LOGGER.error('getByExternalId', 'Échec de la requête', e);
      return resultMap;
    }
  }

  /**
   * @description Compter les éléments de travail par statut.
   * @return Map de statut -> nombre
   */
  public static Map<String, Integer> countByStatus() {
    Map<String, Integer> resultMap = new Map<String, Integer>();

    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return resultMap;
      }

      List<AggregateResult> results = [
        SELECT Status__c, COUNT(Id) cnt
        FROM Work_Item__c
        GROUP BY Status__c
      ];

      for (AggregateResult ar : results) {
        resultMap.put((String) ar.get('Status__c'), (Integer) ar.get('cnt'));
      }

      return resultMap;
    } catch (Exception e) {
      LOGGER.error('countByStatus', 'Échec de la requête d\'agrégation', e);
      return resultMap;
    }
  }
}
