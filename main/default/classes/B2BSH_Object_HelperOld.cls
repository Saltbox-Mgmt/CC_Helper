/**
 * Created by dimitrisavelieff on 2019-06-18.
 */

public with sharing class B2BSH_Object_HelperOld {
    //general vars
    private static List<B2BSH_ConfigOld> configsToRun = new List<B2BSH_ConfigOld>();
    private static Map<Id, B2BHelperConfigOld__mdt> configSettings ;
    private static String storeFrontName = 'Shop360';
    private static Map<String, List<SObject>> returnedSObjects = new Map<String, List<SObject>>();
    //extract vars
    private static List<SObject> var0, var1, var2, var3, var4, var5;
    private static List<Id> accountFilterIds, productFilterIds;
    private static final Integer cntVars = 6;
    private static Integer limNum = 100;
    private static final Set<String> varsToIgnore = new Set<String>{
            'limNum', 'storeFrontName', 'accountFilterIds', 'productFilterIds'
    };


    //load vas
    private static Map<String, SObject> savedSObjects = new Map<String, SObject>();
    private static Map<String, SObject> previousSObjects = new Map<String, SObject>();
    private static final Set<String> fieldsToIgnore = new Set<String>{
            'RecordTypeId'
    };

    private static final String b2bshmdtQuery = 'Select Id, MasterLabel, DeveloperName, allowOverridingQuery__c, Data_Group__c, defaultWhereClause__c, resultName__c, SObject__c, DeleteBeforeLoading__c, UpsertKey__c, (Select Id,DependentConfig__c, ChildConfig__c, Subquery__c, RelationshipName__c from DependentConfigs__r), (Select Id,DependentConfig__c, ChildConfig__c from ChildConfigs__r) from B2BHelperConfigOld__mdt';

    @AuraEnabled(cacheable=true)
    public static boolean uploadConfigFile(String file, Boolean doNotChain) {
        // system.debug(file);
        Blob decodedFile = EncodingUtil.base64Decode(file);
        String txt = decodedFile.toString();
        returnedSObjects = (Map<String, List<SObject>>) Json.deserialize(txt, Map<String, List<SObject>>.class);
        queryConfigs();
        selectConfigs();
        System.enqueueJob(new B2BSH_LoadValuesQueueableOld(configsToRun, returnedSObjects, savedSObjects, previousSObjects, doNotChain));
        return true;
    }
    @AuraEnabled(cacheable=true)
    public static List<String> extractObjectsIds(List<String> selectedConfigs, String filteredObjects) {
        system.debug('*****filteredObjects****');
        system.debug(filteredObjects);
        List<Id> configsToQuery = new List<Id>();
        Map<String, Object> mapfilteredObjects = (Map<String, Object>)JSON.deserializeUntyped(filteredObjects);
        for(String dataGroupKey :mapfilteredObjects.keySet()) {
            Map<String, Object> dataGroupMap = (Map<String, Object>)mapfilteredObjects.get(dataGroupKey);
            if(dataGroupMap.containsKey('sobjects')) {
                for (Object val : (List<Object>)dataGroupMap.get('sobjects'))
                    configsToQuery.add((Id)val);
            }

        }
        system.debug(configsToQuery);
        queryConfigs(configsToQuery );
        selectConfigs();
        //generateQueries();
        List<String> configIds = new List<String>();
        system.debug(configsToRun);
        for(B2BSH_ConfigOld c :configsToRun) {
            configIds.add(c.configId);
        }
        system.debug(configIds);
        //runQueries();
      //  String output = Json.serializePretty(returnedSObjects, true);
       // system.debug(output);
        return configIds;


    }

    @AuraEnabled(cacheable=true)
    public static String runQuery(String configId,  String returnedObjects, String filteredObjects) {
        setFilteredLists(filteredObjects);
        returnedSObjects = (Map<String, List<SObject>>) Json.deserialize(returnedObjects, Map<String, List<SObject>>.class);
        B2BSH_ConfigOld currConfig = new B2BSH_ConfigOld(queryConfig(configId));
        currConfig.query = generateQuery(currConfig.setting);
        executeObjQuery(currConfig.query, currConfig.resultName);
        return Json.serializePretty(returnedSObjects, true);
    }

    @AuraEnabled
    public static List<SObject> getFilteredData(Object configSetting) {
        String currSetting = (String)configSetting;
        system.debug(currSetting);
        if(currSetting == 'Account') {
            return [Select Id, Name from ccrz__E_AccountGroup__c limit 2000];
        } else if(currSetting == 'Product') {
            return [Select Id, Name from ccrz__E_Product__C limit 2000];
        }else {
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAllConfigs() {
        Map<String, List<Object>> configMap = new Map<String, List<Object>>();
        queryConfigs();
        for(B2BHelperConfigOld__mdt config :configSettings.values()) {
            if(configMap.containsKey(config.Data_Group__c)) {
                configMap.get(config.Data_Group__c).add(new Map<String, String>{'label'=>config.SObject__c, 'value'=>config.Id});
            } else {
                configMap.put(config.Data_Group__c, new List<Object>{new Map<String, String>{'label'=>config.SObject__c, 'value'=>config.Id}});
            }
        }

        List<Map<String, Object>> retConfigs = new List<Map<String, Object>>();
        for(String key :configMap.keySet()) {
            retConfigs.add(
              new Map<String, Object>{'dataGroup'=>key, 'data'=>configMap.get(key)}
            );
        }
        return retConfigs;
    }

    private static void setFilteredLists(String filteredObjects) {
        Map<String, Object> mapfilteredObjects = (Map<String, Object>)JSON.deserializeUntyped(filteredObjects);
        for(String dataGroupKey :mapfilteredObjects.keySet()) {
            Map<String, Object> dataGroupMap = (Map<String, Object>)mapfilteredObjects.get(dataGroupKey);
            List<Id> recordIds = new List<Id>();
            system.debug('dataGroupMap');
            system.debug(dataGroupMap);
            if(dataGroupMap.containsKey('filteredRecords')) {
                for (Object val : (List<Object>)dataGroupMap.get('filteredRecords')) {
                    system.debug(val);
                    Map<String, Object> record = (Map<String, Object>)val;
                    if(record.containsKey('Id'))
                        recordIds.add((Id)record.get('Id'));
                }
            }
            system.debug(recordIds);

            if(dataGroupKey == 'Account') {
                accountFilterIds = recordIds;
            } else if(dataGroupKey == 'Product') {
                productFilterIds = recordIds;
            }
            system.debug(accountFilterIds);
            system.debug(productFilterIds);
         }
    }

    private static void queryConfigs() {
        queryConfigs(new List<String>{
                'Configuration', 'Storefront', 'Account', 'Product'
        });

    }
    private static void queryConfigs(List<String> dataConfigs) {
        configSettings = new Map<Id, B2BHelperConfigOld__mdt>(
                (List<B2BHelperConfigOld__mdt>) Database.query(b2bshmdtQuery+' WHERE Data_Group__c in :dataConfigs')
        );

    }
    private static void queryConfigs(List<Id> dataConfigs) {
        system.debug('~~~');
        system.debug(dataConfigs);
        configSettings = new Map<Id, B2BHelperConfigOld__mdt>(
                (List<B2BHelperConfigOld__mdt>) Database.query(b2bshmdtQuery+' WHERE Id in :dataConfigs')
        );

    }
    private static B2BHelperConfigOld__mdt queryConfig(Id configId) {
        return Database.query(b2bshmdtQuery+' WHERE Id = :configId');//[Select Id, MasterLabel, DeveloperName, allowOverridingQuery__c, Data_Group__c, defaultWhereClause__c, resultName__c, SObject__c, (Select Id,DependentConfig__c, ChildConfig__c, Subquery__c, RelationshipName__c from DependentConfigs__r), (Select Id,DependentConfig__c, ChildConfig__c from ChildConfigs__r) from B2BHelperConfigOld__mdt where Id = :configId];
    }

    private static void executeObjQuery(String query, String resultName) {
        List<SObject> queryRet = new List<SObject>();
        try {
        String q = assignMergeVariables(query);
        // system.debug(q);
        queryRet = Database.query(q);
        // system.debug(queryRet);
            } catch (QueryException e) {
            system.debug(query);
            system.debug(e.getMessage());
        }
        returnedSObjects.put(resultName, queryRet);
    }

    private static List<B2BSH_ConfigOld> selectConfigs(List<B2BHelperConfigOld__mdt> configs) {
        List<B2BSH_ConfigOld> retConfigsToRun = new List<B2BSH_ConfigOld>();
        for (B2BHelperConfigOld__mdt c : configs) {
            retConfigsToRun.add(new B2BSH_ConfigOld(c));
        }
        retConfigsToRun = sortB2BSHList(retConfigsToRun);
        return retConfigsToRun;
    }
    private static void selectConfigs() {
        configsToRun = selectConfigs(configSettings.values());
    }

    private static void generateQueries() {
        for (B2BSH_ConfigOld config : configsToRun) {
            config.query = generateQuery(config.setting);
        }
    }

    private static String generateQuery(B2BHelperConfigOld__mdt configSetting) {
        String objQuery = 'Select ';
        objQuery += getFieldsAsString(getFields(configSetting.SObject__c));
        objQuery += getSubQueries(configSetting);
        objQuery += ' FROM ' + configSetting.SObject__c;
        objQuery += (String.isNotBlank(configSetting.defaultWhereClause__c)) ? ' ' + configSetting.defaultWhereClause__c : '';
        system.debug('OLD QUERY!');
        system.debug(objQuery);
        if((configSetting.SObject__c == 'ccrz__E_AccountGroup__c' && accountFilterIds != null)|| (configSetting.SObject__c == 'ccrz__E_Product__c' && productFilterIds != null)) {
            String copiedEnd = '';
            if(objQuery.containsIgnoreCase(' LIMIT')) {
                copiedEnd = objQuery.substring(objQuery.indexOfIgnoreCase(' LIMIT'), objQuery.length());
                objQuery = objQuery.removeEndIgnoreCase(copiedEnd);
            }
            objQuery += (objQuery.containsIgnoreCase('WHERE '))?' AND ':' WHERE ';
            objQuery += ' ID in :';
            objQuery += (configSetting.SObject__c == 'ccrz__E_AccountGroup__c')?'accountFilterIds':'productFilterIds';
            objQuery += copiedEnd;
        }
        system.debug('QUERY!');
        system.debug(objQuery);
        return objQuery;
    }

    private static String assignMergeVariables(String queryString) {
        String mergeRegex = '(:[^\\s()]+)';
        for (String ignVar : varsToIgnore) {
            mergeRegex = '(?!:' + ignVar + ')' + mergeRegex;
        }
        Matcher varMatcher = Pattern.compile(mergeRegex).matcher(queryString);
        Integer cnt = 0;
        while (varMatcher.find() && cnt < cntVars) {
            String grp = varMatcher.group().removeStart(':');

            List<SObject> varToSet = new List<SObject>();
            if (returnedSObjects.containsKey(grp)) varToSet = returnedSObjects.get(grp);
            setVarValue(cnt, varToSet);
            //queryString = queryString.replaceAll(':'+grp,':'+);
            queryString = queryString.replaceAll(':' + grp, ':var' + cnt);
            cnt++;
        }
        return queryString;
    }

    private static void setVarValue(Integer cnt, List<SObject> varToSet) {
        switch on cnt {
            when 0 {
                var0 = varToSet;
            } when 1 {
                var1 = varToSet;
            } when 2 {
                var2 = varToSet;
            } when 3 {
                var3 = varToSet;
            } when 4 {
                var4 = varToSet;
            } when 5 {
                var5 = varToSet;
            }
        }
    }

    private static String getSubQueries(B2BHelperConfigOld__mdt configSetting) {
        String subQueries = '';
        for (B2BHelperDependencyOld__mdt dependency : configSetting.DependentConfigs__r) {
            if (dependency.Subquery__c && configSettings.containsKey(dependency.ChildConfig__c)) {
                B2BHelperConfigOld__mdt childConfig = configSettings.get(dependency.ChildConfig__c);
                subQueries += ', (Select ' + getFieldsAsString(getFields(childConfig.SObject__c)) + ' FROM ' + dependency.RelationshipName__c + ')';
            }
        }
        return subQueries;
    }

    private static Set<String> getFields(String sobjectString) {
        Set<String> sobjectFields = new Set<String>();
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sobjectString).getDescribe().fields.getMap();
        for (Schema.SObjectField fieldRef : fields.values()) {
            Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
            if(fieldResult.isCreateable()) {
                sobjectFields.add(fieldResult.getname());
            }
        }
        //TODO verify if still needed
        if (sobjectFields.contains('RecordTypeId')) {
            sobjectFields.add('RecordType.DeveloperName');
            system.debug('add recordtype');
        }
        return sobjectFields;
    }

    private static String getFieldsAsString(Set<String> sobjectFields) {
        String retString = '';
        Iterator<String> sobjectFieldsIter = sobjectFields.iterator();
        while (sobjectFieldsIter.hasNext()) {
            retString += sobjectFieldsIter.next();
            if (sobjectFieldsIter.hasNext()) retString += ', ';
        }

        return retString;
    }

    private static List<B2BSH_ConfigOld> sortB2BSHList(List<B2BSH_ConfigOld> b2bshToSort) {
        List<B2BSH_ConfigOld> b2bshSorted = new list<B2BSH_ConfigOld>();
        for (Integer i = 0; i < b2bshToSort.size(); i++) {
            Boolean addedConfig = false;
            for (Integer j = 0; j < b2bshSorted.size(); j++) {
                Integer res = b2bshToSort[i].compareTo(b2bshSorted[j]);
                if (res == -1) {
                    b2bshSorted.add(j, b2bshToSort[i]);
                    addedConfig = true;
                    break;
                }
            }
            if (!addedConfig) b2bshSorted.add(b2bshToSort[i]);
        }
        return b2bshSorted;
    }
//    private static void saveValues(B2BSH_ConfigOld configSetings) {
//        if(!returnedSObjects.containsKey(configSetings.resultName)) return;
//        List<SObject> objs = returnedSObjects.get(configSetings.resultName);
//        Map<String, SObject> objsToSave = loadValues(objs, configSetings.setting.SObject__c);
//        try {
//            insert objsToSave.values();
//            system.debug('Saved '+configSetings.setting.SObject__c);
//            savedSObjects.putAll(objsToSave);
//        } catch(DmlException e) {
//            system.debug('Failed to save '+configSetings.setting.SObject__c);
//            system.debug(objsToSave.values());
//            system.debug(e.getMessage());
//        }
//
//    }
//    private static Map<String, SObject> loadValues(List<SObject> objToLoad, String SObjectName ) {
//       // system.debug('***'+SObjectName);
//        Map<String, SObject> SObjectToSave = new Map<String, SObject>();
//        for(SObject obj :objToLoad) {
//            SObject oldSObject = obj;
//            String oldId = (String)obj.get('Id');
//            obj.put('Id', null);
//
//            previousSObjects.put(oldId, oldSObject);
//            for(Schema.SObjectField fieldRef : Schema.getGlobalDescribe().get(SObjectName).getDescribe().fields.getMap().values()) {
//                Schema.DescribeFieldResult fieldResult = fieldRef.getDescribe();
//                String fieldName = fieldResult.getname();
//                if(fieldResult.isCreateable() ) {
//                    if(fieldResult.getType() == Schema.DisplayType.REFERENCE) {
//                        //System.debug('Field Name: '+fieldName);
//                        String referenceId = (String)obj.get(fieldName);
//                        if(savedSObjects.containsKey(referenceId)) {
//                           // System.debug('Found Match for '+fieldName+': '+ savedSObjects.get(referenceId).Id);
//                            obj.put(fieldName, savedSObjects.get(referenceId).Id);
//                        } else {
//                            if(!fieldsToIgnore.contains(fieldName)) {
//                                obj.put(fieldName, null);
//                            }
//                        }
//                    }
//                } else {
//                    //obj.put(fieldName, null);
//                }
//            }
//            try {
//                obj.put('OwnerId', UserInfo.getUserId());
//            } catch(Exception e) {
//
//            }
//            SObjectToSave.put(oldId, obj);
//        }
//        return SObjectToSave;
//    }

    public static void saveAdditionalRelatedFields(Map<String, SObject> psavedSObjects, Map<String, SObject> ppreviousSObjects) {
        system.debug('ADDITIONAL FIELDS');
        system.debug(json.serializePretty(psavedSObjects));
        system.debug(json.serializePretty(ppreviousSObjects));
        Map<String, SObject> sobjectsToSave = new Map<String, SObject>();
        for (String previousId : ppreviousSObjects.keySet()) {
            SObject pobj = ppreviousSObjects.get(previousId);
            Map<String, Object> oldMap = pobj.getPopulatedFieldsAsMap();
            for (String fieldName : oldMap.keySet()) {
                Object oldVal = oldMap.get(fieldName);
                if (oldVal instanceof Id) {
                    String oldValId = (Id)oldVal;
                    if (psavedSObjects.containsKey(previousId)) {
                        SObject savedObj = psavedSObjects.get(previousId);
                        if (savedObj.get(fieldName) == null && psavedSObjects.containsKey(oldValId)) {
                            System.debug('--------');
                            System.debug(psavedSObjects.get(previousId).Id);
                            System.debug(fieldName);
                            System.debug(savedObj.Id);
                            System.debug('--------');
                            savedObj.put(fieldName, psavedSObjects.get(oldValId).Id);
                            sobjectsToSave.put(previousId, savedObj);
                        }
                    }
                }
            }

        }
        system.debug(sobjectsToSave.values());
        update sobjectsToSave.values();
    }


}