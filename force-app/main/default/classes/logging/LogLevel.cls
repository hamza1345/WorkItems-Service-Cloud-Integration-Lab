/**
 * @description Enumeration of logging levels for message severity classification.
 * Follows standard logging hierarchy: DEBUG < INFO < WARN < ERROR < FATAL.
 * @author Hamza Amari
 * @version 1.0
 */
public class LogLevel {
  /**
   * @description Lowest severity - detailed diagnostic information.
   */
  public static final String DEBUG = 'DEBUG';

  /**
   * @description General informational messages about application flow.
   */
  public static final String INFO = 'INFO';

  /**
   * @description Warning messages for potentially harmful situations.
   */
  public static final String WARN = 'WARN';

  /**
   * @description Error messages for serious problems.
   */
  public static final String ERROR = 'ERROR';

  /**
   * @description Fatal messages for critical failures.
   */
  public static final String FATAL = 'FATAL';

  /**
   * @description Get numeric priority for log level (higher = more severe).
   * Used for filtering: only log if message level >= minimum configured level.
   * @param level The log level string
   * @return Priority value (0=DEBUG, 4=FATAL)
   */
  public static Integer getPriority(String level) {
    switch on level {
      when 'DEBUG' {
        return 0;
      }
      when 'INFO' {
        return 1;
      }
      when 'WARN' {
        return 2;
      }
      when 'ERROR' {
        return 3;
      }
      when 'FATAL' {
        return 4;
      }
      when else {
        return 1; // Default to INFO
      }
    }
  }

  /**
   * @description Check if a message at sourceLevel should be logged based on minLevel.
   * @param sourceLevel The message's level
   * @param minLevel The minimum level to log
   * @return true if message meets minimum level threshold
   */
  public static Boolean shouldLog(String sourceLevel, String minLevel) {
    Integer sourcePriority = getPriority(sourceLevel);
    Integer minPriority = getPriority(minLevel);
    return sourcePriority >= minPriority;
  }
}