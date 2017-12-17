html ->
	head ->
		title 'IntraView'
		link href:'lib/bootstrap-3.1.1.min.css', rel:'stylesheet', type:'text/css'
		link href:'lib/angular-motion.min.css', rel:'stylesheet', type:'text/css'
		link href:'timeline/timeline.css', rel:'stylesheet', type:'text/css'
		link href:'editor.css', rel:'stylesheet', type:'text/css'
	body 'ng-app':'app', 'ng-controller':'AppCtrl', 'ng-keydown':'keyDown($event)', 'ng-keyup':'keyUp($event)', 'ng-right-click':' ', ->
    div style:'width: 100%', ->
      div ->
        div '.btn-group', ->
          button 'btn.btn-default.btn-xs', ng_click:'addNewNode()', 'title':'Add a new node to the chart', ->
            'Add Node'
          button '.btn.btn-default.btn-xs', ng_click:'addNewInputConnector()', ng_disabled:'chartViewModel.getSelectedNodes().length == 0', title:'Add a new input connector to the selected node', ->
            'Add Input Connector'
          button '.btn.btn-default.btn-xs', ng_click:'addNewOutputConnector()', ng_disabled:'chartViewModel.getSelectedNodes().length == 0', title:'Add a new output connector to the selected node', ->
            'Add Output Connector'
          button '.btn.btn-default.btn-xs', ng_click:'deleteSelected()', ng_disabled:'chartViewModel.getSelectedNodes().length == 0 && chartViewModel.getSelectedConnections().length == 0', title:'Delete selected nodes and connections', ->
            'Delete Selected'
          button '.btn.btn-default.btn-xs', ng_click:'print()', ->
            'print'
        # This custom element defines the flowchart.
        ul '.nodelist', ->
          li ng_repeat:'node in chartViewModel.nodes track by $index', ng_mousedown:'nodelistMouseDown($event, node)', ->
            input '.btn.btn-default.btn-xs.nodelistbtn', type:'button', value:'{{node.data.name}}'
        ul '.testbtns', ->
          li ->
            input '.btn.btn-default.btn-xs', type:'button', value:'random_connectiondown', ng_click:'random_connectiondown()'
          li ->
            input '.btn.btn-default.btn-xs', type:'button', value:'random_connectionblock', ng_click:'random_connectionblock()'
          li ->
            input '.btn.btn-default.btn-xs', type:'button', value:'random_node_warning', ng_click:'random_nodewarn()'
          li ->
            input '.btn.btn-default.btn-xs', type:'button', value:'random_nodedown', ng_click:'random_nodedown()'
          li ->
            input '.btn.btn-default.btn-xs', type:'button', value:'random_portdown', ng_click:'random_portdown()'
        div 'mouse-capture':' ', ->
          tag 'flow-chart', chart:'chartViewModel', ->
          tag 'timeline', chart:'chartViewModel', ->
    # Library code
    script src:'lib/jquery-2.1.0.min.js', type:'text/javascript'
    script src:'lib/angular-1.2.16.min.js', type:'text/javascript'
    script src:'lib/angular-animate-1.2.16.min.js', type:'text/javascript'
    script src:'lib/angular-strap-2.0.2.min.js', type:'text/javascript'
    script src:'lib/angular-strap-2.0.2.tpl.min.js', type:'text/javascript'
    script src:'lib/d3-3.4.6.min.js', type:'text/javascript'
    # Flowchart code
    script src:'flowchart/mouse_capture_service.js', type:'text/javascript'
    script src:'flowchart/drag_service.js', type:'text/javascript'
    script src:'modal/modal_service.js', type:'text/javascript'
    script src:'flowchart/flowchart_datamodel.js', type:'text/javascript'
    script src:'flowchart/flowchart_controller.js', type:'text/javascript'
    # Topology Related
    script src:'flowchart/topo_algorithm_service.js', type:'text/javascript'
    # Timeline
    script src:'lib/timeline.js', type:'text/javascript'
    script src:'timeline/timeline_directive.js', type:'text/javascript'
    # App code
    script src:'app.js', type:'text/javascript'





