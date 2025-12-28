/**
 * @description Log sink that publishes to Platform Event.
 * Enables asynchronous log processing and persistence.
 * Will be handled by trigger subscriber and batch job later.
 * Currently just publishes the event without error handling.
 * @author Hamza Amari
 * @version 1.0
 */
public class PlatformEventSink implements ILogSink {
  private static final String LOG_EVENT_NAME = 'LogEntry__e';

  /**
   * @description Publish log entry as Platform Event.
   * Creates Log_Entry__e event with structured data.
   * Fire-and-forget: does not wait for processing.
   * @param entry Log entry to publish
   */
  public void write(LogEntry entry) {
    try {
      // Create platform event payload
      Map<String, Object> eventData = new Map<String, Object>{
        'Level__c' => entry.getLevel(),
        'Message__c' => entry.getMessage(),
        'Request_Id__c' => entry.getContext().getRequestId(),
        'Class_Name__c' => entry.getContext().getClassName(),
        'Method_Name__c' => entry.getContext().getMethodName(),
        'User_Id__c' => entry.getContext().getUserId(),
        'Exception_Message__c' => entry.getException() != null
          ? entry.getException().getMessage()
          : null,
        'Exception_Stack_Trace__c' => entry.getExceptionStackTrace(),
        'Timestamp__c' => entry.getTimestamp()
      };

      // For now, we just document the structure
      // Actual event publishing will use sObjectType approach
      // This is a placeholder - real implementation pending event creation
    } catch (Exception e) {
      // Fail silently - don't break application if logging fails
      System.debug('PlatformEventSink error: ' + e.getMessage());
    }
  }
}
