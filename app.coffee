# leaflet + d3 http://calvinmetcalf.github.com/leaflet.d3/

L.D3 = L.Class.extend(
  includes: L.Mixin.Events
  options:
    type: "json"
    topojson: false
    pathClass: "path"

  initialize: (data, options) ->
    _this = this
    L.setOptions _this, options
    _this._loaded = false
    if typeof data is "string"
      d3[_this.options.type] data, (err, json) ->
        if err
          return
        else
          if _this.options.topojson
            _this.data = topojson.object(json, json.objects[_this.options.topojson])
          else if L.Util.isArray(json)
            _this.data =
              type: "FeatureCollection"
              features: json
          else
            _this.data = json
          _this._loaded = true
          _this.fire "dataLoaded"
        return

    else
      if _this.options.topojson
        _this.data = topojson.object(data, data.objects[_this.options.topojson])
      else if L.Util.isArray(data)
        _this.data =
          type: "FeatureCollection"
          features: data
      else
        _this.data = data
      _this._loaded = true
      _this.fire "dataLoaded"
    return

  onAdd: (map) ->
    @_map = map
    @_project = (x) ->
      point = map.latLngToLayerPoint(new L.LatLng(x[1], x[0]))
      [
        point.x
        point.y
      ]

    @_el = d3.select(@_map.getPanes().overlayPane).append("svg")
    @_g = @_el.append("g").attr("class", (if @options.svgClass then @options.svgClass + " leaflet-zoom-hide" else "leaflet-zoom-hide"))
    if @_loaded
      @onLoaded()
    else
      @on "dataLoaded", @onLoaded, this
    @_popup = L.popup()
    @fire "added"
    return

  addTo: (map) ->
    map.addLayer this
    this

  onLoaded: ->
    @bounds = d3.geo.bounds(@data)
    @path = d3.geo.path().projection(@_project)
    @options.before.call this, @data  if @options.before
    @_feature = @_g.selectAll("path").data((if @options.topojson then @data.geometries else @data.features)).enter().append("path").attr("class", @options.pathClass)
    @_map.on "viewreset", @_reset, this
    @_reset()
    return

  onRemove: (map) ->
    
    # remove layer's DOM elements and listeners
    @_el.remove()
    map.off "viewreset", @_reset, this
    return

  _reset: ->
    bottomLeft = @_project(@bounds[0])
    topRight = @_project(@bounds[1])
    @_el.attr("width", topRight[0] - bottomLeft[0]).attr("height", bottomLeft[1] - topRight[1]).style("margin-left", bottomLeft[0] + "px").style "margin-top", topRight[1] + "px"
    @_g.attr "transform", "translate(" + -bottomLeft[0] + "," + -topRight[1] + ")"
    @_feature.attr "d", @path
    return

  bindPopup: (content) ->
    @_popup = L.popup()
    @_popupContent = content
    @_bindPopup()  if @_map
    @on "added", (->
      @_bindPopup()
      return
    ), this
    return

  _bindPopup: ->
    _this = this
    _this._g.on "click", (->
      props = d3.select(d3.event.target).datum().properties
      if typeof _this._popupContent is "string"
        _this.fire "pathClicked",
          cont: _this._popupContent

      else if typeof _this._popupContent is "function"
        _this.fire "pathClicked",
          cont: _this._popupContent(props)

      return
    ), true
    _this.on "pathClicked", (e) ->
      _this._popup.setContent e.cont
      _this._openable = true
      return

    _this._map.on "click", (e) ->
      if _this._openable
        _this._openable = false
        _this._popup.setLatLng(e.latlng).openOn _this._map
      return

    return
)
L.d3 = (data, options) ->
  new L.D3(data, options)

