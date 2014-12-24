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
  
  
               #val for key, val of d # new L.LatLng(d.lat, d.long)
  removeAnyLocation: ->
    d3.select(@_m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
    .data([]).exit().remove()

  setViewByLocation: (d)-> 
    @_m.setView(new L.LatLng(d.lat, d.long), 19, animation: true, duration: 50)

  showLocation: (d) ->
    featureData =[]
    featureData.push new L.LatLng(d.lat, d.long)
    @_g = d3.select(@_m.getPanes().overlayPane).select(".leaflet-zoom-animated").selectAll("g")
    @_g.data(featureData).enter().append("g").append("circle").attr("r", 0
    ).attr("stroke", "white"
    ).attr("fill", "none"
    ).attr("stroke-width", "10"
    ).attr("cx", (d) =>
      return @_m.latLngToLayerPoint(d).x
    ).attr("cy", (d) =>
      return @_m.latLngToLayerPoint(d).y
    ).transition().delay(120).duration(1000).attr("r", 80
    ).attr("stroke", "gray"
    ).attr("stroke-width", "0"
    ).attr("fill", "none")

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
      42.34
      -71.12
    ], 13)
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
        @_el = L.DomUtil.create('svg', 'svg')
        @_m.getPanes().overlayPane.appendChild(@_el)
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
        .append("ul").style("list-style-type", "none").style("padding-left", "0px")
        .attr("width", $(@_m.getContainer())[0].clientWidth/3 )
        .attr("height", $(@_m.getContainer())[0].clientHeight-80)
        @_d3li = @_d3text
        .selectAll("li")
        .data(@text)
        .enter()
        .append("li")
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
          timeout = undefined
          L.DomEvent.addListener @_leafletli, 'click', (e) ->
            e.stopPropagation()
            _this.removeAnyLocation()
            _this.setViewByLocation(d)
            _this.showLocation(d)
             # showLocation(d)
          L.DomEvent.addListener @_leafletli, 'mouseout', (e) ->
            timeout = 0
            e.stopPropagation()
            # _this.removeAnyLocation()

          L.DomEvent.addListener @_leafletli, 'mouseover', (e) ->
            $(this).css('cursor','pointer')
            e.stopPropagation()
            timeout = setTimeout(->
              _this._m._initPathRoot()
              if timeout isnt 0 
                _this.removeAnyLocation()
                _this.showLocation(d)
                timeout = 0
            , 200)
            return 
          , ->
            return
          d.description   
        )
        .style("font-size", "16px")
        .style("color", "rgb(72,72,72)" )
        .on("mouseover", (d,i) ->
          $(this).css('cursor','pointer')
          d3.select(this).transition().duration(0).style("color", "black").style("background-color", "rgb(208,208,208) ").style "opacity", 1
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


