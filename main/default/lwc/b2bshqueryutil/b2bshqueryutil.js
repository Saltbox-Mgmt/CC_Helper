/**
 * Created by dimitrisavelieff on 2020-04-09.
 */

import {LightningElement,api,track,wire} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/b2bshQueryUtilStyle'
import getRecordsForFilter from '@salesforce/apex/B2BSHQueryUtilHelper.getFilteredSObjects';

export default class B2Bshqueryutil extends LightningElement {
    @api sobject;
    @api displayParameters =
        {
            fieldsToDisplay: 'Name,Phone'
        };
    //@api callback;

    @api fieldstodisplay;
    @track recordResults = [];
    @track resultColumns = [];
    @track openResults = false;
    @track noResults = false;
    @track hasResults = false;
    @track querying = false;
    @track resultsButtonLabel = 'No Results';
    sobjectDetails;
    componentTitle = '';
    fieldCISMap = [];
    fieldsToQuery = [];
    recordIds = [];

    @track filterMode = {
        operator:'AND',
        customOperator:'',
        isCustomOperator:false
    }

    @track queryFilters = [
        {
            canRemove:false,
            canAdd: true,
            validateRemove:false,
            fieldName:'',
            stringQuery:false,
            operator:'=',
            filter:'',
            error:'',
            rowId:1
        }
    ];
    @track fieldOptions = [];
    operatorOptionsString = [
        { label:'Equals', value:'=' },
        { label:'Not equals', value:'!=' },
        { label:'Starts With', value:'SW' },
        { label:'Ends With', value:'EW' },
        { label:'Contains With', value:'CNT' },
    ];
    operatorOptionsInt = [
        { label:'Equals', value:'=' },
        { label:'Not equals', value:'!=' },
        { label:'Less than', value:'<' },
        { label:'Less or Equal', value:'<=' },
        { label:'Greater than', value:'>' },
        { label:'Greater or Equal', value:'>=' },
    ];

    queryModeOperators = [
        { label: 'All criteria are met (AND)', value:'AND'},
        { label: 'Any criteria is met (OR)', value:'OR'},
        //{ label: 'Custom Filter Logic', value:'CUSTOM'}
    ];

    @wire(getObjectInfo, { objectApiName: '$sobject' })
    getObjectInfo({ data, error }) {
        if (data) {
            this.sobjectDetails = data;
            this.componentTitle = 'Filter '+this.sobjectDetails.labelPlural;
            this.makeFieldListCaseInsensitive();
            this.setFilterableFields();
            this.setFieldMap();
            debugger;
            //debugger;
            //this.objectFields = data.fields;
           // this.fieldsFormatted = (this.fields || ['Id', 'Name'].join()).split(',').map(field => this.objectApiName + '.' + field);
        }
    }
    makeFieldListCaseInsensitive(){
        for(let index in this.sobjectDetails.fields){
            let field = this.sobjectDetails.fields[index];
            this.fieldCISMap[index.toLowerCase()] = index;
        }
    }
    setFieldMap() {
        this.fieldstodisplay = this.fieldstodisplay.replace(/\s/g,'').toLowerCase();
        let fieldsToDisplay = this.fieldstodisplay.split(',');
        //debugger;
        for(let index in fieldsToDisplay){
            this.fieldsToQuery[fieldsToDisplay[index].toLowerCase()] = this.sobjectDetails.fields[this.fieldCISMap[fieldsToDisplay[index].toLowerCase()]];
        }

    }
    setFilterableFields(){
        if(this.sobjectDetails.fields){
            for(let fieldKey in this.sobjectDetails.fields){
                let field = this.sobjectDetails.fields[fieldKey];
                if(field.filterable){
                    const option = {
                        label: field.label+' ('+field.apiName+')',
                        value: field.apiName
                    };
                    this.fieldOptions = [...this.fieldOptions,option];
                }
            }
        }
    }

    addQueryFilterRow(){
        this.queryFilters[this.queryFilters.length-1].canAdd = false;

        let newQueryFilterRow =  {
            canRemove:true,
            canAdd:this.canAddRow(),
            validateRemove:false,
            fieldName:'',
            stringQuery:false,
            operator:'',
            filter:'',
            error:'',
            rowId:this.queryFilters[this.queryFilters.length-1].rowId+1
        }
        this.queryFilters = [...this.queryFilters,newQueryFilterRow];
    }

    requestRemoveFilterRow(event){
        this.queryFilters[event.target.dataset.item].validateRemove = true;
        this.queryFilters[event.target.dataset.item].canRemove = false;
    }
    cancelRemoveFilterRow(event){
        this.queryFilters[event.target.dataset.item].validateRemove = false;
        this.queryFilters[event.target.dataset.item].canRemove = true;
    }
    removeQueryFilterRow(event) {
        this.queryFilters.splice(event.target.dataset.item,1);
        this.queryFilters[this.queryFilters.length-1].canAdd = true;
    }s

    setQueryRowField(event){
        this.queryFilters[event.target.dataset.item].fieldName = event.target.value;
        this.queryFilters[event.target.dataset.item].stringQuery = (this.getDataRowType(this.sobjectDetails.fields[this.fieldCISMap[event.target.value.toLowerCase()]].dataType) == 'string')?true:false;
    }

    setQueryRowOperator(event){
        this.queryFilters[event.target.dataset.item].operator = event.target.value;
    }

