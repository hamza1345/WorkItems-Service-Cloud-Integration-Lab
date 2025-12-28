/**
 * @description Test class for LogEntry.
 * Tests: Entry creation, exception handling, formatting, immutability.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class LogEntryTest {

  @IsTest
  static void testLogEntryCreation() {
    // Arrange
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');

    // Act
    LogEntry entry = new LogEntry('INFO', 'Test message', context);

    // Assert
    Assert.areEqual('INFO', entry.getLevel());
    Assert.areEqual('Test message', entry.getMessage());
    // Note: entry.getContext() returns a snapshot, so compare properties instead of object reference
    Assert.areEqual(context.getClassName(), entry.getContext().getClassName());
    Assert.areEqual(context.getMethodName(), entry.getContext().getMethodName());
    Assert.isNull(entry.getException());
  }

  @IsTest
  static void testLogEntryWithException() {
    // Arrange
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');
    Exception testException = new DmlException('Test error');

    // Act
    LogEntry entry = new LogEntry('ERROR', 'Error occurred', context, testException);

    // Assert
    Assert.areEqual('ERROR', entry.getLevel());
    Assert.areEqual('Error occurred', entry.getMessage());
    Assert.isNotNull(entry.getException());
    Assert.areEqual('Test error', entry.getException().getMessage());
    Assert.isNotNull(entry.getExceptionStackTrace());
  }

  @IsTest
  static void testLogEntryTimestamp() {
    // Arrange
    LogContext context = new LogContext();
    Long beforeEntry = System.currentTimeMillis();

    // Act
    LogEntry entry = new LogEntry('INFO', 'Test', context);
    Long afterEntry = System.currentTimeMillis();

    // Assert
    Long timestamp = entry.getTimestamp();
    Assert.isTrue(timestamp >= beforeEntry, 'Timestamp should be after creation');
    Assert.isTrue(timestamp <= afterEntry, 'Timestamp should be before now');
  }

  @IsTest
  static void testLogEntryWithAllLevels() {
    // Test that each level can be used
    LogContext context = new LogContext();

    LogEntry debugEntry = new LogEntry('DEBUG', 'Debug', context);
    LogEntry infoEntry = new LogEntry('INFO', 'Info', context);
    LogEntry warnEntry = new LogEntry('WARN', 'Warn', context);
    LogEntry errorEntry = new LogEntry('ERROR', 'Error', context);
    LogEntry fatalEntry = new LogEntry('FATAL', 'Fatal', context);

    Assert.areEqual('DEBUG', debugEntry.getLevel());
    Assert.areEqual('INFO', infoEntry.getLevel());
    Assert.areEqual('WARN', warnEntry.getLevel());
    Assert.areEqual('ERROR', errorEntry.getLevel());
    Assert.areEqual('FATAL', fatalEntry.getLevel());
  }

  @IsTest
  static void testToFormattedString() {
    // Arrange
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');
    LogEntry entry = new LogEntry('INFO', 'Test message', context);

    // Act
    String formatted = entry.toFormattedString();

    // Assert
    Assert.isTrue(formatted.contains('[INFO]'), 'Should contain level');
    Assert.isTrue(formatted.contains('TestClass.testMethod'), 'Should contain class.method');
    Assert.isTrue(formatted.contains('Test message'), 'Should contain message');
  }

  @IsTest
  static void testFormattedStringWithException() {
    // Arrange
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');
    Exception testException = new DmlException('Test error');
    LogEntry entry = new LogEntry('ERROR', 'Error message', context, testException);

    // Act
    String formatted = entry.toFormattedString();

    // Assert
    Assert.isTrue(formatted.contains('[ERROR]'), 'Should contain error level');
    Assert.isTrue(formatted.contains('Test error'), 'Should contain exception message');
  }

  @IsTest
  static void testFormattedStringFormat() {
    // Arrange
    LogContext context = new LogContext().setSource('MyService', 'doSomething');
    LogEntry entry = new LogEntry('WARN', 'Configuration warning', context);

    // Act
    String formatted = entry.toFormattedString();

    // Assert - Format should be: [LEVEL] [timestamp] [class.method] message
    Assert.isTrue(formatted.contains('[WARN]'), 'Should have [WARN]');
    Assert.isTrue(formatted.contains('MyService.doSomething'), 'Should have class.method');
    Assert.isTrue(formatted.contains('Configuration warning'), 'Should have message');
  }

  @IsTest
  static void testLogEntryImmutability() {
    // Arrange
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');

    // Act
    LogEntry entry = new LogEntry('INFO', 'Test message', context);
    String originalMessage = entry.getMessage();
    String originalLevel = entry.getLevel();

    // Assert - Getters should always return same values
    Assert.areEqual(originalMessage, entry.getMessage());
    Assert.areEqual(originalLevel, entry.getLevel());
    Assert.areEqual(originalMessage, entry.getMessage());
  }

  @IsTest
  static void testLogEntryMultipleExceptions() {
    // Test different exception types
    LogContext context = new LogContext();

    Exception dmlEx = new DmlException('DML error');
    Exception queryEx = new QueryException('Query error');

    LogEntry dmlEntry = new LogEntry('ERROR', 'DML failed', context, dmlEx);
    LogEntry queryEntry = new LogEntry('ERROR', 'Query failed', context, queryEx);

    Assert.isTrue(
      dmlEntry.getExceptionStackTrace().contains('DmlException'),
      'Should capture DML exception type'
    );
    Assert.isTrue(
      queryEntry.getExceptionStackTrace().contains('QueryException'),
      'Should capture Query exception type'
    );
  }

  @IsTest
  static void testLogEntryNullMessage() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    LogEntry entry = new LogEntry('INFO', null, context);

    // Assert - Should handle null gracefully
    Assert.isNull(entry.getMessage());
    String formatted = entry.toFormattedString();
    Assert.isNotNull(formatted);
  }

  @IsTest
  static void testLogEntryEmptyMessage() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    LogEntry entry = new LogEntry('INFO', '', context);

    // Assert
    Assert.areEqual('', entry.getMessage());
    String formatted = entry.toFormattedString();
    Assert.isTrue(formatted.contains('[INFO]'));
  }

  @IsTest
  static void testLogEntryLongMessage() {
    // Arrange
    LogContext context = new LogContext();
    String longMessage = 'A'.repeat(5000);

    // Act
    LogEntry entry = new LogEntry('INFO', longMessage, context);

    // Assert
    Assert.areEqual(longMessage, entry.getMessage());
    String formatted = entry.toFormattedString();
    Assert.isTrue(formatted.contains(longMessage));
  }

  @IsTest
  static void testLogEntryContextAccess() {
    // Arrange
    LogContext context = new LogContext().setSource('TestClass', 'testMethod')
      .addCustomData('recordId', '001xx000003DHfAAM');

    // Act
    LogEntry entry = new LogEntry('INFO', 'Test', context);

    // Assert - Should be able to access context data through entry
    Assert.areEqual(context.getClassName(), entry.getContext().getClassName());
    Assert.areEqual(context.getMethodName(), entry.getContext().getMethodName());
    Assert.areEqual(context.getCustomData(), entry.getContext().getCustomData());
  }
}
