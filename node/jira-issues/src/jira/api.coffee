require 'fluentnode'

JiraApi = require('jira-client')
Config  = require('../../src/config')


class Api
  constructor: ->
    @._jira_Api = new JiraApi(Config)

  currentUser: (callback)->
    @._call_Jira 'getCurrentUser', [], (data)->
      callback data.name

  _call_Jira: (command, params, callback)=>
    @._jira_Api[command].apply(@._jira_Api,  params)
      .then (data)->
        callback data
      .catch (err)->
        console.log err.message
        throw err

  issue: (key, callback)->
    issueNumber  = key
    expand       = ""
    fields       = ""
    properties   = "*"
    fieldsByKeys = false
    @._call_Jira "findIssue", [issueNumber,expand, fields,properties,fieldsByKeys], callback

  issues: (jql, fields, callback)=>
    callback = callback || fields           # make fields value optional
    issues   = []
    options =
      startAt   : 0
      maxResults: 200
      #expand    : ['changelog']
      fields    : fields || ['summary','status']

    get_Issues = () =>
      @._call_Jira "searchJira", [jql,options], (data)->
        #console.log options, data.issues.size()
        #console.log "[jira api] fetched #{data.issues.size()} issues"
        if data.issues.size() > 0
          options.startAt += data.issues.size()
          issues = issues.concat data.issues
          get_Issues()                          # recursive call to get more issues
        else
          callback issues                       # no more issues'


    get_Issues jql

  # This can be improved to fail faster when access is not available
  ping_Server: (callback)->
    url = "#{Config.protocol}://#{Config.host}"
    url.GET (data)->
      callback data

  search: (jql, callback)->
    options =
      startAt   : 1
      maxResults: 50
      fields    : ['summary','status']
    @._call_Jira "searchJira", [jql,options], callback

module.exports = Api