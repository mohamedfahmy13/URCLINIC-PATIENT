/// A local map style follows the app preference without changing locations or markers.
const darkMapStyle = '''
[
 {"elementType":"geometry","stylers":[{"color":"#1b2431"}]},
 {"elementType":"labels.text.fill","stylers":[{"color":"#b5c1d0"}]},
 {"elementType":"labels.text.stroke","stylers":[{"color":"#10151d"}]},
 {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304054"}]},
 {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#42556b"}]},
 {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#163a35"}]},
 {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0c2535"}]},
 {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#263445"}]}
]
''';
