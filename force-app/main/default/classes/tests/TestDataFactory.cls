/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Fabrique de données de test pour créer des enregistrements de test.
 * Responsabilités :
 * - Fournir des méthodes de constructeur pour la création d'enregistrements de test
 * - Implémenter des données de test cohérentes sur toutes les classes de test
 * - Prendre en charge l'API fluide pour l'installation flexible des données de test
 * - Gérer les valeurs par défaut pour les champs obligatoires
 * - Isoler la génération de données de test de la logique de test
 *
 * Cette classe implémente le motif Builder pour une installation de test claire.
 * Toutes les méthodes sont publiques et statiques pour une utilisation facile dans les classes de test.
 */
@isTest
public class TestDataFactory {
  /**
   * @description Créer un élément de travail de test avec des valeurs par défaut.
   * @return Enregistrement Work_Item__c prêt pour l'insertion
   */
  public static Work_Item__c createTestWorkItem() {
    // TODO : Implémenter la création par défaut d'un élément de travail
    return new Work_Item__c();
  }

  /**
   * @description Créer plusieurs éléments de travail de test.
   * @param count Nombre d'éléments à créer
   * @return Liste des enregistrements Work_Item__c prêts pour l'insertion
   */
  public static List<Work_Item__c> createTestWorkItems(Integer count) {
    List<Work_Item__c> items = new List<Work_Item__c>();
    // TODO : Implémenter la création en masse
    return items;
  }

  /**
   * @description Créer un élément de travail avec des valeurs de champ spécifiques.
   * @param fields Map du nom du champ -> valeur
   * @return Enregistrement Work_Item__c avec les valeurs spécifiées
   */
  public static Work_Item__c createTestWorkItem(Map<String, Object> fields) {
    Work_Item__c item = createTestWorkItem();
    // TODO : Appliquer les remplacements de champs
    return item;
  }

  /**
   * @description Créer un élément de travail avec un statut spécifique.
   * @param status Valeur du statut
   * @return Enregistrement Work_Item__c avec le statut spécifié
   */
  public static Work_Item__c createTestWorkItemWithStatus(String status) {
    // TODO : Implémenter la création spécifique au statut
    return new Work_Item__c();
  }

  /**
   * @description Créer un élément de travail avec un Account associé.
   * @return Work_Item__c avec Account__c rempli
   */
  public static Work_Item__c createTestWorkItemWithAccount() {
    // TODO : Implémenter avec relation Account
    return new Work_Item__c();
  }

  /**
   * @description Créer un élément de travail avec un Contact associé.
   * @return Work_Item__c avec Contact__c rempli
   */
  public static Work_Item__c createTestWorkItemWithContact() {
    // TODO : Implémenter avec relation Contact
    return new Work_Item__c();
  }

  /**
   * @description Créer un élément de travail avec un Case associé.
   * @return Work_Item__c avec Case__c rempli
   */
  public static Work_Item__c createTestWorkItemWithCase() {
    // TODO : Implémenter avec relation Case
    return new Work_Item__c();
  }

  /**
   * @description Insérer les éléments de travail de test et retourner avec les Ids remplis.
   * @param workItems Liste à insérer
   * @return Liste avec Ids remplis
   */
  public static List<Work_Item__c> insertWorkItems(List<Work_Item__c> workItems) {
    // TODO : Implémenter l'insertion avec gestion des erreurs
    return workItems;
  }

  /**
   * @description Créer un Account de test pour les relations.
   * @return Enregistrement Account prêt pour l'insertion
   */
  public static Account createTestAccount() {
    // TODO : Implémenter la création d'Account de test
    return new Account();
  }

  /**
   * @description Créer un Contact de test pour les relations.
   * @return Enregistrement Contact prêt pour l'insertion
   */
  public static Contact createTestContact() {
    // TODO : Implémenter la création de Contact de test
    return new Contact();
  }

  /**
   * @description Créer un Case de test pour les relations.
   * @return Enregistrement Case prêt pour l'insertion
   */
  public static Case createTestCase() {
    // TODO : Implémenter la création de Case de test
    return new Case();
  }
}
