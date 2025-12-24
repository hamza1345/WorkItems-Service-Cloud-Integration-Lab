/**
 * @description Main logger class for application logging.
 * Manages log entries and routes them to configured sinks (Debug, PlatformEvent).
 * Supports method chaining for fluent API.
 * Thread-safe logging with configurable levels and persistence.
 * @author Hamza Amari
 * @version 1.0
 */
public class Logger {
  private String className;
  private LogContext context;
  private String minLevel;
  private Boolean persistEnabled;
  private Boolean perfLoggingEnabled;
  private List<LogEntry> entries;
  private List<ILogSink> sinks;
  private Boolean isCustomContext;

  /**
   * @description Create a Logger for a specific class.
   * @param className Name of the calling class
   */
  public Logger(String className) {
    this(className, new LogContext());
  }

  /**
   * @description Create a Logger with custom context.
   * @param className Name of the calling class
   * @param context Execution context for logging
   */
  public Logger(String className, LogContext context) {
    this.className = className;
    this.context = context;
    // Check if context came pre-configured (custom context)
    this.isCustomContext = this.context.getClassName() != null && this.context.getClassName() != '';
    // Only set source if not already set (preserve custom context)
    if (!this.isCustomContext) {
      this.context.setSource(className, 'N/A');
    }
    this.minLevel = LogLevel.DEBUG;
    this.persistEnabled = false;
    this.perfLoggingEnabled = false;
    this.entries = new List<LogEntry>();
    this.sinks = initializeSinks();
  }

  /**
   * @description Initialize available sinks.
   * Currently: DebugSink (System.debug) and PlatformEventSink.
   * @return List of configured sinks
   */
  private List<ILogSink> initializeSinks() {
    List<ILogSink> configuredSinks = new List<ILogSink>();
    configuredSinks.add(new DebugSink());
    if (this.persistEnabled) {
      configuredSinks.add(new PlatformEventSink());
    }
    return configuredSinks;
  }

  /**
   * @description Set the minimum log level.
   * @param level Log level (DEBUG, INFO, WARN, ERROR, FATAL)
   * @return this for method chaining
   */
  public Logger setMinLevel(String level) {
    this.minLevel = level;
    return this;
  }

  /**
   * @description Enable/disable log persistence.
   * @param enabled true to persist logs
   * @return this for method chaining
   */
  public Logger setPersistEnabled(Boolean enabled) {
    this.persistEnabled = enabled;
    if (enabled && !hasPlatformEventSink()) {
      this.sinks.add(new PlatformEventSink());
    }
    return this;
  }

  /**
   * @description Enable/disable performance logging.
   * @param enabled true to log performance metrics
   * @return this for method chaining
   */
  public Logger setPerfLoggingEnabled(Boolean enabled) {
    this.perfLoggingEnabled = enabled;
    return this;
  }

  /**
   * @description Check if PlatformEventSink is already initialized.
   * @return true if PlatformEventSink exists
   */
  private Boolean hasPlatformEventSink() {
    for (ILogSink sink : this.sinks) {
      if (sink instanceof PlatformEventSink) {
        return true;
      }
    }
    return false;
  }

  /**
   * @description Log a DEBUG level message.
   * @param methodName Name of the calling method
   * @param message Message to log
   * @return this for method chaining
   */
  public Logger debug(String methodName, String message) {
    return log(LogLevel.DEBUG, methodName, message);
  }

  /**
   * @description Log an INFO level message.
   * @param methodName Name of the calling method
   * @param message Message to log
   * @return this for method chaining
   */
  public Logger info(String methodName, String message) {
    return log(LogLevel.INFO, methodName, message);
  }

  /**
   * @description Log a WARN level message.
   * @param methodName Name of the calling method
   * @param message Message to log
   * @return this for method chaining
   */
  public Logger warn(String methodName, String message) {
    return log(LogLevel.WARN, methodName, message);
  }

  /**
   * @description Log an ERROR level message.
   * @param methodName Name of the calling method
   * @param message Message to log
   * @return this for method chaining
   */
  public Logger error(String methodName, String message) {
    return log(LogLevel.ERROR, methodName, message);
  }

  /**
   * @description Log an ERROR level message with exception.
   * @param methodName Name of the calling method
   * @param message Message to log
   * @param ex Exception to log
   * @return this for method chaining
   */
  public Logger error(String methodName, String message, Exception ex) {
    return log(LogLevel.ERROR, methodName, message, ex);
  }

  /**
   * @description Log a FATAL level message.
   * @param methodName Name of the calling method
   * @param message Message to log
   * @return this for method chaining
   */
  public Logger fatal(String methodName, String message) {
    return log(LogLevel.FATAL, methodName, message);
  }

  /**
   * @description Log a FATAL level message with exception.
   * @param methodName Name of the calling method
   * @param message Message to log
   * @param ex Exception to log
   * @return this for method chaining
   */
  public Logger fatal(String methodName, String message, Exception ex) {
    return log(LogLevel.FATAL, methodName, message, ex);
  }

  /**
   * @description Generic log method for custom level.
   * Checks minimum level before creating entry.
   * @param level Log level
   * @param methodName Calling method name
   * @param message Log message
   * @return this for method chaining
   */
  private Logger log(String level, String methodName, String message) {
    if (!LogLevel.shouldLog(level, this.minLevel)) {
      return this;
    }

    // For custom contexts, preserve the original method name
    // For regular contexts, update with the provided method name
    if (!this.isCustomContext) {
      this.context.setSource(this.context.getClassName(), methodName);
    }
    LogEntry entry = new LogEntry(level, message, this.context);
    this.entries.add(entry);

    // Route to all sinks
    for (ILogSink sink : this.sinks) {
      sink.write(entry);
    }

    return this;
  }

  /**
   * @description Generic log method with exception.
   * @param level Log level
   * @param methodName Calling method name
   * @param message Log message
   * @param ex Exception to log
   * @return this for method chaining
   */
  private Logger log(String level, String methodName, String message, Exception ex) {
    if (!LogLevel.shouldLog(level, this.minLevel)) {
      return this;
    }

    this.context.setSource(this.className, methodName);
    LogEntry entry = new LogEntry(level, message, this.context, ex);
    this.entries.add(entry);

    for (ILogSink sink : this.sinks) {
      sink.write(entry);
    }

    return this;
  }

  /**
   * @description Log performance metrics (execution time).
   * Only logs if perfLoggingEnabled is true.
   * @param methodName Calling method name
   * @param operationName Name of the operation being measured
   * @param durationMs Duration in milliseconds
   * @return this for method chaining
   */
  public Logger logPerformance(String methodName, String operationName, Long durationMs) {
    if (!this.perfLoggingEnabled) {
      return this;
    }

    String perfMessage = 'Performance: ' + operationName + ' took ' + durationMs + 'ms';
    return info(methodName, perfMessage);
  }

  /**
   * @description Get all buffered log entries.
   * @return List of LogEntry objects
   */
  public List<LogEntry> getEntries() {
    return new List<LogEntry>(this.entries);
  }

  /**
   * @description Clear all buffered entries.
   * @return this for method chaining
   */
  public Logger clearEntries() {
    this.entries.clear();
    return this;
  }

  /**
   * @description Get count of buffered entries.
   * @return Number of log entries
   */
  public Integer getEntryCount() {
    return this.entries.size();
  }
}
