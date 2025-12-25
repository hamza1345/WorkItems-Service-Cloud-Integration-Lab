/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Selector layer for Work_Item__c queries.
 * Responsibilities:
 * - Centralize all SOQL queries for Work_Item__c
 * - Build dynamic queries based on filters
 * - Handle CRUD validation
 * - Implement common query patterns
 *
 * RULE: This is the ONLY class with SOQL queries.
 * All methods must be marked @TestVisible.
 * No business logic - only data retrieval.
 */
public with sharing class WorkItemSelector {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemSelector');

  /**
   * @description Get work item by Id with all fields.
   * @param workItemId Id to query
   * @return Work item record or null if not found/not accessible
   */
  @TestVisible
  private static Work_Item__c getById(Id workItemId) {
    try {
      // CRUD validation
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        LOGGER.warn('getById', 'No read access to Work_Item__c');
        return null;
      }

      List<Work_Item__c> results = [
        SELECT
          Id,
          Name,
          Status__c,
          Description__c,
          Assigned_To__c,
          Due_Date__c
        FROM Work_Item__c
        WHERE Id = :workItemId
        LIMIT 1
      ];

      return results.isEmpty() ? null : results[0];
    } catch (Exception e) {
      LOGGER.error('getById', 'Query failed for Id: ' + workItemId, e);
      return null;
    }
  }

  /**
   * @description Get multiple work items by Ids.
   * @param workItemIds Set of Ids to query
   * @return List of work items
   */
  @TestVisible
  private static List<Work_Item__c> getByIds(List<Id> workItemIds) {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        LOGGER.warn('getByIds', 'No read access to Work_Item__c');
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
          Assigned_To__c,
          Due_Date__c
        FROM Work_Item__c
        WHERE Id IN :workItemIds
      ];
    } catch (Exception e) {
      LOGGER.error('getByIds', 'Query failed', e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Get all work items for a user.
   * @param userId Id of assigned user
   * @return List of work items
   */
  @TestVisible
  private static List<Work_Item__c> getByAssignedUser(Id userId) {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return new List<Work_Item__c>();
      }

      return [
        SELECT Id, Name, Status__c, Description__c, Assigned_To__c, Due_Date__c
        FROM Work_Item__c
        WHERE Assigned_To__c = :userId
        ORDER BY Due_Date__c ASC
      ];
    } catch (Exception e) {
      LOGGER.error('getByAssignedUser', 'Query failed for user: ' + userId, e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Get work items by status.
   * @param status Status value (e.g., 'In_Progress')
   * @return List of work items
   */
  @TestVisible
  private static List<Work_Item__c> getByStatus(String status) {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return new List<Work_Item__c>();
      }

      return [
        SELECT Id, Name, Status__c, Description__c, Assigned_To__c, Due_Date__c
        FROM Work_Item__c
        WHERE Status__c = :status
      ];
    } catch (Exception e) {
      LOGGER.error('getByStatus', 'Query failed for status: ' + status, e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Get work items due within N days.
   * @param days Number of days from today
   * @return List of work items
   */
  @TestVisible
  private static List<Work_Item__c> getDueWithinDays(Integer days) {
    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return new List<Work_Item__c>();
      }

      Date dueDate = System.today().addDays(days);

      return [
        SELECT Id, Name, Status__c, Due_Date__c, Assigned_To__c
        FROM Work_Item__c
        WHERE Due_Date__c <= :dueDate AND Status__c != 'Done'
        ORDER BY Due_Date__c ASC
      ];
    } catch (Exception e) {
      LOGGER.error('getDueWithinDays', 'Query failed for days: ' + days, e);
      return new List<Work_Item__c>();
    }
  }

  /**
   * @description Get work items by external Id (for sync).
   * @param externalIds Set of external Ids
   * @return Map of external Id -> Work Item
   */
  @TestVisible
  private static Map<String, Work_Item__c> getByExternalId(Set<String> externalIds) {
    Map<String, Work_Item__c> resultMap = new Map<String, Work_Item__c>();

    try {
      if (!Work_Item__c.sObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
        return resultMap;
      }

      if (externalIds == null || externalIds.isEmpty()) {
        return resultMap;
      }

      List<Work_Item__c> results = [
        SELECT Id, Name, Status__c, External_Id__c
        FROM Work_Item__c
        WHERE External_Id__c IN :externalIds
      ];

      for (Work_Item__c item : results) {
        resultMap.put(item.External_Id__c, item);
      }

      return resultMap;
    } catch (Exception e) {
      LOGGER.error('getByExternalId', 'Query failed', e);
      return resultMap;
    }
  }

  /**
   * @description Count work items by status.
   * @return Map of status -> count
   */
  @TestVisible
  private static Map<String, Integer> countByStatus() {
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
      LOGGER.error('countByStatus', 'Aggregation query failed', e);
      return resultMap;
    }
  }
}
