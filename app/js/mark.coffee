app.controller('markController',['$scope', '$http', ($scope, $http) ->
  $scope.s = ''
  $scope.ts = ''
  $scope.connecting = false

  $scope.submit = ->
    $scope.connecting = true
    $http({
      url : '/mark_all_as_read',
      method : 'POST',
      data : $.param({
        s : $scope.s
        ts : $scope.ts
      }),
      headers :
        'Content-Type' : 'application/x-www-form-urlencoded; charset=UTF-8'
    }).success (res) ->
      $scope.connecting = false
      $scope.requestUrl = res.url
      $scope.responseBody = res.body
]);