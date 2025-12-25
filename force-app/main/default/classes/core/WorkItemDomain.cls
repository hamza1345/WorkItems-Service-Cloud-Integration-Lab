/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Domain layer for Work_Item__c business logic.
 * Responsibilities:
 * - Encapsulate Work_Item__c business rules and validations
 * - Calculate derived fields (e.g., elapsed time, completion percentage)
 * - Manage state transitions (e.g., New -> In_Progress -> Done)
 * - Provide helper methods for WorkItemService
 *
 * This class contains NO database operations (no SOQL/DML).
 * It operates on in-memory Work_Item__c objects only.
 */
public without sharing class WorkItemDomain {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemDomain');
  private static final Integer COMPLETION_THRESHOLD = 80;

  /**
   * @description Validate Work Item state before save.
   * @param records Work items to validate
   * @return List of validation errors (empty if valid)
   */
  public static List<String> validate(List<Work_Item__c> records) {
    List<String> errors = new List<String>();

    if (records == null || records.isEmpty()) {
      return errors;
    }

    for (Work_Item__c record : records) {
      // TODO: Implement validation logic
    }

    return errors;
  }

  /**
   * @description Populate default values for new work items.
   * @param records Records to populate
   */
  public static void populateDefaults(List<Work_Item__c> records) {
    if (records == null || records.isEmpty()) {
      return;
    }

    for (Work_Item__c record : records) {
      // TODO: Implement default population logic
    }
  }

  /**
   * @description Check if a work item can transition to a new status.
   * @param currentStatus Current status value
   * @param newStatus Proposed new status
   * @return true if transition is allowed
   */
  public static Boolean isStatusTransitionValid(String currentStatus, String newStatus) {
    // Use switch instead of if-else for multiple conditions
    switch on currentStatus {
      when 'New' {
        return newStatus == 'In_Progress' || newStatus == 'On_Hold';
      }
      when 'In_Progress' {
        return newStatus == 'Done' || newStatus == 'On_Hold' || newStatus == 'New';
      }
      when 'On_Hold' {
        return newStatus == 'In_Progress' || newStatus == 'Cancelled';
      }
      when 'Done' {
        return newStatus == 'Reopened';
      }
      when 'Cancelled' {
        return false;
      }
      when else {
        return false;
      }
    }
  }

  /**
   * @description Calculate completion percentage based on related tasks.
   * @param workItemId Id of work item
   * @return Completion percentage (0-100)
   */
  public static Integer calculateCompletionPercentage(Id workItemId) {
    // TODO: Implement calculation
    return 0;
  }
}
