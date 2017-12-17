process.on "uncaughtException", (err...) ->
  console.log 'node.js error: '
  console.log err

angular.module("app", ['mgcrea.ngStrap', 'prompt', "flowchartDataModel", "flowChartController", "topo", "timeline", "syslog"
]).controller("AppCtrl", [
  "$scope"
  "$http"
  "prompt"
  "flowchartDataModel"
  "topoAlgorithm"
  "syslogService"
  AppCtrl = ($scope, $http, prompt, flowchartDataModel, topoAlgorithm, syslogService) ->
    $http.get('resource/topo_for_debug.json').success (topd) ->
      raw = (dev for ip,dev of topd)
      cb = (data) ->
        ###
        chartDataModel =
          nodes: [
            {
              name: "IS-084"
              id: 0
              x: 0
              y: 0
              inputConnectors: [
                {
                  name: "P1"
                }
                {
                  name: "P2"
                }
                {
                  name: "P3"
                }
                {
                  name: "P4"
                }
              ]
              outputConnectors: [
                {
                  name: "P5"
                }
                {
                  name: "P6"
                }
                {
                  name: "P7"
                }
                {
                  name: "P8"
                }
              ]
            }
            {
              name: "IS-085"
              id: 1
              x: 400
              y: 200
              inputConnectors: [
                {
                  name: "P1"
                }
                {
                  name: "P2"
                }
                {
                  name: "P3"
                }
                {
                  name: "P4"
                }
              ]
              outputConnectors: [
                {
                  name: "P5"
                }
                {
                  name: "P6"
                }
                {
                  name: "P7"
                }
                {
                  name: "P8"
                }
              ]
            }
          ]
          connections: [
            source:
              nodeID: 0
              connectorIndex: 1

            dest:
              nodeID: 1
              connectorIndex: 2
          ]
        ###
        $scope.chartViewModel = new flowchartDataModel.ChartViewModel(data)
        $scope.nodelist = data.nodes
        iplist = (n.ip for n in $scope.nodelist)
        $scope.dataByIP = []
        for ip in iplist
          do(ip) ->
            syslogService.selectSyslogByIP ip, (data)->
              $scope.$apply(->
                angular.extend $scope.dataByIP, data
              )
      ###
      noPoscb = (data) ->
        $scope.nodelist = data.nodes
      ###
      #topoAlgorithm.preProcess(raw, cb)
      #topoAlgorithm.preProcess(raw, noPoscb, 'noPos')
      topoAlgorithm.preProcess(raw, cb)
    # Code for the delete key.
    deleteKeyCode = 46
    deleteKeyCodeMac = 8
    # Code for control key.
    ctrlKeyCode = 17
    ctrlKeyCodeMac = 91
    # Set to true when the ctrl key is down.
    ctrlDown = false
    ADown = false
    # Code for A key.
    aKeyCode = 65
    # Code for esc key.
    escKeyCode = 27
    # Selects the next node id.
    nextNodeID = 0
    #initail node pos
    InitialNodeX = 50
    InitialNodeY = 50
    # Setup the data-model for the chart.
    $scope.print = () ->
      console.log $scope.chartViewModel.data
    # Event handler for key-down on the flowchart.
    preventDefaultAction = (evt) ->
      #stop event bubbles
      evt.stopPropagation()
      #stop native event from happening
      evt.preventDefault()
    $scope.keyDown = (evt) ->
      if (evt.keyCode is ctrlKeyCode) or (evt.keyCode is ctrlKeyCodeMac)
        preventDefaultAction(evt)
        ctrlDown = true
      if evt.keyCode is aKeyCode
        preventDefaultAction(evt)
        ADown = true
      if evt.keyCode is deleteKeyCodeMac
        preventDefaultAction(evt)
      # Ctrl + A
      if ADown and ctrlDown then $scope.chartViewModel.selectAll()
      if ctrlDown
        console.log 'control down'
        #MUTIPLY SELECTION
        #console.log $scope.chartViewModel
    # Event handler for key-up on the flowchart.
    $scope.keyUp = (evt) ->
      # Delete key.
      if (evt.keyCode is deleteKeyCode) or (evt.keyCode is deleteKeyCodeMac)
        $scope.chartViewModel.deleteSelected()
      # Escape.
      $scope.chartViewModel.deselectAll()  if evt.keyCode is escKeyCode
      if (evt.keyCode is ctrlKeyCode) or (evt.keyCode is ctrlKeyCodeMac)
        ctrlDown = false
      if evt.keyCode is aKeyCode
        ADown = false
    # Add a new node to the chart.
    $scope.nodeExistOnChart = (node) ->
      if $scope.chartViewModel.findNode(node.data.id)?
        return true
      else
        return false
    $scope.nodelistMouseDown = (evt, node) ->
      if $scope.chartViewModel.findNode(node.data.id)?
        $scope.chartViewModel.deselectAll()
        $scope.chartViewModel.findNode(node.data.id).toggleSelected()
      else
        node.data.x = evt.clientX + 100
        node.data.y = evt.clientY
        $scope.chartViewModel.addNode node.data

    $scope.addNewNode = ->
      InitialNodeX = InitialNodeX + 100
      InitialNodeY = InitialNodeY + 150
      $scope.mutinode = false
      # Template for a new node.
      $scope.targetNode =
        name: "New Node"
        id: nextNodeID++
        x: InitialNodeX
        y: InitialNodeY
        inputConnectors: [
          {
            name: "X"
          }
          {
            name: "Y"
          }
          {
            name: "Z"
          }
        ]
        outputConnectors: [
          {
            name: "1"
          }
          {
            name: "2"
          }
          {
            name: "3"
          }
        ]
      $scope.newValue = $scope.targetNode.name
      cb = () ->
        $scope.targetNode.name = $scope.newValue
        $scope.chartViewModel.addNode $scope.targetNode
      prompt("Enter a node name:", "New node", $scope, cb)
    # Add an input connector to selected nodes.
    $scope.addNewInputConnector = ->
      $scope.newValue = Math.floor(Math.random() * (12 - 0 + 1)) + 0
      selectedNodes = $scope.chartViewModel.getSelectedNodes()
      if selectedNodes.length > 1
        $scope.mutinode = true
        $scope.targetNodes = []
        for i in selectedNodes
          $scope.targetNodes.push i.data.name
      else
        $scope.targetNode = selectedNodes[0].data
      cb = () ->
        i = 0
        while i < selectedNodes.length
          node = selectedNodes[i]
          node.addInputConnector name: $scope.newValue
          ++i
        return
      prompt("Enter a connector name:", "", $scope, cb)
    # Add an output connector to selected nodes.
    $scope.addNewOutputConnector = ->
      $scope.newValue = Math.floor(Math.random() * (12 - 0 + 1)) + 0
      selectedNodes = $scope.chartViewModel.getSelectedNodes()
      if selectedNodes.length > 1
        $scope.mutinode = true
        $scope.targetNodes = []
        for i in selectedNodes
          $scope.targetNodes.push i.data.name
      else
        $scope.targetNode = selectedNodes[0].data
      cb = () ->
        i = 0
        while i < selectedNodes.length
          node = selectedNodes[i]
          node.addOutputConnector name: $scope.newValue
          ++i
        return
      prompt("Enter a connector name:", "", $scope, cb)
    # Delete selected nodes and connections.
    $scope.deleteSelected = ->
      $scope.chartViewModel.deleteSelected()
      return
    $scope.random_connectiondown = ->
      console.log $scope.chartViewModel.data
      max = $scope.chartViewModel.data.connections.length - 1
      min = 0
      linkindex = Math.floor(Math.random() * (max - min + 1)) + min

      $scope.chartViewModel.data.connections[linkindex].connectionAlive = false

    $scope.random_connectionblock = ->
      max = $scope.chartViewModel.data.connections.length - 1
      min = 0
      linkindex = Math.floor(Math.random() * (max - min + 1)) + min
      $scope.chartViewModel.data.connections[linkindex].connectionNotBlocked = false
    $scope.random_nodedown = ->
      max = $scope.chartViewModel.data.nodes.length - 1
      min = 0
      nodeindex = Math.floor(Math.random() * (max - min + 1)) + min
      $scope.chartViewModel.data.nodes[nodeindex].nodeAlive = false
    $scope.random_nodewarn = ->
      max = $scope.chartViewModel.data.nodes.length - 1
      min = 0
      nodeindex = Math.floor(Math.random() * (max - min + 1)) + min

      $scope.chartViewModel.data.nodes[nodeindex].nodeWarning = true
    $scope.random_portdown = ->
      max = $scope.chartViewModel.data.nodes.length - 1
      min = 0
      nodeindex = Math.floor(Math.random() * (max - min + 1)) + min
      if $scope.chartViewModel.data.nodes[nodeindex].outputConnectors.length > 0
        max = $scope.chartViewModel.data.nodes[nodeindex].outputConnectors.length - 1
        connectorindex = Math.floor(Math.random() * (max - min + 1)) + min
        $scope.chartViewModel.data.nodes[nodeindex].outputConnectors[connectorindex].linked = false
      if $scope.chartViewModel.data.nodes[nodeindex].inputConnectors.length > 0
        max = $scope.chartViewModel.data.nodes[nodeindex].inputConnectors.length - 1
        connectorindex = Math.floor(Math.random() * (max - min + 1)) + min
        $scope.chartViewModel.data.nodes[nodeindex].inputConnectors[connectorindex].linked = false
    # Create the view-model for the chart and attach to the scope.
    #$scope.chartViewModel = new flowchartDataModel.ChartViewModel(chartDataModel)
]
).directive("ngRightClick", ($parse) ->
  (scope, element, attrs) ->
    fn = $parse(attrs.ngRightClick)
    element.bind "contextmenu", (event) ->
      scope.$apply ->
        event.preventDefault()
        fn scope,
          $event: event
)