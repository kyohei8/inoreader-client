app.directive('feeds', ['$http', ($http) ->
  link = (scope)->
    scope.getFeeds = ->
      # feedを取得
      $http.get('/feeds').success((data) ->
        scope.feeds = data
        scope.s = data[0]
        scope.connecting = false)
    scope.getFeeds()

  return {
  restrict : 'E'
  link : link
  template : '<select class="form-control" name="s" ng-model="s" ng-disabled="sDisabled" ng-options="f.label for f in feeds"></select>'
  }
])

app.controller('addSubscriptionController', ['$scope', '$http', '$request', ($scope, $http, $request) ->
  $scope.quickadd = ''
  $scope.connecting = false
  $scope.requestUrl = ''
  $scope.responseBody = ''
  $scope.submit = ->
    $scope.connecting = true
    $request.send('/add_subscription', { quickadd : $scope.quickadd }, 'POST', ((res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = angular.fromJson(res.body)), ->
      $scope.connecting = false)

]);

app.controller('editSubscriptionController', ['$scope', '$http', '$request', ($scope, $http, $request) ->
  $scope.type = 'e'
  $scope.types = [
    {value : 'e', label : 'edit'},
    {value : 'u', label : 'unsubscribe'},
    {value : 's', label : 'subscribe'}
  ]
  $scope.feed = ''
  $scope.t = ''
  $scope.a = ''
  $scope.r = ''

  $scope.connecting = false
  $scope.requestUrl = ''
  $scope.responseBody = ''

  $scope.$watch 'type', (type) ->
    if type is 'e'
      $scope.sDisabled = false
      $scope.feedDisabled = true
      $scope.tDisabled = false
      $scope.aDisabled = false
      $scope.rDisabled = false
    else if type is 'u'
      $scope.sDisabled = false
      $scope.feedDisabled = true
      $scope.tDisabled = true
      $scope.aDisabled = true
      $scope.rDisabled = true
    else
      $scope.sDisabled = true
      $scope.feedDisabled = false
      $scope.tDisabled = true
      $scope.aDisabled = true
      $scope.rDisabled = true

  $scope.submit = ->
    $scope.connecting = true
    data =
      type : $scope.type
      s : $scope.s.id
      feed : $scope.feed
      t : $scope.t
      a : $scope.a
      r : $scope.r


    $request.send('/edit_subscription', data, 'POST', ((res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
      $scope.getFeeds())
    , ->
      $scope.connecting = false
    )

]);
