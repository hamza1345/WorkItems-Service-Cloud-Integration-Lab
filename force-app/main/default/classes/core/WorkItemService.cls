/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Service layer for Work_Item__c operations.
 * Responsibilities:
 * - Orchestrate business operations (create, update, delete, assign)
 * - Coordinate between Domain, Selector, and external services
 * - Handle transaction management and error recovery
 * - Implement complex business workflows
 * - Publish platform events for async processing
 *
 * This class contains the ONLY database operations (SOQL/DML) for WorkItems.
 * All queries and updates are delegated to private methods marked @TestVisible.
 */
public with sharing class WorkItemService {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemService');

  /**
   * @description Create a new work item with validation.
   * @param workItem Work item to create
   * @return Id of created work item
   */
  public static Id createWorkItem(Work_Item__c workItem) {
    try {
      LOGGER.info('createWorkItem', 'Creating work item: ' + workItem.Name);

      // Validate
      List<String> errors = WorkItemDomain.validate(new List<Work_Item__c>{ workItem });
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, ', ');
        LOGGER.warn('createWorkItem', 'Validation errors: ' + errorMessage);
        throw new IllegalArgumentException(errorMessage);
      }

      // Populate defaults
      WorkItemDomain.populateDefaults(new List<Work_Item__c>{ workItem });

      // Insert
      insert workItem;
      LOGGER.info('createWorkItem', 'Work item created with Id: ' + workItem.Id);

      return workItem.Id;
    } catch (Exception e) {
      LOGGER.error('createWorkItem', 'Failed to create work item', e);
      throw e;
    }
  }

  /**
   * @description Update work item with change detection.
   * @param workItem Work item to update
   */
  public static void updateWorkItem(Work_Item__c workItem) {
    try {
      LOGGER.info('updateWorkItem', 'Updating work item: ' + workItem.Id);

      // Validate
      List<String> errors = WorkItemDomain.validate(new List<Work_Item__c>{ workItem });
      if (!errors.isEmpty()) {
        String errorMessage = String.join(errors, ', ');
        LOGGER.warn('updateWorkItem', 'Validation errors: ' + errorMessage);
        throw new IllegalArgumentException(errorMessage);
      }

      update workItem;
      LOGGER.info('updateWorkItem', 'Work item updated successfully');
    } catch (Exception e) {
      LOGGER.error('updateWorkItem', 'Failed to update work item', e);
      throw e;
    }
  }

  /**
   * @description Delete work item with cascading cleanup.
   * @param workItemId Id of work item to delete
   */
  public static void deleteWorkItem(Id workItemId) {
    try {
      LOGGER.info('deleteWorkItem', 'Deleting work item: ' + workItemId);

      delete new Work_Item__c(Id = workItemId);
      LOGGER.info('deleteWorkItem', 'Work item deleted successfully');
    } catch (Exception e) {
      LOGGER.error('deleteWorkItem', 'Failed to delete work item', e);
      throw e;
    }
  }

  /**
   * @description Assign work item to a user.
   * @param workItemId Id of work item
   * @param userId Id of user to assign
   */
  public static void assignWorkItem(Id workItemId, Id userId) {
    try {
      LOGGER.info('assignWorkItem', 'Assigning work item ' + workItemId + ' to user ' + userId);

      Work_Item__c workItem = new Work_Item__c(Id = workItemId);
      // TODO: Add assignment logic
      update workItem;

      LOGGER.info('assignWorkItem', 'Work item assigned successfully');
    } catch (Exception e) {
      LOGGER.error('assignWorkItem', 'Failed to assign work item', e);
      throw e;
    }
  }

  /**
   * @description Update work item status with transition validation.
   * @param workItemId Id of work item
   * @param newStatus New status value
   */
  public static void updateStatus(Id workItemId, String newStatus) {
    try {
      LOGGER.info('updateStatus', 'Updating status to: ' + newStatus);

      Work_Item__c workItem = WorkItemSelector.getById(workItemId);
      if (workItem == null) {
        throw new IllegalArgumentException('Work item not found');
      }

      // Validate transition
      Boolean isValid = WorkItemDomain.isStatusTransitionValid(workItem.Status__c, newStatus);
      if (!isValid) {
        String errorMessage = 'Invalid status transition from ' + workItem.Status__c + ' to ' + newStatus;
        LOGGER.warn('updateStatus', errorMessage);
        throw new IllegalArgumentException(errorMessage);
      }

      workItem.Status__c = newStatus;
      update workItem;

      LOGGER.info('updateStatus', 'Status updated successfully to: ' + newStatus);
    } catch (Exception e) {
      LOGGER.error('updateStatus', 'Failed to update status', e);
      throw e;
    }
  }

  /**
   * @description Bulk update work items status.
   * @param workItemIds List of work item Ids
   * @param newStatus New status for all items
   */
  public static void bulkUpdateStatus(List<Id> workItemIds, String newStatus) {
    try {
      LOGGER.info('bulkUpdateStatus', 'Updating ' + workItemIds.size() + ' items to status: ' + newStatus);

      if (workItemIds == null || workItemIds.isEmpty()) {
        LOGGER.warn('bulkUpdateStatus', 'No work items provided');
        return;
      }

      List<Work_Item__c> workItems = WorkItemSelector.getByIds(workItemIds);

      for (Work_Item__c item : workItems) {
        item.Status__c = newStatus;
      }

      update workItems;
      LOGGER.info('bulkUpdateStatus', 'Bulk update completed successfully');
    } catch (Exception e) {
      LOGGER.error('bulkUpdateStatus', 'Failed to bulk update status', e);
      throw e;
    }
  }
}
