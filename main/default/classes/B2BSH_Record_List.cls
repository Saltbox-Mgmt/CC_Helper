/**
 * Created by dimitrisavelieff on 2019-09-12.
 */

public with sharing class B2BSH_Record_List {
    @AuraEnabled(cacheable = true)
    public static List<SObject> getRecordsList(Integer pagenumber, Integer numberOfRecords, Integer pageSize, String searchString, String sobj, String additionalFilters) {
        String searchKey = '%' + searchString + '%';
        String query = 'select id, Name from '+ sobj;
        if (searchString != null && searchString != '') {
            query += ' where name like \'%' + searchString + '%\' ';
        }
        query += ' limit ' + pageSize + ' offset ' + (pageSize * (pagenumber - 1));
        return Database.query(query);
    }
    @AuraEnabled(cacheable = true)
    public static Integer getRecordsCount(String searchString,String sobj) {
        String query = 'select count() from '+sobj;
        if (searchString != null && searchString != '') {
            query += ' where name like \'%' + searchString + '%\' ';
        }
        return Database.countQuery(query);
    }
}