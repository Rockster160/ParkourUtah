$(document).ready(function(){

  var users = new Bloodhound({
    limit: 5,
    remote: {
      url: '/peeps/users?by_fuzzy_text=%QUERY',
      filter: function(x) {
        return $.map(x, function(item) {
          return { user: item }
        });
      },
    },
    datumTokenizer: function(user) {
      return Bloodhound.tokenizers.whitespace(user.name);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace
  });

  users.initialize();

  $('#user_index_search_field').typeahead({
    highlight: true,
    hint: true
  }, {
    source: users.ttAdapter(),
    name: 'users',
    templates: {
      suggestion: function(data) {
        var athletes = '';
        $(data.user.dependents).each(function(e) {
          athletes += ('&nbsp;&nbsp;&nbsp;&nbsp;<span>' + this.full_name.substring(0, 30) + ' - ' + this.athlete_id + '</span><br/>')
        })
        return '<div><strong>' +
        data.user.email.substring(0, 50) +
        '</strong><span class="pull-right">' +
        data.user.id +
        '</span><br/>' +
        athletes
        '</div>'
      }
    }
  });

  $('#user_index_search_field').on('typeahead:selected', function(obj, datum, name) {
    window.location.href = "/user/" + datum.user.id
  });
});