##############
L.ParaText = L.Class.extend(
  initialize: (@text) ->
    @properties=
        id: 0
        members: []
        _margin: 
          t: 20
          l: 30
          b: 30
          r: 30
        relations: {}
        lat: 0
        long: 0
    return
  # addChainedAttributeAccessor(this, 'properties', attr) for attr of @properties
  addTo: (map) ->
    map.addLayer this
    this

  getD3: ->
    @_count = 0
    @_canvas = $(".canvas")
    @_width = @_canvas.width() - @properties._margin.l - @properties._margin.r
    @_height = @_canvas.height() - @properties._margin.t - @properties._margin.b
    @_svg = d3.select(".").append("svg").attr("width", @_width + @properties._margin.l + @properties._margin.r).attr("height", @_height + @properties._margin.t + @properties._margin.b).append("g").attr("transform", "translate(" + @properties._margin.l + "," + @properties._margin.t + ")")
    @_svg.selectAll("text").data(@properties.text).enter().append("text").attr("width", 2400).attr("height", 200)
    .style("font-family", "Impact").attr("fill", "black").text((d) ->
      d.description
    ).on("mouseover", ->
      d3.select(this).transition().duration(300).style "fill", "gray"
      # 
      return
    ).on("mouseout", ->
      d3.select(this).transition().duration(300).style "fill", "black"
      return
    ).transition().delay(0).duration(1).each("start", ->
      d3.select(this).transition().duration(1).attr "y", ((@_count + 1) * 30)
      @_count = @_count + 1
      return
    ).transition().duration(11).delay(1).style "opacity", 1
    @_count = @_count + 1
    return @_svg
  
  makeMap: ->
    map = $("body").append("<div id='map'></div>")
    L.mapbox.accessToken = "pk.eyJ1IjoiYXJtaW5hdm4iLCJhIjoiSTFteE9EOCJ9.iDzgmNaITa0-q-H_jw1lJw"
    @_m = L.mapbox.map("map", "arminavn.ib1f592g",
      zoomAnimation: true
      zoomAnimationThreshold: 4
      inertiaDeceleration: 4000
      animate: true
      duration: 1.75
      easeLinearity: 0.1
      ).setView([
      42.3
      -71.5
    ], 9)
    # @_m.dragging.disable()
    @_m.boxZoom.enable()
    @_m.scrollWheelZoom.disable()
    textControl = L.Control.extend(
      options:
        position: "topleft"
      onAdd: (map) =>
        @_m = map  
          # create the control container with a particular class name

        @_textDomEl = L.DomUtil.create('div', 'container paratext-info')
        # @_textDomEl_innerdiv = L.DomUtil.create('div', 'container paratext-info', 'container paratext-info')
        L.DomUtil.enableTextSelection(@_textDomEl)  
        @_m.getPanes().overlayPane.appendChild(@_textDomEl)
        @_textDomObj = $(L.DomUtil.get(@_textDomEl))
        @_textDomObj.css('width', $(@_m.getContainer())[0].clientWidth/3)
        @_textDomObj.css('height', $(@_m.getContainer())[0].clientHeight)
        @_textDomObj.css('background-color', 'white')
        @_textDomObj.css('overflow', 'scroll')
        L.DomUtil.setOpacity(L.DomUtil.get(@_textDomEl), 0.8)
        # here it needs to check to see if there is any vewSet avalable if not it should get it from the lates instance or somethign
        @_viewSet = @_m.getCenter() if @_viewSet is undefined
        L.DomUtil.setPosition(L.DomUtil.get(@_textDomEl), L.point(40, -65), disable3D=0)
        @_d3text = d3.select(".paratext-info")
        # .append("svg")
        # .attr("width", $(@_m.getContainer())[0].clientWidth/3 )
        # .attr("height", $(@_m.getContainer())[0].clientHeight-20)
        .append("ul").style("list-style-type", "none").style("padding-left", "0px")
        .attr("width", $(@_m.getContainer())[0].clientWidth/3 )
        .attr("height", $(@_m.getContainer())[0].clientHeight-80)
        @_d3li = @_d3text
        .selectAll("li")
        .data(@text)
        .enter()
        .append("li")
        # .attr("width", $(@_m.getContainer())[0].clientWidth/3)
        # .attr("height", $(@_m.getContainer())[0].clientHeight-20)
        @_d3li.style("font-family", "Helvetica")
        .style("line-height", "2")
        .style("margin-top", "10px")
        .style("padding-right", "20px")
        .style("padding-left", "40px")
        .attr("id", (d, i) =>
           "line-#{i}" 
          )
        .text((d,i) =>
          @_leafletli = L.DomUtil.get("line-#{i}")
          # L.DomEvent.addListener(@_leafletli, 'mouseover', (e) ->
          #   _this._m.setView(new L.LatLng(d.lat, d.long), 19, animation: true)
          #   console.log "leaflet listerner"
          #   return
          # )
          timeout = undefined
          L.DomEvent.addListener @_leafletli, 'mouseover', (e) ->
            $(this).css('cursor','pointer')
            timeout = setTimeout(->
              # console.log _this
              _this._m.setView(new L.LatLng(d.lat, d.long), 18, animation: true)
              # paratext._m.panBy(10, 10, animation: true)   
            # do stuff on hover
            , 500)
            return
          , ->
            timeout = setTimeout(->
              # console.log _this
              _this._m.setView(new L.LatLng(d.lat, d.long), 19, animation: true)
              # paratext._m.panBy(10, 10, animation: true)   
            # do stuff on hover
            , 1000)
            return
          , ->
            clearTimeout timeout
            return
          d.description   
        )
        .style("font-size", "16px")
        .style("color", "rgb(72,72,72)" )
        .on("mouseover", (d,i) ->
          $(this).css('cursor','pointer')
          d3.select(this).transition().duration(0).style("color", "black").style("background-color", "rgb(208,208,208) ").style "opacity", 1
          # @_leafletli = L.DomUtil.get(this)
          # L.DomEvent.addListener(this, 'mouseover', (e) ->
          #   console.log "e"
          #   return
          # )
  
          return 
        ).on("mouseout", (d,i) ->
          d3.select(this).transition().duration(1000).style("color", "rgb(72,72,72)").style("background-color", "white").style "opacity", 1
          return
        )  
        .transition().duration(1).delay(1).style("opacity", 1)
        @_m.whenReady =>
          # console.log "@_d3li", @_d3li
          # console.log "@_d3text", @_d3text
        
        @_textDomEl
      onSetView: (map) =>
        @_m = map


    )

    @_m.addControl new textControl()
  
    return @_m

  connectRelation: ->
    @raw_text = @properties.text
  )
