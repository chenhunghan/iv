#node webkit
gui = require('nw.gui')
win = gui.Window.get()
#tray = new gui.Tray({ title: 'Test'})
#tray_menu  = new gui.Menu()
#tray_menu.append(new gui.MenuItem({ type: 'checkbox', label: 'box1' }))
#tray.menu = tray_menu
#menubar = new gui.Menu({ type: 'menubar' })
#menubar.append(new gui.MenuItem({ type: 'checkbox', label: '111' }))
process.on "uncaughtException", (err...) ->
  console.log 'node.js error: '
  console.log err
#console.log 'nodewebkit versions: ' + JSON.stringify(process.versions)
#angular module
ngapp = angular.module 'viewerapp', ['rzModule', 'ngAnimate'] #v1.2.2
#mcast listener 
window.mr = require( './mcast')
window.targetmac = ['']
#http server
window.fileserver = require( './static_server')
window.tftp = require( './tftp')
#ng services
#smith agent service
ngapp.service 'smith', ($rootScope, msgbox, effect) ->
  window.agent = []
  window.smith_reconnect = true
  window.targetip = []
  window.agent_start = () ->
    
    create_agent = (ip) ->
      ip = ip
      net = require("net")
      serv_port = 1337
      
      detect_disconnect = (i) ->
        if i.transport is undefined
          return true
        else
          return false
        
      monitor = () ->
        
        socket.on 'timeout', () ->
          msg = 'connection with ' + ip + ' is timeout..'
          msgbox.msgbar_show msg, 'error'
          
        socket.on 'error', (e) ->
          console.log e
          setTimeout (->
            reconnect()
            ff
          ), 2000
          
        socket.on 'connect', () ->
          
          socket.setTimeout 0
          
          Agent = require('smith').Agent
          ag = new Agent()
          
          ag.connect socket, (err, apis) ->
            if err?
              return
         
          ag.on 'connect', () ->
            window.agent =  _.reject(window.agent, detect_disconnect)
            test_exist = (i) ->
              if i.transport.input.remoteAddress is ag.transport.input.remoteAddress
                return false
              else
                return true
            if _.every(window.agent, test_exist) is true
              window.agent.push ag
              msgbox.msgbar_show( 'sucessfully connected to ' + ip, 'info')
              if $rootScope.config is undefined
                $rootScope.config = 'network'
                $rootScope.$apply()
              if window.agent.length != 0
                $rootScope.smith_not_connected = false
                $rootScope.$apply()
                
          ag.on 'disconnect', (err) ->
            if err isnt 'by manaul'
              msgbox.msgbar_show( 'temporary disconnect with ' + ip + ' automatocally reconnect in 3 secs..', 'error')
              window.agent =  _.reject(window.agent, detect_disconnect)
              setTimeout (->
                reconnect()
              ), 3000
     
      socket = net.connect serv_port, ip
      socket.setTimeout 12000
      monitor()
      msgbox.msgbar_show( 'trying to establish connection with ' + ip, 'info')

      reconnect = () ->
        if window.smith_reconnect is true
          socket = net.connect serv_port, ip
          socket.setTimeout 12000
          msgbox.msgbar_show 'trying to reconnect with ' + ip, 'info'
          monitor()
    for ip in window.targetip
      do (ip) ->
        create_agent(ip)
  
  emit: (a...) ->
    api = a[0]
    msg = a[1]
    detect_disconnect = (i) ->
      if i.transport is undefined
        return true
      else
        return false
    send_set = () ->
      applying_status = (ipip, cls) ->
        switch cls
          when 'apply_success'
            d3.select('.lstext' + '.' + ipip).classed 'apply_fail', false
            d3.select('.lstext' + '.' + ipip).classed 'same', false
            d3.select('.lstext' + '.' + ipip).classed 'host', false
            d3.select('.lstext' + '.' + ipip).classed 'diff', false
            
            d3.select('.lstext' + '.' + ipip).classed 'same', true
          when 'apply_fail'
            d3.select('.lstext' + '.' + ipip).classed 'apply_fail', false
            d3.select('.lstext' + '.' + ipip).classed 'same', false
            d3.select('.lstext' + '.' + ipip).classed 'host', false
            d3.select('.lstext' + '.' + ipip).classed 'diff', false
            
            d3.select('.lstext' + '.' + ipip).classed 'apply_fail', true
      for agent in window.agent
        do (agent) ->
          d3.selectAll('.lstext_active').classed 'apply_fail', false
          d3.selectAll('.lstext_active').classed 'apply_fail', true
          if agent.transport isnt undefined
            ip = agent.transport.input.remoteAddress
            ipip = 'IP' + ip.replace(/\./g, '')
            info = 'applying configuration to devices... Please wait...'
            msgbox.msgbar_show( info, 'info')
            cb = () ->
              if arguments.length is 0 or arguments[0] is true
                msg = 'apply configuration to ' + ip + ' without errors'
                msgbox.msgbar_show( msg, 'success')
                applying_status ipip, 'apply_success'
              else
                if arguments[0].code?
                  msgbox.msgbar_show( 'failed to config. Error code: ' + arguments[0].code, 'error')
                  #window.agent = _.reject(window.agent, detect_disconnect)
            a.push cb
            agent.send a
            console.log a
            #console.log cb
            a.pop()
            console.log a
          else
            msg = 'Lost connection. Applying configurations is failed. Please check your connection and apply again.'
            msgbox.msgbar_show( msg, 'error')
            #window.agent = _.reject(window.agent, detect_disconnect)
    send_get = () ->
      for agent in window.agent
        do (agent) ->
          if agent.transport?
            agent.send a
            #console.log a
          else
            return
            #window.agent = _.reject(window.agent, detect_disconnect)
    if msg isnt undefined and api isnt undefined
      if api.match(/get/g) isnt null
        send_get()
        console.log 'smith emit get msg...'
        #console.log a
      else
        if api.match(/set/g) isnt null
          send_set()
          console.log 'smith emit set msg...'
          #console.log a
        else
          console.log 'other api'
          send_get()
    else
      if api is 'system::all_save_cfg'
        send_set()
      else
        console.log api
        console.log msg
        msgbox.msgbar_show('value invalid, please check your input value', 'error') 
#data compare service
ngapp.service 'compare', ($rootScope, msgbox) ->
  window.config_data = {}
  init: () ->
    msgbox.msgbar_show( 'trying to get data from selected devices... please wait', 'info')
    $rootScope.smith_not_connected = true
  pushdata: (agent, api, cfg) ->
    if cfg isnt undefined and agent.transport?
      msgbox.msgbar_show( 'received data from devices', 'info')
      $rootScope.smith_not_connected = false
      $rootScope.$apply()
      ip = agent.transport.input.remoteAddress
      apivalue = {}
      apivalue[api] = $.extend apivalue[api], cfg
      window.config_data[ip] = $.extend window.config_data[ip], apivalue
    else
      return  
  compare: (agent, api) ->
    if agent.transport?
      n = _.keys(window.config_data)
      if n.length > 1
        refer = agent.transport.input.remoteAddress
        referobj = window.config_data[refer]
        referdata = referobj[api]
        host = 'IP' + refer.replace(/\./g, '')
        for ip, data of window.config_data
          do (ip, data) ->
            if ip isnt refer
              other = 'IP' + ip.replace(/\./g, '')
              if angular.equals(data[api], referdata) is true
                d3.select('.lstext' + '.' + other).classed 'apply_fail', false
                d3.select('.lstext' + '.' + other).classed 'same', false
                d3.select('.lstext' + '.' + other).classed 'host', false
                d3.select('.lstext' + '.' + other).classed 'diff', false
                
                d3.select('.lstext' + '.' + other).classed 'same', true
                
                d3.select('.lstext' + '.' + host).classed 'apply_fail', false
                d3.select('.lstext' + '.' + host).classed 'host', false
                d3.select('.lstext' + '.' + host).classed 'same', false
                d3.select('.lstext' + '.' + host).classed 'diff', false
                
                d3.select('.lstext' + '.' + host).classed 'host', true
              if angular.equals(data[api], referdata) is false
                d3.select('.lstext' + '.' + other).classed 'apply_fail', false
                d3.select('.lstext' + '.' + other).classed 'same', false
                d3.select('.lstext' + '.' + other).classed 'host', false
                d3.select('.lstext' + '.' + other).classed 'diff', false
                
                d3.select('.lstext' + '.' + other).classed 'diff', true
                
                d3.select('.lstext' + '.' + host).classed 'apply_fail', false
                d3.select('.lstext' + '.' + host).classed 'host', false
                d3.select('.lstext' + '.' + host).classed 'same', false
                d3.select('.lstext' + '.' + host).classed 'diff', false
                
                d3.select('.lstext' + '.' + host).classed 'host', true
    else
      return
#effect
ngapp.service 'effect', ($rootScope) ->
  animated: (element_id, animation_name) ->
    $(element_id).addClass("animated " + animation_name)
    $(element_id).on "webkitAnimationEnd", ->
      $(element_id).removeClass("animated " + animation_name)
  show_spinner: (arg...) -> 
    $rootScope.content = arg[0]
    $rootScope.duration = arg[1]
    $rootScope.show_global_loading = true
    switch $rootScope.content
      when 'Applying'
        d3.select('.spinning_msg')
      when 'Scanning'
        d3.select('.spinning_msg')
      else
        d3.select('.spinning_msg').text
    if $rootScope.duration? and $rootScope.duration>0
      $timeout (->
        $rootScope.show_global_loading = false
      ),$rootScope.duration
  hide_spinner: () ->
    $rootScope.show_global_loading = false
