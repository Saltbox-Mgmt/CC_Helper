/**
 * Created by dimitrisavelieff on 2020-04-09.
 */

public with sharing class B2BSHQueryUtilHelper {

    @AuraEnabled(cacheable=true)
    public static List<SObject> getFilteredSObjects(String queryParametersString) {
        Map<String, Object> queryParameters = (Map<String, Object>)JSON.deserializeUntyped(queryParametersString);
        string query = buildQuery(queryParameters);
        system.debug(query);
        return Database.query(query);

    }

    private static String buildQuery(Map<String, Object> queryParameters){
        String query = buildSelectedFields((String)queryParameters.get('fieldsToQuery'),(String)queryParameters.get('sobject'));
        query += buildQueryFilters((List<Object>)queryParameters.get('filters'),(Map<String, Object> )queryParameters.get('queryParameters'),(String)queryParameters.get('sobject'));
        return query;
    }

    private static String buildSelectedFields(String fields, String SObjectApiName){
        return 'Select '+fields+' FROM '+SObjectApiName;
    }

    private static String buildQueryFilters(List<Object> queryFilters, Map<String, Object> filterOptions, String sobjectName){
        String retFilterString = '';
        String operator = (String)filterOptions.get('operator');
        Map<String, String> queryFilterMap = buildQueryFilterMap(queryFilters, sobjectName);
        if(operator != 'CUSTOM'){
            for(String filter :queryFilterMap.values()){
                if(String.isNotBlank(retFilterString)){
                    retFilterString += ' '+operator+' ';
                } else {
                    retFilterString += ' WHERE ';
                }
                retFilterString+=filter;
            }
        }
        system.debug('FILTER: '+retFilterString);
        return retFilterString;
    }

    private static Map<String, String> buildQueryFilterMap(List<Object> queryFilters, String sobjectName) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

        Map<String, String> retMap = new Map<String, String>();
        for(Object qfo:queryFilters){
            Map<String, Object> qf = (Map<String, Object>)qfo;
            String field = (String)qf.get('fieldName');
            String operator = (String)qf.get('operator');
            String value = (String)qf.get('filter');
            String rowId = String.valueOf((Integer)qf.get('rowId'));
            if(String.isNotBlank(field) && String.isNotBlank(operator) && String.isNotBlank(value) && String.isNotBlank(rowId)){
                if(wrapWithQuotes(getFieldType(fieldMap,field))){
                    if(operator == 'SW'){
                        retMap.put(rowId,'('+field+' LIKE \''+value+'%\')');
                    } else if(operator == 'EW'){
                        retMap.put(rowId,'('+field+' LIKE \'%'+value+'\')');
                    } else if(operator == 'CNT'){
                        retMap.put(rowId,'('+field+' LIKE \'%'+value+'%\')');
                    } else {
                        retMap.put(rowId,'('+field+' '+operator+' \''+value+'\')');
                    }
                } else {
                    retMap.put(rowId,'('+field+' '+operator+' '+value+')');
                }

            }
        }
        return retMap;
    }

    private static Schema.DisplayType getFieldType(Map<String, Schema.SObjectField> fieldMap, String fieldName){
        if(fieldMap.containsKey(fieldName)){
            Schema.SObjectField field = fieldMap.get(fieldName);
            return field.getDescribe().getType();
        } else return Schema.DisplayType.String;
    }

    private static Boolean wrapWithQuotes(Schema.DisplayType displayType){
        switch on displayType{
            when Currency,Date,DateTime, Double,Integer,Long,Percent {
                return false;
            } when else {
                return true;
            }
        }
    }
}