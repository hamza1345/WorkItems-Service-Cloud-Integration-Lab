/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Logger minimaliste STATIQUE pour Controller (compatible signature existing).
 * 
 * Note: Framework de logging complet existe dans logging/ mais incompatible avec usage static.
 * Ce Logger simple extend l'existant pour usage Controller uniquement.
 * 
 * Usage:
 * ControllerLogger.info('WorkItemController.getItems', 'Fetching items', 'status=New');
 * ControllerLogger.error('WorkItemController.saveItem', 'Save failed', ex, recordId);
 */
public class ControllerLogger {
  
  /**
   * @description Log INFO (entrée/sortie méthodes).
   * @param source Classe.méthode (ex: "WorkItemController.getItems")
   * @param message Message descriptif
   * @param details Détails optionnels (params, etc.)
   */
  public static void info(String source, String message, String details) {
    String corrId = LogContext.getCorrelationId();
    System.debug(LoggingLevel.INFO, '[' + corrId + '] ' + source + ' - ' + message + 
                 (String.isNotBlank(details) ? ' | ' + details : ''));
  }
  
  public static void info(String source, String message) {
    info(source, message, null);
  }
  
  /**
   * @description Log ERROR (exceptions).
   * @param source Classe.méthode
   * @param message Message erreur
   * @param ex Exception capturée
   * @param recordId Record ID impacté (optionnel)
   */
  public static void error(String source, String message, Exception ex, Id recordId) {
    String corrId = LogContext.getCorrelationId();
    String logMsg = '[' + corrId + '] ' + source + ' - ' + message;
    
    if (recordId != null) {
      logMsg += ' | RecordId=' + recordId;
    }
    
    if (ex != null) {
      logMsg += ' | Exception=' + ex.getTypeName() + ': ' + ex.getMessage();
      System.debug(LoggingLevel.ERROR, logMsg);
      System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
    } else {
      System.debug(LoggingLevel.ERROR, logMsg);
    }
  }
  
  public static void error(String source, String message, Exception ex) {
    error(source, message, ex, null);
  }
  
  public static void error(String source, String message) {
    error(source, message, null, null);
  }
}