    setQueryRowValue(event){
        this.queryFilters[event.target.dataset.item].filter = event.target.value;
    }

    executeFilter(event){
        this.hasResults = false;
        this.noResults = false;
        this.querying = true;
        let filterParameters = {};
        filterParameters.fieldsToQuery = (!this.fieldsToQuery['id'])? 'Id,':'';
        filterParameters.fieldsToQuery += this.fieldstodisplay;
        filterParameters.sobject = this.sobjectDetails.apiName;
        filterParameters.filters = this.queryFilters;
        filterParameters.queryParameters = this.filterMode;
        console.log(JSON.stringify(filterParameters));
        this.setFiltersInSession();
        getRecordsForFilter({queryParametersString : JSON.stringify(filterParameters)})
            .then(result => {
                this.querying = false;
                if(result.length > 0){
                    this.recordResults = result;
                    //this.setDataTableResults(result);
                    this.sendRecordIdsToParent(result);
                    this.resultsButtonLabel = 'View '+result.length+' Result'+((result.length >1)?'s':'');
                    debugger;
                    this.hasResults = true;

                 } else {
                    this.noResults = true;
                }
            //this.filteredObjs = result;
        })
        .catch(error =>{
            this.querying = false;
                console.log(error);
        })
        //debugger;
    }

    setFiltersInSession(){
        sessionStorage.setItem('filterSettings-'+this.sobject,JSON.stringify(this.queryFilters));
    }

    /*parseResults(data){
        this.recordResults = [];
        for(let index in data){
            let record = data[index];
            let recordObj = {fields:[]};
            for(let fieldName in record){
                if(fieldName.toLowerCase() == "id"){
                    recordObj.recordId = record[fieldName];
                    if(this.fieldsToQuery['id']) {
                        recordObj.fields.push(record[fieldName]);
                    }
                } else{
                    recordObj.fields.push(record[fieldName]);
                }
            }

            this.recordResults.push(recordObj);
        }
    }

   setDataTableResults(data) {
        this.setDataTableColumns();
        this.setDataTableValues(data);
    }
    setDataTableColumns() {
        this.resultColumns = [];
        for(let key in this.fieldsToQuery){
            let fieldName = this.fieldCISMap[key];
            let field = this.sobjectDetails.fields[fieldName];
            let column = {
                label: field.label,
                fieldName: key,
                type: this.getDataRowType(field.dataType)
            };
            this.resultColumns = [...this.resultColumns,column];
        }

    }
    setDataTableValues(data){
        this.recordResults = [];
        for(let index in data){
            let record = data[index];
            let result = {};
            for(let fieldName in record){
                result[fieldName.toLowerCase()] = record[fieldName];
            }

            this.recordResults = [...this.recordResults,result];
        }

    }*/

    sendRecordIdsToParent(data){
        const selectedEvent = new CustomEvent("filtereddata", {
            detail: {records:data
                //, callback:this.callback
            }
        });
        this.dispatchEvent(selectedEvent);
    }


    canAddRow(){
        return this.queryFilters.length < 5;
    }

    getDataRowType(dataType) {
        switch(dataType.toLowerCase()) {
            case "string":
            case "picklist":
            case "address":
            case "textarea":
            case "reference":
                return "string"
            case "currency":
                return "currency"
            case "phone":
                return "phone"
            case "double":
            case "int":
                return "number";
            case "datetime":
            case "date":
                return "date";
            case "boolean":
                return "boolean";
            case "url":
                return "url";
            case "email":
                return "email";
            default:
                return "string"
        }
    }

    openResultModal() {
        this.openResults = true
    }
    closeResultsModal() {
        this.openResults = false
    }
    downloadResults() {
        this.downloadCSVFile(this.recordResults);
    }

    downloadCSVFile(data) {
        let rowEnd = '\n';
        let csvString = '';
        // this set elminates the duplicates if have any duplicate keys
        let rowData = new Set();

        // getting keys from data
        data.forEach(function (record) {
            Object.keys(record).forEach(function (key) {
                rowData.add(key);
            });
        });

        // Array.from() method returns an Array object from any object with a length property or an iterable object.
        rowData = Array.from(rowData);

        // splitting using ','
        csvString += rowData.join(',');
        csvString += rowEnd;

        // main for loop to get the data based on key value
        for(let i=0; i < data.length; i++){
            let colValue = 0;

            // validating keys in data
            for(let key in rowData) {
                if(rowData.hasOwnProperty(key)) {
                    // Key value
                    // Ex: Id, Name
                    let rowKey = rowData[key];
                    // add , after every value except the first.
                    if(colValue > 0){
                        csvString += ',';
                    }
                    // If the column is undefined, it as blank in the CSV file.
                    let value = data[i][rowKey] === undefined ? '' :data[i][rowKey];
                    csvString += '"'+ value +'"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }

        // Creating anchor element to download
        let downloadElement = document.createElement('a');

        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        // CSV File Name
        downloadElement.download = this.sobject+' Extract.csv';
        // below statement is required if you are using firefox browser
        document.body.appendChild(downloadElement);
        // click() Javascript function to download CSV file
        downloadElement.click();
    }
    connectedCallback() {
        Promise.all([loadStyle(this, styles)]);
        let data = sessionStorage.getItem('filterSettings-'+this.sobject);
        if(data){
            this.queryFilters = JSON.parse(data);
        }
        //this.componentTitle = 'Account';
    }
}