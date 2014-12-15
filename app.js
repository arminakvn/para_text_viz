// Includes classess for extendeing leaflet to d3 and d3 to paratext
(function() {
  var addChainedAttributeAccessor, draw,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  // extending d3 to leaflet, codes is by https://github.com/calvinmetcalf/leaflet.d3
  L.D3 = L.Class.extend({
    includes: L.Mixin.Events,
    options: {
      type: "json",
      topojson: false,
      pathClass: "path"
    },
    initialize: function(data, options) {
      var _this;
      _this = this;
      L.setOptions(_this, options);
      _this._loaded = false;
      if (typeof data === "string") {
        d3[_this.options.type](data, function(err, json) {
          if (err) {
            return;
          } else {
            if (_this.options.topojson) {
              _this.data = topojson.object(json, json.objects[_this.options.topojson]);
            } else if (L.Util.isArray(json)) {
              _this.data = {
                type: "FeatureCollection",
                features: json
              };
            } else {
              _this.data = json;
            }
            _this._loaded = true;
            _this.fire("dataLoaded");
          }
        });
      } else {
        if (_this.options.topojson) {
          _this.data = topojson.object(data, data.objects[_this.options.topojson]);
        } else if (L.Util.isArray(data)) {
          _this.data = {
            type: "FeatureCollection",
            features: data
          };
        } else {
          _this.data = data;
        }
        _this._loaded = true;
        _this.fire("dataLoaded");
      }
    },
    onAdd: function(map) {
      this._map = map;
      this._project = function(x) {
        var point;
        point = map.latLngToLayerPoint(new L.LatLng(x[1], x[0]));
        return [point.x, point.y];
      };
      this._el = d3.select(this._map.getPanes().overlayPane).append("svg");
      this._g = this._el.append("g").attr("class", (this.options.svgClass ? this.options.svgClass + " leaflet-zoom-hide" : "leaflet-zoom-hide"));
      if (this._loaded) {
        this.onLoaded();
      } else {
        this.on("dataLoaded", this.onLoaded, this);
      }
      this._popup = L.popup();
      this.fire("added");
    },
    addTo: function(map) {
      map.addLayer(this);
      return this;
    },
    onLoaded: function() {
      this.bounds = d3.geo.bounds(this.data);
      this.path = d3.geo.path().projection(this._project);
      if (this.options.before) {
        this.options.before.call(this, this.data);
      }
      this._feature = this._g.selectAll("path").data((this.options.topojson ? this.data.geometries : this.data.features)).enter().append("path").attr("class", this.options.pathClass);
      this._map.on("viewreset", this._reset, this);
      this._reset();
    },
    onRemove: function(map) {
      this._el.remove();
      map.off("viewreset", this._reset, this);
    },
    _reset: function() {
      var bottomLeft, topRight;
      bottomLeft = this._project(this.bounds[0]);
      topRight = this._project(this.bounds[1]);
      this._el.attr("width", topRight[0] - bottomLeft[0]).attr("height", bottomLeft[1] - topRight[1]).style("margin-left", bottomLeft[0] + "px").style("margin-top", topRight[1] + "px");
      this._g.attr("transform", "translate(" + -bottomLeft[0] + "," + -topRight[1] + ")");
      this._feature.attr("d", this.path);
    },
    bindPopup: function(content) {
      this._popup = L.popup();
      this._popupContent = content;
      if (this._map) {
        this._bindPopup();
      }
      this.on("added", (function() {
        this._bindPopup();
      }), this);
    },
    _bindPopup: function() {
      var _this;
      _this = this;
      _this._g.on("click", (function() {
        var props;
        props = d3.select(d3.event.target).datum().properties;
        if (typeof _this._popupContent === "string") {
          _this.fire("pathClicked", {
            cont: _this._popupContent
          });
        } else if (typeof _this._popupContent === "function") {
          _this.fire("pathClicked", {
            cont: _this._popupContent(props)
          });
        }
      }), true);
      _this.on("pathClicked", function(e) {
        _this._popup.setContent(e.cont);
        _this._openable = true;
      });
      _this._map.on("click", function(e) {
        if (_this._openable) {
          _this._openable = false;
          _this._popup.setLatLng(e.latlng).openOn(_this._map);
        }
      });
    }
  });

  L.d3 = function(data, options) {
    return new L.D3(data, options);
  };




  // class paratext, parallax text based on the idea of a parallax!
  d3.paratext = (function(_super) {
    __extends(paratext, _super);

    function paratext() {
      this.makeMap = __bind(this.makeMap, this);
      var attr;
      this.properties = {
        id: 0,
        text: '',
        members: [],
        _margin: {
          t: 200,
          l: 300,
          b: 300,
          r: 300
        },
        relations: {},
        lat: 0,
        long: 0
      };
      for (attr in this.properties) {
        addChainedAttributeAccessor(this, 'properties', attr);
      }
      console.log("this", this);
      console.log("L", L);
    }

    paratext.prototype.getD3 = function() {
      this._count = 0;
      this._canvas = $(".canvas");
      this._width = this._canvas.width() - this.properties._margin.l - this.properties._margin.r;
      this._height = this._canvas.height() - this.properties._margin.t - this.properties._margin.b;
      this._svg = d3.select(".canvas").append("svg").attr("width", this._width + this.properties._margin.l + this.properties._margin.r).attr("height", this._height + this.properties._margin.t + this.properties._margin.b).append("g").attr("transform", "translate(" + this.properties._margin.l + "," + this.properties._margin.t + ")");
      this._svg.selectAll("text").data(this.properties.text).enter().append("text").attr("width", 2400).attr("height", 200).style("font-family", "Impact").attr("fill", "black").text(function(d) {
        return d.description;
      }).on("mouseover", function() {
        d3.select(this).transition().duration(300).style("fill", "gray");
      }).on("mouseout", function() {
        d3.select(this).transition().duration(300).style("fill", "black");
      }).transition().delay(0).duration(1).each("start", function() {
        d3.select(this).transition().duration(1).attr("y", (this._count + 1) * 30);
        this._count = this._count + 1;
      }).transition().duration(11).delay(1).style("opacity", 1);
      this._count = this._count + 1;
      return this._svg;
    };

    paratext.prototype.makeMap = function() {
      var stamenAttribution, stamenWaterColor, tiles;
      this._m = new L.map("map").setView([42.08, -71.64], 8);
      stamenAttribution = "Map tiles by <a href=\"http://stamen.com\">Stamen Design</a>, <a href=\"http://creativecommons.org/licenses/by/3.0\">CC BY 3.0</a> &mdash; " + "Map data &copy; <a href=\"http://openstreetmap.org\">OpenStreetMap</a> contributors, <a href=\"http://creativecommons.org/licenses/by-sa/2.0/\">CC-BY-SA</a>";
      tiles = L.layerGroup([
        L.tileLayer("http://{s}.tile.stamen.com/terrain-background/{z}/{x}/{y}.jpg", {
          minZoom: 4,
          maxZoom: 18
        }), L.tileLayer("http://{s}.tile.stamen.com/terrain-lines/{z}/{x}/{y}.png", {
          minZoom: 4,
          maxZoom: 12,
          attribution: stamenAttribution
        })
      ]).addTo(this._m);
      stamenWaterColor = L.tileLayer("http://{s}.tile.stamen.com/watercolor/{z}/{x}/{y}.jpg", {
        minZoom: 3,
        maxZoom: 16,
        attribution: stamenAttribution
      });
      L.control.layers({
        "Stamen Terrain": tiles,
        "Stamen Watercolors": stamenWaterColor
      }, {
        collapsed: false
      }).addTo(this._m);
      return this._m;
    };

    paratext.prototype.connectRelation = function() {
      return this.raw_text = this.properties.text;
    };

    return paratext;

  })(L.D3);

  addChainedAttributeAccessor = function(obj, propertyAttr, attr) {
    return obj[attr] = function() {
      var newValues;
      newValues = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (newValues.length === 0) {
        return obj[propertyAttr][attr];
      } else {
        obj[propertyAttr][attr] = newValues[0];
        return obj;
      }
    };
  };


// this is where the application code happens for an example text
  queue().defer(d3.csv, "ccn_18062014_sample.csv").await(function(err, texts) {
    draw(texts);
  });

  draw = function(data) {
    var $texts, count, d, d3text, map, para, texts;
    count = 0;
    para = new d3.paratext().text(data);
    d = para.getD3();
    d3text = d3.select("body").append("svg").attr("width", 1800).attr("height", 1200).append("g").selectAll("text");
    d3text.data(para.properties.text).enter().append("text").attr("width", 2400).attr("height", 200).style("font-family", "Impact").attr("fill", "black").text(function(d) {
      return d.description;
    }).on("mouseover", function() {
      d3.select(this).transition().duration(300).style("fill", "gray");
    }).on("mouseout", function() {
      d3.select(this).transition().duration(300).style("fill", "black");
    }).transition().delay(0).duration(1).each("start", function() {
      d3.select(this).transition().duration(1).attr("y", (count + 1) * 30);
      count = count + 1;
    }).transition().duration(11).delay(1).style("opacity", 1);
    count = count + 1;
    para.id(count);
    map = $("body").append("<div id='map'></div>");
    // map is built in to the class itself
    para.makeMap();
    $("body").append(para._m);
    texts = d3.selectAll("text");
    // jquery object made with data from d3
    // gets it with jquery and handle the interactions
    $texts = $(texts[0]);
    $texts.each(function() {
      $(this).data("datum", $(this).prop("__data__"));
    });
    $texts.on("click", function() {
      return para._m.setView(new L.LatLng(this.__data__.lat, this.__data__.long), 16);
    });
  };

}).call(this);
