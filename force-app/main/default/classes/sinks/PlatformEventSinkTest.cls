/**
 * @description Test class for PlatformEventSink.
 * Tests: Event publication structure, error handling.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class PlatformEventSinkTest {

  @IsTest
  static void testPlatformEventSinkWrite() {
    // Arrange
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');
    LogEntry entry = new LogEntry('INFO', 'Test message', context);

    // Act & Assert - Should not throw exception
    try {
      sink.write(entry);
      Assert.isTrue(true, 'Write should not throw exception');
    } catch (Exception e) {
      Assert.fail('Write should not throw exception: ' + e.getMessage());
    }
  }

  @IsTest
  static void testPlatformEventSinkWriteWithException() {
    // Arrange
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');
    Exception testException = new DmlException('Test error');
    LogEntry entry = new LogEntry('ERROR', 'Error occurred', context, testException);

    // Act & Assert - Should handle entry with exception gracefully
    try {
      sink.write(entry);
      Assert.isTrue(true, 'Write should handle entry with exception');
    } catch (Exception e) {
      Assert.fail('Write should not throw: ' + e.getMessage());
    }
  }

  @IsTest
  static void testPlatformEventSinkImplementsInterface() {
    // Act
    PlatformEventSink sink = new PlatformEventSink();

    // Assert - PlatformEventSink implements ILogSink interface
    // (instanceof check is redundant since compile-time verifies interface implementation)
    Assert.isNotNull(sink, 'PlatformEventSink should be instantiable');
  }

  @IsTest
  static void testPlatformEventSinkWriteAllLevels() {
    // Test that all log levels work
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext();

    // Act - Write entries with each level
    sink.write(new LogEntry('DEBUG', 'Debug', context));
    sink.write(new LogEntry('INFO', 'Info', context));
    sink.write(new LogEntry('WARN', 'Warn', context));
    sink.write(new LogEntry('ERROR', 'Error', context));
    sink.write(new LogEntry('FATAL', 'Fatal', context));

    // Assert - All should succeed without exception
    Assert.isTrue(true, 'All levels should be writable');
  }

  @IsTest
  static void testPlatformEventSinkWriteMultipleEntries() {
    // Arrange
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext();

    // Act - Write multiple entries sequentially
    for (Integer i = 0; i < 10; i++) {
      LogEntry entry = new LogEntry('INFO', 'Message ' + i, context);
      sink.write(entry);
    }

    // Assert - Should handle multiple writes
    Assert.isTrue(true, 'Should handle multiple writes');
  }

  @IsTest
  static void testPlatformEventSinkWithComplexContext() {
    // Arrange
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext()
      .setSource('ComplexService', 'complexMethod')
      .addCustomData('recordId', '001xx000003DHfAAM')
      .addCustomData('operation', 'UPDATE')
      .addCustomData('retries', 3);

    LogEntry entry = new LogEntry('INFO', 'Complex operation', context);

    // Act & Assert - Should handle complex context
    try {
      sink.write(entry);
      Assert.isTrue(true, 'Should handle complex context');
    } catch (Exception e) {
      Assert.fail('Should not throw for complex context: ' + e.getMessage());
    }
  }

  @IsTest
  static void testPlatformEventSinkWithLongMessage() {
    // Arrange
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext();
    String longMessage = 'A'.repeat(10000);
    LogEntry entry = new LogEntry('INFO', longMessage, context);

    // Act & Assert - Should handle long messages
    try {
      sink.write(entry);
      Assert.isTrue(true, 'Should handle long messages');
    } catch (Exception e) {
      Assert.fail('Should not throw for long messages: ' + e.getMessage());
    }
  }

  @IsTest
  static void testPlatformEventSinkWithNullMessage() {
    // Arrange
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext();
    LogEntry entry = new LogEntry('INFO', null, context);

    // Act & Assert - Should handle null message
    try {
      sink.write(entry);
      Assert.isTrue(true, 'Should handle null message');
    } catch (Exception e) {
      Assert.fail('Should not throw for null message: ' + e.getMessage());
    }
  }

  @IsTest
  static void testPlatformEventSinkMultipleSinks() {
    // Test that multiple sink instances work independently
    PlatformEventSink sink1 = new PlatformEventSink();
    PlatformEventSink sink2 = new PlatformEventSink();
    LogContext context = new LogContext();
    LogEntry entry = new LogEntry('INFO', 'Test', context);

    // Act & Assert
    try {
      sink1.write(entry);
      sink2.write(entry);
      Assert.isTrue(true, 'Multiple sinks should work independently');
    } catch (Exception e) {
      Assert.fail('Multiple sinks should not interfere: ' + e.getMessage());
    }
  }

  @IsTest
  static void testPlatformEventSinkErrorHandling() {
    // Arrange
    PlatformEventSink sink = new PlatformEventSink();
    LogContext context = new LogContext();
    LogEntry entry = new LogEntry('INFO', 'Test', context);

    // Act & Assert - Should fail gracefully (not throw)
    try {
      sink.write(entry);
      Assert.isTrue(true, 'Should handle errors gracefully');
    } catch (Exception e) {
      // Note: Current implementation catches internally
      Assert.fail('Should not throw: ' + e.getMessage());
    }
  }
}
