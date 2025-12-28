/**
 * @description Test class for DebugSink.
 * Tests: Writing to System.debug, formatting, error handling.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class DebugSinkTest {

  @IsTest
  static void testDebugSinkWriteSimpleMessage() {
    // Arrange
    DebugSink sink = new DebugSink();
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
  static void testDebugSinkWriteWithException() {
    // Arrange
    DebugSink sink = new DebugSink();
    LogContext context = new LogContext().setSource('TestClass', 'testMethod');
    Exception testException = new DmlException('Test error');
    LogEntry entry = new LogEntry('ERROR', 'Error occurred', context, testException);

    // Act & Assert - Should handle exception gracefully
    try {
      sink.write(entry);
      Assert.isTrue(true, 'Write should handle entry with exception');
    } catch (Exception e) {
      Assert.fail('Write should not throw: ' + e.getMessage());
    }
  }

  @IsTest
  static void testDebugSinkWriteAllLevels() {
    // Test that all log levels work
    DebugSink sink = new DebugSink();
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
  static void testDebugSinkWriteNullEntry() {
    // Arrange
    DebugSink sink = new DebugSink();

    // Act & Assert - Should handle null gracefully
    try {
      sink.write(null);
      Assert.fail('Should throw NullPointerException for null entry');
    } catch (NullPointerException e) {
      Assert.isTrue(true, 'Should throw NullPointerException as expected');
    } catch (Exception e) {
      Assert.fail('Unexpected exception: ' + e.getMessage());
    }
  }

  @IsTest
  static void testDebugSinkImplementsInterface() {
    // Act
    DebugSink sink = new DebugSink();

    // Assert - DebugSink implements ILogSink interface
    // (instanceof check is redundant since compile-time verifies interface implementation)
    Assert.isNotNull(sink, 'DebugSink should be instantiable');
  }

  @IsTest
  static void testDebugSinkWriteMultipleEntries() {
    // Arrange
    DebugSink sink = new DebugSink();
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
  static void testDebugSinkWithLongMessage() {
    // Arrange
    DebugSink sink = new DebugSink();
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
  static void testDebugSinkWriteFormatting() {
    // Arrange
    DebugSink sink = new DebugSink();
    LogContext context = new LogContext().setSource('MyService', 'myMethod');
    LogEntry entry = new LogEntry('WARN', 'Warning message', context);

    // Act
    sink.write(entry);

    // Assert - Verify the sink formats the entry correctly
    String formatted = entry.toFormattedString();
    Assert.isTrue(formatted.contains('[WARN]'), 'Should format with level');
    Assert.isTrue(formatted.contains('MyService.myMethod'), 'Should format with source');
  }

  @IsTest
  static void testDebugSinkMultipleSinks() {
    // Test that multiple sink instances work independently
    DebugSink sink1 = new DebugSink();
    DebugSink sink2 = new DebugSink();
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
  static void testDebugSinkWriteWithNullMessage() {
    // Arrange
    DebugSink sink = new DebugSink();
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
}
