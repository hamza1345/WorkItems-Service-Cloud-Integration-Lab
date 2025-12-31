/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Controller Aura/LWC pour Work Items.
 * Expose les méthodes Service via @AuraEnabled pour composants Lightning.
 * 
 * Architecture:
 * - Controller (ce fichier) → Service → Selector → Database
 * - Controller gère sérialisation/désérialisation JSON pour UI
 * - Service gère orchestration + business logic
 * - Selector gère SOQL + permissions
 * 
 * Cacheable Rules:
 * - getItems() = cacheable=true (read-only, safe to cache)
 * - saveItem() / markDone() = NON cacheable (modifient data)
 */
public with sharing class WorkItemController {
  
  /**
   * @description Récupère liste de Work Items filtrés (pour dashboard/liste).
   * 
   * CACHEABLE: true
   * - Read-only operation
   * - Pas d'effets de bord
   * - Lightning Data Service peut cacher les résultats
   * - Optimise performances UI (évite roundtrips serveur)
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
    try {
      return WorkItemService.getItems(status, searchTerm, limitSize);
    } catch (BusinessException e) {
      // Wrapper BusinessException dans AuraHandledException pour UI
      throw new AuraHandledException(
        'Erreur métier: ' + e.getMessage() + ' [' + e.getErrorCode() + ']'
      );
    } catch (Exception e) {
      throw new AuraHandledException(
        'Erreur technique: ' + e.getMessage()
      );
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
   * @param item Work_Item__c à sauvegarder
   * @return Work_Item__c sauvegardé avec tous les champs
   * @throws AuraHandledException si validation échoue ou erreur DML
   */
  @AuraEnabled
  public static Work_Item__c saveItem(Work_Item__c item) {
    try {
      return WorkItemService.saveItem(item);
    } catch (BusinessException e) {
      throw new AuraHandledException(
        'Erreur métier: ' + e.getMessage() + ' [' + e.getErrorCode() + ']'
      );
    } catch (DmlException e) {
      throw new AuraHandledException(
        'Erreur sauvegarde: ' + e.getDmlMessage(0)
      );
    } catch (Exception e) {
      throw new AuraHandledException(
        'Erreur technique: ' + e.getMessage()
      );
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
   * @param workItemId Id du Work Item à marquer Done
   * @return Work_Item__c mis à jour avec Completed_On
   * @throws AuraHandledException si Work Item non trouvé ou erreur
   */
  @AuraEnabled
  public static Work_Item__c markDone(Id workItemId) {
    try {
      return WorkItemService.markDone(workItemId);
    } catch (BusinessException e) {
      throw new AuraHandledException(
        'Erreur métier: ' + e.getMessage() + ' [' + e.getErrorCode() + ']'
      );
    } catch (DmlException e) {
      throw new AuraHandledException(
        'Erreur mise à jour: ' + e.getDmlMessage(0)
      );
    } catch (Exception e) {
      throw new AuraHandledException(
        'Erreur technique: ' + e.getMessage()
      );
    }
  }
  
  /**
   * @description Récupère un Work Item par Id (pour détail).
   * 
   * CACHEABLE: true (read-only)
   * 
   * @param workItemId Id du Work Item
   * @return Work_Item__c avec tous les champs
   * @throws AuraHandledException si non trouvé
   */
  @AuraEnabled(cacheable=true)
  public static Work_Item__c getById(Id workItemId) {
    try {
      Work_Item__c item = WorkItemSelector.getById(workItemId);
      if (item == null) {
        throw BusinessException.withCode('GET_BY_ID_NOT_FOUND')
          .withMessage('Work Item non trouvé: ' + workItemId);
      }
      return item;
    } catch (BusinessException e) {
      throw new AuraHandledException(
        'Erreur métier: ' + e.getMessage() + ' [' + e.getErrorCode() + ']'
      );
    } catch (Exception e) {
      throw new AuraHandledException(
        'Erreur technique: ' + e.getMessage()
      );
    }
  }
}
