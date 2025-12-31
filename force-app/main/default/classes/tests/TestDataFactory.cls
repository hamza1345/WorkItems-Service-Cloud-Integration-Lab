/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Factory pour créer des données de test pour Work_Item__c.
 * Centralise la création de test data pour maintenir la cohérence entre tests.
 */
@IsTest
public class TestDataFactory {
  /**
   * @description Crée un Work_Item__c avec valeurs par défaut pour tests.
   * @param name Le nom de l'élément (unique)
   * @return Work_Item__c non-inséré
   */
  public static Work_Item__c createWorkItem(String name) {
    return new Work_Item__c(
      Name = name,
      Status__c = 'New',
      Priority__c = 'Medium',
      Description__c = 'Test description for ' + name,
      Due_Date__c = System.today().addDays(7),
      Category__c = 'Development'
    );
  }

  /**
   * @description Crée un Work_Item__c avec des paramètres personnalisés.
   * @param name Le nom de l'élément
   * @param status Le statut (New, In_Progress, Done, etc.)
   * @param priority La priorité (Low, Medium, High, Critical)
   * @param dueDate La date d'échéance
   * @return Work_Item__c non-inséré
   */
  public static Work_Item__c createWorkItem(
    String name,
    String status,
    String priority,
    Date dueDate
  ) {
    return new Work_Item__c(
      Name = name,
      Status__c = status,
      Priority__c = priority,
      Description__c = 'Test description for ' + name,
      Due_Date__c = dueDate,
      Category__c = 'Development'
    );
  }

  /**
   * @description Crée un Work_Item__c avec tous les champs remplis.
   * @param name Le nom de l'élément
   * @param status Le statut
   * @param priority La priorité
   * @param dueDate La date d'échéance
   * @param category La catégorie
   * @param externalId L'identifiant externe
   * @return Work_Item__c non-inséré
   */
  public static Work_Item__c createWorkItemFull(
    String name,
    String status,
    String priority,
    Date dueDate,
    String category,
    String externalId
  ) {
    Work_Item__c item = new Work_Item__c(
      Name = name,
      Status__c = status,
      Priority__c = priority,
      Description__c = 'Test description for ' + name,
      Due_Date__c = dueDate,
      Category__c = category,
      External_Id__c = externalId
    );

    // Si statut est Done, remplir Completed_On
    if (status == 'Done') {
      item.Completed_On__c = System.now();
    }

    return item;
  }

  /**
   * @description Crée et insère un Work_Item__c avec valeurs par défaut.
   * @param name Le nom de l'élément
   * @return Work_Item__c inséré avec Id
   */
  public static Work_Item__c createAndInsertWorkItem(String name) {
    Work_Item__c item = createWorkItem(name);
    insert item;
    return item;
  }

  /**
   * @description Crée et insère plusieurs Work_Items en masse.
   * @param count Le nombre d'éléments à créer
   * @param namePrefix Le préfixe pour les noms
   * @return List<Work_Item__c> La liste des éléments insérés
   */
  public static List<Work_Item__c> createAndInsertWorkItems(
    Integer count,
    String namePrefix
  ) {
    List<Work_Item__c> items = new List<Work_Item__c>();
    for (Integer i = 0; i < count; i++) {
      items.add(createWorkItem(namePrefix + ' ' + i));
    }
    insert items;
    return items;
  }

  /**
   * @description Crée un Work_Item__c sans valeurs par défaut (pour tester le trigger).
   * @param name Le nom de l'élément
   * @return Work_Item__c sans Status ni Priority
   */
  public static Work_Item__c createWorkItemMinimal(String name) {
    return new Work_Item__c(
      Name = name,
      Description__c = 'Minimal test item',
      Due_Date__c = System.today().addDays(7)
    );
  }

  /**
   * @description Crée un Work_Item__c avec une date d'échéance passée.
   * @param name Le nom de l'élément
   * @return Work_Item__c avec Due_Date dans le passé
   */
  public static Work_Item__c createWorkItemOverdue(String name) {
    return new Work_Item__c(
      Name = name,
      Status__c = 'In_Progress',
      Priority__c = 'High',
      Description__c = 'Overdue test item',
      Due_Date__c = System.today().addDays(-5),
      Category__c = 'Bug_Fix'
    );
  }

  /**
   * @description Crée un Work_Item__c avec External_Id pour tests d'intégration.
   * @param name Le nom de l'élément
   * @param externalId L'identifiant externe
   * @return Work_Item__c avec External_Id
   */
  public static Work_Item__c createWorkItemWithExternalId(
    String name,
    String externalId
  ) {
    return new Work_Item__c(
      Name = name,
      Status__c = 'New',
      Priority__c = 'Medium',
      Description__c = 'Test item with external ID',
      Due_Date__c = System.today().addDays(7),
      External_Id__c = externalId,
      Category__c = 'Integration'
    );
  }

  /**
   * @description Crée un Work_Item__c dans l'état "Done".
   * @param name Le nom de l'élément
   * @return Work_Item__c avec Status Done et Completed_On rempli
   */
  public static Work_Item__c createCompletedWorkItem(String name) {
    return new Work_Item__c(
      Name = name,
      Status__c = 'Done',
      Priority__c = 'Medium',
      Description__c = 'Completed test item',
      Due_Date__c = System.today().addDays(-2),
      Completed_On__c = System.now().addDays(-1),
      Category__c = 'Development'
    );
  }
}
