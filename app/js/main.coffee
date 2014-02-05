app = angular.module 'app', ['ngAnimate', 'ui.bootstrap']
window.app = app

app.controller('navController', ['$scope', '$window', ($scope, $window) ->
  $scope.isActive = (path)->
    path is $window.location.pathname
]);

app.directive('ngLadda', ->
  {
  restrict: 'A'
  link: (scope, $element) ->
    $element.addClass('ladda-button')
    $element.attr('data-style', 'expand-right')
    l = Ladda.create($element[0]);
    l.id = $element.text()
    scope.$watch('connecting', (newVal) ->
      if newVal isnt undefined
        if newVal
          l.start()
        else
          l.stop()

    )
  }
)

app.directive('tags', ->
  return {
  restrict: 'E'
  link: angular.noop()
  template: '<select class="form-control" value="" name="s" ng-model="s" ng-disabled="connecting"><option ng-repeat="tag in tags" value="{{tag}}">{{tag}}</option></select>'
  }
)

app.factory '$request', [ '$http', ($http) ->
  {
  send: (path, data, method, successFunc, errorFunc)->
    $http({
      url: path,
      data: $.param(data),
      method: method,
      headers:
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
    }).success((res) ->
      successFunc(res)
    ).error((data, status, h)->
      window.alert("Error : Request Failed. (ErrorCode:#{status})")
      errorFunc()
    )
  }
]

app.controller('indexController', ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->
  $scope.LoginSuccessAlert =
    type: 'info'
    msg : 'Login Successed!'
    show: false

  $scope.LoginSuccessAlert.show = false

  $http.get('/firstlgoin').success((res)->
    if res.result
      $timeout(->
        $scope.LoginSuccessAlert.show = true
        $timeout(->
          $scope.LoginSuccessAlert.show = false
        , 3000)
      , 1000)
  )

  $scope.closeAlert = ->
    $scope.LoginSuccessAlert.show = false

]);