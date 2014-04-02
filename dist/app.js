(function() {
  var Freckle, colors,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Freckle = (function() {
    var Cache, Entry, Project, User;

    Cache = (function() {
      function Cache() {}

      Cache.prototype.store = window.localStorage;

      Cache.prototype.clear = function() {
        return this.store.clear();
      };

      Cache.prototype.set = function(key, value) {
        value = typeof value !== String ? JSON.stringify(value) : void 0;
        return this.store.setItem(key, value);
      };

      Cache.prototype.get = function(key) {
        return JSON.parse(this.store.getItem(key));
      };

      Cache.prototype.initialize = function(options) {
        this.options = options;
      };

      return Cache;

    })();

    Project = (function() {
      function Project(parent, method) {
        this.parent = parent;
        this.method = method;
      }

      Project.prototype.index = function(params) {
        this.params = params;
        return this.parent.api({
          url: this.parent.url() + ("/" + this.method + ".json"),
          method: this.method,
          callback: this.params.success
        });
      };

      return Project;

    })();

    Entry = (function() {
      function Entry(parent, method) {
        this.parent = parent;
        this.method = method;
      }

      Entry.prototype.search = function(params) {
        var _ref, _ref1, _ref2;
        this.params = params;
        return this.parent.api({
          url: this.parent.url() + ("/" + this.method + ".json"),
          method: this.method,
          data: {
            "search[projects]": (_ref = this.params.projects) != null ? _ref.join(",") : void 0,
            "search[tags]": (_ref1 = this.params.tags) != null ? _ref1.join(",") : void 0,
            "search[billable]": this.params.billable,
            "search[to]": this.params.to,
            "search[from]": this.params.from,
            "search[people]": (_ref2 = this.params.people) != null ? _ref2.join(",") : void 0
          },
          callback: this.params.success
        });
      };

      return Entry;

    })();

    User = (function() {
      function User(parent, method) {
        this.parent = parent;
        this.method = method;
      }

      User.prototype.self = function(params) {
        this.params = params;
        return this.parent.api({
          url: this.parent.url() + ("/" + this.method + "/self"),
          method: this.method,
          callback: this.params.success
        });
      };

      return User;

    })();

    Freckle.prototype.url = function() {
      return "http://www.corsproxy.com/" + this.options.subdomain + ".letsfreckle.com/api";
    };

    Freckle.prototype.api = function(options) {
      var maxCacheAge, requestIdentifier, timeDelta, timestamp,
        _this = this;
      requestIdentifier = "" + this.options.token + "." + options.method + (options.data != null ? '.' + $.param(options.data) : '');
      timestamp = this._cache.get("" + requestIdentifier + ".timestamp");
      timeDelta = Date.now() - timestamp;
      maxCacheAge = 1000 * 60 * 10;
      if ((timestamp != null) && !(timeDelta > maxCacheAge)) {
        console.log("" + options.method + ":cache:hit", "aged " + (timeDelta / 1000) + "s");
        return options.callback.call(this, this._cache.get("" + requestIdentifier + ".response"));
      } else {
        console.log("" + options.method + ":cache:miss", "aged " + (timeDelta / 1000) + "s");
        return $.ajax({
          url: options.url,
          data: $.extend({}, options.data, {
            token: this.options.token
          }),
          success: function(response, status, xhr) {
            _this._cache.set("" + requestIdentifier + ".response", response);
            _this._cache.set("" + requestIdentifier + ".timestamp", Date.now());
            return options.callback.apply(_this, arguments);
          }
        });
      }
    };

    function Freckle(options) {
      this.options = options;
      this.projects = new Project(this, "projects");
      this.entries = new Entry(this, "entries");
      this.users = new User(this, "users");
      this._cache = new Cache;
    }

    return Freckle;

  })();

  Backbone.Marionette.Renderer.render = function(template, data) {
    if (!JST[template]) {
      throw "Template " + template + " not found!";
    }
    return JST[template](data);
  };

  window.Mole = new Backbone.Marionette.Application();

  Mole.addInitializer(function() {
    var _this = this;
    this.vent.on("authentication:success", function() {
      _this.Calendar.start();
      return $(".modal-view").transit({
        opacity: 0
      }, function() {
        return $(".modal-view").empty();
      });
    });
    return this.Authentication.start();
  });

  Mole.module("Authentication", function(Module, App) {
    var Auth, User, _ref, _ref1,
      _this = this;
    this.startWithParent = false;
    User = (function(_super) {
      __extends(User, _super);

      function User() {
        _ref = User.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      User.prototype.parse = function(response) {
        return response.user;
      };

      return User;

    })(Backbone.Model);
    Auth = (function(_super) {
      __extends(Auth, _super);

      function Auth() {
        _ref1 = Auth.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      Auth.prototype.defaults = {
        subdomain: "railslove",
        token: "jagzeek0wsnfmnfhuntigxv3be6qqc3"
      };

      Auth.prototype.schema = {
        subdomain: {
          type: "Text",
          validators: ['required']
        },
        token: {
          type: 'Select',
          options: ['jagzeek0wsnfmnfhuntigxv3be6qqc3', 'plopzlx1l1tvr5bqhi2j59lqe5q2v5u'],
          validators: ['required']
        }
      };

      Auth.prototype.validate = function() {
        if (!(this.get("subdomain") && this.get("token"))) {
          return "Missing subdomain or token";
        }
      };

      return Auth;

    })(Backbone.Model);
    return this.addInitializer(function() {
      var form, init;
      init = function() {
        var _this = this;
        App.freckle = new Freckle({
          subdomain: App.auth.get("subdomain"),
          token: App.auth.get("token")
        });
        return App.freckle.users.self({
          success: function(data) {
            App.user = new User(data, {
              parse: true
            });
            return App.vent.trigger("authentication:success");
          }
        });
      };
      App.auth = new Auth;
      if (App.auth.isValid()) {
        return init();
      } else {
        form = new Backbone.Form({
          model: App.auth
        });
        form.render();
        $(".modal-view").html(form.el);
        return form.$el.on("submit", function(e) {
          e.preventDefault();
          if (form.commit() === void 0 && App.auth.isValid()) {
            return init();
          }
        });
      }
    });
  });

  colors = ["#b0beda", "#cab5da", "#d8b5c8", "#d8c3b3", "#d1dab3", "#b0dab5", "#b0dad6"];

  Mole.module("Calendar", function(Module, App) {
    var Day, DayCollection, DayCompositeView, DayListView, Entry, EntryCollection, EntryItemView, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6,
      _this = this;
    this.startWithParent = false;
    Entry = (function(_super) {
      __extends(Entry, _super);

      function Entry() {
        _ref = Entry.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Entry.prototype.defaults = {
        formatted_description: ""
      };

      Entry.prototype.parse = function(item) {
        return item.entry;
      };

      return Entry;

    })(Backbone.Model);
    EntryCollection = (function(_super) {
      __extends(EntryCollection, _super);

      function EntryCollection() {
        _ref1 = EntryCollection.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      EntryCollection.prototype.model = Entry;

      EntryCollection.prototype.minutes = function() {
        return this.pluck("minutes").reduce((function(a, b) {
          return a + b;
        }), 0);
      };

      return EntryCollection;

    })(Backbone.Collection);
    EntryItemView = (function(_super) {
      __extends(EntryItemView, _super);

      function EntryItemView() {
        this.templateHelpers = __bind(this.templateHelpers, this);
        _ref2 = EntryItemView.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      EntryItemView.prototype.template = "entry/item-view";

      EntryItemView.prototype.tagName = "li";

      EntryItemView.prototype.className = function() {
        return "entry" + (this.model.get("billable") ? "" : " unbillable");
      };

      EntryItemView.prototype.events = {
        click: function() {
          return console.log(this.model);
        }
      };

      EntryItemView.prototype.attributes = function() {
        return {
          style: "height: " + ((this.model.get('minutes') / (60 * 8)) * 100) + "%; background-color: " + (_.sample(colors)) + ";"
        };
      };

      EntryItemView.prototype.templateHelpers = function() {
        var _this = this;
        return {
          tags: function() {
            return _.uniq(_this.model.get("description").toLowerCase().replace(/[!#]/g, "").split(", "));
          }
        };
      };

      return EntryItemView;

    })(Marionette.ItemView);
    Day = (function(_super) {
      __extends(Day, _super);

      function Day() {
        _ref3 = Day.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      Day.prototype.initialize = function(options) {
        var entries;
        entries = options.entries;
        return this.set("entries", new EntryCollection(entries, {
          parse: true
        }));
      };

      return Day;

    })(Backbone.Model);
    DayCollection = (function(_super) {
      __extends(DayCollection, _super);

      function DayCollection() {
        _ref4 = DayCollection.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      DayCollection.prototype.model = Day;

      return DayCollection;

    })(Backbone.Collection);
    DayCompositeView = (function(_super) {
      __extends(DayCompositeView, _super);

      function DayCompositeView() {
        this.templateHelpers = __bind(this.templateHelpers, this);
        _ref5 = DayCompositeView.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      DayCompositeView.prototype.template = "day/composite-view";

      DayCompositeView.prototype.tagName = "li";

      DayCompositeView.prototype.className = function() {
        return "day " + (this.model.get("date") === this.options.today ? "today" : "");
      };

      DayCompositeView.prototype.itemView = EntryItemView;

      DayCompositeView.prototype.itemViewContainer = ".entry-list-view";

      DayCompositeView.prototype.templateHelpers = function() {
        var _this = this;
        return {
          minutes: function() {
            return _this.collection.minutes();
          },
          isToday: function() {
            return _this.model.get("date") === _this.options.today;
          }
        };
      };

      DayCompositeView.prototype.initialize = function(options) {
        this.options = options;
        return this.collection = this.options.model.get("entries");
      };

      return DayCompositeView;

    })(Marionette.CompositeView);
    DayListView = (function(_super) {
      __extends(DayListView, _super);

      function DayListView() {
        _ref6 = DayListView.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      DayListView.prototype.itemView = DayCompositeView;

      DayListView.prototype.el = ".day-list-view";

      DayListView.prototype.itemViewOptions = {
        today: moment().format("YYYY-MM-DD")
      };

      return DayListView;

    })(Marionette.CollectionView);
    this.timeline = function() {
      var $el, currentTime, elHeight, elWidth, index, minuteHeight, minutesSinceMidnight, now, numbers, ruler, y, _i, _ref7, _results;
      $el = $(".entry-list-view");
      elWidth = $el.outerWidth(true);
      elHeight = $el.height();
      console.log(elWidth, elHeight);
      ruler = document.getCSSCanvasContext('2d', 'ruler', elWidth, elHeight);
      numbers = document.getCSSCanvasContext('2d', 'numbers', elWidth, elHeight);
      currentTime = document.getCSSCanvasContext('2d', 'now', elWidth, elHeight);
      index = 10;
      minutesSinceMidnight = (new Date() - new Date().setHours(0, 0, 0, 0)) / 1000 / 60;
      minutesSinceMidnight -= 10 * 60;
      minuteHeight = elHeight / (8 * 60);
      now = minuteHeight * minutesSinceMidnight;
      now = Math.round(now);
      now += 0.5;
      currentTime.beginPath();
      currentTime.strokeStyle = "#CD6B69";
      currentTime.moveTo(40, now);
      currentTime.lineTo(elWidth - 1, now);
      currentTime.stroke();
      currentTime.beginPath();
      currentTime.fillStyle = "#CD6B69";
      currentTime.moveTo(0, now);
      currentTime.arc(40, now, 4, 0, Math.PI * 2, true);
      currentTime.fill();
      currentTime.font = '10px Droid Sans';
      currentTime.textAlign = 'left';
      currentTime.textBaseline = 'middle';
      currentTime.fillStyle = "#CD6B69";
      currentTime.fillText(moment().format("HH:mm"), 5, now);
      _results = [];
      for (y = _i = 5, _ref7 = elHeight / 8; _ref7 > 0 ? _i <= elHeight : _i >= elHeight; y = _i += _ref7) {
        if (!(y !== 5)) {
          continue;
        }
        index++;
        if (index === 18) {
          continue;
        }
        y = Math.round(y);
        y += 0.5;
        ruler.beginPath();
        ruler.strokeStyle = "#e0e0e0";
        ruler.moveTo(0, y);
        ruler.lineTo(elWidth - 1, y);
        ruler.stroke();
        numbers.beginPath();
        numbers.fillStyle = "#e0e0e0";
        numbers.arc(10, y + 0.5, 8, 0, Math.PI * 2, true);
        numbers.fill();
        numbers.font = '8px Droid Sans';
        numbers.textAlign = 'center';
        numbers.textBaseline = 'middle';
        numbers.fillStyle = "black";
        _results.push(numbers.fillText(index, 9.5, y + 1));
      }
      return _results;
    };
    this.refresh = function() {
      App.freckle._cache.store.clear();
      return _this.getDays();
    };
    this.getDays = function() {
      return App.freckle.entries.search({
        people: [App.user.get("id")],
        success: function(entries) {
          var dates, days, end, groupedEntries, range, start;
          groupedEntries = _.groupBy(entries, function(item) {
            return item.entry.date;
          });
          dates = Object.keys(groupedEntries);
          start = moment(dates[dates.length - 1]).startOf('week');
          end = moment().endOf('week');
          range = moment().range(start, end);
          days = [];
          range.by('days', function(moment) {
            var formattedMoment;
            formattedMoment = moment.format("YYYY-MM-DD");
            return days.unshift({
              moment: moment,
              date: formattedMoment,
              entries: groupedEntries[formattedMoment] || []
            });
          });
          _this.dayCollection.reset(days);
          return _this.dayListView.render();
        }
      });
    };
    return this.addInitializer(function() {
      moment.lang('de');
      _this.dayCollection = new DayCollection;
      _this.dayListView = new DayListView({
        collection: _this.dayCollection
      });
      _this.getDays();
      return _this.dayListView.render();
    });
  });

  $(function() {
    return Mole.start();
  });

}).call(this);
