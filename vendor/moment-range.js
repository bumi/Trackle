(function(root, factory) {
    if(typeof exports === 'object') {
        module.exports = factory(require('moment'));
    }
    else if(typeof define === 'function' && define.amd) {
        define('moment-range', ['moment'], factory);
    }
    else {
        root.moment = factory(root.moment);
    }
}(this, function(moment) {
/**
  * DateRange class to store ranges and query dates.
  * @typedef {!Object}
*
*/

var DateRange;

DateRange = (function() {
  /**
    * DateRange instance.
    * @param {(Moment|Date)} start Start of interval.
    * @param {(Moment|Date)} end   End of interval.
    * @constructor
  *
  */

  function DateRange(start, end) {
    this.start = moment(start);
    this.end = moment(end);
  }

  /**
    * Determine if the current interval contains a given moment/date/range.
    * @param {(Moment|Date|DateRange)} other Date to check.
    * @return {!boolean}
  *
  */


  DateRange.prototype.contains = function(other) {
    if (other instanceof DateRange) {
      return this.start < other.start && this.end > other.end;
    } else {
      return (this.start <= other && other <= this.end);
    }
  };

  /**
    * @private
  *
  */


  DateRange.prototype._by_string = function(interval, hollaback) {
    var current, _results;
    current = moment(this.start);
    _results = [];
    while (this.contains(current)) {
      hollaback.call(this, current.clone());
      _results.push(current.add(interval, 1));
    }
    return _results;
  };

  /**
    * @private
  *
  */


  DateRange.prototype._by_range = function(range_interval, hollaback) {
    var i, l, _i, _results;
    l = Math.round(this / range_interval);
    if (l === Infinity) {
      return this;
    }
    _results = [];
    for (i = _i = 0; 0 <= l ? _i <= l : _i >= l; i = 0 <= l ? ++_i : --_i) {
      _results.push(hollaback.call(this, moment(this.start.valueOf() + range_interval.valueOf() * i)));
    }
    return _results;
  };

  /**
    * Determine if the current date range overlaps a given date range.
    * @param {!DateRange} range Date range to check.
    * @return {!boolean}
  *
  */


  DateRange.prototype.overlaps = function(range) {
    var _ref, _ref1;
    if ((this.start < (_ref = range.start) && _ref < this.end)) {
      return true;
    } else if ((range.start < (_ref1 = this.start) && _ref1 < range.end)) {
      return true;
    } else {
      return false;
    }
  };

  /**
    * Iterate over the date range by a given date range, executing a function
    * for each sub-range.
    * @param {!DateRange|String} range     Date range to be used for iteration
    *                                      or shorthand string (shorthands:
    *                                      http://momentjs.com/docs/#/manipulating/add/)
    * @param {!function(Moment)} hollaback Function to execute for each sub-range.
    * @return {!boolean}
  *
  */


  DateRange.prototype.by = function(range, hollaback) {
    if (typeof range === 'string') {
      this._by_string(range, hollaback);
    } else {
      this._by_range(range, hollaback);
    }
    return this;
  };

  /**
    * Date range in milliseconds. Allows basic coercion math of date ranges.
    * @return {!number}
  *
  */


  DateRange.prototype.valueOf = function() {
    return this.end - this.start;
  };

  /**
    * Date range toDate
    * @return  {!Array}
  *
  */


  DateRange.prototype.toDate = function() {
    return [this.start.toDate(), this.end.toDate()];
  };

  return DateRange;

})();

/**
  * Build a date range.
  * @param {(Moment|Date)} start Start of range.
  * @param {(Moment|Date)} end   End of range.
  * @this {Moment}
  * @return {!DateRange}
*
*/


moment.fn.range = function(start, end) {
  if (['year', 'month', 'week', 'day', 'hour', 'minute', 'second'].indexOf(start) > -1) {
    return new DateRange(moment(this).startOf(start), moment(this).endOf(start));
  } else {
    return new DateRange(start, end);
  }
};

/**
  * Check if the current moment is within a given date range.
  * @param {!DateRange} range Date range to check.
  * @this {Moment}
  * @return {!boolean}
*
*/


moment.fn.within = function(range) {
  return range.contains(this._d);
};

    return moment;
}));
