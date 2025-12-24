/**
 * @description Test class for LogContext.
 * Tests: Request ID generation, context data, source tracking, custom data.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class LogContextTest {

  @IsTest
  static void testLogContextInitialization() {
    // Act
    LogContext context = new LogContext();

    // Assert
    Assert.isNotNull(context.getRequestId(), 'Request ID should be generated');
    Assert.isNotNull(context.getUserId(), 'User ID should be set');
    Assert.isNotNull(context.getOrgId(), 'Org ID should be set');
    Assert.areEqual(UserInfo.getUserId(), context.getUserId());
    Assert.areEqual(UserInfo.getOrganizationId(), context.getOrgId());
  }

  @IsTest
  static void testRequestIdFormat() {
    // Act
    LogContext context = new LogContext();
    String requestId = context.getRequestId();

    // Assert - Request ID should have format: XXXXX-XXXXXXXX-XXXXX
    Assert.isTrue(requestId.contains('-'), 'Request ID should contain hyphens');
    Assert.isTrue(requestId.length() > 10, 'Request ID should be reasonably long');
  }

  @IsTest
  static void testRequestIdUniqueness() {
    // Act - Create multiple contexts
    LogContext context1 = new LogContext();
    LogContext context2 = new LogContext();
    String id1 = context1.getRequestId();
    String id2 = context2.getRequestId();

    // Assert - IDs should be different (high probability)
    // Note: Could theoretically be same in microseconds, but very unlikely
    Assert.isTrue(
      !id1.equals(id2),
      'Request IDs should generally be unique'
    );
  }

  @IsTest
  static void testSetSource() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    LogContext result = context.setSource('TestClass', 'testMethod');

    // Assert - Method chaining works
    Assert.areEqual('TestClass', context.getClassName());
    Assert.areEqual('testMethod', context.getMethodName());
    Assert.areEqual(context, result, 'setSource should return this');
  }

  @IsTest
  static void testAddCustomData() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    LogContext result = context
      .addCustomData('key1', 'value1')
      .addCustomData('key2', 123)
      .addCustomData('key3', true);

    // Assert
    Map<String, Object> customData = context.getCustomData();
    Assert.areEqual('value1', customData.get('key1'));
    Assert.areEqual(123, customData.get('key2'));
    Assert.areEqual(true, customData.get('key3'));
    Assert.areEqual(context, result, 'addCustomData should return this');
  }

  @IsTest
  static void testCustomDataIsNotNull() {
    // Act
    LogContext context = new LogContext();

    // Assert
    Assert.isNotNull(context.getCustomData(), 'Custom data map should not be null');
    Assert.areEqual(0, context.getCustomData().size(), 'Custom data should be empty initially');
  }

  @IsTest
  static void testStartTimeIsSet() {
    // Act
    Long beforeContext = System.currentTimeMillis();
    LogContext context = new LogContext();
    Long afterContext = System.currentTimeMillis();

    // Assert
    Long startTime = context.getStartTime();
    Assert.isTrue(startTime >= beforeContext, 'Start time should be after creation');
    Assert.isTrue(startTime <= afterContext, 'Start time should be before now');
  }

  @IsTest
  static void testGetElapsedTime() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    Long elapsedBefore = context.getElapsedTime();
    System.debug('Waiting...');
    Long elapsedAfter = context.getElapsedTime();

    // Assert
    Assert.isTrue(elapsedAfter >= elapsedBefore, 'Elapsed time should increase');
    Assert.isTrue(elapsedBefore >= 0, 'Elapsed time should be non-negative');
  }

  @IsTest
  static void testSourceCanBeChanged() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    context.setSource('Class1', 'method1');
    String className1 = context.getClassName();
    String methodName1 = context.getMethodName();

    context.setSource('Class2', 'method2');
    String className2 = context.getClassName();
    String methodName2 = context.getMethodName();

    // Assert
    Assert.areEqual('Class1', className1);
    Assert.areEqual('method1', methodName1);
    Assert.areEqual('Class2', className2);
    Assert.areEqual('method2', methodName2);
  }

  @IsTest
  static void testMethodChaining() {
    // Act
    LogContext context = new LogContext()
      .setSource('TestClass', 'testMethod')
      .addCustomData('recordId', '001xx000003DHfAAM')
      .addCustomData('action', 'UPDATE');

    // Assert
    Assert.areEqual('TestClass', context.getClassName());
    Assert.areEqual('testMethod', context.getMethodName());
    Assert.areEqual(2, context.getCustomData().size());
  }

  @IsTest
  static void testCustomDataOverwrite() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    context.addCustomData('key', 'value1');
    context.addCustomData('key', 'value2');

    // Assert
    Assert.areEqual('value2', context.getCustomData().get('key'), 'Later value should overwrite');
  }

  @IsTest
  static void testNullCustomData() {
    // Arrange
    LogContext context = new LogContext();

    // Act & Assert - Adding null should not throw
    context.addCustomData('nullKey', null);
    Assert.isTrue(context.getCustomData().containsKey('nullKey'), 'Null value should be stored');
    Assert.isNull(context.getCustomData().get('nullKey'), 'Value should be null');
  }
}