#drawing topology
ngapp.service 'topo', ($rootScope, $q, msgbox, effect) ->   
  showd3: (arg...) ->
    #arguments
    raw = arg[0]
    mode = arg[1]
    starting_point = arg[2]
    currview = arg[3]
    #reset before initialize ( this is necessary because d3.js' s exit.remove() does not work properly on svg+div graph.)
    d3.select('#panel').style('opacity', 0)
    d3.select('#panelsvg').remove()
    d3.select('#panelselectionwrap').remove()
    d3.select('#panel').append('div').attr('id', 'panelselectionwrap')
    d3.select('#panelselectionwrap').append('svg').attr('id', 'panelsvg')
    d3.selectAll('.lsslct').remove()
    d3.selectAll('.lslink').remove()
    d3.selectAll('.ip_list').remove()
    d3.selectAll('.iplslink').remove()
    d3.select('#ip_panel').remove()
    d3.selectAll('.link').remove()
    d3.selectAll('.node').remove()
    d3.selectAll(".nodetext").remove()
    d3.select('.inhibit').remove()
    #tooltip
    tooltip = CustomTooltip("details_tooltip", 400) #the max-width of tooltip 
    tooltip.hideTooltip()
    show_details = (dh)->
      content = ''
      for title,value of dh
        content +="<span class=\"name\">#{title}:</span><span class=\"value\"> #{value}</span><br/>"
      tooltip.showTooltip(content,d3.event)
    hide_details = ->
      tooltip.hideTooltip()
    #basic setting on topology
    width = 1900
    height = 1200
    panelpostop = parseFloat $('#panel').css('top')
    panelposleft = parseFloat $('#panel').css('left')
    svg_pos_top = parseFloat $('#graph').css('top')
    svg_pos_left = parseFloat $('#graph').css('left')
    ls_line_height = 20 #safe range = 20-35
    lsnoder = (ls_line_height)/5
    lsnode_padding_top = (ls_line_height)/2 + lsnoder
    lsnode_padding_left = (ls_line_height)/2 - lsnoder - 1 # 1 is #panel-border-width
    lsnodestokewidth = 1  
    nodes = []
    links = []
    #svg initializes
    svg = d3.select('#toposvg').attr("width", width).attr("height", height)
    node = svg.selectAll(".node")
    nodetext = svg.selectAll(".nodetext")
    link = svg.selectAll(".link")
    lslink = svg.selectAll(".lslink")
    iplslink = svg.selectAll(".iplslink")
    #panel initializes
    panel = d3.select("#panel")
    panelsvg = d3.select('#panelsvg')
    lsnode = panelsvg.selectAll(".lsnode")
    lstext = d3.select("#panelselectionwrap").selectAll(".lstext")
    lsslct = d3.select("#panel").selectAll(".lsslct")
    font_size = 10
    #data initializes
    for k,v of raw.nodes #reset node pos on startup (useless if there are too many nodes!)
      nodes.push v
    ###
    for i in nodes
      i.x = 0
      i.y = 50000
    ###
    if raw.links?
      for lkdata in raw.links
        lidx = lkdata.nodepair
        links.push
          source: nodes[ lkdata.nodepair[0]]
          target: nodes[ lkdata.nodepair[1]]
          ports: lkdata.portpair
          blocked: lkdata.blocked
          rings: lkdata.rings
    ringid_class_idx = {}
    build_rclassmap = (rings)->
      i=1
      for id, ring of rings
        ringid_class_idx[id]=i
        i+=1
    build_rclassmap( raw.rings)
    #force initilize
    force = d3.layout.force().nodes(nodes).links(links)
      .charge(-1800)
      .linkDistance(80)
      .size([width, height])
      .gravity(0.1)
      .on 'tick', ->
        node.attr
          transform: (d)->
            "translate(" + d.x + "," + d.y + ")"
        nodetext.attr
          transform: (d)->
            "translate(" + (d.x + -20) + "," + (d.y - 25) + ")"
        link.attr "d", (d) ->
          #qx = 400
          #qy = 400
          #distance = 10
          #qx = (d.source.x + d.target.x)/2 + distance * (d.target.y - d.source.y) / ((d.target.x - d.source.x)^2 + (d.target.y - d.source.y)^2)^0.5
          #qy = (d.source.y + d.target.y)/2 + distance * (d.target.x - d.source.x) / ((d.target.x - d.source.x)^2 + (d.target.y - d.source.y)^2)^0.5
          #"M"+ d.source.x + "," + d.source.y + " " + "Q" + qx + "," + qy + " " + d.target.x + "," + d.target.y
          "M" + d.source.x + "," + d.source.y + " " + "L" + d.target.x + "," + d.target.y
        lslink.attr
          d: (d, i) ->
            "M" + ( panelposleft + lsnoder + lsnodestokewidth + lsnode_padding_left - svg_pos_left) + "," + ( i*ls_line_height + panelpostop + lsnoder - lsnodestokewidth + lsnode_padding_top - svg_pos_top) + " " + "L"+ d.x + "," + d.y
        iplslink.attr 
          d: (d, i) ->
            "M" + ( -298 + panelposleft + lsnoder + lsnodestokewidth + lsnode_padding_left - svg_pos_left) + "," + ( i*ls_line_height + panelpostop + lsnoder - lsnodestokewidth + lsnode_padding_top - svg_pos_top) + " " + "L"+ d.x + "," + d.y         
    #topology controller
    #zoom controller
    zoom = d3.select("#zoom").on "change", () ->
      p = $("#zoom").val()
      d3.selectAll(".node").attr("r", p/5+6).style
        'stroke-width': p/60 + 1
      d3.selectAll('.nodetext').style("font-size", p/10 + 3 + 'px')
      force.linkDistance(p*6 - 150).gravity(Math.abs(Math.log(p/100)/2)).start()
    #testing code
    ###
    #force toggle
    force_toggle = d3.select("#f-toggle").on "change", () ->
      if(@.checked)
        force.start()
      else
        force.stop()
    #save pos of nodes
    snx = []
    sny = []
    save_pos = d3.select('#save').on "click", () ->
      snx.length = 0
      snx.length = 0
      for i, index in nodes
        snx.push(i.x)
        sny.push(i.y)
    #verify saved pos
    d3.select('#verify').on "click", () ->
      console.log nodes
      console.log links
    #restore pos of nodes
    restore_pos = d3.select('#restore').on "click", () ->
      for j, index in nodes
        j.x = snx[index]
        j.y = sny[index]
      start()
    #remove a link
    remove_link = d3.select('#remove-l').on "click", () ->
      links.pop()
      start()
    #remove a node
    remove_node = d3.select('#remove-n').on "click", () ->
      nodes.pop()
      start()
    #add a node
    add_node = d3.select('#add-n').on "click", () ->
      a =
        name: 'switch' + Math.ceil(Math.random()*(200-1)+1)
        location: 'fab' + Math.ceil(Math.random()*(10-1)+1)
        ip: '192.168.' + Math.ceil(Math.random()*(255-1)+1) + '.' + Math.ceil(Math.random()*(255-1)+1)
        mac: 'mac' + Math.ceil(Math.random()*(25555-1)+1)
      nodes.push a
      start()
    ###
    start = () ->
      choose_ring = ( rings) ->
        return ring for ring in rings when ring.role is 'owner'
        return ring for ring in rings when ring.type is 'major'
        thering = rings[0]
        thering = ring for ring in rings when thering.id > ring.id
        thering
      
      adding_start = () ->

      
        #append lstext ( nodes' text in the panel selection list)
        lstext = lstext.data force.nodes()
        lstext.exit().remove()
        padding = () ->
          if nodes.length * ls_line_height > 350 then (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/4)
          else (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/2)
        lstext.enter().insert('span').attr
          class: (d) ->
            clses = ['lstext']
            dmac = 'MAC' + d.mac
            mac = dmac.replace(/:/g, '')
            clses.push mac
            a = clses.join(' ')
        .text (d) ->
          d.mac.toUpperCase()
        .style
          'height': ls_line_height + 'px'
          'font-size': font_size + 'px'
          'line-height': font_size + 'px'
          'padding-top': padding() + 'px'

        #append lsnode ( nodes in the panel selection list)
        lsnode = lsnode.data force.nodes() #list of nodes that can be selected
        lsnode.enter().append('circle').attr
          transform: (d, i) ->
            "translate(" + (lsnoder + lsnodestokewidth + lsnode_padding_left) + "," + (-2 + i*ls_line_height + lsnoder + lsnodestokewidth + lsnode_padding_top) + ")"
          class: (d)->
            clses = ['lsnode'] 
            dmac = 'MAC' + d.mac
            mac = dmac.replace(/:/g, '')
            clses.push mac #give each node name based on it's 'mac' property
            if currview == 'ring' and d.rings? and d.rings.length > 0
              ring = choose_ring d.rings
              clsidx = ringid_class_idx[ring.id]
              clses.push 'ring_color' + clsidx
              if ring.role == 'neighbour'
                clses.push 'lsdashed'
              if ring.role == 'owner'
                clses.push 'ring_owner_color' + clsidx
            if currview == 'phy'
              clses.push 'phymode' 
            clses.push 'othernode' if not d.rings?
            b = clses.join(' ')
          r: lsnoder
        .style('stroke-width', lsnodestokewidth)
        lsnode.exit().remove()
        
        #lsslct for data storage
        lsslct = lsslct.data force.nodes()
        lsslct.enter().append('input').property('checked', false).attr
          type: "checkbox"
          class: (d) ->
            clses = ['lsslct']
            dmac = 'MAC' + d.mac
            mac = dmac.replace(/:/g, '')
            clses.push mac
            a = clses.join(' ')
        lsslct.exit().remove()
        
        #append lslilink ( the likage between lsnodes and main svg nodes)
        lslink = lslink.data force.nodes()
        lslink.enter().insert("path").attr
          class: (d) ->
            clses = ['lslink']
            dmac = 'MAC' + d.mac
            mac = dmac.replace(/:/g, '')
            clses.push mac
            a = clses.join(' ')
        lslink.exit().remove()
        
        #append lp-lslink ( the likage between ip panel and main svg nodes)
        iplslink = iplslink.data force.nodes()
        iplslink.enter().insert("path").attr
          class: (d) ->
            clses = ['iplslink']
            dmac = 'MAC' + d.mac
            mac = dmac.replace(/:/g, '')
            clses.push mac
            a = clses.join(' ')
        iplslink.exit().remove()
        
        #append link ( the linkage between nodes in the main svg)
        link = link.data force.links()
        link.enter().insert("path").attr
          class: (d) ->
            clses = ['link']
            if currview == 'ring' and d.rings? and d.rings.length>0
              ring = choose_ring(d.rings)
              clsidx = ringid_class_idx[ring.id]
              #decide color
              clses.push  'ring_color'+clsidx
            if currview == 'phy'
              clses.push 'phymode' 
            clses.push 'dashed' if d.blocked
            if d.source? then clses.push d.source.location.slice(3)
            a = clses.join(' ')
        link.on
          mouseover:  (d,i) ->
            d3.select( d3.event.target).classed 'ln-hover', true
            show_details
              From: "#{d.source.mac} -- Port #{d.ports[0]}"
              To: "#{d.target.mac} -- Port #{d.ports[1]}"
          mouseout: (d,i)->
            d3.select( d3.event.target).classed 'ln-hover', false
            hide_details d, i, this
        link.exit().remove()
        
        #append node ( the nodes in the main svg)
        node = node.data force.nodes()
        node.enter().append('circle').on
          mouseover:  (d, i) ->
            d3.select( d3.event.target ).classed 'nd-hover', true
            sd = { Name: d.name, Location: d.location + "(#{i})", MAC: d.mac, IP: d.ip }
            if d.rings? and d.rings.length > 0
              if d.rings.length > 1
                for ring,i in d.rings
                  sd["Ring#{i}"] = "as #{ring.role} of #{ring.type} Ring #{ring.id}"
              else
                ring = d.rings[0]
                sd["Ring"] = "as #{ring.role} of #{ring.type} Ring #{ring.id}"
            show_details sd  
          mouseout: (d, i) ->
            d3.select( d3.event.target).classed 'nd-hover', false
            hide_details d, i, this
          mouseup: (d, i) ->
            node_selecter(d, i, transition_speed, true, 'single_mode')
        .attr
          class: (d)->
            clses = ['node']
            dmac = 'MAC' + d.mac
            mac = dmac.replace(/:/g, '')
            clses.push mac
            if currview == 'ring' and d.rings? and d.rings.length > 0
              ring = choose_ring d.rings
              clsidx = ringid_class_idx[ring.id]
              #decide color
              clses.push 'ring_color' + clsidx
              #decide stroke
              if ring.role == 'neighbour'
                clses.push 'dashed'
              #decide fill
              if ring.role == 'owner'
                clses.push 'ring_owner_color' + clsidx
            if currview == 'phy'
              clses.push 'phymode'
            clses.push 'othernode' if not d.rings?
            a = clses.join(' ')
          r:'15'
        .call(force.drag)
        node.exit().remove()
        
        #append node text ( the nodes' text in the main svg )
        nodetext = nodetext.data force.nodes()
        nodetext.enter().append('text').on
          mouseover:  (d, i) ->
            d3.select( d3.event.target ).classed 'nodetext-hover', true
          mouseout: (d) ->
            d3.select( d3.event.target).classed 'nodetext-hover', false
        .text((d)-> d.name )
        .attr( 'text-anchor', 'middle')
        .attr
          class: (d) ->
            clses = ['nodetext']
            dmac = 'MAC' + d.mac
            mac = dmac.replace(/:/g, '')
            clses.push mac
            a = clses.join(' ')
        .call(force.drag)
        nodetext.exit().remove()
        try
          force.start()
        catch e
          console.log e
      #setsize() : reset ls_line_height depends on reevaluate?
      set_element_size = () -> 
        ls_line_height = Math.min((1/Math.log(nodes.length)) * 80, 40) #max = 40
        lsnoder = (ls_line_height)/5
        lsnode_padding_top = (ls_line_height)/2 - lsnoder
        lsnode_padding_left = (ls_line_height)/2 - lsnoder - 1
        font_size = Math.min(Math.max((ls_line_height/2.428), 10), 13) #(font size = 9-12)
        setpanel_size()
      #setpanel_size() : set panel and panelsvg size when panel initializing 
      setpanel_size = ->
        if nodes.length * ls_line_height > 350
          panel.transition().style
            opacity: 1
            height: '350px'
          .duration(20)
          lsnoder = (ls_line_height)/5
          panelsvg.transition().attr("width", (ls_line_height)/5*4).attr('height', nodes.length * ls_line_height).duration(100)
          d3.select("#panelselectionwrap").style
            'overflow-y': 'scroll'
        else
          panel.transition().style
            opacity: 1
            height: (nodes.length * ls_line_height) + 'px'
          .duration(20)
          panelsvg.transition().attr("width", (ls_line_height)/5*4).attr('height', nodes.length * ls_line_height).duration(100)
        adding_start()
      set_element_size()
    start()
    
    #selection panel
    transition_speed = 30
    all_topology_status = (toggle) ->
      d3.selectAll('.node').classed 'node_active', toggle
      d3.selectAll('.lsnode').classed 'lsnode_active', toggle
      if nodes.length * ls_line_height < 350 then d3.selectAll('.lslink').classed 'lslink_active', toggle
      d3.selectAll('.lstext').classed 'lstext_active', toggle
      d3.selectAll('.lsslct').property 'checked', toggle

    set_button_status = (toggle) ->
      if toggle is off then $('#set').css('background-color', 'rgba(41,95,176,0.2)')
      if toggle is on then $('#set').css('background-color', 'rgba(41,95,176,0.7)')
    check_slection_data = () ->
      if window.targetip.length is 0 
        set_button_status(off) 
      else 
        set_button_status(on)
        
    node_selecter = (d, i, transition_speed, change_lsslct_status, select_all) ->
      switch select_all
        when true
          for i in nodes
            window.targetip.push i.ip
          if nodes.length * ls_line_height < 350  then d3.selectAll('.lslink').transition().style('stroke-dashoffset',0).duration(transition_speed*60)
          all_topology_status(true)
          check_slection_data()
          console.log window.targetip
        when false
          window.targetip = []
          if nodes.length * ls_line_height < 350 then d3.selectAll('.lslink').transition().style('stroke-dashoffset',30000).duration(transition_speed*8)
          all_topology_status(false)
          check_slection_data()
          console.log window.targetip
        when 'single_mode'
          dmac = 'MAC' + d.mac
          mac = dmac.replace(/:/g, '')
          element = d.ip
          target_status = d3.select('.lsslct' + '.' + mac).property('checked')
          single_topology_status = (toggle) ->
            d3.select('.node' + '.' + mac).classed 'node_active', toggle
            if nodes.length * ls_line_height < 350 then d3.select('.lslink' + '.' + mac).classed 'lslink_active', toggle
            d3.select('.lsnode' + '.' + mac).classed 'lsnode_active', toggle
            d3.select('.lstext' + '.' + mac).classed 'lstext_active', toggle
          #transition effect on elements
          if target_status is true
            if change_lsslct_status is true then d3.select('.lsslct' + '.' + mac).property('checked', false)
            single_topology_status (false)
            if nodes.length * ls_line_height < 350 then d3.select('.lslink' + '.' + mac).transition().style('stroke-dashoffset',30000).duration(transition_speed*8)
            search = window.targetip.indexOf(element)
            window.targetip.splice(search, 1)
            check_slection_data()
            console.log window.targetip
          else
            if change_lsslct_status is true then d3.select('.lsslct' + '.' + mac).property('checked', true)
            single_topology_status (true)
            if nodes.length * ls_line_height < 350 then d3.select('.lslink' + '.' + mac).transition().style('stroke-dashoffset',0).duration(transition_speed*60)
            window.targetip.push element
            check_slection_data()
            console.log window.targetip
    #working flow
    #panel basic settings
    panel_ori_size = 210
    panel_resized = parseFloat $('#noti').css('width')
    #working flows
    init_panel = () ->
      d3.select('#paneltitle').style('width', panel_ori_size + 'px')
      d3.select('#panel').style('width', panel_ori_size + 'px')
      d3.select('#panel_bg').transition().style('opacity', 1).duration(800)
      d3.select('#topocontroller').transition().style('opacity', 1).duration(1200)
    resize_panel = () ->
      d3.select('#panel').style('width', panel_resized + 'px')
    inhibit_panel = () ->
      d3.select('#panel').append('div').attr('class', 'inhibit')
      #d3.select('#panel_controller').transition().style('opacity', 0).duration(200)
      d3.select('#paneltitle').transition().style('opacity', 0).duration(100)
    hide_node = () ->
      d3.selectAll('.node').transition().style('opacity', 0.6).duration(1000)
      d3.selectAll('.nodetext').transition().style('opacity', 0.1).duration(1000)
    hide_link = () ->
      d3.selectAll('.lslink').transition().style('opacity', 0).duration(300)
      d3.selectAll('.link').transition().style('opacity', 0.6).duration(1000)
    hide_and_inhibit_topology = () ->
      d3.select('#graph').append('div').attr('class', 'inhibit')
      d3.select('#graph').transition().style('opacity', 0.8).duration(1000)
    hide_zoom = () ->
      d3.select('#topocontroller').transition().style('opacity', 0).duration(1000)
    add_panel_controller = () ->
      d3.select('#panel').append('div').attr('id', 'panel_controller').style('width', panel_ori_size + 'px')
    remove_panel_controller = () ->
      d3.select('#panel_controller').remove()
    adjust_panel_controller_when_set_ip = () ->
      d3.select('#panel_controller').transition().style
        width: panel_resized + 100 + 'px'
        bottom: -130 + 'px'
        left: -300 + 'px'
      .duration(0)
    adjust_panel_controller = (botoom) ->
      d3.select('#panel_controller').transition().style
          width: panel_resized + 'px'
          bottom: botoom + 'px'
      .duration(200)
      d3.select('#paneltitle').transition().style('width', panel_resized + 'px').duration(1000)
    add_select_btn_group = () ->
      d3.select('#panel_controller')
        .append('a').attr
          id:'set'
          class: 'btn btn-primary'
        .text("Config Mode ")
        .append('i').attr('class','fa fa-cog')
      d3.select('#addall').style 'display', 'inline-block'
      d3.select('#rmall').style 'display', 'none'
      d3.select('#mac_mode').style 'display', 'inline-block'
      d3.select('#ip_mode').style 'display', 'none'
      d3.select('#name_mode').style 'display', 'none'
    remove_select_btn_group = () ->
      d3.select('#rmall').style 'display', 'none'
      d3.select('#addall').style 'display', 'none'
      d3.select('#mac_mode').style 'display', 'none'
      d3.select('#ip_mode').style 'display', 'none'
      d3.select('#name_mode').style 'display', 'none'
      d3.select('#set').remove()
    add_backward_to_selection = () ->
      d3.select('#panel_controller')
        .append('a').attr('id', 'back').attr('class', 'btn btn-danger').text("Device Browsing ")
        .append('i').attr('class','fa fa-code-fork')
    move_panel = () ->
      d3.select('#paneltitle').transition().style
        opacity: 0
      .duration(800)
      d3.select('#panel').transition().style
        width: panel_resized + 'px'
        top: 187 + 'px'
        left:15 + 'px'
      .duration(1000)
      d3.select('#panel_controller').transition().style
        bottom: -82 + 'px'
        width: panel_resized + 'px'
      .duration(1500)
    adjust_panel_button = () ->
    recovery = () ->
      d3.select('#panel').classed 'panel_ready', false
      d3.selectAll('.inhibit').remove()
      d3.select('#panel_controller').remove()
      d3.select('#ip_panel').remove()
      d3.select('#panel').transition().style
        width: panel_ori_size + 'px'
        top:68 + 'px'
        left: 972 + 'px'
        opacity:1
      .duration(500)
      if nodes.length * ls_line_height < 350 then d3.selectAll('.lslink').transition().style('opacity', 1).duration(300)
      d3.select('#graph').transition().style('opacity', 1).duration(1000)
      d3.selectAll('.node').transition().style('opacity', 1).duration(1000)
      d3.selectAll('.link').transition().style('opacity', 1).duration(1000)
      d3.selectAll('.nodetext').transition().style('opacity', 0.35).duration(1000)
      d3.select('#topocontroller').transition().style('opacity', 1).duration(1000)
      d3.select('#panel_controller').transition().style
        opacity:1
        bottom: -124 + 'px'
      .duration(1500)
      d3.select('#paneltitle').transition().style
        opacity: 1
        width: panel_ori_size + 'px'
      .duration(500)
      d3.selectAll('.lstext').classed 'apply_fail', false
      d3.selectAll('.lstext').classed 'same', false
      d3.selectAll('.lstext').classed 'host', false
      d3.selectAll('.lstext').classed 'diff', false
      
      d3.selectAll('.lstext').classed 'lstext_active', false
      d3.selectAll('.lsnode').classed 'lsnode_active', false
      if nodes.length * ls_line_height < 350 then d3.selectAll('.lslink').classed 'lslink_active', false
      d3.selectAll('.node').classed 'node_active', false
      d3.selectAll('.lsslct').property('checked', false)
    add_set_ip_button = () ->
      d3.select('#panel_controller')
        .append('a').attr
          id:'setip'
          class: 'btn btn-primary'
        .text("Set IP ")
        .append('i').attr('class','fa fa-arrow-circle-right')
    remove_set_ip_button = () ->
      d3.select('#setip').remove()
    add_ip_panel = () ->
      ip_panelheight = _.size(force.nodes()) * ls_line_height
      if ip_panelheight > 350
        d3.select('#panel')
          .append('div').attr('id', 'ip_panel').style
            height: '350px'
            opacity: 1
            overflow: 'hidden'
            'overflow-y': 'visible'
        $('#ip_panel').on "scroll", ->
          $('#panelselectionwrap').scrollTop $(this).scrollTop()
          
      else
        d3.select('#panel')
          .append('div').attr('id', 'ip_panel').style
            height: ip_panelheight + 'px'
            opacity: 1
      d3.select('#ip_panel').append('form').attr('id', 'ip_form')
    add_apply_ip_button = () ->
      d3.select('#panel_controller')
        .append('a').attr('id', 'applyip').attr('class', 'btn btn-primary').text("Apply ")
        .append('i').attr('class','fa fa-cloud-upload')
    add_cancel_apply_ip_button = () ->
      d3.select('#panel_controller')
        .append('a').attr('id', 'cancel_applyip').attr('class', 'btn btn-danger').text("Skip ")
        .append('i').attr('class','fa fa-forward')
    remove_apply_ip_button = () ->
      d3.select('#applyip').remove()
    remove_cancel_apply_ip_button = () ->
      d3.select('#cancel_applyip').remove()
    add_ip_panel_items = () ->
      ip_list = d3.select('#ip_form').selectAll('.ip_list')
      ip_list = ip_list.data force.nodes()
      text_padding = (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/2-0.5)
      text_size = font_size
      ip_list.enter().append('div')
        .style 
          'height': ls_line_height + 'px'
        .attr
          class: 'ip_list'
      ip_list.append('span')
        .style
          'font-size': text_size + 'px'
          #'line-height': text_size + 'px'
          'padding-top': text_padding + 'px'
          'float':'left'
        .text (d) ->
          d.name
      ip_list.insert('i', 'span').attr('class', 'fa fa-dot-circle-o').style
        'font-size': text_size + 'px'
        #'line-height': text_size + 'px'
        'padding-top': text_padding + 'px'
        'float':'left'                   
      ip_list.append('i').attr('class', 'fa fa-chevron-right').style
        'font-size': text_size + 'px'
        #'line-height': text_size + 'px'
        'padding-top': text_padding + 'px'
      ip_list.insert('input', 'i.fa.fa-chevron-right').attr
        class: 'ip_input ipv4 required'
        type: 'text'
        value: (d) ->
          if d.ip?
            d.ip
          else
            null
      .style
        'height': ls_line_height*0.8 + 'px'
        'font-size': text_size*0.75 + 'px'
        'padding-top': text_size*0.25 + 'px'
        'padding-left': text_size*0.5 + 'px'
        'margin-top': ls_line_height*0.1 + 'px'
      .on
        mouseenter: (d, i) ->
          mac = 'MAC' + d.mac
          t = mac.replace(/:/g, '')
          d3.select('.node' + '.' + t).classed 'node_active_blue', true
          if nodes.length * ls_line_height < 350 then d3.select('.iplslink' + '.' + t).classed 'iplslink_active_blue', true
          d3.select('.lstext' + '.' + t).classed 'lstext_active', true
          d3.select('.nodetext' + '.' + t).classed 'nodetext-hover', true
        mouseout: (d, i) ->
          mac = 'MAC' + d.mac
          t = mac.replace(/:/g, '')
          d3.select('.node' + '.' + t).classed 'node_active_blue', false
          if nodes.length * ls_line_height < 350 then d3.select('.iplslink' + '.' + t).classed 'iplslink_active_blue', false
          d3.select('.lstext' + '.' + t).classed 'lstext_active', false
          d3.select('.nodetext' + '.' + t).classed 'nodetext-hover', false
      
      ip_list.exit().remove()
    hide_iplslink = () ->
      if nodes.length * ls_line_height < 350
        d3.selectAll('.iplslink').style('opacity', 0)
    show_iplslink = () ->
      if nodes.length * ls_line_height < 350
        d3.selectAll('.iplslink').style('opacity', 1)
    add_validate = () ->       
      $("#ip_form").validate
        errorElement:'img' #  -> not an idea hack to hide default error lable
    add_show_detail_panel = () ->
      ip_panelheight = _.size(force.nodes()) * ls_line_height
      d3.select('#panel')
        .append('div').attr('id', 'show_detail_panel').transition().style
          height: ip_panelheight + 'px'
          opacity: 0.9
        .duration(700)
      d3.select('#show_detail_panel').append('form').attr('id', 'ip_show')
      ip_list = d3.select('#ip_show').selectAll('.ip_list')
      ip_list = ip_list.data force.nodes()
      text_padding = (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/2-0.5)
      text_size = font_size
      ip_list.enter().append('div')
        .style 
          'height': ls_line_height + 'px'
        .attr
          class: 'ip_list'
      ip_list.append('span')
        .style
          'font-size': text_size + 'px'
          'padding-top': text_padding + 'px'
          color: 'rgba(0,0,0,0.1)'
        .text (d) ->
          d.name
      ip_list.insert('i', 'span').attr('class', 'fa fa-dot-circle-o').style
        'font-size': text_size + 'px'
        'padding-top': text_padding + 'px'
        opacity: 0                   
      ip_list.append('i').attr('class', 'fa fa-chevron-right').style
        'font-size': text_size + 'px'
        'padding-top': text_padding + 'px'
      ip_list.insert('span', 'i.fa.fa-chevron-right').attr('class', 'ip_input')
      .text (d) ->
          d.mac
      .style
        'font-size': text_size + 'px'
        color: 'rgba(0,0,0,0.3)'
        'padding-top': text_size + 'px'
        'padding-left': text_size*0.5 + 'px'
        'margin-top': text_padding*0.5 + 'px'
      ip_list.exit().remove()
    switch_between_mac_and_ip = (option) ->
      if option is 'mac'
        lstext = d3.select("#panelselectionwrap").selectAll(".lstext")
        lstext = lstext.data force.nodes()
        lstext.enter()
        lstext.text (d) ->
          d.mac.toUpperCase()
        d3.select('#backto_setip_btn').style('display', 'none')
      if option is 'ip'
        lstext = d3.select("#panelselectionwrap").selectAll(".lstext")
        lstext = lstext.data force.nodes()
        lstext.enter()
        lstext.text (d) ->
          d.ip
        d3.select('#backto_setip_btn').style('display', 'block')
      if option is 'name'
        lstext = d3.select("#panelselectionwrap").selectAll(".lstext")
        lstext = lstext.data force.nodes()
        lstext.enter()
        lstext.text (d) ->
          d.name
        d3.select('#backto_setip_btn').style('display', 'none')
    add_backto_setip_btn = () ->
      d3.select('#backto_setip_btn').style('display', 'block')
      d3.select('#backto_setip_btn').on 'click', () ->
        set_ip()
        d3.select('#backto_setip_btn').style('display', 'none')
        d3.selectAll('.node').classed 'node_active', false
        d3.selectAll('.lsnode').classed 'lsnode_active', false
        if nodes.length * ls_line_height < 350 then d3.selectAll('.lslink').classed 'lslink_active', false
        d3.selectAll('.lstext').classed 'lstext_active', false
        d3.selectAll('.lsslct').property 'checked', false
        window.targetip = []
    hide_backto_setip_btn = () ->
      d3.select('#backto_setip_btn').style('display', 'none')
    hide_footer = () -> 
      d3.select('#menubar').transition().style
        top: 700 + 'px'
        opacity: 0
      .duration(2000)
    bring_back_footer = () -> 
      d3.select('#menubar').transition().style
        top: 565 + 'px'
        opacity: 1
      .duration(300)
    #working flow starting points
    #start setting configs with selections
    monitor_select_btn_group = () ->
      d3.select('#set').on 'click', () ->
        if window.targetip.length is 0
          effect.animated("#set", "shake")
          effect.animated(".lstext", "flash")
          msgbox.msgbar_show('please select a device to config', 'error')
          $rootScope.$apply()
        else
          window.agent_start()
          window.smith_reconnect = true
          effect.show_spinner('Applying')
          deferred = new $q.defer()
          promise = deferred.promise
          promise = promise.then(resize_panel).then(inhibit_panel).then(hide_link).then(hide_node).then(hide_and_inhibit_topology).then(hide_zoom).then(remove_select_btn_group).then(adjust_panel_controller(-89)).then(add_backward_to_selection).then(monitor_backward_to_selection).then(hide_footer).then(hide_backto_setip_btn)
          deferred.resolve()
          retry = 0
          ck = () ->
            retry = retry + 1
            if window.agent.length is window.targetip.length or retry > 8
              console.log window.agent
              console.log window.targetip
              effect.hide_spinner()
              clearInterval window.check_agent
              msgbox.msgbar_show('please select desire configuration to set device', 'instruction')
              deferred = new $q.defer()
              promise = deferred.promise
              promise = promise.then(move_panel).then(adjust_panel_button)
              deferred.resolve()
              $rootScope.showconfigs = true
              $rootScope.$apply()
            else
              msgbox.msgbar_show('Connecting to selected devices. Please wait...', 'info')
          window.check_agent = setInterval ck, 2000 
      d3.select('#addall').on 'click', () ->
        node_selecter null, null, transition_speed, null, true
        d3.select('#addall').style 'display', 'none'
        d3.select('#rmall').style 'display', 'inline-block'
      d3.select('#rmall').on 'click', () ->
        node_selecter null, null, transition_speed, false, false
        d3.select('#addall').style 'display', 'inline-block'
        d3.select('#rmall').style 'display', 'none'
      d3.select('#mac_mode').on 'click', () ->
        d3.select('#mac_mode').style 'display', 'none'
        d3.select('#ip_mode').style 'display', 'inline-block'
        d3.select('#name_mode').style 'display', 'none'
        switch_between_mac_and_ip('mac')
      d3.select('#ip_mode').on 'click', () ->
        d3.select('#ip_mode').style 'display', 'none'
        d3.select('#name_mode').style 'display', 'inline-block'
        d3.select('#mac_mode').style 'display', 'none'
        switch_between_mac_and_ip('ip')
      d3.select('#name_mode').on 'click', () ->
        d3.select('#name_mode').style 'display', 'none'
        d3.select('#ip_mode').style 'display', 'none'
        d3.select('#mac_mode').style 'display', 'inline-block'
        switch_between_mac_and_ip('name')    
    #clear selections and revert to selectable status
    monitor_backward_to_selection = () ->
      d3.select('#back').on 'click', () ->
        
        deferred = new $q.defer()
        promise = deferred.promise
        promise = promise.then(recovery).then(add_panel_controller).then(add_select_btn_group).then(monitor_select_btn_group).then(bring_back_footer).then(add_backto_setip_btn)
        deferred.resolve()
        msgbox.msgbar_show('please select desire devices to config', 'instruction')
        $rootScope.showconfigs = false
        $rootScope.$apply()
        for agent in window.agent
          agent.disconnect 'by manaul'
        window.smith_reconnect = false
        window.targetip = []
        window.config_data = {}
        clearInterval window.check_agent
    #apply IPs to selected MAC adresses  
    monitor_apply_ip_button = () ->
      d3.select('#applyip').on 'click', () ->
        if $(".ip_input:blank").length is 0
          if d3.select('.ip_input.error').empty()       
            desire_ip = []
            $('.ip_input').each () ->
              desire_ip.push $(this).val()
            
            clearInterval window.regular_rechecking
            window.targetmac = []
            
            window.targetmac.push i.mac for i in force.nodes() when i.mac?
            console.log window.targetmac

            #$('.lstext').each () ->
            #  window.targetmac.push $(this).text()
            
            window.desire_ip = desire_ip
            
            build_messages_array = () ->
              ips = window.desire_ip
              macs = window.targetmac
              window.messages = []
              buildmessage = (mac, ip) ->
                head = ip.slice 0,ip.lastIndexOf(".")
                tail = '.254'
                gateway = head.concat tail
                message =
                  key:'intrising'
                  type: 'api'
                  mac: mac
                  api:
                    name: 'system::set_net_cfg'            
                    args: 
                      ipaddr: ip
                      gatewayip: gateway
                return message
              for i, key in ips
                window.messages.push buildmessage macs[key], ips[key]
            build_messages_array()
            send = () ->
              for i in window.messages
                window.mr.mcastsend i, window.interface
            send()
            original = force.nodes()
            _.map original, (value, key) ->
              value.ip = window.desire_ip[key]
            msgbox.msgbar_show('Please wait. Intriconfig is applying IPs to devices...', 'info')
            effect.show_spinner('Applying')
            deferred = new $q.defer()
            promise = deferred.promise
            promise = promise.then(hide_iplslink).then(remove_apply_ip_button).then(remove_cancel_apply_ip_button).then(recovery).then(inhibit_panel).then(hide_footer)
            deferred.resolve()
            setTimeout (->
              effect.hide_spinner()
              msgbox.msgbar_show('set IPs to devices', 'success')
              deferred = new $q.defer()
              promise = deferred.promise
              promise = promise.then(recovery).then(add_panel_controller).then(add_select_btn_group).then(monitor_select_btn_group).then(add_backto_setip_btn).then(bring_back_footer)
              deferred.resolve()
              
              d3.selectAll('.lstext').remove()
              lstext = d3.select("#panelselectionwrap").selectAll(".lstext")
              lstext = lstext.data force.nodes()
              padding = () ->
                if nodes.length * ls_line_height > 350 then (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/4)
                else (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/2)
              lstext.enter().insert('span').attr
                class: (d) ->
                  clses = ['lstext']
                  dmac = 'MAC' + d.mac
                  mac = dmac.replace(/:/g, '')
                  dip = 'IP' + d.ip
                  ip = dip.replace(/\./g, '')
                  clses.push mac
                  clses.push ip
                  a = clses.join(' ')
              .text (d) ->
                d.ip
              .style
                'height': ls_line_height + 'px'
                'font-size': font_size + 'px'
                'line-height': font_size + 'px'
                'padding-top': padding() + 'px'
              lstext.on
                mousedown: (d, i) ->
                  node_selecter(d, i, transition_speed, true, 'single_mode')
              window.targetip = []
            ),60000
          else
            effect.animated("#applyip", "shake")
            msgbox.msgbar_show('please input valid IP adress', 'error')
        else
          effect.animated("#applyip", "shake")
          $(".ip_input:blank").addClass "error"
          msgbox.msgbar_show('empty input', 'error')     
    #skip apply IPs
    monitor_cancel_apply_ip_button = () ->
      trying = 0
      d3.select('#cancel_applyip').on 'click', () ->
        if $(".ip_input:blank").length is 0 or trying isnt 0
          if d3.select('.ip_input.error').empty()  or trying isnt 0
            desire_ip = []
            $('.ip_input').each () ->
              desire_ip.push $(this).val()
            uips = _.uniq desire_ip
            if _.size(uips) is _.size(desire_ip) or trying isnt 0
              clearInterval window.regular_rechecking
              deferred = new $q.defer()
              promise = deferred.promise
              promise = promise.then(hide_iplslink).then(remove_apply_ip_button).then(remove_cancel_apply_ip_button).then(recovery).then(inhibit_panel).then(recovery).then(add_panel_controller).then(add_select_btn_group).then(monitor_select_btn_group).then(bring_back_footer).then(add_backto_setip_btn)
              deferred.resolve()
              setTimeout (->
                effect.animated(".lstext", "flash")
              ),2300
              d3.selectAll('.lstext').remove()
              lstext = d3.select("#panelselectionwrap").selectAll(".lstext")
              lstext = lstext.data force.nodes()
              padding = () ->
                if nodes.length * ls_line_height > 350 then (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/4)
                else (lsnode_padding_top + lsnoder - lsnodestokewidth - font_size/2)
              lstext.enter().insert('span').attr
                class: (d) ->
                  clses = ['lstext']
                  dmac = 'MAC' + d.mac
                  mac = dmac.replace(/:/g, '')
                  dip = 'IP' + d.ip
                  ip = dip.replace(/\./g, '')
                  clses.push mac
                  clses.push ip
                  a = clses.join(' ')
              .text (d) ->
                d.ip
              .style
                'height': ls_line_height + 'px'
                'font-size': font_size + 'px'
                'line-height': font_size + 'px'
                'padding-top': padding() + 'px'
              lstext.on
                mousedown: (d, i) ->
                  node_selecter(d, i, transition_speed, true, 'single_mode')
              window.targetip = []
            else
              effect.animated("#cancel_applyip", "shake")
              msgbox.msgbar_show('some of the devices have duplicate ip addresses, you need to set unique ip for each of them in order to configure other settings', 'error')
              setTimeout (->
                effect.animated("#applyip", "flash")
              ),2500
              $rootScope.$apply()
              trying = 1
          else
            effect.animated("#cancel_applyip", "shake")
            msgbox.msgbar_show('some of the devices do not have valid ip address, you need to set valid ip for them in order to configure other settings', 'error')
            $rootScope.$apply()
            setTimeout (->
              effect.animated("#applyip", "flash")
            ),2500
            trying = 1
        else
          effect.animated("#cancel_applyip", "shake")
          msgbox.msgbar_show('some of the devices do not have ip address, you need to set ip for them in order to configure other settings', 'error')
          $rootScope.$apply()
          setTimeout (->
            effect.animated("#applyip", "flash")
          ),2500
          trying = 1
    set_ip = () ->
      deferred = new $q.defer()
      promise = deferred.promise
      promise = promise.then(init_panel).then(remove_panel_controller).then(add_panel_controller).then(add_apply_ip_button).then(add_cancel_apply_ip_button).then(resize_panel).then(adjust_panel_controller_when_set_ip).then(inhibit_panel).then(hide_and_inhibit_topology).then(add_ip_panel).then(add_ip_panel_items).then(show_iplslink).then(add_validate).then(monitor_apply_ip_button).then(monitor_cancel_apply_ip_button).then(inhibit_panel).then(bring_back_footer)
      msgbox.msgbar_show('please set ip first in order to configure devices', 'info')
      deferred.resolve()     
    #working flow initilize
    if mode is 'demo'
      d3.selectAll('.lslink').style('display', 'none')
      d3.select('#panel').style('display', 'none')
      d3.select('#topocontroller').style
        top: 210 + 'px'
        left: 982 + 'px'
        opacity: 1
      d3.select('#panel_bg').transition().style
        opacity: 1
        left: 980 + 'px'
      .duration(800)
      msgbox.msgbar_show('demo mode', 'info')
    if mode is 'scan'
      if starting_point is 'set_config'
        deferred = new $q.defer()
        promise = deferred.promise
        promise = promise.then(init_panel).then(remove_panel_controller).then(add_panel_controller).then(add_select_btn_group).then(monitor_select_btn_group)
        deferred.resolve()
      if starting_point is 'set_ip'
        set_ip()
