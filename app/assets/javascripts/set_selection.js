/*
* jQuery plugin: fieldSelection - v0.1.1 - last change: 2006-12-16
* (c) 2006 Alex Brem <alex@0xab.cd> - http://blog.0xab.cd
*/

(function() {

  var fieldSelection = {

    selectRange: function(start, end) {
      var e = document.getElementById($(this).attr('id')); // I don't know why... but $(this) don't want to work today :-/
      if (!e) return;
      else if (e.setSelectionRange) { e.focus(); e.setSelectionRange(start, end); } /* WebKit */
      else if (e.createTextRange) { var range = e.createTextRange(); range.collapse(true); range.moveEnd('character', end); range.moveStart('character', start); range.select(); } /* IE */
      else if (e.selectionStart) { e.selectionStart = start; e.selectionEnd = end; }
    },

    getSelection: function() {

      var e = (this.jquery) ? this[0] : this;

      return (

        /* mozilla / dom 3.0 */
        ('selectionStart' in e && function() {
          var l = e.selectionEnd - e.selectionStart;
          return { start: e.selectionStart, end: e.selectionEnd, length: l, text: e.value.substr(e.selectionStart, l) };
        }) ||

        /* exploder */
        (document.selection && function() {

          e.focus();

          var r = document.selection.createRange();
          if (r === null) {
            return { start: 0, end: e.value.length, length: 0 }
          }

          var re = e.createTextRange();
          var rc = re.duplicate();
          re.moveToBookmark(r.getBookmark());
          rc.setEndPoint('EndToStart', re);

          return { start: rc.text.length, end: rc.text.length + r.text.length, length: r.text.length, text: r.text };
        }) ||

        /* browser not supported */
        function() { return null; }

      )();

    },

    replaceSelection: function() {

      var e = (typeof this.id == 'function') ? this.get(0) : this;
      var text = arguments[0] || '';

      return (

        /* mozilla / dom 3.0 */
        ('selectionStart' in e && function() {
          e.value = e.value.substr(0, e.selectionStart) + text + e.value.substr(e.selectionEnd, e.value.length);
          return this;
        }) ||

        /* exploder */
        (document.selection && function() {
          e.focus();
          document.selection.createRange().text = text;
          return this;
        }) ||

        /* browser not supported */
        function() {
          e.value += text;
          return jQuery(e);
        }

      )();

    }

  };

  jQuery.each(fieldSelection, function(i) { jQuery.fn[i] = this; });

})();
