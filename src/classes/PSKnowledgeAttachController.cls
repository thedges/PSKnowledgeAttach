public class PSKnowledgeAttachController {
    @AuraEnabled
    public static String queryRecord(String params)
    {
        System.debug('queryRecord invoked...');
        Map<String, String> paramMap = (Map<String, String>)JSON.deserialize(params,   Map<String, String>.class);
        System.debug(JSON.serializePretty(paramMap));

        try
        {
            Map<String, String> dataResp = new Map<String, String>();
            String recordId;
            String searchField;
            String extraFields;
            String objectName;

            if (paramMap.containsKey('recId')) recordId = paramMap.get('recId');
            if (paramMap.containsKey('searchField')) searchField = paramMap.get('searchField');
            if (paramMap.containsKey('extraFields')) extraFields = paramMap.get('extraFields');

            if (recordId != null)
            {
                objectName = ID.valueOf(recordId).getSObjectType().getDescribe().getName();
                dataResp.put('objectName', objectName);

                // handle if auto-search is enabled
                if (searchField != null)
                {
                    String soql = 'SELECT ' + searchField + ' FROM ' + objectName + ' WHERE Id = \'' + recordId + '\'';
                    System.debug('soql=' + soql);
                    SObject obj = Database.query(soql);
                    dataResp.put('searchField', (String)obj.get(searchField));
                }

                // handle if extra fields are specified
                if (extraFields != null)
                {
                    List<PSField> fieldList = new List<PSField>();

                    Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Knowledge__kav');
                    Schema.DescribeSObjectResult sobjResult = targetType.getDescribe();
                    Map<String, Schema.SObjectField> fieldMap = sobjResult.fields.getMap();

                    // set list of fields to describe
                    List<String> keySet = parseCSVString(extraFields);
                    System.debug('keySet=' + keySet);

                    List<Map<String, Object>> retFieldList = new  List<Map<String, Object>>();

                    for (String key : keySet)
                    {
                        Schema.DescribeFieldResult descField = fieldMap.get(key).getDescribe();
                        System.debug('descField=' + JSON.serializePretty(descField));

                        Map<String, Object> tmpFieldDef = new Map<String, Object>();
                        tmpFieldDef.put('label', descField.getLabel());
                        tmpFieldDef.put('type', descField.getType().name().toLowerCase());
                        tmpFieldDef.put('name', descField.getName());
                        retFieldList.add(tmpFieldDef);
                    }

                    dataResp.put('extraFields', JSON.serialize(retFieldList));
                }
            }

            return  JSON.serialize(dataResp);
        }
        catch (exception e)
        {
            throw new  AuraHandledException(e.getTypeName() + ' - ' + e.getMessage() + ' [Line: ' + e.getLineNumber() + ']');
        }
    }

    @AuraEnabled
    public static String queryData(String params)
    {
        System.debug('queryData invoked...');
        Map<String, String> paramMap = (Map<String, String>)JSON.deserialize(params,   Map<String, String>.class);
        System.debug(JSON.serializePretty(paramMap));
        Map<String, String> fileIdMap = new Map<String, String>();
        List<Map<String, Object>> dataResp = new List<Map<String, Object>>();

        try
        {
            if (paramMap.containsKey('query'))
            {
                String language = 'en_US';
                String objectType = 'KnowledgeArticleVersion';
                String searchText = paramMap.get('query');
                String recordId = paramMap.get('recordId');
                String extraFields = paramMap.get('extraFields');
                Integer maxResults = Integer.valueOf(paramMap.get('maxResults'));

                Search.SuggestionOption options = new Search.SuggestionOption();

                Search.KnowledgeSuggestionFilter filters = new Search.KnowledgeSuggestionFilter();

                if (objectType=='KnowledgeArticleVersion') {
                    filters.setLanguage(language);
                    filters.setPublishStatus('Online');

                }

                filters.setLanguage(language);
                filters.setPublishStatus('Online');

                options.setFilter(filters);
                options.setLimit(maxResults);

                Search.SuggestionResults suggestionResults = Search.suggest(searchText, objectType, options);
                List<Search.SuggestionResult> resultList = suggestionResults.getSuggestionResults();



                List<String> kaIdList = new List<String>();
                for (Search.SuggestionResult res : resultList)
                {
                    SObject sobj = res.getSOBject();
                    System.debug('sobj=' + JSON.serializePretty(sobj));
                    kaIdList.add((String)sobj.get('Id'));
                }
                System.debug('kaIdList=' + JSON.serializePretty(kaIdList));

                ////////////////////////////////////////////////
                // get list of KAs already attached to record //
                ////////////////////////////////////////////////
                List<String> laIdList = new List<String>();
                List<LinkedArticle> laList = [SELECT KnowledgeArticleId, KnowledgeArticleVersionId FROM LinkedArticle WHERE LinkedEntityId = :recordId];
                for (LinkedArticle la : laList)
                {
                    laIdList.add(la.KnowledgeArticleVersionId);
                }
                //////////////////////////////////////////////
                // build list of KA details to return to UI //
                //////////////////////////////////////////////
                String soql = 'SELECT Id, ArticleNumber, KnowledgeArticleId, MasterVersionId, Title, Summary';

                List<String> extraFieldsList = parseCSVString(extraFields);
                if (extraFieldsList != null)
                {
                    for (String fld : extraFieldsList)
                    {
                        soql += ', ' + fld;
                    }
                }

                soql += ' FROM Knowledge__kav WHERE Id IN (' + buildInList(kaIdList) + ')';
                System.debug('soql=' + soql);

                //List<Knowledge__kav> kaList = [SELECT Id, ArticleNumber, KnowledgeArticleId, MasterVersionId, Title, Summary, Code__c, Type__c FROM Knowledge__kav WHERE Id IN :kaIdList];
                List<Knowledge__kav> kaList = Database.query(soql);
                for (Knowledge__kav ka : kaList)
                {
                    Map<String, Object> rec = new Map<String, Object>();
                    rec.put('Id', (String)ka.get('Id'));
                    rec.put('ArticleNumber', (String)ka.get('ArticleNumber'));
                    rec.put('KnowledgeArticleId', (String)ka.get('KnowledgeArticleId'));
                    rec.put('MasterVersionId', (String)ka.get('MasterVersionId'));
                    rec.put('Title', (String)ka.get('Title'));
                    rec.put('Summary', (String)ka.get('Summary'));

                    if (extraFieldsList != null)
                    {
                        for (String fld : extraFieldsList)
                        {
                            rec.put(fld, (String)ka.get(fld));
                        }
                    }

                    rec.put('Attached', laIdList.contains((String)ka.get('Id')));

                    dataResp.add(rec);
                }

                System.debug(JSON.serializePretty(dataResp));
            }

            return  JSON.serialize(dataResp);
        }
        catch (exception e)
        {
            throw new  AuraHandledException(e.getTypeName() + ' - ' + e.getMessage() + ' [Line: ' + e.getLineNumber() + ']');
        }
    }

    private static List<String> parseCSVString(String csvStr)
    {
        if (csvStr == null || csvStr.length() == 0) return null;

        return csvStr.split(',');
    }

    private static String buildInList(List<String> strList)
    {
        if (strList == null) return null;

        String retStr;

        for (String str : strList)
        {
            if (retStr == null)
            {
                retStr = '\'' + str + '\'';
            }
            else {
                retStr += ', \'' + str + '\'';
            }
        }

        return retStr;
    }

    @AuraEnabled
    public static String attachDocToRecord(String params)
    {
        System.debug('attachDocToRecord invoked...');
        Map<String, String> paramMap = (Map<String, String>)JSON.deserialize(params,   Map<String, String>.class);
        System.debug(JSON.serializePretty(paramMap));

        try
        {
            Map<String, String> dataResp = new Map<String, String>();

            String recordId = null;
            String docId = null;
            String verId = null;
            String title = null;

            if (paramMap.containsKey('recId')) recordId = paramMap.get('recId');
            if (paramMap.containsKey('docId')) docId = paramMap.get('docId');
            if (paramMap.containsKey('verId')) verId = paramMap.get('verId');
            if (paramMap.containsKey('title')) title = paramMap.get('title');

            LinkedArticle la = new LinkedArticle();
            la.KnowledgeArticleId = docId;
            la.KnowledgeArticleVersionId = verId;
            la.LinkedEntityId = recordId;
            la.Name = title;
            insert la;

            return '';
        }
        catch (exception e)
        {
            throw new  AuraHandledException(e.getTypeName() + ' - ' + e.getMessage() + ' [Line: ' + e.getLineNumber() + ']');
        }
    }
}