#data processer      
ngapp.service 'data', ($rootScope, smith, $q) ->
  processer: ( devs) ->
    grings = {}
    gnodes = []
    glinks = []
    find_node_idx = (mac)->
      return i for node,i in gnodes when node.mac == mac
      -1
    add_to_linkset = (linkset, link) ->
      duplinks = (l for l in linkset when enhanced_equlink(link,l) )
      linkset.push link if duplinks.length==0
    n0 = -1
    n1 = -1
    omit_dup = (linkset) ->
      if linkset? and linkset != []
        for j in linkset
          do (j) ->
            if j? and j.nodepair? and j.blocked is false
              if (j.nodepair[0] is n0 and j.nodepair[1] is n1) or (j.nodepair[0] is n1 and j.nodepair[1] is n0) is true
                n = linkset.indexOf(j)
                linkset.splice n, 1
                console.log 'duplicated data of link is deleted'
    find_dup_n = (linkset) ->
      if linkset? and linkset != []
        for i in linkset
          do (i) ->
            if i? and i.blocked? and i.blocked is true
              n0 = i.nodepair[0]
              n1 = i.nodepair[1]
              omit_dup(linkset)                         
    find_linkidx = ( mac, pno)->
      nidx = find_node_idx( mac)
      for l,i in glinks
        if (nidx==l.nodepair[0] and pno==l.portpair[0]) or (nidx==l.nodepair[1] and pno==l.portpair[1])
          return i
    equlink = ( lka, lkb)->
      (lka.nodepair[0]==lkb.nodepair[0] and lka.nodepair[1]==lkb.nodepair[1]) or (lka.nodepair[0]==lkb.nodepair[1] and lka.nodepair[1]==lkb.nodepair[0])
    enhanced_equlink = (lka, lkb) ->
      (lka.nodepair[0]==lkb.nodepair[0] and lka.nodepair[1]==lkb.nodepair[1] and lka.blocked is lkb.blocked) or (lka.nodepair[0]==lkb.nodepair[1] and lka.nodepair[1]==lkb.nodepair[0] and lka.blocked is lkb.blocked)
    for d in devs
      do (d) ->
        if d.node?
          o = 
            mac: d.node.local_id
            ip: d.node.local_ip_address
            location: d.node.sys_location
            name: d.node.sys_name
            rings:[]
          gnodes.push o
    for d in devs
      blkports = []
      upports = []
      if d.ports?
        blkports = (p.no for p in d.ports when p.blocking)
        upports = (p.no for p in d.ports when p.link is 'up')
      if d.links?
        for l in d.links
          continue if l.local_port_no not in upports
          if find_node_idx( l.neighbour_id)<0
            gnodes.push
              mac: l.neighbour_id
              ip: l.neighbour_ip_address
              location: 'unknown'
              name: l.neighbour_system_name
          link =
            nodepair: [ find_node_idx(l.local_id), find_node_idx(l.neighbour_id)]
            portpair: [l.local_port_no, l.neighbour_port_no]
            blocked: l.local_port_no in blkports
          add_to_linkset glinks, link
          find_dup_n glinks
    for d in devs
      continue if not d.rings?
      for r in d.rings
        if not grings[r.ring_id]?
          grings[r.ring_id]= id:r.ring_id, type:r.type, state:r.state, nodes:[],links:[]
        mring = grings[r.ring_id]
        if d.node? then mring.nodes.push idx: find_node_idx(d.node.local_id), role:r.role
        if d.node? then linkidx = find_linkidx(d.node.local_id, r.ring_port_0)
        if linkidx? then mring.links.push linkidx if linkidx not in mring.links
        if d.node? then linkidx = find_linkidx(d.node.local_id, r.ring_port_1)
        if linkidx? then mring.links.push linkidx  if linkidx not in mring.links
    for rid, ring of grings
      for rnode in ring.nodes
        node = gnodes[rnode.idx]
        node.rings.push
          id: ring.id
          type: ring.type
          role: rnode.role
      for rlinkidx in ring.links
        link = glinks[rlinkidx]
        link.rings=[] if not link.rings?
        link.rings.push
          id: ring.id
          type: ring.type
    return nodes: gnodes, links: glinks, rings: grings
