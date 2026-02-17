var map, markers = [];

var initializeGmaps = function() {
  if ($('.gmap').length > 0) {
    var gmap = $('.gmap');
    var center = new google.maps.LatLng(gmap.data('lat'), gmap.data('lng'));

    map = new google.maps.Map(document.getElementById('map'), {
      mapTypeId: google.maps.MapTypeId.HYBRID,
      center: center,
      zoom: gmap.data('zoom') || 15
    });

    var bounds = new google.maps.LatLngBounds();

    $('.gmap_coord').each(function() {
      var el = $(this);
      var position = new google.maps.LatLng(el.data('lat'), el.data('lon'));
      var marker = new google.maps.Marker({
        position: position,
        map: map,
        animation: google.maps.Animation.DROP,
        draggable: true
      });

      var infowindow = new google.maps.InfoWindow({
        content: '<a href="' + el.data('spot-url') + '">' + el.data('spot-name') + '</a>'
      });
      marker.addListener('click', function() { infowindow.open(map, marker); });

      markers.push(marker);
      bounds.extend(position);
    });

    if (gmap.data('contain') && markers.length > 0) {
      map.fitBounds(bounds);
    }

    $('#gmaps_search').click(function() {
      geoLocate($('#gmaps_address').val());
    });

    $('#gmaps_form').on('submit', function() {
      if (markers.length > 0) {
        var pos = markers[0].getPosition();
        $('#lat').val(pos.lat());
        $('#lon').val(pos.lng());
      }
    });
  }
}

function geoLocate(address) {
  var geocoder = new google.maps.Geocoder();
  geocoder.geocode({ address: address }, function(results, status) {
    if (status === google.maps.GeocoderStatus.OK) {
      var position = results[0].geometry.location;
      markers.forEach(function(m) { m.setMap(null); });
      markers = [];

      var marker = new google.maps.Marker({
        position: position,
        map: map,
        animation: google.maps.Animation.DROP,
        draggable: true
      });
      markers.push(marker);
      map.panTo(position);
    }
  });
}

$(document).ready(initializeGmaps);
