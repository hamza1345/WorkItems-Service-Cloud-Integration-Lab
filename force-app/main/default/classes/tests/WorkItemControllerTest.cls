/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Tests pour WorkItemController.
 * Couvre @AuraEnabled methods, AuraHandledException wrapping, cacheable.
 */
@IsTest
private class WorkItemControllerTest {
  
  /**
   * @description Setup pour chaque test.
   */
  @TestSetup
  static void setupTestData() {
    // Mock FeatureFlags pour activer l'automation
    Logging_Settings__mdt mockSettings = new Logging_Settings__mdt(
      Enable_Logging__c = true,
      Persist_Logs__c = false,
      Disable_Automation__c = false
    );
    FeatureFlags.hasInitialized = false;
    FeatureFlags.cachedSettings = mockSettings;
    FeatureFlags.hasInitialized = true;
  }
  
  /**
   * @description Test 1 : getItems retourne Work Items filtrés.
   */
  @IsTest
  static void testGetItemsReturnsFilteredItems() {
    // Arrange
    List<Work_Item__c> items = new List<Work_Item__c>();
    items.add(TestDataFactory.createWorkItem('Item 1', 'New', 'High', System.today().addDays(5)));
    items.add(TestDataFactory.createWorkItem('Item 2', 'In_Progress', 'Medium', System.today().addDays(10)));
    items.add(TestDataFactory.createWorkItem('Item 3', 'New', 'Low', System.today().addDays(15)));
    insert items;
    
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemController.getItems('New', null, 50);
    Test.stopTest();
    
    // Assert
    Assert.areEqual(2, results.size(), 'Devrait retourner 2 Work Items New');
  }
  
  /**
   * @description Test 2 : getItems recherche par texte.
   */
  @IsTest
  static void testGetItemsSearchesByText() {
    // Arrange
    List<Work_Item__c> items = new List<Work_Item__c>();
    items.add(TestDataFactory.createWorkItem('SEARCHABLE Item 1', 'New', 'Medium', System.today().addDays(5)));
    items.add(TestDataFactory.createWorkItem('Other Item', 'New', 'Medium', System.today().addDays(5)));
    insert items;
    
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemController.getItems(null, 'SEARCHABLE', 50);
    Test.stopTest();
    
    // Assert
    Assert.areEqual(1, results.size(), 'Devrait trouver 1 Work Item SEARCHABLE');
    Assert.isTrue(results[0].Name.contains('SEARCHABLE'), 'Nom devrait contenir SEARCHABLE');
  }
  
  /**
   * @description Test 3 : saveItem INSERT crée un Work Item.
   */
  @IsTest
  static void testSaveItemInsert() {
    // Arrange
    Work_Item__c item = new Work_Item__c(
      Name = 'Test Insert',
      Description__c = 'Test description',
      Due_Date__c = System.today().addDays(7)
    );
    
    // Act
    Test.startTest();
    Work_Item__c saved = WorkItemController.saveItem(item);
    Test.stopTest();
    
    // Assert
    Assert.isNotNull(saved.Id, 'Id devrait être rempli');
    Assert.areEqual('New', saved.Status__c, 'Status devrait être New (défaut)');
    Assert.areEqual('Medium', saved.Priority__c, 'Priority devrait être Medium (défaut)');
  }
  
  /**
   * @description Test 4 : saveItem UPDATE met à jour Work Item.
   */
  @IsTest
  static void testSaveItemUpdate() {
    // Arrange
    Work_Item__c item = TestDataFactory.createAndInsertWorkItem('Test Update');
    item.Priority__c = 'High';
    item.Description__c = 'Updated description';
    
    // Act
    Test.startTest();
    Work_Item__c saved = WorkItemController.saveItem(item);
    Test.stopTest();
    
    // Assert
    Assert.areEqual('High', saved.Priority__c, 'Priority devrait être High');
    Assert.areEqual('Updated description', saved.Description__c, 'Description mise à jour');
  }
  
  /**
   * @description Test 5 : saveItem avec null lève AuraHandledException.
   */
  @IsTest
  static void testSaveItemWithNullThrowsAuraHandledException() {
    // Act & Assert
    try {
      Test.startTest();
      WorkItemController.saveItem(null);
      Test.stopTest();
      Assert.fail('Une AuraHandledException devrait être levée pour Work Item null');
    } catch (AuraHandledException e) {
      Assert.isNotNull(e.getMessage(), 'Message ne devrait pas être null');
    }
  }
  
  /**
   * @description Test 6 : markDone marque Work Item comme Done.
   */
  @IsTest
  static void testMarkDoneSetsStatusDone() {
    // Arrange
    Work_Item__c item = TestDataFactory.createAndInsertWorkItem('Test Done');
    
    // Act
    Test.startTest();
    Work_Item__c result = WorkItemController.markDone(item.Id);
    Test.stopTest();
    
    // Assert
    Assert.areEqual('Done', result.Status__c, 'Status devrait être Done');
    Assert.isNotNull(result.Completed_On__c, 'Completed_On devrait être rempli par Trigger');
  }
  
  /**
   * @description Test 7 : markDone avec null Id lève AuraHandledException.
   */
  @IsTest
  static void testMarkDoneWithNullIdThrowsAuraHandledException() {
    // Act & Assert
    try {
      Test.startTest();
      WorkItemController.markDone(null);
      Test.stopTest();
      Assert.fail('Une AuraHandledException devrait être levée pour Id null');
    } catch (AuraHandledException e) {
      Assert.isNotNull(e.getMessage(), 'Message ne devrait pas être null');
    }
  }
  
  /**
   * @description Test 8 : markDone avec Id inexistant lève AuraHandledException.
   */
  @IsTest
  static void testMarkDoneWithNonExistentIdThrowsAuraHandledException() {
    // Arrange
    Id fakeId = '001000000000000AAA';
    
    // Act & Assert
    try {
      Test.startTest();
      WorkItemController.markDone(fakeId);
      Test.stopTest();
      Assert.fail('Une AuraHandledException devrait être levée pour Id inexistant');
    } catch (AuraHandledException e) {
      Assert.isNotNull(e.getMessage(), 'Message ne devrait pas être null');
    }
  }
  
  /**
   * @description Test 9 : getById retourne Work Item complet.
   */
  @IsTest
  static void testGetByIdReturnsCompleteItem() {
    // Arrange
    Work_Item__c item = TestDataFactory.createAndInsertWorkItem('Test GetById');
    
    // Act
    Test.startTest();
    Work_Item__c result = WorkItemController.getById(item.Id);
    Test.stopTest();
    
    // Assert
    Assert.isNotNull(result, 'Work Item devrait être retourné');
    Assert.areEqual(item.Id, result.Id, 'Id devrait correspondre');
    Assert.areEqual('Test GetById', result.Name, 'Name devrait correspondre');
  }
  
  /**
   * @description Test 10 : getById avec Id inexistant lève AuraHandledException.
   */
  @IsTest
  static void testGetByIdWithNonExistentIdThrowsAuraHandledException() {
    // Arrange
    Id fakeId = '001000000000000AAA';
    
    // Act & Assert
    try {
      Test.startTest();
      WorkItemController.getById(fakeId);
      Test.stopTest();
      Assert.fail('Une AuraHandledException devrait être levée pour Id inexistant');
    } catch (AuraHandledException e) {
      Assert.isNotNull(e.getMessage(), 'Message ne devrait pas être null');
    }
  }
}