#msgbox
ngapp.service 'msgbox', ($rootScope) ->
  msgbar_show: (msg, type, x, y) ->
    if msg? and type?
      console.log type + ': ' + msg
      d3.select('.message-type').classed 'success', false
      d3.select('.message-type').classed 'error', false
      d3.select('.message-type').classed 'instruction', false
      d3.select('.message-type').classed 'info', false
      d3.select('.message-type').text(type)
      d3.select('.message').text(msg)
      switch type
        when 'success'
          d3.select('#noti').transition().style('opacity', 1).duration(200).transition().style('opacity', 0).duration(10000)
          d3.select('.message-type').classed 'success', true
        when 'error'
          d3.select('#noti').transition().style('opacity', 1).duration(200).transition().style('opacity', 0).duration(25000)
          d3.select('.message-type').classed 'error', true
        when 'instruction'
          d3.select('#noti').transition().style('opacity', 1).duration(200).transition().style('opacity', 0).duration(30000)
          d3.select('.message-type').classed 'instruction', true
        when 'info'
          d3.select('#noti').transition().style('opacity', 1).duration(200).transition().style('opacity', 0).duration(50000)
          d3.select('.message-type').classed 'info', true
    if x? and y?
      console.log 'start pointer'
#'loading'
ngapp.controller 'loading', ($scope, $rootScope, smith, $timeout) ->
  $scope.page = ''
  $scope.reload = () ->
    win.reload()
  $scope.showdev = () ->
    win.showDevTools()
  $scope.reloadtopo = () ->
    $scope.page = ' '
    $timeout ( ->
      $scope.page = 'topology'
    ), 400
    $timeout ( ->
      d3.select('#menubar').transition().style
        top: 700 + 'px'
        opacity: 0
      .duration(2000)
    ), 800 
  $scope.$watch 'testconfigs', (newone, oldone) ->
    if newone is true
      window.targetip = ['192.168.16.12', '192.168.16.13']
      window.agent_start()
      $rootScope.showconfigs = true
      window.smith_reconnect = true
    if newone is false
      window.targetip = []
      $rootScope.showconfigs = false
      window.smith_reconnect = false
  $scope.$watch 'config', (newone, oldone) ->
    if newone isnt undefined and $scope.smith_not_connected is false
      $scope.config = newone
    if newone isnt undefined and $scope.smith_not_connected is true
      $scope.$watch 'smith_not_connected', (newstatus, oldstatus) ->
        if newstatus is false
          $scope.config = ''
          $scope.config = newone 
  $scope.list_device = () ->
    console.log window.mr.network_devices_list()
  $scope.test_muticast_send = () ->
    msg =
      key:'intrising'
      type: 'api'
      mac: '28:60:46:a0:07:d5'
      api:
        name: 'system::set_sys_cfg'
        args:
          location: '12dsfsdf34'
    window.mr.mcastsend(msg, window.interface)
  $scope.start_muticast = () ->
    window.mr.start_mcast_receiver(window.interface)
