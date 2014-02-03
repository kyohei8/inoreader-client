app = angular.module 'app', ['ui.bootstrap']
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

