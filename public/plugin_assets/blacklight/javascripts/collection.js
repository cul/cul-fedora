function getMemberQuery(collectionUri, dcType){
  var query = "select $member from <#ri> where \
 $member <rdf:type> <cul:Aggregator>\
 and $member <dc:type> '%s'\
 and walk($p <cul:memberOf> <%s> and $member <cul:memberOf> $p)\
";
  query = query.replace(/%s/,dcType);
  query = query.replace(/%s/,collectionUri);
}
function getRepoCount(collectionUri,dcType,riUrl) {
  var query = getMemberQuery(collectionUri,dcType);
  var queryUrl = riUrl + '?type=tuples&limit=&lang=itql&format=count-json&query=' + encodeURIComponent(query) + '&callback=?';
  $.getJSON(queryUrl, function(data) {
  });
}
