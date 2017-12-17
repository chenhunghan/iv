# Debug utilities.
throw new Error("debug object already defined!")  if typeof debug isnt "undefined"
debug = {}
# Assert that an object is valid.
debug.assertObjectValid = (obj) ->
  throw new Exception("Invalid object!")  unless obj
  throw new Error("Input is not an object! It is a " + typeof (obj))  if $.isPlainObject(obj)

angular.module("flowchartDataModel", []).service( "node", [() ->
  node = this
  node.width = 60
  node.padding = 15
  node.nodeNameHeight = 50
  return
]).service("connector", ["node", (node) ->
    connector = this
    connector.connectorHeight = 46
    # View model for a connector.
    connector.ConnectorViewModel = (connectorDataModel, x, y, parentNode) ->
      if x is 0
        x = x + node.padding
      else
        x = x - node.padding
      @data = connectorDataModel
      @data.linked = true
      @linked = ->
        @data.linked
      @_parentNode = parentNode
      @_x = x
      @_y = y
      # The name of the connector.
      @name = ->
        @data.name
      # X coordinate of the connector.
      @x = ->
        @_x
      # Y coordinate of the connector.
      @y = ->
        @_y
      # The parent node that the connector is attached to.
      @parentNode = ->
        @_parentNode
      return
    return
  ]
).service("flowchartDataModel", [ "node", "connector", (node, connector)->
    flowchart = this
    flowchart.width = 1185
    flowchart.height = 580
    flowchart.nodeWidth = node.width
    flowchart.padding = node.padding
    flowchart.nodeNameHeight = node.nodeNameHeight
    flowchart.connectorHeight = connector.connectorHeight
    # Compute the Y coordinate of a connector, given its index.
    flowchart.computeConnectorY = (connectorIndex) ->
      flowchart.nodeNameHeight + (connectorIndex * flowchart.connectorHeight)
    # Compute the position of a connector in the graph.
    flowchart.computeConnectorPos = (node, connectorIndex, inputConnector) ->
      x: node.x() + (if inputConnector then flowchart.padding else (flowchart.nodeWidth - flowchart.padding))
      y: node.y() + flowchart.computeConnectorY(connectorIndex)
    # View model for a node.
    flowchart.NodeViewModel = (nodeDataModel) ->
      # Create view model for a list of data models.
      createConnectorsViewModel = (connectorDataModels, x, parentNode) ->
        viewModels = []
        if connectorDataModels
          i = 0
          while i < connectorDataModels.length
            connectorViewModel = new connector.ConnectorViewModel(connectorDataModels[i], x, flowchart.computeConnectorY(i), parentNode)
            viewModels.push connectorViewModel
            ++i
        viewModels
      #padding = 18 #padding space for each connector
      @data = nodeDataModel
      @inputConnectors = createConnectorsViewModel(@data.inputConnectors, 0, this)
      @outputConnectors = createConnectorsViewModel(@data.outputConnectors, flowchart.nodeWidth, this)
      # Set to true when the node is selected.
      @_selected = false
      @data.nodeAlive = true
      @data.nodeWarning = false
      # Name of the node.
      @name = ->
        @data.name or ""
      # X coordinate of the node.
      @x = ->
        @data.x
      # Y coordinate of the node.
      @y = ->
        @data.y
      # Width of the node.
      @width = ->
        flowchart.nodeWidth
      # Height of the node.
      @height = ->
        numConnectors = Math.max(@inputConnectors.length, @outputConnectors.length)
        flowchart.computeConnectorY(numConnectors)-25
      # Select the node.
      @select = ->
        @_selected = true
        return
      # Deselect the node.
      @deselect = ->
        @_selected = false
        return
      # Toggle the selection state of the node.
      @toggleSelected = ->
        @_selected = not @_selected
        return
      # Returns true if the node is selected.
      @selected = ->
        @_selected
      @nodeAlive = ->
        @data.nodeAlive
      @nodeWarning = ->
        @data.nodeWarning
      # Internal function to add a connector.
      @_addConnector = (connectorDataModel, x, connectorsDataModel, connectorsViewModel) ->
        connectorViewModel = new connector.ConnectorViewModel(connectorDataModel, x, flowchart.computeConnectorY(connectorsViewModel.length), this)
        connectorsDataModel.push connectorDataModel
        # Add to node's view model.
        connectorsViewModel.push connectorViewModel
        return
      # Add an input connector to the node.
      @addInputConnector = (connectorDataModel) ->
        @data.inputConnectors = []  unless @data.inputConnectors
        @_addConnector connectorDataModel, 0, @data.inputConnectors, @inputConnectors
        return
      # Add an ouput connector to the node.
      @addOutputConnector = (connectorDataModel) ->
        @data.outputConnectors = []  unless @data.outputConnectors
        @_addConnector connectorDataModel, flowchart.nodeWidth, @data.outputConnectors, @outputConnectors
        return
      return
    # Wrap the nodes data-model in a view-model.
    createNodesViewModel = (nodesDataModel) ->
      nodesViewModel = []
      if nodesDataModel
        i = 0
        while i < nodesDataModel.length
          nodesViewModel.push new flowchart.NodeViewModel(nodesDataModel[i])
          ++i
      nodesViewModel
    # View model for a connection.
    flowchart.ConnectionViewModel = (connectionDataModel, sourceConnector, destConnector) ->
      @data = connectionDataModel
      @source = sourceConnector
      @dest = destConnector
      # Set to true when the connection is selected.
      @_selected = false
      @sourceCoordX = ->
        if @source then return @source.parentNode().x() + @source.x()
      @sourceCoordY = ->
        if @source then return @source.parentNode().y() + @source.y()
      @sourceCoord = ->
        x: @sourceCoordX()
        y: @sourceCoordY()
      @sourceTangentX = ->
        flowchart.computeConnectionSourceTangentX @sourceCoord(), @destCoord()
      @sourceTangentY = ->
        flowchart.computeConnectionSourceTangentY @sourceCoord(), @destCoord()
      @destCoordX = ->
        if @dest then return @dest.parentNode().x() + @dest.x()
      @destCoordY = ->
        if @dest then return @dest.parentNode().y() + @dest.y()
      @destCoord = ->
        x: @destCoordX()
        y: @destCoordY()
      @destTangentX = ->
        flowchart.computeConnectionDestTangentX @sourceCoord(), @destCoord()
      @destTangentY = ->
        flowchart.computeConnectionDestTangentY @sourceCoord(), @destCoord()
      @distance = ->
        dd = (a) -> a*a
        dx = @destCoordX() - @sourceCoordX()
        dy = @destCoordY() - @sourceCoordY()
        return Math.sqrt( dd(dx) + dd(dy) )
      @opacity = 0.2
      # Select the connection.
      @select = ->
        @_selected = true
        return
      # Deselect the connection.
      @deselect = ->
        @_selected = false
        return
      # Toggle the selection state of the connection.
      @toggleSelected = ->
        @_selected = not @_selected
        return
      # Returns true if the connection is selected.
      @selected = ->
        @_selected
      @data.connectionAlive = true
      @data.connectionNotBlocked = true
      @connectionAlive = ->
        @data.connectionAlive
      @connectionNotBlocked = ->
        @data.connectionNotBlocked
      return
    # Helper function.
    computeConnectionTangentOffset = (pt1, pt2) ->
      (pt2.x - pt1.x) / 2
    # Compute the tangent for the bezier curve.
    flowchart.computeConnectionSourceTangentX = (pt1, pt2) ->
      pt1.x + computeConnectionTangentOffset(pt1, pt2)
    # Compute the tangent for the bezier curve.
    flowchart.computeConnectionSourceTangentY = (pt1, pt2) ->
      pt1.y
    # Compute the tangent for the bezier curve.
    flowchart.computeConnectionSourceTangent = (pt1, pt2) ->
      x: flowchart.computeConnectionSourceTangentX(pt1, pt2)
      y: flowchart.computeConnectionSourceTangentY(pt1, pt2)
    # Compute the tangent for the bezier curve.
    flowchart.computeConnectionDestTangentX = (pt1, pt2) ->
      pt2.x - computeConnectionTangentOffset(pt1, pt2)
    # Compute the tangent for the bezier curve.
    flowchart.computeConnectionDestTangentY = (pt1, pt2) ->
      pt2.y
    # Compute the tangent for the bezier curve.
    flowchart.computeConnectionDestTangent = (pt1, pt2) ->
      x: flowchart.computeConnectionDestTangentX(pt1, pt2)
      y: flowchart.computeConnectionDestTangentY(pt1, pt2)
    # View model for the chart.
    flowchart.ChartViewModel = (chartDataModel) ->
      @width = flowchart.width
      @height = flowchart.height
      # Find a specific node within the chart.
      @findNode = (nodeID) ->
        i = 0
        while i < @nodes.length
          node = @nodes[i]
          return node if node.data.id is nodeID
          ++i
        throw new Error("Failed to find node " + nodeID)
        return false
      # Find a specific connector within the chart.
      @findConnector = (nodeID, connectorIndex) ->
        node = @findNode(nodeID)
        i = 0
        while i < node.inputConnectors.length
          nin = node.inputConnectors[i]
          if nin.data.name is connectorIndex
            n = nin
            i = node.inputConnectors.length
          else
            i++
        j = 0
        while j < node.outputConnectors.length
          nout = node.outputConnectors[j]
          if nout.data.name is connectorIndex
            n = nout
            j = node.outputConnectors.length
          else
            j++
        n
      # Find a specific node within the chart by ip.
      @findNodeByIP = (nodeIP) ->
        i = 0
        while i < @nodes.length
          node = @nodes[i]
          return node if node.data.ip is nodeIP
          ++i
        return false
      # Create a view model for connection from the data model.
      @_createConnectionViewModel = (connectionDataModel) ->
        sourceConnector = @findConnector(connectionDataModel.source.nodeID, connectionDataModel.sourceport)
        destConnector = @findConnector(connectionDataModel.dest.nodeID, connectionDataModel.targetport)
        new flowchart.ConnectionViewModel(connectionDataModel, sourceConnector, destConnector)
      # Wrap the connections data-model in a view-model.
      @_createConnectionsViewModel = (connectionsDataModel) ->
        connectionsViewModel = []
        if connectionsDataModel
          i = 0
          while i < connectionsDataModel.length
            connectionsViewModel.push @_createConnectionViewModel(connectionsDataModel[i])
            ++i
        connectionsViewModel
      # Reference to the underlying data.
      @data = chartDataModel
      # Create a view-model for nodes.
      @nodes = createNodesViewModel(@data.nodes)
      # Create a view-model for connections.
      @connections = @_createConnectionsViewModel(@data.connections)
      # Create a view model for a new connection.
      @createNewConnection = (sourceConnector, destConnector) ->
        debug.assertObjectValid sourceConnector
        debug.assertObjectValid destConnector
        connectionsDataModel = @data.connections
        connectionsDataModel = @data.connections = []  unless connectionsDataModel
        connectionsViewModel = @connections
        connectionsViewModel = @connections = []  unless connectionsViewModel
        sourceNode = sourceConnector.parentNode()
        sourceConnectorIndex = sourceNode.outputConnectors.indexOf(sourceConnector)
        if sourceConnectorIndex is -1
          sourceConnectorIndex = sourceNode.inputConnectors.indexOf(sourceConnector)
          throw new Error("Failed to find source connector within either inputConnectors or outputConnectors of source node.")  if sourceConnectorIndex is -1
        destNode = destConnector.parentNode()
        destConnectorIndex = destNode.inputConnectors.indexOf(destConnector)
        if destConnectorIndex is -1
          destConnectorIndex = destNode.outputConnectors.indexOf(destConnector)
          throw new Error("Failed to find dest connector within inputConnectors or ouputConnectors of dest node.")  if destConnectorIndex is -1
        connectionDataModel =
          source:
            nodeID: sourceNode.data.id
            connectorIndex: sourceConnectorIndex
          dest:
            nodeID: destNode.data.id
            connectorIndex: destConnectorIndex
        connectionsDataModel.push connectionDataModel
        connectionViewModel = new flowchart.ConnectionViewModel(connectionDataModel, sourceConnector, destConnector)
        connectionsViewModel.push connectionViewModel
        return
      # Add a node to the view model.
      @addNode = (nodeDataModel) ->
        @data.nodes = []  unless @data.nodes
        # Update the data model.
        @data.nodes.push nodeDataModel
        # Update the view model.
        @nodes.push new flowchart.NodeViewModel(nodeDataModel)
        return
      # Select all nodes and connections in the chart.
      @selectAll = ->
        nodes = @nodes
        i = 0
        while i < nodes.length
          node = nodes[i]
          node.select()
          ++i
        connections = @connections
        i = 0
        while i < connections.length
          connection = connections[i]
          connection.select()
          ++i
        return
      # Deselect all nodes and connections in the chart.
      @deselectAll = ->
        nodes = @nodes
        i = 0
        while i < nodes.length
          node = nodes[i]
          node.deselect()
          ++i
        connections = @connections
        i = 0
        while i < connections.length
          connection = connections[i]
          connection.deselect()
          ++i
        return
      # Update the location of the node and its connectors.
      @updateSelectedNodesLocation = (deltaX, deltaY) ->
        selectedNodes = @getSelectedNodes()
        i = 0
        while i < selectedNodes.length
          node = selectedNodes[i]
          node.data.x += deltaX
          node.data.y += deltaY
          ++i
        return
      # Handle mouse click on a particular node.
      @handleNodeClicked = (node, evt) ->
        if evt
          node.toggleSelected()
        else
          @deselectAll()
          node.select()
        # Move node to the end of the list so it is rendered after all the other.
        # This is the way Z-order is done in SVG.
        nodeIndex = @nodes.indexOf(node)
        throw new Error("Failed to find node in view model!")  if nodeIndex is -1
        @nodes.splice nodeIndex, 1
        @nodes.push node
        return
      # Handle mouse down on a connection.
      @handleConnectionMouseDown = (connection, ctrlKey) ->
        if ctrlKey
          connection.toggleSelected()
        else
          @deselectAll()
          connection.select()
        return
      # Delete all nodes and connections that are selected.
      @deleteSelected = ->
        newNodeViewModels = []
        newNodeDataModels = []
        deletedNodeIds = []
        # Sort nodes into:
        #		nodes to keep and
        #		nodes to delete.
        nodeIndex = 0
        while nodeIndex < @nodes.length
          node = @nodes[nodeIndex]
          unless node.selected()
            # Only retain non-selected nodes.
            newNodeViewModels.push node
            newNodeDataModels.push node.data
          else
            # Keep track of nodes that were deleted, so their connections can also
            # be deleted.
            deletedNodeIds.push node.data.id
          ++nodeIndex
        newConnectionViewModels = []
        newConnectionDataModels = []
        # Remove connections that are selected.
        # Also remove connections for nodes that have been deleted.
        connectionIndex = 0
        while connectionIndex < @connections.length
          connection = @connections[connectionIndex]
          if not connection.selected() and deletedNodeIds.indexOf(connection.data.source.nodeID) is -1 and deletedNodeIds.indexOf(connection.data.dest.nodeID) is -1
            # The nodes this connection is attached to, where not deleted,
            # so keep the connection.
            newConnectionViewModels.push connection
            newConnectionDataModels.push connection.data
          ++connectionIndex
        # Update nodes and connections.
        @nodes = newNodeViewModels
        @data.nodes = newNodeDataModels
        @connections = newConnectionViewModels
        @data.connections = newConnectionDataModels
        return
      @updateNodeQuantity = () ->
        oldnodeid = (node.data.id for node in @nodes)
        newnodeid = (node.id for node in @data.nodes)
        diff = (i for i in oldnodeid when newnodeid.indexOf(i) is -1)
        newConnectionViewModels = []
        newConnectionDataModels = []
        connectionIndex = 0
        while connectionIndex < @connections.length
          connection = @connections[connectionIndex]
          if diff.indexOf(connection.data.source.nodeID) is -1 and diff.indexOf(connection.data.dest.nodeID) is -1
            newConnectionViewModels.push connection
            newConnectionDataModels.push connection.data
          ++connectionIndex
        @connections = newConnectionViewModels
        @data.connections = newConnectionDataModels
        @nodes = createNodesViewModel(@data.nodes)
      # Select nodes and connections that fall within the selection rect.
      @applySelectionRect = (selectionRect) ->
        @deselectAll()
        i = 0
        while i < @nodes.length
          node = @nodes[i]
          # Select nodes that are within the selection rect.
          node.select() if node.x() >= selectionRect.x and node.y() >= selectionRect.y and node.x() + node.width() <= selectionRect.x + selectionRect.width and node.y() + node.height() <= selectionRect.y + selectionRect.height
          ++i
        i = 0
        while i < @connections.length
          connection = @connections[i]
          # Select the connection if both its parent nodes are selected.
          connection.select()  if connection.source.parentNode().selected() and connection.dest.parentNode().selected()
          ++i
        return

      # Get the array of nodes that are currently selected.
      @getSelectedNodes = ->
        selectedNodes = []
        i = 0
        while i < @nodes.length
          node = @nodes[i]
          selectedNodes.push node  if node.selected()
          ++i
        selectedNodes

      # Get the array of connections that are currently selected.
      @getSelectedConnections = ->
        selectedConnections = []
        i = 0
        while i < @connections.length
          connection = @connections[i]
          selectedConnections.push connection  if connection.selected()
          ++i
        selectedConnections
      return
    return
  ])