#directive for pages
#demo
ngapp.directive 'demo', ->
  restrict: 'E'
  templateUrl: 'pages/demo.html'
  scope: {}  
  controller: ($scope, $http, $q, $rootScope, topo, msgbox, effect) ->
    $rootScope.showconfigs = false
    window.smith_reconnect = false
    effect.hide_spinner()
    clearInterval window.regular_checking
    clearInterval window.regular_rechecking
    topo_json = 'ringtops.json'
    getdata = (json_url) ->
      $http.get(json_url).success (data) ->
    set_for_selection = (http_get_data) ->              #set seletion items
      rawdata = http_get_data.data
      $scope.topnms = (topnm for topnm, top of rawdata) #make the list of selection
      $scope.topcap = (topnm) ->
        topnm.replace /_/g, ' '                         #replace '_' with space
      $("#selection").chosen 
        no_results_text: "No results match"
        max_selected_options:1
        width: "160px"
      setTimeout (->
        $("#selection").trigger("chosen:updated")
      ),1500
      return http_get_data
    reconstruct_topology_data = (http_get_data) ->
      topodata = http_get_data.data
      complete_topd = (topd) ->
        node.rings = [] for node in topd.nodes
        link.rings = [] for link in topd.links
        for rid,ringd of topd.rings
          for lidx in ringd.links
            link = topd.links[lidx]
            link.rings = [] if not link.rings?
            link.rings.push id:ringd.id, type: ringd.type
          for nrd in ringd.nodes
            node = topd.nodes[nrd.idx]
            node.rings = [] if not node.rings?
            node.rings.push id:ringd.id, type: ringd.type, role: nrd.role
      target_topo = topodata[$scope.seltopnm]
      complete_topd(target_topo)
      return target_topo
    draw_topology = (topodata) ->
      if topodata?      
        topo.showd3 topodata, 'demo', null, 'ring'
      else
        $q.reject('data not ready')
    error = (err) ->
      msgbox.msgbar_show(err, 'error')
    $scope.q_starttopo = () ->
      deferred = $q.defer()
      promise = deferred.promise
      promise.then(getdata).then(set_for_selection).then(reconstruct_topology_data).then(draw_topology, error)
      deferred.resolve(topo_json)
    $scope.q_starttopo()
#100 nodes
ngapp.directive 'testing100', ->
  restrict: 'E'
  templateUrl: 'pages/demo.html'
  scope: {}  
  controller: ($scope, $http, $q, $rootScope, topo, msgbox, effect, smith, data) ->
    $rootScope.showconfigs = false
    window.smith_reconnect = true
    effect.hide_spinner('Scanning')
    clearInterval window.regular_checking
    clearInterval window.regular_rechecking

    $http.get('wonju_topd.json').success (topd) ->
      raw = ( dev for ip,dev of topd)
      good = data.processer(raw)        
      topo.showd3 good, 'scan', 'set_ip', 'ring'
    
#directive for pages
#test work flow page
ngapp.directive 'testing', ->
  restrict: 'E'
  templateUrl: 'pages/demo.html'
  scope: {}  
  controller: ($scope, $http, $q, $rootScope, topo, msgbox, effect, smith) ->
    $rootScope.showconfigs = false
    window.smith_reconnect = true
    effect.hide_spinner('Scanning')
    clearInterval window.regular_checking
    clearInterval window.regular_rechecking
    topo_json = 'ringtops.json'
    getdata = (json_url) ->
      $http.get(json_url).success (data) ->
    set_for_selection = (http_get_data) ->
      rawdata = http_get_data.data
      $scope.topnms = (topnm for topnm, top of rawdata) #make the list of selection
      $scope.topcap = (topnm) ->
        topnm.replace /_/g, ' '                         #replace '/_/g' with space
      return http_get_data
    reconstruct_topology_data = (http_get_data) ->
      topodata = http_get_data.data
      complete_topd = (topd) ->
        node.rings = [] for node in topd.nodes
        link.rings = [] for link in topd.links
        for rid,ringd of topd.rings
          for lidx in ringd.links
            link = topd.links[lidx]
            link.rings = [] if not link.rings?
            link.rings.push id:ringd.id, type: ringd.type
          for nrd in ringd.nodes
            node = topd.nodes[nrd.idx]
            node.rings = [] if not node.rings?
            node.rings.push id:ringd.id, type: ringd.type, role: nrd.role
      target_topo = topodata[$scope.seltopnm]
      complete_topd(target_topo)
      return target_topo
    draw_topology = (topodata) ->
      if topodata?      
        topo.showd3 topodata, 'scan', 'set_ip', 'ring'
      else
        $q.reject('data not ready')
    error = (err) ->
      msgbox.msgbar_show(err, 'error')
    $scope.q_starttopo = () ->
      deferred = $q.defer()
      promise = deferred.promise
      promise.then(getdata).then(set_for_selection).then(reconstruct_topology_data).then(draw_topology, error)
      deferred.resolve(topo_json)
    $scope.q_starttopo()
#topology scan page  
ngapp.directive 'topology', ->
  restrict: 'E'
  templateUrl: 'pages/topology.html'
  scope: {}
  controller: ($rootScope, $scope, $q, $timeout, data, topo, smith, msgbox, effect) ->
    $rootScope.showconfigs = false
    window.smith_reconnect = false
    go = () ->
      $scope.data = {}
      $scope.device_list = {}
      msgbox.msgbar_show 'start to scan device on lan', 'info'
      effect.show_spinner('Scanning')
      window.mr.start_mcast_receiver(window.interface)
      test_structure = (obj) ->
        if _.has(obj, 'ports') is true and _.has(obj, 'links') is true and _.has(obj, 'node') is true and _.has(obj, 'rings') is true then return true else return false
      test_empty = (obj) ->
        if _.isEmpty(obj) is false then return true else return false
      test_ip = (obj) ->
        if _.has(obj, 'ip') then return true else return false
      
      test_ring = (obj) ->
        if obj.id? then return true else return false
      recheckdata = () ->
        msgbox.msgbar_show 'rescanning...', 'info'
        window.mr.start_mcast_receiver(window.interface)
        newraw = ( dev for ip,dev of window.mr.swnodes)
        $scope.device_list = window.mr.network_devices_list()
        $scope.$apply()
        new_topodata = data.processer(newraw)
        #console.log new_topodata
        new_topodata_noring = _.omit new_topodata, 'rings'
        if _.every(new_topodata_noring, test_empty) is true
          $scope.data = new_topodata
          $scope.$apply()
      reset_topology = () ->
        d3.select('#panel').style('opacity', 0)
        d3.select('#panelsvg').remove()
        d3.select('#panelselectionwrap').remove()
        d3.selectAll('.lsslct').remove()
        d3.selectAll('.lslink').remove()
        d3.selectAll('.ip_list').remove()
        d3.selectAll('.iplslink').remove()
        d3.select('#ip_panel').remove()
        d3.selectAll('.link').remove()
        d3.selectAll('.node').remove()
        d3.selectAll(".nodetext").remove()
        d3.select('.inhibit').remove()
      $scope.$watch 'data', (new_data, old_data) ->
        ck_node_rings = () ->
          new_node_ring = _.map new_data.nodes, (value, key, list) -> return value.rings
          new_node_ring_o = _.reject new_node_ring, (n) -> return n is undefined
          old_node_ring = _.map old_data.nodes, (value, key, list) -> return value.rings
          old_node_ring_o = _.reject old_node_ring, (n) -> return n is undefined
          if angular.equals(new_node_ring_o, old_node_ring_o) isnt true
            console.log 'nodes.rings change detected.'
            return true 
          else 
            return false
        ck_link_blocked = ()->
          new_link_blocked = _.map new_data.links, (value, key, list) -> return value.blocked
          old_link_blocked = _.map old_data.links, (value, key, list) -> return value.blocked
          d = _.difference(new_link_blocked, old_link_blocked)
          if _.size(d) is 0
            return false 
          else
            console.log 'links.blocked status change detected.'
            return true
        ck_ring_d = () ->
          new_ring_state = _.map new_data.rings, (e) -> return e.state
          old_ring_state = _.map old_data.rings, (e) -> return e.state
          d = _.difference(new_ring_state, old_ring_state)
          if _.size(d) is 0 
            return false 
          else
            console.log 'rings.state status change detected.'
            return true
        ck_node = () ->
          if new_data.nodes? and old_data.nodes?
            if new_data.nodes.length != old_data.nodes.length
              console.log 'new node deteted'
              return true
            else
              return false
          else
            return false
        ck_link = () ->
          if new_data.links? and old_data.links?
            if new_data.links.length != old_data.links.length
              console.log 'new link detected'
              return true
            else
              return false
          else
            return false
        if ck_node() or ck_link() or ck_ring_d() or ck_node_rings() or ck_link_blocked()
          msgbox.msgbar_show 'new data fetched. topology changes', 'info'
          draw_topology new_data
      $scope.$watch 'device_list', (new_data, old_data) ->
        time = 0
        if _.size(new_data) > 0 and _.size(old_data) > 0
          ck_d = () ->
            d1 = _.difference _.keys(new_data), _.keys(old_data)
            d2 = _.difference _.keys(old_data), _.keys(new_data)
            if _.size(d1) is 0 and _.size(d2) is 0 then return false else return true
          if ck_d() is true
            msgbox.msgbar_show 'network device changed, topology redraw', 'info'
            effect.show_spinner('Scanning')
            clearInterval window.regular_checking
            clearInterval window.regular_rechecking
            reset_topology()
            window.mr.start_mcast_receiver(window.interface)
            window.mr.swnodes = {}
            window.regular_checking = setInterval checkdata, 5000
            time = time + 1
        else if time = 1
          msgbox.msgbar_show 'no connection found, please check you network connections. auto retry in 3 seconds...', 'info'
          effect.show_spinner('Scanning')
          clearInterval window.regular_checking
          clearInterval window.regular_rechecking
          reset_topology()
          window.mr.start_mcast_receiver(window.interface)
          window.mr.swnodes = {}
          window.regular_checking = setInterval checkdata, 5000  
      checkdata = () ->
        $scope.device_list = window.mr.network_devices_list()
        $scope.$apply()
        #console.log $scope.device_list
        raw = ( dev for ip,dev of window.mr.swnodes)
        #console.log window.mr.swnodes
        #if _.every(raw, test_structure) is true
        topodata = data.processer(raw)
        #console.log topodata
        #console.log raw
        topodata_noring = _.omit topodata, ['rings', 'links']
        if _.every(topodata_noring, test_empty) is true
          msgbox.msgbar_show 'initial scaning complete', 'success'
          clearInterval window.regular_checking
          draw_topology topodata_noring
          window.regular_rechecking = setInterval recheckdata, 4000
          $scope.data = topodata_noring
          $scope.$apply()
          effect.hide_spinner()
        else
          msgbox.msgbar_show 'collecting data from devices...', 'info'
          if raw.length is 0 then msgbox.msgbar_show 'no device found', 'info'
          window.mr.start_mcast_receiver(window.interface)
          effect.show_spinner('Scanning')
          #console.log topodata
           
      draw_topology = (topodata) ->
        if _.every(topodata.rings, test_ring) is true
          topo.showd3 topodata, 'scan', 'set_ip', 'ring'
          console.log 'ring mode'
        if _.every(topodata.rings, test_ring) is false
          topo.showd3 topodata, 'scan', 'set_ip', 'phy'
          console.log 'phy mode'
      window.regular_checking = setInterval checkdata, 5000
      
    window.interface = null
    $scope.done = false
    $scope.network_ip_list = window.mr.network_ip_list()
    msgbox.msgbar_show 'Please select your network interface', 'info'
    setTimeout (->
      $("#interface_selection").chosen 
        disable_search: true
        max_selected_options: 1
        width: "180px"
    ),20
      
    $scope.interface_selected = () ->
      window.interface = $scope.$$childHead.interface.address
      if window.interface isnt null
        go()
        $scope.done = true
    if $scope.network_ip_list.length is 1
      go()
    