L.paratext = (text) ->
  new L.ParaText(text)

addChainedAttributeAccessor = (obj, propertyAttr, attr) ->
    obj[attr] = (newValues...) ->
        if newValues.length == 0
            obj[propertyAttr][attr]
        else
            obj[propertyAttr][attr] = newValues[0]
            obj

##########
#################
queue().defer(d3.csv, "ccn_18062014_data.csv").await (err, texts) ->
  draw texts
  return

draw = (data) ->
  paratext = L.paratext(data)
  textmap = paratext.makeMap()
  texts = d3.selectAll("li")

  # bding the L.D3 to jQuery and assiging data from and to datum
  $texts = $(texts[0])
  $texts.each ->
    $(this).data "datum", $(this).prop("__data__")
    return
  # jQuery handles the clicks
  timeout = undefined
  # $texts.hover (->
  #   $(this).css('cursor','pointer')
  #   timeout = setTimeout(=>
  #     paratext._m.setView(new L.LatLng(@__data__.lat, @__data__.long), 19, animation: true)
  #     # paratext._m.panBy(10, 10, animation: true)   
  #   # do stuff on hover
  #   , 500)
  #   return
  # ), ->
  #   clearTimeout timeout
  #   return
  # $texts.on "mouseout", ->
  #   $(this).css('cursor','default')
  #   # paratext._m.setView(new L.LatLng(@__data__.lat, @__data__.long), 1)
  # return

