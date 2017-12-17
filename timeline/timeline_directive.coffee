angular.module("timeline", ['syslog']).directive("timeline", ['$window', '$interval', 'syslogService', '$timeout', ($window, $interval, syslogService, $timeout) ->
  restrict: "E"
  templateUrl: "timeline/timeline_template.html"
  scope:
    chartViewModel: "=chart"
  compile: (tele, attrs) ->
    #ref: http://almende.github.io/chap-links-library/timeline.html
    link = (scope, ele, attr) ->
      # show live event
      cb = (d) ->
        console.log '[Info] Show Live Syslog'
        node = scope.chartViewModel.findNodeByIP d.hostip
        if node isnt false
          $timeout () ->
            console.log '[Info] This is timeout.'
            node.data.nodeWarning = false
            node.data.nodeAlive = true
          , 3000
          node.data.nodeWarning = true
          node.data.nodeAlive = false

          scope.$apply()
        else
          console.log "[Warning] Can not find the node by IP: #{d.ip}"

        #scope.chartViewModel.data.nodes[nodeindex].outputConnectors[connectorindex].linked = false
        #scope.chartViewModel.data.connections[linkindex].connectionNotBlocked = false
        #scope.chartViewModel.data.nodes[nodeindex].nodeWarning = true

      syslogService.startSyslogService(cb)
      timelineWraper = $('.timeline')[0]
      timeline = new links.Timeline(timelineWraper)
      options =
        width: "100%"
        height: "100%"
        zoomMax: (315360000000*0.25/2) #315360000000 = 5 years
        cluster: true
        eventMargin: 5
        eventMarginAxis: 10
        groupMinHeight: 13
      timeline.setOptions options
      now = new $window.Date()
      startTime = new $window.Date()
      startTime.setHours startTime.getHours()-2
      timeline.setVisibleChartRange(startTime, now)
      scope.range =
        start:
          time: startTime
          date: startTime
        end:
          time: now
          date: now
      oldsysdata = []

      get_data = ->
        timeline_range = timeline.getVisibleChartRange()
        startTime = timeline_range.start
        endTime = timeline_range.end

        syslogService.selectSyslogByDatetime startTime, endTime, (syslogdata) ->
          if angular.equals(oldsysdata, syslogdata) is false
            oldsysdata = syslogdata
            data = []
            for d in syslogdata
              do(d) ->
                data.push
                  start: new Date(d.edatetime)
                  content: "#{d.category} is #{d.strvalue}"
                  group: d.category
                  hostip: d.hostip
                  hostname: d.hostname
            timeline.draw(data)
      # only needed when you need two-way binding ( may cause problems when user scroll too fast!)
      ###
      scope.$watch 'range', (o, n) ->
        if n
          timeline.setVisibleChartRange scope.range.start.time, scope.range.end.time

      , true
      ###
      get_data()
      links.events.addListener timeline, 'rangechanged', () ->
        get_data()
        scope.$apply( ->
          timeline_range = timeline.getVisibleChartRange()
          scope.range.start.time = timeline_range.start
          scope.range.start.date = timeline_range.start
          scope.range.end.time = timeline_range.end
          scope.range.end.date = timeline_range.end
        )
      links.events.addListener timeline, 'select', () ->
        if timeline.getSelection().length isnt 0
          scope.content = timeline.data[timeline.getSelection()[0].row]
          timeline.setCurrentTime timeline.data[timeline.getSelection()[0].row].start
          scope.currentTime = timeline.data[timeline.getSelection()[0].row].start
          scope.$apply()
      scope.playing = false

      onlyonce = true
      oldchartViewModelData = []
      scope.$watch 'chartViewModel.data', (n, o) ->
        if n isnt undefined and onlyonce
          oldchartViewModelData = JSON.stringify(n)
          onlyonce = false
          console.log 'viewModel init completed'

      scope.play = ->

        scope.playing = true
        playtime = 500 #milliseconds
        playbackstart = timeline.getVisibleChartRange().start.valueOf()
        playbackend = timeline.getVisibleChartRange().end.valueOf()

        if scope.playmoment
          playbackstart = scope.playmoment
        else
          scope.playmoment = timeline.getVisibleChartRange().start.valueOf()
        scope.playbackstep = (timeline.getVisibleChartRange().end.valueOf() - timeline.getVisibleChartRange().start.valueOf())/playtime

        allevent = timeline.getData()
        eventinRange = []
        for event in allevent
          do (event) ->
            if playbackstart < event.start.valueOf() < playbackend
              eventinRange.push event
        playbackloop = ->
          scope.playmoment = scope.playmoment + scope.playbackstep
          scope.currentTime = new Date(scope.playmoment)
          timeline.setCurrentTime(scope.currentTime)
          for event in eventinRange
            do (event) ->
              if (event.start.valueOf() - scope.playmoment) > 0
                if (event.start.valueOf() - scope.playmoment) < scope.playbackstep
                  console.log event

                  maxnode = scope.chartViewModel.data.nodes.length - 1
                  minnode = 0
                  nodeindex = Math.floor(Math.random() * (maxnode - minnode + 1)) + minnode
                  scope.chartViewModel.data.nodes[nodeindex].nodeAlive = false

                  maxlink = scope.chartViewModel.data.connections.length - 1
                  minlink = 0
                  linkindex = Math.floor(Math.random() * (maxlink - minlink + 1)) + minlink
                  scope.chartViewModel.data.connections[linkindex].connectionNotBlocked = false

                  max = scope.chartViewModel.data.nodes.length - 1
                  min = 0
                  nodeindex = Math.floor(Math.random() * (max - min + 1)) + min
                  if scope.chartViewModel.data.nodes[nodeindex].outputConnectors.length > 0
                    max = scope.chartViewModel.data.nodes[nodeindex].outputConnectors.length - 1
                    connectorindex = Math.floor(Math.random() * (max - min + 1)) + min
                    scope.chartViewModel.data.nodes[nodeindex].outputConnectors[connectorindex].linked = false
                  if scope.chartViewModel.data.nodes[nodeindex].inputConnectors.length > 0
                    max = scope.chartViewModel.data.nodes[nodeindex].inputConnectors.length - 1
                    connectorindex = Math.floor(Math.random() * (max - min + 1)) + min
                    scope.chartViewModel.data.nodes[nodeindex].inputConnectors[connectorindex].linked = false

          if scope.playmoment > playbackend
            console.log 'end'
            $interval.cancel playloop
            scope.playing = false
            scope.playmoment = timeline.getVisibleChartRange().start.valueOf()

        playloop = $interval playbackloop, 1

        scope.pause = ->
          $interval.cancel playloop
          scope.playing = false
          scope.pause = true
        scope.reset = ->
          $interval.cancel playloop
          scope.playmoment = timeline.getVisibleChartRange().start.valueOf()
          timeline.setCurrentTime(scope.playmoment)
          scope.playing = false
          scope.pause = false

          for node in scope.chartViewModel.data.nodes
            node.nodeAlive = true
            for connetor in node.outputConnectors
              connetor.linked = true
            for connetor in node.inputConnectors
              connetor.linked = true
          for connection in scope.chartViewModel.data.connections
            connection.connectionNotBlocked = true

        #$interval must destroyed on directive leave'
        scope.$on '$destroy', ->
          $interval.cancel playloop
      # 10min playback
      ###
      scope.playback = ->
        console.log 'start playback'
      ###
    return link
])