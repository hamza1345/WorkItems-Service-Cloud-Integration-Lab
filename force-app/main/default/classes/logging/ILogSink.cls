/**
 * @description Interface for log sink implementations.
 * A sink is a destination where logs are written.
 * @author Hamza Amari
 * @version 1.0
 */
public interface ILogSink {
  /**
   * @description Write a log entry to the sink.
   * @param entry The log entry to write
   */
  void write(LogEntry entry);
}
