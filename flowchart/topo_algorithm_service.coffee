angular.module("topo", []).factory( "d3", [ () ->
  d3
]).factory( "topoAlgorithm", ["d3", "flowchartDataModel", (d3, flowchartDataModel) ->
  preProcess: (raw, cb, mode) ->
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
    enhanced_equlink = (lka, lkb) ->
      (lka.nodepair[0]==lkb.nodepair[0] and lka.nodepair[1]==lkb.nodepair[1] and lka.blocked is lkb.blocked) or (lka.nodepair[0]==lkb.nodepair[1] and lka.nodepair[1]==lkb.nodepair[0] and lka.blocked is lkb.blocked)
    for d in raw
      do (d) ->
        if d.node?
          o =
            mac: d.node.local_id
            ip: d.node.local_ip_address
            location: d.node.sys_location
            name: d.node.sys_name
            rings:[]
          gnodes.push o
    for d in raw
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
    for d in raw
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
    links = []
    for n,i in gnodes
      n.id = i
      n.inputConnectors = []
      n.outputConnectors = []
    for l in glinks
      links.push
        source: gnodes[l.nodepair[0]]
        target: gnodes[l.nodepair[1]]
        dest: {}
        sourceport: l.portpair[0]
        targetport: l.portpair[1]
    final =
      nodes: gnodes
      rings: grings
    final.links = links

    data = {}
    #console.log nodes_w_pos
    for link in final.links
      if link.sourceport >6
        final.nodes[final.nodes.indexOf(link.source)].outputConnectors.push
          name: link.sourceport
      if link.sourceport <6 or link.sourceport is 6
        final.nodes[final.nodes.indexOf(link.source)].inputConnectors.push
          name: link.sourceport
      if link.targetport >6
        final.nodes[final.nodes.indexOf(link.target)].outputConnectors.push
          name: link.targetport
      if link.targetport <6 or link.targetport is 6
        final.nodes[final.nodes.indexOf(link.target)].inputConnectors.push
          name: link.targetport
    for link in final.links
      link.source.nodeID = link.source.id
      #link.source.connectorIndex = link.sourceport
      link.dest.nodeID = link.target.id
    #link.dest.connectorIndex = link.targetport
    data.nodes = final.nodes
    data.connections = final.links
    if mode is 'noPos'
      cb(data)
    else
      @processPosdata(data, cb)
  processPosdata: (data, cb) ->
    that = @
    did_not_call = true
    width = flowchartDataModel.width
    height = flowchartDataModel.height
    force = d3.layout.force().nodes(data.nodes).links(data.connections)
      .charge(-4800)
      .linkDistance(120)
      .size([width, height])
      .gravity(0.25)
      .on 'tick', (a)->
        if a.alpha < 0.0367 and did_not_call is true
          did_not_call = false
          force.nodes().forEach (o, i) ->
            o.x = o.x * 1.5 - 350
            o.y = o.y * 0.6 + 30

          force.nodes().forEach (o, i) ->
            if o.x < 30
              o.x = 50
            if o.x > (width-250)
              o.x = width-250
            if o.y < 30
              o.y = 50
            if o.y > (height-150)
              o.y = height-150
          that.finalize(force.nodes(),force.links(),cb)
          force.stop()
    n = 100
    force.start()
    i = 0
    while i < n
      force.tick()
      ++i
    force.stop()
  finalize:(nodes_w_pos, links_w_pos, cb) ->
    data =
      nodes: nodes_w_pos
      connections: links_w_pos
    cb(data)
])