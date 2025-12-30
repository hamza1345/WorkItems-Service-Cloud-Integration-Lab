/**
 * @description Log sink that publishes to Platform Event.
 * Enables asynchronous log processing and persistence.
 * Handled by trigger subscriber App_Log_EventSubscriber.
 * @author Hamza Amari
 * @version 1.0
 */
public class PlatformEventSink implements ILogSink {
  private static final Logger LOGGER = LoggerFactory.getLogger('PlatformEventSink');

  /**
   * @description Publish log entry as Platform Event.
   * Creates App_Log__e event with structured data.
   * Fire-and-forget: does not wait for processing.
   * @param entry Log entry to publish
   */
  public void write(LogEntry entry) {
    try {
      // Create the Platform Event
      App_Log__e logEvent = new App_Log__e(
        Level__c = entry.getLevel(),
        Message__c = entry.getMessage(),
        Request_Id__c = entry.getContext().getRequestId(),
        Class_Name__c = entry.getContext().getClassName(),
        Method_Name__c = entry.getContext().getMethodName(),
        User_Id__c = entry.getContext().getUserId(),
        Exception_Message__c = entry.getException() != null
          ? entry.getException().getMessage()
          : null,
        Exception_Stack_Trace__c = entry.getExceptionStackTrace()
      );

      // Publish the event
      List<Database.SaveResult> results = EventBus.publish(new List<App_Log__e>{ logEvent });

      // Check results
      for (Database.SaveResult result : results) {
        if (!result.isSuccess()) {
          for (Database.Error error : result.getErrors()) {
            LOGGER.warn('write', 'Publication error: ' + error.getMessage());
          }
        }
      }
    } catch (Exception e) {
      // Fail silently - don't break application if logging fails
      LOGGER.error('write', 'Error publishing log event', e);
    }
  }
}
