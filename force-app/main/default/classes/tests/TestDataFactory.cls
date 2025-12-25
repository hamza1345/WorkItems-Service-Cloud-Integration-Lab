/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Test data factory for creating test records.
 * Responsibilities:
 * - Provide builder methods for test record creation
 * - Implement consistent test data across all test classes
 * - Support fluent API for flexible test data setup
 * - Manage default values for required fields
 * - Isolate test data generation from test logic
 *
 * This class implements the Builder pattern for clean test setup.
 * All methods are public static for easy test class usage.
 */
@isTest
public class TestDataFactory {
  /**
   * @description Create a test work item with default values.
   * @return Work_Item__c record ready for insert
   */
  public static Work_Item__c createTestWorkItem() {
    // TODO: Implement default work item creation
    return new Work_Item__c();
  }

  /**
   * @description Create multiple test work items.
   * @param count Number of items to create
   * @return List of Work_Item__c records ready for insert
   */
  public static List<Work_Item__c> createTestWorkItems(Integer count) {
    List<Work_Item__c> items = new List<Work_Item__c>();
    // TODO: Implement bulk creation
    return items;
  }

  /**
   * @description Create work item with specific field values.
   * @param fields Map of field name -> value
   * @return Work_Item__c record with specified values
   */
  public static Work_Item__c createTestWorkItem(Map<String, Object> fields) {
    Work_Item__c item = createTestWorkItem();
    // TODO: Apply field overrides
    return item;
  }

  /**
   * @description Create work item with specific status.
   * @param status Status value
   * @return Work_Item__c record with specified status
   */
  public static Work_Item__c createTestWorkItemWithStatus(String status) {
    // TODO: Implement status-specific creation
    return new Work_Item__c();
  }

  /**
   * @description Create work item with related Account.
   * @return Work_Item__c with Account__c populated
   */
  public static Work_Item__c createTestWorkItemWithAccount() {
    // TODO: Implement with Account relationship
    return new Work_Item__c();
  }

  /**
   * @description Create work item with related Contact.
   * @return Work_Item__c with Contact__c populated
   */
  public static Work_Item__c createTestWorkItemWithContact() {
    // TODO: Implement with Contact relationship
    return new Work_Item__c();
  }

  /**
   * @description Create work item with related Case.
   * @return Work_Item__c with Case__c populated
   */
  public static Work_Item__c createTestWorkItemWithCase() {
    // TODO: Implement with Case relationship
    return new Work_Item__c();
  }

  /**
   * @description Insert test work items and return with populated Ids.
   * @param workItems List to insert
   * @return List with Ids populated
   */
  public static List<Work_Item__c> insertWorkItems(List<Work_Item__c> workItems) {
    // TODO: Implement insert with error handling
    return workItems;
  }

  /**
   * @description Create test Account for relationships.
   * @return Account record ready for insert
   */
  public static Account createTestAccount() {
    // TODO: Implement test Account creation
    return new Account();
  }

  /**
   * @description Create test Contact for relationships.
   * @return Contact record ready for insert
   */
  public static Contact createTestContact() {
    // TODO: Implement test Contact creation
    return new Contact();
  }

  /**
   * @description Create test Case for relationships.
   * @return Case record ready for insert
   */
  public static Case createTestCase() {
    // TODO: Implement test Case creation
    return new Case();
  }
}