#directive for configs pages
#Network Settings
ngapp.directive 'ipconf', ->
  restrict: 'E'
  templateUrl: 'pages/configs/ip_conf.html'
  scope: {}
  controller: ($scope, $timeout, smith, msgbox, compare) ->
    $scope.doapply = ->
      smith.emit 'system::set_net_cfg', $scope.cfg
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),2000
    smith.emit 'system::get_net_cfg', (cfg)->
      ncfg = {}
      ncfg[k] = cfg[k] for k in [ 'netmask', 'dnsip']
      $scope.cfg = ncfg
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'ipconf', ncfg)
      compare.compare(agent, 'ipconf')
#Ring Settings
ngapp.directive 'xringconf', ->
  restrict: 'E'
  templateUrl: 'pages/configs/xring_conf.html'
  scope: {}
  controller: ($rootScope, $scope, smith, data, msgbox, compare, $timeout) ->
    compare.init()

    $scope.available_ring_mode = {'basic','enhanced','auto'}
    
    smith.emit 'system::get_sys_cfg', (cfg) ->
      $scope.ring_mode = cfg.ring_mode
      $scope.$apply()
      setTimeout (->
        $("#ring_mode").chosen 
          disable_search: true
          max_selected_options: 1
          width: "160px"
      ),200
    
    $scope.rings = []
    smith.emit 'g8032::get_member_cfg', (rings)->
      $scope.rings = rings
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'ring', rings)
      compare.compare(agent, 'ring')
          
    $scope.doapply = ->
      setnewring = () ->
        if $scope.ring_mode is undefined and $scope.rings.length > 0
          msgbox.msgbar_show('Please set ring mode...', 'error')
          $scope.applying = true
          $timeout (->
            $scope.applying = false
          ),500
        else
          msgbox.msgbar_show('Please wait for few seconds...', 'info')
          for oldring in $scope.old
            smith.emit 'g8032::leave_ring_member_cfg', oldring
          for ring, index in $scope.rings
            do (ring, index) ->
              switch $scope.ringmode 
                when 'auto'
                  ring.role = 'none'
                  ring.node_fail_protection = false
                when 'basic'
                  ring.miss_connection_enabled = false
              n = $scope.rings.length-1
              if index is n
                smith.emit 'g8032::delay_join_ring_member_cfg', $scope.rings
                $timeout (->
                  cfg = 
                    'ring_mode': $scope.ring_mode
                  smith.emit 'system::delay_set_sys_cfg', cfg
                ),2000
          $scope.applying = true
          $timeout (->
            $scope.applying = false
          ),8000
          
      $scope.old = []
      ipppp = []
      getoldring = () ->
        smith.emit 'g8032::get_member_cfg', (oldrings)->
          $scope.old.push oldrings
          $scope.$apply()
          agent = this
          if agent.transport? then ipppp.push agent.transport.input.remoteAddress
          if ipppp.length is window.agent.length then setnewring()
      getoldring()
    $scope.ringchg = ->
      if @cfg.enabled
        @cfg.ring_port_0 = 3 if @cfg.ring_port_0 is -1
        @cfg.ring_port_1 = 4 if @cfg.ring_port_1 is -1
        @cfg.ring_id = 100 if @cfg.ring_id is -1
    $scope.portcap = (pno)->
      "Port #{pno}"
    $scope.yesnocap = ( b)->
      if b then 'YES' else 'NO'
    $scope.enablecap = (b)->
      if b then 'on' else 'off'
    $scope.availports = ->
      used = []
      for ring in $scope.rings
        used.push ring.ring_port_0, ring.ring_port_1
      used = _.union( used, @stpports)
      (port.no for port in this.ports when port.no not in used)
    $scope.editing_invalid = ->
      er = @editing_ring
      return true if not er?
      return true if er.ring_port_0 == er.ring_port_1
      return false if er.type is 'sub'
      epair = [ er.ring_port_0, er.ring_port_1]
      for r,i in @rings when i isnt @editing_idx
        return true if Number(er.ring_id) is Number(r.ring_id)
        othpair = [ r.ring_port_0, r.ring_port_1]
        #return true if _.intersection( epair, othpair).length>0
      return false
    $scope.rolecaps = { none:"None", owner:"Owner", neighbour:"Neighbour"}
    $scope.typecaps = { sub:"Sub", major:"Major"}
    $scope.editing_idx = -1
    $scope.newid = ->
      max =0
      max = ring.ring_id for ring in this.rings when ring.ring_id > max
      return max+1
    $scope.add_ring = ->
      aports = this.availports()
      if aports.length< 1
        msgbox.msgbar_show 'no ports are available for ring', 'error'
        return
      this.rings.push
        enabled:false
        role: 'none'
        type: 'major'
        ring_id: $scope.newid()
        ring_port_0: aports[0]
        ring_port_1: aports[1]
    $scope.del_ring = (rid) ->
      $scope.rings = (r for r in this.rings when r.ring_id isnt rid)
    $scope.switch_to_editing = (idx)->
      $scope.editing = true
      $scope.editing_ring = r = angular.copy $scope.rings[idx]
      aports = (port.no for port in this.ports when port.no not in @stpports)
      $scope.editing_aports = aports
      $scope.editing_idx = idx
      setTimeout (->
        $(".ringselect_port").chosen 
          disable_search: true
          max_selected_options: 1
          width: "75px"
        $(".ringselect").chosen 
          disable_search: true
          max_selected_options: 1
          width: "78px"
      ),200
    $scope.port0msg = ->
      return '' if not @editing_ring?
      return 'the RPL Port to Major' if @editing_ring.role is 'neighbour'
      return 'the RPL Port to Neighbor' if @editing_ring.role is 'owner'
      ''
    $scope.edit_cancel = ->
      $scope.editing = false
      $scope.editing_idx = -1
    $scope.edit_save = ->
      $scope.editing = false
      $scope.rings[this.editing_idx] = this.editing_ring
      $scope.editing_idx = -1
    $scope.automode = false
    $scope.allports_occupied = false
    
    smith.emit 'port_ctrl::get_status', (cfg)->
    
      $scope.ports = cfg
      $scope.$apply()
      
      #agent = this
      #compare.pushdata(agent, 'ring', cfg)
      #compare.compare(agent, 'ring')
      
    $scope.checkdualhoming = ->
      smith.emit 'dualhoming::get_member_cfg', (cfg) ->
        agent = this
        for x in cfg
          if x.port_no and x.enabled
            $scope.stpports.push x.port_no
            $scope.$apply()
            
    smith.emit 'mstp::get_cist_cfg', (cistg)->
      
      if cistg.ports?
        $scope.stpports = ( cp.no for cp in cistg.ports when cp.stp_enabled)
      $scope.allports_occupied =  ($scope.rings.length==0) and ($scope.availports().length==0)
      $scope.$apply()

      #compare.pushdata(agent, 'ring', cistg)
      #compare.compare(agent, 'ring')
      
      $scope.checkdualhoming()
#SFP Digital Diagnostic Monitor Event
ngapp.directive 'evleventsddmev', ->
  restrict: 'E'
  templateUrl: 'pages/configs/evlevents_ddmev.html'
  scope: {}
  controller: ($scope, smith, msgbox, compare, $timeout) ->
    compare.init()
    uW_to_dBm = (uw) ->
      10 * Math.log( Number(uw)/1000) / Math.LN10
    dBm_to_uW = (dbm) ->
      1000 * Math.pow( 10, Number(dbm)/10)
    $scope.ready = false
    $scope.doapply = ->
      cfg = angular.copy $scope.cfg
      thr = cfg.thresholds
      thr.tx_power[0] = dBm_to_uW thr.tx_power[0]
      thr.tx_power[1] = dBm_to_uW thr.tx_power[1]
      thr.rx_power[0] = dBm_to_uW thr.rx_power[0]
      thr.rx_power[1] = dBm_to_uW thr.rx_power[1]
      smith.emit 'hwevent::set_config', ddm:cfg
      #msgbox.msgbar_show 'Configuration Applied', 'success'
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
    $scope.vccfmt = (value) ->
      if value?
        value.toString() + "V"
    $scope.dbmfmt= (value) ->
      if value?
        Math.floor(value).toString() + "dBm"
    $scope.tempfmt= (value) ->
      if value?
        value.toString() + "\u2103"
    $scope.biasfmt= (value) ->
      if value?
        value.toString() + "mA"
    smith.emit 'hwevent::get_config', (allcfg)->
      cfg = allcfg.ddm
      thr = cfg.thresholds
      thr.tx_power[0] = uW_to_dBm thr.tx_power[0]
      thr.tx_power[1] = uW_to_dBm thr.tx_power[1]
      thr.rx_power[0] = uW_to_dBm thr.rx_power[0]
      thr.rx_power[1] = uW_to_dBm thr.rx_power[1]
      $scope.cfg = cfg
      agent = this
      compare.pushdata(agent, 'evleventsddmev', cfg)
      compare.compare(agent, 'evleventsddmev')
      $scope.ready = true
      $scope.$apply()
#SMTP
ngapp.directive 'systemlogsmtpcconf', ->
  restrict: 'E'
  templateUrl: 'pages/configs/systemlog_smtpc_conf.html'
  scope: {}
  controller: ($scope, smith, msgbox, compare, $timeout)->
    compare.init()
    theform_valid = ->
      #theformkeys = ['Password', 'Sender', 'Smtpserver', 'Subject', 'User']
      #valid = true
      #valid = false for k in theformkeys when $scope.theform[k].$invalid
      #valid
      true
    $scope.appliable = ->
      return false if not @smtpc?
      if @smtpc.enabled
        return false if not theform_valid()
      true
    $scope.doapply = ->
      smith.emit 'evact_manager::set_smtp_cfg', $scope.smtpc
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
    $scope.email_toadd = ''
    $scope.smtpc_add_receiver = (email)->
      if email is ''
        msgbox.msgbar_show 'empty input', 'error'
      else
        if email in @smtpc.receivers
          msgbox.msgbar_show 'email address duplicated', 'error'
        else
          @smtpc.receivers.push email
      $scope.email_toadd = ''
    $scope.smtpc_dotest = (rcver) ->
      smith.emit 'evact_manager::smtp_test', rcver
      msgbox.msgbar_show 'Test Email Sent', 'success'
    $scope.smtpc_del_receiver = (rcver)->
      receivers = @smtpc.receivers
      receivers.splice i,1 for r,i in receivers when r == rcver
    smith.emit 'evact_manager::get_smtp_cfg', (cfg)->
      cfg.cloud_smtp = true if not cfg.cloud_smtp?
      $scope.smtpc = cfg
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'systemlogsmtpcconf', cfg)
      compare.compare(agent, 'systemlogsmtpcconf')
  #$('#smtpserver').typeahead
  #  source: [ 'smtp.mail.yahoo.com']
  #to workaround  https://github.com/twitter/bootstrap/issues/4018
    $('ul.typeahead').mousedown (e)->
      e.preventDefault()
