/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Controller Aura/LWC pour Work Items - JOUR 5 version PRO.
 * Expose les méthodes Service via @AuraEnabled pour composants Lightning.
 * 
 * Architecture:
 * - Controller (ce fichier) → Service → Selector → Database
 * - Controller gère sérialisation/désérialisation JSON pour UI
 * - Service gère orchestration + business logic
 * - Selector gère SOQL + permissions
 * 
 * Règles Controller (Senior):
 * ❌ Aucune logique métier (déléguer à Service)
 * ❌ Aucun SOQL direct (utiliser Selector via Service)
 * ❌ Aucun callout (utiliser Queueable)
 * ✅ Validation légère (null checks, limits)
 * ✅ Exception handling avec UiError + correlationId
 * 
 * Cacheable Rules:
 * - getItems() / getById() = cacheable=true (read-only, pas de DML/callout)
 * - saveItem() / markDone() = NON cacheable (modifient data)
 * 
 * Error Handling:
 * - Toutes les exceptions wrappées dans AuraHandledException
 * - UiError.create() génère correlationId automatique
 * - Format message: "{message} [Réf: {correlationId}]"
 */
public with sharing class WorkItemController {
  
  private static final Integer DEFAULT_LIMIT = 50;
  private static final Integer MAX_LIMIT = 100;
  
  /**
   * @description Récupère liste de Work Items filtrés (pour dashboard/liste).
   * 
   * CACHEABLE: true
   * - Read-only operation
   * - Pas d'effets de bord (pas de DML/callout)
   * - Lightning Data Service peut cacher les résultats
   * - Optimise performances UI (évite roundtrips serveur)
   * 
   * Logging:
   * - INFO entrée avec params
   * - DEBUG sortie avec count
   * - ERROR si exception
   * 
   * @param status Statut filter (optionnel: null = tous statuts)
   * @param searchTerm Recherche texte sur Name/Category (optionnel)
   * @param limitSize Nombre max résultats (default: 50, max: 100)
   * @return List<Work_Item__c> Work Items triés par LastModifiedDate DESC
   * @throws AuraHandledException si erreur métier ou technique
   */
  @AuraEnabled(cacheable=true)
  public static List<Work_Item__c> getItems(
    String status,
    String searchTerm,
    Integer limitSize
  ) {
    // Validation + defaults
    if (limitSize == null || limitSize <= 0) {
      limitSize = DEFAULT_LIMIT;
    } else if (limitSize > MAX_LIMIT) {
      limitSize = MAX_LIMIT;
    }
    
    try {
      return WorkItemService.getItems(status, searchTerm, limitSize);
    } catch (BusinessException e) {
      UiError err = UiError.create(e.getErrorCode(), e.getMessage());
      throw new AuraHandledException(err.toMessage());
    } catch (Exception e) {
      UiError err = UiError.create('FETCH_ITEMS_FAILED', 
        'Impossible de récupérer les work items');
      throw new AuraHandledException(err.toMessage());
    }
  }
  
  /**
   * @description Sauvegarde un Work Item (insert ou update).
   * 
   * CACHEABLE: false (modifie data)
   * - Insert si item.Id == null
   * - Update si item.Id != null
   * - Trigger/Domain appliquent règles métier + valeurs par défaut
   * 
   * Logging:
   * - INFO entrée avec operation (INSERT/UPDATE)
   * - DEBUG sortie avec recordId
   * - ERROR si exception avec recordId
   * 
   * @param item Work_Item__c à sauvegarder
   * @return Work_Item__c sauvegardé avec tous les champs
   * @throws AuraHandledException si validation échoue ou erreur DML
   */
  @AuraEnabled
  public static Work_Item__c saveItem(Work_Item__c item) {
    // Validation
    if (item == null) {
      UiError err = UiError.create('SAVE_ITEM_NULL', 
        'Work Item ne peut pas être null');
      throw new AuraHandledException(err.toMessage());
    }
    
    try {
      return WorkItemService.saveItem(item);
    } catch (BusinessException e) {
      UiError err = UiError.create(e.getErrorCode(), e.getMessage());
      throw new AuraHandledException(err.toMessage());
    } catch (DmlException e) {
      UiError err = UiError.create('SAVE_ITEM_DML_FAILED', 
        'Erreur sauvegarde: ' + e.getDmlMessage(0));
      throw new AuraHandledException(err.toMessage());
    } catch (Exception e) {
      UiError err = UiError.create('SAVE_ITEM_FAILED', 
        'Impossible de sauvegarder le work item');
      throw new AuraHandledException(err.toMessage());
    }
  }
  
  /**
   * @description Marque un Work Item comme Done (terminé).
   * 
   * CACHEABLE: false (modifie data)
   * - Set Status__c = 'Done'
   * - Trigger applique Completed_On__c = NOW
   * - Enqueue sync externe si activée (stub Jour 10)
   * 
   * Logging:
   * - INFO entrée avec recordId
   * - DEBUG sortie avec Status + Completed_On
   * - ERROR si exception avec recordId
   * 
   * @param workItemId Id du Work Item à marquer Done
   * @return Work_Item__c mis à jour avec Completed_On
   * @throws AuraHandledException si Work Item non trouvé ou erreur
   */
  @AuraEnabled
  public static Work_Item__c markDone(Id workItemId) {
    // Validation
    if (workItemId == null) {
      UiError err = UiError.create('MARK_DONE_NULL_ID', 
        'Work Item ID ne peut pas être null');
      throw new AuraHandledException(err.toMessage());
    }
    
    try {
      return WorkItemService.markDone(workItemId);
    } catch (BusinessException e) {
      UiError err = UiError.create(e.getErrorCode(), e.getMessage());
      throw new AuraHandledException(err.toMessage());
    } catch (DmlException e) {
      UiError err = UiError.create('MARK_DONE_DML_FAILED', 
        'Erreur mise à jour: ' + e.getDmlMessage(0));
      throw new AuraHandledException(err.toMessage());
    } catch (Exception e) {
      UiError err = UiError.create('MARK_DONE_FAILED', 
        'Impossible de clôturer le work item');
      throw new AuraHandledException(err.toMessage());
    }
  }
  
  /**
   * @description Récupère un Work Item par Id (pour détail).
   * 
   * CACHEABLE: true (read-only)
   * - Pas d'effets de bord
   * - Utilisé pour pages détail / modals
   * 
   * Logging:
   * - INFO entrée avec recordId
   * - DEBUG sortie avec success
   * - ERROR si non trouvé ou exception
   * 
   * @param workItemId Id du Work Item
   * @return Work_Item__c avec tous les champs
   * @throws AuraHandledException si non trouvé
   */
  @AuraEnabled(cacheable=true)
  public static Work_Item__c getById(Id workItemId) {
    // Validation
    if (workItemId == null) {
      UiError err = UiError.create('GET_BY_ID_NULL_ID', 
        'Work Item ID ne peut pas être null');
      throw new AuraHandledException(err.toMessage());
    }
    
    try {
      Work_Item__c item = WorkItemSelector.getById(workItemId);
      
      if (item == null) {
        throw BusinessException.withCode('GET_BY_ID_NOT_FOUND')
          .withMessage('Work Item non trouvé');
      }
      
      return item;
    } catch (BusinessException e) {
      UiError err = UiError.create(e.getErrorCode(), e.getMessage());
      throw new AuraHandledException(err.toMessage());
    } catch (Exception e) {
      UiError err = UiError.create('GET_BY_ID_FAILED', 
        'Impossible de récupérer le work item');
      throw new AuraHandledException(err.toMessage());
    }
  }
}
