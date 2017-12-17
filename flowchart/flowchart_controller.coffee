removeClassSVG = (obj, remove) ->
  classes = obj.attr("class")
  return false  unless classes
  index = classes.search(remove)
  # if the class already doesn't exist, return false now
  if index is -1
    false
  else
    # string manipulation to remove the class
    classes = classes.substring(0, index) + classes.substring((index + remove.length), classes.length)
    # set the new string as the object's class
    obj.attr "class", classes
    true
hasClassSVG = (obj, has) ->
  classes = obj.attr("class")
  return false  unless classes
  index = classes.search(has)
  if index is -1
    false
  else
    true
angular.module("flowChartController", ["dragging", 'prompt']).directive("flowChart", ->
  restrict: "E"
  templateUrl: "flowchart/flowchart_template.html"
  replace: true
  scope:
    chart: "=chart"
  controller: "FlowChartController"
).controller("FlowChartController", [
  "$scope"
  "dragging"
  "$element"
  "flowchartDataModel"
  "prompt"
  FlowChartController = ($scope, dragging, $element, flowchartDataModel, prompt) ->
    controller = this
    # Reference to the document and jQuery, can be overridden for testting.
    @document = document
    # Wrap jQuery so it can easily be  mocked for testing.
    @jQuery = (element) ->
      $ element
    # Init data-model variables.
    $scope.draggingConnection = false
    $scope.connectorSize = 10
    $scope.dragSelecting = false
    # Can use this to test the drag selection rect.
    #	$scope.dragSelectionRect = {
    #		x: 0,
    #		y: 0,
    #		width: 0,
    #		height: 0,
    #	};
    # Reference to the connection, connector or node that the mouse is currently over.
    $scope.mouseOverConnector = null
    $scope.mouseOverConnection = null
    $scope.mouseOverNode = null
    # The class for connections and connectors.
    @connectionClass = "connection"
    @connectorClass = "connector"
    @nodeClass = "node"
    # Search up the HTML element tree for an element the requested class.
    @searchUp = (element, parentClass) ->
      # Reached the root.
      return null  if not element? or element.length is 0
      # Check if the element has the class that identifies it as a connector.
      # Found the connector element.
      return element  if hasClassSVG(element, parentClass)
      # Recursively search parent elements.
      @searchUp element.parent(), parentClass
    # Hit test and retreive node and connector that was hit at the specified coordinates.
    @hitTest = (clientX, clientY) ->
      # Retreive the element the mouse is currently over.
      @document.elementFromPoint clientX, clientY
    # Hit test and retreive node and connector that was hit at the specified coordinates.
    @checkForHit = (mouseOverElement, whichClass) ->
      # Find the parent element, if any, that is a connector.
      hoverElement = @searchUp(@jQuery(mouseOverElement), whichClass)
      return null  unless hoverElement
      hoverElement.scope()
    # Translate the coordinates so they are relative to the svg element.
    @translateCoordinates = (x, y) ->
      svg_elem = $element.get(0)
      matrix = svg_elem.getScreenCTM()
      point = svg_elem.createSVGPoint()
      point.x = x
      point.y = y
      point.matrixTransform matrix.inverse()
    # Called on mouse down in the chart.
    $scope.mouseDown = (evt) ->
      console.log $scope.chart
      switch evt.button
        when 0
          $scope.chart.deselectAll()
          dragging.startDrag evt,
            # Commence dragging... setup variables to display the drag selection rect.
            dragStarted: (x, y) ->
              $scope.dragSelecting = true
              startPoint = controller.translateCoordinates(x, y)
              $scope.dragSelectionStartPoint = startPoint
              $scope.dragSelectionRect =
                x: startPoint.x
                y: startPoint.y
                width: 0
                height: 0
              return
          # Update the drag selection rect while dragging continues.
            dragging: (x, y) ->
              startPoint = $scope.dragSelectionStartPoint
              curPoint = controller.translateCoordinates(x, y)
              $scope.dragSelectionRect =
                x: (if curPoint.x > startPoint.x then startPoint.x else curPoint.x)
                y: (if curPoint.y > startPoint.y then startPoint.y else curPoint.y)
                width: (if curPoint.x > startPoint.x then curPoint.x - startPoint.x else startPoint.x - curPoint.x)
                height: (if curPoint.y > startPoint.y then curPoint.y - startPoint.y else startPoint.y - curPoint.y)
              return
          # Dragging has ended... select all that are within the drag selection rect.
            dragEnded: ->
              $scope.dragSelecting = false
              $scope.chart.applySelectionRect $scope.dragSelectionRect
              delete $scope.dragSelectionStartPoint
              delete $scope.dragSelectionRect
              return
        when 2
          if evt.target.nodeName and evt.target.nodeName is 'svg'
            console.log 'right click on flowchart.'

    # Called for each mouse move on the svg element.
    $scope.mouseMove = (evt) ->
      for connection in $scope.chart.connections
        do (connection) ->
          connection.opacity = connection.distance()/2000
      # Clear out all cached mouse over elements.
      $scope.mouseOverConnection = null
      $scope.mouseOverConnector = null
      $scope.mouseOverNode = null
      mouseOverElement = controller.hitTest(evt.clientX, evt.clientY)
      # Mouse isn't over anything, just clear all.
      return  unless mouseOverElement?
      unless $scope.draggingConnection # Only allow 'connection mouse over' when not dragging out a connection.
        # Figure out if the mouse is over a connection.
        scope = controller.checkForHit(mouseOverElement, controller.connectionClass)
        $scope.mouseOverConnection = (if (scope and scope.connection) then scope.connection else null)
        # Don't attempt to mouse over anything else.
        return  if $scope.mouseOverConnection
      # Figure out if the mouse is over a connector.
      scope = controller.checkForHit(mouseOverElement, controller.connectorClass)
      $scope.mouseOverConnector = (if (scope and scope.connector) then scope.connector else null)
      # Don't attempt to mouse over anything else.
      return  if $scope.mouseOverConnector
      # Figure out if the mouse is over a node.
      scope = controller.checkForHit(mouseOverElement, controller.nodeClass)
      $scope.mouseOverNode = (if (scope and scope.node) then scope.node else null)
      return
    # Handle mousedown on a node.
    $scope.nodeMouseDown = (evt, node) ->
      if evt.shiftKey or evt.ctrlKey
        $scope.chart.handleNodeClicked node, true
      else
        # If nothing is selected when dragging starts,
        # at least select the node we are dragging.
        unless node.selected()
          $scope.chart.deselectAll()
          node.select()
      switch evt.button
        when 0
          chart = $scope.chart
          lastMouseCoords = undefined
          dragging.startDrag evt,
            # Node dragging has commenced.
            dragStarted: (x, y) ->
              lastMouseCoords = controller.translateCoordinates(x, y)
          # Dragging selected nodes... update their x,y coordinates.
            dragging: (x, y) ->
              curCoords = controller.translateCoordinates(x, y)
              deltaX = curCoords.x - lastMouseCoords.x
              deltaY = curCoords.y - lastMouseCoords.y
              chart.updateSelectedNodesLocation deltaX, deltaY
              lastMouseCoords = curCoords
              return
          # The node wasn't dragged... it was clicked.
            clicked: ->
                return
          return
        when 2
          #console.log evt
          if node.selected()
            console.log 'rihgt click on node'
            console.log node.data
    # Handle mousedown on a connection.
    $scope.connectionMouseDown = (evt, connection) ->
      #need to prevent default action on path
      evt.stopPropagation()
      evt.preventDefault()
      if evt.shiftKey or evt.ctrlKey
        $scope.chart.handleConnectionMouseDown connection, true
      else
        unless connection.selected()
          $scope.chart.deselectAll()
          connection.select()
      switch evt.button
        when 0
          console.log 'left click on connection'
        when 2
          console.log 'rihgt click on connection'
          console.log connection.data
    $scope.connectedConnectorMouseDown = (evt, connection) ->
      unless connection.selected()
        $scope.chart.deselectAll()
        connection.select()
      sd = Math.abs(event.x - connection.sourceCoordX()) + Math.abs(event.y - connection.sourceCoordY())
      dd = Math.abs(event.x - connection.destCoordX()) + Math.abs(event.y - connection.destCoordY())
      isInputConnector = (connector) ->
        if connector.x() is (flowchartDataModel.nodeWidth - flowchartDataModel.padding)
          return false
        else
          return true
      node = (connector) ->
        return connector.parentNode()
      connectorIndex = (connector) ->
        switch isInputConnector(connector)
          when true
            for n,i in node(connector).inputConnectors
              if angular.equals(n, connector)
                return i
          when false
            for n,i in node(connector).outputConnectors
              if angular.equals(n, connector)
                return i
      if sd < 35
        connector = connection.dest
        $scope.connectorMouseDown(evt, node(connector), connector, connectorIndex(connector), isInputConnector(connector))
        $scope.chart.deleteSelected()
      if dd < 35
        connector = connection.source
        $scope.connectorMouseDown(evt, node(connector), connector, connectorIndex(connector), isInputConnector(connector))
        $scope.chart.deleteSelected()
    # Handle mousedown on an input connector.
    $scope.connectorMouseDown = (evt, node, connector, connectorIndex, isInputConnector) ->
      ###
      console.log evt
      console.log node
      console.log connector
      console.log connectorIndex
      console.log isInputConnector

###
      # Initiate dragging out of a connection.
      dragging.startDrag evt,
        # Called when the mouse has moved greater than the threshold distance
        # and dragging has commenced.
        dragStarted: (x, y) ->
          curCoords = controller.translateCoordinates(x, y)
          $scope.draggingConnection = true
          $scope.dragPoint1 = flowchartDataModel.computeConnectorPos(node, connectorIndex, isInputConnector)
          $scope.dragPoint2 =
            x: curCoords.x
            y: curCoords.y
          $scope.dragTangent1 = flowchartDataModel.computeConnectionSourceTangent($scope.dragPoint1, $scope.dragPoint2)
          $scope.dragTangent2 = flowchartDataModel.computeConnectionDestTangent($scope.dragPoint1, $scope.dragPoint2)
          return
      # Called on mousemove while dragging out a connection.
        dragging: (x, y, evt) ->

          startCoords = controller.translateCoordinates(x, y)
          $scope.dragPoint1 = flowchartDataModel.computeConnectorPos(node, connectorIndex, isInputConnector)
          $scope.dragPoint2 =
            x: startCoords.x
            y: startCoords.y
          $scope.dragTangent1 = flowchartDataModel.computeConnectionSourceTangent($scope.dragPoint1, $scope.dragPoint2)
          $scope.dragTangent2 = flowchartDataModel.computeConnectionDestTangent($scope.dragPoint1, $scope.dragPoint2)
          return
      # Clean up when dragging has finished.
        dragEnded: ->
          # Dragging has ended...
          # The mouse is over a valid connector...
          # Create a new connection.
          $scope.chart.createNewConnection connector, $scope.mouseOverConnector  if $scope.mouseOverConnector and $scope.mouseOverConnector isnt connector
          $scope.draggingConnection = false
          delete $scope.dragPoint1
          delete $scope.dragTangent1
          delete $scope.dragPoint2
          delete $scope.dragTangent2
          return
      return
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
      selectedNodes = $scope.chart.getSelectedNodes()
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
      selectedNodes = $scope.chart.getSelectedNodes()
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
      $scope.chart.deleteSelected()
      return
]
)