this["JST"] = this["JST"] || {};

this["JST"]["day/composite-view"] = function(m) {
var __t, __p = '', __e = _.escape;
__p += '<div class=\'date\'>' +
((__t = ( m.moment.format('DD.MM') )) == null ? '' : __t) +
', ' +
((__t = ( m.minutes() / 60 )) == null ? '' : __t) +
' hrs</div><ul class=\'entry-list-view\'></ul>';
return __p
};

this["JST"]["entry/item-view"] = function(m) {
var __t, __p = '', __e = _.escape, __j = Array.prototype.join;
function print() { __p += __j.call(arguments, '') }
__p += '<div class="entry-body"><div class="header"><span class=\'project\' style="background-color:' +
((__t = ( m.projectColor() )) == null ? '' : __t) +
';">' +
((__t = ( m.project && m.project.name )) == null ? '' : __t) +
'</span><span class=\'minutes\'>' +
((__t = ( m.minutes / 60 )) == null ? '' : __t) +
'</span></div>';
 var tags = m.tags() ;

 for(var tag in tags) { ;
__p += '<div class=\'description\'>' +
((__t = ( tags[tag] )) == null ? '' : __t) +
'</div>';
 } ;
__p += '</div>';
return __p
};