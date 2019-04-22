# PSKnowledgeAttach
THIS SOFTWARE IS COVERED BY [THIS DISCLAIMER](https://raw.githubusercontent.com/thedges/Disclaimer/master/disclaimer.txt).

This package contains a Lightning component for attaching knowledge articles to *any* object. This component can be dropped on any record page and works similar to way the standard knowledge component works only with cases. Here are core capabilities of the component:

* <b>Attach Knowledge Articles</b> - ability to attach knowledge articles to any object
* <b>Search</b> - search knowledge articles based on search string
* <b>Auto Search</b> - automatically search for knowledge articles based on a configurable field value on the record
* <b>Extra Article Fields</b> - configurable list of extra knowledge article fields to show in the search results
* <b>Clickable Results</b> - click on knowledge article title in search results to launch new window to see article details

Here is the component in action:

![alt text](https://github.com/thedges/PSKnowledgeAttach/blob/master/PSKnowledgeAttach.gif "PSKnowledgeAttach")

Here are the configuration options:

| Parameter  | Definition |
| ------------- | ------------- |
| Title  | The title at top of the component  |
| Search Results Limit  | Integer value to limit the number of search results  |
| Auto Search  | Checkbox to enable auto-search on record page load  |
| Search Field  | The field API name of record to use as default search string for auto-searching  |
| Extra Fields  | Comma separated list of field API names on the Knowledge__kav object to show in search results  |

Here is example of a configuration done for a demo:

![alt text](https://github.com/thedges/PSKnowledgeAttach/blob/master/PSKnowledgeAttach-Config.gif "PSKnowledgeAttach Config")

# Setup Instructions
Here are steps to setup and configure this component:
  * Install the component per the "Deploy to Salesforce" button below.
  * Drop the component on record page of your choice.
  * Configure the component per the options above.
  * That is it!

Then click this to install this package:

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
