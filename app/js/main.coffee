app = angular.module 'app', ['ui.bootstrap']
window.app = app

app.controller('navController', ['$scope', '$window', ($scope, $window) ->
  $scope.isActive = (path)->
    path is $window.location.pathname
]);

app.directive('tags', ['$http', ($http) ->
  link = (scope, element)->
    # タグを取得
    scope.getTags = ->
      scope.connecting = true
      $http.get('/tags').success((res) ->
        scope.tags = res
        scope.connecting = false)
    scope.getTags()

  return {
  restrict : 'E'
  link : link
  template : '<select class="form-control" value="" name="s" ng-model="s" ng-disabled="connecting"><option ng-repeat="tag in tags" value="{{tag}}">{{tag}}</option></select>'
  }
])