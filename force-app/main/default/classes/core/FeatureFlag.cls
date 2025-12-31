/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Utilitaire pour vérifier les Custom Permissions.
 * Permet le bypass des automations via Custom Permissions.
 */
public without sharing class FeatureFlag {
  /**
   * @description Vérifie si l'utilisateur courant a une Custom Permission.
   * @param permissionName Le nom de la Custom Permission (API Name)
   * @return true si l'utilisateur a la permission
   */
  public static Boolean hasPermission(String permissionName) {
    try {
      return FeatureManagement.checkPermission(permissionName);
    } catch (Exception e) {
      // Si erreur (permission n'existe pas), retourner false
      return false;
    }
  }
}
