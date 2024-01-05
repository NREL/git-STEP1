function openTab(evt, tabName) {
    var i, tabcontent, tablinks;
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
      tabcontent[i].style.display = "none";
    }
    tablinks = document.getElementsByClassName("location-tab");
    for (i = 0; i < tablinks.length; i++) {
      tablinks[i].className = tablinks[i].className.replace(" active", "");
    }
    document.getElementById(tabName).style.display = "block";
    evt.currentTarget.className += " active";
}
mapboxgl.accessToken = 'pk.eyJ1IjoiamFyZXRrYWRsZWMiLCJhIjoiY2xwdm1qNzB5MDV4ZTJpcWV4c2VqOWgyZCJ9.2d464B9zhrI2yAd3mo4V9w';
const map = new mapboxgl.Map({
    container: 'map', // container ID
    style: 'mapbox://styles/mapbox/streets-v12', // style URL
    center: [-105.23, 39.75], // starting position [lng, lat]
    zoom: 9, // starting zoom
});
const searchJS = document.getElementById('search-js');
searchJS.onload = function () {
const searchBox = new MapboxSearchBox();
searchBox.accessToken = 'pk.eyJ1IjoiamFyZXRrYWRsZWMiLCJhIjoiY2xwdm1qNzB5MDV4ZTJpcWV4c2VqOWgyZCJ9.2d464B9zhrI2yAd3mo4V9w';
searchBox.options = {
    types: 'address,poi',
    proximity: [-105.23, 39.75]
};
searchBox.marker = true;
searchBox.mapboxgl = mapboxgl;
map.addControl(searchBox);
};
const draw = new MapboxDraw({
  displayControlsDefault: false,
  // Select which mapbox-gl-draw control buttons to add to the map.
  controls: {
  polygon: true,
  trash: true
},
// Set mapbox-gl-draw to draw by default.
// The user does not have to click the polygon control button first.
defaultMode: 'draw_polygon'
});
map.addControl(draw);