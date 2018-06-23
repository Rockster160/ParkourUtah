$(document).ready(function() {
  if ($('.monitor-page').length > 0) {

    App.competition = App.cable.subscriptions.create({
      channel: "CompetitionChannel"
    }, {
      connected: function() {
        reloadCompetition()
      },
      received: function(data) {
        updateRankings(data)
      }
    })

    reloadCompetition = function() {
      var url = $(".monitor-page").attr("data-competition-url")
      $.get(url).success(function(data) {
        updateRankings(data)
      })
    }

    updateRankings = function(data) {
      $(data).each(function() {
        var competitor = this
        var row = $("[data-competitor-id=" + competitor.id + "]")
        $(["flow", "execution", "creativity", "difficulty"]).each(function() {
          var category = this.toString(), score = competitor[category] || "--"
          row.find("[data-category=" + category + "] a").text(score || "--")
        })
        row.find("[data-category=overall_impression]").text(competitor.overall_impression || "--")
        row.find("[data-category=total]").text(competitor.total || "--")
        row.find("[data-category=rank]").text(competitor.rank || "--")
      })
      $(".tableSorter").trigger("reorder")
    }
  }
})