#SMS Alert
ngapp.directive 'systemlogsmscconf', ->
  restrict: 'E'
  templateUrl: 'pages/configs/systemlog_smsc_conf.html'
  scope: {}
  controller: ($scope, smith, msgbox, compare, $timeout)->
    compare.init()
    theform_valid = ->
      #theformkeys = ['User_ID', 'Password', 'Sender_Text']
      #valid = true
      #valid = false for k in theformkeys when $scope.theform[k].$invalid
      valid = true
    $scope.appliable = ->
      return false if not @smsc?
      if @smsc.enabled
        return false if not theform_valid()
        if @smsc.receivers.length==0
          return false
      true
    $scope.doapply = ->
      smith.emit 'evact_manager::set_sms_cfg', @smsc
      #msgbox.msgbar_show('Configuration Saved', 'success')
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
    $scope.phoneno_toadd = ''
    $scope.smsc_add_receiver = (phoneno)->
      return if not phoneno?
      if phoneno in @smsc.receivers
        msgbox.msgbar_show 'Phone number duplicated', 'error'
        return
      @smsc.receivers.push phoneno
      $scope.phoneno_toadd =''
    $scope.smsc_del_receiver = (rcver)->
      receivers = @smsc.receivers
      receivers.splice i,1 for r,i in receivers when r == rcver
    $scope.smsc_dotest=(rcver)->
      smith.emit 'evact_manager::sms_test', rcver
      msgbox.msgbar_show 'SMS message sent'
    smith.emit 'evact_manager::get_sms_cfg', (cfg)->
      $scope.smsc = cfg
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'systemlogsmscconf', cfg)
      compare.compare(agent, 'systemlogsmscconf')
#Event Action Map
ngapp.directive 'evlevactmap', ->
  restrict: 'E'
  templateUrl: 'pages/configs/evl_evactmap.html'
  scope: {}
  controller: ($rootScope, $scope, smith, data, msgbox, compare, $timeout) ->
    compare.init()
    nports = {}
    from_str = (s)->
      [nm, num, st] = s.split('_')
      o = { name:nm }
      o.no = Number(num) if num?
      o.status = st if st?
      o
    to_str = ( ent)->
      s = ent.name
      s+="_#{ent.no}" if ent.no?
      s+="_#{ent.status}" if ent.status?
      s
    evas_to_cfg = ( evas) ->
      cfg = {}
      for eva in evas
        ev = eva.ev
        evinst = { }
        evinst.no = ev.no if ev.no?
        evinst.status = ev.status if ev.status?
        evinst.actions = (from_str( actstr) for actstr in eva.acts)
        cfg[ev.name]=[] if not cfg[ev.name]?
        cfg[ev.name].push evinst
      cfg
    events_enum = ->
      evs = []
      for evnm in ['boot','ddm', 'envmon', 'poe']
        evs.push { name:evnm}
      for st in ['fail', 'success']
        evs.push { name:'auth', status:st}
      for dino in [1..2]
        evs.push { name:'di', no: dino}
      for pwno in [1..2]
        for st in [ 'on', 'off']
          evs.push { name:"power", no: pwno, status:st}
      for p in nports
        for st in [ 'up', 'down']
          evs.push { name:"linkchg", no: p.no, status:st}
      evs
    #expand evm into multiple
    cfg_to_evas = (evmcfg)->
      evas = []
      for evnm, evinsts of evmcfg
        for evinst,i in evinsts
          evo = _.pick( evinst, 'no', 'status')
          evo.name = evnm
          evas.push
            ev: evo
            acts: (to_str(act) for act in evinst.actions)
      evas
    eventtab_register_funcs = ()->
      $scope.doapply = ->
        evas = $scope.curr_evas_norm.concat $scope.curr_evas_link
        cfg = evas_to_cfg( evas)
        diffcfg = {}
        for k in _.union( Object.keys(cfg), Object.keys($scope.origcfg))
          newv = if cfg[k]? then cfg[k] else []
          origv = $scope.origcfg[k]
          diffcfg[k]=newv #if angular.toJson(newv) != angular.toJson(origv)
        smith.emit 'evact_manager::set_event_cfg', diffcfg
        $scope.applying = true
        $timeout (->
          $scope.applying = false
        ),1000
        #msgbox.msgbar_show('Configuration Saved', 'success')
      actnmcaps =
        smtp:'Email'
        remote: 'Syslog'
        snmp: 'SNMP Trap'
        dout: 'DOUT'
        sms: 'SMS'
      $scope.actcap = (actstr)->
        [actnm, actno, actst] = actstr.split('_')
        cap = actnmcaps[actnm]
        cap+= " #{actno}" if actno?
        cap+= " #{actst}" if actst?
        cap
      $scope.add_norm_event = (ev)->
        $scope.curr_evas_norm.push { ev: ev, acts:['remote']}
        setTimeout (->
          $('#normev_form select').chosen()
          $('#add_normev').trigger "chosen:updated"
        ),0
      $scope.del_norm_event = (ev_todel)->
        $scope.curr_evas_norm = (eva for eva in $scope.curr_evas_norm when eva.ev isnt ev_todel)
        $scope.normev_toadd = ''
        setTimeout (->
          $('#add_normev').trigger "chosen:updated"
        ),0
      $scope.is_avail_norm_ev = (ev)->
        return false for eva in $scope.curr_evas_norm when angular.equals( ev, eva.ev)
        return true
      $scope.normev_toadd = ''
      $scope.add_link_event = (ev)->
        $scope.curr_evas_link.push { ev: ev, acts:['remote']}
        setTimeout (->
          $('#linkev_form select').chosen()
          $('#add_linkev').trigger "chosen:updated"
        ),0
      $scope.del_link_event = (ev_todel)->
        $scope.curr_evas_link = (eva for eva in $scope.curr_evas_link when eva.ev isnt ev_todel)
        $scope.linkev_toadd = ''
        setTimeout (->
          $('#add_linkev').trigger "chosen:updated"
        ),0
      $scope.is_avail_link_ev = (ev)->
        return false for eva in $scope.curr_evas_link when angular.equals( ev, eva.ev)
        return true
      $scope.linkev_toadd = ''
      evnmcaps =
        boot: 'Boot'
        auth: 'Login'
        di: 'DIN'
        power: 'Power'
        ring: 'Ring'
        linkchg: 'Port'
        ddm: 'DDM'
        envmon: 'EnvMon'
        poe: 'POE'
      $scope.evcap = (ev)->
        cap = evnmcaps[ev.name]
        if ev.no? and ev.status?
          cap += " #{ev.no} #{ev.status}"
        else if ev.no?
          cap += " #{ev.no}"
        else if ev.status?
          cap += " #{ev.status}"
        cap
    eventtab_load_cfg = ($scope, evmcfg)->
      $scope.origcfg = evmcfg
      evas = cfg_to_evas(evmcfg)
      allevs = events_enum()
      $scope.allacts = [ 'remote', 'smtp', 'sms', 'snmp', 'dout_1', 'dout_2' ]
      $scope.norm_evs = (ev for ev in allevs when ev.name isnt 'linkchg')
      $scope.curr_evas_norm = (eva for eva in evas when eva.ev.name isnt 'linkchg')
      $scope.link_evs = (ev for ev in allevs when ev.name is 'linkchg')
      $scope.curr_evas_link =(eva for eva in evas when eva.ev.name is 'linkchg')
      $scope.$apply()
      $('#normev_form select').chosen()
      $('#linkev_form select').chosen()
      $('#add_normev').trigger "chosen:updated"
      $('#add_linkev').trigger "chosen:updated"
      $('#wait_spin').hide() 
    defev =
      boot : [{actions:[{name:'local'} , {name :'remote'} , {name : 'sms'} , {name : 'smtp'} , {name:'snmp'} ]}]
    auth : [{status:'fail',actions:[{name:'local'} , {name :'remote'} , {name : 'sms'} , {name : 'smtp'} , {name:'snmp'} , {name:'dout' , no : 1}]}]
    linkchg : [{no:1 , status : 'up' , actions:[{name:'local'} , {name :'remote'} ,  {name:'dout' , no : 2}]},{no:2 , status : 'down' , actions:[{name:'local'} , {name :'remote'}]}]
    power : [{no:1 , status : 'on' ,actions:[{name:'local'} , {name :'remote'}]},{no:2 ,status : 'off' , actions:[{name:'local'} , {name :'remote'}]}]
    di : [{no:1 , actions:[{name:'local'} , {name :'remote'}]},{no:2 , actions:[{name:'local'} , {name :'remote'}]}]
    eventtab_register_funcs( $scope)
    smith.emit 'port_ctrl::get_status', (cfg)->
      nports = cfg
      agent = this
      compare.pushdata(agent, 'evlevactmap', cfg)
      compare.compare(agent, 'evlevactmap')
    smith.emit 'evact_manager::get_event_cfg', (cfg)->
      eventtab_load_cfg($scope, cfg)
      agent = this
      compare.pushdata(agent, 'evlevactmap', cfg)
      compare.compare(agent, 'evlevactmap')
#Device Time Configuration
ngapp.directive 'timentp', ->
  restrict: 'E'
  templateUrl: 'pages/configs/sys_time.html'
  scope: {}
  controller: ($rootScope, $scope, smith, data, msgbox, compare, $timeout) ->
    compare.init()
    $('#dp1').datepicker('autoclose',true)
    dp = $('#dp1').data('datepicker')
    $scope.full_zonename = ->
      city = @cfg.timezone
      for conti, cities of @contis
        return "#{conti}/#{city}" if city in cities
    $scope.doapply = ->
      d = dp.getDate()
      localtime = fullyear: d.getFullYear(), month:d.getMonth(), date: d.getDate(), hours:d.getHours(), minutes: d.getMinutes(), seconds: d.getSeconds()
      newcfg =
        timesrc: @cfg.timesrc
        TZ: @full_zonename()
        ntp_server: @cfg.ntp_server
        localtime: localtime
      smith.emit 'system::set_time_cfg', newcfg
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
      #msgbox.msgbar_show('Time config Applied', 'success')
    $scope.srccaps ={ manual: 'Manual', ntp: 'SNTP' }
    $scope.localtimecap = ->
      d = dp.getDate()
      d.toLocaleString()
    $scope.syncbrowser = ->
      dp.setDate(new Date())
    setTimeout (->
      $('#zonesel').chosen
        no_results_text: "No results match"
        max_selected_options:1
        width: "160px"
      $("#clock_source").chosen 
        disable_search: true
        max_selected_options:1
        width: "160px"
    ),700
    $.getJSON 'assets/conti_zones.json', (contis)->
      $scope.contis = contis
      $scope.$apply()
    localtime2date = (lt)->
      new Date( lt.fullyear, lt.month, lt.date, lt.hours, lt.minutes, lt.seconds)
    smith.emit 'system::get_time_cfg', (cfg)->
      cfg.TZ?='Asia/Taipei'
      cfg.timezone = cfg.TZ.split('/')[1..].join('/')
      $scope.cfg = cfg
      $scope.$apply()
      dp.setDate(localtime2date($scope.cfg.localtime))
      setTimeout (->
        $('#zonesel').trigger "chosen:updated"
      ),500
      agent = this
      compare.pushdata(agent, 'timentp', cfg)
      compare.compare(agent, 'timentp')
#IGMP Snooping Configuartion
ngapp.directive 'igmp', ->
  restrict: 'E'
  templateUrl: 'pages/configs/igmp_conf.html'
  scope: {}
  controller: ($scope, smith, msgbox, compare, $timeout) ->
    compare.init()
    $scope.igmpg = {}
    $scope.old = {}
    smith.emit 'igmp::get_sys_cfg', (sys)->
      $scope.igmpg.sys = sys
      agent = this
      compare.pushdata(agent, 'igmp', sys)
      compare.compare(agent, 'igmp')
    smith.emit 'igmp::get_ports_cfg', (ports)->
      $scope.igmpg.ports = ports
      agent = this
      compare.pushdata(agent, 'igmp', ports)
      compare.compare(agent, 'igmp')
    smith.emit 'igmp::get_entry_igmp_cfg', (vlans)->
      $scope.igmpg.vlans = vlans
      $scope.old = angular.copy $scope.igmpg
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'igmp', vlans)
      compare.compare(agent, 'igmp')
    $scope.doapply = ->
      smith.emit 'igmp::set_sys_cfg', $scope.igmpg.sys
      smith.emit 'igmp::set_ports_cfg', $scope.igmpg.ports
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
      #if not angular.equals( $scope.old.sys, $scope.igmpg.sys)
      #  smith.emit 'igmp::set_sys_cfg', $scope.igmpg.sys
      #if not angular.equals( $scope.old.ports, $scope.igmpg.ports)
      #  smith.emit 'igmp::set_ports_cfg', $scope.igmpg.ports
      #if not angular.equals( $scope.old.vlans, $scope.igmpg.vlans)
      #  smith.emit 'vlan::set_entry_igmp_cfg', $scope.igmpg.vlans
      #msgbox.msgbar_show('Configuration Applied', 'success')       
