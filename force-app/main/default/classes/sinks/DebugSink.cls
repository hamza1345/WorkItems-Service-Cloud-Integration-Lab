/**
 * @description Log sink that writes to System.debug().
 * Useful for development and debugging in logs.
 * Always enabled for immediate visibility.
 * @author Hamza Amari
 * @version 1.0
 */
public class DebugSink implements ILogSink {
  /**
   * @description Write log entry to System.debug.
   * Formats entry for readability with level, timestamp, class.method.
   * @param entry Log entry to write
   */
  public void write(LogEntry entry) {
    String formattedMessage = entry.toFormattedString();
    // Convert log level string to LoggingLevel enum
    LoggingLevel logLevel = getLoggingLevel(entry.getLevel());
    System.debug(logLevel, formattedMessage);
  }

  /**
   * @description Convert log level string to LoggingLevel enum.
   * Note: LoggingLevel enum doesn't have FATAL, so map it to ERROR.
   * @param levelString Log level as string
   * @return Corresponding LoggingLevel enum value
   */
  private LoggingLevel getLoggingLevel(String levelString) {
    switch on levelString {
      when 'DEBUG' {
        return LoggingLevel.DEBUG;
      }
      when 'INFO' {
        return LoggingLevel.INFO;
      }
      when 'WARN' {
        return LoggingLevel.WARN;
      }
      when 'ERROR' {
        return LoggingLevel.ERROR;
      }
      when 'FATAL' {
        return LoggingLevel.ERROR;  // Map FATAL to ERROR (FATAL doesn't exist in LoggingLevel)
      }
      when else {
        return LoggingLevel.INFO;
      }
    }
  }
}
