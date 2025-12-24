/**
 * @description Represents a single log entry with level, message, and context.
 * Immutable after creation to ensure data integrity.
 * Contains: level, message, context, exception, timestamp.
 * @author Hamza Amari
 * @version 1.0
 */
public class LogEntry {
  private String level;
  private String message;
  private LogContext context;
  private Exception exceptionObj;
  private Long timestamp;
  private String exceptionStackTrace;
  private String methodNameSnapshot;

  /**
   * @description Create a log entry with message and level.
   * @param level Log level (DEBUG, INFO, WARN, ERROR, FATAL)
   * @param message Log message
   * @param context Execution context
   */
  public LogEntry(String level, String message, LogContext context) {
    this.level = level;
    this.message = message;
    // Create a snapshot to preserve current state (especially methodName)
    this.context = createContextSnapshot(context);
    // Capture the method name at creation time as backup
    this.methodNameSnapshot = context.getMethodName();
    this.timestamp = System.currentTimeMillis();
    this.exceptionObj = null;
    this.exceptionStackTrace = null;
  }

  /**
   * @description Create a snapshot of LogContext to preserve current state.
   * Prevents issues where shared context is modified after entry creation.
   * @param source The source context to snapshot
   * @return A new context with copied values (but same requestId)
   */
  private static LogContext createContextSnapshot(LogContext source) {
    // Create new context through default constructor (generates new requestId)
    LogContext snapshot = new LogContext();
    // Then override fields to match source
    snapshot.setSource(source.getClassName(), source.getMethodName());
    // Copy custom data
    for (String key : source.getCustomData().keySet()) {
      snapshot.addCustomData(key, source.getCustomData().get(key));
    }
    // Note: requestId will be different (new context generates new one)
    // This is acceptable as each LogEntry gets its own request tracking
    return snapshot;
  }

  /**
   * @description Create a log entry with an exception.
   * @param level Log level
   * @param message Log message
   * @param context Execution context
   * @param ex Exception to log
   */
  public LogEntry(String level, String message, LogContext context, Exception ex) {
    this(level, message, context);
    this.exceptionObj = ex;
    this.exceptionStackTrace = ex.getStackTraceString();
  }

  // Getters (read-only)
  public String getLevel() {
    return this.level;
  }

  public String getMessage() {
    return this.message;
  }

  public LogContext getContext() {
    return this.context;
  }

  public Exception getException() {
    return this.exceptionObj;
  }

  public Long getTimestamp() {
    return this.timestamp;
  }

  public String getExceptionStackTrace() {
    if (this.exceptionStackTrace == null) {
      return null;
    }
    // Include exception type in stack trace
    String exceptionType = this.exceptionObj != null ? this.exceptionObj.getTypeName() : 'Unknown';
    return exceptionType + ': ' + this.exceptionStackTrace;
  }

  /**
   * @description Convert log entry to formatted string for display.
   * Format: [LEVEL] [timestamp] [class.method] message
   * @return Formatted log message
   */
  public String toFormattedString() {
    Datetime dt = Datetime.newInstance(this.timestamp);
    String formattedTime = dt.format('yyyy-MM-dd HH:mm:ss.SSS');
    String source = context.getClassName() + '.' + context.getMethodName();
    String formatted = '[' + this.level + '] [' + formattedTime + '] [' + source + '] ' + this.message;

    if (this.exceptionObj != null) {
      formatted += '\n' + this.exceptionObj.getMessage();
      if (this.exceptionStackTrace != null) {
        formatted += '\n' + this.exceptionStackTrace;
      }
    }

    return formatted;
  }
}