#Local Syslog
ngapp.directive 'localconf', ->
  restrict: 'E'
  templateUrl: 'pages/configs/systemlog_local_conf.html'
  scope: {}
  controller: ($scope, smith, msgbox, compare, $timeout)->
    compare.init()
    $scope.dosave = ->
      smith.emit 'evact_manager::set_local_cfg', $scope.cfg
      #msgbox.msgbar_show('Configuration Saved', 'success')
      #console.log @cfg
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
    smith.emit 'evact_manager::get_local_cfg', (cfg)->
      $scope.cfg = cfg
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'localconf', cfg)
      compare.compare(agent, 'localconf')
#Remote Syslog
ngapp.directive 'rsyslogconf', ->
  restrict: 'E'
  templateUrl: 'pages/configs/systemlog_rsyslog_conf.html'
  scope: {}
  controller: ($scope, smith, msgbox, compare, $timeout)->
    compare.init()
    $scope.dosave = ->
      smith.emit 'evact_manager::set_remote_cfg', $scope.rsyslog
      #msgbox.msgbar_show('Configuration Saved', 'success')
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
    smith.emit 'evact_manager::get_remote_cfg', (cfg)->
      $scope.rsyslog = cfg
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'rsyslogconf', cfg)
      compare.compare(agent, 'rsyslogconf')
#SysInfo
ngapp.directive 'sysinfo', ->
  restrict: 'E'
  templateUrl: 'pages/configs/sys_info.html'
  controller: ($scope, smith, msgbox, compare, $timeout)->
    compare.init()
    $scope.doapply = ->
      smith.emit 'system::set_sys_cfg', $scope.cfg
      #msgbox.msgbar_show('Configuration Applied', 'success')
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),1000
    smith.emit 'system::get_sys_cfg', (cfg)->
      #just pickup what we need to avoid mis-applying some dangerous keys
      
      cfg = _.pick( cfg, 'name', 'description', 'location', 'contact' )
      $scope.cfg = cfg
      $scope.$apply()
      agent = this
      compare.pushdata(agent, 'sysinfo', cfg)
      compare.compare(agent, 'sysinfo')
#Save Config
ngapp.directive 'savecfg', ->
  restrict: 'E'
  templateUrl: 'pages/configs/system_savecfg.html'
  scope: {}
  controller: ($scope, smith, msgbox, $timeout)->
    d3.selectAll('.lstext').classed 'apply_fail', false
    d3.selectAll('.lstext').classed 'same', false
    d3.selectAll('.lstext').classed 'host', false
    d3.selectAll('.lstext').classed 'diff', false
    $scope.dosave = ->
      smith.emit 'system::all_save_cfg'
      $scope.applying = true
      $timeout (->
        $scope.applying = false
      ),3000
#Config Import/Export
ngapp.directive 'cfgexport', ->
  restrict: 'E'
  templateUrl: 'pages/configs/cfgexport.html'
  scope: {}
  controller: ($scope, smith, msgbox, $timeout)->
    d3.selectAll('.lstext').classed 'apply_fail', false
    d3.selectAll('.lstext').classed 'same', false
    d3.selectAll('.lstext').classed 'host', false
    d3.selectAll('.lstext').classed 'diff', false
    
    $scope.ips = []
    for key, content of window.mr.network_devices_list()
      do (content) ->
        for device in content
          do (device) ->
            console.log key
            console.log content
            console.log device
            if device.family is 'IPv4'
              $scope.ips.push device.address
              $scope.ip = $scope.ips[0]
              if $scope.ips.length > 1
                $scope.muti_ip = true
    $scope.portn = 7000
    
    $scope.export = () ->
      $scope.export_sucessed_ips =[]
      $scope.export_failed_ips = []
      $scope.exporting = true
      window.tftp.stop()
      setTimeout (->
        when_start = (m) ->
          console.log 'client upload start!'
        when_done = (m) ->
          msgbox.msgbar_show 'export complete.', 'success'
          $scope.export_sucessed_ips.push m.stats.remoteAddress
          $scope.exporting = false
          $scope.$apply()
        when_error = (m) ->
          msgbox.msgbar_show 'export error.', 'error'
          $scope.export_failed_ips.push m.stats.remoteAddress
          $scope.exporting = false
        window.tftp.start $scope.ip, $scope.portn, $scope.exportpath, when_start, when_done, when_error
      ), 100
      setTimeout (->
        for agent in window.agent
          do (agent) ->
            if agent.transport?
              remoteip = agent.transport.input.remoteAddress
              exportcfg =
                url: "tftp://#{$scope.ip}:#{$scope.portn}/#{remoteip}.yml"
                action: 'export' 
              msg = ['system::config_access', exportcfg]
              agent.send msg
              #$scope.exporting = true
            else
              return
      ), 300
      
    $scope.import = () ->
      $scope.import_sucessed_ips =[]
      $scope.import_failed_ips = []
      $scope.importing = true
      window.tftp.stop()
      setTimeout (->
        window.tftp.start $scope.ip, $scope.portn, $scope.importpath
      ), 100
      setTimeout (->
        for agent in window.agent
          do (agent) ->
            if agent.transport?
              remoteip = agent.transport.input.remoteAddress
              importcfg =
                url: "tftp://#{$scope.ip}:#{$scope.portn}/#{remoteip}.yml"
                action: 'import'
              callback = (t) ->
                $scope.importing = false
                agent = this
                console.log t
                if t.state is true
                  msgbox.msgbar_show 'import complete.', 'success'
                  if agent.transport.input.remoteAddress?
                    $scope.import_sucessed_ips.push agent.transport.input.remoteAddress
                    $scope.$apply()
                if t.state is false
                  console.log t.err
                  msgbox.msgbar_show 'import error.', 'error'
                  if agent.transport.input.remoteAddress?
                    $scope.import_failed_ips.push agent.transport.input.remoteAddress
                    $scope.$apply()
                
              msg = ['system::config_access', importcfg, callback]
              agent.send msg
            else
              return
      ), 300 
#Firmware Upgrade
ngapp.directive 'firmware', ->
  restrict: 'E'
  templateUrl: 'pages/configs/firmware.html'
  scope: {}
  controller: ($scope, smith, msgbox, $timeout)->
    d3.selectAll('.lstext').classed 'apply_fail', false
    d3.selectAll('.lstext').classed 'same', false
    d3.selectAll('.lstext').classed 'host', false
    d3.selectAll('.lstext').classed 'diff', false
    
    $scope.ips = []
    for key, content of window.mr.network_devices_list()
      do (content) ->
        for device in content
          do (device) ->
            if device.family is 'IPv4'
              $scope.ips.push device.address
              $scope.ip = $scope.ips[0]
              if $scope.ips.length > 1 
                $scope.muti_ip = true
                $scope.ip = $scope.ips[1]
    $scope.portn = 8081
    
    $scope.$watch 'firmwarepath', (n, o) ->
      if n isnt undefined
        extension = n.replace n.slice(0, n.lastIndexOf '.'), ''
        if extension is '.upg'
          console.log 'good file'
        else
          msgbox.msgbar_show 'please select the .upg file', 'error'
    
    $scope.upgrade = () ->
      $scope.sucessed_ips =[]
      $scope.failed_ips = []
      $scope.upgrade_failed = false
      up_path = $scope.firmwarepath.slice(0, $scope.firmwarepath.lastIndexOf '/')
      $scope.remote_path = $scope.firmwarepath.replace up_path, "http://#{$scope.ip}:#{$scope.portn}"
      if $scope.remote_path isnt undefined
        $scope.upgrading = true
        window.fileserver.stop()
        setTimeout (->
          window.fileserver.start $scope.portn, up_path
        ), 100     
        $timeout (->
          smith.emit 'system::upgrade', $scope.remote_path, (r) ->
            $scope.upgrading = false
            console.log $scope.remote_path
            agent = this
            if r.success is true
              msgbox.msgbar_show r.status, 'success'
              $scope.upgrade_success = true
              $timeout (->
                $scope.upgrade_success = false
              ), 200000
              if agent.transport.input.remoteAddress?
                $scope.sucessed_ips.push agent.transport.input.remoteAddress
                $scope.$apply()
            if r.err?
              console.log r.err
              msgbox.msgbar_show 'Upgrade error.', 'error'
              if agent.transport.input.remoteAddress?
                $scope.failed_ips.push agent.transport.input.remoteAddress
                $scope.upgrade_failed = true
                console.log $scope.failed_ips
                $scope.$apply()
            console.log r
                
        ), 5000
        
#directives for enhancement
#buttons enhancementq
ngapp.constant 'buttonConfig', 
  activeClass: 'active'
ngapp.directive "btnCheckbox", ["buttonConfig", (buttonConfig) ->
  activeClass = buttonConfig.activeClass or "active"
  require: "ngModel"
  link: (scope, element, attrs, ngModelCtrl) ->
    trueValue = scope.$eval(attrs.btnCheckboxTrue) or true
    falseValue = scope.$eval(attrs.btnCheckboxTrue) or false
    scope.$watch (->
      ngModelCtrl.$modelValue
    ), (modelValue) ->
      if angular.equals(modelValue, trueValue)
        element.addClass activeClass
      else
        element.removeClass activeClass
    element.bind "click", ->
      scope.$apply ->
        ngModelCtrl.$setViewValue (if element.hasClass(activeClass) then falseValue else trueValue)
]
ngapp.directive "btnRadio", ["buttonConfig", (buttonConfig) ->
  activeClass = buttonConfig.activeClass or "active"
  require: "ngModel"
  link: (scope, element, attrs, ngModelCtrl) ->
    value = scope.$eval(attrs.btnRadio)
    scope.$watch (->
      ngModelCtrl.$modelValue
    ), (modelValue) ->
      if angular.equals(modelValue, value)
        element.addClass activeClass
      else
        element.removeClass activeClass
    element.bind "click", ->
      unless element.hasClass(activeClass)
        scope.$apply ->
          ngModelCtrl.$setViewValue value
]
ngapp.directive "inputFile", ->
  require: "ngModel"
  restrict: 'E'
  replace: false
  template: '<div class="form-group"><input type="file" name="uploader" style="display:none;"><button class="fake-uploader">Selet File</button></div>'
  #onchange="angular.element(this).scope().sendFile(this)
  link: (scope, ele, attrs, ngModelCtrl) ->
    muti = attrs.multiple
    nwdirectory = attrs.nwdirectory
    classes = attrs.class
    value = attrs.value
    if muti? then ele.find('input[type="file"]').attr 'multiple',''
    if nwdirectory? then ele.find('input[type="file"]').attr 'nwdirectory',''
    if value? then ele.find('.fake-uploader').text value
    if classes?
      ele.find('.fake-uploader').addClass classes
      ele.removeClass classes
    ele.find('.fake-uploader').click ->
      ele.find('input[type="file"]').click()
    ele.find('input[type="file"]').bind 'change', ->
      filepath = ele.find('input[type="file"]').val()
      scope.$apply ->
        ngModelCtrl.$setViewValue filepath
#others
ngapp.directive 'clsbool', ->
  (scope, ele, attr)->
    vname=attr.clsbool
    if attr.clsbool.indexOf('.')<0
      vname="#{attr.clsbool}.#{ele[0].id}"
    ele.addClass attr.offcls
    scope.$watch vname, (newVal, oldVal) ->
      return if newVal==oldVal
      if newVal
        [ncls, pcls] = [attr.oncls, attr.offcls]
      else
        [ncls, pcls] = [attr.offcls, attr.oncls]
      ele.removeClass pcls
      ele.addClass ncls
ngapp.directive 'digit', ->
  restrict: 'A'
  link: ($scope, ele) ->
    ele.bind 'keypress', (e)->
      c= String.fromCharCode(e.which)
      return false if c not in "0123456789"
ngapp.directive 'csvnum', ->
  restrict: 'A'
  require: 'ngModel'
  link: ($scope, ele, attrs, ctrl) ->
    ctrl.$render = ->
      value = ctrl.$viewValue
      ele.val value.join(',')
    ctrl.$parsers.push (s )->
      nums = (Number vs for vs in s.split(',') when Number(vs))
    ele.bind 'keypress', (e)->
      c= String.fromCharCode(e.which)
      return false if c not in "0123456789, "
ngapp.directive 'vldfmt', ->
  #require jquery.validate and additional-methods
  #see http://docs.angularjs.org/guide/forms for 'Custom Validation'
  restrict: 'A'
  require: 'ngModel'
  link: (scope, elm, attrs, ctrl) ->
    m = attrs.vldfmt
    validateFn = (val) ->
      if val
        ctx = { optional: (ele)->false}
        isValid = $.validator.methods[m].call ctx, val
      else
        isValid = true
      ctrl.$setValidity m, isValid
      return if isValid then val else undefined
    ctrl.$formatters.push validateFn
    ctrl.$parsers.push validateFn
ngapp.directive "ngBlur", ->
  restrict: "A"
  require: "ngModel"
  scope: {}
  link: (scope, el, attrs, ctrl) ->
    el.on "focus", () ->
      scope.$apply ->
        ctrl.$blurred = false
    el.on "blur", () ->
      scope.$apply ->
        ctrl.$blurred = true
gui.Window.get().show()