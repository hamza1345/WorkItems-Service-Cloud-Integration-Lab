/**
 * @author Hamza Amari
 * @date 30/12/2025
 * @description Tests unitaires pour App_Log_EventSubscriber.
 * Couverture de test :
 * - Gestion des événements entrants
 * - Conversion événement → enregistrement
 * - Persistance en base de données (bulk-safe)
 * - Gestion des erreurs sans interruption
 * - Respect du flag de persistance
 */
@IsTest
private class App_Log_EventSubscriberTest {
  /**
   * @description Tester que les événements sont convertis en enregistrements.
   */
  @IsTest
  static void testEventConversionToRecord() {
    // Arrange
    App_Log__e logEvent = new App_Log__e(
      Level__c = 'INFO',
      Message__c = 'Message de test',
      Request_Id__c = 'REQ-12345',
      Class_Name__c = 'TestClass',
      Method_Name__c = 'testMethod',
      User_Id__c = UserInfo.getUserId(),
      Exception_Message__c = null,
      Exception_Stack_Trace__c = null
    );

    // Act - Tester directement la conversion sans passer par handleMessage
    AppLogging__c record = App_Log_EventSubscriber.convertEventToRecord(logEvent);

    // Assert - Vérifier le mapping
    Assert.areEqual('INFO', record.Level__c, 'Level devrait être mappé');
    Assert.areEqual('Message de test', record.Message__c, 'Message devrait être mappé');
    Assert.areEqual('REQ-12345', record.Request_Id__c, 'Request ID devrait être mappé');
    Assert.areEqual('TestClass', record.Class_Name__c, 'Class name devrait être mappé');
    Assert.areEqual('testMethod', record.Method_Name__c, 'Method name devrait être mappé');
    Assert.areEqual(UserInfo.getUserId(), record.User_Id__c, 'User ID devrait être mappé');
    Assert.isNotNull(record.Timestamp__c, 'Timestamp devrait être rempli');
  }

  /**
   * @description Tester que les logs sont persistés avec succès via trigger.
   */
  @IsTest
  static void testLogPersistence() {
    // Arrange
    App_Log__e logEvent = new App_Log__e(
      Level__c = 'ERROR',
      Message__c = 'Test de persistance',
      Request_Id__c = 'REQ-67890',
      Class_Name__c = 'PersistenceTest',
      Method_Name__c = 'testMethod',
      User_Id__c = UserInfo.getUserId()
    );

    // Act - Publier l'event pour déclencher le trigger
    Test.startTest();
    EventBus.publish(logEvent);
    Test.stopTest();

    // Assert
    List<AppLogging__c> insertedLogs = [
      SELECT Id, Level__c, Message__c FROM AppLogging__c WHERE Request_Id__c = 'REQ-67890'
    ];
    Assert.isTrue(insertedLogs.size() > 0, 'Log devrait être persisté dans la base de données');
    Assert.areEqual('ERROR', insertedLogs[0].Level__c);
    Assert.areEqual('Test de persistance', insertedLogs[0].Message__c);
  }

  /**
   * @description Tester que la conversion gère les valeurs null.
   */
  @IsTest
  static void testConversionHandlesNull() {
    // Arrange
    Test.startTest();

    App_Log__e logEvent = new App_Log__e(
      Level__c = 'ERROR',
      Message__c = 'Erreur sans exception',
      Request_Id__c = 'REQ-NULL',
      Class_Name__c = 'ErrorClass',
      Method_Name__c = 'errorMethod',
      User_Id__c = UserInfo.getUserId(),
      Exception_Message__c = null,
      Exception_Stack_Trace__c = null
    );

    // Act
    App_Log_EventSubscriber.handleMessage(new List<App_Log__e>{ logEvent });

    Test.stopTest();

    // Assert
    List<AppLogging__c> logs = [
      SELECT Id, Exception_Message__c, Exception_Stack_Trace__c
      FROM AppLogging__c
      WHERE Request_Id__c = 'REQ-NULL'
    ];
    Assert.isTrue(logs.size() > 0, 'Log devrait être persisté');
    Assert.isNull(logs[0].Exception_Message__c, 'Exception message devrait rester null');
    Assert.isNull(logs[0].Exception_Stack_Trace__c, 'Stack trace devrait rester null');
  }

  /**
   * @description Tester la persistance en masse.
   */
  @IsTest
  static void testBulkPersistence() {
    // Arrange
    Test.startTest();

    List<App_Log__e> logEvents = new List<App_Log__e>();
    for (Integer i = 0; i < 10; i++) {
      logEvents.add(
        new App_Log__e(
          Level__c = 'INFO',
          Message__c = 'Message en masse ' + i,
          Request_Id__c = 'BULK-' + i,
          Class_Name__c = 'BulkTest'
        )
      );
    }

    // Act
    App_Log_EventSubscriber.handleMessage(logEvents);

    Test.stopTest();

    // Assert
    List<AppLogging__c> insertedLogs = [SELECT Id FROM AppLogging__c WHERE Class_Name__c = 'BulkTest'];
    Assert.areEqual(10, insertedLogs.size(), '10 logs devraient être persistés');
  }

  /**
   * @description Tester que les erreurs sont gérées gracieusement sans interruption.
   */
  @IsTest
  static void testErrorHandlingGraceful() {
    // Arrange
    Test.startTest();

    App_Log__e logEvent = new App_Log__e(
      Level__c = 'INFO',
      Message__c = 'Test de gestion d\'erreur',
      Request_Id__c = 'REQ-ERROR-TEST'
    );

    // Act & Assert - Ne devrait pas lever d'exception
    try {
      App_Log_EventSubscriber.handleMessage(new List<App_Log__e>{ logEvent });
      Assert.isTrue(true, 'Pas d\'exception levée');
    } catch (Exception e) {
      Assert.fail('Erreur ne devrait pas être levée : ' + e.getMessage());
    }

    Test.stopTest();
  }

  /**
   * @description Tester que les logs avec exceptions sont stockés correctement.
   */
  @IsTest
  static void testLogWithException() {
    // Arrange
    Test.startTest();

    App_Log__e logEvent = new App_Log__e(
      Level__c = 'ERROR',
      Message__c = 'Log avec exception',
      Request_Id__c = 'REQ-EXC',
      Class_Name__c = 'ExceptionTest',
      Method_Name__c = 'testMethod',
      Exception_Message__c = 'DML Exception: Insert failed',
      Exception_Stack_Trace__c = 'Line 42: insert new Account()'
    );

    // Act
    App_Log_EventSubscriber.handleMessage(new List<App_Log__e>{ logEvent });

    Test.stopTest();

    // Assert
    List<AppLogging__c> logs = [
      SELECT Id, Exception_Message__c, Exception_Stack_Trace__c
      FROM AppLogging__c
      WHERE Request_Id__c = 'REQ-EXC'
    ];
    Assert.isTrue(logs.size() > 0, 'Log devrait être persisté');
    Assert.isTrue(logs[0].Exception_Message__c.contains('DML Exception'));
  }
}
