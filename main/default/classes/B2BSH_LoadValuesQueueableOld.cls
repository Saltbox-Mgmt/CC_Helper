/**
 * Created by dimitrisavelieff on 2019-07-03.
 */

public with sharing class B2BSH_LoadValuesQueueableOld implements Queueable{
    private List<B2BSH_ConfigOld> configsToRun;
    private Map<String, List<SObject>> returnedSObjects;
    private Map<String, SObject> savedSObjects;
    private Map<String, SObject> previousSObjects;
    private static final Set<String> fieldsToIgnore = new Set<String>{'RecordTypeId'};
    private boolean doNotChain;
    public B2BSH_LoadValuesQueueableOld(List<B2BSH_ConfigOld> pconfigsToRun, Map<String, List<SObject>> preturnedSObjects, Map<String, SObject> psavedSObjects, Map<String, SObject> ppreviousSObjects, Boolean doNotChain) {
        this.configsToRun = pconfigsToRun;
        this.returnedSObjects = preturnedSObjects;
        this.savedSObjects = psavedSObjects;
        this.previousSObjects = ppreviousSObjects;
        this.doNotChain = doNotChain;
    }
    public void execute(QueueableContext context) {
       // system.debug('savedSObjects '+this.savedSObjects);
        B2BSH_ConfigOld currConfig = configsToRun.remove(0);
        while(configsToRun.size() > 0 && (!returnedSObjects.containsKey(currConfig.resultName) || returnedSObjects.get(currConfig.resultName).size() <= 0) ) {
            currConfig = configsToRun.remove(0);
        }
        if(currConfig.setting.DeleteBeforeLoading__c) {
            this.deleteExistingValues(currConfig.setting.SObject__c);
        }
        //this.saveValues(currConfig);
        this.upsertValues(currConfig);
        if(!configsToRun.isEmpty() ) {
            if(!test.isRunningTest() && !this.doNotChain) {
                System.enqueueJob(new B2BSH_LoadValuesQueueableOld(configsToRun, returnedSObjects, savedSObjects, previousSObjects, doNotChain));
            } else {
                this.execute(context);
            }
        }
        else{
            B2BSH_Object_HelperOld.saveAdditionalRelatedFields(savedSObjects, previousSObjects);
            Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
            semail.setTargetObjectId(UserInfo.getUserId());
            semail.setSubject('B2BSH Config File Processed');
            semail.setPlainTextBody('File has completed processing');
            semail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
        }

    }
    private void deleteExistingValues(String sObjectName) {
        List<SObject> objs = Database.query('Select Id from '+sObjectName);
        try {
            delete objs;
        } catch(DMLException e) {
            system.debug(e.getMessage());
        }
    }
    /*
    private void saveValues(B2BSH_ConfigOld configSetings) {
        if(!returnedSObjects.containsKey(configSetings.resultName)) return;
        List<SObject> objs = returnedSObjects.get(configSetings.resultName);
        Map<String, SObject> objsToSave = loadValues(objs, configSetings.setting.SObject__c);
        try {
            insert objsToSave.values();
            system.debug('Saved '+configSetings.setting.SObject__c);
            system.debug(objsToSave);
            savedSObjects.putAll(objsToSave);
        } catch(DmlException e) {
            system.debug('Failed to save '+configSetings.setting.SObject__c);
            system.debug(objsToSave.values());
            system.debug(e.getMessage());
        }

    }*/
    private Map<String, SObject> loadValues(List<SObject> objToLoad, String SObjectName ) {
        // system.debug('***'+SObjectName);
        Map<String, SObject> SObjectToSave = new Map<String, SObject>();
        for(SObject obj :objToLoad) {
            SObject oldSObject = obj.clone();
            String oldId = (String)obj.get('Id');
            previousSObjects.put(oldId, oldSObject);
            obj.put('Id', null);
            //TODO investigate flipping source fields (iterate over imported fields rather than existing fields)
            for(Schema.SObjectField fieldRef : Schema.getGlobalDescribe().get(SObjectName).getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
                String fieldName = fieldResult.getname();
                if(fieldResult.isCreateable() ) {
                    if(fieldResult.getType() == Schema.DisplayType.REFERENCE) {
                        //System.debug('Field Name: '+fieldName);
                        String referenceId = (String)obj.get(fieldName);
                        if(savedSObjects.containsKey(referenceId)) {
                            // System.debug('Found Match for '+fieldName+': '+ savedSObjects.get(referenceId).Id);
                            obj.put(fieldName, savedSObjects.get(referenceId).Id);
                        } else {
                            if(!fieldsToIgnore.contains(fieldName)) {
                                obj.put(fieldName, null);
                            }
                        }
                    }
                }
            }
            try {
                //TODO check if user exists first before setting as current user
                obj.put('OwnerId', UserInfo.getUserId());
            } catch(Exception e) {

            }
            SObjectToSave.put(oldId, obj);
        }
       // system.debug('SObjectToSave');
        //system.debug(json.serializePretty(SObjectToSave));
        return SObjectToSave;
    }

    private void upsertValues(B2BSH_ConfigOld configSetings) {
        if(!returnedSObjects.containsKey(configSetings.resultName)) return;
        List<SObject> sobjs = returnedSObjects.get(configSetings.resultName);
        Map<String, SObject> objsToSave = loadValues(sobjs, configSetings.setting.SObject__c);
        set<string> newExtIDSet = new set<string>();
        string myExternalIDField = configSetings.setting.UpsertKey__c;
        Map<String, sObject> sObjInsertList = new Map<String, sObject>();
        Map<String, sObject> sObjUpdateList = new Map<String, sObject>();
        if(String.isNotBlank(myExternalIDField)) {
            String tempStr = '';
            for (String refId : objsToSave.keySet()) {
                SObject sObjItem = objsToSave.get(refId);
                tempStr = string.ValueOf(sObjItem.get(myExternalIDField)); if (string.isBlank(tempStr) == false) {
                    newExtIDSet.add(tempStr);
                }
            }
            list<sObject> sObjExistingList = new list<sObject>();
            string sQuery = 'Select ID, ' + myExternalIDField + ' From '+configSetings.setting.SObject__c+' Where ' + myExternalIDField + ' IN :newExtIDSet';

            sObjExistingList = database.query(sQuery);
            map<string, string> extIDToIDMap = new map<string, string>();
            for (sObject sObjItem : sObjExistingList) {
                extIDToIDMap.put(string.valueOf(sObjItem.get(myExternalIDField)), sObjItem.ID);
            }
            for (String refId : objsToSave.keySet()) {
                SObject sObjItem = objsToSave.get(refId);
                if (extIDToIDMap.containsKey(string.ValueOf(sObjItem.get(myExternalIDField)))) {
                    sObjItem.ID = extIDToIDMap.get(string.ValueOf(sObjItem.get(myExternalIDField)));
                    sObjUpdateList.put(refId, sObjItem);
                } else {
                    sObjInsertList.put(refId, sObjItem);
                }
            }
        } else {
            sObjInsertList.putAll(objsToSave);
        } if (sObjUpdateList.size() > 0) {
            update sObjUpdateList.values();
           // system.debug('sObjUpdateList '+sObjUpdateList);
            savedSObjects.putAll(sObjUpdateList);
        }
         if (sObjInsertList.size() > 0) {
             insert sObjInsertList.values();
            // system.debug('sObjInsertList '+sObjInsertList);
             savedSObjects.putAll(sObjInsertList);
        }
    }

}