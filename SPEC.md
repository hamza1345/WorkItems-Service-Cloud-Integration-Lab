spec.md

— Installer @salesforce/sfdx-lwc-jest
Configurer scripts npm.
 Ajouter flushPromises

 day 1

  tâches complétées :

@salesforce/sfdx-lwc-jest — v7.1.2 installée ✓
Scripts npm —  configurés (test, test:unit, test:unit:watch, test:unit:debug, test:unit:coverage) ✓

flushPromises — créée dans testUtils.js avec :
flushPromises() — flush toutes les promesses en attente
waitForDomUpdates() — attend les mises à jour LWC
createMockData() — helper pour créer des données de test

exemple utilisation 

import { flushPromises } from 'c/testUtils';

it('should update after async call', async () => {
    const element = createElement('c-my-component', { is: MyComponent });
    document.body.appendChild(element);
    
    await flushPromises();
    expect(element.textContent).toContain('Expected value');
});

npm run test:lwc ==>fonctionne