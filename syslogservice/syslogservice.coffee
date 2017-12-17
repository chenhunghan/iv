angular.module("syslog", []).service( "syslogService", ()->
  syslog = require './node_modules/insta-syslog/syslog'
  syslogService = new syslog.SyslogService()
  console.log '[Info] This is syslog service.'
  return syslogService
)